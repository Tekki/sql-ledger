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
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Remittance vouchers' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'remittance_voucher',
    vc     => 'customer',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Sales orders' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'sales_order',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Work orders' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'work_order',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Quotations' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'sales_quotation',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Packing lists' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'packing_list',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Pick lists' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'pick_list',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Vendor invoices' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'invoice',
    vc     => 'vendor',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Purchase orders' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'purchase_order',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Bin lists' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'bin_list',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'RFQs' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'request_quotation',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Time cards' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'timecard',
  )->press_button_ok('Generate report', 'continue');
};

subtest 'Stores cards' => sub {
  $t->get_ok(
    'Report frontend', 'bp.pl',
    action => 'search',
    batch  => 'print',
    type   => 'storescard',
  )->press_button_ok('Generate report', 'continue');
};
