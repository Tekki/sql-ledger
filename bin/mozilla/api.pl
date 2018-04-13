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

use SL::AA;
use SL::API;
use SL::CT;
use SL::IC;
use SL::IS;
use SL::OE;

sub add_payment {

  my $result       = 'error';
  my $invoice_form = Form->new;
  $invoice_form->{$_} = $form->{$_} for qw|id dcn invnumber|;
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
    $payment_form->{id_1}                         = $form->{id};
    $payment_form->{paid_1}                       = $form->{amount};
    $payment_form->{checked_1}                    = 1;

    CP->post_payment(\%myconfig, $payment_form) and $result = 'success';
  }

  $form->render_json({result => $result});
}

sub add_reference {

  API->find_invoice(\%myconfig, $form);
  API->add_reference(\%myconfig, $form);

  $form->render_json({result => $form->{result}});
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
    qw|email phone fax mobile salutation firstname lastname gender contacttitle occupation|;
  $form->{gender} ||= 'M';

  my %new_form = map { $_ => $form->{$_} } keys %$form;

  $form->render_json(\%new_form);
}

sub invoice_details {

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

  $form->render_json(\%new_form);
}

sub list_accounts {

  API->list_accounts(\%myconfig, $form);

  $form->render_json({accounts => $form->{accounts}});
}

sub search_customer {

  $form->{db} = 'customer';
  CT->search(\%myconfig, $form);

  $form->render_json({customers => $form->{CT}});
}

sub search_order {

  $form->{open} //= 1;
  $form->{type} ||= 'sales_order';
  $form->{vc}   ||= 'customer';
  OE->transactions(\%myconfig, $form);

  $form->render_json({orders => $form->{OE}});
}

sub search_part {

  IC->all_parts(\%myconfig, $form);

  $form->render_json({parts => $form->{parts} || []})
}

sub search_transaction {

  $form->{open}    //= 1 unless $form->{outstanding};
  $form->{summary} //= 1;
  $form->{vc} = 'customer';
  AA->transactions(\%myconfig, $form);

  $form->render_json({transactions => $form->{transactions}});
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
L<SL::AA>,
L<SL::API>,
L<SL::CT>,
L<SL::IC>,
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

=head2 search_part

=head2 search_transaction

=cut
