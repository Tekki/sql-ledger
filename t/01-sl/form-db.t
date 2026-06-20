use v5.40;

use utf8;
use open ':std', ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use SL::Form;

use Test::More tests => 3;

chdir "$FindBin::Bin/../..";

my $form = new_ok 'SL::Form';

my %expected = (
  col_m6 => 'bool',       # SQL_TINYINT
  col_m5 => 'number',     # SQL_BIGINT
  col_1  => 'text',       # SQL_CHAR
  col_2  => 'decimal',    # SQL_NUMERIC
  col_3  => 'decimal',    # SQL_DECIMAL
  col_4  => 'number',     # SQL_INTEGER
  col_5  => 'number',     # SQL_SMALLINT
  col_6  => 'decimal',    # SQL_FLOAT
  col_8  => 'decimal',    # SQL_DOUBLE
  col_9  => 'date',       # SQL_DATE
  col_12 => 'text',       # SQL_VARCHAR
  col_16 => 'bool',       # SQL_BOOLEAN
  col_91 => 'date',       # SQL_TYPE_DATE
);

subtest 'Data types from hashref' => sub {
  my %testvalues = (
    col_m6 => -6,
    col_m5 => -5,
    col_1  =>  1,
    col_2  =>  2,
    col_3  =>  3,
    col_4  =>  4,
    col_5  =>  5,
    col_6  =>  6,
    col_8  =>  8,
    col_9  =>  9,
    col_12 => 12,
    col_16 => 16,
    col_91 => 91,
  );

  is_deeply $form->dbtypes(\%testvalues), \%expected, 'Process hashref';
};

subtest 'Data types from statement handle' => sub {
  my @names = qw|col_m6 col_m5 col_1 col_2 col_3 col_4 col_5 col_6 col_8 col_9 col_12 col_16 col_91|;
  my @types = (-6, -5, 1, 2, 3, 4, 5, 6, 8, 9, 12, 16, 91);
  my $sth   = bless {NAME => \@names, TYPE => \@types}, 'DBI::st';

  is_deeply $form->dbtypes($sth), \%expected, 'Process sth';
};
