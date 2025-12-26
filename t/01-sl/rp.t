use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::RP';
  use_ok $package;
}

isa_ok $package, 'SL::RP';

can_ok $package,
  (
  'add_accounts',    'aging',         'balance_sheet',   'create_links',
  'get_accounts',    'get_customer',  'get_taxaccounts', 'income_statement',
  'paymentaccounts', 'payments',      'reminder',        'save_level',
  'tax_report',      'trial_balance', 'yearend_statement',
  );
