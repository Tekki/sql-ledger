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

subtest 'Sales orders' => sub {
  $t->get_ok('Report frontend', 'oe.pl', action => 'search', type => 'sales_order')
    ->set_params_ok('Report parameters', closed => 1) # debug
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to order, name', 'a.ordnumber-l', 'a.name-l')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};

subtest 'Requirements' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'so_requirements')
    ->set_action_ok('continue')
    ->post_ok('Generate report');
};

subtest 'Purchase orders' => sub {
  $t->get_ok('Report frontend', 'oe.pl', action => 'search', type => 'purchase_order')
    ->set_params_ok('Report parameters', closed => 1) # debug
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to order, name', 'a.ordnumber-l', 'a.name-l')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};
