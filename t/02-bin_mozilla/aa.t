use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'aa.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'add',          'create_links',
    'delete',       'delete_transactions',
    'deselect_all', 'display_form',
    'edit',         'form_footer',
    'form_header',  'post',
    'search',       'select_all',
    'subtotal',     'transactions',
    'update',       'yes',
    'yes__delete_transactions',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
