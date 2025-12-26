use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'vr.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'add_batch',                  'add_general_ledger_batch',
    'add_payable_batch',          'add_payment_batch',
    'add_payment_reversal_batch', 'add_payments_batch',
    'add_voucher',                'continue',
    'delete',                     'delete_batch',
    'deselect_all',               'edit',
    'edit_batch',                 'edit_payment_reversal',
    'general_ledger_batch',       'list_batches',
    'list_vouchers',              'payable_batch',
    'payment_batch',              'payment_reversal_batch',
    'payments_batch',             'post',
    'post_batch',                 'post_batches',
    'save_batch',                 'search',
    'select_all',                 'subtotal',
    'yes',                        'yes_delete_batch',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
