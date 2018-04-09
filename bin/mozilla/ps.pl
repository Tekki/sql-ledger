#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#=====================================================================
#
# point of sale script
#
#=====================================================================

use SL::AA;
use SL::IS;
use SL::RP;

require "$form->{path}/rp.pl";
require "$form->{path}/ar.pl";
require "$form->{path}/is.pl";
require "$form->{path}/pos.pl";

# customizations
if (-f "$form->{path}/custom/pos.pl") {
  eval { require "$form->{path}/custom/pos.pl"; };
}
if (-f "$form->{path}/custom/$form->{login}/pos.pl") {
  eval { require "$form->{path}/custom/$form->{login}/pos.pl"; };
}

1;
# end

=encoding utf8

=head1 NAME

bin/mozilla/ps.pl - Point of sale script

=head1 DESCRIPTION

L<bin::mozilla::ps> contains functions for point of sale script.

=head1 DEPENDENCIES

L<bin::mozilla::ps>

=over

=item * uses
L<SL::AA>,
L<SL::IS>,
L<SL::RP>

=item * requires
L<bin::mozilla::ar>,
L<bin::mozilla::is>,
L<bin::mozilla::pos>,
L<bin::mozilla::rp>

=item * optionally requires
F<< bin/mozilla/custom/$form->{login}/pos.pl >>,
F<bin/mozilla/custom/pos.pl>

=back

=head1 FUNCTIONS

L<bin::mozilla::ps> implements the following functions:

=cut
