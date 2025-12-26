use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::CP';
  use_ok $package;
}

isa_ok $package, 'SL::CP';

can_ok $package,
  (
  'create_selects',   'format_ten',      'get_openinvoices', 'get_openvc',
  'init',             'invoice_ids',     'new',              'num2text',
  'payment_register', 'paymentaccounts', 'post_payment',     'reissue_payment',
  'retrieve',         'sortsource',      'void_payments',
  );
