use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Mojo::File 'tempdir';
use Storable;
use Cwd;

use Test::More tests => 15;

my $package;

my $oldpwd = getcwd;
my $lang   = 'xyz';
my $file   = 'abc';
my %texts = (
  one       => 'eins',
  two       => 'zwei',
  three     => 'drei',
  January   => 'Januar',
  February  => 'Februar',
  March     => 'März',
  April     => 'April',
  May       => 'Mai',
  June      => 'Juni',
  July      => 'Juli',
  August    => 'August',
  September => 'September',
  October   => 'Oktober',
  November  => 'November',
  December  => 'Dezember',
  Jan       => 'Jan',
  Feb       => 'Feb',
  Mar       => 'Mär',
  Apr       => 'Apr',
  May       => 'Mai',
  Jun       => 'Jun',
  Jul       => 'Jul',
  Aug       => 'Aug',
  Sep       => 'Sep',
  Oct       => 'Okt',
  Nov       => 'Nov',
  Dec       => 'Dez',
);
my %subs = (
  sub_one  => 'sub_one',
  sub_eins => 'sub_one',
  sub_two  => 'sub_two',
  sub_zwei => 'sub_two',
);
my @missing_texts = qw|four five six seven|;

my @testdates    = qw|20380119 380119 19.1.2038|;
my %number_dates = ('dd.mm.yy' => '19.01.2038',);
my %short_dates  = ('dd.mm.yy' => '19. Jan 2038',);
my %long_dates   = ('dd.mm.yy' => '19. Januar 2038',);

BEGIN {
  $package = 'SL::Locale';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

isa_ok $package, 'SL::Locale';

can_ok $package, ('date', 'findsub', 'new', 'text',);

ok my $tmp = tempdir, 'Create temporary directory';
ok chdir $tmp, 'Change to temporary directory';

ok $tmp->child("locale/$lang")->make_path, "Locale directory for $lang";

ok store({texts => \%texts, subs => \%subs}, "$tmp/locale/$lang/$file.bin"), "Create test translation";

my $locale = new_ok $package, [$lang, $file];

subtest 'Texts' => sub {
  for my $key (keys %texts) {
    is $locale->text($key), $texts{$key}, "Translation for $key";
  }
};

subtest 'Missing texts' => sub {
  for my $key (@missing_texts) {
    is $locale->text($key), $key, "No translation for $key";
  }
};

subtest 'Subroutines' => sub {
  for my $key (keys %subs) {
    is $locale->findsub($key), $subs{$key}, "Subroutine for $key";
  }
};

subtest 'Unformatted dates' => sub {
  for my $date (@testdates) {
    is $locale->date({}, $date), $date, "Unformatted $date";
  }
};

subtest 'Number dates' => sub {
  for my $date (@testdates) {
    for my $format (keys %number_dates) {
      is $locale->date({dateformat => $format}, $date), $number_dates{$format},
        "$date formatted as $number_dates{$format}";
    }
  }
};

subtest 'Short dates' => sub {
  for my $date (@testdates) {
    for my $format (keys %short_dates) {
      is $locale->date({dateformat => $format}, $date, 0), $short_dates{$format},
        "$date formatted as $number_dates{$format}";
    }
  }
};

subtest 'Long dates' => sub {
  for my $date (@testdates) {
    for my $format (keys %long_dates) {
      is $locale->date({dateformat => $format}, $date, 1), $long_dates{$format},
        "$date formatted as $number_dates{$format}";
    }
  }
};

chdir $oldpwd;
