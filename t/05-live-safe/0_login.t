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

$t = SL::TestClient->new(configfile => $configfile)->connect_ok;
$t->get_ok('Index', 'index.html')->mj->content_like(qr/content="0; URL=login.pl"/, 'Redirection');

subtest 'Login page' => sub {
  $t->get_ok('Login page', 'login.pl')
    ->elements_exist('Login form', 'form', 'input[type=submit]')
    ->form_fields_exist('login', 'password')
    ->form_hidden_exist('js', 'path', 'small_device');
};

subtest 'User login' => sub {
  $t->user_login_ok
    ->elements_exist('Frames', '#menu_frames', 'frame[name=acc_menu]', 'frame[name=main_window]');
};

subtest 'API login' => sub {
  ok $t->api_login_ok, 'API Login';
  ok $t->headers('login.pl')->{'SL-Token'}, 'Token header';
};

subtest 'Version screen' => sub {
  $t->post_ok('Version screen', 'am.pl', action => 'company_logo')
    ->elements_exist('Version information', 'h1.login', 'table');
};
