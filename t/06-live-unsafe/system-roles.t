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

$t = SL::TestClient->new(configfile => $configfile)->connect_ok('admin')->api_login_ok;

subtest 'Update employee' => sub {
  $t->get_ok('Role screen', 'am.pl', action => 'list_roles')
    ->follow_link_ok('Open role', 'role-l', 0)
    ->form_fields_exist('description')
    ->press_button_ok('Save role', 'save')
    ->elements_exist('Link to role', 'a.role-l')
};
