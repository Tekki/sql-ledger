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
