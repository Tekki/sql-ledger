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
  plan tests => 9;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Projects' => sub {
  $t->get_ok('Report frontend', 'pe.pl', action => 'search', type => 'project')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to project, name', 'a.number-l', 'a.name-l');
};

subtest 'Project transactions' => sub {
  $t->get_ok('Report frontend', 'rp.pl', action => 'report', reportcode => 'projects')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Project time cards' => sub {
  $t->get_ok('Report frontend', 'jc.pl', action => 'search', type => 'timecard', project => 'project')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to name, time card', 'a.id-l');
};

subtest 'Jobs' => sub {
  $t->get_ok('Report frontend', 'pe.pl', action => 'search', type => 'job')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to job, name, partnumber', 'a.number-l', 'a.name-l', 'a.partnumber-l');
};

subtest 'Job time cards' => sub {
  $t->get_ok('Report frontend', 'jc.pl', action => 'search', type => 'timecard', project => 'job')
    ->press_button_ok('Generate report', 'continue')
    ->elements_exist('Links to time card', 'a.id-l');
};

subtest 'Job stores cards' => sub {
  $t->get_ok('Report frontend', 'jc.pl', action => 'search', type => 'storescard', project => 'job')
    ->press_button_ok('Generate report', 'continue');
};

subtest 'Job times and stores cards' => sub {
  $t->get_ok('Report frontend', 'jc.pl', action => 'search', project => 'job')
    ->press_button_ok('Generate report', 'continue');
};
