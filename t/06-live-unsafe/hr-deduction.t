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

subtest 'Update deduction' => sub {
  $t->get_ok(
    'Report frontend', 'hr.pl',
    action => 'search',
    db     => 'deduction'
    )
    ->follow_link_ok('Open deduction', 'deduction-l')
    ->press_button_ok('Update deduction', 'update')
    ->press_button_ok('Save deduction', 'save')
    ->elements_exist('Link to deduction', 'a.deduction-l');
};
