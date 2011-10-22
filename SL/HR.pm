#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# backend code for human resources and payroll
#
#======================================================================

package HR;


sub get_employee {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $sth;
  my $ref;
  my $notid = "";

  if ($form->{id} *= 1) {
    $query = qq|SELECT e.*
                FROM employee e
                WHERE e.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
  
    $ref = $sth->fetchrow_hashref(NAME_lc);
    $ref->{employeelogin} = $ref->{login};
    delete $ref->{login};
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;
  
    # check if employee can be deleted, orphaned
    if (!$form->{employeelogin}) {
      
      $query = qq|SELECT count(*) FROM jcitems
                  WHERE employee_id = $form->{id}|;
      ($form->{status}) = $dbh->selectrow_array($query);
      $form->{status} = ($form->{status}) ? "" : "orphaned";
    }

    # get manager
    $form->{managerid} *= 1;
    $query = qq|SELECT name
                FROM employee
		WHERE id = $form->{managerid}|;
    ($form->{manager}) = $dbh->selectrow_array($query);
    
    $notid = qq|AND id != $form->{id}|;
    
  } else {

    $form->{startdate} = $form->current_date($myconfig);
  
  }
  
  # get managers
  $query = qq|SELECT id, name
              FROM employee
	      WHERE sales = '1'
	      AND role = 'manager'
	      $notid
	      ORDER BY 2|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_manager} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}



sub save_employee {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  my $query;
  my $sth;

  if (! $form->{id}) {
    my $uid = localtime;
    $uid .= $$;

    $query = qq|INSERT INTO employee (name)
                VALUES ('$uid')|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM employee
                WHERE name = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;
  }

  my ($null, $managerid) = split /--/, $form->{manager};
  $managerid *= 1;
  $form->{sales} *= 1;
  $form->{id} *= 1;

  $form->{employeenumber} = $form->update_defaults($myconfig, "employeenumber", $dbh) if ! $form->{employeenumber};

  $query = qq|UPDATE employee SET
              employeenumber = |.$dbh->quote($form->{employeenumber}).qq|,
	      name = |.$dbh->quote($form->{name}).qq|,
	      address1 = |.$dbh->quote($form->{address1}).qq|,
	      address2 = |.$dbh->quote($form->{address2}).qq|,
	      city = |.$dbh->quote($form->{city}).qq|,
	      state = |.$dbh->quote($form->{state}).qq|,
	      zipcode = |.$dbh->quote($form->{zipcode}).qq|,
	      country = |.$dbh->quote($form->{country}).qq|,
	      workphone = '$form->{workphone}',
	      workfax = '$form->{workfax}',
	      workmobile = '$form->{workmobile}',
	      homephone = '$form->{homephone}',
	      startdate = |.$form->dbquote($form->{startdate}, SQL_DATE).qq|,
	      enddate = |.$form->dbquote($form->{enddate}, SQL_DATE).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      role = '$form->{role}',
	      sales = '$form->{sales}',
	      email = |.$dbh->quote($form->{email}).qq|,
	      ssn = '$form->{ssn}',
	      dob = |.$form->dbquote($form->{dob}, SQL_DATE).qq|,
	      iban = '$form->{iban}',
	      bic = '$form->{bic}',
              managerid = $managerid
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $dbh->commit;
  $dbh->disconnect;

}


sub delete_employee {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  for (qw(id db)) { $form->{$_} =~ s/;//g }

  # delete employee
  my $query = qq|DELETE FROM $form->{db}
	         WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM audittrail
	      WHERE employee_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $dbh->commit;
  $dbh->disconnect;

}


sub employees {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $where = "1 = 1";
  $form->{sort} ||= "name";
  my @a = qw(name);
  my $sortorder = $form->sort_order(\@a);
  
  my $var;
  
  for (qw(name employeenumber notes)) {
    if ($form->{$_} ne "") {
      $var = $form->like(lc $form->{$_});
      $where .= " AND lower(e.$_) LIKE '$var'";
    }
  }
 
  if ($form->{startdatefrom}) {
    $where .= " AND e.startdate >= '$form->{startdatefrom}'";
  }
  if ($form->{startdateto}) {
    $where .= " AND e.startdate <= '$form->{startdateto}'";
  }
  if ($form->{sales} eq 'Y') {
    $where .= " AND e.sales = '1'";
  }
  if ($form->{status} eq 'orphaned') {
    $where .= qq| AND e.login IS NULL
                  AND NOT e.id IN 
		          (SELECT DISTINCT employee_id
			   FROM jcitems)|;
  }
  if ($form->{status} eq 'active') {
    $where .= qq| AND e.enddate IS NULL|;
  }
  if ($form->{status} eq 'inactive') {
    $where .= qq| AND e.enddate <= current_date|;
  }

  my $query = qq|SELECT e.*, m.name AS manager
                 FROM employee e
                 LEFT JOIN employee m ON (m.id = e.managerid)
                 WHERE $where
		 ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{address} = "";
    for (qw(address1 address2 city state zipcode country)) { $ref->{address} .= "$ref->{$_} " }
    push @{ $form->{all_employee} }, $ref;
  }

  $sth->finish;
  $dbh->disconnect;

}


1;

