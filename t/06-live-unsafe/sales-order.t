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

subtest 'Update latest sales order' => sub {
  $t->get_ok('Report frontend', 'oe.pl', action => 'search', type => 'sales_order')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open order', 'ordnumber-l', 0)
    ->store_ok('ordnumber')
    ->press_button_ok('Update',           'update')
    ->press_button_ok('Save order', 'save')
    ->press_button_ok('Confirm changes',  'continue')
    ->elements_exist('Links to number, name', 'a.ordnumber-l', 'a.name-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used order', 'a.number-l' => \'ordnumber');
};

subtest 'Add new orders' => sub {
  for my $ord ($t->config->{sales_order}{new}->@*) {
    $t->get_ok('Order screen', 'oe.pl', action => 'add', type => 'sales_order')
      ->set_params_ok('Order header', description => $t->test_stamp, $ord->{header}->%*)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('ordnumber');

    for my $row ($ord->{rows}->@*) {
      $t->update_row_ok('Add row', 'rowcount', $row->%*);
    }

    for my $payment ($ord->{payments}->@*) {
      $payment->{datepaid} ||= $t->date_tomorrow;
      $t->update_row_ok('Add payment', 'paidaccounts', $payment->%*);
    }

    $t->press_button_ok('Save order', 'save')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->texts_are('Most recently used order', 'a.number-l' => \'ordnumber')
      ->follow_link_ok('Open order', 'number-l')
      ->params_are(
        'Content of order',
        description => \'test_stamp',
        ordnumber   => \'ordnumber',
        $ord->{expected}->%*
        )
      ->rows_are('Order rows', $ord->{expected_rows}->@*)
      ->rows_are('Payments', $ord->{expected_payments}->@*);
  }
};

subtest 'Print order' => sub {
  $t->get_ok('Report frontend', 'oe.pl', action => 'search', type => 'sales_order')
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open order', 'ordnumber-l', 0);

  for my ($lang, $templates) ($t->config->{sales_order}{print}->%*) {
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
