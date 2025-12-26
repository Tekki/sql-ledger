use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::RD';
  use_ok $package;
}

isa_ok $package, 'SL::RD';

can_ok $package,
  (
  'all_documents',   'attach_document', 'delete_document', 'delete_documents',
  'detach_document', 'get_document',    'prepare_search',  'save_document',
  );
