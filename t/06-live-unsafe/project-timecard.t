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

subtest 'Update timecard' => sub {
  $t->get_ok('Report frontend', 'jc.pl', action => 'search', type => 'timecard', project => 'project')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open time card', 'id-l', 0)
    ->store_ok('id')
    ->press_button_ok('Update', 'update')
    ->press_button_ok('Save timecard', 'save')
    ->press_button_ok('Confirm changes', 'continue')
    ->elements_exist('Links to time card', 'a.id-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used time card', 'a.number-l' => \'id');
};
