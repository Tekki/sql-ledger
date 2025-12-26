use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'pos.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'add',           'assign_number', 'display_row',       'edit',
    'form_footer',   'form_header',   'lookup_partsgroup', 'main_groups',
    'open_drawer',   'openinvoices',  'poledisplay',       'post',
    'preview',       'print',         'print_and_post',    'print_form',
    'print_options', 'receipts',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
