use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More;
use SL::TestClient;

chdir "$FindBin::Bin/../..";

my $configfile = "$FindBin::Bin/../testdata/testconfig.yml";
my $t;

if ($ENV{SL_LIVETEST}) {
  plan tests => 15;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Sales invoices' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'invoice',
    vc     => 'customer',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Remittance vouchers' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'remittance_voucher',
    vc     => 'customer',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Sales orders' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'sales_order',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Work orders' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'work_order',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Quotations' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'sales_quotation',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Packing lists' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'packing_list',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Pick lists' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'pick_list',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Vendor invoices' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'invoice',
    vc     => 'vendor',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Purchase orders' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'purchase_order',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Bin lists' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'bin_list',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'RFQs' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'request_quotation'
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Time cards' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'timecard',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};

subtest 'Stores cards' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'storescard',
    )
    ->press_button_ok('Generate report', 'continue')
    ->buttons_exist('select_all', 'print')
    ->accesskeys_exist(qw|? A P|);
};
