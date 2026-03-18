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

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Update project' => sub {
  $t->get_ok('Report frontend', 'pe.pl', action => 'search', type => 'project')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open project', 'number-l')
    ->store_ok('projectnumber')
    ->form_fields_exist('description', 'customer', 'startdate', 'enddate')
    ->press_button_ok('Update', 'update')
    ->press_button_ok('Save project', 'save')
    ->elements_exist('Links to orders', 'a.number-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used project', 'a.number-l' => \'projectnumber');
};
