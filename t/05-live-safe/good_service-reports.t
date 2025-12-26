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
  plan tests => 13;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'All items' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'all')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to partnumber', 'a.partnumber-l');
};

subtest 'Parts' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'part')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to partnumber', 'a.partnumber-l');
};

subtest 'Labors' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'labor')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to partnumber', 'a.partnumber-l');
};

subtest 'Services' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'service')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to partnumber', 'a.partnumber-l');
};

subtest 'Partsgroups' => sub {
  $t->get_ok('Report frontend', 'pe.pl', action => 'search', type => 'partsgroup')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to partsgroup', 'a.partsgroup-l');
};

subtest 'Pricegroups' => sub {
  $t->get_ok('Report frontend', 'pe.pl', action => 'search', type => 'pricegroup')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to pricegroup', 'a.pricegroup-l');
};

subtest 'Kits' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'kit')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Assemblies' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'assembly')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Components' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'search', searchitems => 'component')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Supply and demand' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'supply_demand')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Requirements' => sub {
  $t->get_ok('Report frontend', 'ic.pl', action => 'requirements')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to partnumber', 'a.partnumber-l');
};
