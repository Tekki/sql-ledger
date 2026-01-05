#======================================================================
# SQL-Ledger ERP
#
# © 2024-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# Swiss Payment Standard
#
#======================================================================
use v5.40;

package SL::SPS;

use utf8;

use Time::Piece;

# functions

sub payment_add_metadata ($pmt) {
  return $pmt
    unless $pmt->{name}
    && $pmt->{streetname}
    && $pmt->{buildingnumber}
    && $pmt->{zipcode}
    && $pmt->{city}
    && $pmt->{curr}
    && $pmt->{datepaid}
    && $pmt->{amount} > 0
    && ($pmt->{iban} || $pmt->{qriban});

  if (($pmt->{qriban} || $pmt->{iban}) =~ /^(CH|LI)/) {
    if ($pmt->{curr} =~ /CHF|EUR/) {
      if ($pmt->{qriban} && $pmt->{dcn}) {
        $pmt->{type} = 'D1q';
      } elsif ($pmt->{iban}) {
        $pmt->{type} = 'D1i';
      }
    } elsif ($pmt->{iban}) {
      $pmt->{type} = 'X1';
    }
  } elsif ($pmt->{iban} && $pmt->{curr} eq 'EUR') {
    $pmt->{type} = 'S';
  } elsif ($pmt->{iban} && $pmt->{bic}) {
    $pmt->{type} = 'X2';
  }

  $pmt->{valid} = !!$pmt->{type};

  return $pmt;
}

sub payment_type {
  return payment_add_metadata($_[0])->{type};
}

sub payment_valid {
  return payment_add_metadata($_[0])->{valid};
}

sub sepa_escape {
  return $_[0] =~ tr/A-Za-z0-9()+,'.\-:?//cdr;
}

# xml_escape: parts copied from Mojo::Util

my %XML_ESC = (
  '&'  => '&amp;',
  '<'  => '&lt;',
  '>'  => '&gt;',
  '"'  => '&quot;',
  '«'  => '&quot;',
  '»'  => '&quot;',
  '\'' => '&#39;',
);
my %XML_SUBST
  = ('$' => 'USD', '£' => 'GBP', '¥' => 'JPY', '€' => 'EUR', '#' => '', '©' => '(C)', '®' => '(R)');

sub xml_escape {
  my ($str, $len) = (shift // '', shift);

  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  $str =~ s/([\$£¥€#©®])/$XML_SUBST{$1}/ge;
  $str = substr $str, 0, $len if $len;
  $str =~ s/([&<>"«»'])/$XML_ESC{$1}/ge;

  return $str;
}

# constructor

sub new ($class, $form) {

  my %self = (
    payment_count    => 0,
    payment_groups   => {},
    payment_sum      => 0,
    pmt_grp_num      => 0,
    pmt_num          => 0,
    software_version => $form->{version},
  );

  $self{$_} = $form->{$_} for qw|accountbic accountiban company companycountry|;

  $self{created}    = localtime->datetime;
  $self{message_id} = sepa_escape "$self{created}_$$";

  return bless \%self, $class;
}

# methods

sub add_payment ($self, $pmt) {

  if (payment_valid($pmt)) {
    push $self->{payment_groups}{"$pmt->{datepaid}--$pmt->{type}--$pmt->{curr}"}->@*, $pmt;
    $self->{payment_count}++;
    $self->{payment_sum} += $pmt->{amount};
  }

  return $self;
}

sub to_xml ($self) {

  my @payment_groups;

  for my $key (sort keys $self->{payment_groups}->%*) {
    my $group = $self->{payment_groups}{$key};
    my ($payment_date, $payment_info, @payments);
    my $payment_sum = 0;

    for my $payment (@$group) {

      $payment_info //= $self->xml_payment_info($payment);
      $payment_date ||= $payment->{datepaid};
      $payment_sum += $payment->{amount};
      my $address   = $self->xml_address($payment);
      my $bank      = $self->xml_payment_bank($payment);
      my $info      = $self->xml_payment_info($payment);
      my $reference = $self->xml_payment_reference($payment);

      push @payments, $self->xml_payment($payment, $address, $bank, $reference);
    }

    push @payment_groups,
      $self->xml_payment_group($payment_date, $payment_sum, $payment_info, \@payments);
  }

  return sprintf q|<?xml version="1.0" encoding="UTF-8"?>
<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.09" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:iso:std:iso:20022:tech:xsd:pain.001.001.09 pain.001.001.09.ch.03.xsd">
  <CstmrCdtTrfInitn>%s%s
  </CstmrCdtTrfInitn>
</Document>|, $self->xml_header, join('', @payment_groups);
}

sub xml_address ($self, $pmt) {

  return sprintf q|
          <Nm>%s</Nm>
          <PstlAdr>
            <StrtNm>%s</StrtNm>
            <BldgNb>%s</BldgNb>
            <PstCd>%s</PstCd>
            <TwnNm>%s</TwnNm>
            <Ctry>%s</Ctry>
          </PstlAdr>|,
    xml_escape($pmt->{name}),           xml_escape($pmt->{streetname}),
    xml_escape($pmt->{buildingnumber}), xml_escape($pmt->{zipcode}),
    xml_escape($pmt->{city}),           $pmt->{country} || $self->{companycountry};
}

sub xml_header ($self) {

  return sprintf q|
    <GrpHdr>
      <MsgId>%s</MsgId>
      <CreDtTm>%s</CreDtTm>
      <NbOfTxs>%d</NbOfTxs>
      <CtrlSum>%.2f</CtrlSum>
      <InitgPty>
        <Nm>%s</Nm>
        <CtctDtls>
          <Othr>
            <ChanlTp>NAME</ChanlTp>
            <Id>SQL-Ledger</Id>
          </Othr>
          <Othr>
            <ChanlTp>VRSN</ChanlTp>
            <Id>%s</Id>
          </Othr>
          <Othr>
            <ChanlTp>PRVD</ChanlTp>
            <Id>Tekki</Id>
          </Othr>
          <Othr>
            <ChanlTp>SPSV</ChanlTp>
            <Id>2.0</Id>
          </Othr>
        </CtctDtls>
      </InitgPty>
    </GrpHdr>|, $self->{message_id}, $self->{created}, $self->{payment_count},
    $self->{payment_sum}, xml_escape($self->{company}), $self->{software_version};
}

sub xml_payment ($self, $pmt, $addr, $bank, $ref) {

  my $iban = ($pmt->{type} eq 'D1q' ? $pmt->{qriban} : $pmt->{iban}) =~ s/ //gr;

  return sprintf q|
      <CdtTrfTxInf>
        <PmtId>
          <InstrId>tr-%1$s-%2$d</InstrId>
          <EndToEndId>tr-%1$s-%2$d</EndToEndId>
        </PmtId>
        <Amt>
          <InstdAmt Ccy="%3$s">%4$0.2f</InstdAmt>
        </Amt>%6$s
        <Cdtr>%5$s
        </Cdtr>
        <CdtrAcct>
          <Id>
            <IBAN>%7$s</IBAN>
          </Id>
        </CdtrAcct>
        <RmtInf>%8$s
        </RmtInf>
      </CdtTrfTxInf>|, $self->{message_id}, ++$self->{pmt_num}, $pmt->{curr}, $pmt->{amount},
    $addr, $bank, $iban, $ref;
}

sub xml_payment_bank ($self, $pmt) {
  my $rv = '';

  if ($pmt->{type} eq 'X2') {
    $rv = sprintf q|
        <CdtrAgt>
          <FinInstnId>
            <BICFI>%s</BICFI>
          </FinInstnId>
        </CdtrAgt>|, $pmt->{bic};
  }

  return $rv;
}

sub xml_payment_group ($self, $pmtdt, $psum, $info, $pmts) {

  return sprintf q|
    <PmtInf>
      <PmtInfId>pmt-%d</PmtInfId>
      <PmtMtd>TRF</PmtMtd>
      <BtchBookg>false</BtchBookg>
      <NbOfTxs>%d</NbOfTxs>
      <CtrlSum>%.2f</CtrlSum>%s
      <ReqdExctnDt>
        <Dt>%s</Dt>
      </ReqdExctnDt>
      <Dbtr>
        <Nm>%s</Nm>
      </Dbtr>
      <DbtrAcct>
        <Id>
          <IBAN>%s</IBAN>
        </Id>
      </DbtrAcct>
      <DbtrAgt>
        <FinInstnId>
          <BICFI>%s</BICFI>
        </FinInstnId>
      </DbtrAgt>%s
    </PmtInf>|, ++$self->{pmt_grp_num}, scalar @$pmts, $psum, $info, $pmtdt,
    xml_escape($self->{company}), $self->{accountiban} =~ s/ //gr, $self->{accountbic},
    join('', @$pmts);
}

sub xml_payment_info ($self, $pmt) {
  my $rv = '';

  if ($pmt->{type} eq 'S') {
    $rv = q|
      <PmtTpInf>
        <SvcLvl>
          <Cd>SEPA</Cd>
        </SvcLvl>
      </PmtTpInf>|;
  }

  return $rv;
}

sub xml_payment_reference ($self, $pmt) {
  my $rv;

  if ($pmt->{type} eq 'D1q') {
    $rv = sprintf q|
          <Strd>
            <CdtrRefInf>
              <Tp>
                <CdOrPrtry>
                  <Prtry>QRR</Prtry>
                </CdOrPrtry>
              </Tp>
              <Ref>%s</Ref>
            </CdtrRefInf>
            <AddtlRmtInf>%s</AddtlRmtInf>
          </Strd>|, $pmt->{dcn} =~ s/ //gr, xml_escape($pmt->{invnumber});
  } else {
    $rv = sprintf q|
          <Ustrd>%s</Ustrd>|, xml_escape("$pmt->{invnumber} $pmt->{memo}");
  }

  return $rv;
}


1;
