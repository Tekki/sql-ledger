#!/usr/bin/perl
use Mojo::Base -strict, -signatures;
use open ':std', ':encoding(utf8)';

use DBI;
use FindBin;
use Mojo::File qw|path|;
use Mojo::UserAgent;

chdir "$FindBin::Bin/..";

my $memberfile = 'users/members';

my $ezv = 'https://www.backend-rates.ezv.admin.ch/api/xmldaily';

open(my $fh, '<:encoding(utf-8)', $memberfile) or die "$memberfile: $!";

my (%members, $member, $new, $var);
while (<$fh>) {
  if (/^\[(.*)\]/) {
    $member = $+;
    if ($member =~ /^admin\@/) {
      $member = substr($member, 6);
      $new    = 1;
    } else {
      $new = 0;
    }
  }
  if ($new) {
    if (/^(company|dbconnect|dbuser|dbpasswd|templates)=/) {
      $var = $1;
      (undef, $members{$member}{$var}) = split /=/, $_, 2;
      $members{$member}{$var} =~ s/(\r\n|\n)//;
    }
  }
}

close $fh;

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

  if ($currencies[0] ne 'CHF') {
    my $factor2 = delete $rates{$currencies[0]} or next;
    $rates{CHF} = 1;

    for (values %rates) {
      $_ = sprintf '%.5f', $_ / $factor2;
    }

  }

  $query = q|DELETE FROM exchangerate WHERE transdate = CURRENT_DATE|;
  $dbh->do($query) || die $dbh->errstr;

  $query = q|INSERT INTO exchangerate (curr, transdate, exchangerate) VALUES (?, CURRENT_DATE, ?)|;
  $sth   = $dbh->prepare($query);

  for my $curr (@currencies) {
    if ($rates{$curr}) {
      $sth->execute($curr, $rates{$curr});
    }
  }

  $dbh->disconnect;
}
