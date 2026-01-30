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

subtest 'Quotations' => sub {
  $t->get_ok('Report frontend', 'oe.pl', action => 'search', type => 'sales_quotation')
    ->set_params_ok('Report parameters', closed => 1) # debug
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to quotation, name', 'a.quonumber-l', 'a.name-l')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};

subtest 'RFQs' => sub {
  $t->get_ok('Report frontend', 'oe.pl', action => 'search', type => 'request_quotation')
    ->set_params_ok('Report parameters', closed => 1) # debug
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to quotation, name', 'a.quonumber-l', 'a.name-l')
    ->download_ok('Spreadsheet', 'xlsx', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};
