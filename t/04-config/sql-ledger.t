use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Storable;

use Test::More tests => 8;

chdir "$FindBin::Bin/../..";

my @config_params = (
  'accessfolders', 'admin_totp_activated', 'charset',       'dvipdf',
  'gpg',           'gzip',                 'helpful_login', 'images',
  'language',      'latex',                'memberfile',    'pdftk',
  'sendmail',      'spool',                'templates',     'userspath',
  'xelatex',
);

my $sl_bin = 'config/sql-ledger.bin';
my $sl_yml = 'config/sql-ledger.yml';

for my $file ($sl_yml, $sl_bin) {
  ok -f $file, "$file exists" or BAIL_OUT "$file: File not found."
}

ok -M $sl_bin < -M $sl_yml, "$sl_bin is up to date";

ok my $slconfig = retrieve $sl_bin, 'Read config';

subtest 'All parameters' => sub {
  for (@config_params) {
    ok exists $slconfig->{$_}, "Parameter $_ exists";
  }
};

ok keys %$slconfig == @config_params, 'No additional parameters';

subtest 'Booleans' => sub {
  for ('dvipdf', 'latex', 'pdftk', 'xelatex') {
    is ref $slconfig->{$_}, !!0, "$_ is a boolean";
  }
};

subtest 'Arrays' => sub {
  for ('accessfolders') {
    is ref $slconfig->{$_}, 'ARRAY', "$_ is an array";
  }
}
