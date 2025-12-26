use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::AA';
  use_ok $package;
}

isa_ok $package, 'SL::AA';

can_ok $package,
  (
  'EMPTY_PROJECTS',     'NO_PROJECTS',         'all_names',    'company_details',
  'delete_transaction', 'delete_transactions', 'get_name',     'post_transaction',
  'reverse_vouchers',   'ship_to',             'transactions', 'vc_links',
  );
