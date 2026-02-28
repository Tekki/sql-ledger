# Never run this test on a production system!
use v5.40;

use utf8;
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

subtest 'Add and edit helpref' => sub {
  for my $helpref ($t->config->{helpref}{new}->@*) {
    $t->get_ok('Start page', $helpref->{path}, $helpref->{params}->%*)
      ->follow_link_ok('Open help', 'help')
      ->press_button_ok('Edit', 'edit')
      ->set_params_ok('Add content', body => $helpref->{content})
      ->press_button_ok('Save', 'save')
      ->content_is('Rendered content', pre => $helpref->{expected});

    $t->get_ok('Start page', $helpref->{path}, $helpref->{params}->%*)
      ->texts_are('Symbol', 'a.help' => '◥')
      ->follow_link_ok('Open help', 'help')
      ->content_is('Rendered content', pre => $helpref->{expected})
      ->press_button_ok('Edit', 'edit')
      ->set_params_ok('Add content', body => '')
      ->press_button_ok('Save', 'save')
      ->content_is('Rendered content', pre => "\n\n");

    $t->get_ok('Start page', $helpref->{path}, $helpref->{params}->%*)
      ->texts_are('Symbol', 'a.help' => '◹');
  }
};
