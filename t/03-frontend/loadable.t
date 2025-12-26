use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
chdir "$FindBin::Bin/../..";

use Test::More tests => 4;

$ENV{QUERY_STRING} = 'path=bin/mozilla';

subtest 'Standard scripts' => sub {
  for my $script (
    'am', 'ar',   'bp', 'ca', 'cp', 'ct', 'gl', 'hr', 'ic', 'im', 'ir', 'is',
    'jc', 'menu', 'oe', 'pe', 'ps', 'rc', 'rd', 'rp', 'ru', 'sm',
    )
  {
    ok my $output = `perl $script.pl`, "Call $script.pl";
    like $output, qr/href=login.pl/, 'Link to login';
  }
};

subtest 'User Login' => sub {
  my $script = 'login';
  ok my $output = `perl $script.pl`, "Call $script.pl";
  like $output, qr/form method=post name=main action=login.pl/, 'User login screen';
};

subtest 'Admin Login' => sub {
  my $script = 'admin';
  ok my $output = `perl $script.pl`, "Call $script.pl";
  like $output, qr/form method=post name=main action="admin.pl"/, 'Admin login screen';
};

subtest 'API' => sub {
  my $script = 'api';
  ok my $output = `perl $script.pl`, "Call $script.pl";
  like $output, qr/"message":"Access Denied!"/, 'API error message';
};
