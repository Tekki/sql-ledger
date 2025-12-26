use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'rp.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'aging',                  'build_report',
    'continue',               'deselect_all',
    'deselect_all_reminder',  'deselect_all_statement',
    'display_all',            'do_print_reminder',
    'do_print_statement',     'e_mail',
    'e_mail_reminder',        'e_mail_statement',
    'generate_ap_aging',      'generate_ar_aging',
    'generate_balance_sheet', 'generate_income_statement',
    'generate_projects',      'generate_reminder',
    'generate_tax_report',    'generate_trial_balance',
    'list_accounts',          'list_payments',
    'payment_subtotal',       'prepare_e_mail',
    'print',                  'print_options',
    'print_reminder',         'print_report',
    'print_report_options',   'print_statement',
    'reminder',               'report',
    'save_level',             'section_display',
    'section_subtotal',       'select_all',
    'select_all_reminder',    'select_all_statement',
    'send_email_reminder',    'send_email_statement',
    'statement_details',      'subtotal',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
