use v5.40;

use utf8;
use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 5;

my $package;

BEGIN {
  $package = 'SL::SPS';
  use_ok $package;
}

isa_ok $package, 'SL::SPS';

can_ok $package,
  (
  'add_payment',          'gmtime',           'localtime',         'new',
  'payment_add_metadata', 'payment_type',     'payment_valid',     'sepa_escape',
  'to_xml',               'xml_address',      'xml_escape',        'xml_header',
  'xml_payment',          'xml_payment_bank', 'xml_payment_group', 'xml_payment_info',
  'xml_payment_reference',
  );

subtest 'SEPA escape' => sub {
  is SL::SPS::sepa_escape('Abc_defäöü0123'), 'Abcdef0123', 'SEPA escape';
};

subtest 'XML escape' => sub {
  my @test_strings = (
    ' abc '       => 'abc',
    '& < > " \''  => '&amp; &lt; &gt; &quot; &#39;',
    '« #3 »'      => '&quot; 3 &quot;',
    '$ £ ¥ € © ®' => 'USD GBP JPY EUR (C) (R)',
  );

  for my ($text, $expected) (@test_strings) {
    is SL::SPS::xml_escape($text), $expected, "Escape $text";
  }

  is SL::SPS::xml_escape(), '', 'Undef string';

  my $text = q|«5 € are more than 5 $»|;
  is SL::SPS::xml_escape($text, 15), '&quot;5 EUR are more', "Shorten '$text'";
};
