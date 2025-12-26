use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::PE';
  use_ok $package;
}

isa_ok $package, 'SL::PE';

can_ok $package,
  (
  'allocate_projectitems',   'chart_translations',
  'delete_job',              'delete_partsgroup',
  'delete_pricegroup',       'delete_project',
  'delete_translation',      'description_translations',
  'get_customer',            'get_jcitems',
  'get_job',                 'get_partsgroup',
  'get_pricegroup',          'get_project',
  'jobs',                    'list_stock',
  'partsgroup_translations', 'partsgroups',
  'pricegroups',             'project_sales_order',
  'project_translations',    'projects',
  'save_job',                'save_partsgroup',
  'save_pricegroup',         'save_project',
  'save_translation',        'stock_assembly',
  );
