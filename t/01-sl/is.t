use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::IS';
  use_ok $package;
}

isa_ok $package, 'SL::IS';

can_ok $package,
  (
  'assembly_details',    'cogs',                 'cogs_difference',  'cogs_returns',
  'consolidate',         'consolidate_invoices', 'delete_invoice',   'generate_invoice',
  'invoice_details',     'post_invoice',         'process_assembly', 'process_kit',
  'project_description', 'retrieve_invoice',     'retrieve_item',    'reverse_invoice',
  );
