use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::GL';
  use_ok $package;
}

isa_ok $package, 'SL::GL';

can_ok $package, ('delete_transaction', 'post_transaction', 'transaction', 'transactions',);
