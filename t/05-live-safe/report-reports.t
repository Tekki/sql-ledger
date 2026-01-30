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

subtest 'Chart of accounts' => sub {
  $t->get_ok('Report frontend', 'ca.pl', action => 'chart_of_accounts')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Reconciliation' => sub {
  $t->get_ok('Report frontend', 'rc.pl', action => 'reconciliation', report => 1)
    ->set_params_ok('Report parameters', fromdate => $t->date_jan1, todate => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Trial balance' => sub {
  $t->get_ok('Report frontend', 'rp.pl', action => 'report', reportcode => 'trial_balance')
    ->set_params_ok('Report parameters', fromdate => $t->date_jan1, todate => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->press_button_ok('Generate details report', 'display_all')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};

subtest 'Income statement' => sub {
  $t->get_ok('Report frontend', 'rp.pl', action => 'report', reportcode => 'income_statement')
    ->set_params_ok('Report parameters', fromdate => $t->date_jan1, todate => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};

subtest 'Balance sheet' => sub {
  $t->get_ok('Report frontend', 'rp.pl', action => 'report', reportcode => 'balance_sheet')
    ->set_params_ok('Report parameters', todate => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};
