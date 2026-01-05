#======================================================================
# SQL-Ledger ERP
#
# © 2015-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#  Version: 0.4
#
#======================================================================
#
# JSON API
#
#======================================================================
use v5.40;

package SL::API;

sub add_reference ($, $myconfig, $form) {

  if ($form->{id} and $form->{referencecode} and $form->{referencedescription}) {
    my $dbh = $form->dbconnect($myconfig);
    my $query
      = q|INSERT INTO reference (code, trans_id, description, formname) VALUES (?,?,?,?)|;
    my $sth = $dbh->prepare($query) or $form->dberror($query);
    $sth->execute($form->{referencecode}, $form->{id},
      $form->{referencedescription}, 'ar_invoice')
      or $form->dberror($query);

    $form->{result} = 'success';
  } else {
    $form->{result} = 'error';
  }
}

sub find_invoice ($, $myconfig, $form) {

  my $dbh   = $form->dbconnect($myconfig);
  my $where = '1 = 0';

  if ($form->{id}) {
    $where = 'id = ' . $dbh->quote($form->{id});
    delete $form->{id};
  } elsif ($form->{dcn}) {
    $where = 'dcn = ' . $dbh->quote($form->{dcn});
  } elsif ($form->{invnumber}) {
    $where = 'invnumber = ' . $dbh->quote($form->{invnumber});
  } elsif ($form->{waybill}) {
    $where = 'waybill = ' . $dbh->quote($form->{waybill});
  }

  my $query = qq|SELECT id, customer_id FROM ar WHERE $where ORDER BY id DESC LIMIT 1|;

  if (my $ref = $dbh->selectrow_arrayref($query)) {
    ($form->{id}, $form->{customer_id}) = @$ref;
  }

}

sub list_accounts ($, $myconfig, $form) {

  my $dbh = $form->dbconnect($myconfig);

  my $query = q|SELECT * FROM chart WHERE charttype='A' ORDER BY accno|;
  my $sth = $dbh->prepare($query) or $form->dberror($query);
  $sth->execute;

  my $ref;
  while ($ref = $sth->fetchrow_hashref) {
    push @{$form->{accounts}}, $ref;
  }
}

1;

=encoding utf8

=head1 NAME

SL::API - JSON API

=head1 DESCRIPTION

L<SL::API> contains the JSON API.

=head1 FUNCTIONS

L<SL::API> implements the following functions:

=head2 add_reference

  SL::API->add_reference($myconfig, $form);

=head2 find_invoice

  SL::API->find_invoice($myconfig, $form);

=head2 list_accounts

  SL::API->list_accounts($myconfig, $form);

=cut
