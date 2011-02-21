#!/usr/bin/perl -w

use strict;
use DBI;
require DBD::SQLite;
use Data::Dumper;
use HTML::Entities;
#use POSIX;
#use IO::Handle;
#STDERR->autoflush(1);
#BEGIN { $diagnostics::PRETTY = 1 }
#use diagnostics;

my ($program_name, $script_name) = ($0, (defined($ENV{"SCRIPT_NAME"}) && defined($ENV{"SCRIPT_LINENO"})) ? "$ENV{'SCRIPT_NAME'}:$ENV{'SCRIPT_LINENO'}" : "");
$program_name =~ s/(.*?)\/?([^\/]+)$/$2/;

for my $env (qw(DOCUMENTATION_SQL_DATABASE_FILE GENERATED_HTML_DIR DOCUMENTATION_TEMPLATES_DIR)) {
  if(!defined($ENV{$env}))  { print("${script_name} error: $program_name: Environment variable $env not set.\n"); exit(1); }
}

my $dbh = DBI->connect("dbi:SQLite:dbname=$ENV{'DOCUMENTATION_SQL_DATABASE_FILE'}","","", { AutoCommit => 1, RaiseError => 1 });

$dbh->do("PRAGMA synchronous = OFF");
$dbh->do("ANALYZE");

$dbh->begin_work;

my %no_link;
for my $row (selectall_hash($dbh, "SELECT DISTINCT xref FROM xrefs WHERE href IS NULL")) { $no_link{$row->{'xref'}} = 1; }

print("Loading data...\n");

#$dbh->do("CREATE TEMP TABLE t_xtoc AS SELECT * FROM v_xtoc");
#print("Temp table built\n");

my %global_xtoc_cache = gen_xtoc_cache();
my (@rows, %toc, %tasks, %hdoc, %hdocFiles);
populate_tasks_html();
populate_const_html();

print("Creating toc.html\n");
create_toc_html();



for my $tocName (keys %{$global_xtoc_cache{'toc'}{'contentsForToc'}}) {
  if(!exists($hdoc{$tocName}{'printedClassMethods'})) { $hdoc{$tocName}{'printedClassMethods'} = 0; }
  if(!exists($hdoc{$tocName}{'printedInstanceMethods'})) { $hdoc{$tocName}{'printedInstanceMethods'} = 0; }
  
  for my $tx (0 .. $#{$global_xtoc_cache{'toc'}{'contentsForToc'}{$tocName}}) {
    my $at = $global_xtoc_cache{'toc'}{'contentsForToc'}{$tocName}[$tx];
    if($at->{'table'} eq "objCMethods") {
      if(!defined($hdoc{$tocName}{'methods'})) { $hdoc{$tocName}{'methods'} = ""; }

      if($hdoc{$tocName}{'printedClassMethods'} == 0 && $at->{'linkText'} =~ /^\+/) {
        $hdoc{$tocName}{'printedClassMethods'} = 1;
        $hdoc{$tocName}{'methods'} .= "\n<h2>Class Methods</h2>\n\n";
      } elsif($hdoc{$tocName}{'printedInstanceMethods'} == 0 && $at->{'linkText'} =~ /^\-/) {
        $hdoc{$tocName}{'printedInstanceMethods'} = 1;
        $hdoc{$tocName}{'methods'} .= "\n<h2>Instance Methods</h2>\n\n";
      }
      $hdoc{$tocName}{'methods'} .= meth_html($at->{'id'});
    } elsif($at->{'table'} eq "prototypes") {
      if(!exists($hdoc{$tocName}{'functions'})) { $hdoc{$tocName}{'functions'} = ""; }
      $hdoc{$tocName}{'functions'} .= func_html($at->{'id'});
    } elsif($at->{'table'} eq "typedefEnum") {
      if(!exists($hdoc{$tocName}{'typedefs'})) { $hdoc{$tocName}{'typedefs'} = ""; }
      $hdoc{$tocName}{'typedefs'} .= typedef_html($at->{'id'});
    }
  }
}

for my $atTocTemplate (keys %{$global_xtoc_cache{'toc'}{'contentsForToc'}}) {
  my ($tocTmplFilename, $tocHtmlFilename, $HDOC_OUTPUT, $HDOC_TMPL, $hdoc_tmpl);
  $tocTmplFilename = "$atTocTemplate.tmpl";
  $tocHtmlFilename = "$atTocTemplate.html";
  
  if (!(-e "$ENV{'DOCUMENTATION_TEMPLATES_DIR'}/$tocTmplFilename")) { printf("warning: The expected template '$tocTmplFilename' does not exist, skipping.\n"); next; }
  print("Creating $tocHtmlFilename\n");
  
  open($HDOC_TMPL, "<", "$ENV{'DOCUMENTATION_TEMPLATES_DIR'}/$tocTmplFilename"); read($HDOC_TMPL, $hdoc_tmpl, (stat($HDOC_TMPL))[7]); close($HDOC_TMPL);
  
  if ($hdoc_tmpl !~ /\n$/s) { $hdoc_tmpl .= "\n"; }
  $hdoc_tmpl =~ s/((?<!\\)[\%\$\@])/\\\\$1/g;
  $hdoc_tmpl =~ s/(\\?)\\([\%\$\@])/$1$2/g;
  
  my ($evald_hdoc, $in_eval_hdoc)  = ("", '$evald_hdoc = <<END_OF_HDOC_TMPL;' . "\n" . $hdoc_tmpl . "END_OF_HDOC_TMPL\n");
  eval($in_eval_hdoc);
  $evald_hdoc = replaceLinks($evald_hdoc, $atTocTemplate);
  
  open($HDOC_OUTPUT, ">", "$ENV{'GENERATED_HTML_DIR'}/$tocHtmlFilename"); print($HDOC_OUTPUT $evald_hdoc); close($HDOC_OUTPUT);
}

$dbh->commit;

$dbh->disconnect();
exit(0);


sub extractLinks {
  my($text) = @_;
  my %links;
  while ($text =~ /\@link\s+([^\s]+)\s+(.*?)\s?\@\/link/sg) { my ($x, $y) = ($1, $1); $y =~ s?//apple_ref/\w+/\w+/(\w+)(\?:/.*)\??\Q$1\E?; $links{$x} = $y; }
  return(%links);
}

sub replaceLinks {
  my($text, $className) = ($_[0], $_[1]);
  my(%links) = extractLinks($text);

  #print(Dumper(%links));
  
  for my $atLink (sort keys %links) {
    if ($no_link{$links{$atLink}} || $links{$atLink} eq $className) {
      $text =~ s/\@link\s+\Q$atLink\E\s+(.*?)\s?\@\/link/{
        my $x=$1;
        if($x !~ ?(\?i)<span class=\"code\">(.*\?)<\/span>?) { $x="<span class=\"code\">$x<\/span>"; }
        $x
      }/sge;
    } else {
      if (defined($global_xtoc_cache{'xref'}->{$links{$atLink}}{'href'})) {
        $text =~ s/\@link\s+\Q$atLink\E\s+(.*?)\s?\@\/link/{
          my $x = $1;
          my $linkClass = defined($global_xtoc_cache{'xref'}->{$links{$atLink}}{'class'}) ? $global_xtoc_cache{'xref'}->{$links{$atLink}}{'class'} : "";
          my $classText = $linkClass ne "" ? " class=\"$linkClass\"" : "";
          $x =~ s?<span class=\"$linkClass\">(.*\?)<\/span>?$1?sg;
          $x = "<a href=\"$global_xtoc_cache{'xref'}->{$links{$atLink}}{'href'}\"$classText>$x<\/a>"
        }/sge;
      } else {
        $text =~ s/\@link\s+\Q$atLink\E\s+(.*?)\s?\@\/link/<span class="XXX code">$1<\/span>/sg;
      }
    }
  }
  return($text);
}


sub populate_const_html {
  my (%const_html, %html, %declaredIn);

  for my $tx (0 .. $#{$global_xtoc_cache{'toc'}{'contentsForToc'}{'Constants'}}) {
    my $at = $global_xtoc_cache{'toc'}{'contentsForToc'}{'Constants'}[$tx];
    my ($row, $groupName) = ($global_xtoc_cache{'tables'}{$at->{'table'}}[$at->{'hdcid'}], $at->{'groupName'});
    my ($hdcid, $tags) = ($row->{'hdcid'}, $global_xtoc_cache{'tags'}[$row->{'hdcid'}]);
    my $name = ($at->{'table'} eq 'constant') ? 'name' : 'defineName';
    
    if(!exists($html{$groupName})) { $html{$groupName} = ""; }
    if(!exists($const_html{$groupName})) { $const_html{$groupName} = ""; }
    
    if($groupName eq 'Preprocessor Macros') {
      my $signature_html = "  <div class=\"signature\">$row->{'cppText'}</div>\n";
      $html{$groupName} .= "<div class=\"macro\">\n  <div class=\"name\"><a name=\"$global_xtoc_cache{'xref'}{$row->{$name}}{'linkId'}\">$row->{$name}</a></div>\n";
      
      $html{$groupName} .= common_html($signature_html, $hdcid);
      $html{$groupName} .= "  <div class=\"declared_in\"><div class=\"header\">Declared In</div>\n    <div class=\"file\">$global_xtoc_cache{'headers'}[$row->{'hid'}]{'fileName'}</div>\n  </div>\n";
      $html{$groupName} .= "</div>\n\n";
    } else {
      $html{$groupName} .= "    <div class=\"row\"><div class=\"name cell\">" . add_xref($row->{'fullText'}) . "</div></div>\n";
      $const_html{$groupName} .= "  <div class=\"constant\">\n";
      $const_html{$groupName} .= "    <div class=\"identifier\"><a name=\"$global_xtoc_cache{'xref'}{$row->{$name}}{'linkId'}\">$row->{$name}</a></div>\n";
      $const_html{$groupName} .= "    <div class=\"text\">$tags->{'abstract'}</div>\n";
      if (defined($tags->{'seealso'})) {
        my(@seealso_html);
        for my $s (@{$tags->{'seealso'}}) { push(@seealso_html, "      <li>".$s."</li>"); }
        $const_html{$groupName} .= "  <div class=\"seealso\"><div class=\"header\">See Also</div>\n    <ul>\n" . join("\n", @seealso_html) . "\n    </ul>\n  </div>\n";
      }
      $const_html{$groupName} .= "  </div>\n";
      $declaredIn{$groupName} = $global_xtoc_cache{'headers'}[$row->{'hid'}]{'fileName'};
    }
  }
  
  $hdoc{'AllConstants'} = "";

  for my $tx (0 .. $#{$global_xtoc_cache{'toc'}{'tocGroups'}{'Constants'}}) {
    my $groupName = $global_xtoc_cache{'toc'}{'tocGroups'}{'Constants'}[$tx];
    my $groupNameLinkId = $groupName;
    $groupNameLinkId =~ s/ /_/g;
    
    $hdoc{'AllConstants'} .= "<h2><a name=\"" . $groupNameLinkId . "\">" . $groupName . "</a></h2>\n\n";
    if($groupName eq 'Preprocessor Macros') {
      $hdoc{'AllConstants'} .= $html{$groupName};
    } else {
      $hdoc{'AllConstants'} .= "<div class=\"constants\">\n";
      $hdoc{'AllConstants'} .= "  <div class=\"declaration table\">\n";
      $hdoc{'AllConstants'} .= $html{$groupName};
      $hdoc{'AllConstants'} .= "  </div>\n";
      $hdoc{'AllConstants'} .= "  <div class=\"constants\"><div class=\"header\">Constants</div>\n" . $const_html{$groupName} . "  </div>\n";
      $hdoc{'AllConstants'} .= "  <div class=\"declared_in\"><div class=\"header\">Declared In</div>\n    <div class=\"file\">" . $declaredIn{$groupName} . "</div>\n  </div>\n";
      $hdoc{'AllConstants'} .= "</div>\n\n\n";
    }
  }
}

 

sub add_xref {
  my $xref = shift(@_);
#  $xref =~ s/<span class="code">(\w+)<\/span>/defined($global_xtoc_cache{'xref'}{$1}{'href'}) ? "<a href=\"$global_xtoc_cache{'xref'}{$1}{'href'}\"" . $global_xtoc_cache{'xref'}{$1}{'class'} ne "" ? "class=\"$global_xtoc_cache{'xref'}{$1}{'class'}\"" :"" . ">$1<\/a>" : $1/sge;
  $xref =~ s/<span class="code">(\w+)<\/span>/defined($global_xtoc_cache{'xref'}{$1}{'href'}) ? "<a href=\"$global_xtoc_cache{'xref'}{$1}{'href'}\" class=\"code\">$1<\/a>" : $1/sge;
  $xref =~ s/(\w+)/defined($global_xtoc_cache{'xref'}{$1}{'href'}) ? "<a href=\"$global_xtoc_cache{'xref'}{$1}{'href'}\" class=\"code\">$1<\/a>" : $1/sge;
  return($xref);
}


sub func_html {
  my $pid = shift(@_);
  my($html, $row, $signature_html) = ("");
  
  if(defined($global_xtoc_cache{'functions'}[$pid])) {
    my $row = $global_xtoc_cache{'functions'}[$pid]; 
    my ($pretty, $hdcid, $tags) = ($row->{'prettyText'}, $row->{'hdcid'}, $global_xtoc_cache{'tags'}[$row->{'hdcid'}]);
    $pretty =~ s/(\((.*?)\))/{my ($full, $mid) = ($1, $2); $mid =~ s?(\S+)?if(defined($global_xtoc_cache{'xref'}{$1}{'href'})) { "<a href=\"$global_xtoc_cache{'xref'}{$1}{'href'}\">$1<\/a>" } else { $1 }?sge; "($mid)"} /sge;
    $signature_html = "<div class=\"signature\">$pretty</div>\n";
    $html = "<div class=\"function\">\n<div class=\"name\"><a name=\"$global_xtoc_cache{'xref'}{$tags->{'function'}}{'linkId'}\">$tags->{'function'}</a></div>\n";
    $html .= common_html($signature_html, $hdcid);
    $html .= "</div>\n\n";
  }
    
  return($html);
}


sub meth_html {
  my $ocmid = shift(@_);
  my($html, $row, $signature_html) = ("");
  
  if(defined($global_xtoc_cache{'methods'}[$ocmid])) {
    my $row = $global_xtoc_cache{'methods'}[$ocmid]; 
    my ($pretty, $hdcid, $tags, $mxref) = ($row->{'prettyText'}, $row->{'hdcid'}, $global_xtoc_cache{'tags'}[$row->{'hdcid'}], "$row->{'class'}/$row->{'type'}$row->{'selector'}");
    
    $pretty =~ s/(\((.*?)\))/{my ($full, $mid) = ($1, $2); $mid =~ s?(\S+)?if(defined($global_xtoc_cache{'xref'}{$1}{'href'})) { "<a href=\"$global_xtoc_cache{'xref'}{$1}{'href'}\">$1<\/a>" } else { $1 }?sge; "($mid)"} /sge;
    $signature_html = "  <div class=\"signature\">$pretty</div>\n";

    $html = "<div class=\"method\">\n  <div class=\"name\"><a name=\"$global_xtoc_cache{'xref'}{$mxref}{'linkId'}\">$tags->{'method'}</a></div>\n";

    $html .= common_html($signature_html, $hdcid);
    $html .= "</div>\n\n";
  }
  
  return($html);
}

sub seealso_html {
  my($tags, $html, $seealso_html, @seealso) = (shift(@_), "");
  if (defined($tags->{'seealso'})) {
    $seealso_html = join("\n", map("      <li>".$_."</li>", @{$tags->{'seealso'}}));
    $html = <<END_HTML
  <div class="seealso"><div class="header">See Also</div>
    <ul>
$seealso_html
    </ul>
  </div>
END_HTML
  }
}
  
sub common_html {
  my $signature_html = shift(@_);
  my $hdcid = shift(@_);
  my($html, $tags, $row) = ("", $global_xtoc_cache{'tags'}[$hdcid]);
  
  if (defined($tags->{'abstract'})) { $html .= "  <div class=\"summary\">$tags->{'abstract'}</div>\n"; }
  if (defined($signature_html)) { $html .= $signature_html; }
  
  if (defined($tags->{'param'})) {
    my @param_html;
    for my $p (@{$tags->{'param'}}) {
      my($arg, $text, $extra) = (@{$p}[0], @{$p}[1], "");
      if ($text =~ /(.*?)\s*(<div.*)/s) { $extra = $2; $text = $1; if($extra !~ /\n\z/s) { $extra .= "\n"; } }
      push(@param_html, "      <li>\n        <div class=\"name\">$arg</div>\n        <div class=\"text\">$text</div>\n$extra\n      </li>");
    }
    $html .= "  <div class=\"parameters\"><div class=\"header\">Parameters</div>\n    <ul>\n" . join("\n", @param_html) . "\n    </ul>\n  </div>\n";
  }
  
  if(defined($tags->{'discussion'})) { $html .= "  <div class=\"discussion\"><div class=\"header\">Discussion</div>\n$tags->{'discussion'}\n  </div>\n"; }
  if(defined($tags->{'result'})) { $html .= "  <div class=\"result\"><div class=\"header\">Return Value</div>\n$tags->{'result'}\n  </div>\n"; }
  
  if (defined($tags->{'seealso'})) {
    my(@seealso_html);
    for my $s (@{$tags->{'seealso'}}) { push(@seealso_html, "      <li>".$s."</li>"); }
    $html .= "  <div class=\"seealso\"><div class=\"header\">See Also</div>\n    <ul>\n" . join("\n", @seealso_html) . "\n    </ul>\n  </div>\n";
  }
  
  return($html);
}

sub typedef_html {
  my $tdeid = shift(@_);

  if(defined($global_xtoc_cache{'typedefs'}[$tdeid])) {
    my $row = $global_xtoc_cache{'typedefs'}[$tdeid]; 
    my ($html, $tags, $hdcid, $const_html) = ("", $global_xtoc_cache{'tags'}[$row->{'hdcid'}], $row->{'hdcid'}, "");
    $html .= "<div class=\"typedef\">\n";
    $html .= "  <div class=\"name\"><a name=\"$global_xtoc_cache{'xref'}{$row->{'name'}}{'linkId'}\">$row->{'name'}</a></div>\n";
    if(defined($tags->{'abstract'})) { $html .= "  <div class=\"summary\">$tags->{'abstract'}</div>\n"; }
    
    $html .= "  <div class=\"declaration code table\">\n";
    $html .= "    <div class=\"top row\"><div class=\"cell\">typedef enum {</div></div>\n";
    
    for my $tderow (@{$global_xtoc_cache{'enums'}[$row->{'tdeid'}]}) {
      my $comma = ",";
      if($tderow == $global_xtoc_cache{'enums'}[$row->{'tdeid'}][$#{$global_xtoc_cache{'enums'}[$row->{'tdeid'}]}]) { $comma = ""; }
      $html .= "    <div class=\"enum row\">\n";
      $html .= "      <div class=\"identifier cell\"><a href=\"$global_xtoc_cache{'xref'}{$tderow->{'identifier'}}{'href'}\">$tderow->{'identifier'}</a></div>\n";
      $const_html .= "    <div class=\"constant\">\n";
      $const_html .= "      <div class=\"identifier\"><a name=\"$global_xtoc_cache{'xref'}{$tderow->{'identifier'}}{'linkId'}\">$tderow->{'identifier'}</a></div>\n";
      $const_html .= "      <div class=\"text\">$tderow->{'tagText'}</div>\n";
      $const_html .= "    </div>\n";
      $html .= "      <div class=\"equals cell\">=</div>\n";
      $html .= "      <div class=\"constant cell\">$tderow->{'constant'}$comma</div>\n";
      $html .= "    </div>\n";
      
    }
    $html .= "    <div class=\"bottom row\"><div class=\"cell\">} $row->{'name'};</div></div>\n";
    $html .= "  </div>\n\n";
    $html .= "  <div class=\"constants\"><div class=\"header\">Constants</div>\n" . $const_html . "  </div>\n";
    if(defined($row->{'discussion'})) { $html .= "  <div class=\"discussion\"><div class=\"header\">Discussion</div>$row->{'discussion'}</div>\n"; }
    $html .= "  <div class=\"declared_in\"><div class=\"header\">Declared In</div>\n    <div class=\"file\">$global_xtoc_cache{'headers'}[$row->{'hid'}]{'fileName'}</div>\n  </div>\n";
    $html .= "</div>\n\n";  
    return($html);
  }
}  

sub create_toc_html {
  populate_toc_html();
  
  my ($TOC_OUTPUT, $TOC_TMPL, $toc_tmpl);
  open($TOC_TMPL, "<", "$ENV{'DOCUMENTATION_TEMPLATES_DIR'}/toc.tmpl"); read($TOC_TMPL, $toc_tmpl, (stat($TOC_TMPL))[7]); close($TOC_TMPL);
  
  if ($toc_tmpl !~ /\n$/s) { $toc_tmpl .= "\n"; }
  $toc_tmpl =~ s/((?<!\\)[\%\$\@])/\\\\$1/g;
  $toc_tmpl =~ s/(\\?)\\([\%\$\@])/$1$2/g;
  my ($et, $etoc)  = ("", '$et = <<END_OF_TOC_TMPL;' . "\n" . $toc_tmpl . "END_OF_TOC_TMPL\n");
  eval($etoc);
  
  open($TOC_OUTPUT, ">", "$ENV{'GENERATED_HTML_DIR'}/toc.html"); print($TOC_OUTPUT $et); close($TOC_OUTPUT);
}  

sub populate_toc_html {
  for my $tocName (keys %{$global_xtoc_cache{'toc'}{'groupEntries'}}) {
    my $html = "";
    my (@tocArray) = (@{$global_xtoc_cache{'toc'}{'groupEntries'}{$tocName}});
    my $file = $global_xtoc_cache{'toc'}{$tocName}{'file'};

    my $sectionId = "tocID_$tocName";
    $sectionId =~ s/[^a-zA-Z0-9_\.\-]//sg;
    $html .= <<DIV_END;
  <div class="section closed" id="$sectionId">
    <div class="header">
      <span class="indicator large">&nbsp;</span>
      <span class="title"><a href="$file" target="doc">$tocName</a></span>
    </div>
    <div class="contents">
      <div class="entries">
DIV_END
        
    for my $tx (0 .. $#tocArray) {
      my $groupName = $global_xtoc_cache{'toc'}{'tocGroups'}{$tocName}[$tx];
      my $extraSpaces = "";
      if(defined($groupName)) {
        $extraSpaces = "      ";
        my $subSectionId = "tocID_${tocName}_${groupName}";
        $subSectionId =~ s/[^a-zA-Z0-9_\.\-]//sg;
        $html .= <<DIV_END;
        <div class="section closed sub" id="$subSectionId">
          <div class="header">
            <span class="indicator small">&nbsp;</span>
            <span class="title">$groupName</span>
          </div> 
          <div class="contents">
            <div class="entries">
DIV_END
      }
      for my $ex (0 .. $#{$global_xtoc_cache{'toc'}{'groupEntries'}{$tocName}[$tx]}) {
        my $at = $global_xtoc_cache{'toc'}{'groupEntries'}{$tocName}[$tx][$ex];
        $html .= "$extraSpaces        <div class=\"entry\"><a href=\"$at->{'href'}\" title=\"$at->{'titleText'}\" class=\"code\" target=\"doc\">$at->{'linkText'}</a></div>\n";
      }
          
      if(defined($groupName)) {
        $html .= <<DIV_END;
              </div>
            </div>
          </div>
DIV_END
      }
    }
    $html .= <<DIV_END;
        <span class="rightEdge"><img alt="Overflow fade" src="Images/grad_18_1.png"></span>
      </div>
    </div>
  </div>


DIV_END

    $toc{$tocName} = $html;
  }
}

sub populate_tasks_html {
  for my $tocName (keys %{$global_xtoc_cache{'toc'}{'groupEntries'}}) {
    my $html = "<h2>Tasks</h2>\n\n";
    my (@tocArray) = (@{$global_xtoc_cache{'toc'}{'groupEntries'}{$tocName}});

    for my $tx (0 .. $#tocArray) {
      my $groupName = $global_xtoc_cache{'toc'}{'tocGroups'}{$tocName}[$tx];
      $html .= "<div class=\"tasks\">\n";
      if(defined($groupName)) { $html .= "  <div class=\"header\">$groupName</div>\n"; }
      $html .= "  <ul>\n";
      for my $ex (0 .. $#{$global_xtoc_cache{'toc'}{'groupEntries'}{$tocName}[$tx]}) {
        my $at = $global_xtoc_cache{'toc'}{'groupEntries'}{$tocName}[$tx][$ex];
        $html .= "    <li><a href=\"$at->{'href'}\" title=\"$at->{'titleText'}\" class=\"code\">$at->{'linkText'}</a></li>\n";
      }
      $html .= "  </ul>\n";
      $html .= "</div>\n";
    }

    $hdoc{$tocName}{'tasks'} = $html;
  }
}

#sub stripExcess {
#  my($strip) = @_;
#  $strip =~ s/<div\s+[^>]*\bclass="[^\"]*\bbox\b[^\"]*"[^>]*>.*(?:<\/div>\s*){4}//sg;
#  $strip =~ s/\@link .*? (.*?)\s?\@\/link/$1/sg;
#  $strip =~ s/<[^>]+>(.*?)<\/[^>]+>/$1/sg;
#  $strip =~ s/\"/\\"/sg;
#  return($strip);
#}

sub stripExcess {
  my($strip) = @_;

  $strip =~ s/<div\s+[^>]*\bclass="[^\"]*\bbox\b[^\"]*"[^>]*>.*(?:<\/div>\s*){4}//sg;
  $strip =~ s/\@link .*? (.*?)\s?\@\/link/$1/sg;
  $strip =~ s/<[^>]*>//gs;
  $strip =~ s/\n//gs;
  
  $strip = encode_entities($strip);
  
  return($strip);
}

sub gen_xtoc_cache {
  my (%cache);
  
  for my $row (selectall_hash($dbh, "SELECT DISTINCT xref, linkId, href FROM t_xtoc WHERE xref IS NOT NULL AND linkId IS NOT NULL AND href IS NOT NULL")) {
    $cache{'xref'}->{$row->{'xref'}}{'linkId'} = $row->{'linkId'};
    $cache{'xref'}->{$row->{'xref'}}{'href'} = $row->{'href'};
    $cache{'xref'}->{$row->{'xref'}}{'class'} = "code";
  }

  for my $row (selectall_hash($dbh, "SELECT DISTINCT xref, class, href FROM xrefs WHERE href IS NOT NULL")) {
    $cache{'xref'}->{$row->{'xref'}}{'href'} = $row->{'href'};
    $cache{'xref'}->{$row->{'xref'}}{'class'} = $row->{'class'};
   }
  
  for my $row (selectall_hash($dbh, "SELECT DISTINCT tbl, idCol, id, hdtype, tocName, groupName, pos, linkId, href, titleText, linkText, file FROM t_xtoc WHERE tocName IS NOT NULL AND pos IS NOT NULL AND id IS NOT NULL AND href IS NOT NULL AND linkText IS NOT NULL ORDER BY pos, linkText")) {
    if(defined($row->{'groupName'})) { $cache{'toc'}{'tocGroups'}{$row->{'tocName'}}[$row->{'pos'} - 1] = $row->{'groupName'}; }
    if(defined($row->{'file'}))      { $cache{'toc'}{$row->{'tocName'}}{'file'} = $row->{'file'}; }
    my $entry = {'table' => $row->{'tbl'}, 'idColumn' => $row->{'idCol'}, 'id' => $row->{'id'}, 'type' => $row->{'hdtype'}, 'href' => $row->{'href'}, 'linkId' => $row->{'linkId'}, 'linkText' => $row->{'linkText'}};
    if(defined($row->{'titleText'})) { $entry->{'titleText'} = stripExcess($row->{'titleText'}); }
    push(@{$cache{'toc'}{'groupEntries'}{$row->{'tocName'}}[$row->{'pos'} - 1]}, $entry);
  }
  
  for my $row (selectall_hash($dbh, "SELECT DISTINCT tbl, idCol, id, hdcid, hdtype, tocName, groupName, linkId, href, linkText FROM t_xtoc WHERE tocName IS NOT NULL AND pos IS NOT NULL AND id IS NOT NULL AND href IS NOT NULL AND linkText IS NOT NULL ORDER BY linkText")) {
    push(@{$cache{'toc'}{'contentsForToc'}{$row->{'tocName'}}}, {'groupName' => $row->{'groupName'}, 'table' => $row->{'tbl'}, 'idColumn' => $row->{'idCol'}, 'id' => $row->{'id'}, 'hdcid' => $row->{'hdcid'}, 'type' => $row->{'hdtype'}, 'href' => $row->{'href'}, 'linkId' => $row->{'linkId'},'linkText' => $row->{'linkText'}});
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
  for my $row (selectall_hash($dbh, "SELECT * FROM constant WHERE hdcid IS NOT NULL ORDER BY name")) { push(@{$cache{'constants'}}, $row); $cache{'tables'}{'constant'}[$row->{'hdcid'}] = $row; }
  for my $row (selectall_hash($dbh, "SELECT * FROM define WHERE hdcid IS NOT NULL ORDER BY defineName")) { push(@{$cache{'defines'}}, $row); $cache{'tables'}{'define'}[$row->{'hdcid'}] = $row; }
  for my $row (selectall_hash($dbh, "SELECT * FROM define WHERE hdcid IN (SELECT hdcid FROM t_xtoc WHERE tocName = 'Constants' AND groupName = 'Constants') ORDER BY defineName")) { push(@{$cache{'constantDefines'}}, $row); }
  for my $row (selectall_hash($dbh, "SELECT * FROM define WHERE hdcid IN (SELECT hdcid FROM t_xtoc WHERE tocName = 'Constants' AND groupName = 'Preprocessor Macros') ORDER BY defineName")) { push(@{$cache{'preprocessorDefines'}}, $row); }
  for my $row (selectall_hash($dbh, "SELECT * FROM headers")) { $cache{'headers'}[$row->{'hid'}] = $row; }
  
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
