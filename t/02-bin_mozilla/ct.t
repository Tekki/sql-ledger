use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'ct.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    '_transaction_report', 'add',                'add_customer',     'add_transaction',
    'add_vendor',          'ap_transaction',     'ap_transactions',  'ar_transaction',
    'ar_transactions',     'continue',           'create_links',     'credit_invoice',
    'credit_note',         'customer_pricelist', 'debit_invoice',    'debit_note',
    'delete',              'delete_customers',   'delete_vendors',   'display_form',
    'display_pricelist',   'edit',               'form_footer',      'form_header',
    'history',             'include_in_report',  'item_selected',    'list_history',
    'list_names',          'list_subtotal',      'lookup_name',      'new_number',
    'pos',                 'pricelist',          'pricelist_footer', 'pricelist_header',
    'purchase_order',      'purchase_orders',    'quotation',        'quotations',
    'retrieve_names',      'rfq',                'rfqs',             'sales_invoice',
    'sales_order',         'sales_orders',       'save',             'save_as_new',
    'save_pricelist',      'search',             'search_name',      'select_item',
    'shipping_address',    'shipto_selected',    'transactions',     'update',
    'vendor_invoice',      'vendor_pricelist',   'yes__delete',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
