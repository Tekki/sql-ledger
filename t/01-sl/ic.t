use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::IC';
  use_ok $package;
}

isa_ok $package, 'SL::IC';

can_ok $package,
  (
  'adjust_inventory', 'adjust_onhand',
  'all_parts',        'assembly_demand',
  'assembly_item',    'create_links',
  'delete',           'get_assembly_bom_transfer',
  'get_inventory',    'get_part',
  'get_warehouses',   'history',
  'include_assembly', 'orphaned',
  'requirements',     'retrieve_assemblies',
  'retrieve_items',   'save',
  'so_requirements',  'stock_assemblies',
  'supply_demand',    'transfer',
  'transfer_report',  'update_assembly',
  );
