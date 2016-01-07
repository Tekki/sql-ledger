#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2015
#
#  Author: Tekki at Cubulon
#     Web: https://cubulon.ch
#
#  Version: 0.3
#
#======================================================================
#
# Cubulon connector
#
#======================================================================

use JSON::PP;
use SL::AA;
use SL::CT;
use SL::Cubulon;
use SL::IS;
use SL::OE;

sub add_reference {

  Cubulon->find_invoice(\%myconfig, $form);
  Cubulon->add_reference(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->utf8(0)->encode({result => $form->{result}});
}

sub customer_details {

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
    qw|email phone fax mobile salutation firstname lastname gender contacttitle occupation|
    ;
  $form->{gender} ||= 'M';

  my %new_form = map { $_ => $form->{$_} } keys %$form;

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->utf8(0)->encode(\%new_form);
}

sub invoice_details {

  Cubulon->find_invoice(\%myconfig, $form);

  if ($form->{id}) {
    $form->{vc} = 'customer';
    AA->get_name(\%myconfig, $form);
    delete $form->{notes};
    IS->retrieve_invoice(\%myconfig, $form);
    $form->get_reference($form->dbconnect(\%myconfig));
  }
  my %new_form = map { $_ => $form->{$_} } keys %$form;

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->utf8(0)->encode(\%new_form);
}

sub list_accounts {

  Cubulon->list_accounts(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->utf8(0)->encode({accounts => $form->{accounts}});
}

sub search_customer {

  $form->{db} = 'customer';
  CT->search(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->utf8(0)->encode({customers => $form->{CT}});
}

sub search_order {

  $form->{open} //= 1;
  $form->{type} ||= 'sales_order';
  $form->{vc} ||= 'customer';
  OE->transactions(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->utf8(0)->encode({orders => $form->{OE}});
}

sub search_transaction {

  $form->{open} //= 1;
  $form->{summary} //= 1;
  $form->{vc} = 'customer';
  AA->transactions(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->utf8(0)->encode({transactions => $form->{transactions}});
}

1;
