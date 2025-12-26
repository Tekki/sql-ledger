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
  plan tests => 6;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Menu frame' => sub {
  $t->post_ok('Menu', 'menu.pl', action => 'acc_menu', js => 1)
    ->elements_exist('Frame', 'body.menu', 'img', 'div.menuOut', 'div.submenu');
};

ok my $entries = $t->dom->find('a'), 'Get menu entries';
ok $entries->size > 200, 'Number of entries';

subtest 'Call entries' => sub {
  $entries->each(
    sub ($el, $i) {
      my ($href, $target, $label) = ($el->attr('href'), $el->attr('target') || '', $el->text);
      return if $target ne 'main_window';
      return if $href =~ /action=(backup|pg_dump|list_templates)/;
      return if $href =~ /level=Batch--Queue/;

      $t->get_ok($label, $href);

      # ->element_exists('form[name=main]', 'Main form');
    }
  );
};
