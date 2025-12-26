use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'ca.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = ('ca_subtotal', 'chart_of_accounts', 'list', 'list_transactions', 'spreadsheet',);

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
