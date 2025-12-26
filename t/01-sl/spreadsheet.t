use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use Mojo::File 'tempdir';
use lib "$FindBin::Bin/../..";

use Test::More tests => 4;

my $package;

BEGIN {
  $package = 'SL::Spreadsheet';
  use_ok $package;
}

isa_ok $package, 'SL::Spreadsheet';

my $tmp = tempdir;

$ENV{HTTP_REFERER} = 'http://localhost';
my $obj = new_ok $package, [{path => 't/dummy', login => 'someone'}, $tmp];

can_ok $obj,
  (
  '_get_set',      'adjust_columns', 'balance',           'balance_column',
  'balance_fn',    'balance_group',  'balance_start',     'bool',
  'change_format', 'column_index',   'crlf',              'data_row',
  'date',          'decimal',        'finish',            'freeze_panes',
  'group_by',      'group_label',    'group_title',       'header_row',
  'lf',            'link',           'looks_like_number', 'max',
  'maxwidth',      'min',            'new',               'nonzero_decimal',
  'number',        'report_options', 'reset_width',       'set_width',
  'structure',     'subtotal_row',   'tab',               'table_row',
  'text',          'title',          'title_row',         'total_row',
  'totalize',      'worksheet',
  );
