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

subtest 'GL entries' => sub {
  $t->get_ok('Report frontend', 'gl.pl', action => 'search')
    ->set_params_ok('Report parameters', datefrom => $t->date_jan1, dateto => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to reference', 'a.reference-l');
};

subtest 'Reconciliation' => sub {
  $t->get_ok('Report frontend', 'rc.pl', action => 'reconciliation')
    ->set_params_ok('Report parameters', fromdate => $t->date_jan1, todate => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue');
};
