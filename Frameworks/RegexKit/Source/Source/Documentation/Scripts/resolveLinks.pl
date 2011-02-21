#!/usr/bin/perl -w

use strict;
use DBI;
require DBD::SQLite;
use Data::Dumper;
use Cwd 'realpath';
use File::Basename;
#use POSIX;
#use IO::Handle;
#STDERR->autoflush(1);
#BEGIN { $diagnostics::PRETTY = 1 }
#use diagnostics; 

my ($program_name, $script_name) = ($0, (defined($ENV{"SCRIPT_NAME"}) && defined($ENV{"SCRIPT_LINENO"})) ? "$ENV{'SCRIPT_NAME'}:$ENV{'SCRIPT_LINENO'}" : "");
$program_name =~ s/(.*?)\/?([^\/]+)$/$2/;

for my $env (qw(DOCUMENTATION_SQL_DATABASE_FILE GENERATED_HTML_DIR)) {
  if(!defined($ENV{$env}))  { print("${script_name} error: $program_name: Environment variable $env not set.\n"); exit(1); }
}

my $dbh = DBI->connect("dbi:SQLite:dbname=$ENV{'DOCUMENTATION_SQL_DATABASE_FILE'}","","", { AutoCommit => 1, RaiseError => 1 });

$dbh->do("PRAGMA synchronous = OFF");
$dbh->do("ANALYZE");

$dbh->begin_work;

my (%no_link, %xrefs);
for my $row (selectall_hash($dbh, "SELECT DISTINCT xref FROM xrefs WHERE href IS NULL")) { $no_link{$row->{'xref'}} = 1; }
for my $row (selectall_hash($dbh, "SELECT DISTINCT xref, href FROM t_xtoc WHERE xref IS NOT NULL AND href IS NOT NULL")) { $xrefs{'xref'}->{$row->{'xref'}}{'href'} = $row->{'href'}; }
for my $row (selectall_hash($dbh, "SELECT DISTINCT xref, href FROM xrefs WHERE href IS NOT NULL"))                       { $xrefs{'xref'}->{$row->{'xref'}}{'href'} = $row->{'href'}; }

for my $file (@ARGV) {
  my($FILE_IN, $FILE_OUT, $in, $out);


  my($fullName) = (realpath($ENV{'DOCUMENTATION_SOURCE_DIR'} . '/Static/' . $file));
  my($name, $path) = fileparse($fullName);

  print("Resolving: $name\n");

  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($fullName);

  open($FILE_IN, "<", $fullName); sysread($FILE_IN, $in, $size); close($FILE_IN);
  $out = replaceLinks($in);
  open($FILE_OUT, ">", "$ENV{'GENERATED_HTML_DIR'}/$name"); print($FILE_OUT $out); close($FILE_OUT);
}

$dbh->commit;

$dbh->disconnect();
exit(0);


sub extractLinks {
  my($text) = @_;
  my %links;
  #while ($text =~ /\@link\s(.*?)\s(.*?)\s?\@\/link/sg) { my ($x, $y) = ($1, $1); $y =~ s?//apple_ref/\w+/\w+/(\w+)(\?:/.*)\??$1?; $links{$x} = $y; }
  while ($text =~ /\@link\s+([^\s]+)\s+(.*?)\s?\@\/link/sg) { my ($x, $y) = ($1, $1); $y =~ s?//apple_ref/\w+/\w+/(\w+)(\?:/.*)\??\Q$1\E?; $links{$x} = $y; }
  return(%links);
}

sub replaceLinks {
  my($text) = @_;
  my(%links) = extractLinks($text);

  for my $atLink (sort keys %links) {
    if ($no_link{$links{$atLink}}) {
      $text =~ s/\@link\s+\Q$atLink\E\s+(.*?)\s?\@\/link/{
        my $x=$1;
        if($x !~ ?(\?i)<span class=\"code\">(.*\?)<\/span>?) { $x="<span class=\"code\">$x<\/span>"; }
        $x
      }/sge;
    } else {
      if (defined($xrefs{'xref'}->{$links{$atLink}}{'href'})) {
        $text =~ s/\@link\s+\Q$atLink\E\s+(.*?)\s?\@\/link/{
          my $x = $1;
          $x =~ s?<span class=\"code\">(.*\?)<\/span>?$1?sg;
          $x = "<a href=\"$xrefs{'xref'}->{$links{$atLink}}{'href'}\" class=\"code\">$x<\/a>"
        }/sge;
      } else {
        $text =~ s/\@link\s+\Q$atLink\E\s+(.*?)\s?\@\/link/<span class="XXX UNKNOWN code">$1<\/span>/sg;
      }
    }
  }
  return($text);
}

sub selectall_hash {
  my($dbh, $stmt, @args, @results) = (shift(@_), shift(@_), @_);
  my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, undef) or return;
  $sth->execute(@args) or return;
  while (my $row = $sth->fetchrow_hashref) { push(@results, $row); }
  $sth->finish;
  return(@results);
}
