use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'am.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'account_header',       'add',
    'add_account',          'add_business',
    'add_currency',         'add_department',
    'add_exchange_rate',    'add_gifi',
    'add_language',         'add_mimetype',
    'add_payment_method',   'add_role',
    'add_sic',              'add_snapshot',
    'add_warehouse',        'audit_control',
    'audit_log',            'backup',
    'bank_accounts',        'bank_footer',
    'bank_header',          'business_header',
    'clear_semaphores',     'company_logo',
    'config',               'continue',
    'copy_to_coa',          'currency_header',
    'defaults',             'delete',
    'delete_account',       'delete_business',
    'delete_currency',      'delete_department',
    'delete_gifi',          'delete_language',
    'delete_mimetype',      'delete_paymentmethod',
    'delete_role',          'delete_sic',
    'delete_snapshots',     'delete_sql_command',
    'delete_warehouse',     'department_header',
    'deselect_all',         'display_form',
    'display_stylesheet',   'display_taxes',
    'do_add_snapshot',      'do_delete_snapshots',
    'do_lock_dataset',      'do_restore',
    'do_restore_snapshot',  'do_unlock_dataset',
    'doclose',              'edit',
    'edit_account',         'edit_bank',
    'edit_business',        'edit_currency',
    'edit_department',      'edit_exchangerate',
    'edit_gifi',            'edit_language',
    'edit_mimetype',        'edit_paymentmethod',
    'edit_recurring',       'edit_role',
    'edit_sic',             'edit_template',
    'edit_warehouse',       'email_recurring',
    'exchangerate_header',  'form_footer',
    'formnames',            'generate_yearend',
    'get_dataset',          'gifi_footer',
    'gifi_header',          'language_header',
    'list_account',         'list_audit_log',
    'list_business',        'list_currencies',
    'list_department',      'list_exchangerates',
    'list_gifi',            'list_language',
    'list_mimetypes',       'list_paymentmethod',
    'list_roles',           'list_sic',
    'list_snapshots',       'list_templates',
    'list_warehouse',       'lock_dataset',
    'mimetype_header',      'monitor',
    'move',                 'paymentmethod_header',
    'pg_dump',              'print_recurring',
    'process_transactions', 'recurring_transactions',
    'remove_locks',         'restore',
    'restore_snapshot',     'role_header',
    'run_sql_command',      'save',
    'save_account',         'save_as_new',
    'save_bank',            'save_business',
    'save_currency',        'save_defaults',
    'save_department',      'save_exchangerate',
    'save_gifi',            'save_language',
    'save_mimetype',        'save_paymentmethod',
    'save_preferences',     'save_role',
    'save_sic',             'save_sql',
    'save_sql_command',     'save_taxes',
    'save_template',        'save_warehouse',
    'save_workstations',    'search_exchangerates',
    'select_all',           'sic_header',
    'taxes',                'unlock_dataset',
    'update',               'update_taxes',
    'update_workstations',  'upgrade_dataset',
    'warehouse_header',     'workstations',
    'yearend',              'yes',
    'yes_delete_language',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
