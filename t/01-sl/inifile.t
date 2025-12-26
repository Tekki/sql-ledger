use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::Inifile';
  use_ok $package;
}

isa_ok $package, 'SL::Inifile';

can_ok $package, ('add_file', 'new',);
