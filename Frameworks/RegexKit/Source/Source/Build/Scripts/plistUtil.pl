#!/usr/bin/perl -w

use strict;
require Foundation;

if($#ARGV != 2) { print("Usage: FILE KEY VALUE\n"); exit(1); }

my $fileNameString = NSString->stringWithCString_($ARGV[0]);
my $keyString = NSString->stringWithCString_($ARGV[1]);
my $valueString = NSString->stringWithCString_($ARGV[2]);

if(($$fileNameString == 0) || ($$keyString == 0) || ($$valueString == 0)) { print("CLI arguments turned in to a null NSString?\n"); exit(1); }

my $dict = NSMutableDictionary->dictionaryWithContentsOfFile_($fileNameString);

if($$dict == 0) { print("NSMutableDictionary returned NULL.\n"); exit(1); }

$dict->setObject_forKey_($valueString, $keyString);
if($dict->writeToFile_atomically_($fileNameString, 1) == 0) { print("dictionary writeToFile returned NO."); exit(1); }

exit(0);
