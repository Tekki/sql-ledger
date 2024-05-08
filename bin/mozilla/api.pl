#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2015-2017
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# JSON API
#
#======================================================================

use JSON::PP;
use SL::API;

sub add_payment {
  require SL::AA;
  require SL::IS;

  my $result       = 'error';
  my $invoice_form = Form->new;
  $invoice_form->{$_} = $form->{$_} for qw|id dcn invnumber waybill|;
  API->find_invoice(\%myconfig, $invoice_form);

  if ($invoice_form->{id}) {

    $invoice_form->{vc} = 'customer';
    AA->get_name(\%myconfig, $invoice_form);
    delete $invoice_form->{notes};
    IS->retrieve_invoice(\%myconfig, $invoice_form);

    my $payment_form = Form->new;
    $payment_form->{$_} = $invoice_form->{$_}
      for qw|ARAP defaultcurrency precision vc|;
    $payment_form->{currency} = $form->{currency}
      || $invoice_form->{defaultcurrency};
    $payment_form->{$_} = $form->{$_}
      for qw|amount datepaid exchangerate memo paymentmethod source|;
    $payment_form->{rowcount}                     = 1;
    $payment_form->{"$payment_form->{ARAP}_paid"} = $form->{paymentaccount};
    $payment_form->{id_1}                         = $invoice_form->{id};
    $payment_form->{paid_1}                       = $form->{amount};
    $payment_form->{checked_1}                    = 1;

    CP->post_payment(\%myconfig, $payment_form) and $result = 'success';
  }

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->encode({result => $result});
}

sub add_reference {

  API->find_invoice(\%myconfig, $form);
  API->add_reference(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->encode({result => $form->{result}});
}

sub customer_details {
  require SL::CT;

  $form->{db}   = 'customer';
  $form->{ARAP} = 'AR';
  CT->create_links(\%myconfig, $form);
  for (qw(discount cashdiscount)) { $form->{$_} *= 100 }
  $form->{contactid} = $form->{all_contact}->[0]->{id};
  if ($form->{all_contact}->[0]->{typeofcontact}) {
    $form->{typeofcontact} = $form->{all_contact}->[0]->{typeofcontact};
  }
  $form->{typeofcontact} ||= "company";
  $form->{$_} = $form->{all_contact}->[0]->{$_}
    for
    qw|email phone fax mobile salutation firstname lastname gender contacttitle occupation|;
  $form->{gender} ||= 'M';

  my %new_form = map { $_ => $form->{$_} } keys %$form;

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->encode(\%new_form);
}

sub get_token {
  require Digest::SHA;

  my $token = Digest::SHA::sha256_base64($myconfig{sessionkey});

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->encode({token => $token});
}

sub invoice_details {
  require SL::AA;
  require SL::IS;

  API->find_invoice(\%myconfig, $form);

  if ($form->{id}) {
    $form->{vc} = 'customer';
    $form->create_links('AR', \%myconfig, 'customer', 1);
    AA->get_name(\%myconfig, $form);
    delete $form->{notes};
    IS->retrieve_invoice(\%myconfig, $form);
    $form->all_references($form->dbconnect(\%myconfig));
  }
  my %new_form = map { $_ => $form->{$_} } grep !/^all_/, keys %$form;

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->encode(\%new_form);
}

sub list_accounts {

  API->list_accounts(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->encode({accounts => $form->{accounts}});
}

sub search_customer {
  require SL::CT;

  $form->{db} = 'customer';
  CT->search(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->encode({customers => $form->{CT}});
}

sub search_order {
  require SL::OE;

  $form->{open} //= 1;
  $form->{type} ||= 'sales_order';
  $form->{vc}   ||= 'customer';
  OE->transactions(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->encode({orders => $form->{OE}});
}

sub search_transaction {
  require SL::AA;

  $form->{open}    //= 1 unless $form->{outstanding};
  $form->{summary} //= 1;
  $form->{vc} = 'customer';
  AA->transactions(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->encode({transactions => $form->{transactions}});
}

sub upload_file {

  $form->{description} ||= $form->{filename} =~ s/(.+)\.[^.]+$/$1/r;

  my %result = (
    data   => {$form->%{'description', 'filename', 'tmpfile'}},
    result => 'success',
  );

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->encode(\%result);
}

1;

=encoding utf8

=head1 NAME

bin/mozilla/api.pl - JSON API

=head1 DESCRIPTION

L<bin::mozilla::api> contains functions for json api.

=head1 DEPENDENCIES

L<bin::mozilla::api>

=over

=item * uses
L<JSON::PP>,
L<SL::AA>,
L<SL::API>,
L<SL::CT>,
L<SL::IS>,
L<SL::OE>

=back

=head1 FUNCTIONS

L<bin::mozilla::api> implements the following functions:

=head2 add_payment

=head2 add_reference

=head2 customer_details

=head2 invoice_details

=head2 list_accounts

=head2 search_customer

=head2 search_order

=head2 search_transaction

=head2 upload_file

=cut
