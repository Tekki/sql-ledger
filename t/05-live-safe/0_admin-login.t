# Never run this test on a production system!
use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More;
use SL::TestClient;

chdir "$FindBin::Bin/../..";

my $configfile = "$FindBin::Bin/../testdata/testconfig.yml";
my ($t, $adminpwd);

unless ($ENV{SL_LIVETEST}) {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile);

if ($adminpwd = $t->config->{server}{adminpassword}) {
  plan tests => 2;
} else {
  plan skip_all => 'Admin password not available.';
}

$t->connect_ok(1);

subtest 'Admin screen' => sub {
  $t->post_ok('Login as admin', 'admin.pl', action   => 'login', password => $adminpwd)
    ->elements_exist('Links to datasets', 'a.dataset-l')
    ->follow_link_ok('Open first dataset', 'dataset-l', 1)
    ->form_exists
    ->form_fields_exist('lock');
};
