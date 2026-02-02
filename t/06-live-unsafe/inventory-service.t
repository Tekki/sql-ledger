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

subtest 'Update service with the hightest number' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'service')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open service', 'partnumber-l', 0)
    ->store_ok('partnumber')
    ->press_button_ok('Update',           'update')
    ->press_button_ok('Save service', 'save')
    ->elements_exist('Link to partnumber', 'a.partnumber-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used service', 'a.number-l' => \'partnumber');
};

subtest 'Add new services' => sub {
  for my $service ($t->config->{ic_service}{new}->@*) {
    $t->get_ok('Service screen', 'ic.pl', action => 'add', item => 'service')
      ->set_params_ok('Service header', notes => $t->test_stamp, $service->{header}->%*)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('partnumber');

    for my $customer ($service->{customers}->@*) {
      $t->update_row_ok('Add customer', 'customer_rows', $customer->%*);
    }

    for my $vendor ($service->{vendors}->@*) {
      $t->update_row_ok('Add vendor', 'vendor_rows', $vendor->%*);
    }

    $t->press_button_ok('Save service', 'save')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->texts_are('Most recently used service', 'a.number-l' => \'partnumber')
      ->follow_link_ok('Open service', 'number-l')
      ->params_are(
      'Content of service',
      notes      => \'test_stamp',
      partnumber => \'partnumber',
      $service->{expected}->%*
      );
  }
};
