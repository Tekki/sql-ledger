use v5.40;

use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use lib "$FindBin::Bin/../..";
use Mojo::File 'path';
use YAML::PP;
use YAML::PP::Common ':PRESERVE';

use Test::More;
use SL::SPS;

chdir "$FindBin::Bin/../..";

my $yp       = YAML::PP->new(preserve => PRESERVE_ORDER);
my $datafile = 't/testdata/sps-testdata.yml';
my $testdata;

if (-f $datafile) {
  plan tests => 5;
} else {
  plan skip_all => 'No test data.';
}

$testdata = $yp->load_file($datafile);

my $payment_date     = $testdata->{payment_date};
my $form             = $testdata->{form};
my @invalid_payments = $testdata->{invalid_payments}->@*;

my @valid_payments;
for (qw|d1q d1i s x1 x2|) {
  push @valid_payments, $testdata->{"valid_payments_$_"}->@*;
}

for my $pmt (@valid_payments) {
  for (grep /^_/, keys %$pmt) {
    $pmt->{$_} =~ s/\s+$//;
  }
}

my %expected;
for (qw|header payment_group|) {
  $expected{$_} = $testdata->{"expected_$_"} =~ s/\s+$//r;
}

my $sps = new_ok 'SL::SPS', [$form];

subtest 'Initial content' => sub {
  for (qw|company companycountry|) {
    is $sps->{$_}, $form->{$_}, $_;
  }

  is $sps->{software_version}, $form->{version}, 'Software version';
  like $sps->{created},    qr/^\d{4}-\d{2}-\d{2}T/, 'Created';
  like $sps->{message_id}, qr/$sps->{created}\d+/,  'Message ID';
  is $sps->{payment_count}, 0, 'Payment count';
  is $sps->{payment_sum},   0, 'Control sum';
  is $sps->{pmt_num},       0, 'Payment number';
  is $sps->{pmt_grp_num},   0, 'Payment group number';
};

subtest 'Validate payments' => sub {

  for (@valid_payments) {
    ok SL::SPS::payment_valid($_), "$_->{name}: valid";
    is SL::SPS::payment_type($_), $_->{_payment_type}, "$_->{name}: type";
  }

  for (@invalid_payments) {
    ok !SL::SPS::payment_valid($_), "$_->{name}: invalid";
    ok !SL::SPS::payment_type($_),  "$_->{name}: no type";
  }

};

subtest 'Add payments' => sub {
  my $group_key;
  for (@valid_payments, @invalid_payments) {
    is $sps->add_payment($_), $sps, "Add $_->{name}";
    $group_key ||= "$_->{datepaid}--$_->{type}--$_->{curr}";
  }

  is $sps->{payment_count}, scalar @valid_payments, 'Counter';
  is $sps->{payment_sum},   1000 * @valid_payments, 'Control sum';
  ok $sps->{payment_groups}{$group_key}, 'Payment group exists';
};

subtest 'XML elements' => sub {
  $sps                  = SL::SPS->new($form);
  $sps->{created}       = '2025-01-31T01:02:03';
  $sps->{message_id}    = '2025-01-31T01:02:0312345';
  $sps->{payment_count} = 5;
  $sps->{payment_sum}   = 123;

  # header
  is $sps->xml_header, $expected{header}, 'Header';

  # address
  subtest 'address' => sub {
    for (@valid_payments) {
      if (exists $_->{_address}) {
        my $expected = $_->{_address};
        is $sps->xml_address($_), $expected, "Address $_->{name}";
      }
    }
  };

  # payment bank
  subtest 'bank' => sub {
    for (@valid_payments) {
      if (exists $_->{_payment_bank}) {
        my $expected = $_->{_payment_bank};
        is $sps->xml_payment_bank($_), $expected, "Bank $_->{name}";
      }
    }
  };
  
  # payment info
  subtest 'info' => sub {
    for (@valid_payments) {
      if (exists $_->{_payment_info}) {
        my $expected = $_->{_payment_info};
        is $sps->xml_payment_info($_), $expected, "Info $_->{name}";
      }
    }
  };
  
  # payment reference
  subtest 'reference' => sub {
    for (@valid_payments) {
      if (exists $_->{_payment_reference}) {
        my $expected = $_->{_payment_reference};
        is $sps->xml_payment_reference($_), $expected, "Reference $_->{name}";
      }
    }
  };
  
  # payment
  subtest 'payment' => sub {
    for (@valid_payments) {
      if (my $expected = $_->{_payment}) {
        $sps->{pmt_num} = 0;
        is $sps->xml_payment($_, 'Address', 'Bank', 'Reference'), $expected, "Payment $_->{name}";
      }
    }
  };

  # payment group
  is $sps->xml_payment_group($payment_date, 321, 'Info', ["\nPayment 1", "\nPayment 2"]),
    $expected{payment_group} , 'Payment group';
};
