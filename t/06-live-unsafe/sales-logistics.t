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
  plan tests => 3;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok()->api_login_ok;

subtest 'Ship order' => sub {
  $t->get_ok('Report frontend', 'oe.pl', action => 'search', type => 'ship_order')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open first order', 'ordnumber-l')
    ->set_params_ok('Add quantity and serial number', ship_1 => 1, serialnumber_1 => $t->test_stamp)
    ->press_button_ok('Update shipment', 'update')
    ->press_button_ok('Save shipment',   'done')
    ->elements_exist('Link to order and name', 'a.ordnumber-l', 'a.name-l');
};
