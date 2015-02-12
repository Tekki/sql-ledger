#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2007
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Import/Export module
#
#======================================================================

package IM;



sub sales_invoice_links {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $sth;
  my $ref;
  
  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};
  
  $form->{ARAP} = "AR";

  # check for AR accounts
  $query = qq|SELECT accno FROM chart
              WHERE link = '$form->{ARAP}'|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  my %ARAP = ();
  my $default_arap_accno;

  $sth->execute || $form->dberror($query);
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ARAP{$ref->{accno}} = 1;
    $default_arap_accno ||= $ref->{accno};
  }
  
  if (! %ARAP) {
    $dbh->disconnect;
    return -1;
  }
  
  # customer
  $query = qq|SELECT vc.id, vc.name, vc.terms,
	      e.id AS employee_id, e.name AS employee,
	      c.accno AS taxaccount, a.accno AS arap_accno,
	      ad.city
	      FROM customer vc
	      JOIN address ad ON (ad.trans_id = vc.id)
	      LEFT JOIN customertax ct ON (vc.id = ct.customer_id)
	      LEFT JOIN employee e ON (e.id = vc.employee_id)
	      LEFT JOIN chart c ON (c.id = ct.chart_id)
	      LEFT JOIN chart a ON (a.id = vc.arap_accno_id)
	      WHERE customernumber = ?|;
  my $cth = $dbh->prepare($query) || $form->dberror($query);
  
  # employee
  $query = qq|SELECT id, name
              FROM employee
	      WHERE employeenumber = ?|;
  my $eth = $dbh->prepare($query) || $form->dberror($query);
  
  # parts
  $query = qq|SELECT p.id, p.unit, p.description, c.accno
              FROM parts p
              LEFT JOIN partstax pt ON (p.id = pt.parts_id)
	      LEFT JOIN chart c ON (c.id = pt.chart_id)
              WHERE partnumber = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);
  
  # department
  $query = qq|SELECT id
              FROM department
              WHERE description = ?|;
  my $dth = $dbh->prepare($query) || $form->dberror($query);

  # warehouse
  $query = qq|SELECT id
              FROM warehouse
              WHERE description = ?|;
  my $wth = $dbh->prepare($query) || $form->dberror($query);
  
  # project
  $query = qq|SELECT id
              FROM project
              WHERE projectnumber = ?|;
  my $ptth = $dbh->prepare($query) || $form->dberror($query);

  # clean out report
  my $reportid = &delete_import($dbh, $form);

  $query = qq|INSERT INTO reportvars (reportid, reportvariable, reportvalue)
              VALUES ($reportid, ?, ?)|;
  my $rth = $dbh->prepare($query) || $form->dberror($query);


  my $terms;
  my $i = 0;
  my $j = 0;
  my %customertax;
  my $sameinvoice = "\x01";
  my $parts_id;

  my @d = split /\n/, $form->{data};
  shift @d if ! $form->{mapfile};

  my @dl;
  
  for (@d) {

    @dl = &dataline($form);

    if ($#dl) {
      $i++;
      for (keys %{$form->{$form->{type}}}) {
	$form->{"${_}_$i"} = $dl[$form->{$form->{type}}->{$_}{ndx}] if defined $form->{$form->{type}}->{$_}{ndx};
      }

      if ($sameinvoice ne "$dl[$form->{$form->{type}}->{invnumber}{ndx}]$dl[$form->{$form->{type}}->{customernumber}{ndx}]") {
	
	$sameinvoice = "$dl[$form->{$form->{type}}->{invnumber}{ndx}]$dl[$form->{$form->{type}}->{customernumber}{ndx}]";
	
        # employee
	if ($dl[$form->{$form->{type}}->{employeenumber}{ndx}]) {
	  $eth->execute("$dl[$form->{$form->{type}}->{employeenumber}{ndx}]");
	  ($form->{"employee_id_$i"}, $form->{"employee_$i"}) = $eth->fetchrow_array;
	  $eth->finish;
	}
	
	$j = $i;
	$form->{ndx} .= "$i ";

	$terms = 0;
	%customertax = ();

	$cth->execute("$dl[$form->{$form->{type}}->{customernumber}{ndx}]");
	
	while ($ref = $cth->fetchrow_hashref(NAME_lc)) {
	  $arap_accno = $ref->{arap_accno};
	  $terms = $ref->{terms};
	  $form->{"customer_id_$i"} = $ref->{id};
	  $form->{"name_$i"} = $ref->{name};
	  $form->{"city_$i"} = $ref->{city};
	  $form->{"employeename_$i"} ||= $ref->{employee};
	  $form->{"employee_id_$i"} ||= $ref->{employee_id};
	  $customertax{$ref->{taxaccount}} = 1;
	}
	$cth->finish;

	if (! $form->{"customer_id_$i"}) {
	  $form->{"missing_$i"} = 1;
	  $form->{missingcustomer} .= "$dl[$form->{$form->{type}}->{invnumber}{ndx}] : $dl[$form->{$form->{type}}->{customernumber}{ndx}]\n";
	}

	if (! $ARAP{"$dl[$form->{$form->{type}}->{$form->{ARAP}}{ndx}]"}) {
	  $arap_accno ||= $default_arap_accno;
	  $form->{"$form->{ARAP}_$i"} ||= $arap_accno;
	}

        $form->{"transdate_$i"} ||= $form->current_date($myconfig);
	  
	# terms and duedate
	if ($form->{"duedate_$i"}) {
	  $form->{"terms_$i"} = $form->datediff($myconfig, $form->{"transdate_$i"}, $form->{"duedate_$i"});
	} else {
	  $form->{"terms_$i"} = $terms * 1;
	  $form->{"duedate_$i"} ||= $form->{"transdate_$i"};

	  if ($form->{"terms_$i"} > 0) {
	    $form->{"duedate_$i"} = $form->add_date($myconfig, $form->{"transdate_$i"}, $form->{"terms_$i"}, 'days');
	  }
	}
	
	$dth->execute("$dl[$form->{$form->{type}}->{department}{ndx}]");
	($form->{"department_id_$i"}) = $dth->fetchrow_array;
	$dth->finish;
	
	$wth->execute("$dl[$form->{$form->{type}}->{warehouse}{ndx}]");
	($form->{"warehouse_id_$i"}) = $wth->fetchrow_array;
	$wth->finish;

      }
      
      $form->{transdate} = $form->{"transdate_$i"};
      %tax = &taxrates("", $myconfig, $form, $dbh);

      $pth->execute("$dl[$form->{$form->{type}}->{partnumber}{ndx}]");
      
      $parts_id = 0;
      while ($ref = $pth->fetchrow_hashref(NAME_lc)) {
	$form->{"parts_id_$i"} = $ref->{id};
	for (qw(unit description)) { $form->{"${_}_$i"} ||= $ref->{$_} }
	
	$parts_id = 1;
	if ($customertax{$ref->{accno}}) {
	  $form->{"tax_$i"} += $dl[$form->{$form->{type}}->{sellprice}{ndx}] * $dl[$form->{$form->{type}}->{qty}{ndx}] * $tax{$ref->{accno}};
	}
      }
      $pth->finish;

      $ptth->execute("$dl[$form->{$form->{type}}->{projectnumber}{ndx}]");
      ($form->{"projectnumber_$i"}) = $ptth->fetchrow_array;
      $ptth->finish;
      
      $form->{"projectnumber_$i"} = qq|--$form->{"projectnumber_$i"}| if $form->{"projectnumber_$i"};
      
      if (! $parts_id) {
	$form->{"missing_$j"} = 1;
	$form->{missingpart} .= "$dl[$form->{$form->{type}}->{invnumber}{ndx}] : $dl[$form->{$form->{type}}->{partnumber}{ndx}]\n";
      }

      $form->{"total_$j"} += $dl[$form->{$form->{type}}->{sellprice}{ndx}] * $dl[$form->{$form->{type}}->{qty}{ndx}] + $form->{"tax_$i"};
      $form->{"totalqty_$j"} += $dl[$form->{$form->{type}}->{qty}{ndx}];
     
      for (qw(name customer_id city employee employee_id department_id warehouse_id paymentaccno paymentmethod transdate duedate terms parts_id unit description)) {
	$form->{$form->{type}}->{$_}{ndx} == 0;
      }
     
      for (keys %{$form->{$form->{type}}}) {
	if ($form->{"${_}_$i"}) {
	  $rth->execute("${_}_$i", $form->{"${_}_$i"});
	  $rth->finish;
	}
      }

    }

    $form->{rowcount} = $i;

  }

  $dbh->disconnect;

  chop $form->{ndx};

}


sub order_links {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $sth;
  my $ref;
  
  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};
  
  # vendor/customer
  $query = qq|SELECT vc.id, vc.name, vc.terms,
	      e.id AS employee_id, e.name AS employee,
	      c.accno AS taxaccount,
	      ad.city
	      FROM $form->{vc} vc
	      JOIN address ad ON (ad.trans_id = vc.id)
	      LEFT JOIN employee e ON (e.id = vc.employee_id)
	      LEFT JOIN $form->{vc}tax ct ON (vc.id = ct.$form->{vc}_id)
	      LEFT JOIN chart c ON (c.id = ct.chart_id)
	      WHERE $form->{vc}number = ?|;
  my $cth = $dbh->prepare($query) || $form->dberror($query);
  
  # employee
  $query = qq|SELECT id, name
              FROM employee
	      WHERE employeenumber = ?|;
  my $eth = $dbh->prepare($query) || $form->dberror($query);
  
  # parts
  $query = qq|SELECT p.id, p.unit, p.description,
              c.accno
              FROM parts p
              LEFT JOIN partstax pt ON (p.id = pt.parts_id)
	      LEFT JOIN chart c ON (c.id = pt.chart_id)
              WHERE partnumber = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);
  
  # department
  $query = qq|SELECT id
              FROM department
              WHERE description = ?|;
  my $dth = $dbh->prepare($query) || $form->dberror($query);

  # warehouse
  $query = qq|SELECT id
              FROM warehouse
              WHERE description = ?|;
  my $wth = $dbh->prepare($query) || $form->dberror($query);
  
  # project
  $query = qq|SELECT id
              FROM project
              WHERE projectnumber = ?|;
  my $ptth = $dbh->prepare($query) || $form->dberror($query);

  # clean out report
  my $reportid = &delete_import($dbh, $form);

  $query = qq|INSERT INTO reportvars (reportid, reportvariable, reportvalue)
              VALUES ($reportid, ?, ?)|;
  my $rth = $dbh->prepare($query) || $form->dberror($query);


  my $terms;
  my $i = 0;
  my $j = 0;
  my %vctax;
  my $sameorder = "\x01";
  my $parts_id;

  my @d = split /\n/, $form->{data};
  shift @d if ! $form->{mapfile};

  my @dl;
  
  for (@d) {

    @dl = &dataline($form);

    if ($#dl) {
      $i++;
      for (keys %{$form->{$form->{type}}}) {
	$form->{"${_}_$i"} = $dl[$form->{$form->{type}}->{$_}{ndx}] if defined $form->{$form->{type}}->{$_}{ndx};
      }

      if ($sameorder ne qq|$dl[$form->{$form->{type}}->{ordnumber}{ndx}]$dl[$form->{$form->{type}}->{"$form->{vc}number"}{ndx}]|) {
	
	$sameorder = qq|$dl[$form->{$form->{type}}->{ordnumber}{ndx}]$dl[$form->{$form->{type}}->{"$form->{vc}number"}{ndx}]|;
	
        # employee
	if ($dl[$form->{$form->{type}}->{employeenumber}{ndx}]) {
	  $eth->execute("$dl[$form->{$form->{type}}->{employeenumber}{ndx}]");
	  ($form->{"employee_id_$i"}, $form->{"employee_$i"}) = $eth->fetchrow_array;
	  $eth->finish;
	}
	
	$j = $i;
	$form->{ndx} .= "$i ";

	$terms = 0;
	%vctax = ();

	$cth->execute(qq|$dl[$form->{$form->{type}}->{"$form->{vc}number"}{ndx}]|);
	
	while ($ref = $cth->fetchrow_hashref(NAME_lc)) {
	  $terms = $ref->{terms};
	  $form->{"$form->{vc}_id_$i"} = $ref->{id};
	  $form->{"name_$i"} = $ref->{name};
	  $form->{"city_$i"} = $ref->{city};
	  $form->{"employeename_$i"} ||= $ref->{employee};
	  $form->{"employee_id_$i"} ||= $ref->{employee_id};
	  $vctax{$ref->{taxaccount}} = 1;
	}
	$cth->finish;

	
	if (! $form->{"$form->{vc}_id_$i"}) {
	  $form->{"missing_$i"} = 1;
	  $form->{"missing$form->{vc}"} .= qq|$dl[$form->{$form->{type}}->{ordnumber}{ndx}] : $dl[$form->{$form->{type}}->{"$form->{vc}number"}{ndx}]\n|;
	}

        $form->{"transdate_$i"} ||= $form->current_date($myconfig);
	  
	# terms and reqdate
	if ($form->{"reqdate_$i"}) {
	  $form->{"terms_$i"} = $form->datediff($myconfig, $form->{"transdate_$i"}, $form->{"reqdate_$i"});
	} else {
	  $form->{"terms_$i"} = $terms * 1;
	  $form->{"reqdate_$i"} ||= $form->{"transdate_$i"};

	  if ($form->{"terms_$i"} > 0) {
	    $form->{"reqdate_$i"} = $form->add_date($myconfig, $form->{"transdate_$i"}, $form->{"terms_$i"}, 'days');
	  }
	}
	
	$dth->execute("$dl[$form->{$form->{type}}->{department}{ndx}]");
	($form->{"department_id_$i"}) = $dth->fetchrow_array;
	$dth->finish;
	
	$wth->execute("$dl[$form->{$form->{type}}->{warehouse}{ndx}]");
	($form->{"warehouse_id_$i"}) = $wth->fetchrow_array;
	$wth->finish;

      }
      
      $form->{transdate} = $form->{"transdate_$i"};
      %tax = &taxrates("", $myconfig, $form, $dbh);

      $pth->execute("$dl[$form->{$form->{type}}->{partnumber}{ndx}]");

      
      $parts_id = 0;
      while ($ref = $pth->fetchrow_hashref(NAME_lc)) {
	$form->{"parts_id_$i"} = $ref->{id};
	for (qw(unit description)) { $form->{"${_}_$i"} ||= $ref->{$_} }

	$parts_id = 1;
	if ($vctax{$ref->{accno}}) {
	  $form->{"tax_$i"} += $dl[$form->{$form->{type}}->{sellprice}{ndx}] * $dl[$form->{$form->{type}}->{qty}{ndx}] * $tax{$ref->{accno}};
	}
      }
      $pth->finish;

      $ptth->execute("$dl[$form->{$form->{type}}->{projectnumber}{ndx}]");
      ($form->{"projectnumber_$i"}) = $ptth->fetchrow_array;
      $ptth->finish;
      
      $form->{"projectnumber_$i"} = qq|--$form->{"projectnumber_$i"}| if $form->{"projectnumber_$i"};
      
      if (! $parts_id) {
	$form->{"missing_$j"} = 1;
	$form->{missingpart} .= "$dl[$form->{$form->{type}}->{ordnumber}{ndx}] : $dl[$form->{$form->{type}}->{partnumber}{ndx}]\n";
      }

      $form->{"total_$j"} += $dl[$form->{$form->{type}}->{sellprice}{ndx}] * $dl[$form->{$form->{type}}->{qty}{ndx}] + $form->{"tax_$i"};
     
      for (qw(name city employee employee_id department_id warehouse_id transdate reqdate terms parts_id unit description)) {
	$form->{$form->{type}}->{$_}{ndx} == 0;
      }
      $form->{$form->{type}}->{"$form->{vc}_id"}{ndx} == 0;
     
      for (keys %{$form->{$form->{type}}}) {
	if ($form->{"${_}_$i"}) {
	  $rth->execute("${_}_$i", $form->{"${_}_$i"});
	  $rth->finish;
	}
      }

    }

    $form->{rowcount} = $i;

  }

  $dbh->disconnect;

  chop $form->{ndx};

}



sub delete_import {
  my ($dbh, $form) = @_;

  my $query = qq|SELECT reportid FROM report
                 WHERE reportcode = '$form->{reportcode}'
	         AND login = '$form->{login}'|;
  my ($reportid) = $dbh->selectrow_array($query);

  if (! $reportid) {
    $query = qq|INSERT INTO report (reportcode, login)
                VALUES ('$form->{reportcode}', '$form->{login}')|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT reportid FROM report
                WHERE reportcode = '$form->{reportcode}'
		AND login = '$form->{login}'|;
    ($reportid) = $dbh->selectrow_array($query); 
  }

  $query = qq|DELETE FROM reportvars
              WHERE reportid = $reportid|;
  $dbh->do($query) || $form->dberror($query);

  $reportid;

}


sub taxrates {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  # get tax rates
  my $query = qq|SELECT c.accno, t.rate
              FROM chart c
	      JOIN tax t ON (c.id = t.chart_id)
	      WHERE c.link LIKE '%$form->{ARAP}_tax%'
	      AND (t.validto >= ? OR t.validto IS NULL)
	      ORDER BY c.accno, t.validto|;
  my $sth = $dbh->prepare($query);
  $sth->execute($form->{transdate}) || $form->dberror($query);
  
  my %tax = ();
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    if (not exists $tax{$ref->{accno}}) {
      $tax{$ref->{accno}} = $ref->{rate};
    }
  }
  $sth->finish;
  
  %tax;
  
}


sub import_sales_invoice {
  my ($self, $myconfig, $form, $ndx) = @_;
  
  use SL::IS;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $ref;

  $query = qq|SELECT reportid FROM report
              WHERE reportcode = '$form->{reportcode}'
	      AND login = '$form->{login}'|;
  my ($reportid) = $dbh->selectrow_array($query);

  $query = qq|SELECT * FROM reportvars
              WHERE reportid = $reportid
	      AND reportvariable LIKE ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  # retrieve invoice
  my $i = 1;
  my $j;
  for $j (@{$ndx}) {
    $sth->execute("%\\_$j") || $form->dberror($query);
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{reportvariable} =~ s/_$j/_$i/;
      $form->{$ref->{reportvariable}} = $ref->{reportvalue};
    }
    $sth->finish;

    $form->{"id_$i"} = $form->{"parts_id_$i"};

    for (qw(qty discount)) { $form->{"${_}_$i"} = $form->format_amount($myconfig, $form->{"${_}_$i"}) }
    $form->{"sellprice_$i"} = $form->format_amount($myconfig, $form->{"sellprice_$i"}, $form->{precision});
    
    $i++;
  }
  $form->{rowcount} = $i;

  for (qw(invnumber ordnumber quonumber ponumber transdate name customer_id datepaid duedate shippingpoint shipvia waybill terms notes intnotes curr exchangerate language_code cashdiscount discountterms AR taxincluded AR_paid_1 paymentmethod_1 paid_1 datepaid_1 shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail)) { $form->{$_} = $form->{"${_}_1"} }
  $form->{description} = $form->{"invoicedescription_1"};
  $form->{customer} = $form->{"name_1"};

  # check if invoice exists
  if ($form->{invnumber}) {
    my $paid;
    $query = qq|SELECT id, paid
		FROM ar
		WHERE invnumber = '$form->{invnumber}'|;
    ($form->{id}, $paid) = $dbh->selectrow_array($query);

    if ($form->{id}) {
      $form->{updated} = "$form->{invnumber}";
    }
    
    if ($paid) {
      $form->{rejected} = "$form->{invnumber}";
      delete $form->{updated};
      $dbh->disconnect;
      return 1;
    }
  }
 
  $query = qq|SELECT curr
              FROM curr
	      ORDER BY rn|;
  ($form->{defaultcurrency}) = $dbh->selectrow_array($query);
  
  $form->{curr} ||= $form->{defaultcurrency};
  $form->{currency} = $form->{curr};

  my $language_code;
  my $paymentaccno;
  my $paymentmethod_id;

  if ($form->{paymentmethod_1}) {
    $query = qq|SELECT id
                FROM paymentmethod
		WHERE description = '$form->{paymentmethod_1}'|;
    ($paymentmethod_id) = $dbh->selectrow_array($query);

    $form->{paymentmethod_1} .= "--$paymentmethod_id";
  }

  $query = qq|SELECT c.customernumber, c.language_code, a.city,
              ch.accno, c.paymentmethod_id
              FROM customer c
	      JOIN address a ON (a.trans_id = c.id)
	      LEFT JOIN chart ch ON (ch.id = c.payment_accno_id)
	      LEFT JOIN paymentmethod pm ON (pm.id = c.paymentmethod_id)
	      WHERE c.id = $form->{customer_id}|;
  ($form->{customernumber}, $language_code, $form->{city}, $paymentaccno, $paymentmethod_id) = $dbh->selectrow_array($query);

  $form->{language_code} ||= $language_code;
  $form->{AR_paid_1} ||= $paymentaccno;
  $form->{paidaccounts} = 1;
  $form->{paymentmethod_1} ||= "--$paymentmethod_id";

  $query = qq|SELECT c.accno, t.rate
              FROM customertax ct
              JOIN chart c ON (c.id = ct.chart_id)
	      JOIN tax t ON (t.chart_id = c.id)
              WHERE ct.customer_id = $form->{customer_id}
	      AND (validto > '$form->{transdate}' OR validto IS NULL)
	      ORDER BY t.validto DESC|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;

  $form->{taxaccounts} = "";
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{taxaccounts} .= "$ref->{accno} ";
    $form->{"$ref->{accno}_rate"} = $ref->{rate};
  }
  $sth->finish;
  chop $form->{taxaccounts};

  $form->{employee} = qq|--$form->{"employee_id_1"}|;
  $form->{department} = qq|--$form->{"department_id_1"}|;
  $form->{warehouse} = qq|--$form->{"warehouse_id_1"}|;

  # post invoice
  my $rc = IS->post_invoice($myconfig, $form, $dbh);

  $dbh->disconnect;

  $rc;

}


sub import_order {
  my ($self, $myconfig, $form, $ndx) = @_;
  
  use SL::OE;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $ref;

  $query = qq|SELECT reportid FROM report
              WHERE reportcode = '$form->{reportcode}'
	      AND login = '$form->{login}'|;
  my ($reportid) = $dbh->selectrow_array($query);

  $query = qq|SELECT * FROM reportvars
              WHERE reportid = $reportid
	      AND reportvariable LIKE ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  # retrieve order
  my $i = 1;
  my $j;
  for $j (@{$ndx}) {
    $sth->execute("%\\_$j") || $form->dberror($query);
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{reportvariable} =~ s/_$j/_$i/;
      $form->{$ref->{reportvariable}} = $ref->{reportvalue};
    }
    $sth->finish;

    $form->{"id_$i"} = $form->{"parts_id_$i"};

    for (qw(qty)) { $form->{"${_}_$i"} = $form->format_amount($myconfig, $form->{"${_}_$i"}) }
    $form->{"sellprice_$i"} = $form->format_amount($myconfig, $form->{"sellprice_$i"}, $form->{precision});
    
    $i++;
  }
  $form->{rowcount} = $i;

  for (qw(ordnumber quonumber ponumber transdate name reqdate shippingpoint shipvia waybill terms notes intnotes curr exchangerate language_code taxincluded shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail)) { $form->{$_} = $form->{"${_}_1"} }
  $form->{"$form->{vc}_id"} = $form->{"$form->{vc}_id_1"};
  $form->{description} = $form->{"orderdescription_1"};
  $form->{"$form->{vc}"} = $form->{"name_1"};

  # check if order exists
  if ($form->{ordnumber}) {
    $query = qq|SELECT id
		FROM oe
		WHERE ordnumber = '$form->{ordnumber}'|;
    ($form->{id}) = $dbh->selectrow_array($query);

    if ($form->{id}) {
      $form->{updated} = "$form->{ordnumber}";
    }
    
  }
 
  $query = qq|SELECT curr
              FROM curr
	      ORDER BY rn|;
  ($form->{defaultcurrency}) = $dbh->selectrow_array($query);
  
  $form->{curr} ||= $form->{defaultcurrency};
  $form->{currency} = $form->{curr};

  my $language_code;

  $query = qq|SELECT c.$form->{vc}number, c.language_code, a.city
              FROM $form->{vc} c
	      JOIN address a ON (a.trans_id = c.id)
	      WHERE c.id = $form->{"$form->{vc}_id"}|;
  ($form->{"$form->{vc}number"}, $language_code, $form->{city}) = $dbh->selectrow_array($query);

  $form->{language_code} ||= $language_code;

  $query = qq|SELECT c.accno, t.rate
              FROM $form->{vc}tax ct
              JOIN chart c ON (c.id = ct.chart_id)
	      JOIN tax t ON (t.chart_id = c.id)
              WHERE ct.$form->{vc}_id = $form->{"$form->{vc}_id"}
	      AND (validto > '$form->{transdate}' OR validto IS NULL)
	      ORDER BY t.validto DESC|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;

  $form->{taxaccounts} = "";
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{taxaccounts} .= "$ref->{accno} ";
    $form->{"$ref->{accno}_rate"} = $ref->{rate};
  }
  $sth->finish;
  chop $form->{taxaccounts};

  $form->{employee} = qq|--$form->{"employee_id_1"}|;
  $form->{department} = qq|--$form->{"department_id_1"}|;
  $form->{warehouse} = qq|--$form->{"warehouse_id_1"}|;

  # save order
  my $rc = OE->save($myconfig, $form, $dbh);

  $dbh->disconnect;

  $rc;

}


sub import_vc {
  my ($self, $myconfig, $form) = @_;
  
  use SL::CT;
  
  my $newform = new Form;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $ref;
  my $new;

  my $ARAP = ($form->{type} eq 'customer') ? "AR" : "AP";

  $query = qq|SELECT reportid FROM report
              WHERE reportcode = '$form->{reportcode}'
	      AND login = '$form->{login}'|;
  my ($reportid) = $dbh->selectrow_array($query);

  $query = qq|SELECT * FROM reportvars
              WHERE reportid = $reportid
	      AND reportvariable LIKE ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT curr
              FROM curr
	      ORDER BY rn|;
  ($form->{defaultcurrency}) = $dbh->selectrow_array($query);

  $query = qq|SELECT id FROM $form->{type}
              WHERE $form->{type}number = ?|;
  my $cth = $dbh->prepare($query) || $form->dberror($query);

  my %link = ( business => { fld => description },
               pricegroup => { fld => pricegroup },
	       paymentmethod => { fld => description },
	       employee => { fld => name }
	     );

  for my $i (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$i"}) {

      for (keys %$newform) { delete $newform->{$_} }

      $new = 1;
      $newform->{db} = $form->{type};
      
      $sth->execute("%\\_$i");
      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	$ref->{reportvariable} =~ s/_\d+//;
	$newform->{$ref->{reportvariable}} = $ref->{reportvalue};
      }
      $sth->finish;

      $newform->{curr} ||= $form->{defaultcurrency};
      $newform->{arap_accno} = $newform->{$ARAP};
      
      if ($newform->{"$newform->{db}number"}) {
	$cth->execute($newform->{"$newform->{db}number"});
	($newform->{id}) = $cth->fetchrow_array;
	$cth->finish;
      }

      if ($newform->{id}) {
	$new = 0;
	for (qw(address contact)) {
	  $query = qq|SELECT id FROM $_
		      WHERE trans_id = $newform->{id}|;
	  ($newform->{"${_}id"}) = $dbh->selectrow_array($query);
	}
      }

      for (qw(employee business pricegroup paymentmethod)) {
	$query = qq|SELECT id FROM $_
		    WHERE $link{$_}{fld} = '$newform->{$_}'|;
	($var) = $dbh->selectrow_array($query);
	$newform->{$_} = "--$var";
      }

      for (split / /, $newform->{taxaccounts}) { $newform->{"tax_$_"} = 1 }

      CT->save($myconfig, $newform, $dbh);
      
      if ($new) {
	$form->{added} .= qq|$newform->{"$newform->{db}number"}, $newform->{name}\n|;
      } else {
	$form->{updated} .= qq|$newform->{"$newform->{db}number"}, $newform->{name}\n|;
      }

    }
    $i++;
  }

  $dbh->disconnect;

}


sub import_item {
  my ($self, $myconfig, $form) = @_;
  
  use SL::IC;
  
  my $newform = new Form;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $ref;
  my $new;
  my $found;
  my $var;

  $query = qq|SELECT current_date
              FROM defaults
	      WHERE fldname = 'version'|;
  my ($today) = $dbh->selectrow_array($query);
  
  $query = qq|SELECT reportid FROM report
              WHERE reportcode = '$form->{reportcode}'
	      AND login = '$form->{login}'|;
  my ($reportid) = $dbh->selectrow_array($query);
  
  $query = qq|SELECT * FROM reportvars
              WHERE reportid = $reportid
	      AND reportvariable LIKE ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT p.id, pg.partsgroup,
              c1.accno AS inventory_accno,
	      c2.accno AS income_accno,
	      c3.accno AS expense_accno
              FROM parts p
	      LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
	      LEFT JOIN chart c1 ON (c1.id = p.inventory_accno_id)
	      LEFT JOIN chart c2 ON (c2.id = p.income_accno_id)
	      LEFT JOIN chart c3 ON (c3.id = p.expense_accno_id)
              WHERE p.partnumber = ?
	      ORDER BY p.id DESC|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);


  $query = qq|SELECT id FROM partsgroup
	      WHERE partsgroup = ?|;
  my $gsth = $dbh->prepare($query) || $form->dberror($query);
 
  $query = qq|INSERT INTO partsgroup (partsgroup)
              VALUES (?)|;
  my $gath = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT id FROM partsgroup
	      WHERE code = ?|;
  my $csth = $dbh->prepare($query) || $form->dberror($query);
 
  $query = qq|INSERT INTO partsgroup (partsgroup,code)
              VALUES (?,?)|;
  my $cath = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT * FROM makemodel
	      WHERE parts_id = ?|;
  my $makesth = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT * FROM partscustomer
	      WHERE parts_id = ?|;
  my $pcsth = $dbh->prepare($query) || $form->dberror($query);
 
  $query = qq|SELECT * FROM partsvendor
	      WHERE parts_id = ?|;
  my $pvsth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT id FROM vendor
	      WHERE vendornumber = ?|;
  my $vsth = $dbh->prepare($query) || $form->dberror($query);
  
  my %makemodel;
  my %partsvendor;
 
  my %defaults = $form->get_defaults($dbh, \@{['%_accno_id']});
  for (qw(inventory income expense)) {
    $query = qq|SELECT accno FROM chart
                WHERE id = $defaults{"${_}_accno_id"}|;
    ($form->{"IC_$_"}) = $dbh->selectrow_array($query);
  }

  $query = qq|SELECT curr FROM curr
              ORDER BY rn|;
  my ($defaultcurrency) = $dbh->selectrow_array($query);
  
  $query = qq|SELECT accno FROM chart
              WHERE link LIKE '%IC_tax%'|;
  my $tth = $dbh->prepare($query) || $form->dberror($query);
  $tth->execute || $form->dberror($query);
  
  $form->{taxaccounts} = "";
  while ($ref = $tth->fetchrow_hashref(NAME_lc)) {
    $form->{taxaccounts} .= "$ref->{accno} ";
  }
  $tth->finish;
  chop $form->{taxaccounts};

  my @acclink = ();
  if ($form->{type} eq 'part') {
    @acclink = qw(inventory income expense);
  }
  if ($form->{type} eq 'service') {
    @acclink = qw(income expense);
  }
  if ($form->{type} eq 'labor') {
    @acclink = qw(inventory expense);
  }

  my %accno;
  my @accno;
  $query = qq|SELECT accno, link FROM chart
              WHERE link LIKE '%IC%'|;
  $tth = $dbh->prepare($query) || $form->dberror($query);
  $tth->execute || $form->dberror($query);
  
  while ((@accno) = $tth->fetchrow_array) {
    $accno{$accno[0]} = 1 unless $accno[1] =~ /tax/;
  }
  $tth->finish;

  my $partsgroup_id;
  
  my $i;
  my $j;
  my $sep = "\x01";

  for $i (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$i"}) {

      for (keys %$newform) { delete $newform->{$_} }
      %makemodel = ();
      %partsvendor = ();

      $new = 1;
      $newform->{item} = $form->{type};

      $sth->execute("%\\_$i");
      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	$ref->{reportvariable} =~ s/_(\d+)//;
	if ($1 == $i) {
	  $newform->{$ref->{reportvariable}} = $ref->{reportvalue};
	}
      }
      $sth->finish;

      for (@acclink) {
	$newform->{"IC_$_"} = $newform->{"${_}_accno"};
	$newform->{"IC_$_"} ||= $form->{"IC_$_"};
	$newform->{"IC_$_"} = $form->{"IC_$_"} unless $accno{qq|$newform->{"IC_$_"}|};
      }
      
      $newform->{taxaccounts} ||= $form->{taxaccounts};
      
      for (split / /, $newform->{taxaccounts}) {
	$newform->{"IC_tax_$_"} = 1;
      }

      $newform->{priceupdate} ||= $today;

      if ($newform->{partnumber}) {
	$pth->execute($newform->{partnumber});
	$ref = $pth->fetchrow_hashref(NAME_lc);

        $newform->{id} = $ref->{id};
	
	if ($newform->{id}) {
	  $new = 0;
	  $newform->{orphaned} = IC->orphaned($dbh, \%$newform);

	  if (! $newform->{orphaned}) {
	    for (@acclink) {
	      if ($ref->{"${_}_accno"} ne $newform->{"${_}_accno"}) {
		$newform->{changeup} = 1;
		$new = 1;
		last;
	      }
	    }
	  }
	  
	}

	$pth->finish;
      }


      if ($newform->{id}) {

        # makes and models
	$makesth->execute($newform->{id});
	while ($ref = $makesth->fetchrow_hashref(NAME_lc)) {
	  $makemodel{"$ref->{make}$sep$ref->{model}"} = $ref;
	}
	$makesth->finish;
	
	# partscustomer, keep
	$pcsth->execute($newform->{id});

        $j = 1;
	while ($ref = $pcsth->fetchrow_hashref(NAME_lc)) {
	  
	  for $var (qw(customer pricegroup)) { $newform->{"${var}_$j"} = qq|--$ref->{"${var}_id"}| }
	  for $var (qw(pricebreak validfrom validto)) { $newform->{"${var}_$j"} = $ref->{$var} }
	  $newform->{"customercurr_$j"} = $ref->{curr};
	  $newform->{"customerprice_$j"} = $ref->{sellprice};
	  
	  $newform->{customer_rows} = $j++;
	}
	$pcsth->finish;

	# partsvendor, keep old ones and replace
	$pvsth->execute($newform->{id});
	while ($ref = $pvsth->fetchrow_hashref(NAME_lc)) {
	  $partsvendor{"$ref->{vendor_id}$sep$ref->{partnumber}"} = $ref;
	}
	$pvsth->finish;

      }

      $partsgroup_id = 0;
      
      # link for partsgroup
      if ($newform->{partsgroup}) {
	
	$gsth->execute($newform->{partsgroup});
	($partsgroup_id) = $gsth->fetchrow_array;
	$gsth->finish;

	if ($newform->{code} eq "") {
	  if (!$partsgroup_id) {
	    $gath->execute($newform->{partsgroup});
	    $gath->finish;
	  }
	}
	
	if (!$partsgroup_id) {
	  $gsth->execute($newform->{partsgroup});
	  ($partsgroup_id) = $gsth->fetchrow_array;
	  $gsth->finish;
	}
      }


      # if there is a partsgroup code
      if ($newform->{code}) {
	if (!$partsgroup_id) {
	  $csth->execute($newform->{code});
	  ($partsgroup_id) = $csth->fetchrow_array;
	  $csth->finish;

	  if (!$partsgroup_id) {
	    $partsgroup = $newform->{partsgroup} || $newform->{code};

	    $cath->execute($partsgroup, $newform->{code});
	    $cath->finish;
	  }

          if (!$partsgroup_id) {
	    $csth->execute($newform->{code});
	    ($partsgroup_id) = $csth->fetchrow_array;
	    $csth->finish;
	  }
	}
      }
      
      $newform->{partsgroup} = "--$partsgroup_id" if $partsgroup_id;


      # make and model
      if ($newform->{make} || $newform->{model}) {
	for $var (qw(make model)) { $makemodel{"$newform->{make}$sep$newform->{model}"}{$var} = $newform->{$var} }
      }
     
      $j = 1;
      for (keys %makemodel) {
	$newform->{"make_$j"} = $makemodel{$_}{make};
	$newform->{"model_$j"} = $makemodel{$_}{model};
	$newform->{makemodel_rows} = ++$j;
      }
    
      
      if ($newform->{vendornumber}) {

	$vsth->execute($newform->{vendornumber});
	($var) = $vsth->fetchrow_array;
	$vsth->finish;
	
	if ($var) {
	  $partsvendor{"$var$sep$newform->{vendorpartnumber}"} = {
	                 vendor_id => $var,
			 partnumber => $newform->{vendorpartnumber},
			 leadtime => $newform->{leadtime},
			 lastcost => $newform->{lastcost},
			 curr => $newform->{vendorcurr}
		       };
	  $partsvendor{"$var$sep$newform->{vendorpartnumber}"}{curr} ||= $defaultcurrency;
	} else {
	  $form->{missingvendor} .= "\n$newform->{partnumber}, $newform->{description} : $newform->{vendornumber}";
	}
	
	$j = 1;
	for (keys %partsvendor) {
	  $newform->{"vendor_$j"} = qq|--$partsvendor{$_}{vendor_id}|;
	  $newform->{"vendorcurr_$j"} = $partsvendor{$_}{curr};
	  for $var (qw(partnumber lastcost leadtime)) { $newform->{"${var}_$j"} = $partsvendor{$_}{$var} }
	  $newform->{vendor_rows} = $j++;
	}
      }
    
    
      for (split / /, $newform->{taxaccounts}) { $newform->{"tax_$_"} = 1 }

      IC->save($myconfig, \%$newform, $dbh);
      
      if ($new) {
	$form->{added} .= qq|$newform->{partnumber}, $newform->{description}\n|;
      } else {
	$form->{updated} .= qq|$newform->{partnumber}, $newform->{description}\n|;
      }

    }
    $i++;
  }

  $dbh->disconnect;

}


sub import_coa {
  my ($self, $myconfig, $form) = @_;
  
  use SL::AM;
  
  my $newform = new Form;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $ref;

  $query = qq|SELECT reportid FROM report
              WHERE reportcode = '$form->{reportcode}'
	      AND login = '$form->{login}'|;
  my ($reportid) = $dbh->selectrow_array($query);
  
  $query = qq|SELECT * FROM reportvars
              WHERE reportid = $reportid
	      AND reportvariable LIKE ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT id
              FROM chart
	      WHERE accno = ?|;
  my $cth = $dbh->prepare($query) || $form->dberror($query);
	      
  for my $i (1 .. $form->{rowcount}) {

    for (keys %$newform) { delete $newform->{$_} }

    $sth->execute("%\\_$i");
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{reportvariable} =~ s/_(\d+)//;
      if ($1 == $i) {
	$newform->{$ref->{reportvariable}} = $ref->{reportvalue};
      }
    }
    $sth->finish;

    $cth->execute("$newform->{accno}");
    ($newform->{id}) = $cth->fetchrow_array;
    $cth->finish;

    $newform->{charttype} ||= "A";
    $newform->{category} ||= "A";

    for (split ':', $newform->{link}) { $newform->{$_} = $_ }
    
    if ($newform->{id}) {
      $form->{updated} .= qq|$newform->{accno}, $newform->{description}\n|;
    } else {
      $form->{added} .= qq|$newform->{accno}, $newform->{description}\n|;
    }

    AM->save_account($myconfig, \%$newform, $dbh);

  }

  $dbh->disconnect;

}



sub import_group {
  my ($self, $myconfig, $form) = @_;
  
  my $newform = new Form;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $ref;
  my $id;

  $query = qq|SELECT reportid FROM report
              WHERE reportcode = '$form->{reportcode}'
	      AND login = '$form->{login}'|;
  my ($reportid) = $dbh->selectrow_array($query);
  
  $query = qq|SELECT * FROM reportvars
              WHERE reportid = $reportid
	      AND reportvariable LIKE ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT id FROM partsgroup
	      WHERE partsgroup = ?|;
  my $gsth = $dbh->prepare($query) || $form->dberror($query);
 
  $query = qq|INSERT INTO partsgroup (partsgroup, pos)
              VALUES (?,?)|;
  my $gath = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|UPDATE partsgroup SET
              pos = ?
	      WHERE id = ?|;
  my $guth = $dbh->prepare($query) || $form->dberror($query);
  

  for my $i (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$i"}) {

      for (keys %$newform) { delete $newform->{$_} }
      
      $sth->execute("%\\_$i");
      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	$ref->{reportvariable} =~ s/_\d+//;
	$newform->{$ref->{reportvariable}} = $ref->{reportvalue};
      }
      $sth->finish;

      $id = "";
      $gsth->execute("$newform->{partsgroup}");
      ($id) = $gsth->fetchrow_array;
      $gsth->finish;

      $newform->{pos} = 1;

      if ($id) {
	$guth->execute("$newform->{pos}",$id);
	$guth->finish;
	$form->{updated} .= qq|$newform->{partsgroup}\n|;
      } else {
	$gath->execute("$newform->{partsgroup}","$newform->{pos}");
	$gath->finish;
	$form->{added} .= qq|$newform->{partsgroup}\n|;
      }
    }
    $i++;
  }

  $dbh->disconnect;

}


sub prepare_import_data {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $sth;
  my $ref;

  # clean out report
  my $reportid = &delete_import($dbh, $form);

  $query = qq|DELETE FROM reportvars
              WHERE reportid = $reportid|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|INSERT INTO reportvars (reportid, reportvariable, reportvalue)
              VALUES ($reportid, ?, ?)|;
  my $rth = $dbh->prepare($query) || $form->dberror($query);

  my $i = 0;
  my $j = 0;

  my @d = split /\n/, $form->{data};
  shift @d if ! $form->{mapfile};

  my @dl;

  for (@d) {

    @dl = &dataline($form);

    if ($#dl) {
      $i++;
      for (keys %{$form->{$form->{type}}}) {
	if (defined $form->{$form->{type}}->{$_}{ndx}) {
	  $form->{"${_}_$i"} = $dl[$form->{$form->{type}}->{$_}{ndx}];
	  if ($form->{"${_}_$i"}) {
	    $rth->execute("${_}_$i", $form->{"${_}_$i"});
	    $rth->finish;
	  }
	}
      }
    }
    $form->{rowcount} = $i;

  }

  $dbh->disconnect;

}



sub paymentaccounts {
  my ($self, $myconfig, $form) = @_;

  $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['address']});
  $form->{address} = $defaults{address};
  
  my $query = qq|SELECT c.accno, c.description, c.link,
                 l.description AS translation
		 FROM chart c
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		 WHERE c.link LIKE '%_paid'
		 ORDER BY c.accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{all_paymentaccount} }, $ref;
  }
  $sth->finish;

  $form->{currencies} = $form->get_currencies($dbh, $myconfig);

  $query = qq|SELECT *
              FROM paymentmethod
	      ORDER BY 2|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_paymentmethod} }, $ref;
  }
  $sth->finish;
  
  $dbh->disconnect;
  
}


sub payment_links {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $ref;
  
  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = ($defaults{precision}) ? $defaults{precision} : 2;
  
  $query = qq|SELECT c.name, c.customernumber AS companynumber, ad.city,
              a.id, a.invnumber, a.description, a.exchangerate,
	      (a.amount - a.paid) / a.exchangerate AS amount,
	      a.transdate, a.paymentmethod_id, 'customer' AS vc,
	      'ar' AS arap
	      FROM ar a
	      JOIN customer c ON (a.customer_id = c.id)
	      JOIN address ad ON (ad.trans_id = c.id)
	      WHERE a.amount != a.paid
	      UNION
	      SELECT c.name, c.vendornumber AS companynumber, ad.city,
	      a.id, a.invnumber, a.description, a.exchangerate,
	      (a.amount - a.paid) / a.exchangerate AS amount,
	      a.transdate, a.paymentmethod_id, 'vendor' AS vc,
	      'ap' AS arap
	      FROM ap a
	      JOIN vendor c ON (a.vendor_id = c.id)
	      JOIN address ad ON (ad.trans_id = c.id)
	      WHERE a.amount != a.paid|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my %amount;
  my $amount;

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $amount = $form->format_amount($myconfig, $ref->{amount}, $form->{precision});
    push @{ $amount{$amount} }, $ref;
  }
  $sth->finish;
	
  # retrieve invoice by dcn
  $query = qq|SELECT c.name, c.customernumber AS companynumber, ad.city,
              a.id, a.invnumber, a.description, a.dcn,
	      a.paymentmethod_id, 'customer' AS vc, 'ar' AS arap
	      FROM ar a
	      JOIN customer c ON (a.customer_id = c.id)
	      JOIN address ad ON (ad.trans_id = c.id)
	      WHERE a.dcn = ?
	      UNION
	      SELECT c.name, c.vendornumber AS companynumber, ad.city,
              a.id, a.invnumber, a.description, a.dcn,
	      a.paymentmethod_id, 'vendor' AS vc, 'ap' AS arap
	      FROM ap a
	      JOIN vendor c ON (a.vendor_id = c.id)
	      JOIN address ad ON (ad.trans_id = c.id)
	      WHERE a.dcn = ?
	      |;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT exchangerate FROM exchangerate
	      WHERE curr = '$form->{currency}'
	      AND transdate = ?|;
  my $eth = $dbh->prepare($query) || $form->dberror($query);
  
  my $i = 0;
  my $j = 0;

  my $vc;

  my @d = split /\n/, $form->{data};
  shift @d if ! $form->{mapfile};

  my @dl;
  my $am;

  for (@d) {

    @dl = &dataline($form);

    if ($#dl) {

      $amount = $form->format_amount($myconfig, $dl[$form->{$form->{type}}->{credit}{ndx}] - $dl[$form->{$form->{type}}->{debit}{ndx}], $form->{precision});
      $am = 1;

      $i++;

      for (keys %{$form->{$form->{type}}}) {
	if (defined $form->{$form->{type}}->{$_}{ndx}) {
	  $dl[$form->{$form->{type}}->{$_}{ndx}] =~ s/(^"|"$)//g;
	  $form->{"${_}_$i"} = $dl[$form->{$form->{type}}->{$_}{ndx}];
	}
      }
      $form->{"amount_$i"} = $amount;
      
      # dcn
      if (defined $form->{$form->{type}}->{dcn}{ndx}) {
	$am = 0;
	$sth->execute("$dl[$form->{$form->{type}}->{dcn}{ndx}]", "$dl[$form->{$form->{type}}->{dcn}{ndx}]");
	$ref = $sth->fetchrow_hashref(NAME_lc);

	if ($ref->{invnumber}) {
	  $vc = $ref->{vc};
	  $ref->{outstanding} = $ref->{amount};
	  for (qw(id invnumber description name companynumber vc arap city paymentmethod_id outstanding)) { $form->{"${_}_$i"} = $ref->{$_} }
	}
	$sth->finish;
      } else {
	$am = 1;
      }
      
      if ($am) {
	$vc = $amount{$amount}->[0]->{vc};
	
	for (qw(id invnumber description name companynumber vc arap city paymentmethod_id)) { $form->{"${_}_$i"} = $amount{$amount}->[0]->{$_} }
	$form->{"outstanding_$i"} = $dl[$form->{$form->{type}}->{credit}{ndx}] - $dl[$form->{$form->{type}}->{debit}{ndx}];

	shift @{ $amount{$amount} };
      }

      # get exchangerate
      if ($form->{currency} ne $form->{defaultcurrency}) {
	$eth->execute($dl[$form->{$form->{type}}->{datepaid}{ndx}]);
	($form->{"exchangerate_$i"}) = $eth->fetchrow_array;
	$eth->finish;
      }

    }

    $form->{rowcount} = $i;

  }

  $dbh->disconnect;

}


sub dataline {
  my ($form) = @_;

  my @dl = ();
  my $string = 0;
  my $chr = "";
  my $m = 0;

  chomp;

  if ($form->{tabdelimited}) {
    @dl = split /\t/, $_;
  } else {
    if ($form->{stringsquoted}) {
      foreach $chr (split //, $_) {
	if ($chr eq '"') {
	  if (! $string) {
	    $string = 1;
	    next;
	  }
	}
	if ($string) {
	  if ($chr eq '"') {
	    $string = 0;
	    next;
	  }
	}
	if ($chr eq $form->{delimiter}) {
	  if (! $string) {
	    $m++;
	    next;
	  }
	}
	$dl[$m] .= $chr;
      }
    } else {
      @dl = split /$form->{delimiter}/, $_;
    }
  }

  unshift @dl, "";
  return @dl;

}


sub unreconciled_payments {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->remove_locks($myconfig, $dbh);

  if ($form->{initreport}) {
    $form->retrieve_report($myconfig, $dbh);
  }
  
  my $query;
  my $ref;
  my $null;

  my ($accno) = split /--/, $form->{paymentaccount};

  my %defaults = $form->get_defaults($dbh, \@{[qw(precision company address)]});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $where;
  
  if ($form->{curr}) {
    $where = " AND a.curr = '$form->{curr}'";
    $query = qq|SELECT prec FROM curr
                WHERE curr = '$form->{curr}'|;
    ($form->{precision}) = $dbh->selectrow_array($query);
  }

  my $paymentmethod_id;
  if ($form->{paymentmethod}) {
    ($null, $paymentmethod_id) = split /--/, $form->{paymentmethod};
    $where .= " AND pm.paymentmethod_id = $paymentmethod_id";
  }
  
  $query = qq|SELECT vc.name, vc.customernumber AS companynumber,
              a.id, a.invnumber, a.description, a.curr, a.dcn,
	      ac.source, ac.memo, ac.amount * -1 AS amount,
	      to_char(ac.transdate, '$form->{dateformat}') AS datepaid,
	      'ar' AS module,
	      ad.address1, ad.address2, ad.city, ad.zipcode, ad.state,
	      ad.country,
	      bk.iban, bk.clearingnumber, bk.membernumber 
	      FROM ar a
	      JOIN acc_trans ac ON (ac.trans_id = a.id)
	      JOIN chart c ON (c.id = ac.chart_id)
	      JOIN customer vc ON (a.customer_id = vc.id)
	      JOIN address ad ON (ad.trans_id = vc.id)
	      JOIN payment pm ON (pm.trans_id = a.id)
	      LEFT JOIN bank bk ON (bk.id = vc.id)
	      WHERE ac.cleared IS NULL
	      AND c.accno = '$accno'
	      AND ac.fx_transaction = '0'
	      AND ac.approved = '1'
	      $where
	      UNION
	      SELECT vc.name, vc.vendornumber AS companynumber,
	      a.id, a.invnumber, a.description, a.curr, a.dcn,
	      ac.source, ac.memo, ac.amount,
	      to_char(ac.transdate, '$form->{dateformat}') AS datepaid,
	      'ap' AS module,
	      ad.address1, ad.address2, ad.city, ad.zipcode, ad.state,
	      ad.country,
	      bk.iban, bk.clearingnumber, bk.membernumber 
	      FROM ap a
	      JOIN acc_trans ac ON (ac.trans_id = a.id)
	      JOIN chart c ON (c.id = ac.chart_id)
	      JOIN vendor vc ON (a.vendor_id = vc.id)
	      JOIN address ad ON (ad.trans_id = vc.id)
	      JOIN payment pm ON (pm.trans_id = a.id)
	      LEFT JOIN bank bk ON (bk.id = vc.id)
	      WHERE ac.cleared IS NULL
	      AND c.accno = '$accno'
	      AND ac.fx_transaction = '0'
	      AND ac.approved = '1'
	      $where
	      ORDER BY datepaid
	      |;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  delete $form->{TR};
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->create_lock($myconfig, $dbh, $ref->{id}, $ref->{module});
    push @{ $form->{TR} }, $ref;
  }
  $sth->finish;

  $query = qq|SELECT iban, clearingnumber
              FROM bank
              WHERE id = (SELECT id FROM chart
	                  WHERE accno = '$accno')|;
  ($form->{accountnumber}, $form->{accountclearingnumber}) = $dbh->selectrow_array($query);
  
  $dbh->disconnect;

}


sub reconcile_payments {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my ($paymentaccount) = split /--/, $form->{paymentaccount};
  
  my $sth;
  my $query;
  
  $query = qq|SELECT id FROM chart
              WHERE accno = '$paymentaccount'|;
  my ($paymentaccount_id) = $dbh->selectrow_array($query);
	      
  $query = qq|UPDATE acc_trans SET
              cleared = '$form->{dateprepared}'
	      WHERE trans_id = ?
	      AND transdate = ?
	      AND chart_id = $paymentaccount_id|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  
  my $i;
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$i"}) {
      $sth->execute($form->{"ndx_$i"} * 1, $form->{"datepaid_$i"});
      $sth->finish;
    }
  }

  $form->remove_locks($myconfig, $dbh);

  $dbh->disconnect;

}


1;

