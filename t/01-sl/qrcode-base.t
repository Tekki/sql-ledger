use v5.40;

use utf8;
use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Mojo::File 'path';

use Test::More tests => 5;

chdir "$FindBin::Bin/../..";

my $package;

BEGIN {
  $package = 'SL::QRCode';
  use_ok $package;
}

isa_ok $package, 'SL::QRCode';

can_ok $package, ('decode_file', 'decode_qrbill', 'fmax', 'plot_latex', 'plot_svg',);

# plot

subtest 'Plot QR SVG' => sub {
  my $plot   = $package->can('plot_svg');
  my $text   = 'Tekki';
  my %params = (width => 200, height => 200);
  ok my $svg = $plot->($text, %params), 'Plot QR Code';
  is $svg, path('t/testdata/qrcode-Tekki_200x200_black.svg')->slurp, 'Content is correct';

  $text               = 'Szőlőlé';
  $params{level}      = 'H';
  $params{foreground} = 'red';
  ok $svg = $plot->($text, %params), 'Plot with red unicode text';
  is $svg, path('t/testdata/qrcode-Grapejuice_200x200_H_red.svg')->slurp, 'Content is correct';
};

subtest 'Plot QR LaTeX' => sub {
  my $plot   = $package->can('plot_latex');
  my $text   = 'Tekki';
  my %params = (height => 50);
  ok my $svg = $plot->($text, %params), 'Plot QR Code';
  is $svg, path('t/testdata/qrcode-Tekki_50x50_black.tex')->slurp, 'Content is correct';

  %params = (
    margin              => 10,
    height              => 70,
    additional_elements => ['  \draw[draw=blue] (5,5) rectangle (65,65);'],
  );
  ok $svg = $plot->($text, %params), 'Plot with margin and additional element';
  is $svg, path('t/testdata/qrcode-Tekki_70x70_addition.tex')->slurp, 'Content is correct';

  %params = (
    background => 'green',
    margin     => 10,
    height     => 70,
  );
  ok $svg = $plot->($text, %params), 'Plot with margin and green background';
  is $svg, path('t/testdata/qrcode-Tekki_70x70_black_green.tex')->slurp, 'Content is correct';

  $text   = 'Szőlőlé';
  %params = (level => 'H', foreground => 'red', height => 60);
  ok $svg = $plot->($text, %params), 'Plot with red unicode text';
  is $svg, path('t/testdata/qrcode-Grapejuice_60x60_H_red.tex')->slurp, 'Content is correct';
};
