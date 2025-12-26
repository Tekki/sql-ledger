use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::API';
  use_ok $package;
}

isa_ok $package, 'SL::API';

can_ok $package, ('add_reference', 'find_invoice', 'list_accounts',);
