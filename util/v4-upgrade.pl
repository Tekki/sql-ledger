#! /usr/bin/env perl

use v5.40;
use feature 'class';
no warnings 'experimental::class';

$| = 1;

use FindBin;
use lib "$FindBin::Bin/..";
chdir "$FindBin::Bin/..";
use Print::Colored ':all';

say "Upgrade to SQL-Ledger Version 4\n";

my $www_user = prompt_input 'User name for web server [www-data]: ';
my $www_group = prompt_input 'Group name for web server [www-data]: ';
$www_user ||= 'www-data';
$www_group ||= 'www-data';

my $www_user_id = `id -u $www_user` * 1;
my $www_group_id = `id -g $www_group` * 1;

# sql-ledger.conf

print "\nConverting sql-ledger.conf ... ";
my $sl = SLConf->new;
say $sl->convert ? color_ok 'ok' : color_warn 'skipped';

# member file

print "\nConverting member file ... ";
my $members = Members->new;
say $members->convert($sl->config->{memberfile}) ? color_ok 'ok' : color_warn 'skipped';

# users

say "\nConverting user config files";
my $user = UserConf->new;

$user->list($sl->config->{userpath})->each(
  sub ($file, $i) {
    printf '  %s ... ', $file->basename('.conf');
    say $user->convert($file) ? color_ok 'ok' : color_warn 'skipped';
  }
);

# classes

class Members {
  use Carp;
  use Mojo::File 'path';
  use Storable;
  use YAML::PP;

  method convert ($memberfile) {
    croak "$memberfile not found" unless -f $memberfile;
    return !!0 if -f "$memberfile.yml" && -f "$memberfile.bin";

    my (%member, $user);
    for my $line (split "\n", path($memberfile)->slurp('UTF-8')) {
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;

      next if $line =~ /^(#|;|\s)/;
      last if $line =~ /^\./;

      if ($line =~ /\[(.+)\]/) {
        $user = {};
        $member{$1} = $user;
      } elsif ($line =~ /(.+?)=(.+)/) {
        $user->{$1} = $2;
      }
    }

    YAML::PP->new->dump_file("$memberfile.yml", \%member);
    store \%member, "$memberfile.bin";

    return !!1;
  }
}

class SLConf {
  use Carp;
  use Tie::IxHash;
  use YAML::PP::Common ':PRESERVE';
  use YAML::PP;

  our (
    $userspath,     $spool, $memberfile, $templates, $sendmail, $images,  $language, $charset,
    $latex,         $gzip,  $gpg,        $dvipdf,    $pdftk,    $xelatex, @accessfolders,
    $helpful_login, $admin_totp_activated
  );

  field $config :reader;
  field $config_old = 'sql-ledger.conf';
  field $config_new = 'config/sql-ledger.yml';

  method convert () {
    my $yml = YAML::PP->new(preserve => PRESERVE_ORDER);

    if (-f $config_new) {
      $config = $yml->load_file($config_new);
      return !!0;
    }
    croak "$config_old not found" unless -f $config_old;

    require "./$config_old";

    tie my %conf, 'Tie::IxHash';

    $conf{userspath}            = $userspath;
    $conf{spool}                = $spool;
    $conf{memberfile}           = $memberfile;
    $conf{templates}            = $templates;
    $conf{sendmail}             = $sendmail;
    $conf{images}               = $images;
    $conf{language}             = $language;
    $conf{charset}              = $charset;
    $conf{latex}                = !!$latex;
    $conf{gzip}                 = $gzip;
    $conf{gpg}                  = $gpg;
    $conf{dvipdf}               = !!$dvipdf;
    $conf{pdftk}                = !!$pdftk;
    $conf{xelatex}              = !!$xelatex;
    $conf{accessfolders}        = \@accessfolders;
    $conf{helpful_login}        = !!$helpful_login;
    $conf{admin_totp_activated} = !!$admin_totp_activated;

    $config = \%conf;
    $yml->dump_file($config_new, \%conf);

    return !!1;
  }
}

class UserConf {
  use Mojo::File 'path';
  use Storable;

  our %myconfig;

  method convert ($file) {
    my $converted = $file->sibling($file->basename('.conf').'.bin');
    return !!0 if -f $converted;

    %myconfig = ();
    require "./$file";

    store \%myconfig, $converted;
    chown $www_user_id, $www_group_id, $converted;

    return !!1;
  }

  method list ($folder) {
    return path('users')->list->grep(qr/.+@.+\.conf/);
  }
}
