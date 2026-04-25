use v5.40;

use utf8;
use open ':std', ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use SL::Form;

use Test::More tests => 5;

chdir "$FindBin::Bin/../..";

my $form = new_ok 'SL::Form';

subtest 'Parse numbers' => sub {
  my @numbers = (
    undef          => q|1,000.00|    => 0,
    q||            => q|1,000.00|    => 0,
    q| |           => q|1,000.00|    => 0,
    q|x|           => q|1,000.00|    => 0,
    q|1,234.56|    => q|1,000.00|    => 1234.56,
    q|1234.56|     => q|1000.00|     => 1234.56,
    q|1.234,56|    => q|1.000,00|    => 1234.56,
    q|1234,56|     => q|1000,00|     => 1234.56,
    q|1'234.56|    => q|1'000.00|    => 1234.56,
    q|1,23,456.78| => q|1,00,000.00| => 123456.78,
    q|1234.56|     => ''             => 1234.56,
  );

  for my ($number, $format, $expected) (@numbers) {
    my %myconfig = $format ? (numberformat => $format) : ();
    is my $parsed = $form->parse_amount(\%myconfig, $number), $expected, "Parse |$number| with $format";
    isa_ok $parsed, 'Math::BigFloat', "Parsed |$number|";
    is $form->parse_amount(\%myconfig, $parsed), $parsed, "Parse parsed $parsed";
  }
};

subtest 'Arithmetics' => sub {
  require Math::BigFloat;    # patched in SL::Form
  my $n;
  is $n = Math::BigFloat->new(),    0, 'Create number with undefined';
  is $n = Math::BigFloat->new(''),  0, 'Create number with empty string';
  is $n = Math::BigFloat->new(' '), 0, 'Create number with space';
  is $n = Math::BigFloat->new('a'), 0, 'Create number with text';
  is $n = Math::BigFloat->new(5),   5, 'Create number 5';
  is $n + 1,     6,  'Add number';
  is $n + '',    5,  'Add empty string';
  is $n + 'x',   5,  'Add empty string';
  is $n + undef, 5,  'Add undefined';
  is $n * 2,     10, 'Multiply by empty string';
  is $n * '',    0,  'Multiply by empty string';
  is $n * 'x',   0,  'Multiply by empty string';
  is $n * undef, 0,  'Multiply by undefined';
};

subtest 'Round numbers' => sub {
  my @numbers = (
    5     => 5,
    5.4   => 5.4,
    5.43  => 5.43,
    5.432 => 5.43,
    5.435 => 5.44,
    0     => 0,
    ''    => 0,
    ' '   => 0,
    undef => 0,
  );

  for my ($number, $rounded) (@numbers) {
    is $form->round_amount( $number, 2), $rounded, "Round '$number'";
  }
};

subtest 'Format numbers' => sub {
  my @numbers = (
    undef    => q|1'000.00| => q||         => q|0.00|,
    ''       => q|1'000.00| => q||         => q|0.00|,
    ' '      => q|1'000.00| => q||         => q|0.00|,
    0        => q|1'000.00| => q||         => q|0.00|,
    5        => q|1'000.00| => q|5.00|     => q|5.00|,
    5432.1   => q|1'000.00| => q|5'432.10| => q|5'432.10|,
    5432.12  => q|1'000.00| => q|5'432.12| => q|5'432.12|,
    5432.123 => q|1'000.00| => q|5'432.12| => q|5'432.12|,
    0        => q|1.000,00| => q||         => q|0,00|,
    5        => q|1.000,00| => q|5,00|     => q|5,00|,
    5432.1   => q|1.000,00| => q|5.432,10| => q|5.432,10|,
    5432.12  => q|1.000,00| => q|5.432,12| => q|5.432,12|,
    5432.123 => q|1.000,00| => q|5.432,12| => q|5.432,12|,
    5432.1   => ''          => q|5432.1|   => q|5432.1|,
  );

  for my ($number, $format, $formatted, $dashed) (@numbers) {
    my %myconfig = $format ? (numberformat => $format) : ();
    is $form->format_amount(\%myconfig, $number, 2), $formatted, "Format '$number'";
    is $form->format_amount(\%myconfig, Math::BigFloat->new($number), 2), $formatted,
      "Format BigFloat '$number'";
    is $form->format_amount(\%myconfig, $number, 2, 0), $dashed, "Format '$number' with dash";
    is $form->format_amount(\%myconfig, Math::BigFloat->new($number), 2, 0), $dashed,
      "Format BigFloat '$number' with dash";
  }
};
