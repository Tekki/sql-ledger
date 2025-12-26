use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'pe.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'add',                  'add_group',
    'add_job',              'add_pricegroup',
    'add_project',          'continue',
    'customer_selected',    'delete',
    'display_form',         'edit',
    'edit_translation',     'generate_sales_orders',
    'jcitems',              'job_footer',
    'job_header',           'job_report',
    'list_projects',        'list_stock',
    'list_translations',    'name_selected',
    'partsgroup_footer',    'partsgroup_header',
    'partsgroup_report',    'prepare_job',
    'prepare_partsgroup',   'prepare_pricegroup',
    'prepare_project',      'pricegroup_footer',
    'pricegroup_header',    'pricegroup_report',
    'project_footer',       'project_header',
    'project_jcitems_list', 'project_report',
    'project_sales_order',  'sales_order_footer',
    'sales_order_header',   'save',
    'save_as_new',          'search',
    'select_customer',      'select_name',
    'stock',                'translation',
    'translation_footer',   'translation_header',
    'update',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
