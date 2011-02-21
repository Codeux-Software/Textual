#!/usr/bin/perl -w

use strict;
use DBI;
require DBD::SQLite;
use Data::Dumper;
use HTML::Entities;
$| = 1;

my ($program_name, $script_name) = ($0, (defined($ENV{"SCRIPT_NAME"}) && defined($ENV{"SCRIPT_LINENO"})) ? "$ENV{'SCRIPT_NAME'}:$ENV{'SCRIPT_LINENO'}" : "");
#$program_name =~ s/(.*?)\/?([^\/]+)$/$2/;
$program_name =~ s/^$ENV{'PROJECT_DIR'}\/?//;

for my $env (qw(DOCUMENTATION_SQL_DATABASE_FILE DOCUMENTATION_DOCSET_ID DOCUMENTATION_DOCSET_SOURCE_HTML DOCUMENTATION_DOCSET_TEMP_DIR)) {
  if(!defined($ENV{$env}))  { print("${$program_name} error: Environment variable $env not set.\n"); exit(1); }
}

my $dbh = DBI->connect("dbi:SQLite:dbname=$ENV{'DOCUMENTATION_SQL_DATABASE_FILE'}","","", { AutoCommit => 1, RaiseError => 1 });

$dbh->do("PRAGMA synchronous = OFF");
$dbh->do("ANALYZE");

$dbh->begin_work;


#### DB prep work, create functions, etc

my $sqlSelectDSID = $dbh->prepare("SELECT dsid FROM docset WHERE docset = ?");
my $sqlInsertDocset = $dbh->prepare("INSERT INTO docset (docset) VALUES (?)");

$dbh->func( 'docsetid', 1,
sub {
  my ($docset) = (@_);
  my ($row) = ($dbh->selectrow_hashref($sqlSelectDSID, {MaxRows => 1}, ($docset)));
  if ($row) { return($row->{'dsid'}); }
  $sqlInsertDocset->execute($docset);
  $row = $dbh->selectrow_hashref($sqlSelectDSID, {MaxRows => 1}, ($docset));
  if ($row) { return($row->{'dsid'}); } else { return(undef); }
}, 'create_function' 
);

my $sqlSelectFID = $dbh->prepare("SELECT fid FROM files WHERE dsid = docsetid(?) AND path = ? AND file = ?");
my $sqlInsertFiles = $dbh->prepare("INSERT INTO files (dsid, path, file, filePath) VALUES (docsetid(?), ?, ?, ?)");
my $sqlAnalyze = $dbh->prepare("ANALYZE");

$dbh->func( 'filefid', 3,
sub {
  my ($docset, $path, $file) = (@_);
  my ($row) = $dbh->selectrow_hashref($sqlSelectFID, {MaxRows => 1}, ($docset, $path, $file));
  if ($row) { return($row->{'fid'}); }
  $sqlInsertFiles->execute($docset, $path, $file, (($path eq '') ? '' : "$path/") . $file);
  my $fid = $dbh->last_insert_id(undef, undef, undef, undef);
  if(($fid % 59) == 0) { $sqlAnalyze->execute; }
  return($fid);
}, 'create_function' 
);

my $sqlInsertNodeName = $dbh->prepare("INSERT INTO nodeNames (fid, anchor, name, href) VALUES (filefid(?, ?, ?), ?, ?, ?)");
my $sqlSelectRefIDInternal = $dbh->prepare("SELECT refid FROM nodeNames WHERE fid = filefid(?, ?, ?) AND anchor = ?");

$dbh->func( 'refid', 3,
sub {
  my ($docset, $href, $name) = (@_);
  $href =~ /^([^#]*)(?:#?)(.*)$/;
  my($hrefFile, $hrefAnchor) = ($1, $2);
  $hrefFile =~ /(.*?)\/?([^\/]+)$/;
  my ($path, $file, $filePath) = ($1, $2, (($1 eq '') ? $2 : "$1/$2"));
  
  my ($row) = $dbh->selectrow_hashref($sqlSelectRefIDInternal, {MaxRows => 1}, ($docset, $path, $file, $hrefAnchor));
  if ($row) { return($row->{'refid'}); }
  $sqlInsertNodeName->execute($docset, $path, $file, $hrefAnchor, $name, $href);
  my $refid = $dbh->last_insert_id(undef, undef, undef, undef);
  return($refid);
}, 'create_function' 
);

my $sqlSelectRefID = $dbh->prepare("SELECT refid(?, ?, ?) AS refid");

my %xrefs;
for my $row (selectall_hash($dbh, "SELECT DISTINCT linkId, href, apple_ref, file FROM t_xtoc WHERE xref IS NOT NULL AND linkId IS NOT NULL AND href IS NOT NULL")) {
  $xrefs{'name'}->{$row->{'linkId'}} = $row->{'apple_ref'};
  $xrefs{'href'}->{$row->{'href'}} = $row->{'file'} . '#' . $row->{'apple_ref'};
  $xrefs{'file'}->{$row->{'file'}} = $row->{'file'};
}


my $docset = $ENV{'DOCUMENTATION_DOCSET_ID'};

my @htmlFiles = @{$dbh->selectcol_arrayref("SELECT DISTINCT file FROM html ORDER BY file")};
push(@htmlFiles, qw(content.html content_frame.html toc_opened.html));


#
#  Work starts here where we re-write all the anchors in to //apple_ref/ format.
#

print("${program_name}:97: note: Rewriting anchors to //apple-ref/ format.\n");
for my $file (@htmlFiles) { processFile($ENV{'DOCUMENTATION_DOCSET_SOURCE_HTML'}, $file, $ENV{'DOCUMENTATION_DOCSET_TEMP_DOCS_DIR'}); }

# We need to give docsetutil a list of 'nodes'.  The definition of a 'node'
# is a bit fuzzy.  It seems to be 'and individual file', and that file can be
# local or via http:  Then there's the nodes 'path' and 'file' attributes.
# File is optional, path is mandatory and can be the complete path to a 
# file.. I don't know why file exists.  And then nodes can be 'folder' types
# which behave differently than file types.  BUT, we need a DocSet wide
# unique reference id for all our files.  To add to the fun, nodes can
# also have 'anchors', ie 'index.html#middle'.  So we enumerate all our
# possible href's and assign them a reference ID.  What's unclear, however,
# is if two nodes point to the same file, but have different anchors, are
# they different 'nodes'.  I'd hope so as it'd be useless if you could have
# a single link to a file.  Who knows, we assign an id for every unique
# href.  Then, we track who links to those nodes, and the intersection of
# those two form the contents of what we'll put in the 'Nodes' library.

my @referenceNodes;

for my $row (selectall_hash($dbh, "SELECT ocdef.hid AS hid, occl.class AS class, vt2.text AS filename FROM objCClassDefinition AS ocdef JOIN objcclass AS occl ON ocdef.occlid = occl.occlid JOIN v_tagid AS vt1 ON vt1.hid = ocdef.hid AND vt1.keyword = 'class' AND vt1.text = occl.class JOIN v_tagid AS vt2 ON vt2.hdcid = vt1.hdcid AND vt2.keyword = 'toc' and vt2.arg = 0")) {
  $sqlInsertNodeName->execute($docset, '', $row->{'class'} . '.html', undef, $row->{'class'} . ' Class Reference', $row->{'class'} . '.html');
  push(@referenceNodes, $row->{'class'} . '.html');
}

for my $row (selectall_hash($dbh, "SELECT DISTINCT ocm.hid AS hid, occl.class AS class, occat.category AS category, toc.tocName AS tocName FROM toc JOIN objCMethods AS ocm ON ocm.tocid = toc.tocid AND ocm.hdcid IS NOT NULL JOIN objCClassCategory AS occat ON occat.occlid = ocm.occlid AND ocm.startsAt >= occat.startsAt AND (occat.startsAt + occat.length) >= (ocm.startsAt) join objCClass AS occl ON ocm.occlid = occl.occlid;")) {
  $sqlInsertNodeName->execute($docset, '', $row->{'tocName'} . '.html', undef, $row->{'tocName'} . ' RegexKit Additions Reference', $row->{'tocName'} . '.html');
  push(@referenceNodes, $row->{'tocName'} . '.html');
}

$sqlInsertNodeName->execute($docset, '', 'Constants.html', undef, 'RegexKit Constants Reference',  'Constants.html'); push(@referenceNodes, 'Constants.html');
$sqlInsertNodeName->execute($docset, '', 'DataTypes.html', undef, 'RegexKit Data Types Reference', 'DataTypes.html'); push(@referenceNodes, 'DataTypes.html');
$sqlInsertNodeName->execute($docset, '', 'Functions.html', undef, 'RegexKit Functions Reference',  'Functions.html'); push(@referenceNodes, 'Functions.html');


$sqlInsertNodeName->execute($docset, 'pcre', 'index.html', undef, 'PCRE', 'pcre/index.html');
$sqlInsertNodeName->execute($docset, 'pcre', 'pcresyntax.html', 'SEC1', 'Regex Quick Reference', 'pcre/pcresyntax.html');
$sqlInsertNodeName->execute($docset, 'pcre', 'pcrepattern.html', 'SEC1', 'Regular Expression Syntax', 'pcre/pcrepattern.html');


my (%nodeRefHash, %libraryHash);
for my $row (selectall_hash($dbh, "SELECT refid, href FROM nodeNames ORDER BY refid")) { $nodeRefHash{$row->{'href'}} = $row->{'refid'}; }

$libraryHash{'content.html'} = $nodeRefHash{'content.html'};
$libraryHash{'RegexKitImplementationTopics.html'} = $nodeRefHash{'RegexKitImplementationTopics.html'};
$libraryHash{'RegexKitProgrammingGuide.html'} = $nodeRefHash{'RegexKitProgrammingGuide.html'};
$libraryHash{'pcre/index.html'} = $nodeRefHash{'pcre/index.html'};
$libraryHash{'pcre/pcresyntax.html'} = $nodeRefHash{'pcre/pcresyntax.html'};
$libraryHash{'pcre/pcrepattern.html'} = $nodeRefHash{'pcre/pcrepattern.html'};

my $FH;

#
# Here we create the DocSets Info.plist.
#

open($FH, ">", "$ENV{'DOCUMENTATION_DOCSET_TEMP_DIR'}/$ENV{'DOCUMENTATION_DOCSET_ID'}/Contents/Info.plist");

print $FH <<END_PLIST;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleGetInfoString</key>
    <string>$ENV{'PROJECT_CURRENT_VERSION'}, Copyright © 2007-2008, John Engelhart</string>
    <key>CFBundleIdentifier</key>
    <string>$docset</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Reference Library</string>
    <key>CFBundleShortVersionString</key>
    <string>$ENV{'PROJECT_CURRENT_VERSION'}</string>
    <key>CFBundleVersion</key>
    <string>$ENV{'PROJECT_CURRENT_VERSION'}</string>
    <key>DocSetFeedName</key>
    <string>RegexKit</string>
    <key>DocSetFeedURL</key>
    <string>$ENV{'DOCUMENTATION_DOCSET_FEED_SCHEME'}//$ENV{'DOCUMENTATION_DOCSET_FEED_URL'}</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2007-2008, John Engelhart</string>
</dict>
</plist>
END_PLIST
close($FH); undef($FH);


#
# Now enumerate all of our 'tokens', which is a method, function,
# type, pre-processor macro, etc.
#

print("${program_name}:191: note: Creating Tokens.xml file.\n");


# Load up our trusty database that was build when we create the HTML docs.

my %no_link;
for my $row (selectall_hash($dbh, "SELECT DISTINCT xref FROM xrefs WHERE href IS NULL")) { $no_link{$row->{'xref'}} = 1; }

my %apple_ref;
my %global_xtoc_cache = gen_xtoc_cache();


# Here we go.. it's not pretty.
# We call 'common_token' to create an individual entry.  It also does the
# referenced marking of nodes.  'common_token' also calls 'seealso_tokens'
# which creates a docset format 'see also' reference and marks any nodes
# as referenced.

open($FH, ">", "$ENV{'DOCUMENTATION_DOCSET_TEMP_DIR'}/$ENV{'DOCUMENTATION_DOCSET_ID'}/Contents/Resources/Tokens.xml");

print($FH "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
print($FH "<Tokens version=\"1.0\">\n");

# Preprocessor macros (ENABLE_MACOSX_GARBAGE_COLLECTION, RKInteger, etc)
for my $row (@{$global_xtoc_cache{'preprocessorDefines'}}) { my $xref = $global_xtoc_cache{'xhdcid'}->{$row->{'hdcid'}}; my $avail = $global_xtoc_cache{'avail'}->{$xref->{'tbl'}}[$xref->{'id'}]; print $FH common_token("  ", {apple_ref => $apple_ref{$row->{'defineName'}}, hdcid => $row->{hdcid}, declaration => $row->{'cppText'}, header => $row->{'hid'}, addRefID => $row->{'defineName'}, abstract => $global_xtoc_cache{'tags'}[$row->{'hdcid'}]->{'abstract'}, path => $global_xtoc_cache{'xref'}{$row->{'defineName'}}{'file'}, avail => $avail, anchor => $apple_ref{$row->{'defineName'}}}); }

# Constant defines (RKReplaceAll) (only one?)
for my $row (@{$global_xtoc_cache{'constantDefines'}}) { my $xref = $global_xtoc_cache{'xhdcid'}->{$row->{'hdcid'}}; my $avail = $global_xtoc_cache{'avail'}->{$xref->{'tbl'}}[$xref->{'id'}]; print $FH common_token("  ", {apple_ref => $apple_ref{$row->{'defineName'}}, hdcid => $row->{hdcid}, declaration => $row->{'cppText'}, header => $row->{'hid'}, addRefID => $row->{'defineName'}, abstract => $global_xtoc_cache{'tags'}[$row->{'hdcid'}]->{'abstract'}, path => $global_xtoc_cache{'xref'}{$row->{'defineName'}}{'file'}, avail => $avail, anchor => $apple_ref{$row->{'defineName'}}}); }

# Constants (RKRegexCaptureReferenceException, etc)
for my $row (@{$global_xtoc_cache{'constants'}}) { my $xref = $global_xtoc_cache{'xhdcid'}->{$row->{'hdcid'}}; my $avail = $global_xtoc_cache{'avail'}->{$xref->{'tbl'}}[$xref->{'id'}]; print $FH common_token("  ", {apple_ref => $apple_ref{$row->{'name'}}, hdcid => $row->{hdcid}, declaration => $row->{'fullText'}, header => $row->{'hid'}, addRefID => $row->{'name'}, abstract => $global_xtoc_cache{'tags'}[$row->{'hdcid'}]->{'abstract'}, avail => $avail, path => $global_xtoc_cache{'xref'}{$row->{'name'}}{'file'}, anchor => $apple_ref{$row->{'name'}}}); }

# Category extensions to existing classes
for my $row (selectall_hash($dbh, "SELECT DISTINCT ocm.hid AS hid, occl.class AS class, occl.occlid AS occlid, occat.category AS category, toc.tocName AS tocName FROM toc JOIN objCMethods AS ocm ON ocm.tocid = toc.tocid AND ocm.hdcid IS NOT NULL JOIN objCClassCategory AS occat ON occat.occlid = ocm.occlid AND ocm.startsAt >= occat.startsAt AND (occat.startsAt + occat.length) >= (ocm.startsAt) join objCClass AS occl ON ocm.occlid = occl.occlid;")) { my $avail = $global_xtoc_cache{'avail'}->{'objCClass'}[$row->{'occlid'}]; print $FH common_token("  ", {apple_ref => "//apple_ref/occ/cat/$row->{'class'}($row->{'category'})", header => $row->{'hid'}, refid => $nodeRefHash{"$row->{'tocName'}.html"}, avail => $avail, path => "$row->{'tocName'}.html"}); }

# New classes.
for my $row (selectall_hash($dbh, "SELECT ocdef.hid AS hid, occl.class AS class, occl.occlid AS occlid, vt2.text AS filename FROM objCClassDefinition AS ocdef JOIN objcclass AS occl ON ocdef.occlid = occl.occlid JOIN v_tagid AS vt1 ON vt1.hid = ocdef.hid AND vt1.keyword = 'class' AND vt1.text = occl.class JOIN v_tagid AS vt2 ON vt2.hdcid = vt1.hdcid AND vt2.keyword = 'toc' and vt2.arg = 0")) { my $avail = $global_xtoc_cache{'avail'}->{'objCClass'}[$row->{'occlid'}]; print $FH common_token("  ", {apple_ref => "//apple_ref/occ/cl/$row->{'class'}", header => $row->{'hid'}, refid => $nodeRefHash{"$row->{'class'}.html"}, avail => $avail, path => "$row->{'filename'}.html"}); }


# We borrow this from the HTML build doc code.  Basically, grab the items
# that are flagged to go in to the table of contents (and thus have headerdoc
# comments) an enumerate them.  Only three types pop out here:
# objc methods, functions, and typedef/enums.
for my $tocName (keys %{$global_xtoc_cache{'toc'}{'contentsForToc'}}) {
  for my $tx (0 .. $#{$global_xtoc_cache{'toc'}{'contentsForToc'}{$tocName}}) {
    my $at = $global_xtoc_cache{'toc'}{'contentsForToc'}{$tocName}[$tx];
    if($at->{'table'} eq "objCMethods") {
      my $xref = $global_xtoc_cache{'xhdcid'}->{$at->{'hdcid'}}; my $avail = $global_xtoc_cache{'avail'}->{$xref->{'tbl'}}[$xref->{'id'}]; 
      print $FH common_token("    ", {apple_ref => $at->{apple_ref}, hdcid => $at->{hdcid}, declaration => addLinks($global_xtoc_cache{'methods'}[$at->{id}]->{'prettyText'}), header => $global_xtoc_cache{'methods'}[$at->{id}]->{'hid'}, addRefID => $at->{apple_ref}, abstract => $at->{titleText}, avail => $avail, anchor => $at->{apple_ref}});
    }
    elsif($at->{'table'} eq "prototypes") {
      my $xref = $global_xtoc_cache{'xhdcid'}->{$at->{'hdcid'}}; my $avail = $global_xtoc_cache{'avail'}->{$xref->{'tbl'}}[$xref->{'id'}]; 
      print $FH common_token("    ", {apple_ref => $at->{apple_ref}, hdcid => $at->{hdcid}, declaration => addLinks($global_xtoc_cache{'functions'}[$at->{id}]->{'prettyText'}), header => $global_xtoc_cache{'functions'}[$at->{id}]->{'hid'}, addRefID => $global_xtoc_cache{'tags'}[$at->{hdcid}]->{function}, abstract => $at->{titleText}, avail => $avail, anchor => $at->{apple_ref}});

    }
    elsif($at->{'table'} eq "typedefEnum") { print($FH typedef_token("    ",$at->{'id'})); }
  }
}

print($FH "</Tokens>\n");
close($FH); undef($FH);


# Now that we've enumerated everything that can possibly reference a node,
# we can output the used nodes.  Nodes.xml also contains the 'Table of
# Contents', which isn't terribly useful for us because we really don't
# have enough material for it to make sense.

print("${program_name}:257: note: Creating Nodes.xml file.\n");

my $docSetNodes = <<END_NODES;
<?xml version="1.0" encoding="UTF-8"?>
<DocSetNodes version="1.0">
  <TOC>
    <Node>
      <Name>Root</Name>
      <Path>index.html</Path>
      <Subnodes>
        <Node>
          <Name>RegexKit</Name>
          <Path>index.html</Path>
          <Subnodes>
            <Node>
              <Name>Guides</Name>
              <Path>index.html</Path>
              <Subnodes>
                <NodeRef refid="$nodeRefHash{'RegexKitImplementationTopics.html'}" />
                <NodeRef refid="$nodeRefHash{'RegexKitProgrammingGuide.html'}" />
              </Subnodes>
            </Node>
            <Node>
              <Name>Reference</Name>
              <Path>index.html</Path>
              <Subnodes>
END_NODES
# This spits out all the class and category nodes
for my $file (@referenceNodes) {
  $docSetNodes .= "                <NodeRef refid=\"$nodeRefHash{$file}\" />\n";
  $libraryHash{$file} = $nodeRefHash{$file};
}
$docSetNodes .= <<END_NODES;
              </Subnodes>
            </Node>
            <Node>
              <Name>PCRE</Name>
              <Path>pcre/index.html</Path>
              <Subnodes>
                <NodeRef refid="$nodeRefHash{'pcre/pcresyntax.html'}" />
                <NodeRef refid="$nodeRefHash{'pcre/pcrepattern.html'}" />
              </Subnodes>
            </Node>
          </Subnodes>
        </Node>
      </Subnodes>
    </Node>
  </TOC>
<Library>
END_NODES

# %libraryHash is what has kept the marked nodes.  We enumerate its keys
# and look up the refid we assigned at the start.
for my $href (sort keys %libraryHash) {
  my $refid = $libraryHash{$href};
  if(!defined($refid)) { $docSetNodes .= "    <!-- href '$href' is undefined. -->\n"; next; }
  my ($row) = $dbh->selectrow_hashref("SELECT f.filePath AS filePath, nn.name AS name, nn.anchor AS anchor FROM nodeNames AS nn JOIN files AS f ON f.fid = nn.fid WHERE nn.refid = $refid", {MaxRows => 1});
  my $anchor = (defined($row->{'anchor'})) ? ('<Anchor>' . $row->{'anchor'} . '</Anchor> ') : ""; 
  $docSetNodes .= "    <Node id=\"$refid\"> <Name>$row->{'name'}</Name> <Path>$row->{'filePath'}</Path> ${anchor}</Node>\n"
}

$docSetNodes .= "  </Library>\n";
$docSetNodes .= "</DocSetNodes>\n";

# And, output the collected 'Nodes.xml' string we've been putting together..
open($FH, ">", "$ENV{'DOCUMENTATION_DOCSET_TEMP_DIR'}/$ENV{'DOCUMENTATION_DOCSET_ID'}/Contents/Resources/Nodes.xml"); print($FH $docSetNodes); close($FH); undef($FH);

# We're done! Release our DB resources and go home.

$dbh->commit;

undef $sqlSelectRefID;
undef $sqlSelectRefIDInternal;
undef $sqlSelectDSID;
undef $sqlInsertDocset;
undef $sqlSelectFID;
undef $sqlInsertFiles;
undef $sqlInsertNodeName;
undef $sqlAnalyze;

$dbh->disconnect();
exit(0);

# This function takes the HTML documentation that we built earlier and
# rewrites the anchors in //apple_ref/ form.  Why not just use //apple_ref/
# an be done with it?  Love to.  But it's not valid HTML (for whatever reason,
# name="HERE" has really odd restrictions on legal characters.  And since
# we `tidy` check everything to catch errors, having tidy kick out five or
# six hundred warnings about how your name='blah' has invalid characters
# is not helpful nor productive.

sub processFile {
  my($inpath, $file, $outpath, $in, $out, $size, $lastm, $FILE_HANDLE) = ($_[0], $_[1], $_[2], "", "", (stat("$_[0]/$_[1]"))[7], 0);
  print("Rewriting: $file\n");
  if(! -r "$inpath/$file")  { print(STDERR "IN  Not readable: $file\n"); exit(1); return(undef); }
  if(! -w "$outpath/$file") { print(STDERR "OUT Not writeable: $file\n"); exit(1); return(undef); }

  # The idea is to scoop up the file in one shot, then sit in a pattern
  # matching while loop looking <a ... tags. We use a string to accumulate our
  # results. When we find a <a ... match, we append the our accumulator
  # the text we jumped over, and then look and see if it needs to be rewritten.
  # If it does, we append the rewritten form to the accumulator, and if not
  # we append the matched text unaltered and go to the next one.
  
  open($FILE_HANDLE, "<", "$inpath/$file"); sysread($FILE_HANDLE, $in, $size); close($FILE_HANDLE); undef($FILE_HANDLE);

  study($in);
  while($in =~ /((<a\s+[^>]*)(name|href)="([^"]*)"([^>]*>))/sgi) {
    if(defined($xrefs{lc($3)}{$4})) { $out .= substr($in, $lastm, $-[0] - $lastm) . $2 . $3 . "=\"". $xrefs{lc($3)}{$4} . "\"" . $5; $lastm = $+[0]; }
  }
  # Mop up the text from the last match to the end of the file.
  $out .= substr($in, $lastm, $size - $lastm);
  undef($in);

  open($FILE_HANDLE, ">", "$outpath/$file"); syswrite($FILE_HANDLE, $out, length($out)); close($FILE_HANDLE); undef($FILE_HANDLE);

  # If this is our Table of Contents, we extract all the links it has for
  # our 'nodes' reference id database.
  if($file eq "toc.html") { processToc($out); }
  return($out);
}


sub processToc {
  my($in) = @_;

  study($in);
  while($in =~ /(<a\s+[^>]*href="([^"]*)"[^>]*>([^<]*)<\/a>)/sgi) {
    my($match, $href, $body) = ($1, $2, $3);
    $href =~ /^([^#]*)(?:#?)(.*)$/;
    my($file, $anchor) = ($1, $2);
#    if(defined($xrefs{'file'}{$file})) { next; }
    $file =~ /(.*?)\/?([^\/]+)$/;
    my ($nodePath, $nodeFile, $filePath) = ($1, $2, (($1 eq '') ? $2 : "$1/$2"));
    $sqlInsertNodeName->execute($docset, $nodePath, $nodeFile, $anchor eq "" ? undef : $anchor, $body, "$filePath" . (($anchor eq "") ? '' : "#$anchor"));
  }
}


sub extractLinks {
  my($text) = @_;
  my %links;
  #while ($text =~ /\@link\s(.*?)\s(.*?)\s?\@\/link/sg) { my ($x, $y) = ($1, $1); $y =~ s?//apple_ref/\w+/\w+/(\w+)(\?:/.*)\??$1?; $links{$x} = $y; }
  while ($text =~ /\@link\s+([^\s]+)\s+(.*?)\s?\@\/link/sg) { my ($x, $y) = ($1, $1); $y =~ s?//apple_ref/\w+/\w+/(\w+)(\?:/.*)\??\Q$1\E?; $links{$x} = $y; }
  return(%links);
}

# Turns headerdoc @link @/link into <a href> </a> links where possible.
sub replaceLinks {
  my($text) = ($_[0], $_[1]);
  my(%links) = extractLinks($text);
  my @link_keys = keys %links;
  
  for my $atLink (sort keys %links) {
    if ($no_link{$links{$atLink}}) {
      $text =~ s/\@link\s+\Q$atLink\E\s+(.*?)\s?\@\/link/{
        my $x=$1;
        if($x !~ ?(\?i)<span class=\"code\">(.*\?)<\/span>?) { $x="<code>$x<\/code>"; }
        $x
      }/sge;
    } else {
      if (defined($global_xtoc_cache{'xref'}->{$links{$atLink}}{'href'})) {
        $text =~ s/\@link\s+\Q$atLink\E\s+(.*?)\s?\@\/link/{
          my $x = $1;
          my $linkClass = defined($global_xtoc_cache{'xref'}->{$links{$atLink}}{'class'}) ? $global_xtoc_cache{'xref'}->{$links{$atLink}}{'class'} : "";
          my $classText = $linkClass ne "" ? " class=\"$linkClass\"" : "";
          $x =~ s?<span class=\"$linkClass\">(.*\?)<\/span>?$1?sg;
          $x = "<a href=\"$global_xtoc_cache{'xref'}->{$links{$atLink}}{'apple_href'}\">$x<\/a>"
        }/sge;
      } else {
        $text =~ s/\@link\s+\Q$atLink\E\s+(.*?)\s?\@\/link/$1/sg;
      }
    }
  }
  return($text);
}

sub common_token {
  my ($sp, $th) = @_;
  my($token, $header) = ("", $global_xtoc_cache{'headers'}[$th->{header}]{'fileName'});
  if(defined($th->{addRefID})) {
    my $file = $global_xtoc_cache{'xref'}{$th->{addRefID}}{'file'};
    $th->{refid} = $libraryHash{$file} = $nodeRefHash{$file};
  }

                                    $token .= $sp . "<Token>\n";
                                    $token .= $sp . "  <TokenIdentifier>" . $th->{apple_ref} . "</TokenIdentifier>\n";
  if(defined($th->{declaration})) { $token .= $sp . "  <Declaration type=\"html\">" . encode_entities("<pre>$th->{declaration}</pre>") . "</Declaration>\n"; }
  if(defined($th->{abstract}))    { $token .= $sp . "  <Abstract type=\"html\">" . simpleHTML($th->{abstract}) . "</Abstract>\n"; }
  if(defined($th->{header}))      { $token .= $sp . "  <DeclaredIn>\n";
                                    $token .= $sp . "    <HeaderPath>RegexKit.framework/Headers/$header</HeaderPath>\n";
                                    $token .= $sp . "    <FrameworkName>RegexKit</FrameworkName>\n";
                                    $token .= $sp . "  </DeclaredIn>\n"; }
  if(defined($th->{avail}))       { $token .= $sp . "  <Availability distribution=\"RegexKit\">\n";
    if(defined($th->{avail}->{i32})){ $token .= $sp . "    <IntroducedInVersion bitsize=\"32\">" . $th->{avail}->{i32} . "</IntroducedInVersion>\n"; }
    if(defined($th->{avail}->{i64})){ $token .= $sp . "    <IntroducedInVersion bitsize=\"64\">" . $th->{avail}->{i64} . "</IntroducedInVersion>\n"; }
    if(defined($th->{avail}->{d32})){ $token .= $sp . "    <DeprecatedInVersion bitsize=\"32\">" . $th->{avail}->{d32} . "</DeprecatedInVersion>\n"; }
    if(defined($th->{avail}->{d64})){ $token .= $sp . "    <DeprecatedInVersion bitsize=\"64\">" . $th->{avail}->{d64} . "</DeprecatedInVersion>\n"; }
    if(defined($th->{avail}->{ds})) { $token .= $sp . "    <DeprecationSummary type=\"html\">"   . $th->{avail}->{ds}  . "</DeprecationSummary>\n"; }
    if(defined($th->{avail}->{r32})){ $token .= $sp . "    <RemovedAfterVersion bitsize=\"32\">" . $th->{avail}->{r32} . "</RemovedAfterVersion>\n"; }
    if(defined($th->{avail}->{r64})){ $token .= $sp . "    <RemovedAfterVersion bitsize=\"64\">" . $th->{avail}->{r64} . "</RemovedAfterVersion>\n"; }
                                    $token .= $sp . "  </Availability>\n"; }
  if(defined($th->{refid}))       { $token .= $sp . "  <NodeRef refid=\"$th->{refid}\" />\n"; }
  $token .= seealso_tokens($sp . "  ", $th->{hdcid});
  if(defined($th->{path}))        { $token .= $sp . "  <Path>" . $th->{path} . "</Path>\n"; }
  if(defined($th->{anchor}))      { $token .= $sp . "  <Anchor>" . $th->{anchor} . "</Anchor>\n"; }
                                    $token .= $sp . "</Token>\n";
  
  return($token);
}

sub typedef_token {
  my $sp = shift(@_);
  my $tdeid = shift(@_);
  
  if(defined($global_xtoc_cache{'typedefs'}[$tdeid])) {
    my $row = $global_xtoc_cache{'typedefs'}[$tdeid]; 
    my ($token, $tags, $hdcid, $hid, $name, @enums) = ("", $global_xtoc_cache{'tags'}[$row->{'hdcid'}], $row->{'hdcid'}, $row->{'hid'}, $row->{'name'}, @{$global_xtoc_cache{'enums'}[$row->{'tdeid'}]});
    my $xref = $global_xtoc_cache{'xhdcid'}->{$row->{'hdcid'}}; my $avail = $global_xtoc_cache{'avail'}->{$xref->{'tbl'}}[$xref->{'id'}]; 
    
    $token .= common_token($sp, {apple_ref => $apple_ref{$row->{'name'}}, hdcid => $hdcid, declaration => $row->{'name'}, header => $hid, addRefID => $name, abstract => $tags->{'abstract'}, avail => $avail, anchor => $apple_ref{$row->{'name'}}});
    
    for my $e (@enums) { my $xref = $global_xtoc_cache{'xhdcid'}->{$row->{'hdcid'}}; my $avail = $global_xtoc_cache{'avail'}->{$xref->{'tbl'}}[$xref->{'id'}]; my $id = $e->{'identifier'}; my $ar = $apple_ref{$id}; $token .= common_token($sp, {apple_ref => $ar, declaration => $id, header => $hid, addRefID => $name, abstract => $e->{'tagText'}, avail => $avail, anchor => $ar}); }
    return($token);
  }
}  


sub seealso_tokens {
  my $sp = shift(@_);
  my $hdcid = shift(@_);
  if(!defined($hdcid)) { return(""); }
  my $tags = $global_xtoc_cache{'tags'}[$hdcid];

  my $token = "";
  if (defined($tags->{'seealso'})) {
    my(@related_tokens, @related_documents, @related_sourcecode);
    for my $s (@{$tags->{'seealso'}}) {
      my(%links) = extractLinks($s);

      for my $atLink (sort keys %links) { if (defined($apple_ref{$links{$atLink}})) { push(@related_tokens, $sp . "  <TokenIdentifier>" . $apple_ref{$links{$atLink}} . "</TokenIdentifier>"); } }
      if($s =~ /<a\s+[^>]*href="([^\"]*)"[^>]*>(.*)<\/a>/si) {
        my ($href, $name) = ($1, $2);
        if($href !~ /^http:/) {
          my ($row) = $dbh->selectrow_hashref($sqlSelectRefID, {MaxRows => 1}, ($docset, $href, $name));
          if ($row) { $nodeRefHash{$href} = $row->{'refid'}; }
          if (defined($nodeRefHash{$href})) { push(@related_documents, $sp . '  <NodeRef refid="' . $nodeRefHash{$href} . '" />'); $libraryHash{$href} = $nodeRefHash{$href}; }
        }
      }
    }
    if($#related_tokens > -1)    { $token .= $sp . "<RelatedTokens>\n"    . join("\n", @related_tokens)    . "\n" . $sp ."</RelatedTokens>\n";    }
    if($#related_documents > -1) { $token .= $sp . "<RelatedDocuments>\n" . join("\n", @related_documents) . "\n" . $sp ."</RelatedDocuments>\n"; }
  }
  return($token);
}


sub stripExcess {
  my($strip) = shift(@_);

  $strip = stripBoxes($strip);
  $strip =~ s/\@link .*? (.*?)\s?\@\/link/$1/sg;
  $strip =~ s/<[^>]*>//gs;
  $strip =~ s/\n//gs;
  
  $strip = encode_entities($strip);
  
  return($strip);
}

sub stripBoxes {
  my($strip) = shift(@_);

  $strip =~ s/<div\s+[^>]*\bclass="[^\"]*\bbox\b[^\"]*"[^>]*>.*(?:<\/div>\s*){4}//sg;
  
  return($strip);
}

sub simpleHTML {
  my $html = shift(@_);

  $html = stripBoxes($html);
  $html = replaceLinks($html);
  $html =~ s/<span class="(?:nobr)">(.*?)<\/span>/$1/sig;
  $html =~ s/<span class="[^"]*\b(?:code|regex)\b[^"]*">(.*?)<\/span>/<code>$1<\/code>/sig;
  $html =~ s/<span class="[^"]*\b(?:argument)\b[^"]*">(.*?)<\/span>/<i>$1<\/i>/sig;
  $html = encode_entities($html);

  return($html);
}

# This takes a function or method 'pretty text' definition and scans it to
# see if we have links for whatever.. So, (RKRegex *) becomes something like
# (<a href="RKRegex.html">RKRegex</a> *)
sub addLinks {
  my $pretty = shift(@_);
  $pretty =~ s/(\((.*?)\))/{my ($full, $mid) = ($1, $2); $mid =~ s?(\S+)?if(defined($global_xtoc_cache{'xref'}{$1}{'apple_href'})) { "<a href=\"$global_xtoc_cache{'xref'}{$1}{'apple_href'}\">$1<\/a>" } else { $1 }?sge; "($mid)"} /sge;
  return($pretty);
}

# inhales large portions of the documentation database and stuffs it in to
# various hashes.  This is taken wholesale from the html doc generation script
# and could stand to be cleaned up a bit.

sub gen_xtoc_cache {
  my (%cache);
  
  for my $row (selectall_hash($dbh, "SELECT DISTINCT xref, linkId, href, apple_ref, file, hdcid, tbl, id FROM t_xtoc WHERE xref IS NOT NULL AND linkId IS NOT NULL AND href IS NOT NULL")) {
    $cache{'xref'}->{$row->{'xref'}}{'linkId'} = $row->{'linkId'};
    $cache{'xref'}->{$row->{'xref'}}{'href'} = $row->{'href'};
    $cache{'xref'}->{$row->{'xref'}}{'apple_ref'} = $row->{'apple_ref'};
    $cache{'xref'}->{$row->{'xref'}}{'apple_href'} = $row->{'file'} . '#' . $row->{'apple_ref'};
    $cache{'xref'}->{$row->{'xref'}}{'file'} = $row->{'file'};
    $cache{'xref'}->{$row->{'xref'}}{'tbl'} = $row->{'tbl'};
    $cache{'xref'}->{$row->{'xref'}}{'id'} = $row->{'id'};
    $cache{'xref'}->{$row->{'xref'}}{'class'} = "code";
    $cache{'xhdcid'}->{$row->{'hdcid'}} = {'tbl' => $row->{'tbl'}, 'id' => $row->{'id'}};
    
    $apple_ref{$row->{'xref'}} = $row->{'apple_ref'};
  }

  for my $row (selectall_hash($dbh, "SELECT DISTINCT xref, class, href  FROM xrefs WHERE href IS NOT NULL")) {
    $cache{'xref'}->{$row->{'xref'}}{'href'} = $row->{'href'};
    $cache{'xref'}->{$row->{'xref'}}{'class'} = $row->{'class'};
   }
  
  for my $row (selectall_hash($dbh, "SELECT DISTINCT tbl, idCol, id, hdtype, tocName, groupName, pos, linkId, apple_ref, href, titleText, linkText, file FROM t_xtoc WHERE tocName IS NOT NULL AND pos IS NOT NULL AND id IS NOT NULL AND href IS NOT NULL AND linkText IS NOT NULL ORDER BY pos, linkText")) {
    if(defined($row->{'groupName'})) { $cache{'toc'}{'tocGroups'}{$row->{'tocName'}}[$row->{'pos'} - 1] = $row->{'groupName'}; }
    if(defined($row->{'file'}))      { $cache{'toc'}{$row->{'tocName'}}{'file'} = $row->{'file'}; }
    my $entry = {'table' => $row->{'tbl'}, 'idColumn' => $row->{'idCol'}, 'id' => $row->{'id'}, 'type' => $row->{'hdtype'}, 'href' => $row->{'href'}, 'linkId' => $row->{'linkId'}, 'apple_ref' => $row->{'apple_ref'}, 'linkText' => $row->{'linkText'}};
    if(defined($row->{'titleText'})) { $entry->{'titleText'} = stripExcess($row->{'titleText'}); }
    push(@{$cache{'toc'}{'groupEntries'}{$row->{'tocName'}}[$row->{'pos'} - 1]}, $entry);
  }
  
  for my $row (selectall_hash($dbh, "SELECT DISTINCT tbl, idCol, id, hdtype, tocName, linkId, apple_ref, href, linkText, file, titleText, hdcid FROM t_xtoc WHERE tocName IS NOT NULL AND pos IS NOT NULL AND id IS NOT NULL AND href IS NOT NULL AND linkText IS NOT NULL ORDER BY linkText")) {
    push(@{$cache{'toc'}{'contentsForToc'}{$row->{'tocName'}}}, {'table' => $row->{'tbl'}, 'idColumn' => $row->{'idCol'}, 'id' => $row->{'id'}, 'type' => $row->{'hdtype'}, 'href' => $row->{'href'}, 'linkId' => $row->{'linkId'},'apple_ref' => $row->{'apple_ref'}, 'linkText' => $row->{'linkText'}, file => $row->{file}, titleText => $row->{titleText}, hdcid => $row->{hdcid}});
  }

  for my $row (selectall_hash($dbh, "SELECT * FROM v_hd_tags ORDER BY hdcid, tpos")) {
    my $p = defined($row->{'arg1'}) ? [$row->{'arg0'}, $row->{'arg1'}] : $row->{'arg0'};
    if($row->{'multiple'} == 0) { $cache{'tags'}[$row->{'hdcid'}]{$row->{'keyword'}} = $p; }
    else { push(@{$cache{'tags'}[$row->{'hdcid'}]{$row->{'keyword'}}}, $p); }
  }

  for my $row (selectall_hash($dbh, "SELECT ocm.*, occ.class AS class FROM objCMethods AS ocm JOIN objCClass AS occ ON ocm.occlid = occ.occlid WHERE ocm.hdcid IS NOT NULL")) { $cache{'methods'}[$row->{'ocmid'}] = $row; }
  for my $row (selectall_hash($dbh, "SELECT * FROM prototypes WHERE hdcid IS NOT NULL")) { $cache{'functions'}[$row->{'pid'}] = $row; }
  for my $row (selectall_hash($dbh, "SELECT * FROM typedefEnum WHERE hdcid IS NOT NULL")) { $cache{'typedefs'}[$row->{'tdeid'}] = $row; }
  for my $row (selectall_hash($dbh, "SELECT e.*, vhd.arg1 AS tagText FROM enumIdentifier AS e JOIN v_hd_tags AS vhd ON vhd.hdcid = e.hdcid AND vhd.keyword = 'constant' AND vhd.arg0 = e.identifier WHERE e.hdcid IS NOT NULL ORDER BY tdeid, position")) { $cache{'enums'}[$row->{'tdeid'}][$row->{'position'}] = $row; }
  for my $row (selectall_hash($dbh, "SELECT * FROM constant WHERE hdcid IS NOT NULL ORDER BY name")) { push(@{$cache{'constants'}}, $row); }  
  for my $row (selectall_hash($dbh, "SELECT * FROM define WHERE hdcid IS NOT NULL ORDER BY defineName")) { push(@{$cache{'defines'}}, $row); }
  for my $row (selectall_hash($dbh, "SELECT * FROM define WHERE hdcid IN (SELECT hdcid FROM t_xtoc WHERE tocName = 'Constants' AND groupName = 'Constants') ORDER BY defineName")) { push(@{$cache{'constantDefines'}}, $row); }
  for my $row (selectall_hash($dbh, "SELECT * FROM define WHERE hdcid IN (SELECT hdcid FROM t_xtoc WHERE tocName = 'Constants' AND groupName = 'Preprocessor Macros') AND cppText IS NOT NULL ORDER BY defineName")) { push(@{$cache{'preprocessorDefines'}}, $row); }
  for my $row (selectall_hash($dbh, "SELECT * FROM headers")) { $cache{'headers'}[$row->{'hid'}] = $row; }

  for my $row (selectall_hash($dbh, "SELECT * FROM v_versionXRef")) {
    $cache{'avail'}->{$row->{'tbl'}}[$row->{'id'}]->{"i$row->{'bitSize'}"} = $row->{'intro'};
    if(defined($row->{'dvid'})) { $cache{'avail'}->{$row->{'tbl'}}[$row->{'id'}]->{"d$row->{'bitSize'}"} = $row->{'depre'}; }
    if(defined($row->{'rvid'})) { $cache{'avail'}->{$row->{'tbl'}}[$row->{'id'}]->{"r$row->{'bitSize'}"} = $row->{'removed'}; }
    if(defined($row->{'deprecatedSummary'})) { $cache{'avail'}->{$row->{'tbl'}}[$row->{'id'}]->{'ds'} = $row->{'deprecatedSummary'}; }
  }
  
  return(%cache);
}


sub selectall_hash {
  my($dbh, $stmt, @args, @results) = (shift(@_), shift(@_), @_);
  my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, undef) or return;
  $sth->execute(@args) or return;
  while (my $row = $sth->fetchrow_hashref) { push(@results, $row); }
  $sth->finish;
  return(@results);
}
