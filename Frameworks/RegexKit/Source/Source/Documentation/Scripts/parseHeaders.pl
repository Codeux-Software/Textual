#!/usr/bin/perl -w

use strict;
use DBI;
require DBD::SQLite;
use Cwd 'realpath';
use File::Basename;
use re 'eval';
#use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
$|=1;

#use Data::Dumper;
#use IO::Handle;
#STDERR->autoflush(1);
#BEGIN { $diagnostics::PRETTY = 1 }
#use diagnostics; 

#my ($seconds, $microseconds) = gettimeofday;
#my ($start_time) = ($seconds + ($microseconds/1000000.0));

my ($program_name, $script_name) = ($0, (defined($ENV{"SCRIPT_NAME"}) && defined($ENV{"SCRIPT_LINENO"})) ? "$ENV{'SCRIPT_NAME'}:$ENV{'SCRIPT_LINENO'}" : "");
$program_name =~ s/(.*?)\/?([^\/]+)$/$2/;

for my $env (qw(DOCUMENTATION_SQL_DATABASE_FILE)) {
  if (!defined($ENV{$env})) { print("${script_name} error: $program_name: Environment variable $env not set.\n"); exit(1); }
}


my ($dbh);
my ($keywordTKID, $keywordArguments, $tagKeywordRows, $keywordRegex, @keywordArray);
my ($preparedHeaderDocCommentsInsert, $preparedTagsInsert, $preparedTagArgumentsInsert, $preparedObjCMethodInsert, $preparedPrototypeInsert, $preparedFunctionInsert, $preparedHeaderSelect, $preparedHeaderInsert, $preparedTypedefEnumInsert, $preparedEnumIdentifierInsert, $preparedObjCClass, $preparedObjCClassCategory, $preparedObjCClassDefinition, $preparedClassIDSelect);

$dbh = DBI->connect("dbi:SQLite:dbname=$ENV{'DOCUMENTATION_SQL_DATABASE_FILE'}","","", { AutoCommit => 1, RaiseError => 1 });

$dbh->do("PRAGMA synchronous = OFF");
$dbh->do("ANALYZE");

$dbh->begin_work;

$tagKeywordRows = $dbh->selectall_arrayref("SELECT tkid, keyword, arguments FROM tagKeywords ORDER BY keyword");
foreach my $row (@$tagKeywordRows) { $keywordTKID->{"@$row[1]"} = @$row[0]; $keywordArguments->{"@$row[1]"} = @$row[2]; push(@keywordArray, @$row[1]); }
$keywordRegex = '\@((?i)' . join("|", @keywordArray) . ')\b';

$preparedClassIDSelect = $dbh->prepare("SELECT occlid FROM objCClass WHERE class = ?");
$preparedObjCClass = $dbh->prepare("INSERT OR IGNORE INTO objCClass (class) VALUES (?);");

$dbh->func( 'classid', 1,
            sub {
              my ($className) = @_;
              my ($row) = ($dbh->selectrow_hashref($preparedClassIDSelect, {MaxRows => 1}, ($className)));
              if ($row) { return($row->{'occlid'}); }
              $preparedObjCClass->execute($className);
              $row = $dbh->selectrow_hashref($preparedClassIDSelect, {MaxRows => 1}, ($className));
              if ($row) { return($row->{'occlid'}); } else { return(undef); }
            }, 'create_function' );

$preparedHeaderDocCommentsInsert = $dbh->prepare("INSERT OR IGNORE INTO headerDocComments (hid, startsAt, length) VALUES (?, ?, ?)");
$preparedTagsInsert = $dbh->prepare("INSERT OR IGNORE INTO tags (tkid, hdcid, position) VALUES (?, ?, ?)");
$preparedTagArgumentsInsert = $dbh->prepare("INSERT OR IGNORE INTO tagArguments (tid, argument, argText) VALUES (?, ?, ?)");
$preparedObjCMethodInsert = $dbh->prepare("INSERT OR IGNORE INTO objcmethods (hid, startsAt, length, type, fullText, prettyText, signature, selector) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
$preparedPrototypeInsert = $dbh->prepare("INSERT OR IGNORE INTO prototypes (hid, startsAt, length, fullText, prettyText, signature, sym) VALUES (?, ?, ?, ?, ?, ?, ?)");
$preparedFunctionInsert = $dbh->prepare("INSERT OR IGNORE INTO functions (hid, startsAt, length, fullText, prettyText, signature, sym) VALUES (?, ?, ?, ?, ?, ?, ?)");
$preparedHeaderSelect = $dbh->prepare("SELECT * FROM headers WHERE path = ? AND fileName = ?");
$preparedHeaderInsert = $dbh->prepare("INSERT OR IGNORE INTO headers (path, fileName, size, modified) VALUES (?, ?, ?, ?)");
$preparedTypedefEnumInsert = $dbh->prepare("INSERT OR IGNORE INTO typedefEnum (hid, startsAt, length, position, fullText, name, enumText) VALUES (?, ?, ?, ?, ?, ?, ?)");
$preparedEnumIdentifierInsert = $dbh->prepare("INSERT OR IGNORE INTO enumIdentifier (tdeid, startsAt, length, position, fullText, identifier, constant) VALUES (?, ?, ?, ?, ?, ?, ?)");
$preparedObjCClass = $dbh->prepare("INSERT OR IGNORE INTO objCClass (class) VALUES (?);");
$preparedObjCClassCategory = $dbh->prepare("INSERT INTO objCClassCategory (hid, occlid, startsAt, length, category, protocols, methodsStart, methodsLength) VALUES (?, classid(?), ?, ?, ?, ?, ?, ?)");

$preparedObjCClassDefinition = $dbh->prepare("INSERT INTO objCClassDefinition (hid, occlid, scclid, startsAt, length, protocols, ivars, methodsStart, methodsLength) VALUES (?, classid(?), classid(?), ?, ?, ?, ?, ?, ?)");
my $preparedConstantInsert = $dbh->prepare("INSERT OR IGNORE INTO constant (hid, startsAt, length, name, fullText) VALUES (?, ?, ?, (SELECT v1.text FROM v_tagid AS v1 WHERE v1.keyword = 'const' AND ? LIKE '%'||v1.text||'%'), ?)");
my $preparedConstantExactInsert = $dbh->prepare("INSERT OR IGNORE INTO constant (hid, startsAt, length, name, fullText) VALUES (?, ?, ?, (SELECT v1.text FROM v_tagid AS v1 WHERE v1.keyword = 'const' AND ? = v1.text), ?)");
my $preparedDefineInsert = $dbh->prepare("INSERT OR IGNORE INTO define (hid, startsAt, length, defineName, leftHandSide, rightHandSide, fullText) VALUES (?, ?, ?, ?, ?, ?, ?)");
my $preparedDefineUpdate = $dbh->prepare("UPDATE define SET cppLeftHandSide = ?, cppRightHandSide = ?, cppText = ? WHERE did = ?");

my ($c_typeSpecifiers) =  (qr/\b(?:void|char|short|int|long|float|double|signed|unsigned|const|volatile|BOOL|id|SEL)\b/);

my ($ident_re, $balancedParenRE, $balancedCurlyRE, $proto_re, $decl_re, $mp_re, $attr_re, $method_re, $valid_re, $fparam_re, $flist_re, $func_re, $nlws, $xnlws);

$nlws = qr/(?>[\n\s]*)/s;
$balancedParenRE = qr/(?:\((?:(?>[^\(\)]+)|(??{$balancedParenRE}))*\))/;
$balancedCurlyRE = qr/(?:\{(?:(?>[^\{\}]+)|(??{$balancedCurlyRE}))*\})/;
$valid_re = qr/[a-zA-Z0-9_\*\[\]]*/;
$ident_re = qr/[a-zA-Z_][a-zA-Z_0-9]*/;
$decl_re = qr/$ident_re(?:$nlws$valid_re)*/;
#$mp_re = qr/(?:(?:$ident_re(?:\:\([^\)]*\)(?:$nlws$ident_re)?)?)|(?:\,$nlws\.\.\.))?/;
$mp_re = qr/(?:(?:$ident_re(?:\:$balancedParenRE(?:$nlws$ident_re)?)?)|(?:\,$nlws\.\.\.))?/;
$attr_re = qr/(?:__attribute|__attribute__|RK_ATTRIBUTES)$nlws$balancedParenRE/;

$fparam_re = qr/(?:$nlws$attr_re?$nlws$decl_re*$nlws$ident_re$nlws$attr_re?)/;
$flist_re = qr/(?:$fparam_re(?:,$nlws$fparam_re)?(?:,$nlws\.\.\.))?/;
$func_re = qr/$fparam_re$nlws$ident_re$nlws\([^\)]*\)(?:$nlws$attr_re)?/;

$proto_re = qr/<[^>]+>/;
$method_re = qr/(?:\+|\-)$nlws(?:\([^\)]*\))?(?:$nlws$mp_re)*(?:$nlws\;)/;

#print(STDERR "All prep word done, processing files.\n");
#print(STDERR "File list: " . join(", ", @ARGV) . "\n");
#fflush(STDERR);

#my @timing;

for my $atArg (@ARGV) {
  #my($fseconds, $fmicroseconds) = gettimeofday;
  #my($start_time) = ($fseconds + ($fmicroseconds/1000000.0));

  processFile($atArg);

  #($fseconds, $fmicroseconds) = gettimeofday;
  #my($end_time) = ($fseconds + ($fmicroseconds/1000000.0));

  #my ($fname) = ($atArg);
  #$fname =~ s/.*\/([^\/]+)$/$1/;
  #push(@timing, sprintf("%-30.30s: %f", $fname, $end_time - $start_time));
}

#print(STDERR "----\n");
#print(STDERR join("\n", @timing));
#print(STDERR "\n----\n");
#debug: Got function 'NSString * const RK_C99(restrict))captureNameString inMatchedRanges:(const NSRange * const RK_C99(restrict))matchedRanges;'

#($seconds, $microseconds) = gettimeofday;
#my ($insert_time) = ($seconds + ($microseconds/1000000.0));
$dbh->do("ANALYZE");

print("Performing table updates.\n");

$dbh->do("INSERT INTO toc (tocName) SELECT DISTINCT text FROM v_tagid WHERE keyword = 'toc'");
$dbh->do("INSERT INTO tocGroup (groupName) SELECT DISTINCT text FROM v_tagid WHERE keyword = 'group'");
$dbh->do("INSERT INTO tocMembers (tocid, tgid, pos) SELECT toc.tocid, tg.tgid, t2.tpos FROM toc, tocGroup AS tg, v_tagid AS t1 JOIN v_tagid AS t2 ON t1.hdcid = t2.hdcid AND t2.keyword = 'group' AND t2.text = tg.groupName WHERE t1.keyword = 'toc' AND toc.tocName = t1.text");

$dbh->do("UPDATE objCMethods SET occlid = (SELECT v1.occlid FROM v_occlid_ocmid_map AS v1 WHERE v1.ocmid = objCMethods.ocmid)");

$dbh->do("UPDATE objCMethods SET hdcid = (SELECT v1.hdcid FROM v_tagid AS v1 WHERE v1.keyword = 'method' AND objCMethods.selector = v1.text AND v1.hid = objCMethods.hid)");
$dbh->do("UPDATE constant SET hdcid = (SELECT v1.hdcid FROM v_tagid AS v1 WHERE v1.keyword = 'const' AND constant.name = v1.text)");
$dbh->do("UPDATE define SET hdcid = (SELECT v1.hdcid FROM v_tagid AS v1 WHERE v1.keyword = 'defined' AND define.defineName = v1.text)");
$dbh->do("UPDATE typedefEnum SET hdcid = (SELECT v1.hdcid FROM v_tagid AS v1 WHERE v1.keyword = 'typedef' AND typedefEnum.name = v1.text)");
$dbh->do("UPDATE enumIdentifier SET hdcid = (SELECT v1.hdcid FROM v_tagid AS v1 WHERE v1.keyword = 'constant' AND enumIdentifier.identifier = v1.text)");
$dbh->do("UPDATE prototypes SET hdcid = (SELECT v1.hdcid FROM v_tagid AS v1 WHERE v1.keyword = 'function' AND prototypes.sym = v1.text)");

$dbh->do("UPDATE objCMethods SET tocid = (SELECT tocid FROM v_objmtg AS v1 WHERE v1.ocmid = objCMethods.ocmid )");
$dbh->do("UPDATE objCMethods SET tgid = (SELECT tgid FROM v_objmtg AS v1 WHERE v1.ocmid = objCMethods.ocmid)");

updateCPPDefines("$ENV{'DOCUMENTATION_TEMP_DIR'}/cpp_defines.out");

#($seconds, $microseconds) = gettimeofday;
#my ($update_time) = ($seconds + ($microseconds/1000000.0));
$dbh->do("ANALYZE");

print("Creating table of contents cross reference table.\n");

$dbh->do("CREATE TABLE t_xtoc AS SELECT * FROM v_xtoc");
$dbh->do("CREATE INDEX t_xtoc_xref_idx ON t_xtoc (xref)");

$dbh->do("ANALYZE");

$dbh->commit;
#($seconds, $microseconds) = gettimeofday;
#my ($create_time) = ($seconds + ($microseconds/1000000.0));
$dbh->do("ANALYZE");

undef($preparedHeaderDocCommentsInsert);
undef($preparedTagsInsert);
undef($preparedTagArgumentsInsert);
undef($preparedObjCMethodInsert);
undef($preparedPrototypeInsert);
undef($preparedFunctionInsert);
undef($preparedHeaderSelect);
undef($preparedHeaderInsert);
undef($preparedTypedefEnumInsert);
undef($preparedEnumIdentifierInsert);
undef($preparedObjCClass);
undef($preparedObjCClassCategory);
undef($preparedObjCClassDefinition);
undef($preparedClassIDSelect);
undef($preparedConstantExactInsert);
undef($preparedConstantInsert);
undef($preparedDefineInsert);
undef($preparedDefineUpdate);

#$dbh->disconnect();
#($seconds, $microseconds) = gettimeofday;
#my ($end_time) = ($seconds + ($microseconds/1000000.0));

#printf("Insert time: %f\n", $insert_time-$start_time);
#printf("Update time: %f\n", $update_time-$insert_time);
#printf("Create time: %f\n", $create_time-$update_time);

#printf("Total time : %f\n", $end_time-$start_time);

exit(0);

sub updateCPPDefines {
  my $defineFile = shift(@_);
  print("Checking CPP defines..\n");
  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($defineFile);
  my ($CPP_IN, $cppText);
  
  print("File size: $size\n");
  open($CPP_IN, "<", $defineFile);
  sysread($CPP_IN, $cppText, $size);
  close($CPP_IN);
  study $cppText;
  
  for my $row (selectall_hash($dbh, "SELECT did, defineName FROM define WHERE hdcid IS NOT NULL")) {
    if ($cppText =~ /(#define\s+($row->{'defineName'}.*))/) {
      my ($defineFullText, $defineText) = ($1, $2);
      my ($defineName, $leftHandSide, $rightHandSide);
      if ($defineText =~ /^(([a-zA-Z0-9_\-]+)\s*($balancedParenRE))\s*(.*$balancedParenRE.*)/) { $defineName = $2; $leftHandSide = $1; $rightHandSide = $4; }
      elsif ($defineText =~ /^(([a-zA-Z0-9_\-]+)\s*($balancedParenRE))\s*(\S+.*)/) { $defineName = $2; $leftHandSide = $1; $rightHandSide = $4; }
      elsif ($defineText =~ /^([a-zA-Z0-9_\-]+)\s*($balancedParenRE)\s*$/) { $defineName = $1; $leftHandSide = $1; $rightHandSide = $2; }
      elsif ($defineText =~ /^([a-zA-Z0-9_\-]+)\s+(\S+.*)\s*$/) { $defineName = $1; $leftHandSide = $1; $rightHandSide = $2; }
      elsif ($defineText =~ /^([a-zA-Z0-9_\-]+)\s*$/) { $defineName = $1; }
      else {
        print("$row->{'defineName'}: define of '$defineText' --> ");
        print("DID NOT MATCH\n");
      }
      if (defined($defineName)) { $preparedDefineUpdate->execute($leftHandSide, $rightHandSide, $defineFullText, $row->{'did'}); }
    } else {
      print("Missed '$row->{'defineName'}' is CPP output?\n");
    }
  }
  
}

sub selectall_hash {
  my($dbh, $stmt, @args, @results) = (shift(@_), shift(@_), @_);
  my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, undef) or return;
  $sth->execute(@args) or return;
  while (my $row = $sth->fetchrow_hashref) { push(@results, $row); }
  $sth->finish;
  return(@results);
}

sub processFile {
  my($processFileName) = @_;
  my($in, $at, $hid, $STH, $HEADER_IN) = ("", 0);
  
  my($fullName) = (realpath($processFileName));
  my($name, $path) = fileparse($fullName);
  
  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($fullName);
  
  my $row = $dbh->selectrow_hashref($preparedHeaderSelect, {MaxRows => 1}, ($path, $name));
  if ($row) {
    if (($mtime ne $row->{'modified'}) || ($size ne $row->{'size'})) { $dbh->do("DELETE FROM headers WHERE hid = $row->{'hid'}"); }
    else { printf("Up to date: $name\n"); return; }
  }
  
  if (!defined($hid)) {
    printf("Processing: $name\n");
    $preparedHeaderInsert->execute($path, $name, $size, $mtime);
    $hid = $dbh->last_insert_id(undef, undef, undef, undef);
  }
  
  open($HEADER_IN, "<", $fullName);
  sysread($HEADER_IN, $in, $size);
  close($HEADER_IN);
  
  while ($in =~ /extern[ \t\n]*\"C\"[ \t\n]*\{/sg) {
    my ($som, $eom, $len) = ($-[0], $+[0], $+[0] - $-[0]);
    substr($in, $som, $len) =~ s/[^\n]/ /sg;
    substr($in, curlyEnd($in, $eom, 1) - 1, 1) = " ";
  }

  my @line_times;
  my($commentNumber) = (0);

  study($in);
  while ($in =~ /(\/\*!(([^\*]+|\*(?!\/))*)\*\/)/sg) {
    my($headerDoc, $remainingText, $fullText, $hdcid, $tagPosition, $shdcom, $ehdcom) = ($1, $2, $1, 0, 0, $-[0], $+[0]);
    #    substr($in, $shdcom, ($ehdcom - $shdcom) ) =~ s/[^\n]/ /sg;;
  
    $preparedHeaderDocCommentsInsert->execute($hid, $shdcom, $ehdcom - $shdcom);
    $hdcid = $dbh->last_insert_id(undef, undef, undef, undef);
    #	printf("\n\n---------------\n");
    #	printf("New comment: #$commentNumber hdcid: $hdcid\n");
    #	printf("Text: $remainingText\n");
	
    $commentNumber++;
	
    while (length($remainingText) > 0) {
      my($tag, $argumentsFullText, $tagFullText, $tid);
    
      if ($remainingText =~ /((${keywordRegex})(.*?))(${keywordRegex}.*)/s) {
	$tagFullText = $1; $tag = $3; $argumentsFullText = $4; $remainingText = $5;
      } elsif ($remainingText =~ /((${keywordRegex})(.*))/s) {
	$tagFullText = $1; $tag = $3; $argumentsFullText = $4; $remainingText = "";
      } else {
	$remainingText = ""; next;
      }
    
      #	    printf("tagFullText  : $tagFullText\n");
      #	    printf("tag          : $tag\n");
      #	    printf("argFullText  : $argumentsFullText\n");
      #	    printf("remainingText: $remainingText\n");
      #	    printf("\n");
    
      $argumentsFullText =~ s/\A\s*(.*?)(\s|\n)*\Z/$1/gs;
    
      $preparedTagsInsert->execute($keywordTKID->{$tag}, $hdcid, $tagPosition);
      $tid = $dbh->last_insert_id(undef, undef, undef, undef);
    
      if ($keywordArguments->{$tag} == 1) { $preparedTagArgumentsInsert->execute($tid, 0, $argumentsFullText); }
      else {
	my ($argumentNumber, $argumentsText, $remainingArgumentsText);
	$argumentNumber = 0;
	$argumentsText = $argumentsFullText;
	$remainingArgumentsText = $argumentsText;
      
	while ((length($remainingArgumentsText) > 0) && ($argumentNumber < ($keywordArguments->{$tag} - 1))) {
	  if ($remainingArgumentsText =~ /(.*?)\s+(.*)/s) { 
	    my($cleaned);
	    $remainingArgumentsText = $2;
	    ($cleaned = $1) =~ s/\A\s*(.*?)(\s|\n)*\Z/$1/gs;
	    $preparedTagArgumentsInsert->execute($tid, $argumentNumber, $cleaned);
	    $remainingArgumentsText =~ s/\A\s*(.*?)(\s|\n)*\Z/$1/gs;		    
	    $argumentNumber++;
	  } else { last; }
	}
	$preparedTagArgumentsInsert->execute($tid, $argumentNumber, $remainingArgumentsText);
      }
      $tagPosition++;
    }
  }


  #    $in =~ s/(\/(?:\/[^\n]*\n|\*(?:[^\*]+|\*(?!\/))*\*\/))/{my($sx); ($sx = $1) =~ s\/[^\n]\/ \/sg; $sx}/sge;
  while ($in =~ /(?:\/(?:\/[^\n]*\n|\*(?:[^\*]+|\*(?!\/))*\*\/))/sg) { my($som, $eom) = ($-[0], $+[0]); substr($in, $som, $eom-$som) =~ s/[^\n]/ /sg; }

  open($STH, "<", \$in);
  my($next_line) = (0);
  while (<$STH>) {
    my($sol, $eol) = (tell($STH) - length($_), tell($STH));
  
    if ($next_line == 1) {
      /(^[^\n]*)$/;
      my($som, $eom) = ($sol + $-[1], $sol + $+[1]);
      if (/\\\n/) { $next_line = 1; } else { $next_line = 0; }
      substr($in, $som, ($eom - $som)) =~ s/[^\n]/ /sg;
    } elsif (/(^\s*\#define\s+(.*?)\s*$(?<!\\\n))/) {
      my ($defineFullText, $defineText) = ($1, $2);
      my($som, $eom) = ($sol + $-[1], $sol + $+[1]);
      substr($in, $som, ($eom - $som)) =~ s/[^\n]/ /sg;
    
      my ($defineName, $leftHandSide, $rightHandSide);
      if ($defineText =~ /^(([a-zA-Z0-9_\-]+)\s*($balancedParenRE))\s*(.*$balancedParenRE.*)/) { $defineName = $2; $leftHandSide = $1; $rightHandSide = $4; }
      elsif ($defineText =~ /^(([a-zA-Z0-9_\-]+)\s*($balancedParenRE))\s*(\S+.*)/) { $defineName = $2; $leftHandSide = $1; $rightHandSide = $4; }
      elsif ($defineText =~ /^([a-zA-Z0-9_\-]+)\s*($balancedParenRE)$/) { $defineName = $1; $leftHandSide = $1; $rightHandSide = $2; }
      elsif ($defineText =~ /^([a-zA-Z0-9_\-]+)\s+(\S+.*)$/) { $defineName = $1; $leftHandSide = $1; $rightHandSide = $2; }
      elsif ($defineText =~ /^([a-zA-Z0-9_\-]+)$/) { $defineName = $1; }
      else {
	print("$name: define of '$defineText' --> ");
	print("DID NOT MATCH\n");
      }
      if (defined($defineName)) { $preparedDefineInsert->execute($hid, $som, $eom-$som, $defineName, $leftHandSide, $rightHandSide, $defineFullText); }
    } elsif (/(^\s*\#(\w+)[^\n]*)$/) {
      my($som, $eom) = ($sol + $-[1], $sol + $+[1]);
      if (/\\\n/) { $next_line = 1; } else { $next_line = 0; }
      substr($in, $som, ($eom - $som)) =~ s/[^\n]/ /sg;
    } elsif (/^\s*(\S*DECL\S*)\s*$/) {
      my($som, $eom) = ($sol + $-[1], $sol + $+[1]);
      substr($in, $som, ($eom - $som)) =~ s/[^\n]/ /sg;
    }
  
  }
  close($STH);

  my($typedefPos) = (0);

  while ($in =~ /typedef${nlws}enum${nlws}\{/sg) {
    my ($som, $eom, $startEnumText, $endEnumText) = ($-[0], $+[0], $+[0]);
    $eom = curlyEnd($in, $eom, 1);
    $endEnumText = $eom - 1;
    $eom = index($in, ";", $eom) + 1;
    my($typedefName, $enumText, $fullText) = (substr($in, $endEnumText, $eom - $endEnumText), substr($in, $startEnumText, $endEnumText - $startEnumText), substr($in, $som, $eom-$som));
    $typedefName =~ s/\}?${nlws}($ident_re)$nlws\;/$1/s;

    $preparedTypedefEnumInsert->execute($hid, $som, $eom-$som, $typedefPos, $fullText, $typedefName, $enumText);
    my($tdeid) = ($dbh->last_insert_id(undef, undef, undef, undef));

    my($enumPos) = (0);

    while ($enumText =~ /[\n\s]*?([ \t]*($ident_re)$nlws\=$nlws(.*?)$nlws(?:\,|\z))/sg) {
      my($esom, $eeom, $thisFullText, $identifier, $constant, $endType) = ($-[1], $+[1], substr($enumText, $-[1], $+[1] - $-[1]), $2, $3);
      $thisFullText =~ s/$nlws\z//s;
      $constant =~ s/\n/ /sg;
      $constant =~ s/\s{2,}/ /sg;
      $constant =~ s/\(\s+/\(/sg;
      $constant =~ s/\s+\)/\)/sg;
      $preparedEnumIdentifierInsert->execute($tdeid, $startEnumText + $esom, $eeom-$esom, $enumPos, $thisFullText, $identifier, $constant);
      $enumPos++;
    }

    substr($in, $som, ($eom - $som) ) =~ s/[^\n]/ /sg;
    $typedefPos++;
  }


  open($STH, "<", \$in);
  while (<$STH>) {
  
    my ($fh_line, $fh_len, $fh_sol, $fh_eol, $fh_line_num) = ($_, length($_), tell($STH) - length($_), tell($STH), $.);
    my($som, $eom);
	
    pos($in) = $fh_sol;
  
    if ($_ =~ /^\s*$/) { next; }
  
#    my($fseconds, $fmicroseconds) = gettimeofday;
#    my($start_time) = ($fseconds + ($fmicroseconds/1000000.0));

    #  if(($name eq "RegexKitTypes.h") && ($fh_line_num >= 40)) {
    #    printf(STDERR "[$name@%5d: %5d %5d %5d] Looking at '%s'\n", $fh_line_num, $fh_sol, $fh_eol, $fh_eol - $fh_sol, $fh_line);
    #  }
  
    if (!defined($eom)) {
      if ($fh_line =~ /\@interface/) {
	$som = $fh_sol + $-[0];
	pos($in) = $som;
      
	if ($in =~ /\G\@interface\s+($ident_re)\s*\:\s*($ident_re)\s*($proto_re)?\s*($balancedCurlyRE)(.*?)\@end/sgc) {
	  my($smeth, $emeth) = ($-[5], $+[5]);
	  $eom = $-[5];
	  my($soc, $eoc, $class, $superclass, $proto, $ivars) = ($-[0], $+[0], $1, $2, defined($3) ? $3:"NULL", $4);
	  $preparedObjCClassDefinition->execute($hid, $class, $superclass, $soc, $eoc - $soc, $proto, $ivars, $smeth, $emeth - $smeth);
	} elsif ($in =~ /\G\@interface\s+($ident_re)\s*\(\s*($ident_re)\s*\)\s*($proto_re)?(.*?)\@end/sgc) {
	  my($smeth, $emeth) = ($-[4], $+[4]);
	  $eom = $-[4];
	  my($soc, $eoc, $class, $category, $proto) = ($-[0], $+[0], $1, $2, defined($3) ? $3:"NULL");
	  $preparedObjCClassCategory->execute($hid, $class, $soc, $eoc - $soc, $category, $proto, $smeth, $emeth - $smeth);
	} else { printf("no interface match?\n"); }
      
	if (!defined($eom)) { printf("interface didn't define eom\n"); }
      }
    }
    if (!defined($eom)) {
      if ($fh_line =~ /\@class/) {
	$som = $fh_sol + $-[0]; $in =~ /;/sg; $eom = $+[0]; 
	#printf(STDERR "[$name@%5d: %5d %5d %5d] Parsed '\@class' - '%s'\n", $fh_line_num, $som, $eom, $eom-$som, $fh_line);
      } }
    if (!defined($eom)) { if ($fh_line =~ /\@end/) { $som = $fh_sol + $-[0]; $eom = $fh_sol + $+[0]; } }
    if (!defined($eom)) {
      if ($in =~ /\G\s*(?!\n)($method_re)/s) {
	$som = $-[1]; $eom = $+[1];
	my($mstr) = (substr($in, $som, $eom-$som));
      
	my($pretty, $signature, $selector, $mid, $type) = ($mstr);
	#		print("debug: Got method '$pretty'\n");
  $pretty =~ s/RK_REQUIRES_NIL_TERMINATION//;
	$pretty =~ s/RK_C99($balancedParenRE)/my $x=$1; $x=~ s#\A\((.*)\)\z#$1#; $x/sge;
	$pretty =~ s/\n/ /sg;
	$pretty =~ s/$attr_re//sg;
	$pretty =~ s/[\n\s]*\z//s;
	$pretty =~ s/[\n\s]{2,}/ /sg;
	$pretty =~ s/\*[\n\s]+\*/**/sg;
	$pretty =~ s/($ident_re)\s*\:\s*\(\s*([^\)]*)\s*\)\s*($ident_re(?: |;))/$1:\($2\)$3/sg;
	$pretty =~ s/(\+|\-)\s*(\S)/$1 $2/s;
	$pretty =~ s/\A[\n\s]*(.*?)[\n\s]*\z/$1/sg;
	$pretty =~ s/^\s+//s;
	$pretty =~ s/\s+$//s;

	($signature = $pretty) =~ s/($ident_re\:)(:?\([^\)]*\)$ident_re?)? /$1/sg;
	$signature =~ s/($ident_re\:)\([^\)]*\)$ident_re?(?=;)/$1/s;
	$signature =~ s/($ident_re\:|,[^,]*)(:?\([^\)]*\)$ident_re?)?/$1/sg;
	$signature =~ s/(\+|\-) (?:\([^\)]*\))?(.*);/$1 $2/s;

	($selector = $signature) =~ s/(?:\+|\-)\s*(?:\([^\)]*\))?([^\,]*).*$/$1/s;

	($type = $pretty) =~ s/(\+|\-).*/$1/;
	$preparedObjCMethodInsert->execute($hid, $som, $eom-$som, $type, $mstr, $pretty, $signature, $selector);
      }
    }
    if (!defined($eom)) {
      #      if ($in =~ /\G\s*($func_re)/gs) {
      if ($in =~ /$nlws($func_re)/gs) {
	$som = $-[1];
	#	if ($in =~ /\G[^\{\;]*([;|\{])/gs) {
	if ($in =~ /[^\{\;]*([;|\{])/gs) {
	  my($mtype) = ($1);
	  $eom = ($mtype eq "{") ? curlyEnd($in, $+[1], 1) : $+[1];
	  my($mstr) = (substr($in, $som, $eom-$som));
	  my($signature, $pretty, $mid, $symbol) = ($mstr);
  
	  #    print("debug: Got function '$signature'\n");
    $signature =~ s/RK_REQUIRES_NIL_TERMINATION//;
	  $signature =~ s/RK_C99($balancedParenRE)/my $x=$1; $x=~ s#\A\((.*)\)\z#$1#; $x/sge;
	  $signature =~ s/\{.*\}\z//s;
	  $signature =~ s/\;//s;
	  $signature =~ s/[\n\s]*\z//s;
	  $signature =~ s/$attr_re//sg;
	  $signature =~ s/\n/ /sg;
	  $signature =~ s/[\n\s]{2,}/ /sg;
	  $signature =~ s/\*[\n\s]+\*/**/sg;
	  $signature =~ s/(.*?\*)[\n\s]*($ident_re\()/$1$2/sg;
	  $signature =~ s/\A[\n\s]*(.*?)[\n\s]*\z/$1/sg;
	  $signature =~ s/^\w+_EXPORT|^\w+_EXTERN//sg;
	  $signature =~ s/^\s+//s;
	  $signature =~ s/\s+$//s;
                                   
	  $pretty = $signature;
                                   
	  ($mid = $signature) =~ s/.*(\(.*\)).*/$1/s;
	  $mid =~ s/(\(?[^\*]+\*).*?(,|\))/$1$2/sg;
	      
	  $mid =~ s/(\(?(?:[^,]+\*|(?:$c_typeSpecifiers\s*)*))(.*?)(\, |\))/
	    {
	     my ($a, $b, $c, $arg) = ($1, $2, defined($3) ? $3:"", defined($1) ? $1:"");
	     if (defined($b)) { if ($b =~ \/(\S+) (\S+)\/) { $arg .= $1; } elsif (!defined($a) || $a eq "(" || length($a) < 1) { $arg .= $b; } }
	     $arg =~ s\/ \z\/\/;
	     $arg .= $c;
	     $arg
	    }/ge;
		    
	  $signature =~ s/\(.*\)/$mid/s;
		    
	  $symbol = $signature;
	  $symbol =~ s/.*?\s*($ident_re)\(.*$/$1/s;
                                    
	  if ($mtype eq "{") { $preparedFunctionInsert->execute($hid, $som, $eom-$som, $signature, $pretty, $signature, $symbol); } 
	  elsif ($mtype eq ";") { $preparedPrototypeInsert->execute($hid, $som, $eom-$som, $mstr, $pretty, $signature, $symbol); }
	} else { printf("Did not match: $fh_line\n"); }
      }
    }
    if (!defined($eom)) {
      if ($fh_line =~ /\s*(?:typedef|struct|enum|union)/) {
	pos($in) = $fh_sol + $-[0];
		
	if ($in =~ /(?:typedef|struct|enum|typedef${nlws}struct|union)$nlws[^\{;]*(\{|;)?/g) {
	  # we don't deal with these right now
	  $som = $-[0]; $eom = $+[0];
  
	  if ($1 eq "{") {
	    pos($in) = $eom;
    
	    $eom = $+[1];
	    $eom = curlyEnd($in, $eom, 1);
	    pos($in) = $eom;
	    $in =~ /.*?\;/sg;
	    $eom = $+[0];
	  }
	  substr($in, $som, $eom-$som) =~ s/[^\n]/ /sg;
	} else { printf("wtf\n"); }
      }
    }

    if (!defined($eom)) {
      if ($fh_line =~ /$nlws([a-zA-Z0-9_\*\[\]\n\s]+;)/s) {
	$som = $fh_sol + $-[0];
	$eom = $fh_sol + $+[0];
	#printf(STDERR "[$name@%5d: %5d %5d %5d] Parsed constant - '%s'\n", $fh_line_num, $som, $eom, $eom-$som, $fh_line);

	my $mtxt = $1;
	pos($in) = $eom;
	substr($in, $som, $eom-$som) =~ s/[^\n]/ /sg;
  if($mtxt =~ /extern\s.*?\s+($ident_re);/) {
    my $ctxt = $1;
    #printf(STDERR "[$name@%5d: %5d %5d %5d] Parsed constant - '%s' '%s'\n", $fh_line_num, $som, $eom, $eom-$som, $ctxt, $mtxt);
    $preparedConstantExactInsert->execute($hid, $som, $eom-$som, $ctxt, $mtxt);
  } else {
    #printf(STDERR "[$name@%5d: %5d %5d %5d] Parsed constant - '%s'\n", $fh_line_num, $som, $eom, $eom-$som, $mtxt);
    $preparedConstantInsert->execute($hid, $som, $eom-$som, $mtxt, $mtxt);
  }
      }
    }

    if (!defined($eom)) {
      #      if($in =~ /$nlws([a-zA-Z0-9_\*\[\]\n\s]+;)/gcs) {
      if ($in =~ /\G$nlws([a-zA-Z0-9_\*\[\]\n\s]+;)/gcs) {
	my $mtxt = $1;
	$som = $-[1];
	$eom = $+[1];
	pos($in) = $eom;
	substr($in, $som, $eom-$som) =~ s/[^\n]/ /sg;
	$preparedConstantInsert->execute($hid, $som, $eom-$som, $mtxt, $mtxt);
      }
    }

    if (defined($eom)) {
      if ($eom > $fh_eol) { 
	my($mstr, $dcnt) = (substr($in, $som, $eom-$som), 0);
	while ($mstr =~ /\n/g) { $dcnt++; }
	$. += ($dcnt - 1);
	seek($STH, $eom, 0);
      }
    } else {
      if ($fh_line !~ /(DECL)/) { printf(STDERR "[$name@%5d: %5d %5d %5d]>>>>>>> '%s'\n", $fh_line_num, $fh_sol, $fh_eol, $fh_len, $fh_line); }
    }
#      ($fseconds, $fmicroseconds) = gettimeofday;
#  my($end_time) = ($fseconds + ($fmicroseconds/1000000.0));
#  push(@line_times, sprintf("%4d [%6d] / %-30.30s: %f", $fh_line_num, $fh_sol, $name, $end_time - $start_time));

  }
#print(STDERR "----\n");
#print(STDERR join("\n", @line_times));
#print(STDERR "\n----\n");

  close($STH);
  undef($in);
}

sub curlyEnd {
  my($str, $at_pos, $depth) = @_;
  pos($str) = $at_pos;
  my ($endPos) = ($at_pos);
  
  while ($str =~ /([\{\}]{1})/sg) {
    if ($1 eq "{") { $depth++; } elsif ($1 eq "}") { $depth--; }
    $endPos = $+[1];
    if ($depth < 1) { return($endPos); }
  }
}
