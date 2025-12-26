use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'sm.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs
    = ('continue', 'do_repost_invoices', 'fld_config', 'fld_edit', 'fld_save', 'repost_invoices',);

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
