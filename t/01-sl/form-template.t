use v5.40;

use utf8;
use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Mojo::File 'path';
use Mojo::Util 'encode';

use SL::Form;

use Test::More tests => 3;

chdir "$FindBin::Bin/../..";

my $form = new_ok 'SL::Form';

subtest 'Format line' => sub {
  my @lines = (
    'Hello there' => '<%testvalue%>' => 'Hello there',

    # if else
    'Hello there' => '<%if testvalue%>Yes<%end testvalue%>'                      => 'Yes',
    'Hello there' => '<%if not testvalue%>No<%end testvalue%>'                   => '',
    ''            => '<%if not testvalue%>No<%end testvalue%>'                   => 'No',
    ''            => '<%if testvalue%>One<%else testvalue%>Two<%end testvalue%>' => 'Two',

    # align
    'Hello there'  => '<%testvalue width=20 align=left%>'  => 'Hello there         ',
    'Hello there'  => '<%testvalue width=20 align=right%>' => '         Hello there',
    "Hello\nthere" => '<%testvalue width=10 align=right%>' => "     Hello\n     there",

    # 'Hello there' => '<%testvalue width=20 align=center%>' => '    Hello there     ',
    # center: wrong result with length 19

    # group
    '0123456789' => '<%testvalue group=3left%>'  => '012 345 678 9',
    '0123456789' => '<%testvalue group=3right%>' => '0 123 456 789',
  );

  for my ($value, $template, $expected) (@lines) {
    $form->{testvalue} = $value;
    is $form->format_line($template), $expected, "Format $value with $template";
  }
};

subtest 'Format line, QR Code' => sub {
  my @lines = (
    'Tekki' => '<%testvalue qrcode=50%>'                            => 'Tekki_50x50_black.tex',
    'Tekki' => '<%testvalue qrcode=70 margin=10 background=green%>' =>
      'Tekki_70x70_black_green.tex',
    'Szőlőlé' => '<%testvalue qrcode=60 foreground=red level=H%>' => 'Grapejuice_60x60_H_red.tex',
  );

  for my ($value, $template, $expected) (@lines) {
    $form->{testvalue} = $value;
    ok my $latex = $form->format_line($template), "Format $value with $template";
    is $latex, path("t/testdata/qrcode-$expected")->slurp, 'Content is correct';
  }
};
