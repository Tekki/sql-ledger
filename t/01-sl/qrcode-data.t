use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Mojo::File 'path';
use YAML::PP;
use YAML::PP::Common ':PRESERVE';

use Test::More;
use SL::QRCode;

chdir "$FindBin::Bin/../..";

my $yp       = YAML::PP->new(preserve => PRESERVE_ORDER);
my $datafile = 't/testdata/qrcode-testdata.yml';
my $testdata;

if (-f $datafile) {
  plan tests => 1;
} else {
  plan skip_all => 'No test data.';
}

$testdata = $yp->load_file($datafile);

subtest 'Decode Swiss QR Bill' => sub {
  my $decoder = SL::QRCode->can('decode_qrbill');

  is_deeply $decoder->('t/testdata/qrcode-Tekki_200x200_black.png'),
    {result => 'error', errstr => 'Not a QR Bill', data => 'Tekki'}, 'Not a QR Bill';

  my $qrbills = $testdata->{qrbills};

  for my ($file, $page) (%$qrbills) {
    ok my $rv = $decoder->("$file.pdf", $page);
    is $rv->{result}, 'ok', "$file: processed" or do { diag $rv->{errstr}; next; };

    my $expected = path("$file.txt")->slurp('UTF-8');
    is $rv->{data}, $expected, "$file: content is correct";

    my $struc = $yp->load_file("$file.yml");
    is_deeply $rv->{structured_data}, $struc, "$file: structured data is correct";
  }
};
