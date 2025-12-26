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

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Documents' => sub {
  $t->get_ok('Report frontend', 'rd.pl', action => 'search_documents')
    ->press_button_ok('Generate report', 'continue')
    ->download_ok('Spreadsheet', 'spreadsheet')
    ->download_is('Spreadsheet', 'xlsx');
};
