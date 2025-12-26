use v5.40;
no strict 'refs';

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use SL::Form;

use Test::More tests => 2;

my $script = 'rd.pl';
our $form = SL::Form->new;
$form->{path} = 't/dummy';

ok eval { require "bin/mozilla/$script"; 1; }, "Load $script";

subtest 'Subroutines' => sub {
  my @subs = (
    'add_document', 'add_file',          'attach',         'continue',
    'delete',       'delete_documents',  'delete_files',   'deselect_all',
    'detach',       'display_documents', 'do_attach',      'download_document',
    'edit',         'formnames',         'list_documents', 'list_images',
    'save',         'search_documents',  'select_all',     'spreadsheet',
    'upload',       'upload_file',       'upload_image',   'upload_imagefile',
  );

  for my $sub (@subs) {
    ok defined &{"main::$sub"}, "$sub available";
  }
};
