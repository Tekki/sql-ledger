#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2024
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Swiss Payment Standard
#
#======================================================================
package SL::SPS;

use strict;
use warnings;
use utf8;

use Time::Piece;

# functions

sub payment_add_metadata {
  my ($pmt) = @_;
  return $pmt
    unless $pmt->{name}
    && $pmt->{streetname}
    && $pmt->{buildingnumber}
    && $pmt->{zipcode}
    && $pmt->{city}
    && $pmt->{curr}
    && $pmt->{datepaid}
    && $pmt->{amount} > 0;

  if ($pmt->{curr} =~ /CHF|EUR/) {
    if ($pmt->{qriban} || $pmt->{iban} =~ /^(CH|LI)/) {
      if ($pmt->{qriban} && $pmt->{dcn}) {
        $pmt->{type} = 'D1q';
      } elsif ($pmt->{iban}) {
        $pmt->{type} = 'D1i';
      }
    }
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

my %XML_REPL
  = ('$' => 'USD', '£' => 'GBP', '¥' => 'JPY', '€' => 'EUR', '#' => '', '©' => '(C)', '®' => '(R)');
my %XML_ESC = (
  '&'  => '&amp;',
  '<'  => '&lt;',
  '>'  => '&gt;',
  '"'  => '&quot;',
  '«'  => '&quot;',
  '»'  => '&quot;',
  '\'' => '&#39;',
);

sub xml_escape {
  my ($str, $len) = (shift // '', shift);

  $str =~ s/([\$£¥€#©®])/$XML_REPL{$1}/ge;
  $str = substr $str, 0, $len if $len;
  $str =~ s/([&<>"«»'])/$XML_ESC{$1}/ge;

  return $str;
}

# constructor

sub new {
  my ($class, $form) = @_;

  my %self = (
    payment_count    => 0,
    payment_groups   => {},
    payment_sum      => 0,
    pmt_grp_num      => 0,
    pmt_num          => 0,
    software_version => $form->{version2},
  );

  $self{$_} = $form->{$_} for qw|accountbic accountiban company companycountry|;

  $self{created}    = localtime->datetime;
  $self{message_id} = sepa_escape "$self{created}_$$";

  return bless \%self, $class;
}

# methods

sub add_payment {
  my ($self, $pmt) = @_;

  if (payment_valid($pmt)) {
    push $self->{payment_groups}{"$pmt->{datepaid}--$pmt->{curr}"}->@*, $pmt;
    $self->{payment_count}++;
    $self->{payment_sum} += $pmt->{amount};
  }

  return $self;
}

sub to_xml {
  my ($self) = @_;

  my @payment_groups;

  for my $key (sort keys $self->{payment_groups}->%*) {
    my $group = $self->{payment_groups}{$key};
    my ($payment_date, @payments);
    my $payment_sum = 0;

    for my $payment (@$group) {

      $payment_date ||= $payment->{datepaid};
      $payment_sum += $payment->{amount};
      my $address   = $self->xml_address($payment);
      my $reference = $self->xml_payment_reference($payment);

      push @payments, $self->xml_payment($payment, $address, $reference);
    }

    push @payment_groups, $self->xml_payment_group($payment_date, $payment_sum, \@payments);
  }

  return sprintf q|<?xml version="1.0" encoding="UTF-8"?>
<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.09" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:iso:std:iso:20022:tech:xsd:pain.001.001.09 pain.001.001.09.ch.03.xsd">
  <CstmrCdtTrfInitn>%s%s
  </CstmrCdtTrfInitn>
</Document>|, $self->xml_header, join('', @payment_groups);
}

sub xml_address {
  my ($self, $pmt) = @_;

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

sub xml_header {
  my ($self) = @_;

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

sub xml_payment {
  my ($self, $pmt, $addr, $ref) = @_;

  my $iban = ($pmt->{type} eq 'D1q' ? $pmt->{qriban} : $pmt->{iban}) =~ s/ //gr;

  return sprintf q|
      <CdtTrfTxInf>
        <PmtId>
          <InstrId>tr-%1$s-%2$d</InstrId>
          <EndToEndId>tr-%1$s-%2$d</EndToEndId>
        </PmtId>
        <Amt>
          <InstdAmt Ccy="%3$s">%4$0.2f</InstdAmt>
        </Amt>
        <Cdtr>%5$s
        </Cdtr>
        <CdtrAcct>
          <Id>
            <IBAN>%6$s</IBAN>
          </Id>
        </CdtrAcct>
        <RmtInf>%7$s
        </RmtInf>
      </CdtTrfTxInf>|, $self->{message_id}, ++$self->{pmt_num}, $pmt->{curr}, $pmt->{amount},
    $addr, $iban, $ref;
}

sub xml_payment_group {
  my ($self, $pmtdt, $psum, $pmts) = @_;

  return sprintf q|
    <PmtInf>
      <PmtInfId>pmt-%d</PmtInfId>
      <PmtMtd>TRF</PmtMtd>
      <BtchBookg>false</BtchBookg>
      <NbOfTxs>%d</NbOfTxs>
      <CtrlSum>%.2f</CtrlSum>
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
    </PmtInf>|, ++$self->{pmt_grp_num}, scalar @$pmts, $psum, $pmtdt, xml_escape($self->{company}),
    $self->{accountiban} =~ s/ //gr, $self->{accountbic}, join('', @$pmts);
}

sub xml_payment_reference {
  my ($self, $pmt) = @_;
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
  } elsif ($pmt->{type} eq 'D1i') {
    $rv = sprintf q|
          <Ustrd>%s</Ustrd>|, xml_escape($pmt->{invnumber});
  }

  return $rv;
}


1;
