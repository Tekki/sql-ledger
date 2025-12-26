#!/usr/bin/perl
use v5.40;
use open ':std', ':encoding(UTF-8)';

use DBI;
use FindBin;
use Mojo::File qw|path|;
use Mojo::UserAgent;
use Storable ();

chdir "$FindBin::Bin/..";

my $memberfile = 'users/members';

my $ezv = 'https://www.backend-rates.bazg.admin.ch/api/xmldaily';

my %members = Storable::retrieve("$memberfile.bin")->%*;

my $ua  = Mojo::UserAgent->new;
my $res = $ua->get($ezv)->result;
if ($res->is_error) {
  die $res->message;
}

my $update = $res->dom;
my %rates;

$update->find('devise')->each(
  sub ($el, $i) {
    my ($factor, $curr) = $el->at('waehrung')->text =~ /(\d+) (\w{3})/;
    my $rate = $el->at('kurs')->text * 1;

    $rates{$curr} = $rate / $factor;
  }
);

for my $dataset (values %members) {
  next unless $dataset->{dbconnect};

  my $dbh = DBI->connect(
    $dataset->{dbconnect}, $dataset->{dbuser},
    unpack('u', $dataset->{dbpasswd} // ''), {AutoCommit => 1}
  );
  unless ($dbh) {
    warn $DBI::errstr;
    next;
  }

  my $query = q|SELECT curr FROM curr ORDER BY rn|;
  my $sth   = $dbh->prepare($query);
  $sth->execute || die $dbh->errstr;

  my @currencies;
  while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
    push @currencies, $ref->{curr};
  }

  my %ds_rates = %rates;
  if ($currencies[0] ne 'CHF') {
    my $factor2 = delete $ds_rates{$currencies[0]} or next;
    $ds_rates{CHF} = 1;

    for (values %ds_rates) {
      $_ = sprintf '%.5f', $_ / $factor2;
    }

  }

  $query = q|DELETE FROM exchangerate WHERE transdate = CURRENT_DATE|;
  $dbh->do($query) || die $dbh->errstr;

  $query = q|INSERT INTO exchangerate (curr, transdate, exchangerate) VALUES (?, CURRENT_DATE, ?)|;
  $sth   = $dbh->prepare($query);

  for my $curr (@currencies) {
    if ($ds_rates{$curr}) {
      $sth->execute($curr, $ds_rates{$curr});
    }
  }

  $dbh->disconnect;
}
