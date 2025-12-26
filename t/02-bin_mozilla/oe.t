use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'oe.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    '_transactions_spreadsheet', 'add',
    'consolidate_orders',        'consolidate_orders_to_invoice',
    'create_backorder',          'delete',
    'display_ship_receive',      'done',
    'edit',                      'form_footer',
    'form_header',               'generate_orders',
    'generate_purchase_orders',  'generate_sales_invoices',
    'invoice',                   'lookup_order',
    'order_links',               'po_orderitems',
    'prepare_order',             'print_and_save',
    'print_and_save_as_new',     'quotation_',
    'rfq_',                      'sales_invoice',
    'save',                      'save_as_new',
    'search',                    'select_vendor',
    'ship_all',                  'ship_receive',
    'subtotal',                  'transactions',
    'update',                    'vendor_invoice',
    'vendor_selected',           'yes',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
