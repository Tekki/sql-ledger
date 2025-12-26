use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'ic.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'add',                        'add_assembly',
    'add_kit',                    'add_labor_overhead',
    'add_part',                   'add_service',
    'adjust_onhand',              'assembly_bom_transfer',
    'assembly_row',               'check_customer',
    'check_vendor',               'continue',
    'customer_row',               'delete',
    'edit',                       'form_footer',
    'form_header',                'generate_report',
    'history',                    'ic_print_options',
    'link_part',                  'list_assemblies',
    'list_assembly_bom_transfer', 'list_inventory',
    'makemodel_row',              'name_selected',
    'new_number',                 'parts_subtotal',
    'preview',                    'print_',
    'requirements',               'requirements_report',
    'restock_assemblies',         'save',
    'save_as_new',                'search',
    'search_transfer',            'select_name',
    'so_requirements',            'so_requirements_report',
    'stock_adjustment',           'stock_assembly',
    'supply_demand',              'supply_demand_report',
    'transfer',                   'transfer_list',
    'transfer_report',            'update',
    'upload_image',               'upload_imagefile',
    'vendor_row',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
