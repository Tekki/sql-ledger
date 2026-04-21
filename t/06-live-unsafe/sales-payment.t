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

subtest 'Single payment' => sub {
  $t->get_ok(
    'Payment frontend', 'cp.pl',
    action => 'payment',
    type   => 'receipt',
    )
    ->press_button_ok('List open invoices', 'continue');
};

subtest 'Multiple payments' => sub {
  $t->get_ok(
    'Payment frontend', 'cp.pl',
    action => 'payments',
    type   => 'receipt',
    )
    ->press_button_ok('Update list', 'update');
};
