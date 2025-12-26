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

subtest 'Employees' => sub {
  $t->get_ok('Report frontend', 'hr.pl', action => 'search', db => 'employee')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Payroll' => sub {
  $t->get_ok('Report frontend', 'hr.pl', action => 'search', db => 'payroll')
    ->press_button_ok('Generate report', 'continue');
};
