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
  plan tests => 7;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'All vouchers' => sub {
  $t->get_ok('Report frontend', 'vr.pl', action => 'search')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Payable' => sub {
  $t->get_ok('Report frontend', 'vr.pl', action => 'search', batch => 'ap')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Payment' => sub {
  $t->get_ok('Report frontend', 'vr.pl', action => 'search', batch => 'payment')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Payment reversal' => sub {
  $t->get_ok('Report frontend', 'vr.pl', action => 'search', batch => 'payment_reversal')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'General ledger' => sub {
  $t->get_ok('Report frontend', 'vr.pl', action => 'search', batch => 'gl')
    ->press_button_ok('Generate report', 'continue');
};
