use v5.40;

use utf8;
use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 6;

chdir "$FindBin::Bin/../..";

my $package;

my $language = '';  # default = English

my %numbers = (
  -1      => 'One',
  0       => 'Zero',
  1       => 'One',
  2       => 'Two',
  3       => 'Three',
  4       => 'Four',
  5       => 'Five',
  6       => 'Six',
  7       => 'Seven',
  8       => 'Eight',
  9       => 'Nine',
  10      => 'Ten',
  11      => 'Eleven',
  12      => 'Twelve',
  13      => 'Thirteen',
  14      => 'Fourteen',
  15      => 'Fifteen',
  16      => 'Sixteen',
  17      => 'Seventeen',
  18      => 'Eighteen',
  19      => 'Nineteen',
  20      => 'Twenty',
  21      => 'Twenty One',
  22      => 'Twenty Two',
  23      => 'Twenty Three',
  24      => 'Twenty Four',
  25      => 'Twenty Five',
  26      => 'Twenty Six',
  27      => 'Twenty Seven',
  28      => 'Twenty Eight',
  29      => 'Twenty Nine',
  30      => 'Thirty',
  40      => 'Forty',
  50      => 'Fifty',
  60      => 'Sixty',
  70      => 'Seventy',
  80      => 'Eighty',
  90      => 'Ninety',
  100     => 'One Hundred',
  110     => 'One Hundred Ten',
  120     => 'One Hundred Twenty',
  130     => 'One Hundred Thirty',
  140     => 'One Hundred Forty',
  150     => 'One Hundred Fifty',
  160     => 'One Hundred Sixty',
  170     => 'One Hundred Seventy',
  180     => 'One Hundred Eighty',
  190     => 'One Hundred Ninety',
  200     => 'Two Hundred',
  300     => 'Three Hundred',
  400     => 'Four Hundred',
  500     => 'Five Hundred',
  600     => 'Six Hundred',
  700     => 'Seven Hundred',
  800     => 'Eight Hundred',
  900     => 'Nine Hundred',
  1000    => 'One Thousand',
  1100    => 'One Thousand One Hundred',
  1200    => 'One Thousand Two Hundred',
  1300    => 'One Thousand Three Hundred',
  1400    => 'One Thousand Four Hundred',
  1500    => 'One Thousand Five Hundred',
  1600    => 'One Thousand Six Hundred',
  1700    => 'One Thousand Seven Hundred',
  1800    => 'One Thousand Eight Hundred',
  1900    => 'One Thousand Nine Hundred',
  2000    => 'Two Thousand',
  3000    => 'Three Thousand',
  4000    => 'Four Thousand',
  5000    => 'Five Thousand',
  6000    => 'Six Thousand',
  7000    => 'Seven Thousand',
  8000    => 'Eight Thousand',
  9000    => 'Nine Thousand',
  10000   => 'Ten Thousand',
  11000   => 'Eleven Thousand',
  12000   => 'Twelve Thousand',
  13000   => 'Thirteen Thousand',
  14000   => 'Fourteen Thousand',
  15000   => 'Fifteen Thousand',
  16000   => 'Sixteen Thousand',
  17000   => 'Seventeen Thousand',
  18000   => 'Eighteen Thousand',
  19000   => 'Nineteen Thousand',
  20000   => 'Twenty Thousand',
  21000   => 'Twenty One Thousand',
  22000   => 'Twenty Two Thousand',
  23000   => 'Twenty Three Thousand',
  24000   => 'Twenty Four Thousand',
  25000   => 'Twenty Five Thousand',
  26000   => 'Twenty Six Thousand',
  27000   => 'Twenty Seven Thousand',
  28000   => 'Twenty Eight Thousand',
  29000   => 'Twenty Nine Thousand',
  30000   => 'Thirty Thousand',
  100000  => 'One Hundred Thousand',
  200000  => 'Two Hundred Thousand',
  1000000 => 'One Million',
  2000000 => 'Two Million',
);

BEGIN {
  $package = 'SL::CP';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

isa_ok $package, 'SL::CP';
my $cp = new_ok $package, [$language];
can_ok $cp, 'init', 'num2text', 'format_ten';

ok $cp->init, 'Initialize';

subtest 'English numbers' => sub {
  for my $num (sort {$a <=> $b} keys %numbers) {
    is $cp->num2text($num), $numbers{$num}, "Translate $num";
  }
};
