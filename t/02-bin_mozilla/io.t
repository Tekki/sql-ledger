use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'io.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'calc_markup',    'check_form', 'create_form',  'display_form',
    'display_row',    'e_mail',     'invoicetotal', 'item_selected',
    'new_item',       'print',      'print_form',   'print_options',
    'purchase_order', 'quotation',  'rfq',          'sales_order',
    'select_item',    'send_email', 'ship_to',      'shipto_selected',
    'validate_items',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
