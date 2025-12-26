use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::BP';
  use_ok $package;
}

isa_ok $package, 'SL::BP';

can_ok $package,
  ('delete_spool', 'get_spoolfiles', 'get_vc', 'print_spool', 'set_printed', 'spoolfile',);
