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

subtest 'Search' => sub {
  $t->get_ok('Report fontend', 'ct.pl', action => 'search', db => 'vendor')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to name, e-mail', 'a.name-l', 'a.email-l');
};

subtest 'History' => sub {
  $t->get_ok('Report fontend', 'ct.pl', action => 'history', db => 'vendor')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to invoice, name', 'a.name-l');
};
