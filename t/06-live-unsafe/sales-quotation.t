# Never run this test on a production system!
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
  plan tests => 6;
} else {
  plan skip_all => 'SL_LIVETEST not enabled.';
}

$t = SL::TestClient->new(configfile => $configfile)->connect_ok->api_login_ok;

subtest 'Update latest sales quotation' => sub {
  $t->get_ok('Report frontend', 'oe.pl', action => 'search', type => 'sales_quotation')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open quotation', 'quonumber-l', 0)
    ->store_ok('quonumber')
    ->press_button_ok('Update',           'update')
    ->press_button_ok('Save quotation', 'save')
    ->press_button_ok('Confirm changes',  'continue')
    ->elements_exist('Links to number, name', 'a.quonumber-l', 'a.name-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used quotation', 'a.number-l' => \'quonumber');
};

subtest 'Add new quotations' => sub {
  for my $quo ($t->config->{sales_quotation}{new}->@*) {
    $t->get_ok('Quotation screen', 'oe.pl', action => 'add', type => 'sales_quotation')
      ->set_params_ok('Quotation header', description => $t->test_stamp, $quo->{header}->%*)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('quonumber');

    for my $row ($quo->{rows}->@*) {
      $t->update_row_ok('Add row', 'rowcount', $row->%*);
    }

    $t->press_button_ok('Save quotation', 'save')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->texts_are('Most recently used quotation', 'a.number-l' => \'quonumber')
      ->follow_link_ok('Open quotation', 'number-l')
      ->params_are(
        'Content of quotation',
        description => \'test_stamp',
        quonumber   => \'quonumber',
        $quo->{expected}->%*
        )
      ->rows_are('Quotation rows', $quo->{expected_rows}->@*)
  }
};

subtest 'Print quotation' => sub {
  $t->get_ok('Report frontend', 'oe.pl', action => 'search', type => 'sales_quotation')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open quotation', 'quonumber-l', 0);

  for my ($lang, $templates) ($t->config->{sales_quotation}{print}->%*) {
    $t->set_params_ok(
      'Set language and format',
      language_code => $lang eq 'default' ? '' : $lang,
      format        => 'pdf'
    );

    for my $template (@$templates) {
      $t->set_params_ok("Template $template", formname => $template)
        ->download_ok("Print $lang $template", 'pdf', 'preview')
        ->download_is("$lang $template", 'pdf');
    }
  }
};

$t->remove_locks_ok;
