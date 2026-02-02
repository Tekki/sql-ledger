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

subtest 'Update part with the hightest number' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'part')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open part', 'partnumber-l', 0)
    ->store_ok('partnumber')
    ->press_button_ok('Update',           'update')
    ->press_button_ok('Save part', 'save')
    ->elements_exist('Link to partnumber', 'a.partnumber-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used part', 'a.number-l' => \'partnumber');
};

subtest 'Add new parts' => sub {
  for my $part ($t->config->{ic_part}{new}->@*) {
    $t->get_ok('Part screen', 'ic.pl', action => 'add', item => 'part')
      ->set_params_ok('Part header', notes => $t->test_stamp, $part->{header}->%*)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('partnumber');

    for my $customer ($part->{customers}->@*) {
      $t->update_row_ok('Add customer', 'customer_rows', $customer->%*);
    }

    for my $vendor ($part->{vendors}->@*) {
      $t->update_row_ok('Add vendor', 'vendor_rows', $vendor->%*);
    }

    $t->press_button_ok('Save part', 'save')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->texts_are('Most recently used part', 'a.number-l' => \'partnumber')
      ->follow_link_ok('Open part', 'number-l')
      ->params_are(
      'Content of part',
      notes      => \'test_stamp',
      partnumber => \'partnumber',
      $part->{expected}->%*
      );
  }
};
