use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'jc.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'add',                'add_stores_card',
    'add_time_card',      'check_in',
    'check_out',          'continue',
    'delete',             'delete_storescard',
    'delete_timecard',    'display_form',
    'edit',               'form_footer',
    'form_header',        'islocked',
    'item_selected',      'jcitems_links',
    'list_cards',         'new_item',
    'prepare_storescard', 'prepare_timecard',
    'preview',            'print',
    'print_and_save',     'print_and_save_as_new',
    'print_form',         'print_options',
    'resave',             'save',
    'save_as_new',        'search',
    'select_item',        'storescard_footer',
    'storescard_header',  'timecard_footer',
    'timecard_header',    'update',
    'yes',                'yes_delete_storescard',
    'yes_delete_timecard',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
