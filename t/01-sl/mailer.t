use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 5;

my $package;

BEGIN {
  $package = 'SL::Mailer';
  use_ok $package;
}

isa_ok $package, 'SL::Mailer';

my $obj = new_ok $package;

can_ok $obj, ('encode_base64', 'new', 'send',);

subtest 'Defaults' => sub {
  my %expected = (
    attachments => [],
    bcc         => '',
    cc          => '',
    charset     => 'UTF-8',
    contenttype => 'text/plain',
    fileid      => '',
    from        => '',
    message     => '',
    notify      => '',
    subject     => '',
    to          => '',
    version     => '',
  );

  is_deeply $obj, \%expected, 'Content is correct';
};
