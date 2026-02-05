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
  plan tests => 6;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Update timecard' => sub {
  $t->get_ok('Report frontend', 'jc.pl', action => 'search', type => 'timecard', project => 'project')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open time card', 'id-l', 0)
    ->store_ok('id')
    ->press_button_ok('Update', 'update')
    ->press_button_ok('Save timecard', 'save')
    ->press_button_ok('Confirm changes', 'continue')
    ->elements_exist('Links to time card', 'a.id-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used time card', 'a.number-l' => \'id');
};

subtest 'Add timecards' => sub {
  for my $tc ($t->config->{timecard}{new}->@*) {
    $t->get_ok('Timecard screen', 'jc.pl', action => 'add', type => 'timecard', project => 'project')
      ->set_params_ok('Timecard header', $tc->{header}->%*)
      ->press_button_ok('Update', 'update')
      ->set_params_ok('Description and time', description => $t->test_stamp, $tc->{time}->%*)
      ->press_button_ok('Update', 'update')
      ->press_button_ok('Save timecard', 'save')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->follow_link_ok('Open timecard', 'number-l')
      ->params_are(
        'Contents of timecard',
        description => \'test_stamp',
        $tc->{expected}->%*,
      );
  }
};

subtest 'Convert timecards to orders' => sub {
  $t->get_ok('Report frontend', 'pe.pl', action => 'project_sales_order')
    ->set_params_ok('Set beginning date', transdatefrom => $t->date_today)
    ->press_button_ok('Generate report', 'continue')
    ->press_button_ok('Generate orders', 'generate_sales_orders')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->follow_link_ok('Open order', 'number-l')
    ->rows_are('Order rows', {description => \'test_stamp'});
};

$t->remove_locks_ok;
