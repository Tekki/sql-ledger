use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::PM';
  use_ok $package;
}

isa_ok $package, 'SL::PM';

can_ok $package, ('price_matrix', 'price_matrix_query',);
