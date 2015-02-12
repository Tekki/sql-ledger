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
  my ($self, $myconfig, $form, $nolock) = @_;

  my $dbh = $form->dbconnect($myconfig);

  $form->remove_locks($myconfig, $dbh, 'hr') unless $nolock;

  my $query;
  my $sth;
  my $ref;
  my $notid = "";
  my $rne;
  
  my @df = qw(closedto revtrans company address tel fax businessnumber precision referenceurl);
  my %defaults = $form->get_defaults($dbh, \@df);
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  %defaults = $form->get_defaults($dbh, \@{['printer_%']});
  
  my $label;
  my $command;
  for (keys %defaults) {
    if ($_ =~ /printer_/) {
      ($label, $command) = split /=/, $defaults{$_};
      $form->{"${label}_printer"} = $command;
    }
  }

  if ($form->{id}) {
    $query = qq|SELECT e.*,
                ad.id AS addressid, ad.address1, ad.address2, ad.city,
		ad.state, ad.zipcode, ad.country,
		bk.name AS bankname, bk.iban, bk.bic, bk.membernumber,
                bk.clearingnumber,
		ad1.address1 AS bankaddress1,
		ad1.address2 AS bankaddress2,
		ad1.city AS bankcity,
		ad1.state AS bankstate,
		ad1.zipcode AS bankzipcode,
		ad1.country AS bankcountry,
		c1.accno AS ap, c1.description AS ap_description,
		tr1.description AS ap_translation,
		c2.accno AS payment, c2.description AS payment_description,
		tr2.description AS payment_translation,
		pm.description AS paymentmethod,
		r.description AS acsrole
                FROM employee e
		JOIN address ad ON (e.id = ad.trans_id)
		LEFT JOIN acsrole r ON (r.id = e.acsrole_id)
		LEFT JOIN bank bk ON (bk.id = e.id)
		LEFT JOIN address ad1 ON (bk.address_id = ad1.id)
		LEFT JOIN chart c1 ON (c1.id = e.apid)
		LEFT JOIN chart c2 ON (c2.id = e.paymentid)
		LEFT JOIN translation tr1 ON (tr1.trans_id = c1.id AND tr1.language_code = '$myconfig->{countrycode}')
		LEFT JOIN translation tr2 ON (tr2.trans_id = c2.id AND tr2.language_code = '$myconfig->{countrycode}')
		LEFT JOIN paymentmethod pm ON (pm.id = e.paymentmethod_id)
                WHERE e.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
  
    $ref = $sth->fetchrow_hashref(NAME_lc);
    $ref->{employeelogin} = $ref->{login};
    for (qw(ap payment)) { $ref->{"${_}_description"} = $ref->{"${_}_translation"} if $ref->{"${_}_translation"} }
    for (qw(login ap_translation payment_translation)) { delete $ref->{$_} }
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;
  
    # check if employee can be deleted, orphaned
    $form->{status} = "";
    $query = qq|SELECT count(*) FROM ap
                WHERE vendor_id = $form->{id}|;
    if (! $dbh->selectrow_array($query)) {
      $form->{status} = "orphaned";
    }
                
    if (! $form->{status}) {
      $query = qq|SELECT count(*) FROM jcitems
                  WHERE employee_id = $form->{id}|;
      if (! $dbh->selectrow_array($query)) {
        $form->{status} = "orphaned";
      }
    }
   
    $query = qq|SELECT *
		FROM payrate
		WHERE trans_id = $form->{id}
		ORDER BY id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{all_payrate} }, $ref;
    }
    $sth->finish;
    
    # get wage links
    $query = qq|SELECT w.*
		FROM employeewage ew
		JOIN wage w ON (ew.wage_id = w.id)
		WHERE ew.employee_id = $form->{id}
		ORDER BY ew.id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{all_employeewage} }, $ref;
    }
    $sth->finish;

    # get deductions
    $query = qq|SELECT d.id, d.description, ed.exempt, ed.maximum,
                ed.id AS edid
		FROM employeededuction ed
		JOIN deduction d ON (ed.deduction_id = d.id)
		WHERE ed.employee_id = $form->{id}
		ORDER BY ed.id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{all_employeededuction} }, $ref;
    }
    $sth->finish;

    $query = qq|SELECT d.id, da.trans_id, da.withholding, da.percent
		FROM deduct da
		JOIN deduction d ON (da.deduction_id = d.id)|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my %deduct;
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{percent} ||= 1;
      push @{ $form->{deduct}{$ref->{trans_id}} }, $ref;
      $deduct{$ref->{id}} = 1;
    }
    $sth->finish;

    # reorder to calculate dependencies
    for $ref (@{ $form->{all_employeededuction} }) {
      if ($deduct{$ref->{id}}) {
	push @{$deduct{a}}, $ref;
      } else {
	push @{$deduct{b}}, $ref;
      }
    }
    @{ $form->{all_employeededuction} } = ();
    push @{ $form->{all_employeededuction} }, @{$deduct{a}};
    push @{ $form->{all_employeededuction} }, @{$deduct{b}};

    $notid = qq|AND id != $form->{id}|;

    # retrieve totals
    my $cd;
    if ($form->{transdate}) {
      $cd = substr($form->datetonum($myconfig, $form->{transdate}),0,4);
    } else {
      $query = qq|SELECT to_char(current_date, 'YYYY')|;
      ($cd) = $dbh->selectrow_array($query);
    }

    if ($form->{trans_id}) {
      $query = qq|SELECT *
                  FROM pay_trans
                  WHERE trans_id = $form->{trans_id}|;
      my $tth = $dbh->prepare($query);
      $tth->execute;
      while ($ref = $tth->fetchrow_hashref(NAME_lc)) {
        $deduct{$ref->{id}} = $ref->{amount};
      }
      $tth->finish;
    }
    
    $query = qq|SELECT SUM(pt.amount)
		FROM pay_trans pt
		JOIN ap a ON (a.id = pt.trans_id)
		WHERE a.vendor_id = $form->{id}
		AND a.transdate >= '${cd}0101'
		AND a.transdate <= '${cd}1231'
		AND pt.id = ?|;
    $sth = $dbh->prepare($query);

    for $ref (@{ $form->{all_employeededuction} }) {
      $sth->execute($ref->{id});
      ($form->{total}{$ref->{id}}) = $sth->fetchrow_array;
      $form->{total}{$ref->{id}} -= $deduct{$ref->{id}} if $deduct{$ref->{id}};
      $form->{total}{$ref->{id}} *= -1;
      $sth->finish;
    }
    
    $query = qq|SELECT a.rn
		FROM acsrole a
		JOIN employee e ON (e.acsrole_id = a.id)
		WHERE e.id = $form->{id}|;
    ($rne) = $dbh->selectrow_array($query);
   
    $form->get_reference($dbh);

    $form->create_lock($myconfig, $dbh, $form->{id}, 'hr') unless $nolock;
 
  } else {

    $form->{startdate} = $form->current_date($myconfig);
  
  }

  my $login = $form->{login};
  $login =~ s/\@.*//;
  $query = qq|SELECT a.rn
              FROM acsrole a
	      JOIN employee e ON (e.acsrole_id = a.id)
	      WHERE e.login = '$login'|;
  my ($rnl) = $dbh->selectrow_array($query);

  $rnl *= 1;
  if ($rnl) {
    $form->{admin} = ($rne) ? $rnl < $rne : 1;
  }
  $form->{admin} = 1 if $login eq 'admin';

  # get acsrole
  $query = qq|SELECT id, description
              FROM acsrole
	      WHERE rn > $rnl
	      ORDER BY rn|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_acsrole} }, $ref;
  }
  $sth->finish;

  
  # get wages
  $query = qq|SELECT *
              FROM wage
	      ORDER BY 2|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_wage} }, $ref;
  }
  $sth->finish;

 
  # get deductions
  $query = qq|SELECT *
              FROM deduction
	      ORDER BY 2|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_deduction} }, $ref;
    # for payroll
    $form->{payrolldeduction}{$ref->{id}} = $ref;
  }
  $sth->finish;
  
  # get deductionrates
  $query = qq|SELECT *
              FROM deductionrate
	      ORDER BY trans_id, rn|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_deductionrate} }, $ref;
  }
  $sth->finish;
  
  my %ae = ( ap => { category => 'L', link => qq| AND c.link = 'AP' | },
	payment => { category => 'A', link => qq| AND c.link LIKE '%AP_paid%' | } );
  for (qw(ap payment)) {
    $query = qq|SELECT c.accno, c.description,
		l.description AS translation
		FROM chart c
		LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		WHERE c.charttype = 'A'
		AND c.category = '$ae{$_}{category}'
		$ae{$_}{link}
		ORDER BY c.accno|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{description} = $ref->{translation} if $ref->{translation};
      push @{ $form->{"${_}_accounts"} }, $ref;
    }
    $sth->finish;
  }

  # get paymentmethod
  $query = qq|SELECT *
              FROM paymentmethod
	      ORDER BY rn|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  @{ $form->{"all_paymentmethod"} } = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{"all_paymentmethod"} }, $ref;
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

  $form->remove_locks($myconfig, $dbh, 'hr');

  my $bank_address_id;
  my $null;
  my $employeelogin;
  my $sales;
  my $acsrole_id;
  my $rn;

  for (qw(paymentmethod acsrole)) { ($null, $form->{"${_}_id"}) = split /--/, $form->{$_} }

  if ($form->{id} *= 1) {
    $query = qq|SELECT e.login, e.sales, e.acsrole_id, a.rn
		FROM employee e
                LEFT JOIN acsrole a ON (e.acsrole_id = a.id)
		WHERE e.id = $form->{id}|;
    ($employeelogin, $sales, $acsrole_id, $rn) = $dbh->selectrow_array($query);

    my $login = $form->{login};
    $login =~ s/@.*//;

    $query = qq|SELECT a.rn
                FROM acsrole a
                JOIN employee e ON (e.acsrole_id = a.id)
                WHERE e.login = '$login'|;
    my ($loginrn) = $dbh->selectrow_array($query);

    unless ($form->{admin}) {
      if ($rn <= $loginrn) {
        $form->{acsrole_id} *= 1;
        $form->{sales} = $sales;
        $form->{acsrole} = qq|--$acsrole_id|;
        $form->{nochange} = 1;
      }
    }

    if ($employeelogin) {
      $query = qq|UPDATE report SET
                  login = '$form->{employeelogin}'
		  WHERE login = '$employeelogin'|;
      $dbh->do($query) || $form->dberror($query);
    }
  
    $query = qq|SELECT address_id
                FROM bank
		WHERE id = $form->{id}|;
    ($bank_address_id) = $dbh->selectrow_array($query);

    $query = qq|DELETE FROM bank
                WHERE id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
    
    $bank_address_id *= 1;
    $query = qq|DELETE FROM address
                WHERE trans_id = $bank_address_id|;
    $dbh->do($query) || $form->dberror($query);

    $form->{addressid} *= 1;
    $query = qq|DELETE FROM address
	        WHERE id = $form->{addressid}|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|DELETE FROM payrate
                WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|DELETE FROM reference
                WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
    
  } else {
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

  $form->{employeenumber} = $form->update_defaults($myconfig, "employeenumber", $dbh) if ! $form->{employeenumber};

  for (qw(ap payment)) { ($form->{$_}) = split /--/, $form->{$_} }

  $form->{acsrole_id} ||= 'NULL';
  $form->{sales} *= 1;
  
  $employeelogin = ($form->{employeelogin}) ? $dbh->quote($form->{employeelogin}) : 'NULL';
	      
  $query = qq|UPDATE employee SET
              employeenumber = |.$dbh->quote($form->{employeenumber}).qq|,
	      name = |.$dbh->quote($form->{name}).qq|,
	      workphone = '$form->{workphone}',
	      workfax = '$form->{workfax}',
	      workmobile = '$form->{workmobile}',
	      homephone = '$form->{homephone}',
	      homemobile = '$form->{homemobile}',
	      startdate = |.$form->dbquote($form->{startdate}, SQL_DATE).qq|,
	      enddate = |.$form->dbquote($form->{enddate}, SQL_DATE).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      sales = '$form->{sales}',
	      login = $employeelogin,
	      email = |.$dbh->quote($form->{email}).qq|,
	      ssn = '$form->{ssn}',
	      dob = |.$form->dbquote($form->{dob}, SQL_DATE).qq|,
	      payperiod = |.$form->dbquote($form->{payperiod}, SQL_INT).qq|,
	      apid = (SELECT id FROM chart WHERE accno = '$form->{ap}'),
	      paymentid = (SELECT id FROM chart WHERE accno = '$form->{payment}'),
	      paymentmethod_id = |.$dbh->quote($form->{paymentmethod_id}).qq|,
	      acsrole_id = $form->{acsrole_id},
	      acs = '$form->{acs}'
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # add address
  my $id;
  my $var;

  if ($form->{addressid}) {
    $id = "id, ";
    $var = "$form->{addressid}, ";
  }

  $query = qq|INSERT INTO address ($id trans_id, address1, address2,
              city, state, zipcode, country) VALUES ($var
	      $form->{id},
	      |.$dbh->quote($form->{address1}).qq|,
	      |.$dbh->quote($form->{address2}).qq|,
	      |.$dbh->quote($form->{city}).qq|,
	      |.$dbh->quote($form->{state}).qq|,
	      |.$dbh->quote($form->{zipcode}).qq|,
	      |.$dbh->quote($form->{country}).qq|)|;
  $dbh->do($query) || $form->dberror($query);
  
  my $ok;
  
  for (qw(iban bic membernumber clearingnumber)) {
    if ($form->{$_}) {
      $ok = 1;
      last;
    }
  }

  if (!$ok) {
    for (qw(name address1 address2 city state zipcode country)) {
      if ($form->{"bank$_"}) {
	$ok = 1;
	last;
      }
    }
  }
  
  if ($ok) {
    if ($bank_address_id) {
      $query = qq|INSERT INTO bank (id, name, iban, bic, membernumber,
                  clearingnumber, address_id)
                  VALUES ($form->{id}, |
		  .$dbh->quote(uc $form->{bankname}).qq|,|
		  .$dbh->quote($form->{iban}).qq|,|
		  .$dbh->quote($form->{bic}).qq|,|
		  .$dbh->quote($form->{membernumber}).qq|,|
		  .$dbh->quote($form->{clearingnumber}).qq|,
		  $bank_address_id
		  )|;
    } else {
      $query = qq|INSERT INTO bank (id, name, iban, bic, membernumber,
                  clearingnumber)
                  VALUES ($form->{id}, |
		  .$dbh->quote(uc $form->{bankname}).qq|,|
		  .$dbh->quote($form->{iban}).qq|,|
		  .$dbh->quote($form->{bic}).qq|,|
		  .$dbh->quote($form->{membernumber}).qq|,|
		  .$dbh->quote($form->{clearingnumber}).qq|
		  )|;
    }
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT address_id
                FROM bank
		WHERE id = $form->{id}|;
    ($bank_address_id) = $dbh->selectrow_array($query);
    
  }

  $ok = 0;
  for (qw(address1 address2 city state zipcode country)) {
    if ($form->{"bank$_"}) {
      $ok = 1;
      last;
    }
  }

  if ($ok) {
    if ($bank_address_id) {
      $query = qq|INSERT INTO address (id, trans_id, address1, address2,
                  city, state, zipcode, country) VALUES (
		  $bank_address_id, $bank_address_id,
		  |.$dbh->quote(uc $form->{bankaddress1}).qq|,
		  |.$dbh->quote(uc $form->{bankaddress2}).qq|,
		  |.$dbh->quote(uc $form->{bankcity}).qq|,
		  |.$dbh->quote(uc $form->{bankstate}).qq|,
		  |.$dbh->quote(uc $form->{bankzipcode}).qq|,
		  |.$dbh->quote(uc $form->{bankcountry}).qq|)|;
      $dbh->do($query) || $form->dberror($query);

    } else {
      $query = qq|INSERT INTO bank (id, name)
                  VALUES ($form->{id},
		  |.$dbh->quote(uc $form->{bankname}).qq|)|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|SELECT address_id
                  FROM bank
		  WHERE id = $form->{id}|;
      ($bank_address_id) = $dbh->selectrow_array($query);

      $query = qq|INSERT INTO address (id, trans_id, address1, address2,
                  city, state, zipcode, country) VALUES (
		  $bank_address_id, $bank_address_id,
		  |.$dbh->quote(uc $form->{bankaddress1}).qq|,
		  |.$dbh->quote(uc $form->{bankaddress2}).qq|,
		  |.$dbh->quote(uc $form->{bankcity}).qq|,
		  |.$dbh->quote(uc $form->{bankstate}).qq|,
		  |.$dbh->quote(uc $form->{bankzipcode}).qq|,
		  |.$dbh->quote(uc $form->{bankcountry}).qq|)|;
      $dbh->do($query) || $form->dberror($query);
    }
  }
  

  # insert wage, deduction and exempt for payroll
  $query = qq|DELETE FROM employeewage
              WHERE employee_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|INSERT INTO employeewage (employee_id, id, wage_id) VALUES
              ($form->{id},?,?)|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  for ($i = 1; $i <= $form->{wage_rows}; $i++) {
    ($null, $wage_id) = split /--/, $form->{"wage_$i"};
    if ($wage_id) {
      $sth->execute($i,$wage_id) || $form->dberror($query);
    }
  }
  $sth->finish;

  $query = qq|DELETE FROM employeededuction
              WHERE employee_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|INSERT INTO employeededuction (employee_id, id, deduction_id,
              exempt, maximum) VALUES ($form->{id},?,?,?,?)|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  for ($i = 1; $i <= $form->{deduction_rows}; $i++) {
    for (qw(exempt maximum)) { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) }
    ($null, $deduction_id) = split /--/, $form->{"deduction_$i"};
    if ($deduction_id) {
      $sth->execute($i, $deduction_id, $form->{"exempt_$i"}, $form->{"maximum_$i"}) || $form->dberror($query);
    }
  }
  $sth->finish;

  $query = qq|INSERT INTO payrate (trans_id, id, rate, above)
              VALUES ($form->{id},?,?,?)|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  
  for ($i = 1; $i <= $form->{payrate_rows}; $i++) {
    for (qw(rate above)) { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) }
    $form->{"above_$i"} = $form->parse_amount($myconfig, $form->{"above_$i"});
    if ($form->{"rate_$i"}) {
      $sth->execute($i, $form->{"rate_$i"}, $form->{"above_$i"}) || $form->dberror($query);
    }
  }
  $sth->finish;

  $form->save_reference($dbh);
  
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub delete_employee {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;

  $query = qq|SELECT address_id
              FROM bank
              WHERE id = $form->{id}|;
  my ($bank_address_id) = $dbh->selectrow_array($query);
  
  $bank_address_id *= 1;
  $query = qq|DELETE FROM address
              WHERE trans_id = $bank_address_id|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|SELECT login
              FROM employee
	      WHERE id = $form->{id}|;
  my ($login) = $dbh->selectrow_array($query);
  
  if ($login) {
    $query = qq|UPDATE report
                SET login = ''
		WHERE login = '$login'|;
    $dbh->do($query) || $form->dberror($query);
  }

  # delete employee
  $query = qq|DELETE FROM $form->{db}
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|DELETE FROM address
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM reference
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
 
  $query = qq|DELETE FROM audittrail
	      WHERE employee_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $form->remove_locks($myconfig, $dbh, 'hr');
 
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub employees {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['company', 'precision']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $where = "1 = 1";

  $form->{sort} ||= "name";

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
  if ($form->{status} eq 'sales') {
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

  my $query = qq|SELECT e.*, 
                 ad.address1, ad.address2, ad.city, ad.state,
		 ad.zipcode, ad.country,
		 bk.iban, bk.bic,
		 r.description AS acsrole
                 FROM employee e
		 LEFT JOIN address ad ON (ad.trans_id = e.id)
		 LEFT JOIN bank bk ON (bk.id = e.id)
		 LEFT JOIN acsrole r ON (r.id = e.acsrole_id)
                 WHERE $where|;

  my @sf = qw(name);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{address} = "";
    for (qw(address1 address2 city state zipcode country)) { $ref->{address} .= "$ref->{$_} " }
    push @{ $form->{all_employee} }, $ref;
  }
  $sth->finish;
  
  $query = qq|SELECT c.accno, c.description, l.description AS translation
	      FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.link = 'AP'
	      ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{all_ap} }, $ref;
  }
  $sth->finish;
 
  $query = qq|SELECT c.accno, c.description, l.description AS translation
	      FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.link LIKE '%AP_paid%'
	      ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{all_payment} }, $ref;
  }
  $sth->finish;
  
  $query = qq|SELECT *
              FROM paymentmethod
	      ORDER BY rn|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_paymentmethod} }, $ref;
  }
  $sth->finish;

  $form->get_peripherals($dbh);

  $form->all_languages($myconfig, $dbh);
  
  $form->all_projects($myconfig, $dbh);
  
  $form->all_departments($myconfig, $dbh, 'vendor');

  $dbh->disconnect;

}


sub payroll_links {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->remove_locks($myconfig, $dbh);
  
  my @var;
  
  my @df = qw(closedto revtrans company precision namesbynumber referenceurl);
  my %defaults = $form->get_defaults($dbh, \@df);
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  my $sortorder = "name";
  $sortorder = "employeenumber" if $form->{namesbynumber};

  my $query = qq|SELECT *
                 FROM employee
                 WHERE id IN (SELECT employee_id FROM employeewage)
                 AND enddate IS NULL
		 ORDER BY $sortorder|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_employee} }, $ref;
  }
  $sth->finish;

  $form->{datepaid} = $form->{transdate} = $form->current_date($myconfig);

  if ($form->{id}) {
    $query = qq|SELECT a.*, e.name AS employee, e.payperiod,
                d.description AS department,
		c1.accno AS ap_accno, c1.description AS ap_accno_description,
		t1.description AS ap_accno_translation,
		c2.accno AS payment_accno, c2.description AS payment_accno_description,
		t2.description AS payment_accno_translation,
		pm.description AS paymentmethod, e.paymentmethod_id
                FROM ap a
		JOIN employee e ON (e.id = a.vendor_id)
		LEFT JOIN department d ON (d.id = a.department_id)
		LEFT JOIN chart c1 ON (c1.id = e.apid)
		LEFT JOIN translation t1 ON (t1.trans_id = c1.id AND t1.language_code = '$myconfig->{countrycode}')
		LEFT JOIN chart c2 ON (c2.id = e.paymentid)
		LEFT JOIN translation t2 ON (t2.trans_id = c2.id AND t2.language_code = '$myconfig->{countrycode}')
		LEFT JOIN paymentmethod pm ON (pm.id = e.paymentmethod_id)
		WHERE a.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    $ref = $sth->fetchrow_hashref(NAME_lc);
    delete $ref->{id};
    
    for (qw(ap payment)) {
      $ref->{$_} = qq|$ref->{"${_}_accno"}--$ref->{"${_}_accno_description"}|;
      $ref->{$_} = qq|$ref->{"${_}_accno"}--$ref->{"${_}_accno_description"}| if $ref->{"${_}_accno_translation"};
    }
    
    for (qw(paymentmethod department)) {
      $ref->{$_} = qq|$ref->{$_}--$ref->{"${_}_id"}|;
    }
    
    $ref->{employee} = qq|$ref->{employee}--$ref->{vendor_id}|;
    
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $sth->finish;
    
    # ap
    $query = qq|SELECT c.accno, c.description, t.description AS translation
                FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		LEFT JOIN translation t ON (t.trans_id = c.id AND t.language_code = '$myconfig->{countrycode}')
		WHERE c.link = 'AP'
		AND ac.trans_id = $form->{id}|;
    (@var) = $dbh->selectrow_array($query);
    if (@var) {
      $form->{ap} = qq|$var[0]--$var[1]|;
      $form->{ap} = qq|$var[0]--$var[2]| if $var[2];
    }
    
    # payment
    $query = qq|SELECT ac.source, ac.memo, c.accno, c.description,
                t.description AS translation,
		pm.id AS pmid, pm.description AS paymentmethod
                FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		LEFT JOIN translation t ON (t.trans_id = c.id AND t.language_code = '$myconfig->{countrycode}')
		JOIN payment p ON (p.trans_id = ac.trans_id and p.id = ac.id)
		LEFT JOIN paymentmethod pm ON (pm.id = p.paymentmethod_id)
		WHERE c.link LIKE '%AP_paid%'
		AND ac.trans_id = $form->{id}|;
    (@var) = $dbh->selectrow_array($query);
    if (@var) {
      $form->{source} = $var[0];
      $form->{memo} = $var[1];
      $form->{payment} = qq|$var[2]--$var[3]|;
      $form->{payment} = qq|$var[2]--$var[4]| if $var[4];
      $form->{paymentmethod} = qq|$var[6]--$var[5]|;
    }
    
    my %wage;
    
    # all wages for employee
    $query = qq|SELECT w.*
                FROM wage w
                JOIN employeewage ew ON (ew.wage_id = w.id)
		WHERE ew.employee_id = $form->{vendor_id}
		ORDER BY ew.id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $i = 0;
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $i++;
      $form->{"wage_$i"} = $ref->{description};
      $form->{"wage_id_$i"} = $ref->{id};
      $form->{"amount_$i"} = $ref->{amount};
      $wage{$ref->{id}} = $i;
    }
    $sth->finish;
    $form->{wage_rows} = $i;
    
    # wages and deductions
    $query = qq|SELECT pt.*, w.description AS wage, d.description AS deduction
                FROM pay_trans pt
		LEFT JOIN wage w ON (w.id = pt.id)
		LEFT JOIN deduction d ON (d.id = pt.id)
		WHERE pt.trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $i = 0;
    my $j = 0;
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      if ($ref->{wage}) {
	for (qw(qty amount)) { $form->{"${_}_$wage{$ref->{id}}"} = $ref->{$_} }
      }
      if ($ref->{deduction}) {
	$j++;
	$form->{"deduction_$j"} = $ref->{deduction};
	$form->{"deduction_id_$j"} = $ref->{id};
      }
    }
    $sth->finish;
    $form->{deduction_rows} = $j;

    # payrates
    $query = qq|SELECT *
                FROM payrate
		WHERE trans_id = $form->{vendor_id}
		ORDER BY id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $i = 0;
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $i++;
      for (qw(rate above)) { $form->{"${_}_$i"} = $ref->{$_} }
    }
    $sth->finish;
    $form->{payrate_rows} = $i;

    $form->get_reference($dbh);

    $form->create_lock($myconfig, $dbh, $form->{id}, 'hr');
    
  }
 
  $query = qq|SELECT c.accno, c.description, l.description AS translation
	      FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.link = 'AP'
	      ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{all_ap} }, $ref;
  }
  $sth->finish;
 
  $query = qq|SELECT c.accno, c.description, l.description AS translation
	      FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.link LIKE '%AP_paid%'
	      ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{all_payment} }, $ref;
  }
  $sth->finish;
  
  $query = qq|SELECT *
              FROM paymentmethod
	      ORDER BY rn|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_paymentmethod} }, $ref;
  }
  $sth->finish;

  $form->get_peripherals($dbh);

  $form->all_languages($myconfig, $dbh);
  
  $form->all_projects($myconfig, $dbh);
  
  $form->all_departments($myconfig, $dbh, 'vendor');

  $dbh->disconnect;

}


sub search_payroll {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my %defaults = $form->get_defaults($dbh, \@{['namesbynumber']});
  
  my $sortorder = "name";
  if ($defaults{namesbynumber}) {
    $sortorder = "employeenumber";
  }

  my $query = qq|SELECT id, name, employeenumber
                 FROM employee
                 WHERE id IN (SELECT employee_id FROM employeewage)
		 ORDER BY $sortorder|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_employee} }, $ref;
  }
  $sth->finish;
  
  $query = qq|SELECT *
              FROM paymentmethod
	      ORDER BY rn|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_paymentmethod} }, $ref;
  }
  $sth->finish;

  $form->all_projects($myconfig, $dbh);
  
  $form->all_departments($myconfig, $dbh, 'vendor');

  $dbh->disconnect;

}



sub payroll_transactions {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['company', 'precision']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $where = "1 = 1";
  my $acwhere = "1 = 1";

  $form->{sort} ||= "employee";

  my $id;
 
  $form->report_level($myconfig, $dbh);
  
  if ($form->{employee}) {
    (undef, $id) = split /--/, $form->{employee};
    $where .= qq|
                AND v.id = $id|;
  }
  
  if ($form->{department}) {
    (undef, $id) = split /--/, $form->{department};
    $where .= qq|
                AND a.department_id = $id|;
  }
  if ($form->{paymentmethod}) {
    (undef, $id) = split /--/, $form->{paymentmethod};
    $where .= qq|
                AND a.paymentmethod_id = $id|;
  }

  ($form->{transdatefrom}, $form->{transdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  
  $where .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
  $where .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};
  
  my $query = qq|SELECT DISTINCT v.name AS employee,
                 a.transdate, a.invnumber, a.vendor_id, a.id, a.amount, a.paid
                 FROM pay_trans pt
		 JOIN ap a ON (a.id = pt.trans_id)
		 JOIN vendor v ON (v.id = a.vendor_id)
		 WHERE $where|;

  my @sf = qw(employee);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  # project ?
  (undef, $id) = split /--/, $form->{projectnumber};
  $query = qq|SELECT trans_id
	      FROM acc_trans
	      WHERE project_id = $id
	      AND trans_id = ?|;
  my $pth = $dbh->prepare($query);

  # gl
  $query = qq|SELECT reference
              FROM gl
	      WHERE id = ?|;
  my $gth = $dbh->prepare($query);
	      
  # wages / deductions
  $query = qq|SELECT *
              FROM pay_trans
	      WHERE trans_id = ?|;
  my $wth = $dbh->prepare($query);

  my $ok;
  my $ref;

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ok = 0;
    $wth->execute($ref->{id});

    while ($dref = $wth->fetchrow_hashref(NAME_lc)) {
      $ref->{glid} = $dref->{glid};
      if ($ref->{$dref->{id}} = $dref->{amount} * $dref->{qty}) {
	$form->{$dref->{id}} = 1;
	$ok = 1;
      }
    }
    $wth->finish;
    
    if ($ref->{glid}) {
      $gth->execute($ref->{glid});
      ($ref->{reference}) = $gth->fetchrow_array;
      $gth->finish;
    }

    if ($form->{projectnumber}) {
      $pth->execute($ref->{id});
      $ok = $pth->fetchrow_array;
      $pth->finish;
    }
    
    push @{ $form->{transactions} }, $ref if $ok;
    
  }
  $sth->finish;

  for (qw(wage deduction)) {
    $query = qq|SELECT id, description
		FROM $_
		ORDER BY 2|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{"all_$_"} }, $ref if $form->{$ref->{id}};
    }
    $sth->finish;
  }

  $dbh->disconnect;

}



sub payslip_details {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $sth;
  my $ref;
  
  my %defaults = $form->get_defaults($dbh, \@{['company', 'address', 'tel', 'fax', 'companyemail', 'companywebsite', 'businessnumber', 'precision', 'referenceurl']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  %defaults = $form->get_defaults($dbh, \@{['printer_%']});
  
  my ($null, $id) = split /--/, $form->{employee};

  if ($id *= 1) {
    $query = qq|SELECT e.*,
                ad.address1, ad.address2, ad.city,
                ad.state, ad.zipcode, ad.country,
		bk.name AS employeebankname, bk.iban AS employeebankiban,
                bk.bic AS employeebankbic,
                bk.membernumber AS employeebankmembernumber,
                bk.clearingnumber AS employeebankclearingnumber,
		ad1.address1 AS employeebankaddress1,
		ad1.address2 AS employeebankaddress2,
		ad1.city AS employeebankcity,
		ad1.state AS employeebankstate,
		ad1.zipcode AS employeebankzipcode,
		ad1.country AS employeebankcountry
                FROM employee e
		JOIN address ad ON (e.id = ad.trans_id)

		LEFT JOIN bank bk ON (bk.id = e.id)
		LEFT JOIN address ad1 ON (bk.address_id = ad1.id)

                WHERE e.id = $id|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
  
    $ref = $sth->fetchrow_hashref(NAME_lc);
    $ref->{employeelogin} = $ref->{login};
    delete $ref->{login};
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;
  }

  ($null, $id) = split /--/, $form->{paymentmethod};
  if ($id *= 1) {
    $query = qq|SELECT fee, roundchange
                FROM paymentmethod
                WHERE id = $id|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
  
    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;
  }

  ($id) = split /--/, $form->{payment};

  if ($id *= 1) {
    $query = qq|SELECT
		c2.accno AS payment, c2.description AS payment_description,
		tr2.description AS payment_translation,
		bk.name AS bankname, bk.iban, bk.bic, bk.dcn, bk.rvc,
                bk.membernumber, bk.clearingnumber,
		ad1.address1 AS bankaddress1,
		ad1.address2 AS bankaddress2,
		ad1.city AS bankcity,
		ad1.state AS bankstate,
		ad1.zipcode AS bankzipcode,
		ad1.country AS bankcountry
                FROM chart c2
                LEFT JOIN bank bk ON (bk.id = c2.id)
		LEFT JOIN address ad1 ON (bk.id = ad1.trans_id)
		LEFT JOIN translation tr2 ON (tr2.trans_id = c2.id AND tr2.language_code = '$myconfig->{countrycode}')
                WHERE c2.accno = '$id'|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
  
    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;
  }


  ($id) = split /--/, $form->{ap};

  if ($id *= 1) {
    $query = qq|SELECT
		c1.accno AS ap, c1.description AS ap_description,
		tr1.description AS ap_translation
                FROM chart c1
		LEFT JOIN translation tr1 ON (tr1.trans_id = c1.id AND tr1.language_code = '$myconfig->{countrycode}')
                WHERE c1.accno = '$id'|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
  
    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;
  }

  $dbh->disconnect;

}



sub post_transaction {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect_noauto($myconfig);
  my $ap = new Form;
  my $gl = new Form;
  
  my %defaults = $form->get_defaults($dbh, \@{['expense_accno_id']});
  
  my $query;
  my $sth;
  my $ref;
  my $user_id;

  $query = qq|SELECT *
              FROM wage
	      WHERE id = ?|;
  my $wth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT *
              FROM deduction
	      WHERE id = ?|;
  my $dth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|INSERT INTO pay_trans (trans_id, id, qty, amount)
              VALUES (?,?,?,?)|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);
	      
  $query = qq|SELECT curr
              FROM curr
	      ORDER BY rn|;
  ($ap->{currency}) = $dbh->selectrow_array($query);
  
  $query = qq|SELECT accno
              FROM chart
	      WHERE id = ?|;
  my $cth = $dbh->prepare($query) || $form->dberror($query);

  my ($employee, $employee_id) = split /--/, $form->{employee};

  $cth->execute($defaults{expense_accno_id});
  my ($expense_accno) = $cth->fetchrow_array;
  $cth->finish;
  
  $query = qq|SELECT id
              FROM vendor
	      WHERE id = $employee_id|;

  if (! $dbh->selectrow_array($query)) {
    $query = qq|SELECT *
                FROM employee
		WHERE id = $employee_id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);

    ($null, $user_id) = $form->get_employee($dbh);
    my $vendornumber = $form->update_defaults($myconfig, 'vendornumber');
    
    $query = qq|INSERT INTO vendor (id, name, phone,
                fax, email, notes,
		vendornumber, employee_id, curr,
		startdate, enddate, arap_accno_id,
		payment_accno_id, paymentmethod_id)
                VALUES (
                $employee_id, |
                .$dbh->quote($employee).qq|, '$ref->{workphone}',
		'$ref->{workfax}', '$ref->{email}', '$ref->{notes}',
		$vendornumber, $user_id, '$ap->{currency}',|
		.$form->dbquote($ref->{startdate}, SQL_DATE).qq|, |
		.$form->dbquote($ref->{enddate}, SQL_DATE).qq|, |
		.$dbh->quote($ref->{apid}).qq|, |
		.$dbh->quote($ref->{paymentid}).qq|, |
		.$dbh->quote($ref->{paymentmethod_id}).qq|)|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|INSERT INTO contact (trans_id, typeofcontact,
                phone, fax, mobile, email)
                VALUES ($employee_id, 'person',
		'$ref->{workphone}', '$ref->{workfax}', '$ref->{workmobile}',
		'$ref->{email}')|;
    $dbh->do($query) || $form->dberror($query);

    $sth->finish;
  }
  
  if ($form->{id}) {
    $query = qq|SELECT pt.glid, g.reference
		FROM pay_trans pt
		JOIN ap a ON (a.id = pt.trans_id)
		JOIN gl g ON (g.id = pt.glid)
		WHERE pt.trans_id = $form->{id}|;
    ($gl->{id}, $gl->{reference}) = $dbh->selectrow_array($query);

    $query = qq|DELETE FROM pay_trans
                WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }
 
  $ap->{login} = $form->{login};
  $ap->{id} = $form->{id};
  $ap->{invnumber} = $form->{invnumber};
  $ap->{vendor_id} = $employee_id; 
  $ap->{defaultcurrency} = $ap->{currency};
  $ap->{department} = $form->{department};
  $ap->{vc} = 'vendor';
  $ap->{transdate} = $form->{transdate};
  $ap->{duedate} = $form->{transdate};
  $ap->{AP} = $form->{ap};
  $ap->{description} = $form->{description};
  
  my $i = 0;
  my $j;
  my $employerpays;
  my $amount;
  
  for $j (1 .. $form->{wage_rows}) {
    
    if ($form->{"wage_id_$j"}) {
      
      $wth->execute($form->{"wage_id_$j"});
      $ref = $wth->fetchrow_hashref(NAME_lc);
      
      # accno
      $cth->execute($ref->{chart_id});
      ($accno) = $cth->fetchrow_array;
      $cth->finish;

      if ($ref->{defer}) {
	# deferred wages
	$cth->execute($ref->{defer});
	($defer) = $cth->fetchrow_array;
	$cth->finish;
	
	if ($amount = $form->round_amount($form->{"pay_$j"}, 10)) {
	  push @employerpays, { employeraccno => $defer, employeeaccno => $accno, description => $form->{"wage_$j"}, amount => $amount };
	}
	
      } else {
	
	$i++;

	# acc_trans amount
	$ap->{"amount_$i"} = $form->{"pay_$j"};
	$ap->{"AP_amount_$i"} = $accno || $expense_accno;
	$ap->{"description_$i"} = $form->{"wage_$j"};
	$ap->{"projectnumber_$i"} = $form->{project};
      }
      $wth->finish;

      
    }
  }
  
  for $j (1 .. $form->{deduction_rows}) {
    $dth->execute($form->{"deduction_id_$j"});
    $ref = $dth->fetchrow_hashref(NAME_lc);

    # employee
    if ($ref->{employeepays}) {
      # accno
      $cth->execute($ref->{employee_accno_id});
      ($accno) = $cth->fetchrow_array;
      $cth->finish;
      
      $accno ||= $expense_accno;
      $i++;

      # acc_trans amount
      $ap->{"amount_$i"} = $form->{"deduct_$j"};
      $ap->{"AP_amount_$i"} = $accno;
      $ap->{"description_$i"} = $form->{"deduction_$j"};
      $ap->{"projectnumber_$i"} = $form->{project};
    }

    # employer
    if ($ref->{employerpays}) {
      $cth->execute($ref->{employer_accno_id});
      ($employeraccno) = $cth->fetchrow_array;
      $cth->finish;
      
      $employeraccno ||= $form->{ap};
      
      $amount = $form->parse_amount($myconfig, $form->{"deduct_$j"}) * $ref->{employerpays};

      if ($amount) {
	push @employerpays, { employeraccno => $employeraccno, employeeaccno => $accno, description => $form->{"deduction_$j"}, amount => $amount };
      }
      
    }
 
    $dth->finish;
  }
  $ap->{rowcount} = $i;
  
  # payment
  $ap->{paidaccounts} = 1;
  $ap->{"datepaid_1"} = $form->{datepaid};
  $ap->{"paid_1"} = $form->{paid};
  $ap->{"AP_paid_1"} = $form->{payment};
  $ap->{"source_1"} = $form->{source};
  $ap->{"memo_1"} = $form->{memo};
  $ap->{"paymentmethod_1"} = $form->{paymentmethod};

  $i = 0;
  for (1 .. $form->{reference_rows}) {
    if ($form->{"referenceid_$_"}) {
      $i++;
      $ap->{"referenceid_$i"} = $form->{"referenceid_$_"};
      $ap->{"referencedescription_$i"} = $form->{"referencedescription_$_"};
      $gl->{"referenceid_$i"} = $form->{"referenceid_$_"};
      $gl->{"referencedescription_$i"} = $form->{"referencedescription_$_"};
    }
  }
  $ap->{reference_rows} = $i;
  $gl->{reference_rows} = $i;
  
  AA->post_transaction($myconfig, $ap, $dbh);
  
  # pay_trans entries
  for $j (1 .. $form->{wage_rows}) {
    for (qw(qty amount)) { $form->{"${_}_$j"} = $form->parse_amount($myconfig, $form->{"${_}_$j"}) }

    if ($form->round_amount($form->{"qty_$j"} * $form->{"amount_$j"},10)) {
      $pth->execute($ap->{id}, $form->{"wage_id_$j"}, $form->{"qty_$j"}, $form->{"amount_$j"});
      $pth->finish;
    }
  }

  for $j (1 .. $form->{deduction_rows}) {
    if ($form->{"deduct_$j"} = $form->parse_amount($myconfig, $form->{"deduct_$j"})) {
      $pth->execute($ap->{id}, $form->{"deduction_id_$j"}, 1, $form->{"deduct_$j"});
      $pth->finish;
    }
  }

  $gl->{login} = $form->{login};
  
  # employer pays
  if (@employerpays) {
    $gl->{transdate} = $form->{transdate};
    $gl->{department} = $form->{department};
    $gl->{currency} = $ap->{currency};
    $gl->{defaultcurrency} = $ap->{currency};
    $gl->{description} = $employee;
    $gl->{notes} = qq|$form->{description}|;

    $i = 1;
    for (@employerpays) {

      if ($_->{amount}) {
	$gl->{"accno_$i"} = $_->{employeeaccno} || $form->{expense};
	$gl->{"memo_$i"} = $_->{description};
	$gl->{"projectnumber_$i"} = $form->{projectnumber};

	if ($_->{amount} < 0) {
	  $gl->{"debit_$i"} = $form->format_amount($myconfig, $_->{amount}, $form->{precision});
	} else {
	  $gl->{"credit_$i"} = $form->format_amount($myconfig, $_->{amount} * -1, $form->{precision});
	}
	$i++;
	
	$gl->{"accno_$i"} = $_->{employeraccno} || $form->{ap};
	$gl->{"memo_$i"} = $_->{description};
	$gl->{"projectnumber_$i"} = $form->{projectnumber};

	if ($_->{amount} < 0) {
	  $gl->{"credit_$i"} = $form->format_amount($myconfig, $_->{amount}, $form->{precision});
	} else {
	  $gl->{"debit_$i"} = $form->format_amount($myconfig, $_->{amount} * -1, $form->{precision});
	}
	  
	$i++;
      }
    }
    $gl->{rowcount} = $i;

    GL->post_transaction($myconfig, $gl, $dbh);

    $query = qq|UPDATE pay_trans SET
                glid = $gl->{id}
		WHERE trans_id = $ap->{id}|;
    $dbh->do($query) || $form->dberror($query);

  }

  my $rc = $dbh->commit;
  
  $dbh->disconnect;
  
  $rc;
  
}


sub get_deduction {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);
  my $query;
  my $sth;
  my $ref;
  my $item;
  my $i;

  $form->remove_locks($myconfig, $dbh, 'hr');
  
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  if ($form->{id}) {
    $query = qq|SELECT d.*,
		 c1.accno AS employee_accno,
		 c1.description AS employee_accno_description,
		 l1.description AS employee_accno_translation,
		 c2.accno AS employer_accno,
		 c2.description AS employer_accno_description,
		 l2.description AS employer_accno_translation,
		 b.description AS basedesc
                 FROM deduction d
		 LEFT JOIN chart c1 ON (c1.id = d.employee_accno_id)
		 LEFT JOIN translation l1 ON (l1.trans_id = c1.id AND l1.language_code = '$myconfig->{countrycode}')
		 LEFT JOIN chart c2 ON (c2.id = d.employer_accno_id)
		 LEFT JOIN translation l2 ON (l2.trans_id = c2.id AND l2.language_code = '$myconfig->{countrycode}')
		 LEFT JOIN deduction b ON (d.basedon = b.id)
                 WHERE d.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
  
    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (qw(employee employer)) { $ref->{"${_}_accno_description"} = $ref->{"${_}_translation"} if $ref->{"${_}_translation"} }
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;
  
    # check if orphaned
    $form->{status} = "";
    $query = qq|SELECT count(*) FROM employeededuction
                WHERE deduction_id = $form->{id}|;
    if (! $dbh->selectrow_array($query)) {
      $form->{status} = 'orphaned';
    }

    # get the rates
    $query = qq|SELECT *
                FROM deductionrate
                WHERE trans_id = $form->{id}
		ORDER BY rn|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{deductionrate} }, $ref;
    }
    $sth->finish;

    $query = qq|SELECT d.id, d.description, da.withholding, da.percent
                FROM deduction d
		JOIN deduct da ON (da.deduction_id = d.id)
                WHERE da.trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{deduct} }, $ref;
    }
    $sth->finish;

    # build selection list for basedon
    $query = qq|SELECT id, description
                FROM deduction
	        WHERE id != $form->{id}
		ORDER BY 2|;
		
    $form->create_lock($myconfig, $dbh, $form->{id}, 'hr');

  } else {
    # build selection list for basedon
    $query = qq|SELECT id, description
		FROM deduction
		ORDER BY 2|;
  }
  
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_deduction} }, $ref;
  }
  $sth->finish;

  $query = qq|SELECT c.accno, c.description,
	      l.description AS translation
	      FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.charttype = 'A'
	      AND c.link LIKE '%AP_amount%'
	      ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{accounts} }, $ref;
  }
  $sth->finish;
  
  $dbh->disconnect;

}


sub deductions {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $query = qq|SELECT d.id, d.description, d.employeepays, d.employerpays,
                 b.description AS basedon,
                 c1.accno AS employee_accno,
                 c2.accno AS employer_accno,
                 dr.*
                 FROM deduction d
		 LEFT JOIN deduction b ON (b.id = d.basedon)
		 LEFT JOIN deductionrate dr ON (dr.trans_id = d.id)
		 LEFT JOIN chart c1 ON (d.employee_accno_id = c1.id)
		 LEFT JOIN chart c2 ON (d.employer_accno_id = c2.id)
                 ORDER BY 2, dr.rn|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_deduction} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;

}


sub save_deduction {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $null;
  my $deduction_id;
  my $query;
  my $sth;

  ($null, $form->{basedon}) = split /--/, $form->{basedon};
  
  if (! $form->{id}) {
    my $uid = localtime;
    $uid .= $$;

    $query = qq|INSERT INTO deduction (description)
                VALUES ('$uid')|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM deduction
                WHERE description = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;
  }


  for (qw(employee employer)) {
    ($form->{"${_}_accno"}) = split /--/, $form->{"${_}_accno"};
    $form->{"${_}pays"} = $form->parse_amount($myconfig, $form->{"${_}pays"});
  }
  
  $query = qq|UPDATE deduction SET
	      description = |.$dbh->quote($form->{description}).qq|,
	      employee_accno_id =
	           (SELECT id FROM chart
	            WHERE accno = '$form->{employee_accno}'),
	      employer_accno_id =
	           (SELECT id FROM chart
	            WHERE accno = '$form->{employer_accno}'),
	      employerpays = '$form->{employerpays}',
	      employeepays = '$form->{employeepays}',
	      fromage = |.$form->dbquote($form->{fromage}, SQL_INT).qq|,
	      toage = |.$form->dbquote($form->{toage}, SQL_INT).qq|,
	      basedon = |.$dbh->quote($form->{basedon}).qq|,
	      agedob = |.$dbh->quote($form->{agedob}).qq|
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);


  $query = qq|DELETE FROM deductionrate
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|INSERT INTO deductionrate
	      (rn, trans_id, rate, amount, above, below) VALUES (?,?,?,?,?,?)|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
 
  for ($i = 1; $i <= $form->{rate_rows}; $i++) {
    for (qw(rate amount above below)) { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) }
    $form->{"rate_$i"} /= 100;

    if ($form->{"rate_$i"} + $form->{"amount_$i"} + $form->{"above_$i"} + $form->{"below_$i"}) {
      $sth->execute($i, $form->{id}, $form->{"rate_$i"}, $form->{"amount_$i"}, $form->{"above_$i"}, $form->{"below_$i"}) || $form->dberror($query);
    }
  }
  $sth->finish;

  $query = qq|DELETE FROM deduct
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|INSERT INTO deduct
              (trans_id, deduction_id, withholding, percent) VALUES (?,?,?,?)|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  for ($i = 1; $i <= $form->{deduct_rows}; $i++) {
    ($null, $deduction_id) = split /--/, $form->{"deduct_$i"};
    if ($deduction_id) {
      $form->{"percent_$i"} = $form->parse_amount($myconfig, $form->{"percent_$i"});
      $form->{"percent_$i"} /= 100;

      $sth->execute($form->{id}, $deduction_id, $form->{"withholding_$i"}, $form->{"percent_$i"}) || $form->dberror($query);
    }
  }
  $sth->finish;
  
  $form->remove_locks($myconfig, $dbh, 'hr');

  $dbh->commit;
  $dbh->disconnect;

}


sub delete_deduction {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  # delete deduction
  my $query = qq|DELETE FROM deduction
	         WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM deductionrate
	         WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM deduct
	         WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $form->remove_locks($myconfig, $dbh, 'hr');

  $dbh->commit;
  $dbh->disconnect;

}


sub get_wage {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);
  my $query;
  my $sth;
  my $ref;

  $form->remove_locks($myconfig, $dbh, 'hr');

  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  if ($form->{id}) {
    $query = qq|SELECT w.*,
		 c.accno, c.description AS accno_description,
		 l.description AS accno_translation,
		 c1.accno AS defer, c1.description AS defer_description,
		 l1.description AS defer_translation
                 FROM wage w
		 LEFT JOIN chart c ON (c.id = w.chart_id)
		 LEFT JOIN chart c1 ON (c1.id = w.defer)
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		 LEFT JOIN translation l1 ON (l1.trans_id = c1.id AND l1.language_code = '$myconfig->{countrycode}')
                 WHERE w.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    $ref->{"accno_description"} = $ref->{"accno_translation"} if $ref->{"accno_translation"};
    $ref->{"defer_description"} = $ref->{"defer_translation"} if $ref->{"defer_translation"};
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;
  
    # check if orphaned
    $form->{status} = "";
    $query = qq|SELECT count(*) FROM employeewage
                WHERE wage_id = $form->{id}|;
    if (! $dbh->selectrow_array($query)) {
      $form->{status} = 'orphaned';
    }

    $form->create_lock($myconfig, $dbh, $form->{id}, 'hr');

  }

  $query = qq|SELECT c.accno, c.description,
	      l.description AS translation
	      FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.charttype = 'A'
	      AND c.link LIKE '%AP_amount%'
	      ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{accounts} }, $ref;
  }
  $sth->finish;
  
  $dbh->disconnect;

}


sub wages {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $query = qq|SELECT w.*,
                 c.accno, c1.accno AS defer
                 FROM wage w
		 JOIN chart c ON (w.chart_id = c.id)
		 LEFT JOIN chart c1 ON (c1.id = w.defer)
		 ORDER BY 2|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_wage} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;

}


sub save_wage {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $sth;

  if (! $form->{id}) {
    my $uid = localtime;
    $uid .= $$;

    $query = qq|INSERT INTO wage (description)
                VALUES ('$uid')|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM wage
                WHERE description = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;
  }

  $form->{exempt} *= 1;
  $form->{amount} = $form->parse_amount($myconfig, $form->{amount});
  ($form->{accno}) = split /--/, $form->{accno};
  ($form->{defer}) = split /--/, $form->{defer};
  
  $query = qq|UPDATE wage SET
	      description = |.$dbh->quote($form->{description}).qq|,
	      defer =
	           (SELECT id FROM chart
	            WHERE accno = '$form->{defer}'),
	      exempt = '$form->{exempt}',
	      chart_id =
	           (SELECT id FROM chart
	            WHERE accno = '$form->{accno}'),
	      amount = $form->{amount}
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $form->remove_locks($myconfig, $dbh, 'hr');

  $dbh->commit;
  $dbh->disconnect;

}


sub delete_wage {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  # delete deduction
  my $query = qq|DELETE FROM wage
	         WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
 
  $form->remove_locks($myconfig, $dbh, 'hr');

  $dbh->commit;
  $dbh->disconnect;

}


1;

