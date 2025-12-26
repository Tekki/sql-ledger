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
  plan tests => 4;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Update employee' => sub {
  $t->get_ok('Report frontend', 'hr.pl', action => 'search', db => 'employee')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open employee', 'name-l', 0)
    ->store_ok('employeenumber')
    ->press_button_ok('Update', 'update')
    ->press_button_ok('Save employee', 'save')
    ->elements_exist('Links to name', 'a.name-l')
};

subtest 'Add new employees' => sub {
  for my $em ($t->config->{employee}{new}->@*) {
    my %values   = $em->{header}->%*;
    my %expected = $em->{expected}->%*;

    if ($values{employeelogin} && $values{employeepassword}) {
      $values{employeelogin} .= int rand 1000;

      $expected{employeelogin}    = $values{employeelogin};
      $expected{employeepassword} = '';
    }
    
    $t->get_ok('Employee screen', 'hr.pl', action => 'add', db => 'employee')
      ->set_params_ok('Employee data', notes => $t->test_stamp, %values)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('employeenumber')
      ->press_button_ok('Save employee', 'save')
      ->get_ok('Report frontend', 'hr.pl', action => 'search', db => 'employee')
      ->set_params_ok('Search parameters', employeenumber => \'employeenumber')
      ->press_button_ok('Generate report', 'continue')
      ->follow_link_ok('Open employee', 'name-l', 0)
      ->params_are(
      'Content of employee',
      notes          => \'test_stamp',
      employeenumber => \'employeenumber',
      %expected,
      );
  }
};
