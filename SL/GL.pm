#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# General ledger backend code
#
#======================================================================

package GL;


sub delete_transaction {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{id} *= 1;
  
  my %audittrail = ( tablename  => 'gl',
                     reference  => $form->{reference},
		     formname   => 'transaction',
		     action     => 'deleted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);

  if ($form->{batchid} *= 1) {
    $query = qq|SELECT sum(amount)
		FROM acc_trans
		WHERE trans_id = $form->{id}
		AND amount < 0|;
    my ($mount) = $dbh->selectrow_array($query);
    
    $amount = $form->round_amount($amount, $form->{precision});
    $form->update_balance($dbh,
			  'br',
			  'amount',
			  qq|id = $form->{batchid}|,
			  $amount);
    
    $query = qq|DELETE FROM vr WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  $query = qq|DELETE FROM gl WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|SELECT trans_id FROM pay_trans
              WHERE glid = $form->{id}|;
  ($form->{apid}) = $dbh->selectrow_array($query);
  
  my $id;
  for $id (qw(id apid)) {
    for (qw(acc_trans dpt_trans yearend pay_trans status)) {
      if ($form->{$id} *= 1) {
	$query = qq|DELETE FROM $_ WHERE trans_id = $form->{$id}|;
	$dbh->do($query) || $form->dberror($query);
      }
    }
  }
  
  for (qw(recurring recurringemail recurringprint)) {
    $query = qq|DELETE FROM $_ WHERE id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }

  $form->delete_references($dbh);

  $form->remove_locks($myconfig, $dbh, 'gl');

  # commit and redirect
  my $rc = $dbh->commit;
  $dbh->disconnect;
  
  $rc;
  
}


sub post_transaction {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my $project_id;
  my $department_id;
  my $i;
  my $keepcleared;
  
  my $disconnect = ($dbh) ? 0 : 1;

  # connect to database, turn off AutoCommit
  if (! $dbh) {
    $dbh = $form->dbconnect_noauto($myconfig);
  }

  my $query;
  my $sth;
  
  my $approved = ($form->{pending}) ? '0' : '1';
  my $action = ($approved) ? 'posted' : 'saved';

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};

  if ($form->{id} *= 1) {
    $keepcleared = 1;
    
    if ($form->{batchid} *= 1) {
      $query = qq|SELECT * FROM vr
		  WHERE trans_id = $form->{id}|;
      $sth = $dbh->prepare($query) || $form->dberror($query);
      $sth->execute || $form->dberror($query);
      $ref = $sth->fetchrow_hashref(NAME_lc);
      $form->{voucher}{transaction} = $ref;
      $sth->finish;
     
      $query = qq|SELECT SUM(amount)
		  FROM acc_trans
		  WHERE amount < 0
		  AND trans_id = $form->{id}|;
      ($amount) = $dbh->selectrow_array($query);
      
      $form->update_balance($dbh,
			    'br',
			    'amount',
			    qq|id = $form->{batchid}|,
			    $amount);
      
      # delete voucher
      $query = qq|DELETE FROM vr
                  WHERE trans_id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);

    }

    $query = qq|SELECT id FROM gl
                WHERE id = $form->{id}|;
    ($form->{id}) = $dbh->selectrow_array($query);

    if ($form->{id}) {
      # delete individual transactions
      for (qw(acc_trans dpt_trans)) {
	$query = qq|DELETE FROM $_ WHERE trans_id = $form->{id}|;
	$dbh->do($query) || $form->dberror($query);
      }
    }
  }

  if (!$form->{id}) {
   
    my $uid = localtime;
    $uid .= $$;

    $query = qq|INSERT INTO gl (reference, employee_id, approved)
                VALUES ('$uid', (SELECT id FROM employee
		                 WHERE login = '$form->{login}'),
		'$approved')|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT id FROM gl
                WHERE reference = '$uid'|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }
  
  (undef, $department_id) = split /--/, $form->{department};
  $department_id *= 1;

  $form->{reference} = $form->update_defaults($myconfig, 'glnumber', $dbh) unless $form->{reference};

  $form->{currency} ||= $form->{defaultcurrency};

  $form->{exchangerate} = $form->parse_amount($myconfig, $form->{exchangerate}) || 1;

  $query = qq|UPDATE gl SET 
	      reference = |.$dbh->quote($form->{reference}).qq|,
	      description = |.$dbh->quote($form->{description}).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      transdate = '$form->{transdate}',
	      department_id = $department_id,
	      curr = '$form->{currency}',
	      exchangerate = $form->{exchangerate}
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  if ($department_id) {
    $query = qq|INSERT INTO dpt_trans (trans_id, department_id)
                VALUES ($form->{id}, $department_id)|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  # update exchangerate
  $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, $form->{exchangerate});

  my $amount;
  my $debit;
  my $credit;
  my $cleared = 'NULL';
  my $bramount = 0;
 
  # insert acc_trans transactions
  for $i (1 .. $form->{rowcount}) {

    $amount = 0;
    
    $debit = $form->parse_amount($myconfig, $form->{"debit_$i"});
    $credit = $form->parse_amount($myconfig, $form->{"credit_$i"});

    # extract accno
    ($accno) = split(/--/, $form->{"accno_$i"});
    
    if ($credit) {
      $amount = $credit;
      $bramount += $form->round_amount($amount * $form->{exchangerate}, $form->{precision});
    }
    if ($debit) {
      $amount = $debit * -1;
    }

    # add the record
    (undef, $project_id) = split /--/, $form->{"projectnumber_$i"};
    $project_id ||= 'NULL';
    
    if ($keepcleared) {
      $cleared = $form->dbquote($form->{"cleared_$i"}, SQL_DATE);
    }

    if ($form->{"fx_transaction_$i"} *= 1) {
      $cleared = $form->dbquote($form->{transdate}, SQL_DATE);
    }
    
    if ($amount || $form->{"source_$i"} || $form->{"memo_$i"} || ($project_id ne 'NULL')) {
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
		  source, fx_transaction, project_id, memo, cleared, approved)
		  VALUES
		  ($form->{id}, (SELECT id
				 FROM chart
				 WHERE accno = '$accno'),
		   $amount, '$form->{transdate}', |.
		   $dbh->quote($form->{"source_$i"}) .qq|,
		  '$form->{"fx_transaction_$i"}',
		  $project_id, |.$dbh->quote($form->{"memo_$i"}).qq|,
		  $cleared, '$approved')|;
      $dbh->do($query) || $form->dberror($query);

      if ($form->{currency} ne $form->{defaultcurrency}) {

				$amount = $form->round_amount($amount * ($form->{exchangerate} - 1), $form->{precision});
	
				if ($amount) {
					$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
								source, project_id, fx_transaction, memo, cleared, approved)
								VALUES
								($form->{id}, (SELECT id
									 FROM chart
									 WHERE accno = '$accno'),
								 $amount, '$form->{transdate}', |.
								 $dbh->quote($form->{"source_$i"}) .qq|,
								$project_id, '1', |.$dbh->quote($form->{"memo_$i"}).qq|,
								$cleared, '$approved')|;
					$dbh->do($query) || $form->dberror($query);
				}
      }
    }
  }

  if ($form->{batchid} *= 1) {
    # add voucher
    $form->{voucher}{transaction}{vouchernumber} = $form->update_defaults($myconfig, 'vouchernumber', $dbh) unless $form->{voucher}{transaction}{vouchernumber};

    $query = qq|INSERT INTO vr (br_id, trans_id, id, vouchernumber)
                VALUES ($form->{batchid}, $form->{id}, $form->{id}, |
		.$dbh->quote($form->{voucher}{transaction}{vouchernumber}).qq|)|;
    $dbh->do($query) || $form->dberror($query);

    # update batch
    $form->update_balance($dbh,
			  'br',
			  'amount',
			  qq|id = $form->{batchid}|,
			  $bramount);
   
  }

  # save reference documents
  $form->save_reference($dbh, 'gl');
    
  my %audittrail = ( tablename  => 'gl',
                     reference  => $form->{reference},
		     formname   => 'transaction',
		     action     => $action,
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);

  $form->save_recurring($dbh, $myconfig);

  $form->remove_locks($myconfig, $dbh, 'gl');

  # commit and redirect
  my $rc;
  
  if ($disconnect) {
    $rc = $dbh->commit;
    $dbh->disconnect;
  }

  $rc;

}


sub transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query;
  my $sth;
  my $var;
  
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my ($glwhere, $arwhere, $apwhere) = ("g.approved = '1'", "a.approved = '1'", "a.approved = '1'");
  
  if ($form->{reference}) {
    $var = $form->like(lc $form->{reference});
    $glwhere .= " AND lower(g.reference) LIKE '$var'";
    $arwhere .= " AND lower(a.invnumber) LIKE '$var'";
    $apwhere .= " AND lower(a.invnumber) LIKE '$var'";
  }
  if ($form->{description}) {
    $var = $form->like(lc $form->{description});
    $glwhere .= " AND lower(g.description) LIKE '$var'";
    $arwhere .= " AND lower(a.description) LIKE '$var'";
    $apwhere .= " AND lower(a.description) LIKE '$var'";
  }
  if ($form->{name}) {
    $var = $form->like(lc $form->{name});
    $glwhere .= " AND lower(g.description) LIKE '$var'";
    $arwhere .= " AND lower(ct.name) LIKE '$var'";
    $apwhere .= " AND lower(ct.name) LIKE '$var'";
  }
  if ($form->{vcnumber}) {
    $var = $form->like(lc $form->{vcnumber});
    $glwhere .= " AND g.id = 0";
    $arwhere .= " AND lower(ct.customernumber) LIKE '$var'";
    $apwhere .= " AND lower(ct.vendornumber) LIKE '$var'";
  }
  if ($form->{department}) {
    (undef, $var) = split /--/, $form->{department};
    $glwhere .= " AND g.department_id = $var";
    $arwhere .= " AND a.department_id = $var";
    $apwhere .= " AND a.department_id = $var";
  }
  
  my $gdescription = "''";
  my $invoicejoin;
  my $lineitem = "''";
 
  if ($form->{lineitem}) {
    $var = $form->like(lc $form->{lineitem});
    $glwhere .= " AND lower(ac.memo) LIKE '$var'";
    $arwhere .= " AND lower(i.description) LIKE '$var'";
    $apwhere .= " AND lower(i.description) LIKE '$var'";

    $gdescription = "ac.memo";
    $lineitem = "i.description";
    $invoicejoin = qq|
		 LEFT JOIN invoice i ON (i.id = ac.id)|;
  }
 
  if ($form->{l_lineitem}) {
    $gdescription = "ac.memo";
    $lineitem = "i.description";
    $invoicejoin = qq|
                 LEFT JOIN invoice i ON (i.id = ac.id)|;
  }

  if ($form->{source}) {
    $var = $form->like(lc $form->{source});
    $glwhere .= " AND lower(ac.source) LIKE '$var'";
    $arwhere .= " AND lower(ac.source) LIKE '$var'";
    $apwhere .= " AND lower(ac.source) LIKE '$var'";
  }
  
  my $where;

  if ($form->{accnofrom}) {
    $query = qq|SELECT c.description,
                l.description AS translation
		FROM chart c
		LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		WHERE c.accno = '$form->{accnofrom}'|;
    ($form->{accnofrom_description}, $form->{accnofrom_translation}) = $dbh->selectrow_array($query);
      $form->{accnofrom_description} = $form->{accnofrom_translation} if $form->{accnofrom_translation};
 
    $where = " AND c.accno >= '$form->{accnofrom}'";
    $glwhere .= $where;
    $arwhere .= $where;
    $apwhere .= $where;
  }

  if ($form->{accnoto}) {
    $query = qq|SELECT c.description,
                l.description AS translation
		FROM chart c
		LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		WHERE c.accno = '$form->{accnoto}'|;
    ($form->{accnoto_description}, $form->{accnoto_translation}) = $dbh->selectrow_array($query);
      $form->{accnoto_description} = $form->{accnoto_translation} if $form->{accnoto_translation};
 
    $where = " AND c.accno <= '$form->{accnoto}'";
    $glwhere .= $where;
    $arwhere .= $where;
    $apwhere .= $where;
  }

  if ($form->{memo}) {
    $var = $form->like(lc $form->{memo});
    $glwhere .= " AND lower(ac.memo) LIKE '$var'";
    $arwhere .= " AND lower(ac.memo) LIKE '$var'";
    $apwhere .= " AND lower(ac.memo) LIKE '$var'";
  }

  unless ($form->{datefrom} || $form->{dateto}) {
    ($form->{datefrom}, $form->{dateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
  
  if ($form->{datefrom}) {
    $glwhere .= " AND ac.transdate >= '$form->{datefrom}'";
    $arwhere .= " AND ac.transdate >= '$form->{datefrom}'";
    $apwhere .= " AND ac.transdate >= '$form->{datefrom}'";
  }
  if ($form->{dateto}) {
    $glwhere .= " AND ac.transdate <= '$form->{dateto}'";
    $arwhere .= " AND ac.transdate <= '$form->{dateto}'";
    $apwhere .= " AND ac.transdate <= '$form->{dateto}'";
  }
  if ($form->{amountfrom}) {
    $glwhere .= " AND abs(ac.amount) >= $form->{amountfrom}";
    $arwhere .= " AND abs(ac.amount) >= $form->{amountfrom}";
    $apwhere .= " AND abs(ac.amount) >= $form->{amountfrom}";
  }
  if ($form->{amountto}) {
    $glwhere .= " AND abs(ac.amount) <= $form->{amountto}";
    $arwhere .= " AND abs(ac.amount) <= $form->{amountto}";
    $apwhere .= " AND abs(ac.amount) <= $form->{amountto}";
  }
  if ($form->{notes}) {
    $var = $form->like(lc $form->{notes});
    $glwhere .= " AND lower(g.notes) LIKE '$var'";
    $arwhere .= " AND lower(a.notes) LIKE '$var'";
    $apwhere .= " AND lower(a.notes) LIKE '$var'";
  }
  if ($form->{accno}) {
    $glwhere .= " AND c.accno = '$form->{accno}'";
    $arwhere .= " AND c.accno = '$form->{accno}'";
    $apwhere .= " AND c.accno = '$form->{accno}'";
  }
  if ($form->{gifi_accno}) {
    $glwhere .= " AND c.gifi_accno = '$form->{gifi_accno}'";
    $arwhere .= " AND c.gifi_accno = '$form->{gifi_accno}'";
    $apwhere .= " AND c.gifi_accno = '$form->{gifi_accno}'";
  }
  if ($form->{category} ne 'X') {
    $glwhere .= " AND c.category = '$form->{category}'";
    $arwhere .= " AND c.category = '$form->{category}'";
    $apwhere .= " AND c.category = '$form->{category}'";

    delete $form->{l_contra};
  }

  if ($form->{accno} || $form->{gifi_accno}) {
    
    # get category for account
    if ($form->{accno}) {
      $query = qq|SELECT c.category, c.link, c.contra, c.description,
                  l.description AS translation
		  FROM chart c
		  LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		  WHERE c.accno = '$form->{accno}'|;
      ($form->{category}, $form->{link}, $form->{contra}, $form->{account_description}, $form->{account_translation}) = $dbh->selectrow_array($query);
      $form->{account_description} = $form->{account_translation} if $form->{account_translation};
    }
    
    if ($form->{gifi_accno}) {
      $query = qq|SELECT c.category, c.link, c.contra, g.description
		  FROM chart c
		  LEFT JOIN gifi g ON (g.accno = c.gifi_accno)
		  WHERE c.gifi_accno = '$form->{gifi_accno}'|;
      ($form->{category}, $form->{link}, $form->{contra}, $form->{gifi_account_description}) = $dbh->selectrow_array($query);
    }
 
    if ($form->{datefrom}) {
      $where = $glwhere;
      $where =~ s/(AND)??ac.transdate.*?(AND|$)//g;
      
      $query = qq|SELECT SUM(ac.amount)
		  FROM acc_trans ac
		  JOIN chart c ON (ac.chart_id = c.id)
		  JOIN gl g ON (g.id = ac.trans_id)
		  WHERE $where
		  AND ac.transdate < date '$form->{datefrom}'
		  |;
      my ($balance) = $dbh->selectrow_array($query);
      $form->{balance} += $balance;


      $where = $arwhere;
      $where =~ s/(AND)??ac.transdate.*?(AND|$)//g;
      
      $query = qq|SELECT SUM(ac.amount)
		  FROM acc_trans ac
		  JOIN chart c ON (ac.chart_id = c.id)
		  JOIN ar a ON (a.id = ac.trans_id)
		  JOIN customer ct ON (ct.id = a.customer_id)
		  $invoicejoin
		  WHERE $where
		  AND ac.transdate < date '$form->{datefrom}'
		  |;
      ($balance) = $dbh->selectrow_array($query);
      $form->{balance} += $balance;

 
      $where = $apwhere;
      $where =~ s/(AND)??ac.transdate.*?(AND|$)//g;
      
      $query = qq|SELECT SUM(ac.amount)
		  FROM acc_trans ac
		  JOIN chart c ON (ac.chart_id = c.id)
		  JOIN ap a ON (a.id = ac.trans_id)
		  JOIN vendor ct ON (ct.id = a.vendor_id)
		  $invoicejoin
		  WHERE $where
		  AND ac.transdate < date '$form->{datefrom}'
		  |;
      
      ($balance) = $dbh->selectrow_array($query);
      $form->{balance} += $balance;

    }
  }
  

  my $false = ($myconfig->{dbdriver} =~ /Pg/) ? FALSE : q|'0'|;
 
  my $query = qq|SELECT g.id, 'gl' AS type, $false AS invoice, g.reference,
                 g.description, ac.transdate, ac.source,
		 ac.amount, c.accno, c.gifi_accno, g.notes, c.link,
		 '' AS till, ac.cleared, d.description AS department,
		 ac.memo, '0' AS name_id, '' AS db,
		 $gdescription AS lineitem, '' AS name, '' AS vcnumber,
		 '' AS address1, '' AS address2, '' AS city,
		 '' AS zipcode, '' AS country
                 FROM gl g
		 JOIN acc_trans ac ON (g.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 LEFT JOIN department d ON (d.id = g.department_id)
                 WHERE $glwhere
	UNION ALL
	         SELECT a.id, 'ar' AS type, a.invoice, a.invnumber,
		 a.description, ac.transdate, ac.source,
		 ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
		 a.till, ac.cleared, d.description AS department,
		 ac.memo, ct.id AS name_id, 'customer' AS db,
		 $lineitem AS lineitem, ct.name, ct.customernumber,
		 ad.address1, ad.address2, ad.city,
		 ad.zipcode, ad.country
		 FROM ar a
		 JOIN acc_trans ac ON (a.id = ac.trans_id)
		 $invoicejoin
		 JOIN chart c ON (ac.chart_id = c.id)
		 JOIN customer ct ON (a.customer_id = ct.id)
		 JOIN address ad ON (ad.trans_id = ct.id)
		 LEFT JOIN department d ON (d.id = a.department_id)
		 WHERE $arwhere
	UNION ALL
	         SELECT a.id, 'ap' AS type, a.invoice, a.invnumber,
		 a.description, ac.transdate, ac.source,
		 ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
		 a.till, ac.cleared, d.description AS department,
		 ac.memo, ct.id AS name_id, 'vendor' AS db,
		 $lineitem AS lineitem, ct.name, ct.vendornumber,
		 ad.address1, ad.address2, ad.city,
		 ad.zipcode, ad.country
		 FROM ap a
		 JOIN acc_trans ac ON (a.id = ac.trans_id)
		 $invoicejoin
		 JOIN chart c ON (ac.chart_id = c.id)
		 JOIN vendor ct ON (a.vendor_id = ct.id)
		 JOIN address ad ON (ad.trans_id = ct.id)
		 LEFT JOIN department d ON (d.id = a.department_id)
		 WHERE $apwhere|;
 
  my @sf = qw(id transdate reference accno);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my %trans;
  my $i = 0;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    # gl
    if ($ref->{type} eq "gl") {
      $ref->{module} = "gl";
    }

    # ap
    if ($ref->{type} eq "ap") {
      $ref->{memo} ||= $ref->{lineitem};
      if ($ref->{invoice}) {
        $ref->{module} = "ir";
      } else {
        $ref->{module} = "ap";
      }
    }

    # ar
    if ($ref->{type} eq "ar") {
      $ref->{memo} ||= $ref->{lineitem};
      if ($ref->{invoice}) {
        $ref->{module} = ($ref->{till}) ? "ps" : "is";
      } else {
        $ref->{module} = "ar";
      }
    }

    if ($ref->{amount} < 0) {
      $ref->{debit} = $ref->{amount} * -1;
      $ref->{credit} = 0;
    } else {
      $ref->{credit} = $ref->{amount};
      $ref->{debit} = 0;
    }

    for (qw(address1 address2 city zipcode country)) { $ref->{address} .= "$ref->{$_} " }

    $trans{$ref->{id}}{$i} = {
                 transdate => $ref->{transdate},
                      link => $ref->{link},
                      type => $ref->{type},
                     accno => $ref->{accno},
                gifi_accno => $ref->{gifi_accno},
                     debit => $ref->{debit},
                    credit => $ref->{credit},
                    amount => $ref->{debit} + $ref->{credit}
		             };
    push @{ $form->{GL} }, $ref;

    $i++;
    
  }
  $sth->finish;

  if ($form->{initreport}) {
    $form->retrieve_report($myconfig, $dbh);
  }
  
  $form->report_level($myconfig, $dbh);

  $dbh->disconnect;

  if (! ($form->{accnofrom} || $form->{accnoto}) ) {
    for my $id (keys %trans) {

      my $arap = "";
      my $ARAP;
      my $gifi_arap = "";
      my $paid = "";
      my $gifi_paid = "";
      my $accno = "";
      my $gifi_accno = "";
      my @arap = ();
      my @paid = ();
      my @accno = ();
      my %accno = ();
      my $aa = 0;
      my $j;

      for $i (reverse sort { $trans{$id}{$a}{amount} <=> $trans{$id}{$b}{amount} } keys %{$trans{$id}}) {

	if ($trans{$id}{$i}{type} =~ /(ar|ap)/) {
	  $ARAP = uc $trans{$id}{$i}{type};
	  $aa = 1;
	  if ($trans{$id}{$i}{link} eq $ARAP) {
	    $arap = $trans{$id}{$i}{accno};
	    $gifi_arap = $trans{$id}{$i}{gifi_accno};
	    push @arap, $i;
	  } elsif ($trans{$id}{$i}{link} =~ /${ARAP}_paid/) {
	    $paid = $trans{$id}{$i}{accno};
	    $gifi_paid = $trans{$id}{$i}{gifi_accno};
	    push @paid, $i;
	  } else {
	    push @accno, { accno => $trans{$id}{$i}{accno},
		      gifi_accno => $trans{$id}{$i}{gifi_accno},
                       transdate => $trans{$id}{$i}{transdate},
			       i => $i };
	  }
	}
      }

      if ($aa) {
	for (@paid) {
	  $form->{GL}[$_]{contra} = $arap;
	  $form->{GL}[$_]{gifi_contra} = $gifi_arap;
	}
	if (@paid) {
	  $i = pop @arap;
	  $form->{GL}[$i]{contra} = $paid;
	  $form->{GL}[$i]{gifi_contra} = $gifi_paid;
	}
	for (@arap) {
	  $i = 0;
	  for $ref (@accno) {
	    $form->{GL}[$_]{contra} .= "$ref->{accno} " unless $seen{"$ref->{accno}$ref->{transdate}"};
	    $seen{"$ref->{accno}$ref->{transdate}"} = 1;

	    $form->{GL}[$_]{gifi_contra} .= "$ref->{gifi_accno} " unless $seen{"$ref->{gifi_accno}$ref->{transdate}"};
	    $seen{"$ref->{gifi_accno}$ref->{transdate}"} = 1;
	  }
	  $i++;
	}
	for $ref (@accno) {
	  $form->{GL}[$ref->{i}]{contra} = $arap;
	  $form->{GL}[$ref->{i}]{gifi_contra} = $gifi_arap;
	}
      } else {
	
	%accno = %{$trans{$id}};

	for $i (reverse sort { $trans{$id}{$a}{amount} <=> $trans{$id}{$b}{amount} } keys %{$trans{$id}}) {
	  $found = 0;
	  $amount = $trans{$id}{$i}{amount};
	  $j = $i;

	  if ($trans{$id}{$i}{debit}) {
	    $amt = "debit";
	    $rev = "credit";
	  } else {
	    $amt = "credit";
	    $rev = "debit";
	  }

	  if ($amount) {
	    for (keys %accno) {
	      if ($accno{$_}{$rev} == $amount) {
		$form->{GL}[$i]{contra} = $accno{$_}{accno};
		$form->{GL}[$i]{gifi_contra} = $accno{$_}{gifi_accno};
		$found = 1;
		last;
	      }
	    }
	  }

	  if (!$found) {
	    if ($amount) {
	      for $i (reverse sort { $accno{$a}{amount} <=> $accno{$b}{amount} } keys %accno) {
		if ($accno{$i}{$rev}) {

                  # add contra to accno
		  $form->{GL}[$j]{contra} .= "$accno{$i}{accno} ";
		  $form->{GL}[$j]{gifi_contra} .= "$accno{$i}{gifi_accno} ";

		  $amount = $form->round_amount($amount - $accno{$i}{$rev}, 10);
                  last if $amount <= 0;

		}
	      }
              $form->{GL}[$j]{contra} = join ' ', sort split / /, $form->{GL}[$j]{contra};
              $form->{GL}[$j]{gifi_contra} = join ' ', sort split / /, $form->{GL}[$j]{gifi_contra};
	    }
	  }
	}
      }
    }
  }

}


sub transaction {
  my ($self, $myconfig, $form) = @_;
  
  my $query;
  my $sth;
  my $ref;
  my @gl;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->remove_locks($myconfig, $dbh, 'gl');
  
  my %defaults = $form->get_defaults($dbh, \@{[qw(closedto revtrans precision referenceurl)]});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  $form->{currencies} = $form->get_currencies($myconfig, $dbh);
  
  if ($form->{id} *= 1) {
    $query = qq|SELECT g.*, 
                d.description AS department,
		br.id AS batchid, br.description AS batchdescription
                FROM gl g
	        LEFT JOIN department d ON (d.id = g.department_id)
		LEFT JOIN vr ON (vr.trans_id = g.id)
		LEFT JOIN br ON (br.id = vr.br_id)
	        WHERE g.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $form->{currency} = $form->{curr};
    $sth->finish;
  
    # retrieve individual rows
    $query = qq|SELECT ac.*, c.accno, c.description, p.projectnumber,
                l.description AS translation
	        FROM acc_trans ac
	        JOIN chart c ON (ac.chart_id = c.id)
	        LEFT JOIN project p ON (p.id = ac.project_id)
		LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	        WHERE ac.trans_id = $form->{id}
	        ORDER BY c.accno|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{description} = $ref->{translation} if $ref->{translation};
      push @gl, $ref;
      if ($ref->{fx_transaction}) {
	$fxdr += $ref->{amount} if $ref->{amount} < 0;
	$fxcr += $ref->{amount} if $ref->{amount} > 0;
      }
    }
    $sth->finish;
    
    if ($fxdr < 0 || $fxcr > 0) {
      $form->{fxadj} = 1 if $form->round_amount($fxdr * -1, $form->{precision}) != $form->round_amount($fxcr, $form->{precision});
    }

    if ($form->{fxadj}) {
      @{ $form->{GL} } = @gl;
    } else {
      foreach $ref (@gl) {
	if (! $ref->{fx_transaction}) {
	  push @{ $form->{GL} }, $ref;
	}
      }
    }
    
    # get recurring transaction
    $form->get_recurring($dbh);

    $form->all_references($dbh);

    $form->create_lock($myconfig, $dbh, $form->{id}, 'gl');

  } else {
    $form->{transdate} = $form->current_date($myconfig);
  }

  # get chart of accounts
  $query = qq|SELECT c.accno, c.description,
              l.description AS translation
              FROM chart c
              LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
              WHERE c.charttype = 'A'
              AND c.closed = '0'
              ORDER by 1|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{all_accno} }, $ref;
  }
  $sth->finish;

  # get departments
  $form->all_departments($myconfig, $dbh);
  
  # get projects
  $form->all_projects($myconfig, $dbh, $form->{transdate});
  
  $dbh->disconnect;

}


1;

