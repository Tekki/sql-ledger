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

subtest 'Update latest transaction' => sub {
  $t->get_ok(
    'Report frontend', 'ar.pl',
    action      => 'search',
    nextsub     => 'transactions',
    outstanding => 1
    )
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open transaction', 'ar-l', 0)
    ->store_ok('invnumber')
    ->press_button_ok('Update', 'update')
    ->press_button_ok('Post transaction', 'post')
    ->press_button_ok('Confirm changes', 'continue')
    ->elements_exist('Links to invoice, name', 'a.invnumber-l', 'a.ar-l', 'a.is-l', 'a.name-l')
    ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
    ->texts_are('Most recently used transaction', 'a.number-l' => \'invnumber');
};

subtest 'Add new transactions' => sub {
  for my $tr ($t->config->{ar_transaction}{new}->@*) {
    $t->get_ok('Transaction screen', 'ar.pl', action => 'add', type => 'transaction')
      ->set_params_ok('Transaction header', description => $t->test_stamp, $tr->{header}->%*)
      ->press_button_ok('Get new number', 'new_number')
      ->store_ok('invnumber');

    for my $row ($tr->{rows}->@*) {
      $t->update_row_ok('Add row', 'rowcount', $row->%*);
    }

    for my $payment ($tr->{payments}->@*) {
      $payment->{datepaid} ||= $t->date_tomorrow;
      $t->update_row_ok('Add payment', 'paidaccounts', $payment->%*);
    }

    $t->press_button_ok('Post transaction', 'post')
      ->get_ok('Recently used', 'ru.pl', action => 'list_recent')
      ->texts_are('Most recently used transaction', 'a.number-l' => \'invnumber')
      ->follow_link_ok('Open transaction', 'number-l')
      ->params_are(
      'Content of transaction',
      description => \'test_stamp',
      invnumber   => \'invnumber',
      $tr->{expected}->%*
      );
  }
};

subtest 'Print transaction' => sub {
  $t->get_ok(
    'Report frontend', 'ar.pl',
    action      => 'search',
    nextsub     => 'transactions',
    outstanding => 1
    )
    ->press_button_ok('Generate report', 'continue')
    ->follow_link_ok('Open transaction', 'ar-l', 0);

  for my ($lang, $templates) ($t->config->{ar_transaction}{print}->%*) {
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
