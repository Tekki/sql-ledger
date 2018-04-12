#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2018
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Material Requirements Planning
#
#======================================================================

package MRP;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use SL::IC;

sub part_requirements ($, $myconfig, $form, $dbh = undef) {
  return unless $form->{id};

  my $disconnect;

  # connect to database
  if (!$dbh) {
    $disconnect = 1;
    delete $myconfig->{dboptions};    ## debug
    $dbh = $form->dbconnect($myconfig);
  }


  my %defaults = $form->get_defaults($dbh, ['precision', 'company']);
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  IC->get_part($myconfig, $form, $dbh);

  my $where =
    qq|NOT o.closed AND NOT o.quotation AND oi.parts_id = $form->{id}|;

  my $query = qq|
    SELECT o.reqdate AS reqdate2, o.vendor_id, o.customer_id,
    oi.reqdate AS reqdate1,
    o.id, o.ordnumber, oi.qty - oi.ship AS qty,
    c.name AS customer_name,
    v.name AS vendor_name
    FROM oe o
    JOIN orderitems oi ON oi.trans_id = o.id
    LEFT JOIN customer c ON c.id = o.customer_id
    LEFT JOIN vendor v ON v.id = o.vendor_id
    WHERE $where|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my @requirements;
  while (my $ref = $sth->fetchrow_hashref) {
    $ref->{date} = $ref->{reqdate1} || $ref->{reqdate2} || '';
    delete $ref->{"reqdate$_"} for 1 .. 2;
    if ($ref->{customer_id}) {
      $ref->{order_type} = 'sales_order';
      $ref->{qty_out}    = delete $ref->{qty};
    } elsif ($ref->{vendor_id}) {
      $ref->{order_type} = 'purchase_order';
      $ref->{qty_in}     = delete $ref->{qty};
    }
    push @requirements, $ref;
  }

  @requirements = sort { $a->{date} cmp $b->{date} } @requirements;
  my %onhand = (date => $form->current_date({dateformat => 'yyyy-mm-dd'}));
  unshift @requirements, \%onhand;

  $form->{"total_$_"} = 0 for qw|in out|;
  for (@requirements) {
    $form->{total_in}  += $_->{qty_in}  || 0;
    $form->{total_out} += $_->{qty_out} || 0;
    $_->{total} = $form->{onhand} + $form->{total_in} - $form->{total_out};
  }
  $form->{total_qty} = $form->{total_in} - $form->{total_out};

  $form->{requirements} = \@requirements;

  $sth->finish;

  $dbh->disconnect if $disconnect;
}

sub warnings ($, $myconfig, $form, $dbh = undef) {

  my $disconnect;

  # connect to database
  if (!$dbh) {
    $disconnect = 1;
    delete $myconfig->{dboptions};    ## debug
    $dbh = $form->dbconnect($myconfig);
  }

  my %defaults = $form->get_defaults($dbh, ['precision', 'company']);
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $where =
    qq|NOT o.closed AND NOT o.quotation|;

  my $order = 'p.partnumber';

  my $query = qq|
    SELECT DISTINCT(oi.parts_id) AS id, p.partnumber, p.description, p.onhand,
      ( SELECT sum(oi2.qty - oi2.ship)
        FROM oe o2
        JOIN orderitems oi2 on oi2.trans_id = o2.id
        WHERE NOT o2.closed AND NOT o2.quotation
          AND oi2.parts_id = oi.parts_id AND o2.vendor_id <> 0
      ) AS incoming,
      ( SELECT sum(oi3.qty - oi3.ship)
        FROM oe o3
        JOIN orderitems oi3 on oi3.trans_id = o3.id
        WHERE NOT o3.closed AND NOT o3.quotation
          AND oi3.parts_id = oi.parts_id AND o3.customer_id <> 0
      ) AS outgoing
    FROM oe o
    JOIN orderitems oi ON oi.trans_id = o.id
    JOIN parts p ON p.id = oi.parts_id
    WHERE $where
    ORDER BY $order|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my @warnings;
  while (my $ref = $sth->fetchrow_hashref) {
    $ref->{$_} //= 0 for qw|onhand incoming outgoing|;
    $ref->{total} = $ref->{onhand} + $ref->{incoming} - $ref->{outgoing};
    push @warnings, $ref if $ref->{total} < 0;
  }
  $form->{warnings} = \@warnings;

  $dbh->disconnect if $disconnect;
}

1;

=encoding utf8

=head1 NAME

MRP - Material Requirements Planning

=head1 DESCRIPTION

L<SL::MRP> contains the backend for material requirements planning.

=head1 FUNCTIONS

L<SL::MRP> implements the following functions:

=head2 part_requirements

  MRP->part_requirements($myconfig, $form, $dbh);

Calculates the requirements for the part with ID C<< $form->{id} >>.

=head2 warnings

  MRP->warnings($myconfig, $form, $dbh);

Lists all the parts where the demand exceeds the supply.

=cut
