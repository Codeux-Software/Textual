#!/usr/bin/perl -w

use strict;

# Take an optional argument, the directory of the pcre documentation.  If no argument, then we'll use the current working directory.
# Do some simple error checks too.

my ($program_name, $script_name) = ($0, (defined($ENV{"SCRIPT_NAME"}) && defined($ENV{"SCRIPT_LINENO"})) ? "$ENV{'SCRIPT_NAME'}:$ENV{'SCRIPT_LINENO'}" : "");
$program_name =~ s/(.*?)\/?([^\/]+)$/$2/;

if($#ARGV > 0) { print(STDERR "Usage: $program_name [DIRECTORY OF PCRE DOCUMENTATION]\n"); exit(1); }
if($#ARGV == 0) { if(chdir($ARGV[0]) != 1) { print(STDERR "Can't change to directory '$ARGV[0]'.\n"); exit(1); } }
my ($pwd);

if((!-r "index.html") || (!-r "pcrepattern.html")) { chomp($pwd = `pwd`); print(STDERR "Can't find expected PCRE documentation files in '$pwd'.\n"); exit(1); }

# Since the titles we're interested in are all uppercase, we need to pretty re-capitalize them.

my (%toLower, %allUpper);

for (qw( a about above absent across after against along amid amidst among amongst an and around as at before behind below beneath beside besides between beyond but by circa de down during except for from has in into near nor of off on onto or out over past per since so than the through till to toward towards under until unto up upon versus via von with within without yet malloc pcre_partial pcregrep pcretest ) ) { $toLower{lc($_)}++; }

for (qw(api ebcdic pcre posix utf)) { $allUpper{lc($_)}++; }

sub titleCap {
  local $_ = shift;
    
  s/\b(((\w|_)+)(?!\(\)))\b/$toLower{lc($1)} ? lc($1) : ucfirst($1)/ge; 
  s/^\b(((\w|_)+)(?!\(\)))\b/ucfirst($1)/e; 
  s/(\(\s*|:\s*|;\s*)\b(((\w|_)+)(?!\(\)))\b/$1 . ucfirst($2)/ge; 
  s/\b(((\w|_)+)(?!\(\)))\b/$allUpper{lc($1)} ? uc($1) : $1/ge; 
  s/(\w+)'S\b/$1's/g; 
    
  return $_;
}

print("<div class=\"bar\">&nbsp;</div>\n");
print("<div class=\"header\"><span class=\"label\">Related Reference</span></div>\n");

# Read in the PCRE syntax file, pcresyntax.html, and output it as a stand alone toc section.

if(-r "pcresyntax.html") {
  my($quickref_in, $quickref_found) = ("", 0);
  
  open(PCREQUICKREF, "<pcresyntax.html");
  while(<PCREQUICKREF>) { $quickref_in .= $_; if(/<\/ul>/) { $quickref_found = 1; last; } }
  close(PCREQUICKREF);
  $quickref_in =~ s/BACTRACKING/BACKTRACKING/sg;
  if($quickref_found == 1) {
    $quickref_in =~ /(<ul>.*?<\/ul>)/si;
    my $quickreful = $1;
    print <<QUICKREF_START;
  <div class="section closed syntax" id="tocID_pcreQuickRef">
    <div class="header">
      <span class="indicator large"><span class="img">&nbsp;</span></span>
      <span class="title"><a href="pcre/pcresyntax.html" target="doc">Quick Reference</a></span>
    </div>
        
    <div class="contents">
      <div class="entries">
QUICKREF_START
        while($quickreful =~ /(<li>(.*(?!<li>)))/gi) {
          my $lineitem = $2;
          $lineitem =~ /<a name="[^\"]*" href="(#[^\"]+)">(.*?)<\/a>/i;
          my $href = $1; my $title = $2; my $tc_title = titleCap(lc($title));
          if(($tc_title eq "Author") || ($tc_title eq "Revision")) { next; }
          print("      <div class=\"entry\"><a href=\"pcre/pcresyntax.html$href\" target=\"doc\">$tc_title</a></div>\n");
        }
      print <<QUICKREF_END;
      </div>
      <span class="rightEdge"><img alt="Overflow fade" src="Images/grad_18_1.png"></span>
    </div>
  </div>
QUICKREF_END
  }
}

# Read in the PCRE syntax file, pcrepattern.html, and output it as a stand alone toc section.

my($syn_in, $syn_found) = ("", 0);

open(PCRESYN, "<pcrepattern.html");
while(<PCRESYN>) { $syn_in .= $_; if(/<\/ul>/) { $syn_found = 1; last; } }
close(PCRESYN);
$syn_in =~ s/BACTRACKING/BACKTRACKING/sg;
if($syn_found == 1) {
  $syn_in =~ /(<ul>.*?<\/ul>)/si;
  my $synul = $1;
  print <<SYN_START;
<div class="section closed syntax" id="tocID_pcreSyn">
  <div class="header">
    <span class="indicator large"><span class="img">&nbsp;</span></span>
    <span class="title"><a href="pcre/pcrepattern.html" target="doc">Regular Expression Syntax</a></span>
  </div>

  <div class="contents">
    <div class="entries">
SYN_START
  while($synul =~ /(<li>(.*(?!<li>)))/gi) {
    my $lineitem = $2;
    $lineitem =~ /<a name="[^\"]*" href="(#[^\"]+)">(.*?)<\/a>/i;
    my $href = $1; my $title = $2; my $tc_title = titleCap(lc($title));
    if(($tc_title eq "Author") || ($tc_title eq "Revision")) { next; }
    print("      <div class=\"entry\"><a href=\"pcre/pcrepattern.html$href\" target=\"doc\">$tc_title</a></div>\n");
  }
  print <<SYN_END;
    </div>
  <span class="rightEdge"><img alt="Overflow fade" src="Images/grad_18_1.png"></span>
  </div>
</div>
SYN_END
}


# Read in index.html to get a list of files we might be interested in.

my($idx) = ("");

open(INDEX, "<index.html");
while(<INDEX>) { $idx .= $_; }
close(INDEX);

# We use the following heuristic:
# The file is divided up in to <tables>
# One of the tables is primarily the API reference
# We'll take the first table with the lowest number of API hits.

my @tables;
my @tables_score;

while($idx =~ /(<table>.*?<\/table>)/sgi) {
  my $tbl = $1;
  $tbl =~ s/\&nbsp;/ /sgi;
  $tbl =~ s/<table>(.*?)<\/table>/$1/sgi;
  $tbl =~ s/(<tr>.*?<\/tr>)/{my $x = $1; $x =~ s\/\n\s*((<td>)?)\s*\/$1\/sg; $x}/sgie;
  $tbl =~ s/\n(\n|\s)*\n/\n/mg;
  push(@tables, $tbl);
  my $cnt = 0;
  while($tbl =~ /\b((pcre_exec|pcre_study|pcre_compile\d?|pcre_config|pcre_version|pcre_(full)?info)(\(.*?\))?)\b/sg) { $cnt++; }
  push(@tables_score, $cnt);
}

my $lowest_idx = -1;
my $lowest_score = 2^30;
for(my $x=0; $x<$#tables_score; $x++) {
  if($tables_score[$x] < $lowest_score) { $lowest_idx = $x; $lowest_score = $tables_score[$x]; }
}

my $scan_tbl = $tables[$lowest_idx];
my @scanfiles;

while($scan_tbl =~ /(<tr>.*?<\/tr>)/sg) {
  my $tr = $1;
  if($tr =~ /<tr>\s*<td>\s*<a\b.*?\bhref="([^\"]+\.html)".*?>(.*?)<\/a>\s*<\/td>.*?<td>\s*(.*?)\s*<\/td>\s*<\/tr>/i) {
    my ($htmlfile, $desc) = ($1, $3);
    if($htmlfile !~ /pcre_/) {
      $desc =~ s/<(\w+).*>(.*?)<\/((?i)\1)>/$2/g;
      push(@scanfiles, {"file" => $htmlfile, "desc" => $desc});
    }
  }
}

if($#scanfiles == -1) {
  print("<!-- Did not match any PCRE.html files? -->\n");
  exit(0);
}

print <<SECT_START;

<div class="bar">&nbsp;</div>

<div class="header"><span class="label">Related Documentation</span></div>

<div class="section closed pcreDoc last" id="tocID_pcreDoc">
  <div class="header">
    <span class="indicator large">&nbsp;</span>
    <span class="title"><a href="pcre/index.html" target="doc">PCRE Documentation</a></span>
  </div>

  <div class="contents">
    <div class="entries">
SECT_START

for(my $x = 0; $x < $#scanfiles; $x++) {
  my $atfile = $scanfiles[$x]{"file"}; my $atdesc = $scanfiles[$x]{"desc"};
  my $in = ""; my $found = 0; my $toc; my $tc_desc = titleCap($atdesc);
  open(HTML, "< $atfile");
  while(<HTML>) { $in .= $_; if(/<\/ul>/) { $found = 1; last; } }
  close(HTML);
  $in =~ s/BACTRACKING/BACKTRACKING/sg;

  my $sectionId = "tocID_pcreDoc_$tc_desc";
  $sectionId =~ s/[^a-zA-Z0-9_\.\-]//sg;

  if($found == 1) {
    $in =~ /(<ul>.*?<\/ul>)/si;
    my $tocul = $1;
    print <<TOC_START;
      <div class="section closed sub" id="$sectionId">
        <div class="header">
          <span class="indicator small">&nbsp;</span>
          <span class="title"><a href="pcre/$atfile" target="doc">$tc_desc</a></span>
        </div>
        <div class="contents">
          <div class="entries">
TOC_START

    while($tocul =~ /(<li>(.*(?!<li>)))/gi) {
      my $lineitem = $2;
      $lineitem =~ /<a name="[^\"]*" href="(#[^\"]+)">(.*?)<\/a>/i;
      my $href = $1; my $title = $2; my $tc_title = titleCap(lc($title));
      if(($tc_title eq "Author") || ($tc_title eq "Revision")) { next; }
      print("            <div class=\"entry\"><a href=\"pcre/$atfile$href\" target=\"doc\">$tc_title</a></div>\n");
    }
    print <<TOC_END;
          </div>
        </div>
      </div>

TOC_END
  } else {
    my $single_title = $tc_desc;
    if($in =~ /^\s*(([A-Z]|[[:punct:]]|\s)+)\s*$/m) { $single_title = titleCap(lc($1)); }

    print <<SINGLE_TOC;
      <div class="section closed sub" id="$sectionId">
        <div class="header">
          <span class="indicator small">&nbsp;</span>
          <span class="title">$tc_desc</span>
        </div>
        <div class="contents">
          <div class="entries">
            <div class="entry"><a href="pcre/$atfile" target="doc">$single_title</a></div>
          </div>
        </div>
      </div>

SINGLE_TOC
  }
}

print <<SECT_END;
      <span class="rightEdge"><img alt="Overflow fade" src="Images/grad_18_1.png"></span>
    </div>
  </div>
</div>
SECT_END
