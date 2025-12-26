use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::HR';
  use_ok $package;
}

isa_ok $package, 'SL::HR';

can_ok $package,
  (
  'acsrole',         'deductions',       'delete_deduction', 'delete_employee',
  'delete_wage',     'employees',        'get_deduction',    'get_employee',
  'get_wage',        'isadmin',          'payroll_links',    'payroll_transactions',
  'payslip_details', 'post_transaction', 'save_deduction',   'save_employee',
  'save_wage',       'search_payroll',   'wages',
  );
