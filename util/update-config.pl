#! /usr/bin/env perl

use v5.40;

$| = 1;

use File::stat;
use FindBin;
chdir "$FindBin::Bin/..";
use Print::Colored ':all';
use Storable;
use YAML::PP;

my $slconfig;

say 'Updating config files';

# sql-ledger.yml

my $sl_yml = 'config/sql-ledger.yml';
my $sl_bin = 'config/sql-ledger.bin';

print "\nSQL-Ledger config ... ";

unless (-f $sl_yml) {
  say_error 'error';
  die "$sl_yml not found."
}

if (-f $sl_bin && -M $sl_bin <= -M $sl_yml) {
  $slconfig = retrieve $sl_bin;
  say_warn 'skipped';
} else {
  $slconfig = YAML::PP::LoadFile $sl_yml;
  store $slconfig, $sl_bin;
  say_ok 'ok';
}

# members

my $members_yml = "$slconfig->{memberfile}.yml";
my $members_bin = "$slconfig->{memberfile}.bin";
my $users_stat  = stat($slconfig->{userspath});

print "\nMembers ... ";

unless (-f $members_yml) {
  say_warn 'warning';
  say "$members_yml not found, creating empty file.";

  open my $out, '>', $members_yml or die "$members_yml: $!";
  say $out <<~'EOT';
    ---
    root_login:
      password:
    EOT
  close $out;
}

if (-f $members_bin && -M $members_bin <= -M $members_yml) {
  say_warn 'skipped';
} else {
  my $members = YAML::PP::LoadFile $members_yml;
  store $members, $members_bin;
  chown $users_stat->uid, $users_stat->gid, $members_bin, $members_yml;

  say_ok 'ok';
}
