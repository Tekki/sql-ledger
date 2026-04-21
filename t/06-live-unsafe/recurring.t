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

$t = SL::TestClient->new(configfile => $configfile)->connect_ok()->api_login_ok;

subtest 'Update recurring transaction' => sub {
  $t->get_ok('Report frontend', 'am.pl', action => 'recurring_transactions',)
    ->follow_link_ok('Open schedule', 'schedule-l')
    ->press_button_ok('Save schedule',   'save_schedule')
    ->elements_exist('Link to schedule, name and transaction', 'a.schedule-l', 'a.name-l', 'a.transaction-l');
};
