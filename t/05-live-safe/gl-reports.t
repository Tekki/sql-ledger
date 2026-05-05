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
  plan tests => 11;
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

subtest 'Action from GL entries: GL transaction' => sub {
  $t->get_ok('Report frontend', 'gl.pl', action => 'search')
    ->set_params_ok('Report parameters', datefrom => $t->date_jan1, dateto => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->press_button_ok('Screen to add GL transaction', 'gl_transaction');
};

subtest 'Action from GL entries: AR transaction' => sub {
  $t->get_ok('Report frontend', 'gl.pl', action => 'search')
    ->set_params_ok('Report parameters', datefrom => $t->date_jan1, dateto => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->press_button_ok('Screen to add AR transaction', 'ar_transaction');
};

subtest 'Action from GL entries: sales invoice' => sub {
  $t->get_ok('Report frontend', 'gl.pl', action => 'search')
    ->set_params_ok('Report parameters', datefrom => $t->date_jan1, dateto => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->press_button_ok('Screen to add sales invoice', 'sales_invoice_');
};

subtest 'Action from GL entries: credit invoice' => sub {
  $t->get_ok('Report frontend', 'gl.pl', action => 'search')
    ->set_params_ok('Report parameters', datefrom => $t->date_jan1, dateto => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->press_button_ok('Screen to add credit invoice', 'credit_invoice_');
};

subtest 'Action from GL entries: AP transaction' => sub {
  $t->get_ok('Report frontend', 'gl.pl', action => 'search')
    ->set_params_ok('Report parameters', datefrom => $t->date_jan1, dateto => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->press_button_ok('Screen to add AP transaction', 'ap_transaction');
};

subtest 'Action from GL entries: vendor invoice' => sub {
  $t->get_ok('Report frontend', 'gl.pl', action => 'search')
    ->set_params_ok('Report parameters', datefrom => $t->date_jan1, dateto => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->press_button_ok('Screen to add vendor invoice', 'vendor_invoice_');
};

subtest 'Action from GL entries: debit invoice' => sub {
  $t->get_ok('Report frontend', 'gl.pl', action => 'search')
    ->set_params_ok('Report parameters', datefrom => $t->date_jan1, dateto => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue')
    ->press_button_ok('Screen to add debit invoice', 'debit_invoice_');
};

subtest 'Reconciliation' => sub {
  $t->get_ok('Report frontend', 'rc.pl', action => 'reconciliation')
    ->set_params_ok('Report parameters', fromdate => $t->date_jan1, todate => $t->date_dec31)
    ->press_button_ok('Generate report', 'continue');
};
