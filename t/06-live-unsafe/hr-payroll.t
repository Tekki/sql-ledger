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

$t = SL::TestClient->new(configfile => $configfile)->connect_ok()->api_login_ok;

subtest 'Update payroll' => sub {
  $t->get_ok(
    'Report frontend', 'hr.pl',
    action => 'search',
    db     => 'payroll'
    )
    ->set_params_ok(
      'Time range',
      transdatefrom => $t->date_jan1,
      transdateto   => $t->date_dec31
    )
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open payroll', 'payroll-l')
    ->press_button_ok('Update payroll', 'update')
    ->press_button_ok('Post payroll', 'post')
    ->press_button_ok('Confirm changes', 'continue')
    ->elements_exist('Links to payroll, invoice, GL', 'a.payroll-l', 'a.invoice-l', 'a.gl-l');
};

$t->remove_locks_ok;
