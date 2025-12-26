use v5.40;
use strict;
use warnings;

use utf8;
use open ':std', ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Encode 'encode';

use SL::Form;

use Test::More tests => 13;

subtest 'Own country' => sub {

  my $form  = _empty_form();
  my @tests = ('' => 'CH', 'DE' => 'DE');
  plan tests => 1 + @tests * 3 / 2;

  for my ($test, $expected) (@tests) {
    $form->{companycountry} = $test;
    $form->qr_variables({});
    for (qw|qr qr2e qrasc|) {
      is $form->{"${_}_company_country"}, $expected, "Country '$test', variable $_";
    }
  }
};

subtest 'Own name' => sub {

  my $form  = _empty_form();
  my @tests = (
    'Schweizerische Bundesbahnen SBB' => 'Schweizerische Bundesbahnen SBB',
    'Schweizerische Südostbahn AG'    => 'Schweizerische Sudostbahn AG',
  );

  plan tests => 1 + @tests * 3 / 2;

  for my ($unicode, $ascii) (@tests) {
    $form->{company} = $unicode;
    $form->qr_variables({});
    _check_vars($form, 'company_name', $unicode, $ascii);
  }
};

subtest 'Own address, street name' => sub {

  my $form  = _empty_form();
  my @tests = (
    'Haupstrasse'          => 'Haupstrasse',
    'Zürcherstrasse'       => 'Zurcherstrasse',
    'Dunavirág út'         => 'Dunavirag ut',
    'Str. Barbu Văcărescu' => 'Str. Barbu Vacarescu',
  );

  plan tests => 1 + @tests * 3 / 2;

  for my ($unicode, $ascii) (@tests) {
    $form->{address} = "Some Addition\n$unicode 123b\nZipcode City";
    $form->qr_variables({});
    _check_vars($form, 'company_streetname', $unicode, $ascii);
  }
};

subtest 'Own address, building number' => sub {

  my $form  = _empty_form();
  my @tests = (
    '10'        => '10',
    '5'         => '5',
    '88'        => '88',
    '301 — 311' => '301 - 311',
  );
  plan tests => 1 + @tests * 3 / 2;

  for my ($unicode, $ascii) (@tests) {
    $form->{address} = "Some Addition\nSome Street $unicode\nZipcode City";
    $form->qr_variables({});
    _check_vars($form, 'company_buildingnumber', $unicode, $ascii);
  }
};

subtest 'Own address, zipcode' => sub {

  my $form  = _empty_form();
  my @tests = (
    '8866'   => '8866',
    '020276' => '020276',
  );
  plan tests => 1 + @tests * 3 / 2;

  for my ($unicode, $ascii) (@tests) {
    $form->{address} = "Some Street\n$unicode Some City";
    $form->qr_variables({});
    _check_vars($form, 'company_zipcode', $unicode, $ascii);
  }
};

subtest 'Own address, city' => sub {

  my $form  = _empty_form();
  my @tests = (
    'Ziegelbrücke' => 'Ziegelbrucke',
    'București'    => 'Bucuresti',
  );
  plan tests => 1 + @tests * 3 / 2;

  for my ($unicode, $ascii) (@tests) {
    $form->{address} = "Some Street\n12345 $unicode";
    $form->qr_variables({});
    _check_vars($form, 'company_city', $unicode, $ascii);
  }
};

subtest 'Customer country' => sub {

  my $form = _empty_form();
  my @tests = ('' => 'CH', 'DE' => 'DE');

  plan tests => 1 + @tests * 3 / 2;

  for my ($test, $expected) (@tests) {
    $form->{country} = $test;
    $form->qr_variables({});
    _check_vars($form, 'customer_country', $expected, $expected);
  }
};

subtest 'Customer name, company' => sub {

  my $form = _empty_form();
  $form->{typeofcontact} = 'company';
  my @tests = (
    'Poșta Română'                                           => 'Posta Romana',
    'Magyar Államvasutak Zártkörűen Működő Részvénytársaság' =>
      'Magyar Allamvasutak Zartkoruen Mukodo Reszvenytarsasag',
  );

  plan tests => 1 + @tests * 3 / 2;

  for my ($unicode, $ascii) (@tests) {
    $form->{name} = $unicode;
    $form->qr_variables({});
    _check_vars($form, 'customer_name', $unicode, $ascii);
  }
};

subtest 'Customer name, person' => sub {

  my $form = _empty_form();
  $form->{typeofcontact} = 'person';
  my @tests = (
    'Rolf', 'Stöckli' => 'Rolf Stockli',
  );

  plan tests => 1 + @tests;

  for my ($firstname, $lastname, $ascii) (@tests) {
    $form->{firstname} = $firstname;
    $form->{lastname} = $lastname;
    my $unicode = "$firstname $lastname";
    $form->qr_variables({});
    _check_vars($form, 'customer_name', $unicode, $ascii);
  }
};

subtest 'Customer address, street name' => sub {

  my $form = _empty_form();
  my @tests = (
    'Haupstrasse'          => 'Haupstrasse',
    'Zürcherstrasse'       => 'Zurcherstrasse',
    'Dunavirág út'         => 'Dunavirag ut',
    'Str. Barbu Văcărescu' => 'Str. Barbu Vacarescu',
  );

  plan tests => 1 + @tests * 3 / 2;

  for my ($unicode, $ascii) (@tests) {
    $form->{streetname} = $unicode;
    $form->qr_variables({});
    _check_vars($form, 'customer_streetname', $unicode, $ascii);
  }
};

subtest 'Customer address, building number' => sub {

  my $form = _empty_form();
  my @tests = (
    '10'        => '10',
    '5'         => '5',
    '88'        => '88',
    '301 — 311' => '301 - 311',
  );

  plan tests => 1 + @tests * 3 / 2;

  for my ($unicode, $ascii) (@tests) {
    $form->{buildingnumber} = $unicode;
    $form->qr_variables({});
    _check_vars($form, 'customer_buildingnumber', $unicode, $ascii);
  }
};

subtest 'Customer address, zipcode' => sub {

  my $form = _empty_form();
  my @tests = (
    '8866'   => '8866',
    '020276' => '020276',
  );

  plan tests => 1 + @tests * 3 / 2;

  for my ($unicode, $ascii) (@tests) {
    $form->{zipcode} = $unicode;
    $form->qr_variables({});
    _check_vars($form, 'customer_zipcode', $unicode, $ascii);
  }
};

subtest 'Customer address, city' => sub {

  my $form = _empty_form();
  my @tests = (
    'Ziegelbrücke' => 'Ziegelbrucke',
    'București'    => 'Bucuresti',
  );

  plan tests => 1 + @tests * 3 / 2;

  for my ($unicode, $ascii) (@tests) {
    $form->{city} = $unicode;
    $form->qr_variables({});
    _check_vars($form, 'customer_city', $unicode, $ascii);
  }
};

# internal functions

sub _check_vars ($form, $var, $unicode, $ascii) {
  $unicode =~ tr/–—/--/;
  my $utf8 = encode 'UTF-8', $unicode;

  is $form->{"qr_$var"},    $unicode, "$var $unicode";
  is $form->{"qr2e_$var"},  $utf8,    "$var $unicode, UTF-8 encoded";
  is $form->{"qrasc_$var"}, $ascii,   "$var $unicode, ASCII";
}

# internal subroutines

sub _empty_form {
  my $form = new_ok 'SL::Form';
  for (
    'address1',       'buildingnumber', 'businessnumber', 'city',   'company',
    'companycountry', 'country',        'firstname',      'format', 'invnumber',
    'lastname',       'name',           'streetname',     'terms',  'transdate',
    'typeofcontact',  'zipcode',
    )
  {
    $form->{$_} = '';
  }

  $form->{address}  = " \n ";
  $form->{rowcount} = 0;

  return $form;
}
