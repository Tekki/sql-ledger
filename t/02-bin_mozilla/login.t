use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'login.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'continue', 'email_tan',     'login',     'login_screen',
    'logout',   'selectdataset', 'tan_login', 'totp_login',
    'totp_screen',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
