use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'im.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    '_do_export_payments',      'continue',
    'ex_customer',              'ex_payment',
    'ex_vc',                    'ex_vendor',
    'export',                   'export_customers',
    'export_payments',          'export_payments_csv',
    'export_payments_txt',      'export_payments_xml',
    'export_screen_customer',   'export_screen_payment',
    'export_screen_vc',         'export_screen_vendor',
    'export_vc',                'export_vendors',
    'im_camt054_payment',       'im_coa',
    'im_csv_payment',           'im_customer',
    'im_gl',                    'im_item',
    'im_labor',                 'im_order',
    'im_part',                  'im_partsgroup',
    'im_payment',               'im_purchase_order',
    'im_qrbill',                'im_sales_invoice',
    'im_sales_order',           'im_service',
    'im_v11_payment',           'im_vc',
    'im_vendor',                'import',
    'import_chart_of_accounts', 'import_customers',
    'import_file',              'import_general_ledger',
    'import_groups',            'import_items',
    'import_labor_overhead',    'import_orders',
    'import_parts',             'import_payments',
    'import_qrbill',            'import_sales_invoices',
    'import_services',          'import_vc',
    'import_vendors',           'process_qrbill',
    'reconcile_payments',       'xmlcsvhdr',
    'xmldata',                  'xmlform',
    'xmlin',                    'xmlorder',
    'xrefhdr',                  'yes__reconcile_payments',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
