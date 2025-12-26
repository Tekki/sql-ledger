use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::AM';
  use_ok $package;
}

isa_ok $package, 'SL::AM';

can_ok $package,
  (
  '_snapshot_name',   'audit_log',        'audit_log_links',   'backup',
  'bank_accounts',    'business',         'check_access',      'closebooks',
  'closedto',         'company_defaults', 'currencies',        'defaultaccounts',
  'delete_account',   'delete_business',  'delete_currency',   'delete_department',
  'delete_gifi',      'delete_language',  'delete_mimetype',   'delete_paymentmethod',
  'delete_publickey', 'delete_role',      'delete_sic',        'delete_snapshots',
  'delete_warehouse', 'departments',      'earningsaccounts',  'encrypt_file',
  'exchangerates',    'get_account',      'get_bank',          'get_business',
  'get_currency',     'get_defaults',     'get_department',    'get_exchangerates',
  'get_gifi',         'get_language',     'get_paymentmethod', 'get_role',
  'get_sic',          'get_warehouse',    'gifi_accounts',     'import_publickey',
  'language',         'load_template',    'mimetypes',         'move',
  'paymentmethod',    'post_yearend',     'recurring_details', 'recurring_transactions',
  'remove_locks',     'reorder_rn',       'restore',           'restore_snapshot',
  'roles',            'save_account',     'save_bank',         'save_business',
  'save_currency',    'save_defaults',    'save_department',   'save_exchangerate',
  'save_gifi',        'save_language',    'save_mimetype',     'save_paymentmethod',
  'save_preferences', 'save_role',        'save_sic',          'save_snapshot',
  'save_taxes',       'save_template',    'save_warehouse',    'save_workstations',
  'sic',              'snapshots',        'taxes',             'update_recurring',
  'warehouses',       'workstations',
  );
