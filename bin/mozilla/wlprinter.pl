#======================================================================
# WLprinter for SQL-Ledger
# Copyright (c) 2010-2011
#
# Author: Tekki
# License: GPL
#
#======================================================================
#
# bin/mozilla/wlprinter.pl - the page that redirects to JNLP
#
#======================================================================

use Storable;

my $tekkiserver = "http://tekki.ch/software/Wlprinter.jar";

1;

sub open {
	my $username  = $form->{login};
	my $tokenfile = "$userspath/wlprinter-tokens";
	my $userid    = sprintf "%.0f", ( rand 10 ) * 100000000000;
	my %tokens;

	if ( -e "$tokenfile" ) {
		%tokens = %{ retrieve($tokenfile) };
		while ( ( $key, $value ) = each %tokens ) {
			if ( $value eq $username ) {
				delete $tokens{$key};
			}
		}
	}
	$tokens{"$userid"} = $username;

	store \%tokens, $tokenfile;
	unless ($serveraddress) {
		$ENV{HTTP_REFERER} =~ m|/\w+\.pl|;
		$serveraddress = $` . "/wlprinter";
	}
	my $serverUrl = "$serveraddress/server.pl?id=$userid";
	my $jarUrl    = $externalclient ? $tekkiserver : "Wlprinter.jar";

	#print "Content-Type: text/plain\n\n";
	print qq|Content-Type: application/x-java-jnlp-file
Content-disposition: attachment; filename=\"wlprinter.jnlp\"

<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<jnlp codebase="$serveraddress" spec="1.0+">
    <information>
        <title>WLprinter</title>
        <vendor>Tekki</vendor>
        <homepage href="http://www.tekki.ch/software"/>
        <description>Wlprinter: Web to local print solution</description>
        <description kind="short">WLprinter</description>
    </information>
    <security>
        <all-permissions/>
    </security>
    <resources>
        <j2se version="1.6+" href="http://java.sun.com/products/autodl/j2se"/>
        <jar href="$jarUrl" main="true"/>
    </resources>
    <application-desc main-class="ch.tekki.wlprinter.WlprinterApplication">
        <argument>$serverUrl</argument>
        <argument>$interval</argument>
    </application-desc>
</jnlp>
|;
}
