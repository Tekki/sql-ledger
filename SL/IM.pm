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



sub sales_invoice {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $ref;
  
  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};
  
  $form->{ARAP} = "AR";

  # get AR accounts
  $query = qq|SELECT accno FROM chart
              WHERE link = '$form->{ARAP}'|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  my %ARAP = ();
  my $default_arap_accno;
  
  $sth->execute || $form->dberror($query);
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ARAP{"$ref->{accno}"} = 1;
    $default_arap_accno ||= $ref->{accno};
  }

  if (! %ARAP) {
    $dbh->disconnect;
    return -1;
  }
  
  # customer
  $query = qq|SELECT cv.id, cv.name, cv.customernumber, cv.terms,
              e.id AS employee_id, e.name AS employee,
	      c.accno AS taxaccount, a.accno AS arap_accno,
	      ad.city
	      FROM customer cv
	      JOIN address ad ON (ad.trans_id = cv.id)
	      LEFT JOIN employee e ON (e.id = cv.employee_id)
	      LEFT JOIN customertax ct ON (cv.id = ct.customer_id)
	      LEFT JOIN chart c ON (c.id = ct.chart_id)
	      LEFT JOIN chart a ON (a.id = cv.arap_accno_id)
	      WHERE customernumber = ?|;
  my $cth = $dbh->prepare($query) || $form->dberror($query);
  
  # parts
  $query = qq|SELECT p.id, p.unit, p.description, p.notes AS itemnotes,
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

  my $arap_accno;
  my $terms;
  my $i = 0;
  my $j = 0;
  my %tax;
  my %customertax;
  my $customernumber;
  my $invnumber;
  my %partstax;
  my $parts_id;

  my @d = split /\n/, $form->{data};
  shift @d if ! $form->{mapfile};

  for (@d) {

    @a = &ndxline($form);

    if (@a) {
      $i++;
      for (keys %{$form->{$form->{type}}}) {
	$a[$form->{$form->{type}}->{$_}{ndx}] =~ s/(^"|"$)//g;
	$form->{"${_}_$i"} = $a[$form->{$form->{type}}->{$_}{ndx}];
      }

      if ($customernumber ne $a[$form->{$form->{type}}->{customernumber}{ndx}] || $invnumber ne $a[$form->{$form->{type}}->{invnumber}{ndx}]) {
	
	$j = $i;
	$form->{ndx} .= "$i ";

	%customertax = ();
	
	$cth->execute("$a[$form->{$form->{type}}->{customernumber}{ndx}]");

        $arap_accno = "";
	$terms = 0;
	
	while ($ref = $cth->fetchrow_hashref(NAME_lc)) {
	  $customernumber = $ref->{customernumber};
	  $arap_accno = $ref->{arap_accno};
	  $terms = $ref->{terms};
	  $form->{"customer_id_$i"} = $ref->{id};
	  $form->{"customer_$i"} = $ref->{name};
	  $form->{"city_$i"} = $ref->{city};
	  $form->{"employee_$i"} = $ref->{employee};
	  $form->{"employee_id_$i"} = $ref->{employee_id};
	  $customertax{$ref->{accno}} = 1;
	}
	$cth->finish;

	if (! $ARAP{"$a[$form->{$form->{type}}->{$form->{ARAP}}{ndx}]"}) {
	  $arap_accno ||= $default_arap_accno;
	  $form->{"$form->{ARAP}_$i"} ||= $arap_accno;
	}

        $form->{"transdate_$i"} ||= $form->current_date($myconfig);
	
	# terms and duedate
	if ($form->{"duedate_$i"}) {
	    $form->{"terms_$i"} = $form->datediff($myconfig, $form->{"transdate_$i"}, $form->{"duedate_$i"});
	} else {
	  $form->{"terms_$i"} = $terms if $form->{"terms_$i"} !~ /\d/;
	  $form->{"duedate_$i"} ||= $form->{"transdate_$i"};
	  if ($form->{"terms_$i"} > 0) {
	    $form->{"duedate_$i"} = $form->add_date($myconfig, $form->{"transdate_$i"}, $form->{"terms_$i"}, 'days');
	  }
	}
	  
	$dth->execute("$a[$form->{$form->{type}}->{department}{ndx}]");
	($form->{"department_id_$i"}) = $dth->fetchrow_array;
	$dth->finish;
	
	$wth->execute("$a[$form->{$form->{type}}->{warehouse}{ndx}]");
	($form->{"warehouse_id_$i"}) = $wth->fetchrow_array;
	$wth->finish;

      }
      
      $form->{transdate} = $form->{"transdate_$i"};
      %tax = &taxrates("", $myconfig, $form, $dbh);

      $pth->execute("$a[$form->{$form->{type}}->{partnumber}{ndx}]");

      $parts_id = 0;
      while ($ref = $pth->fetchrow_hashref(NAME_lc)) {
	$form->{"parts_id_$i"} = $ref->{id};
	for (qw(description unit)) { $form->{"${_}_$i"} ||= $ref->{$_} }
	
	$form->{"itemnotes_$i"} ||= $ref->{notes};
	
	$parts_id = 1;
	if ($customertax{$ref->{accno}}) {
	  $form->{"tax_$j"} += $a[$form->{$form->{type}}->{sellprice}{ndx}] * $a[$form->{$form->{type}}->{qty}{ndx}] * $tax{$ref->{accno}};
	}
      }
      $pth->finish;
      
      $ptth->execute("$a[$form->{$form->{type}}->{projectnumber}{ndx}]");
      ($form->{"projectnumber_$i"}) = $ptth->fetchrow_array;
      $ptth->finish;

      $form->{"projectnumber_$i"} = qq|--$form->{"projectnumber_$i"}| if $form->{"projectnumber_$i"};

      if (! $parts_id) {
	$form->{"customer_id_$j"} = 0;
	$form->{missingparts} .= "$a[$form->{$form->{type}}->{invnumber}{ndx}] : $a[$form->{$form->{type}}->{partnumber}{ndx}]\n";
      }
      
      $form->{"total_$j"} += $a[$form->{$form->{type}}->{sellprice}{ndx}] * $a[$form->{$form->{type}}->{qty}{ndx}];
      $form->{"totalqty_$j"} += $a[$form->{$form->{type}}->{qty}{ndx}];
	
    }

    $invnumber = $a[$form->{$form->{type}}->{invnumber}{ndx}];
    $form->{rowcount} = $i;

  }

  $dbh->disconnect;

  chop $form->{ndx};

}


sub taxrates {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  # get tax rates
  my $query = qq|SELECT c.accno, t.rate
              FROM chart c
	      JOIN tax t ON (c.id = t.chart_id)
	      WHERE c.link LIKE '%$form->{ARAP}_tax%'
	      AND (t.validto >= ? OR t.validto IS NULL)
	      ORDER BY accno, validto|;
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
  my ($self, $myconfig, $form) = @_;
  
  use SL::IS;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;

  $query = qq|SELECT curr
              FROM curr
	      ORDER BY rn|;
  ($form->{defaultcurrency}) = $dbh->selectrow_array($query);
  
  $form->{curr} ||= $form->{defaultcurrency};
  $form->{currency} = $form->{curr};

  my $language_code;
  $query = qq|SELECT c.customernumber, c.language_code, a.city
              FROM customer c
	      JOIN address a ON (a.trans_id = c.id)
	      WHERE c.id = $form->{customer_id}|;
  ($form->{customernumber}, $language_code, $form->{city}) = $dbh->selectrow_array($query);

  $form->{language_code} ||= $language_code;

  $query = qq|SELECT c.accno, t.rate
              FROM customertax ct
              JOIN chart c ON (c.id = ct.chart_id)
	      JOIN tax t ON (t.chart_id = c.id)
              WHERE ct.customer_id = $form->{customer_id}
	      AND (validto > '$form->{transdate}' OR validto IS NULL)
	      ORDER BY validto DESC|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;

  $form->{taxaccounts} = "";
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{taxaccounts} .= "$ref->{accno} ";
    $form->{"$ref->{accno}_rate"} = $ref->{rate};
  }
  $sth->finish;
  chop $form->{taxaccounts};

  # post invoice
  my $rc = IS->post_invoice($myconfig, $form, $dbh);

  $dbh->disconnect;

  $rc;

}


sub paymentaccounts {
  my ($self, $myconfig, $form) = @_;

  $dbh = $form->dbconnect($myconfig);

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


sub payments {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $myconfig{numberformat} = "1000.00";
  
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
	      LEFT JOIN address ad ON (ad.trans_id = c.id)
	      WHERE a.amount != a.paid
	      UNION
	      SELECT c.name, c.vendornumber AS companynumber, ad.city,
	      a.id, a.invnumber, a.description, a.exchangerate,
	      (a.amount - a.paid) / a.exchangerate AS amount,
	      a.transdate, a.paymentmethod_id, 'vendor' AS vc,
	      'ap' AS arap
	      FROM ap a
	      JOIN vendor c ON (a.vendor_id = c.id)
	      LEFT JOIN address ad ON (ad.trans_id = c.id)
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
	      LEFT JOIN address ad ON (ad.trans_id = c.id)
	      WHERE a.amount != a.paid
	      AND a.dcn = ?
	      UNION
	      SELECT c.name, c.vendornumber AS companynumber, ad.city,
              a.id, a.invnumber, a.description, a.dcn,
	      a.paymentmethod_id, 'vendor' AS vc, 'ap' AS arap
	      FROM ap a
	      JOIN vendor c ON (a.vendor_id = c.id)
	      LEFT JOIN address ad ON (ad.trans_id = c.id)
	      WHERE a.amount != a.paid
	      AND a.dcn = ?
	      |;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT buy, sell FROM exchangerate
	      WHERE curr = '$form->{currency}'
	      AND transdate = ?|;
  my $eth = $dbh->prepare($query) || $form->dberror($query);
  
  my $i = 0;
  my $j = 0;

  my $vc;
  my $buy;
  my $sell;

  my @d = split /\n/, $form->{data};
  shift @d if ! $form->{mapfile};

  my $am;

  for (@d) {

    @a = &ndxline($form);

    if (@a) {

      
      $amount = $form->format_amount($myconfig, $a[$form->{$form->{type}}->{credit}{ndx}] - $a[$form->{$form->{type}}->{debit}{ndx}], $form->{precision});
      $am = 1;
      
      # dcn
      if (exists $form->{$form->{type}}->{dcn}) {

	if ($a[$form->{$form->{type}}->{dcn}{ndx}]) {
	  $am = 0;
	  $sth->execute("$a[$form->{$form->{type}}->{dcn}{ndx}]", "$a[$form->{$form->{type}}->{dcn}{ndx}]");
	  $ref = $sth->fetchrow_hashref(NAME_lc);

	  if ($ref->{invnumber}) {

	    $i++;

	    for (keys %{$form->{$form->{type}}}) {
	      $a[$form->{$form->{type}}->{$_}{ndx}] =~ s/(^"|"$)//g;
	      $form->{"${_}_$i"} = $a[$form->{$form->{type}}->{$_}{ndx}];
	    }

            $vc = $ref->{vc};
	    for (qw(id invnumber description name companynumber vc arap city paymentmethod_id)) { $form->{"${_}_$i"} = $ref->{$_} }
	    $form->{"amount_$i"} = $amount;
	  }
	  $sth->finish;
	} else {
	  $am = 1;
	}
	
      }
      
      if ($am) {
	
	if ($amount) {

	  if ($amount{$amount}) {
	      
	    $i++;
    
	    for (keys %{$form->{$form->{type}}}) {
	      $a[$form->{$form->{type}}->{$_}{ndx}] =~ s/(^"|"$)//g;
	      $form->{"${_}_$i"} = $a[$form->{$form->{type}}->{$_}{ndx}];
	    }

            $vc = $amount{$amount}->[0]->{vc};
	    for (qw(id invnumber description name companynumber vc arap city paymentmethod_id)) { $form->{"${_}_$i"} = $amount{$amount}->[0]->{$_} }
	    $form->{"amount_$i"} = $amount;

	    pop @{ $amount{$amount} };
	  }
	}
      }

      # get exchangerate
      if ($form->{currency} ne $form->{defaultcurrency}) {
	$eth->execute($a[$form->{$form->{type}}->{datepaid}{ndx}]);
	($buy, $sell) = $eth->fetchrow_array;
	$eth->finish;
	($form->{"exchangerate_$i"}) = ($vc eq 'customer') ? $buy : $sell;
      }

    }

    $form->{rowcount} = $i;

  }

  $dbh->disconnect;

}


sub ndxline {
  my ($form) = @_;
 
 my @a = ();
 my $string = 0;
 my $chr = "";
 my $m = 0;

  if ($form->{tabdelimited}) {
    @a = split /\t/, $_;
  } else {
    
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
      $a[$m] .= $chr;
    }
  }

  return @a;

}


sub unreconciled_payments {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $ref;
  my $null;

  my ($accno) = split /--/, $form->{paymentaccount};

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};

  my $where;
  
  if ($form->{currency}) {
    $where = " AND a.curr = '$form->{currency}'";
    $query = qq|SELECT precision FROM curr
                WHERE curr = '$form->{currency}'|;
    ($form->{precision}) = $dbh->selectrow_array($query);
  }

  my $paymentmethod_id;
  if ($form->{paymentmethod}) {
    ($null, $paymentmethod_id) = split /--/, $form->{paymentmethod};
    $where .= " AND a.paymentmethod_id = $paymentmethod_id";
  }
  
  $query = qq|SELECT vc.name, vc.customernumber AS companynumber,
              a.id, a.invnumber, a.description, a.curr,
	      ac.source, ac.memo, ac.amount, ac.transdate AS datepaid
	      FROM ar a
	      JOIN acc_trans ac ON (ac.trans_id = a.id)
	      JOIN chart c ON (c.id = ac.chart_id)
	      JOIN customer vc ON (a.customer_id = vc.id)
	      WHERE ac.cleared IS NULL
	      AND c.accno = '$accno'
	      AND ac.amount > 0
	      AND ac.fx_transaction = '0'
	      AND ac.approved = '1'
	      $where
	      UNION
	      SELECT vc.name, vc.vendornumber AS companynumber,
	      a.id, a.invnumber, a.description, a.curr,
	      ac.source, ac.memo, ac.amount, ac.transdate AS datepaid
	      FROM ap a
	      JOIN acc_trans ac ON (ac.trans_id = a.id)
	      JOIN chart c ON (c.id = ac.chart_id)
	      JOIN vendor vc ON (a.vendor_id = vc.id)
	      WHERE ac.cleared IS NULL
	      AND c.accno = '$accno'
	      AND ac.amount > 0
	      AND ac.fx_transaction = '0'
	      AND ac.approved = '1'
	      $where
	      ORDER BY datepaid
	      |;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{TR} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}


1;

