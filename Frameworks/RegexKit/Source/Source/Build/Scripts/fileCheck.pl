#!/usr/bin/perl -w

use strict;
use DBI;
require DBD::SQLite;
use Data::Dumper;
use Cwd 'realpath';
use File::Basename;
use File::Find;

if(! -r $ARGV[0]) { print("$ARGV[0] is not a valid database file.\n"); exit(1); }
if(! -d $ARGV[2]) { print("$ARGV[2] is not a valid directory.\n"); exit(1); }

my $doPrintSQL = 0;
my $fullPath = realpath($ARGV[2]);
my $clusterName = $ARGV[1];

my $dbh = DBI->connect("dbi:SQLite:dbname=$ARGV[0]","","", { AutoCommit => 1, RaiseError => 1 });

$dbh->do("PRAGMA synchronous = OFF");
$dbh->begin_work;

$dbh->do("INSERT INTO cluster (name, type, fullPath) VALUES ('$clusterName', 'Verification', '$fullPath')");

my $cid = $dbh->func('last_insert_rowid');

my $preparedFileInsert = $dbh->prepare("INSERT INTO file (cid, name, type, mode, linkTo, gfi_attr, gfi_type, gfi_creator) VALUES ($cid, ?, ?, ?, ?, ?, ?, ?)");

my @files = all_files_for_path($fullPath, 0);

foreach my $file (@files) {
  $preparedFileInsert->execute($file->{'relative'}, $file->{'type'}, $file->{'mode'}, $file->{'linkTo'}, $file->{'gfi_attr'}, $file->{'gfi_type'}, $file->{'gfi_creator'});

  if($doPrintSQL == 1) {
    my (@cols, @vals);
    
    push(@cols, 'cid');  push(@vals, $cid);
    push(@cols, 'name'); push(@vals, "'$file->{'relative'}'");
    push(@cols, 'type'); push(@vals, "'$file->{'type'}'");
    push(@cols, 'mode'); push(@vals, $file->{'mode'});
    if(defined($file->{'linkTo'})) { push(@cols, 'linkTo'); push(@vals, "'$file->{'linkTo'}'"); }
    if(defined($file->{'gfi_attr'})) { push(@cols, 'gfi_attr'); push(@vals, "'$file->{'gfi_attr'}'"); }
    if(defined($file->{'gfi_type'})) { push(@cols, 'gfi_type'); push(@vals, "'$file->{'gfi_type'}'"); }
    if(defined($file->{'gfi_creator'})) { push(@cols, 'gfi_creator'); push(@vals, "'$file->{'gfi_creator'}'"); }
    
    print("INSERT INTO file (" . join(", ", @cols) . ") VALUES (" . join(", ", @vals) . ");\n");
  }
}

undef($preparedFileInsert);

$dbh->do("ANALYZE");

my $mcid = (selectall_hash($dbh, "SELECT cid FROM cluster WHERE name = '$clusterName' AND type = 'Master'"))[0]->{'cid'};

$dbh->do("INSERT INTO common (mcid, vcid, name, type, mode, linkTo) SELECT $mcid, $cid, name, type, mode, linkTo FROM file WHERE cid = $mcid INTERSECT SELECT $mcid, $cid, name, type, mode, linkTo FROM file WHERE cid = $cid");

for my $row (selectall_hash($dbh, "SELECT * FROM file WHERE cid IN ($cid, $mcid)")) {
  $dbh->do("UPDATE common SET " . (($row->{'cid'} == $cid) ? "vfid":"mfid") ." = $row->{'fid'} WHERE mcid = $mcid AND vcid = $cid AND name = '$row->{'name'}' AND type = '$row->{'type'}' AND mode = $row->{'mode'}" . (($row->{'type'} eq 'l') ? " AND linkTo = '$row->{'linkTo'}'":""));
}

$dbh->commit;

$dbh->do("ANALYZE");

my (@master_names, @verify_names);
foreach my $row (@{$dbh->selectall_arrayref("SELECT \"'\" || name || \"'\" AS name FROM file WHERE cid = $mcid AND fid NOT IN (SELECT mfid FROM common WHERE mcid = $mcid AND vcid = $cid);")}) { push(@master_names, @{$row}[0]); }
foreach my $row (@{$dbh->selectall_arrayref("SELECT \"'\" || name || \"'\" AS name FROM file WHERE cid = $cid  AND fid NOT IN (SELECT vfid FROM common WHERE mcid = $mcid AND vcid = $cid);")})  { push(@verify_names, @{$row}[0]); }

if($#master_names != -1) {
  printf("warning: There are %d files missing from the '$clusterName' distribution directory.\n", $#master_names +1);
  my ($cutoff, @names) = ("");
  if($#master_names > 4) { for(my $x=0; $x<5; $x++) { $names[$x] = $master_names[$x]; } $cutoff = " ... (Remaining " . ($#master_names - 4) . " cut off)"; } else { @names = @master_names; }
  print("Files: " . join(", ", @names) . "$cutoff\n");
}

if($#verify_names != -1) {
  printf("warning: There are %d unknown, extra files in the '$clusterName' distribution directory.\n", $#verify_names +1);
  my ($cutoff, @names) = ("");
  if($#verify_names > 4) { for(my $x=0; $x<5; $x++) { $names[$x] = $verify_names[$x]; } $cutoff = " ... (Remaining " . ($#verify_names - 4) . " cut off)"; } else { @names = @verify_names; }
  print("Files: " . join(", ", @names) . "$cutoff\n");
}

if(($dbh->selectall_arrayref("SELECT count(*) FROM cluster WHERE created < datetime('now', '-15 minutes') AND type != 'Master'"))->[0]->[0]) {
  $dbh->begin_work;
  $dbh->do("DELETE FROM cluster WHERE created <= datetime('now', '-15 minutes') AND type != 'Master'");
  $dbh->commit;
}

$dbh->disconnect();

if(($#master_names != -1) || ($#verify_names != -1)) { exit(1); }

exit(0);



sub all_files_for_path {
  my ($path, $doGetFileInfo, @files, $root, @info) = (shift, shift);
  ($root = $path)  =~ s/(.*?)(\/?)$/$1/;
  find({wanted => sub { if($_ eq $root) { return; } push(@files, $_); }, no_chdir => 1}, ($path));
  
  foreach my $filename (@files) {
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
    my ($type, $relative, $linkTo) = ("?", $filename);
    
    if(-l $filename) { $type="l"; $linkTo = readlink($filename); } elsif(-d $filename) { $type="d"; }
    elsif(-f $filename) { $type="f"; } elsif(-p $filename) { $type="p"; } elsif(-S $filename) { $type="S"; }
    elsif(-b $filename) { $type="b"; } elsif(-c $filename) { $type="c"; }
    
    my($gfi_type, $gfi_creator, $gfi_attr);
    if($doGetFileInfo == 1) {
      if($type eq "l") {
        open(GFI,"/Developer/Tools/GetFileInfo -P '$filename' |");
      } else {
        open(GFI,"/Developer/Tools/GetFileInfo '$filename' |");
      }
      while(<GFI>) {
        if(/type:\s+"(.{0,4})"/) { $gfi_type = $1; }
        if(/creator:\s+"(.{0,4})"/) { $gfi_creator = $1; }
        if(/attributes:\s+(\w+)\b/) { $gfi_attr = $1; }
      }
      close(GFI);
    }
    
    $relative =~ s/$root//;
      my $thisFile = {'type' => $type, 'mode' => $mode, 'full' => $filename, 'relative' => $relative, 'linkTo' => $linkTo,
        'gfi_type' => $gfi_type, 'gfi_creator' => $gfi_creator, 'gfi_attr' => $gfi_attr};
    push(@info, $thisFile);
  }
  return(@info);
}


sub selectall_hash {
  my($dbh, $stmt, @args, @results) = (shift(@_), shift(@_), @_);
  my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, undef) or return;
  $sth->execute(@args) or return;
  while (my $row = $sth->fetchrow_hashref) { push(@results, $row); }
  $sth->finish;
  return(@results);
}
