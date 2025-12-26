use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::ADR';
  use_ok $package;
}

isa_ok $package, 'SL::ADR';

can_ok $package,
  (
  'COUNTRY_CODES',   'LOCAL_ADDRESS', 'check_country', 'country_name',
  'default_country', 'local_address',
  );
