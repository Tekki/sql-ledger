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

subtest 'Incoming payments' => sub {
  $t->get_ok('Report frontend', 'rp.pl', action => 'report', reportcode => 'receipts')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Outgoint payments' => sub {
  $t->get_ok('Report frontend', 'rp.pl', action => 'report', reportcode => 'payments')
    ->press_button_ok('Generate report', 'continue');
};
