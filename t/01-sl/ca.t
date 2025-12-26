use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::CA';
  use_ok $package;
}

isa_ok $package, 'SL::CA';

can_ok $package, ('all_accounts', 'all_transactions',);
