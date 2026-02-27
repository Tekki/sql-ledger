use v5.40;

use utf8;
use open ':std', ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use SL::Form;

use Test::More tests => 3;

chdir "$FindBin::Bin/../..";

my $form = new_ok 'SL::Form';

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
  my %myconfig = (numberformat => q|1'000.00|);
  my @numbers  = (
    5        => '5.00'     => '5.00',
    5        => '5.00'     => '5.00',
    5432.1   => "5'432.10" => "5'432.10",
    5432.12  => "5'432.12" => "5'432.12",
    5432.123 => "5'432.12" => "5'432.12",
    0        => ''         => '0.00',
    ''       => ''         => '0.00',
    ' '      => ''         => '0.00',
    undef    => ''         => '0.00',
  );

  for my ($number, $formatted, $dash) (@numbers) {
    is $form->format_amount(\%myconfig, $number, 2), $formatted, "Format '$number'";
    is $form->format_amount(\%myconfig, $number, 2, 0), $dash, "Format '$number' with dash";
  }
};
