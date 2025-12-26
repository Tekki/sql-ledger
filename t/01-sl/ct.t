use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::CT';
  use_ok $package;
}

isa_ok $package, 'SL::CT';

can_ok $package,
  (
  'batch_delete',   'create_links',  'delete',         'get_history',
  'pricelist',      'retrieve_item', 'retrieve_names', 'save',
  'save_pricelist', 'search',        'ship_to',
  );
