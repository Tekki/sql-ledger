use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::IM';
  use_ok $package;
}

isa_ok $package, 'SL::IM';

can_ok $package,
  (
  'dataline',            'delete_import', 'import_coa',         'import_gl',
  'import_groups',       'import_item',   'import_order',       'import_sales_invoice',
  'import_vc',           'order_links',   'payment_links',      'paymentaccounts',
  'prepare_import_data', 'qrbill_links',  'reconcile_payments', 'sales_invoice_links',
  'taxrates',            'unreconciled_payments',
  );
