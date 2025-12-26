use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'arap.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'add_transaction',  'ap_transaction',      'ar_transaction',    'check_name',
    'check_project',    'continue',            'credit_invoice_',   'debit_invoice_',
    'delete_schedule',  'gl_transaction',      'islocked',          'name_selected',
    'new_number',       'post_as_new',         'preview',           'print_and_post_as_new',
    'project_selected', 'rebuild_departments', 'rebuild_formnames', 'rebuild_vc',
    'repost',           'reprint',             'sales_invoice_',    'save_schedule',
    'schedule',         'select_name',         'select_project',    'spreadsheet',
    'vendor_invoice_',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
