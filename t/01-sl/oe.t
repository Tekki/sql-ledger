use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::OE';
  use_ok $package;
}

isa_ok $package, 'SL::OE';

can_ok $package,
  (
  'add_items_required', 'adj_inventory', 'adj_onhand',      'assembly_details',
  'consolidate_orders', 'delete',        'generate_orders', 'get_soparts',
  'get_warehouses',     'lookup_order',  'order_details',   'project_description',
  'retrieve',           'save',          'save_inventory',  'transactions',
  );
