#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2018-2019
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#  Version: 0.1
#
#======================================================================
#
# backend for recently used objects
#
#======================================================================

package RU;

use constant {
  MAX_RECENT => 12,
  CODES      => {
    a1 => 'ar.pl?action=edit',
    a2 => 'is.pl?action=edit',
    c1 => 'ct.pl?db=customer&action=edit',
    d1 => 'ap.pl?action=edit',
    d2 => 'ir.pl?action=edit',
    e2 => 'ct.pl?db=vendor&action=edit',
    i1 => 'oe.pl?type=sales_order&action=edit',
    i2 => 'oe.pl?type=purchase_order&action=edit',
    k1 => 'oe.pl?type=sales_quotation&action=edit',
    k2 => 'oe.pl?type=request_quotation&action=edit',
    m1 => 'ic.pl?action=edit',
  },
  AP_TRANSACTION    => 'd1',
  AR_TRANSACTION    => 'a1',
  CUSTOMER          => 'c1',
  ITEM              => 'm1',
  PURCHASE_ORDER    => 'i2',
  REQUEST_QUOTATION => 'k2',
  SALES_INVOICE     => 'a2',
  SALES_ORDER       => 'i1',
  SALES_QUOTATION   => 'k1',
  VENDOR            => 'e2',
  VENDOR_INVOICE    => 'd2',
};

sub delete {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query;

  $query = 'DELETE FROM recentdescr WHERE object_id = ?';
  $dbh->do($query, undef, $form->{id}) or $form->dberror($query);

  $query = 'DELETE FROM recent WHERE object_id = ?';
  $dbh->do($query, undef, $form->{id}) or $form->dberror($query);

  $dbh->disconnect;
}

sub list {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my ($query, $ref, $sth);

  my $sortorder;
  if ($form->{sort}) {
    if (!$form->{direction} || $form->{sort} ne $form->{oldsort}) {
      $form->{direction} = 'ASC';
    }
    $sortorder = "$form->{sort} $form->{direction}, ";
    $form->{direction} = $form->{direction} eq 'ASC' ? 'DESC' : 'ASC';
    $form->{oldsort}   = $form->{sort};
  }
  $sortorder .= 'id DESC';

  $query = qq|SELECT r.*, rd.number, rd.description
            FROM recent r
            LEFT JOIN recentdescr rd ON (r.object_id = rd.object_id)
            ORDER BY $sortorder|;
  $sth = $dbh->prepare($query) or $form->dberror($query);
  $sth->execute or $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{$form->{all_recent}}, $ref;
  }

  $dbh->disconnect;
}

sub register {
  my ($self, $myconfig, $form) = @_;
  my $login = $form->{login};
  $login =~ s/\@.*//;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my ($query, @values, $rv);

  # object and employee id
  my $object_id = $form->{id} or return;

  $query = qq|SELECT id FROM employee WHERE login = '$login'|;
  my ($employee_id) = $dbh->selectrow_array($query);
  return unless $employee_id;

  $employee_id *= 1;

  # register object

  my $code = $self->_code($form);
  @values = ($employee_id, $object_id);

  $query = q|UPDATE recent SET id = nextval('recentid')
             WHERE (employee_id = ? AND object_id = ?)|;
  $rv = $dbh->do($query, undef, @values) or $form->dberror($query);

  if ($rv < 1) {
    $query
      = q|INSERT INTO recent (employee_id, object_id, code) VALUES (?, ?, ?)|;
    $dbh->do($query, undef, @values, $code) or $form->dberror($query);
  }

  # description

  @values = $self->_descr($form);

  $query
    = q|UPDATE recentdescr SET number = ?, description = ? WHERE object_id = ?|;
  $rv = $dbh->do($query, undef, @values, $object_id) or $form->dberror($query);

  if ($rv < 1) {
    $query = q|INSERT INTO recentdescr
               (object_id, number, description)
               VALUES (?, ?, ?)|;
    $dbh->do($query, undef, $object_id, @values) or $form->dberror($query);
  }

  # cleanup
  $query = q|DELETE FROM recent r
             WHERE r.employee_id = ? and r.code = ?
             AND ( SELECT count(*) FROM recent r2
                   WHERE r2.id > r.id AND r2.employee_id = r.employee_id AND r2.code = r.code
                 ) >= ?|;
  $dbh->do($query, undef, $employee_id, $code, MAX_RECENT)
    or $form->dberror($query);

  $query
    = q|DELETE FROM recentdescr WHERE object_id NOT IN (SELECT distinct(object_id) FROM recent)|;
  $dbh->do($query) or $form->dberror($query);

  $dbh->disconnect;
}

# internal methods

sub _code {
  my ($self, $form) = @_;
  $form->{script} =~ /(.+)\.pl/;
  my $fn = $self->can("_code_$1") or $form->error("$1: no recent code found");
  return $fn->($form);
}

sub _code_ap {
  return AP_TRANSACTION;
}

sub _code_ar {
  return AR_TRANSACTION;
}

sub _code_ct {
  return &{uc shift->{db}};
}

sub _code_ic {
  return ITEM;
}

sub _code_ir {
  return VENDOR_INVOICE;
}

sub _code_is {
  return SALES_INVOICE;
}

sub _code_oe {
  return &{uc shift->{type}};
}

sub _descr {
  my ($self, $form) = @_;
  $form->{script} =~ /(.+)\.pl/;
  my $fn = $self->can("_descr_$1") or return $form->{id}, '';
  my ($number, $description) = $fn->($form);
  $description .= ", $form->{description}"
    if $form->{description} && $form->{script} ne 'ic.pl';
  return $number, $description;
}

sub _descr_ap {
  my ($form) = @_;
  return $form->{invnumber}, "$form->{vendor}, $form->{transdate}";
}

sub _descr_ar {
  my ($form) = @_;
  return $form->{invnumber}, "$form->{customer}, $form->{transdate}";
}

sub _descr_ct {
  my ($form) = @_;
  return $form->{"$form->{db}number"},
    "$form->{name}, $form->{zipcode} $form->{city}";
}

sub _descr_ic {
  my ($form) = @_;
  return $form->{partnumber}, (split "\n", $form->{description})[0];
}

sub _descr_ir {
  return &_descr_ap;
}

sub _descr_is {
  return &_descr_ar;
}

sub _descr_oe {
  my ($form) = @_;
  my $number = $form->{type} =~ /quotation/ ? 'quonumber' : 'ordnumber';
  return $form->{$number}, qq|$form->{$form->{vc}}, $form->{transdate}|;
}

1;

=encoding utf8

=head1 NAME

RU - backend for recently used objects

=head1 DESCRIPTION

L<SL::RU> contains the backend for recently used objects.

=head1 FUNCTIONS

L<SL::RU> implements the following functions:

=head2 delete

  RU->delete($myconfig, $form);

=head2 list

  RU->list($myconfig, $form);

=head2 register

  RU->register($myconfig, $form);

=cut
