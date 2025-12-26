use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'arapprn.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'payment_selected',  'print',
    'print_and_post',    'print_check',
    'print_credit_note', 'print_debit_note',
    'print_options',     'print_payslip',
    'print_receipt',     'print_remittance_voucher',
    'print_transaction', 'select_payment',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
