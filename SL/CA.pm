#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# chart of accounts
#
#======================================================================


package CA;


sub all_accounts {
  my ($self, $myconfig, $form) = @_;

  my $amount = ();
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $ref;
  
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
 
  my $query = qq|SELECT c.accno,
                 SUM(ac.amount) AS amount
                 FROM chart c
		 JOIN acc_trans ac ON (ac.chart_id = c.id)
		 WHERE ac.approved = '1'
		 GROUP BY c.accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $amount{$ref->{accno}} = $ref->{amount}
  }
  $sth->finish;
 
  $query = qq|SELECT accno, description
              FROM gifi|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $gifi = ();
  while (my ($accno, $description) = $sth->fetchrow_array) {
    $gifi{$accno} = $description;
  }
  $sth->finish;

  $query = qq|SELECT c.id, c.accno, c.description, c.charttype, c.gifi_accno,
              c.category, c.link, c.contra,
	      l.description AS translation
              FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
 
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{amount} = $amount{$ref->{accno}};
    $ref->{gifi_description} = $gifi{$ref->{gifi_accno}};
    if ($ref->{amount} < 0) {
      $ref->{debit} = $ref->{amount} * -1;
    } else {
      $ref->{credit} = $ref->{amount};
    }
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{CA} }, $ref;
  }

  $sth->finish;
  $dbh->disconnect;

}


sub all_transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);


  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
    
  # get chart_id
  my $query = qq|SELECT id FROM chart
                 WHERE accno = '$form->{accno}'|;
  if ($form->{accounttype} eq 'gifi') {
    $query = qq|SELECT id FROM chart
                WHERE gifi_accno = '$form->{gifi_accno}'|;
  }
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my @id = ();
  while (my ($id) = $sth->fetchrow_array) {
    push @id, $id;
  }
  $sth->finish;

  my $fromdate_where;
  my $todate_where;

  ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  
  if ($form->{fromdate}) {
    $fromdate_where = qq|
                 AND ac.transdate >= '$form->{fromdate}'
		|;
  }
  if ($form->{todate}) {
    $todate_where = qq|
                 AND ac.transdate <= '$form->{todate}'
		|;
  }
  

  my $false = ($myconfig->{dbdriver} =~ /Pg/) ? FALSE : q|'0'|;
  
  my $null;
  my $department_id;
  my $dpt_where;
  my $dpt_join;
  my $union;
  
  ($null, $department_id) = split /--/, $form->{department};
  
  if ($department_id) {
    $dpt_join = qq|
                   JOIN department t ON (t.id = a.department_id)
		  |;
    $dpt_where = qq|
		   AND t.id = $department_id
		  |;
  }

  my $project;
  my $project_id;
  if ($form->{projectnumber}) {
    ($null, $project_id) = split /--/, $form->{projectnumber};
    $project = qq|
                 AND ac.project_id = $project_id
		 |;
  }

  if ($form->{accno} || $form->{gifi_accno}) {
    # get category for account
    $query = qq|SELECT c.description, c.category, c.link, c.contra,
                l.description AS translation
                FROM chart c
		LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		WHERE c.accno = '$form->{accno}'|;
    if ($form->{accounttype} eq 'gifi') {
      $query = qq|SELECT description, category, link, contra
                FROM chart
		WHERE gifi_accno = '$form->{gifi_accno}'
		AND charttype = 'A'|;
    }

    ($form->{description}, $form->{category}, $form->{link}, $form->{contra}, $form->{translation}) = $dbh->selectrow_array($query);

    $form->{description} = $form->{translation} if $form->{translation};
    
    if ($form->{fromdate}) {

      if ($department_id) {
	
	$query = ""; 
	$union = "";

	for (qw(ar ap gl)) {
	  
	  if ($form->{accounttype} eq 'gifi') {
	    $query = qq|
	                $union
			SELECT SUM(ac.amount)
			FROM acc_trans ac
			JOIN $_ a ON (a.id = ac.trans_id)
			JOIN chart c ON (ac.chart_id = c.id)
			WHERE c.gifi_accno = '$form->{gifi_accno}'
			AND ac.approved = '1'
			AND ac.transdate < '$form->{fromdate}'
			AND a.department_id = $department_id
			$project
			|;
		      
	  } else {

	    $query = qq|
			$union
			SELECT SUM(ac.amount)
			FROM acc_trans ac
			JOIN $_ a ON (a.id = ac.trans_id)
			JOIN chart c ON (ac.chart_id = c.id)
			WHERE c.accno = '$form->{accno}'
			AND ac.approved = '1'
			AND ac.transdate < '$form->{fromdate}'
			AND a.department_id = $department_id
			$project
			|;
	  }

	}
	
      } else {
	
	if ($form->{accounttype} eq 'gifi') {
	  $query = qq|SELECT SUM(ac.amount)
		    FROM acc_trans ac
		    JOIN chart c ON (ac.chart_id = c.id)
		    WHERE c.gifi_accno = '$form->{gifi_accno}'
		    AND ac.approved = '1'
		    AND ac.transdate < '$form->{fromdate}'
		    $project
		    |;
	} else {
	  $query = qq|SELECT SUM(ac.amount)
		      FROM acc_trans ac
		      JOIN chart c ON (ac.chart_id = c.id)
		      WHERE c.accno = '$form->{accno}'
		      AND ac.approved = '1'
		      AND ac.transdate < '$form->{fromdate}'
		      $project
		      |;
	}
      }
	
      ($form->{balance}) = $dbh->selectrow_array($query);
      
    }
  }

  $query = "";
  my $union = "";

  foreach my $id (@id) {
    
    # get all transactions
    $query .= qq|$union
                 SELECT a.id, a.reference, a.description, ac.transdate,
	         $false AS invoice, ac.amount, 'gl' as module, ac.cleared,
		 ac.source,
		 '' AS till, ac.chart_id, '0' AS vc_id
		 FROM gl a
		 JOIN acc_trans ac ON (ac.trans_id = a.id)
		 $dpt_join
		 WHERE ac.chart_id = $id
		 AND ac.approved = '1'
		 $fromdate_where
		 $todate_where
		 $dpt_where
		 $project
      
             UNION ALL
      
                 SELECT a.id, a.invnumber, c.name, ac.transdate,
	         a.invoice, ac.amount, 'ar' as module, ac.cleared,
		 ac.source,
		 a.till, ac.chart_id, c.id AS vc_id
		 FROM ar a
		 JOIN acc_trans ac ON (ac.trans_id = a.id)
		 JOIN customer c ON (a.customer_id = c.id)
		 $dpt_join
		 WHERE ac.chart_id = $id
		 AND ac.approved = '1'
		 $fromdate_where
		 $todate_where
		 $dpt_where
		 $project
      
             UNION ALL
      
                 SELECT a.id, a.invnumber, v.name, ac.transdate,
	         a.invoice, ac.amount, 'ap' as module, ac.cleared,
		 ac.source,
		 a.till, ac.chart_id, v.id AS vc_id
		 FROM ap a
		 JOIN acc_trans ac ON (ac.trans_id = a.id)
		 JOIN vendor v ON (a.vendor_id = v.id)
		 $dpt_join
		 WHERE ac.chart_id = $id
		 AND ac.approved = '1'
		 $fromdate_where
		 $todate_where
		 $dpt_where
		 $project
		 |;

    $union = qq|
             UNION ALL
                 |;
  }

  my @sf = qw(transdate reference description);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $query = qq|SELECT c.id, c.accno FROM chart c
              JOIN acc_trans ac ON (ac.chart_id = c.id)
              WHERE ac.amount >= 0
	      AND (c.link = 'AR' OR c.link = 'AP')
	      AND ac.approved = '1'
	      AND ac.trans_id = ?|;
  my $dr = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT c.id, c.accno FROM chart c
              JOIN acc_trans ac ON (ac.chart_id = c.id)
              WHERE ac.amount < 0
	      AND (c.link = 'AR' OR c.link = 'AP')
	      AND ac.approved = '1'
	      AND ac.trans_id = ?|;
  my $cr = $dbh->prepare($query) || $form->dberror($query);
  
  my $accno;
  my $chart_id;
  my %accno;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    
    # gl
    if ($ref->{module} eq "gl") {
      $ref->{module} = "gl";
      $ref->{vc_id} = 0;
      $ref->{db} = "";
    }

    # ap
    if ($ref->{module} eq "ap") {
      $ref->{module} = ($ref->{invoice}) ? 'ir' : 'ap';
      $ref->{module} = 'ps' if $ref->{till};
      $ref->{db} = "vendor";
    }

    # ar
    if ($ref->{module} eq "ar") {
      $ref->{module} = ($ref->{invoice}) ? 'is' : 'ar';
      $ref->{module} = 'ps' if $ref->{till};
      $ref->{db} = "customer";
    }

    if ($ref->{amount}) {
      %accno = ();

      if ($ref->{amount} < 0) {
	$ref->{debit} = $ref->{amount} * -1;
	$ref->{credit} = 0;
	$dr->execute($ref->{id});
	$ref->{accno} = ();
	while (($chart_id, $accno) = $dr->fetchrow_array) {
	  $accno{$accno} = 1 if $chart_id ne $ref->{chart_id};
	}
	$dr->finish;
	
	for (sort keys %accno) { push @{ $ref->{accno} }, "$_ " }

      } else {
	$ref->{credit} = $ref->{amount};
	$ref->{debit} = 0;
	
	$cr->execute($ref->{id});
	$ref->{accno} = ();
	while (($chart_id, $accno) = $cr->fetchrow_array) {
	  $accno{$accno} = 1 if $chart_id ne $ref->{chart_id};
	}
	$cr->finish;

	for (keys %accno) { push @{ $ref->{accno} }, "$_ " }

      }

      push @{ $form->{CA} }, $ref;
    }
    
  }
 
  $sth->finish;
  $dbh->disconnect;

}

1;

