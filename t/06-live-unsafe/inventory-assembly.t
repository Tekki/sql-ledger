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

subtest 'Update assembly with the hightest number' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'assembly')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open part', 'partnumber-l', 0)
    ->store_ok('partnumber')
    ->press_button_ok('Update',    'update')
    ->press_button_ok('Save part', 'save')
    ->elements_exist('Link to partnumber', 'a.partnumber-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used part', 'a.number-l' => \'partnumber');
};

subtest 'Add new assemblies' => sub {
  for my $assembly ($t->config->{ic_assembly}{new}->@*) {
    $t->get_ok('Assembly screen', 'ic.pl', action => 'add', item => 'assembly')
      ->set_params_ok('Assembly header', notes => $t->test_stamp, $assembly->{header}->%*)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('partnumber');

    for my $component ($assembly->{components}->@*) {
      $t->update_row_ok('Add component', 'assembly_rows', $component->%*);
    }

    for my $customer ($assembly->{customers}->@*) {
      $t->update_row_ok('Add customer', 'customer_rows', $customer->%*);
    }

    $t->press_button_ok('Save assembly', 'save')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->texts_are('Most recently used assembly', 'a.number-l' => \'partnumber')
      ->follow_link_ok('Open assembly', 'number-l')
      ->params_are(
      'Content of assembly',
      notes      => \'test_stamp',
      partnumber => \'partnumber',
      $assembly->{expected}->%*
      );
  }
};
