#! /usr/bin/perl
#======================================================================
# WLprinter for SQL-Ledger
# Copyright (c) 2010-2011
#
# Author: Tekki
# License: GPL
#
#======================================================================
#
# wlprinter/fileprinter.pl - script to print in files
#
#======================================================================
#
# script that stores printed files in a subdirectory
# of the spool directory
# argument: username
#

use FindBin '$Bin';

chdir ($Bin);
eval {require "../sql-ledger.conf"; };

chomp(my $username = shift);

die "Username missing!\n" if $username eq "";

$counter = 0;
eval {require "../$spool/counter"};
$counter++;

my $fileid = sprintf "%05u%05u", $counter, rand 100000;
my $userdir = "../$spool/$username";
my $targetfile = "$userdir/$fileid";

mkdir "$userdir", 0700 unless -d "$userdir";

open OUTPUT, ">", $targetfile or die "Unable to write to $targetfile";

while (<>) {
    print OUTPUT  $_;
}

close OUTPUT;

open COUNTER, ">", "../$spool/counter";
print COUNTER "\$counter = $counter;\n";
close COUNTER;
