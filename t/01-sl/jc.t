use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::JC';
  use_ok $package;
}

isa_ok $package, 'SL::JC';

can_ok $package,
  (
  'company_defaults', 'delete',        'jcitems', 'jcitems_links',
  'retrieve_card',    'retrieve_item', 'save',
  );
