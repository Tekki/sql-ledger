#! /usr/bin/env perl

use v5.40;
use feature 'try';

$| = 1;

use FindBin;
use lib "$FindBin::Bin/..";
chdir "$FindBin::Bin/..";

use DBI;
use Mojo::File 'path';
use Print::Colored ':all';
use Storable;

use SL::Form;
use SL::User;

my $slconfig = retrieve 'config/sql-ledger.bin';
my $members  = retrieve "$slconfig->{memberfile}.bin";
my $form = SL::Form->new;

say "Upgrading datasets to version $form->{dbversion}\n";

for my $login (sort grep /^admin@/, keys %$members) {
  my $myconfig = $members->{$login};
  printf '%-20s ... ', $myconfig->{dbname};
  my $lockfile = path "$slconfig->{userspath}/$myconfig->{dbname}.LCK";

  try {
    die 'Dataset locked.' if -f $lockfile;
    $lockfile->touch;

    for (qw|dbname dbhost dbport dbdriver dbconnect dbuser dateformat|) {
      $form->{$_} = $myconfig->{$_};
    }
    $form->{dbpasswd} = unpack 'u', $myconfig->{dbpasswd};

    SL::User->dbupdate($form);

    $lockfile->remove;
    say_ok 'ok';
  } catch ($e) {
    say_error 'error';
    say "  $e";
  }
}
