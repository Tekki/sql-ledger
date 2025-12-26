use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'cp.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'back',                    'check_form',
    'check_openvc',            'deselect_all',
    'edit',                    'invoices_due',
    'list_checks',             'list_invoices',
    'payment',                 'payment_footer',
    'payment_header',          'payment_register',
    'payments',                'payments_footer',
    'payments_header',         'post',
    'post_payment',            'post_payments',
    'prepare_payments_header', 'print',
    'print_form',              'print_payment',
    'print_payments',          'reissue_payments',
    'reissue_receipts',        'select_all',
    'update',                  'update_payment',
    'update_payments',         'void_checks',
    'void_receipts',           'yes__reissue_checks',
    'yes__reissue_receipts',   'yes__void_checks',
    'yes__void_payments',      'yes__void_receipts',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
