use v5.40;

use utf8;
use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 6;

chdir "$FindBin::Bin/../..";

my $package;

my $language = 'tr';

my %numbers = (
  -1      => 'Bir',
  0       => 'Sıfır',
  1       => 'Bir',
  2       => 'İki',
  3       => 'Üç',
  4       => 'Dört',
  5       => 'Beş',
  6       => 'Altı',
  7       => 'Yedi',
  8       => 'Sekiz',
  9       => 'Dokuz',
  10      => 'On',
  11      => 'On Bir',
  12      => 'On İki',
  13      => 'On Üç',
  14      => 'On Dört',
  15      => 'On Beş',
  16      => 'On Altı',
  17      => 'On Yedi',
  18      => 'On Sekiz',
  19      => 'On Dokuz',
  20      => 'Yirmi',
  21      => 'Yirmi Bir',
  22      => 'Yirmi İki',
  23      => 'Yirmi Üç',
  24      => 'Yirmi Dört',
  25      => 'Yirmi Beş',
  26      => 'Yirmi Altı',
  27      => 'Yirmi Yedi',
  28      => 'Yirmi Sekiz',
  29      => 'Yirmi Dokuz',
  30      => 'Otuz',
  40      => 'Kırk',
  50      => 'Elli',
  60      => 'Altmış',
  70      => 'Yetmiş',
  80      => 'Seksen',
  90      => 'Doksan',
  100     => 'Yüz',
  110     => 'Yüz On',
  120     => 'Yüz Yirmi',
  130     => 'Yüz Otuz',
  140     => 'Yüz Kırk',
  150     => 'Yüz Elli',
  160     => 'Yüz Altmış',
  170     => 'Yüz Yetmiş',
  180     => 'Yüz Seksen',
  190     => 'Yüz Doksan',
  200     => 'İki Yüz',
  300     => 'Üç Yüz',
  400     => 'Dört Yüz',
  500     => 'Beş Yüz',
  600     => 'Altı Yüz',
  700     => 'Yedi Yüz',
  800     => 'Sekiz Yüz',
  900     => 'Dokuz Yüz',
  1000    => 'Bin',
  1100    => 'Bin Yüz',
  1200    => 'Bin İki Yüz',
  1300    => 'Bin Üç Yüz',
  1400    => 'Bin Dört Yüz',
  1500    => 'Bin Beş Yüz',
  1600    => 'Bin Altı Yüz',
  1700    => 'Bin Yedi Yüz',
  1800    => 'Bin Sekiz Yüz',
  1900    => 'Bin Dokuz Yüz',
  2000    => 'İki Bin',
  3000    => 'Üç Bin',
  4000    => 'Dört Bin',
  5000    => 'Beş Bin',
  6000    => 'Altı Bin',
  7000    => 'Yedi Bin',
  8000    => 'Sekiz Bin',
  9000    => 'Dokuz Bin',
  10000   => 'On Bin',
  11000   => 'On Bir Bin',
  12000   => 'On İki Bin',
  13000   => 'On Üç Bin',
  14000   => 'On Dört Bin',
  15000   => 'On Beş Bin',
  16000   => 'On Altı Bin',
  17000   => 'On Yedi Bin',
  18000   => 'On Sekiz Bin',
  19000   => 'On Dokuz Bin',
  20000   => 'Yirmi Bin',
  21000   => 'Yirmi Bir Bin',
  22000   => 'Yirmi İki Bin',
  23000   => 'Yirmi Üç Bin',
  24000   => 'Yirmi Dört Bin',
  25000   => 'Yirmi Beş Bin',
  26000   => 'Yirmi Altı Bin',
  27000   => 'Yirmi Yedi Bin',
  28000   => 'Yirmi Sekiz Bin',
  29000   => 'Yirmi Dokuz Bin',
  30000   => 'Otuz Bin',
  100000  => 'Yüz Bin',
  200000  => 'İki Yüz Bin',
  1000000 => 'Bir Milyon',
  2000000 => 'İki Milyon',
);

BEGIN {
  $package = 'SL::CP';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

isa_ok $package, 'SL::CP';
my $cp = new_ok $package, [$language];
can_ok $cp, 'init', 'num2text', 'format_ten';

ok $cp->init, 'Initialize';

subtest 'Turkish numbers' => sub {
  for my $num (sort {$a <=> $b} keys %numbers) {
    is $cp->num2text($num), $numbers{$num}, "Translate $num";
  }
};
