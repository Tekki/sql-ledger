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
  plan tests => 8;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Transactions' => sub {
  $t->get_ok('Report frontend', 'ar.pl', action => 'search', nextsub => 'transactions')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to invoice, name', 'a.invnumber-l', 'a.ar-l', 'a.is-l', 'a.name-l')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};

subtest 'Outstanding' => sub {
  $t->get_ok(
    'Report frontend', 'ar.pl',
    action      => 'search',
    nextsub     => 'transactions',
    outstanding => 1
    )
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to invoice, name', 'a.invnumber-l', 'a.ar-l', 'a.is-l', 'a.name-l')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};

subtest 'Aging' => sub {
  $t->get_ok('Report frontend', 'rp.pl', action => 'report', reportcode => 'ar_aging')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to name', 'a.vc-l');
};

subtest 'Reminder' => sub {
  $t->get_ok('Report frontend', 'rp.pl', action => 'report', reportcode => 'reminder')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to invoice, name', 'a.vc-l', 'a.invnumber-l');
};

subtest 'Tax collected' => sub {
  $t->get_ok('Report frontend', 'rp.pl', action => 'report', reportcode => 'tax_collected')
    ->set_params_ok('Report parameters', fromdate => $t->date_jan1, todate => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to invoice, name', 'a.invnumber-l', 'a.name-l')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};

subtest 'Non taxable' => sub {
  $t->get_ok('Report frontend', 'rp.pl', action => 'report', reportcode => 'nontaxable_sales')
    ->set_params_ok('Report parameters', fromdate => $t->date_jan1, todate => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to invoice, name', 'a.invnumber-l', 'a.name-l')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};
