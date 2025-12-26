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

subtest 'Logout' => sub {
  $t->post_ok('Logout', 'login.pl', action => 'logout')
    ->elements_exist('Links to invoice, name', 'form', 'input[type=submit]')
    ->form_fields_exist('login', 'password')
    ->form_hidden_exist('js', 'path', 'small_device');
};
