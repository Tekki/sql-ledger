use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 8;

my $package;

BEGIN {
  $package = 'SL::TOTP';
  use_ok $package;
}

isa_ok $package, 'SL::TOTP';

can_ok $package,
  (
  'add_secret',    'check_code',      'decode',    'decode_base32',
  'encode_base32', 'generate_secret', 'hmac_sha1', 'url',
  );

subtest 'Base 32' => sub {
  my $decoded
    = 'Hallo world, whats new? 1234567890 abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ .:!%$@#*()[]{}<>"/ ';
  my $encoded
    = 'JBQWY3DPEB3W64TMMQWCA53IMF2HGIDOMV3T6IBRGIZTINJWG44DSMBAMFRGGZDFMZTWQ2LKNNWG23TPOBYXE43UOV3HO6DZPIQECQSDIRCUMR2IJFFEWTCNJZHVAUKSKNKFKVSXLBMVUIBOHIQSKJCAEMVCQKK3LV5X2PB6EIXSA';

  is SL::TOTP::encode_base32($decoded), $encoded, 'Encode to Base 32';
  is SL::TOTP::decode_base32($encoded), $decoded, 'Decode from Base 32';
};

subtest 'Generate secret' => sub {
  ok SL::TOTP::generate_secret =~ /[A-Z0-9]+/;
};

subtest 'Add secret' => sub {
  my $user = {};
  SL::TOTP::add_secret($user);
  ok $user->{totp_secret},        'Secret added';
};

subtest 'URL' => sub {
  my $user = {
    login       => 'someone@company',
    totp_secret => 'JBSWY3DPEHPK3PXP',
  };

  is SL::TOTP::url($user),
    'otpauth://totp/SQL-Ledger:someone@company?secret=JBSWY3DPEHPK3PXP&issuer=SQL-Ledger&algorithm=SHA1&digits=6&period=30',
    'URL without server name';

  $ENV{SERVER_NAME} = 'somewhere';

  is SL::TOTP::url($user),
    'otpauth://totp/SQL-Ledger:someone@company@somewhere?secret=JBSWY3DPEHPK3PXP&issuer=SQL-Ledger&algorithm=SHA1&digits=6&period=30',
    'URL with server name';

};

subtest 'Check codes' => sub {

  # test vectors from RFC 6238 Appendix B
  my @testcodes = (
    ['GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', '050471', 1111111111],
    ['GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', '287082', 59],
    ['GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', '081804', 1111111109],
    ['GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', '050471', 1111111111],
    ['GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', '005924', 1234567890],
    ['GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', '279037', 2000000000],
    ['GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ', '353130', 20000000000],
  );

  for my $code (@testcodes) {
    ok SL::TOTP::check_code({totp_secret => $code->[0]}, $code->[1], $code->[2]),
      "Code $code->[1] is correct";
  }
};
