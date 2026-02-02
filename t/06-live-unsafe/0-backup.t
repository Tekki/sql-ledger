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

subtest 'Internal backup' => sub {
  $t->get_download_ok('Internal backup', 'gz', 'am.pl', action => 'backup', media => 'file')
    ->download_is('Internal backup', 'gz');
};

subtest 'Pg Dump' => sub {
  $t->get_download_ok('Pg Dump', 'gz', 'am.pl', action => 'pg_dump')
    ->download_is('Pg Dump', 'gz');
};
