#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
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

