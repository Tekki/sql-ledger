#======================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# Accounts Payable
#
#======================================================================

use SL::IR;

require "$form->{path}/arap.pl";
require "$form->{path}/arapprn.pl";
require "$form->{path}/aa.pl";

$form->{vc} = 'vendor';
$form->{ARAP} = 'AP';

1;
# end of main


=encoding utf8

=head1 NAME

bin/mozilla/ap.pl - Accounts Payable

=head1 DESCRIPTION

L<bin::mozilla::ap> contains functions for accounts payable.

=head1 DEPENDENCIES

L<bin::mozilla::ap>

=over

=item * uses
L<SL::IR>

=item * requires
L<bin::mozilla::aa>,
L<bin::mozilla::arap>,
L<bin::mozilla::arapprn>

=back

=head1 FUNCTIONS

L<bin::mozilla::ap> implements the following functions:

=cut
