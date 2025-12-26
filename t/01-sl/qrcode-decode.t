use v5.40;

use utf8;
use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Mojo::File 'path';

use Test::More;
use SL::QRCode;

chdir "$FindBin::Bin/../..";

if (eval { require Imager::zxing; require Image::Magick; 1; }) {
  plan tests => 3;
} else {
  plan skip_all => 'Imager::zxing or Image::Magick not installed.';
}
  
# decode

subtest 'Decode files with single codes' => sub {
  my $decoder = SL::QRCode->can('decode_file');

  my @testfiles = (
    'inexistant' => {result => 'error', errstr => "File not found: t/testdata/qrcode-inexistant"},
    'Empty.png'  => {result => 'error', errstr => 'No code found'},
    'Tekki_200x200_black.png'      => {result => 'ok', data => 'Tekki'},
    'Grapejuice_200x200_H_red.png' => {result => 'ok', data => 'Szőlőlé'},
    'Tekki.pdf'                    => {result => 'ok', data => 'Tekki'},
    'Grapejuice.pdf'               => {result => 'ok', data => 'Szőlőlé'},
  );

  for my ($file, $expected) (@testfiles) {
    is_deeply $decoder->("t/testdata/qrcode-$file"), $expected, 'Content is correct',;
  }
};

subtest 'Decode files with multiple codes' => sub {
  my $decoder = SL::QRCode->can('decode_file');

  my @testfiles = (

    # png
    'Tekki_Grapejuice_400x400.png' => {width => 200, height => 200} =>
      {result => 'ok', data => 'Tekki'},
    'Tekki_Grapejuice_400x400.png' => {left => 200, height => 200} =>
      {result => 'ok', data => 'Szőlőlé'},
    'Tekki_Grapejuice_400x400.png' => {top  => 200} => {result => 'ok', data => 'Szőlőlé'},
    'Tekki_Grapejuice_400x400.png' => {left => 200} => {result => 'ok', data => 'Szőlőlé'},
    'Tekki_Grapejuice_400x400.png' => {left => 200, top => 200} =>
      {result => 'ok', data => 'Tekki'},

    # pdf
    'Tekki_Grapejuice_1page.pdf' => {width => 50, height => 50} =>
      {result => 'ok', data => 'Tekki'},
    'Tekki_Grapejuice_1page.pdf' => {left => 50, height => 50} =>
      {result => 'ok', data => 'Szőlőlé'},
    'Tekki_Grapejuice_1page.pdf' => {top  => 50} => {result => 'ok', data => 'Szőlőlé'},
    'Tekki_Grapejuice_1page.pdf' => {left => 50} => {result => 'ok', data => 'Szőlőlé'},
    'Tekki_Grapejuice_1page.pdf' => {left => 50, top => 50} => {result => 'ok', data => 'Tekki'},
  );

  my $i;
  for my ($file, $params, $expected) (@testfiles) {
    $i++;
    is_deeply $decoder->("t/testdata/qrcode-$file", %$params), $expected, "Content $i is correct",;
  }
};

subtest 'Decode files with multiple pages' => sub {
  my $decoder = SL::QRCode->can('decode_file');

  my @testfiles = (
    'Tekki_Grapejuice_2pages.pdf' => {} => {result => 'ok', data => 'Tekki'},
    'Tekki_Grapejuice_2pages.pdf' => {page => 0} => {result => 'ok', data => 'Szőlőlé'},
    'Tekki_Grapejuice_2pages.pdf' => {page => 1} => {result => 'ok', data => 'Tekki'},
    'Tekki_Grapejuice_2pages.pdf' => {page => 2} => {result => 'ok', data => 'Szőlőlé'},
  );

  my $i;
  for my ($file, $params, $expected) (@testfiles) {
    $i++;
    is_deeply $decoder->("t/testdata/qrcode-$file", %$params), $expected, "Content $i is correct",;
  }
};
