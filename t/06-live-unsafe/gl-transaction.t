# Never run this test on a production system!
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
  plan tests => 5;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Update latest GL transaction' => sub {
  $t->get_ok('Report frontend', 'gl.pl', action => 'search')
    ->set_params_ok('Time range', datefrom => $t->date_jan1, dateto => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open transaction', 'gl-l', 0)
    ->store_ok('reference')
    ->press_button_ok('Update',           'update')
    ->press_button_ok('Post transaction', 'post')
    ->press_button_ok('Confirm changes',  'continue')
    ->elements_exist('Links to number', 'a.gl-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used transaction', 'a.number-l' => \'reference');
};

subtest 'Add new GL transactions' => sub {
  for my $tr ($t->config->{gl_transaction}{new}->@*) {
    $t->get_ok('Transaction screen', 'gl.pl', action => 'add')
      ->set_params_ok('Transaction header', description => $t->test_stamp, $tr->{header}->%*)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('reference');

    for my $row ($tr->{rows}->@*) {
      $t->update_row_ok('Add row', 'rowcount', $row->%*);
    }

    $t->press_button_ok('Post transaction', 'post')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->texts_are('Most recently used transaction', 'a.number-l' => \'reference')
      ->follow_link_ok('Open transaction', 'number-l')
      ->params_are(
        'Content of transaction',
        description => \'test_stamp',
        reference   => \'reference',
        $tr->{expected}->%*
        )
      ->rows_are('Transaction rows', $tr->{expected_rows}->@*)
  }
};

$t->remove_locks_ok;
