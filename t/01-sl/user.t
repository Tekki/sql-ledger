use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::User';
  use_ok $package;
}

isa_ok $package, 'SL::User';

can_ok $package,
  (
  'add_db_size',   'calc_version',  'check_recurring', 'config_vars',
  'country_codes', 'create_config', 'dbconnect_vars',  'dbcreate',
  'dbdelete',      'dbdrivers',     'dbpassword',      'dbsources',
  'dbupdate',      'delete_login',  'encoding',        'error',
  'login',         'logout',        'new',             'process_query',
  'save_member',   'script_version',
  );
