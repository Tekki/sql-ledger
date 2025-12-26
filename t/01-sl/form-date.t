use v5.40;

use utf8;
use open ':std', ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";

use SL::Form;

use Test::More tests => 7;

chdir "$FindBin::Bin/../..";

my $form = new_ok 'SL::Form';

subtest 'Split date' => sub {
  my @dates = (
    'mm-dd-yy'   => '01-14-2025' => '01142025',
    'mm/dd/yy'   => '01/14/2025' => '01142025',
    'dd-mm-yy'   => '14-01-2025' => '14012025',
    'dd/mm/yy'   => '14/01/2025' => '14012025',
    'dd.mm.yy'   => '14.01.2025' => '14012025',
    'yyyy-mm-dd' => '2025-01-14' => '20250114',
  );

  my @split = ('25', '01', '14');

  for my ($format, $date, $expected) (@dates) {
    is_deeply [$form->split_date($format, $date)], [$expected, @split], "Split $format";
  }
};

subtest 'First and last day of month' => sub {
  my @dates = (
    'mm-dd-yy' => '01-14-2025' => '01-01-2025', => '01-31-2025',
    'mm/dd/yy' => '01/14/2025' => '01/01/2025', => '01/31/2025',
    'dd-mm-yy' => '14-01-2025' => '01-01-2025', => '31-01-2025',
    'dd/mm/yy' => '14/01/2025' => '01/01/2025', => '31/01/2025',
    'dd.mm.yy' => '14.01.2025' => '01.01.2025', => '31.01.2025',
    'yyyy-mm-dd' => '2025-01-14' => '2025-01-01', => '2025-01-31',
  );

  for my ($format, $date, $first, $last) (@dates) {
    is $form->dayofmonth($format, $date, 'fdm'), $first, "First for $date";
    is $form->dayofmonth($format, $date), $last, "Last for $date";
  }
};

subtest 'Date to number' => sub {
  my @dates = (
    'mm-dd-yy'   => '01-14-2025',
    'mm/dd/yy'   => '01/14/2025',
    'dd-mm-yy'   => '14-01-2025',
    'dd/mm/yy'   => '14/01/2025',
    'dd.mm.yy'   => '14.01.2025',
    'yyyy-mm-dd' => '2025-01-14',
  );

  for my ($format, $date) (@dates) {
    is $form->datetonum({dateformat => $format}, $date), '20250114', "Numeric of $format";
  }
};

subtest 'Format date' => sub {
  my @dates = (
    'mm-dd-yy'   => '01-14-25',
    'mm/dd/yy'   => '01/14/25',
    'dd-mm-yy'   => '14-01-25',
    'dd/mm/yy'   => '14/01/25',
    'dd.mm.yy'   => '14.01.25',
    'yyyy-mm-dd' => '2025-01-14',
  );

  for my ($format, $date) (@dates) {
    is $form->format_date($format, '20250114'), $date, "Date formatted as $format";
  }

  is $form->format_date('', ''), '', 'Empty date';
};

subtest 'Weekday' => sub {
  my @dates = (
    '05.01.2025', '06.01.2025', '07.01.2025', '08.01.2025',
    '09.01.2025', '10.01.2025', '11.01.2025',
  );

  for my $i (0 .. $#dates) {
    is $form->weekday({dateformat => 'dd.mm.yy'}, $dates[$i]), $i, "Weekday for $dates[$i]";
  }
};

subtest 'Working days' => sub {
  my @workdays = ('06.01.2025', '07.01.2025', '08.01.2025', '09.01.2025', '10.01.2025',);
  my @holidays = ('05.01.2025', '11.01.2025',);

  for my $day (@workdays) {
    ok $form->workingday({dateformat => 'dd.mm.yy'}, $day), "$day is workday";
  }

  for my $day (@holidays) {
    ok !$form->workingday({dateformat => 'dd.mm.yy'}, $day), "$day is holiday";
  }
};
