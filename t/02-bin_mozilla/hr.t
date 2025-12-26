use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'hr.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'access_control',    'add',              'add_deduction',        'add_employee',
    'add_transaction',   'add_wage',         'continue',             'deduction_footer',
    'deduction_header',  'delete',           'delete_deduction',     'delete_employee',
    'delete_payroll',    'delete_wage',      'display_form',         'edit',
    'employee_footer',   'employee_header',  'list_employees',       'payroll_footer',
    'payroll_header',    'payroll_subtotal', 'payroll_transactions', 'post',
    'prepare_deduction', 'prepare_employee', 'prepare_payroll',      'prepare_wage',
    'preview',           'save',             'save_acs',             'save_as_new',
    'save_deduction',    'save_employee',    'save_memberfile',      'save_wage',
    'search',            'search_deduction', 'search_employee',      'search_payroll',
    'search_wage',       'update',           'update_deduction',     'update_employee',
    'update_payroll',    'wage_footer',      'wage_header',          'yes',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
