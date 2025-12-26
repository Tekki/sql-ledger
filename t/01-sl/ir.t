use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::IR';
  use_ok $package;
}

isa_ok $package, 'SL::IR';

can_ok $package,
  (
  'cogs',          'cogs_returns', 'delete_invoice', 'invoice_details',
  'item_links',    'post_invoice', 'process_kit',    'retrieve_invoice',
  'retrieve_item', 'reverse_invoice',
  );
