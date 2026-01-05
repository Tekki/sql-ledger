use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Mojo::File 'path';
use Storable;

use Test::More tests => 8;

chdir "$FindBin::Bin/../..";

my @config_params = (
  'countrycode', 'dateformat',   'dbconnect', 'dbpasswd', 'dbuser', 'name',
  'email',       'numberformat', 'password',  'templates',
);

my $sl_bin = 'config/sql-ledger.bin';
ok my $slconfig = retrieve $sl_bin, 'Read config';

my $members_bin = "$slconfig->{memberfile}.bin";
my $members_yml = "$slconfig->{memberfile}.yml";

for my $file ($members_yml, $members_bin) {
  ok -f $file, "$file exists" or BAIL_OUT "$file: File not found."
}

ok -M $members_bin <= -M $members_yml, "$members_bin is up to date";

ok my $members = retrieve $members_bin, 'Read config';

diag q|Warning: Root login doesn't exist| unless $members->{'root login'};

ok my $userfiles = path('users')->list->grep(qr/.+@.+\.bin/), 'List user files';

subtest 'No orphaned logins' => sub {
  plan skip_all => 'No user logins.' unless @$userfiles;

  for my $userfile (@$userfiles) {
    my $user = $userfile->basename('.bin');
    ok $members->{$user}, "$user defined in $members_bin";
  }
};

subtest 'User config' => sub {
  plan skip_all => 'No user logins.' unless @$userfiles;

  for my $userfile (@$userfiles) {
    my $user     = $userfile->basename('.bin');
    my $myconfig = retrieve $userfile, "Config for $user";

    for (@config_params) {
      is $myconfig->{$_}, $members->{$user}{$_}, "$user: $_";
    }
    ok $myconfig->{sessionkey}, "$user: sessionkey";
  }
};
