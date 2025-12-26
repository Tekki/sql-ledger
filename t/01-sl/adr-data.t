use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Mojo::Util 'trim';
use YAML::PP;
use YAML::PP::Common ':PRESERVE';

use Test::More;
use SL::ADR;
use SL::Form;

chdir "$FindBin::Bin/../..";

my $yp       = YAML::PP->new(preserve => PRESERVE_ORDER);
my $datafile = 't/testdata/adr-testdata.yml';
my $testdata;

if (-f $datafile) {
  plan tests => 4;
} else {
  plan skip_all => 'No test data.';
}

$testdata = $yp->load_file($datafile);

subtest 'Country code' => sub {
  my $codes = $testdata->{countrycodes};

  for my ($code, $name) (%$codes) {
    is SL::ADR::country_name($code), $name, "$code is $name";
  }

  is SL::ADR::country_name('XYZ'), '', 'Inexistant country';
  is SL::ADR::country_name(),      '', 'Empty country';
};

subtest 'Default country' => sub {
  is_deeply SL::ADR::default_country({}), {valid => 0}, 'Missing country code';
  is_deeply SL::ADR::default_country({companycountry => ''}),   {valid => 0}, 'Empty country code';
  is_deeply SL::ADR::default_country({companycountry => 'CH'}),
    {countrycode => 'CH', countryname => 'Schweiz / Suisse / Svizzera', valid => 1},
    'Country code CH';
};

subtest 'Local address' => sub {
  my $countries = $testdata->{localaddresses};
  my $first_address;

  for my ($country, $addresses) (%$countries) {
    note "Country: $country";

    for my $address (@$addresses) {
      $address->{pre} ||= '';
      $address->{expected} = trim $address->{expected};

      my %form_values = (companycountry => 'CH');
      $form_values{vc}                    = $address->{vc};
      $form_values{"$address->{pre}name"} = $address->{name};

      for (
        'typeofcontact', 'contact',    'firstname',      'lastname',
        'address1',      'streetname', 'buildingnumber', 'address2',
        'zipcode',       'city',       'state',          'country',
        )
      {
        $form_values{"$address->{pre}$_"} = $address->{$_};
      }

      is SL::ADR::local_address(\%form_values, undef, $address->{pre}), $address->{expected},
        $address->{expected} =~ s/\n/, /gr;

      $first_address ||= {values => \%form_values, expected => $address->{expected}};
    }
  }

  # address data as reference
  my %form_values = $first_address->{values}->%{'companycountry', 'vc'};
  is SL::ADR::local_address(\%form_values, $first_address->{values}), $first_address->{expected},
    $first_address->{expected};
};

subtest 'Swiss UID Register' => sub {
  my $uids = $testdata->{uids};
  my $form = SL::Form->new;

  for my ($uid, $expected) (%$uids) {
    $form->{taxnumber} = $uid;
    is_deeply SL::ADR::uid_register($form), $expected, "UID Register: $expected->{name}";
  }
};
