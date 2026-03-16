#! /usr/bin/env perl

use v5.40;

use File::stat;
use FindBin;
use List::Util 'shuffle';
use Print::Colored ':all';
use Storable;
use YAML::PP;

die 'Not called from console.' unless -t STDIN && -t STDOUT;

chdir "$FindBin::Bin/..";

say 'Generate new password for dataset admin or root login';

my $sl_yml   = 'config/sql-ledger.yml';
my $slconfig = retrieve 'config/sql-ledger.bin';

my $members_yml = "$slconfig->{memberfile}.yml";
my $members_bin = "$slconfig->{memberfile}.bin";
my $members     = YAML::PP::LoadFile($members_yml);
my $users_stat  = stat($slconfig->{userspath});

my $dataset = prompt_input 'Dataset [root login]: ';

my ($login, $salt);
if ($dataset) {
  $login = "admin\@$dataset";
  $salt  = 'admin';
} else {
  $login = 'root login';
  $salt  = 'root_login';
}

my $member = $members->{$login} or die color_error "$login: Not found.";

my $password  = join '', (shuffle '0' .. '9', 'a' .. 'z', 'A' .. 'Z')[0 .. 9];

$member->{password} = crypt $password, $salt;

YAML::PP::DumpFile($members_yml, $members);
Storable::store($members, $members_bin);
chown $users_stat->uid, $users_stat->gid, $members_bin, $members_yml;

say "New password for $login: $password";
