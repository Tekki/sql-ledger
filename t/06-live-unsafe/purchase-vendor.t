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

subtest 'Update vendor' => sub {
  $t->get_ok('Report frontend', 'ct.pl', action => 'search', db => 'vendor')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open vendor', 'name-l', 0)
    ->store_ok('vendornumber')
    ->set_action_ok('update')
    ->post_ok('Update')
    ->press_button_ok('Save vendor', 'save')
    ->elements_exist('Links to name, e-mail', 'a.name-l', 'a.email-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used vendor', 'a.number-l' => \'vendornumber');
};

subtest 'Add new vendors' => sub {
  for my $vc ($t->config->{vendor}{new}->@*) {
    $t->get_ok('Vendor screen', 'ct.pl', action => 'add', db => 'vendor')
      ->set_params_ok('Vendor data', notes => $t->test_stamp, $vc->{header}->%*)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('vendornumber')
      ->press_button_ok('Save vendor', 'save')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->texts_are('Most recently used vendor', 'a.number-l' => \'vendornumber')
      ->follow_link_ok('Open vendor', 'number-l')
      ->params_are(
      'Content of vendor',
      notes          => \'test_stamp',
      vendornumber => \'vendornumber',
      $vc->{expected}->%*
      );
  }
};
