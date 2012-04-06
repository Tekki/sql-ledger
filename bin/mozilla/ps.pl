#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
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

require "$form->{path}/ar.pl";
require "$form->{path}/is.pl";
require "$form->{path}/rp.pl";
require "$form->{path}/pos.pl";

# customizations
if (-f "$form->{path}/custom_pos.pl") {
  eval { require "$form->{path}/custom_pos.pl"; };
}
if (-f "$form->{path}/$form->{login}_pos.pl") {
  eval { require "$form->{path}/$form->{login}_pos.pl"; };
}

1;
# end
