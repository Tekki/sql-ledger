use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Mojo::File 'tempfile';

use Test::More tests => 6;

my $class;

BEGIN {
  $class = 'SL::TestClient';
  use_ok $class;
}

my $configfile = tempfile->spew(<<~'EOT');
  ---
  server:
    url: http://localhost/sql-ledger
    username: testuser@testdb
    password: testpwd
  EOT

my %config = (
  server => {
    url      => 'http://localhost/sql-ledger',
    username => 'testuser@testdb',
    password => 'testpwd',
  }
);

my $obj = new_ok $class, [configfile => $configfile];

can_ok $obj, (

  # fields
  'config', 'form_params', 'form_script', 'mj',

  # methods
  'api_login_ok',      'body',           'connect_ok',      'date_dec31',      'date_jan1',
  'date_today',        'date_tomorrow',  'date_yesterday',  'dom',             'download_ok',
  'download_is',       'elements_exist', 'follow_link_ok',  'form_exists',     'form_fields_exist',
  'form_hidden_exist', 'form_params',    'get_download_ok', 'get_ok',          'headers',
  'json',              'params_are',     'post_ok',         'press_button_ok', 'remove_locks_ok',
  'set_action_ok',     'set_form',       'set_params_ok',   'store_ok',        'test_stamp',
  'texts_are',         'update_row_ok',  'user_login_ok',   'DESTROY',

  # internal mmethods
  '_build_path', '_download_file', '_register_problems',

);

is_deeply $obj->config, \%config, 'Config values';

like $obj->test_stamp, qr/Live Test \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, 'Test stamp';

subtest 'Dates' => sub {
  my $year  = (localtime)[5] + 1900;
  my $month = (localtime)[4] + 1;
  my $day   = (localtime)[3];

  my $year1 = $month < 4 ? $year - 1 : $year;

  is $obj->date_jan1,  "${year1}0101",                             'Jan 1';
  is $obj->date_dec31, "${year}1231",                              'Dec 31';
  is $obj->date_today, sprintf('%d%02d%02d', $year, $month, $day), 'Today';
};
