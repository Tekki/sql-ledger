use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use Test::More tests => 3;

my $package;

BEGIN {
  $package = 'SL::RU';
  use_ok $package;
}

isa_ok $package, 'SL::RU';

can_ok $package,
  (
  'AP_TRANSACTION',  'AR_TRANSACTION',    'CODES',         'CUSTOMER',
  'GL_TRANSACTION',  'ITEM',              'MAX_RECENT',    'PROJECT',
  'PURCHASE_ORDER',  'REQUEST_QUOTATION', 'SALES_INVOICE', 'SALES_ORDER',
  'SALES_QUOTATION', 'TIMECARD',          'VENDOR',        'VENDOR_INVOICE',
  '_code',           '_code_',            '_code_ap',      '_code_ar',
  '_code_ct',        '_code_gl',          '_code_ic',      '_code_ir',
  '_code_is',        '_code_jc',          '_code_oe',      '_code_pe',
  '_descr',          '_descr_ap',         '_descr_ar',     '_descr_ct',
  '_descr_gl',       '_descr_ic',         '_descr_jc',     '_descr_oe1',
  '_descr_oe2',      '_descr_pe',         '_employee_id',  '_object_id',
  'delete',          'list',              'register',      'unregister',
  );
