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

subtest 'Create snapshot' => sub {
  $t->get_ok('Snapshot report', 'am.pl', action => 'list_snapshots')
    ->press_button_ok('Add snapshot', 'add_snapshot')
    ->press_button_ok('Confirm', 'continue')
    ->elements_exist('Back to snapshot report', 'input[name=allbox]');
};
