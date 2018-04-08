#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Accounts Receivable
#
#======================================================================

use SL::PE;
use SL::IS;

require "$form->{path}/arap.pl";
require "$form->{path}/arapprn.pl";
require "$form->{path}/aa.pl";

$form->{vc} = 'customer';
$form->{ARAP} = 'AR';

1;
# end of main


=encoding utf8

=head1 NAME

bin/mozilla/ar.pl - Accounts Receivable

=head1 DESCRIPTION

L<bin::mozilla::ar> contains functions for accounts receivable.

=head1 DEPENDENCIES

L<bin::mozilla::ar>

=over

=item * uses
L<SL::IS>,
L<SL::PE>

=item * requires
L<bin::mozilla::aa>,
L<bin::mozilla::arap>,
L<bin::mozilla::arapprn>

=back

=head1 FUNCTIONS

L<bin::mozilla::ar> implements the following functions:

=cut
