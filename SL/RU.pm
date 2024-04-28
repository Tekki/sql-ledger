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
    a1 => {
      object => 'ar.pl?action=edit',
      report => 'ar.pl?action=search&nextsub=transactions'
    },
    a2 => {
      object => 'is.pl?action=edit',
      report => 'ar.pl?action=search&nextsub=transactions'
    },
    c1 => {
      object => 'ct.pl?db=customer&action=edit',
      report => 'ct.pl?db=customer&action=search'
    },
    d1 => {
      object => 'ap.pl?action=edit',
      report => 'ap.pl?action=search&nextsub=transactions'
    },
    d2 => {
      object => 'ir.pl?action=edit',
      report => 'ap.pl?action=search&nextsub=transactions'
    },
    e2 => {
      object => 'ct.pl?db=vendor&action=edit',
      report => 'ct.pl?db=vendor&action=search'
    },
    i1 => {
      object => 'oe.pl?type=sales_order&action=edit',
      report => 'oe.pl?type=sales_order&action=search'
    },
    i2 => {
      object => 'oe.pl?type=purchase_order&action=edit',
      report => 'oe.pl?type=purchase_order&action=search'
    },
    j1 => {
      object => 'gl.pl?action=edit',
      report => 'gl.pl?action=search',
    },
    k1 => {
      object => 'oe.pl?type=sales_quotation&action=edit',
      report => 'oe.pl?type=sales_quotation&action=search'
    },
    k2 => {
      object => 'oe.pl?type=request_quotation&action=edit',
      report => 'oe.pl?type=request_quotation&action=search'
    },
    m1 => {
      object => 'ic.pl?action=edit',
      report => 'ic.pl?action=search&searchitems=all'
    },
    n1 => {
      object => 'pe.pl?type=project&action=edit',
      report => 'pe.pl?type=project&action=search',
    },
    n2 => {
      object => 'jc.pl?type=timecard&project=project&action=edit',
      report => 'jc.pl?type=timecard&project=project&action=search',
    },
  },
  AP_TRANSACTION    => 'd1',
  AR_TRANSACTION    => 'a1',
  CUSTOMER          => 'c1',
  GL_TRANSACTION    => 'j1',
  ITEM              => 'm1',
  PROJECT           => 'n1',
  PURCHASE_ORDER    => 'i2',
  REQUEST_QUOTATION => 'k2',
  SALES_INVOICE     => 'a2',
  SALES_ORDER       => 'i1',
  SALES_QUOTATION   => 'k1',
  TIMECARD          => 'n2',
  VENDOR            => 'e2',
  VENDOR_INVOICE    => 'd2',
};

sub delete {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query;

  my $object_id = &_object_id($form);

  $query = 'DELETE FROM recentdescr WHERE object_id = ?';
  $dbh->do($query, undef, $object_id) or $form->dberror($query);

  $query = 'DELETE FROM recent WHERE object_id = ?';
  $dbh->do($query, undef, $object_id) or $form->dberror($query);

  $dbh->disconnect;
}

sub list {
  my ($self, $myconfig, $form) = @_;
  $form->{all_recent} = [];

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my ($query, $ref, $sth);

  # employee id
  my $employee_id = &_employee_id($form, $dbh) or return;

  # list recent objects

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
            WHERE r.employee_id = ?
            ORDER BY $sortorder|;
  $sth = $dbh->prepare($query) or $form->dberror($query);
  $sth->execute($employee_id) or $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{object_id} = abs $ref->{object_id};
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
  my $object_id   = &_object_id($form) or return;
  my $employee_id = &_employee_id($form, $dbh) or return;

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

  @values = $self->_descr($form, $code);

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
             WHERE r.employee_id = ? AND r.code = ?
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

sub unregister {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my ($query, $ref, $sth);

  # employee id
  my $employee_id = &_employee_id($form, $dbh) or return;

  $query = q|DELETE FROM recent
            WHERE employee_id = ? AND code = ?|;
  $dbh->do($query, undef, $employee_id, $form->{code})
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
  return $self->can("_code_$1")->($form);
}

sub _code_ {
  my ($form) = @_;
  return SALES_ORDER   if $form->{type} eq 'sales_order';
  return SALES_INVOICE if $form->{type} eq 'invoice';
  $form->error('type not identified');
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

sub _code_gl {
  return GL_TRANSACTION;
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

sub _code_jc {
  return TIMECARD;
}

sub _code_oe {
  my ($form) = @_;
  my $type = $form->{type};
  $type =~ s/consolidate_//;
  return &{uc $type};
}

sub _code_pe {
  PROJECT;
}

sub _descr {
  my ($self, $form, $code) = @_;

  my %descr = (
    &AP_TRANSACTION    => \&_descr_ap,
    &AR_TRANSACTION    => \&_descr_ar,
    &CUSTOMER          => \&_descr_ct,
    &GL_TRANSACTION    => \&_descr_gl,
    &ITEM              => \&_descr_ic,
    &PROJECT           => \&_descr_pe,
    &PURCHASE_ORDER    => \&_descr_oe2,
    &REQUEST_QUOTATION => \&_descr_oe1,
    &SALES_INVOICE     => \&_descr_ar,
    &SALES_ORDER       => \&_descr_oe2,
    &SALES_QUOTATION   => \&_descr_oe1,
    &TIMECARD          => \&_descr_jc,
    &VENDOR            => \&_descr_ct,
    &VENDOR_INVOICE    => \&_descr_ap,
  );
  my $fn = $descr{$code} or return $form->{id}, '';

  my ($number, $description) = $fn->($form);
  $description =~ s/--\d+//;
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

sub _descr_gl {
  my ($form) = @_;
  return $form->{reference}, $form->{transdate};
}

sub _descr_ic {
  my ($form) = @_;
  return $form->{partnumber}, (split "\n", $form->{description})[0] // '';
}

sub _descr_jc {
  my ($form) = @_;
  return $form->{id},
    ($form->{projectdescription} || $form->{projectnumber})
    . qq|, $form->{transdate} $form->{inhour}:$form->{inmin}-$form->{outhour}:$form->{outmin}, $form->{qty}|;
}

sub _descr_oe1 {
  my ($form) = @_;
  return $form->{quonumber}, qq|$form->{$form->{vc}}, $form->{transdate}|;
}

sub _descr_oe2 {
  my ($form) = @_;
  return $form->{ordnumber}, qq|$form->{$form->{vc}}, $form->{transdate}|;
}

sub _descr_pe {
  my ($form) = @_;
  return $form->{projectnumber},
    qq|$form->{$form->{vc}}, $form->{startdate}-$form->{enddate}|;
}

sub _employee_id {
  my ($form, $dbh) = @_;

  return -1 if $form->{admin};

  my $login = $form->{login};
  $login =~ s/\@.*//;

  $query = qq|SELECT id FROM employee WHERE login = '$login'|;
  my ($rv) = $dbh->selectrow_array($query);
  $rv *= 1;

  return $rv;
}

sub _object_id {
  my ($form) = @_;
  return $form->{script} eq 'jc.pl' ? -$form->{id} : $form->{id};
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
