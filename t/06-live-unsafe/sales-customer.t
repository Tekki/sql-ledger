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
  plan tests => 4;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Update customer' => sub {
  $t->get_ok('Report frontend', 'ct.pl', action => 'search', db => 'customer')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open customer', 'name-l', 0)
    ->store_ok('customernumber')
    ->set_action_ok('update')
    ->post_ok('Update')
    ->press_button_ok('Save customer', 'save')
    ->elements_exist('Links to name, e-mail', 'a.name-l', 'a.email-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used customer', 'a.number-l' => \'customernumber');
};

subtest 'Add new customers' => sub {
  for my $vc ($t->config->{customer}{new}->@*) {
    $t->get_ok('Customer screen', 'ct.pl', action => 'add', db => 'customer')
      ->set_params_ok('Customer data', notes => $t->test_stamp, $vc->{header}->%*)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('customernumber')
      ->press_button_ok('Save customer', 'save')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->texts_are('Most recently used customer', 'a.number-l' => \'customernumber')
      ->follow_link_ok('Open customer', 'number-l')
      ->params_are(
      'Content of customer',
      notes          => \'test_stamp',
      customernumber => \'customernumber',
      $vc->{expected}->%*
      );
  }
};
