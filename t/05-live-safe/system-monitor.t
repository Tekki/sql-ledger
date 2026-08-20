use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More;
use SL::TestClient;

chdir "$FindBin::Bin/../..";

my $configfile = "$FindBin::Bin/../testdata/testconfig.yml";
my $t;

if ($ENV{SL_LIVETEST}) {
  plan tests => 4;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok('admin')->api_login_ok;

subtest 'Run SQL query' => sub {
  $t->get_ok('Monitor screen', 'am.pl', action => 'monitor')
    ->buttons_exist('run_sql_command')
    ->buttons_exist_not('save_sql_command', 'delete_sql_command', 'spreadsheet')
    ->accesskeys_exist(qw|? R|)
    ->set_params_ok('Add query', sql => 'SELECT customernumber, name FROM customer ORDER BY name')
    ->press_button_ok('Run query', 'run_sql_command')
    ->buttons_exist('save_sql_command', 'spreadsheet')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};

subtest 'Run SQL query with parameters' => sub {
  my $parameter = $t->date_jan1 . " -- start date\n" . $t->date_dec31 . " -- end date";

  $t->get_ok('Monitor screen', 'am.pl', action => 'monitor')
    ->set_params_ok(
    'Add query',
    sql       => 'SELECT transdate, invnumber FROM ar WHERE transdate BETWEEN ? AND ?',
    parameter => $parameter,
    )
    ->press_button_ok('Run query', 'run_sql_command');
};
