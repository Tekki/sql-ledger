#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2024
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Address Validation
#
#======================================================================
package SL::ADR;

use strict;
use warnings;
use utf8;

use constant {
  COUNTRY_CODES => {
    AD => 'Andorra',
    AE => 'Al-Imarat',
    AF => 'Afghanistan',
    AG => 'Antigua and Barbuda',
    AI => 'Anguilla',
    AL => 'Shqipëri',
    AM => 'Hayastan',
    AO => 'Angola',
    AQ => 'Antarctica',
    AR => 'Argentina',
    AS => 'American Samoa',
    AT => 'Österreich',
    AU => 'Australia',
    AW => 'Aruba',
    AX => 'Åland',
    AZ => 'Azərbaycan',
    BA => 'Bosna i Hercegovina',
    BB => 'Barbados',
    BD => 'Bangladesh',
    BE => 'België / Belgique / Belgien',
    BF => 'Burkina Faso',
    BG => 'Bulgaria',
    BH => 'Bahrain',
    BI => 'Burundi',
    BJ => 'Bénin',
    BL => 'Saint-Barthélemy',
    BM => 'Bermuda',
    BN => 'Brunei',
    BO => 'Bolivia',
    BQ => 'Bonaire',
    BR => 'Brasil',
    BS => 'Bahamas',
    BT => 'Bhutan',
    BV => 'Bouvet',
    BW => 'Botswana',
    BY => 'Belarus',
    BZ => 'Belize',
    CA => 'Canada',
    CC => 'Cocos Islands',
    CD => 'Congo-Kinshasa',
    CF => 'Central African Republic',
    CG => 'Congo-Brazzaville',
    CH => 'Schweiz / Suisse / Svizzera',
    CI => 'Côte d\'Ivoire',
    CK => 'Cook Islands',
    CL => 'Chile',
    CM => 'Cameroun',
    CN => 'China',
    CO => 'Colombia',
    CR => 'Costa Rica',
    CU => 'Cuba',
    CV => 'Cabo Verde',
    CW => 'Curaçao',
    CX => 'Christmas Island',
    CY => 'Kýpros',
    CZ => 'Česko',
    DE => 'Deutschland',
    DJ => 'Djibouti',
    DK => 'Danmark',
    DM => 'Dominica',
    DO => 'República Dominicana',
    DZ => 'Algérie',
    EC => 'Ecuador',
    EE => 'Eesti',
    EG => 'Misr',
    EH => 'Western Sahara',
    ER => 'Eritrea',
    ES => 'España',
    ET => 'Ethiopia',
    FI => 'Suomi',
    FJ => 'Fiji',
    FK => 'Falkland Islands',
    FM => 'Micronesia',
    FO => 'Føroyar',
    FR => 'France',
    GA => 'Gabon',
    GB => 'United Kingdom',
    GD => 'Grenada',
    GE => 'Sakartvelo',
    GF => 'Guyane',
    GG => 'Guernsey',
    GH => 'Ghana',
    GI => 'Gibraltar',
    GL => 'Kalaallit Nunaat',
    GM => 'Gambia',
    GN => 'Guinée',
    GP => 'Guadeloupe',
    GQ => 'Guinea Ecuatorial',
    GR => 'Ellás',
    GT => 'Guatemala',
    GU => 'Guam',
    GW => 'Guiné-Bissau',
    GY => 'Guyana',
    HK => 'Hong Kong',
    HM => 'Heard Island and McDonald Islands',
    HN => 'Honduras',
    HR => 'Hrvatska',
    HT => 'Haïti',
    HU => 'Magyarország',
    ID => 'Indonesia',
    IE => 'Éire',
    IL => 'Israel',
    IM => 'Isle of Man',
    IN => 'Bharat',
    IO => 'British Indian Ocean Territory',
    IQ => 'Iraq',
    IR => 'Iran',
    IS => 'Ísland',
    IT => 'Italia',
    JE => 'Jersey',
    JM => 'Jamaica',
    JO => 'Jordan',
    JP => 'Japan',
    KE => 'Kenya',
    KG => 'Kyrgyzstan',
    KH => 'Kampuchea',
    KI => 'Kiribati',
    KM => 'Comores',
    KN => 'Saint Kitts and Nevis',
    KP => 'North Korea',
    KR => 'South Korea',
    KW => 'Kuwait',
    KY => 'Cayman Islands',
    KZ => 'Kazakhstan',
    LA => 'Laos',
    LB => 'Lebanon',
    LC => 'Saint Lucia',
    LI => 'Liechtenstein',
    LK => 'Sri Lanka',
    LR => 'Liberia',
    LS => 'Lesotho',
    LT => 'Lietuva',
    LU => 'Luxembourg',
    LV => 'Latvija',
    LY => 'Libya',
    MA => 'Morocco',
    MC => 'Monaco',
    MD => 'Moldova',
    ME => 'Crna Gora',
    MF => 'Saint-Martin',
    MG => 'Madagasikara',
    MH => 'Marshall Islands',
    MK => 'Severna Makedonija',
    ML => 'Mali',
    MM => 'Myanma',
    MN => 'Mongolia',
    MO => 'Macau',
    MP => 'Northern Mariana Islands',
    MQ => 'Martinique',
    MR => 'Mauritanie',
    MS => 'Montserrat',
    MT => 'Malta',
    MU => 'Maurice',
    MV => 'Maldives',
    MW => 'Malawi',
    MX => 'México',
    MY => 'Malaysia',
    MZ => 'Moçambique',
    NA => 'Namibia',
    NC => 'Nouvelle-Calédonie',
    NE => 'Niger',
    NF => 'Norfolk Island',
    NG => 'Nigeria',
    NI => 'Nicaragua',
    NL => 'Nederland',
    NO => 'Norge',
    NP => 'Nepal',
    NR => 'Nauru',
    NU => 'Niue',
    NZ => 'New Zealand',
    OM => 'Oman',
    PA => 'Panamá',
    PE => 'Perú',
    PF => 'Polynésie Française',
    PG => 'Papua New Guinea',
    PH => 'Pilipinas',
    PK => 'Pakistan',
    PL => 'Polska',
    PM => 'Saint-Pierre-et-Miquelon',
    PN => 'Pitcairn Islands',
    PR => 'Puerto Rico',
    PS => 'Filastin',
    PT => 'Portugal',
    PW => 'Palau',
    PY => 'Paraguay',
    QA => 'Qatar',
    RE => 'La Réunion',
    RO => 'România',
    RS => 'Srbija',
    RU => 'Rossiâ',
    RW => 'Rwanda',
    SA => 'Al-Sa\'udiyya',
    SB => 'Solomon Islands',
    SC => 'Seychelles',
    SD => 'Sudan',
    SE => 'Sverige',
    SG => 'Singapore',
    SH => 'Saint Helena',
    SI => 'Slovenija',
    SJ => 'Svalbard og Jan Mayen',
    SK => 'Slovensko',
    SL => 'Sierra Leone',
    SM => 'San Marino',
    SN => 'Sénégal',
    SO => 'Soomaaliya',
    SR => 'Suriname',
    SS => 'South Sudan',
    ST => 'São Tomé e Príncipe',
    SV => 'El Salvador',
    SX => 'Sint Maarten',
    SY => 'Suriyah',
    SZ => 'Eswatini',
    TC => 'Turks and Caicos Islands',
    TD => 'Tchad',
    TF => 'Terres Australes Françaises',
    TG => 'Togo',
    TH => 'Prathet Thai',
    TJ => 'Tojikiston',
    TK => 'Tokelau',
    TL => 'Timor-Leste',
    TM => 'Türkmenistan',
    TN => 'Tunis',
    TO => 'Tonga',
    TR => 'Türki̇ye',
    TT => 'Trinidad and Tobago',
    TV => 'Tuvalu',
    TW => 'Taiwan',
    TZ => 'Tanzania',
    UA => 'Ukraina',
    UG => 'Uganda',
    UM => 'United States Minor Outlying Islands',
    US => 'United States of America',
    UY => 'Uruguay',
    UZ => 'O‘zbekiston',
    VA => 'Città del Vaticano',
    VC => 'Saint Vincent and the Grenadines',
    VE => 'Venezuela',
    VG => 'British Virgin Islands',
    VI => 'United States Virgin Islands',
    VN => 'Việt Nam',
    VU => 'Vanuatu',
    WF => 'Wallis-et-Futuna',
    WS => 'Samoa',
    YE => 'Al-Yaman',
    YT => 'Mayotte',
    ZA => 'South Africa',
    ZM => 'Zambia',
    ZW => 'Zimbabwe',
  },
  LOCAL_ADDRESS => {
    BG => ["%1\$s\n%2\$s %3\$s\n%4\$s\n%5\$s %6\$s\n%7\$s\n%10\$s\n%8\$s %9\$s\n%11\$s", [8,10]],
    CA => ["%2\$s %3\$s\n%1\$s\n%4\$s\n%6\$s %5\$s\n%7\$s\n%9\$s %10\$s %8\$s\n%11\$s", [0..10]],
    ES => ["%1\$s\n%2\$s %3\$s\n%4\$s\n%5\$s %6\$s\n%7\$s\n%8\$s %9\$s\n%10\$s\n%11\$s", [8..10]],
    FR => ["%1\$s\n%2\$s %3\$s\n%4\$s\n%6\$s %5\$s\n%7\$s\n%8\$s %9\$s %10\$s\n%11\$s", [4..10]],
    GB => ["%1\$s\n%2\$s %3\$s\n%4\$s\n%6\$s %5\$s\n%7\$s\n%9\$s\n%8\$s\n%11\$s", [8..10]],
    GR => ["%1\$s\n%2\$s %3\$s\n%4\$s\n%6\$s, %5\$s\n%7\$s\n%8\$s %9\$s %10\$s\n%11\$s", [0..10]],
    HU => ["%1\$s\n%3\$s %2\$s\n%4\$s\n%9\$s\n%5\$s %6\$s.\n%7\$s\n%8\$s\n%11\$s"],
    IE => ["%1\$s\n%2\$s %3\$s\n%4\$s\n%6\$s %5\$s\n%7\$s\n%9\$s\n%8\$s\n%11\$s", [3..10]],
    IT => ["%1\$s\n%2\$s %3\$s\n%4\$s\n%5\$s %6\$s\n%7\$s\n%8\$s %9\$s %10\$s\n%11\$s", [0..10]],
    NL => ["%2\$s %3\$s\n%1\$s\n%4\$s\n%7\$s\n%5\$s %6\$s\n%8\$s %9\$s\n%11\$s", [8..10]],
    PT => ["%1\$s\n%2\$s %3\$s\n%4\$s\n%5\$s %6\$s\n%7\$s\n%8\$s %9\$s %10\$s\n%11\$s", [0..10]],
    RO => ["%1\$s\n%2\$s %3\$s\n%4\$s\n%5\$s %6\$s\n%7\$s\n%8\$s %9\$s %10\$s\n%11\$s", [8..10]],
    TR => ["%2\$s %3\$s\n%1\$s\n%4\$s\n%5\$s. %6\$s\n%7\$s\n%8\$s %9\$s/%10\$s\n%11\$s", [8..10]],
    US => ["%2\$s %3\$s\n%1\$s\n%4\$s\n%6\$s %5\$s\n%7\$s\n%9\$s %10\$s %8\$s\n%11\$s", [0..10]],
    _  => ["%1\$s\n%2\$s %3\$s\n%4\$s\n%5\$s %6\$s\n%7\$s\n%8\$s %9\$s %10\$s\n%11\$s"],
  },
};

# functions

sub check_country {
  my ($form, $msg, $pre) = @_;
  $pre ||= '';
  my $countrycode = $form->{"${pre}country"};

  if ($countrycode && !country_name($countrycode)) {
    $form->error("$countrycode: $msg");
  }

  return {valid => 1};
}

sub country_name {
  return COUNTRY_CODES->{$_[0] // ''} || '';
}

sub default_country {
  my ($form) = @_;
  my %rv = (valid => 0);

  if (my $name = country_name($form->{companycountry})) {
    %rv = (
      countrycode => $form->{companycountry},
      countryname => $name,
      valid       => 1,
    );
  }

  return \%rv;
}

sub local_address {
  my ($form, $ref, $pre) = @_;
  my $in = $ref || $form;
  $pre ||= '';
  my ($rv, @values);

  if ($pre) {
    push @values, $in->{"${pre}name"} // '';
    push @values, '', $in->{"${pre}contact"} // '';
  } else {
    if ( ($in->{typeofcontact} || '') eq 'company') {
      push @values, $in->{name} // '';
    } else {
      push @values, '';
    }
    push @values, ($in->{firstname} // '') , ($in->{lastname} // '');
  }

  for (qw|address1 streetname buildingnumber address2 zipcode city state|) {
    push @values, $in->{"${pre}$_"} // '';
  }

  my $countrycode = $in->{"${pre}country"} || $form->{companycountry};
  push @values, $countrycode eq $form->{companycountry} ? '' : country_name($countrycode);

  my $tpl = LOCAL_ADDRESS->{$countrycode} || LOCAL_ADDRESS->{_};

  if ($tpl->[1]) {
    for ($tpl->[1]->@*) {
      $values[$_] = uc $values[$_];
    }
  }

  $rv = sprintf $tpl->[0], @values;
  $rv =~ s/^[ .,]+//mg;
  $rv =~ s/[ ]+$//mg;
  $rv =~ s/\n{2,}/\n/g;
  $rv =~ s/^\n//;
  $rv =~ s/\n$//;

  return $rv;
}

1;

=encoding utf8

=head1 NAME

SL::ADR - Address Validation

=head1 SYNOPSIS

    use SL::ADR;

    SL::ADR::check_country($form, $msg, $pre);
    my $name = SL::ADR::country_name($iso_code);
    my $code = SL::ADR::default_country($form);

=head1 DESCRIPTION

L<SL::ADR> provides functions to process and validate postal addresses.

=head1 FUNCTIONS

=head2 check_country

    my $msg = 'Illegal country code!';
    SL::ADR::check_country($form, $msg);
    SL::ADR::check_country($form, $msg, 'shipto');

=head2 country_name

    my $name = SL::ADR::country_name($iso_code);

=head2 default_country

    my $code = SL::ADR::default_country($form);

=cut
