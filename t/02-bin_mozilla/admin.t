use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 1;

my $script = 'admin.pl';
our $form = SL::Form->new;
our $memberfile='users/members';
$form->{path} = 't/dummy';

eval {
  local *STDOUT;
  my $nil;
  open STDOUT, '>>', \$nil;

  require "bin/mozilla/$script";
  1;
};

subtest 'Subroutines' => sub {
  my @subs = (
    'Mock',            'Pg',              'add_dataset',    'adminlogin',
    'change_host',     'change_password', 'check_password', 'continue',
    'create_config',   'create_dataset',  'dbcreate',       'dbdriver_defaults',
    'dbselect_source', 'delete',          'do_change_host', 'do_change_password',
    'do_delete',       'do_lock_system',  'edit',           'form_footer',
    'form_header',     'list_datasets',   'lock_dataset',   'lock_system',
    'login',           'logout',          'unlock_dataset', 'unlock_system',
    'yes',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
