use v5.40;

use utf8;
use open ':std', ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Mojo::DOM;

use SL::Form;

use Test::More tests => 4;

chdir "$FindBin::Bin/../..";

subtest 'Header' => sub {

  my $form = new_ok 'SL::Form';
  $ENV{HTTP_USER_AGENT} = 'x';

  $form->{title} = 'Test Title';
  $form->{favicon} = 'favicon.ico';
  $form->{stylesheet} = 'sql-ledger.css';

  ok my $header = Mojo::DOM->new(_get_output($form, 'header')), 'Get header';

  ok $form->{header}, 'Header flag';

  is $header->at('title')->text, 'Test Title', 'Title';
  is $header->at('meta[http-equiv=Content-Type]')->attr('content'), 'text/html; charset=UTF-8',
    'Content';
  is $header->at('link[rel=icon]')->attr('href'), 'favicon.ico', 'Favicon';
  like $header->at('link[rel=stylesheet]')->attr('href'), qr~^css/sql-ledger.css~, 'Stylesheet';
};

subtest 'Info' => sub {

  my $form = new_ok 'SL::Form';
  $ENV{HTTP_USER_AGENT} = '';

  is _get_output($form, 'info', 'hello'), "hello\n", 'Text info';
  is _get_output($form, 'info', 'hello', 'type1'), "hello\n", 'Text info with type';

  $ENV{HTTP_USER_AGENT} = 'x';
  $form->{header} = 1;

  is _get_output($form, 'info', 'hello'), '<b>hello</b>', 'HTML info';
  is _get_output($form, 'info', 'hello', 'type1'), '<b class="type1">hello</b>',
    'HTML info with type';
};

subtest 'Buttons' => sub {
  my $form = new_ok 'SL::Form';
  $ENV{HTTP_USER_AGENT} = 'x';

  my %button = (
    _label_   => 'Label',
    'Value 1' => {ndx => 1, key => 'A', value => 'Value 1'},
    'Value 2' => {ndx => 2, key => 'B', value => 'Value 2'},
    'Value 3' => {ndx => 3, key => 'C', value => 'Value 3', class => 'someclass'},
  );

  my $expected = q|
<button class="submit noprint" type="submit" name="action" value="value_1" accesskey="A" title="Value 1 [A]">Value 1</button>
<button class="submit noprint" type="submit" name="action" value="value_2" accesskey="B" title="Value 2 [B]">Value 2</button>
<button class="someclass submit noprint" type="submit" name="action" value="value_3" accesskey="C" title="Value 3 [C]">Value 3</button>|;

  is _get_output($form, 'print_button', \%button), $expected;
};

subtest 'Button table' => sub {
  my $form = new_ok 'SL::Form';
  $ENV{HTTP_USER_AGENT} = 'x';

  my @buttons = (
    {
      'Value 1' => {ndx => 1, key => 'A', value => 'Value 1'},
    },
    {
      _label_   => 'Label 1',
      'Value 2' => {ndx => 2, key => 'B', value => 'Value 2'},
      'Value 3' => {ndx => 3, key => 'C', value => 'Value 3'},
    },
    {
      _label_ => 'Label 2',
    },
  );

  my $expected = q|
<table width="100%">
  <tr>
    <td colspan="2">
<button class="submit noprint" type="submit" name="action" value="value_1" accesskey="A" title="Value 1 [A]">Value 1</button>
    </td>
  </tr>
  <tr>
    <td width="1%">Label 1</td>
    <td>
<button class="submit noprint" type="submit" name="action" value="value_2" accesskey="B" title="Value 2 [B]">Value 2</button>
<button class="submit noprint" type="submit" name="action" value="value_3" accesskey="C" title="Value 3 [C]">Value 3</button>
    </td>
  </tr>
</table>|;

  is _get_output($form, 'print_button_table', \@buttons), $expected;
};

# internal subroutines

sub _get_output ($form, $fn, @params) {
  my $rv = '';

  {
    local *STDOUT;
    open STDOUT, '>>', \$rv;
    $form->$fn(@params);
  }

  return $rv;
}
