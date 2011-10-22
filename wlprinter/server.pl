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
# wlprinter/server.pl - the web frontend for Wlprinter
#
#======================================================================
#
# arguments:
#   accesskey as id=...
#   action=list, returns the list of the available documents
#   action=head&docid=..., returns the first bytes of the document
#   action=get&docid=..., returns the specified document
#   action=delete&docid=..., deletes the specified document
#   action=deletall, deletes all the documents for this user
#

use FindBin '$Bin';
use Storable;
use File::Basename;

my $version = 1.12;

# SQL-Ledger defaults
$userspath = "users";
$spool     = "spool";

# wLprinter defaults
$headlength = 50;

eval { require "../wlprinter.conf"; };
eval { require "../sql-ledger.conf"; };

my $tokenfile = "../$userspath/wlprinter-tokens";
my $spooldir  = "../$spool";

read( STDIN, $_, $ENV{CONTENT_LENGTH} );

if ( $ENV{QUERY_STRING} ) {
	$_ = $ENV{QUERY_STRING};
}

if ( $ARGV[0] ) {
	$_ = $ARGV[0];
}

my @request = split(/&/);
my ( $fields, $username );

foreach (@request) {
	( $name, $value ) = split( /=/, $_ );
	$fields{$name} = $value;
}
$fields{docid} =~ s/\D//g;

$userid = $fields{id};
%tokens = %{ retrieve($tokenfile) };

unless ( $userspath && -d "../$userspath" ) {
	print "Content-Type: text/plain\n\n";
	print "-105\nConfiguration error.\n";
} elsif ( exists $tokens{$userid} ) {
	if ( $spool && -d $spooldir ) {
		$username = $tokens{$userid};
		eval { &{ $fields{action} } };
		if ($@) {
			print "Content-Type: text/plain\n\n";
			print "-104\nNo action specified.\n";
		}
	} else {
		print "Content-Type: text/plain\n\n";
		print "-106\nConfiguration error: spool directory.\n";
	}
} else {
	print "Content-Type: text/plain\n\n";
	print "-101\nNot authenticated.\n";
}

sub version {
	print "Content-Type: text/plain\n\n";
	print "1\n$version\n";
}

sub list {
	print "Content-Type: text/plain\n\n";
	print "1\n";
	for ( glob "$spooldir/$username/*" ) {
		print basename($_) . "\n";
	}
}

sub head {
	my $requestfile = "$spooldir/$username/$fields{docid}";
	if ( $fields{docid} ne "" && -e $requestfile ) {
		print "Content-Type: application/octet-stream\n\n";
		open INPUT, "<", $requestfile;
		for ( my $i = 0 ;
			$i < $headlength && ( $_ = getc(INPUT) ) ne "" ; $i++ )
		{
			print $_;
		}
		close INPUT;
	} else {
		print "Content-Type: text/plain\n\n";
		print "-102\nFile does not exist.\n";
	}
}

sub get {
	my $requestfile = "$spooldir/$username/$fields{docid}";
	if ( $fields{docid} ne "" && -e $requestfile ) {
		print "Content-Type: application/octet-stream\n\n";
		open INPUT, "<", $requestfile;
		while (<INPUT>) {
			print $_;
		}
		close INPUT;
	} else {
		print "Content-Type: text/plain\n\n";
		print "-102\nFile does not exist.\n";
	}
}

sub delete {
	my $requestfile = "$spooldir/$username/$fields{docid}";
	if ( $fields{docid} ne "" && -e $requestfile ) {
		unlink $requestfile;
		print "Content-Type: text/plain\n\n";
		print "1\nFile deleted.\n";
	} else {
		print "Content-Type: text/plain\n\n";
		print "-102\nFile does not exist.\n";
	}
}

sub deleteall {
	my $requestfiles = glob "$spooldir/$username/*";
	if ($requestfiles) {
		unlink $requestfiles;
		print "Content-Type: text/plain\n\n";
		print "1\nAll files deleted.\n";
	} else {
		print "Content-Type: text/plain\n\n";
		print "-103\nNothing deleted.\n";
	}
}

sub logout {
	delete $tokens{$userid};
	store \%tokens, $tokenfile;

	print "Content-Type: text/plain\n\n";
	print "1\nLogged out.\n";
}
