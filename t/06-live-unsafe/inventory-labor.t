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

subtest 'Update labor with the hightest number' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'labor')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open labor', 'partnumber-l', 0)
    ->store_ok('partnumber')
    ->form_fields_exist('partsgroup', 'IC_expense', 'IC_inventory')
    ->form_fields_exist_not('IC_income')
    ->press_button_ok('Update',    'update')
    ->press_button_ok('Save labor', 'save')
    ->elements_exist('Link to partnumber', 'a.partnumber-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used labor', 'a.number-l' => \'partnumber');
};

subtest 'Add new labors' => sub {
  for my $labor ($t->config->{ic_labor}{new}->@*) {
    $t->get_ok('Labor screen', 'ic.pl', action => 'add', item => 'labor')
      ->set_params_ok('Labor header', notes => $t->test_stamp, $labor->{header}->%*)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('partnumber');

    $t->press_button_ok('Save labor', 'save')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->texts_are('Most recently used labor', 'a.number-l' => \'partnumber')
      ->follow_link_ok('Open labor', 'number-l')
      ->params_are(
      'Content of labor',
      notes      => \'test_stamp',
      partnumber => \'partnumber',
      $labor->{expected}->%*
      );
  }
};
