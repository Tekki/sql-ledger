use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 4;

my $package;

BEGIN {
  $package = 'SL::Form';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

isa_ok $package, 'SL::Form';
my $obj = new_ok $package;

can_ok $obj,
  (
  'add_date',              'add_shipto',        'all_business',      'all_countries',
  'all_departments',       'all_employees',     'all_languages',     'all_projects',
  'all_references',        'all_roles',         'all_taxaccounts',   'all_vc',
  'all_warehouses',        'all_years',         'audittrail',        'check_exchangerate',
  'cleanup',               'create_links',      'create_lock',       'current_date',
  'cwd',                   'datediff',          'datetonum',         'dayofmonth',
  'dbconnect',             'dbconnect_noauto',  'dberror',           'dbquote',
  'debug',                 'delete_references', 'download_tmpfile',  'dump',
  'dump_form',             'dump_timer',        'error',             'escape',
  'exchangerate_defaults', 'fastcwd',           'fastgetcwd',        'fdld',
  'format_amount',         'format_date',       'format_dcn',        'format_line',
  'format_string',         'from_to',           'gentex',            'get_currencies',
  'get_defaults',          'get_employee',      'get_exchangerate',  'get_name',
  'get_onhand',            'get_partsgroup',    'get_peripherals',   'get_recurring',
  'get_reference',         'getcwd',            'header',            'helpref',
  'hide_form',             'info',              'isblank',           'json_error',
  'lastname_used',         'like',              'load_defaults',     'load_module',
  'mimetype',              'new',               'numtextrows',       'pad',
  'parse_amount',          'parse_callback',    'parse_template',    'perl_modules',
  'print_button',          'process_template',  'process_tex',       'qr_variables',
  'quote',                 'redirect',          'redo_rows',         'remove_locks',
  'report_level',          'reports',           'rerun_latex',       'reset_shipped',
  'retrieve_form',         'retrieve_report',   'round_amount',      'run_latex',
  'save_exchangerate',     'save_form',         'save_intnotes',     'save_recurring',
  'save_reference',        'save_report',       'save_status',       'select_option',
  'set_cookie',            'sha256_hex',        'sort_column_index', 'sort_columns',
  'sort_order',            'split_date',        'timegm',            'timelocal',
  'unescape',              'unquote',           'update_balance',    'update_defaults',
  'update_exchangerate',   'update_status',     'valid_date',        'weekday',
  'workingday',
  );
