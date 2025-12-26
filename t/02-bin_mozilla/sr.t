use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'sr.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'add_column',  'delete_column', 'delete_report', 'do_save_report',
    'edit_column', 'save_column',   'save_report',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
