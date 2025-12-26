use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::VR';
  use_ok $package;
}

isa_ok $package, 'SL::VR';

can_ok $package,
  (
  'create_links',            'delete_batch',
  'delete_payment_reversal', 'delete_transaction',
  'edit_batch',              'list_batches',
  'list_vouchers',           'payment_reversal',
  'post_batch',              'post_payment_reversal',
  'post_transaction',        'save_batch',
  );
