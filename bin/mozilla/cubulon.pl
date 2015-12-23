#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2015
#
#  Author: Tekki at Cubulon
#     Web: https://cubulon.ch
#
#  Version: 0.1
#
#======================================================================
#
# Cubulon connector
#
#======================================================================

use JSON::PP;
use SL::AA;
use SL::Cubulon;
use SL::IS;

1;

sub add_reference {

  Cubulon->find_invoice(\%myconfig, $form);
  Cubulon->add_reference(\%myconfig, $form);

  print qq|Content-Type: application/json; charset=$form->{charset}

| . JSON::PP->new->utf8(0)->encode({result => $form->{result}});
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
