#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Account reconciliation routines
#
#======================================================================

package RC;


sub paymentaccounts {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT c.accno, c.description,
                 l.description AS translation
                 FROM chart c
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		 WHERE c.charttype = 'A'
                 AND c.closed = '0'
		 ORDER BY c.accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{PR} }, $ref;
  }
  $sth->finish;

  $form->all_years($myconfig, $dbh);

  $dbh->disconnect;

}


sub payment_transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my $query = qq|SELECT category FROM chart
                 WHERE accno = '$form->{accno}'|;
  ($form->{category}) = $dbh->selectrow_array($query);

  unless ($form->{fromdate} || $form->{todate}) {
    ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }

  my $cleared;
  if ($form->{todate}) {
    $form->{recdate} = $form->current_date($myconfig, $form->{todate});
  } else {
    $form->{recdate} = $form->current_date($myconfig);
  }
   
  my $transdate = "";

  if ($form->{fromdate}) {
    $transdate = qq| AND ac.transdate < date '$form->{fromdate}'|;
    $cleared = qq| AND ac.cleared < date '$form->{fromdate}'|;
  } else {
    $cleared = qq| AND ac.cleared IS NOT NULL|;
  }
  
  # get beginning balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      WHERE ch.accno = '$form->{accno}'
	      AND ac.approved = '1'
	      $transdate
	      $cleared
	      |;
  ($form->{beginningbalance}) = $dbh->selectrow_array($query) if $form->{fromdate};

  # fx balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      WHERE ch.accno = '$form->{accno}'
	      AND ac.approved = '1'
	      AND ac.fx_transaction = '1'
	      $transdate
	      $cleared
	      |;
  ($form->{fx_balance}) = $dbh->selectrow_array($query) if $form->{fromdate};
  

  $transdate = "";
  $cleared = "";
  if ($form->{todate}) {
    $transdate = qq| AND ac.transdate <= date '$form->{todate}'|;
    $cleared = qq| AND ac.cleared <= date '$form->{todate}'|;
  }
 
  # get statement balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      WHERE ch.accno = '$form->{accno}'
	      AND ac.approved = '1'
	      $transdate
	      $cleared
	      |;
  ($form->{endingbalance}) = $dbh->selectrow_array($query);


  # fx balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      WHERE ch.accno = '$form->{accno}'
	      AND ac.approved = '1'
	      AND ac.fx_transaction = '1'
	      $transdate
	      $cleared
	      |;
  ($form->{fx_endingbalance}) = $dbh->selectrow_array($query);
  
  my %defaults = $form->get_defaults($dbh, \@{['fx%_accno_id','precision', 'company']});
  for (qw(precision company)) { $form->{$_} = $defaults{$_} }
 
  my $fx_transaction;
  if ($form->{fx_transaction}) {
   
    $fx_transaction = qq|
	      AND NOT ac.chart_id = $defaults{fxgainloss_accno_id}|;
		 
  } else {
    $fx_transaction = qq|
	      AND ac.fx_transaction = '0'|;
  }
 
  $transdate = "";
  $cleared = "";
  
  if ($form->{fromdate}) {
    $transdate .= qq| AND (ac.transdate >= '$form->{fromdate}' OR ac.cleared >= '$form->{fromdate}')|;
  }
  if ($form->{todate}) {
    $transdate .= qq| AND ac.transdate <= '$form->{todate}'|;
  }
 
  if ($form->{report}) {
    if (!$form->{fromdate}) {
      $form->{beginningbalance} = 0;
      $form->{fx_balance} = 0;
    }
  }
  
  if ($form->{report}) {
    $transdate = "";
    $cleared = qq| AND ac.cleared IS NOT NULL|;
    if ($form->{fromdate} || $form->{todate}) {
      $cleared = "";
      if ($form->{fromdate}) {
	$cleared = qq| AND ac.cleared >= '$form->{fromdate}'|;
      }
      if ($form->{todate}) {
	$cleared .= qq| AND ac.cleared <= '$form->{todate}'|;
      }
    }
  }

  my $union;
  
  $query = "";
  
  for (1 .. 2) {
    $query .= qq|$union
		SELECT ac.transdate, ac.source, ac.fx_transaction,
		ac.amount, ac.cleared, g.id, g.description
		FROM acc_trans ac
		JOIN chart ch ON (ac.chart_id = ch.id)
		JOIN gl g ON (g.id = ac.trans_id)
		WHERE ch.accno = '$form->{accno}'
		AND ac.approved = '1'
		$fx_transaction
		$transdate
		$cleared
		UNION
		SELECT ac.transdate, ac.source, ac.fx_transaction,
		ac.amount, ac.cleared, a.id, n.name
		FROM acc_trans ac
		JOIN chart ch ON (ac.chart_id = ch.id)
		JOIN ar a ON (a.id = ac.trans_id)
		JOIN customer n ON (n.id = a.customer_id)
		WHERE ch.accno = '$form->{accno}'
		AND ac.approved = '1'
		$fx_transaction
		$transdate
		$cleared
		UNION
		SELECT ac.transdate, ac.source, ac.fx_transaction,
		ac.amount, ac.cleared, a.id, n.name
		FROM acc_trans ac
		JOIN chart ch ON (ac.chart_id = ch.id)
		JOIN ap a ON (a.id = ac.trans_id)
		JOIN vendor n ON (n.id = a.vendor_id)
		WHERE ch.accno = '$form->{accno}'
		AND ac.approved = '1'
		$fx_transaction
		$transdate
		$cleared|;

    last if $form->{report};
    
    $union = "UNION ALL";
    
    $transdate = "";
    if ($form->{fromdate}) {
      $transdate = qq| AND ac.transdate < '$form->{fromdate}'|;
    }
    if ($form->{todate}) {
      $transdate .= qq| AND ac.transdate < '$form->{todate}'|;
    }
   
    $cleared = qq| AND ac.cleared IS NULL|;
  }
  
  $query .= " ORDER BY 1,2,3";

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $sameitem;
  my $samename;
  my $i = -1;
  my $sw;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    if ($i == -1) {
      $sw = $ref->{amount};
    }

    $ref->{oldcleared} = $ref->{cleared};
    
    if ($form->{summary}) {

      if ($ref->{amount} > 0 && $sw < 0) {
	$sameitem = "";
	$sw = $ref->{amount};
      }
      if ($ref->{amount} < 0 && $sw > 0) {
	$sameitem = "";
	$sw = $ref->{amount};
      }
      
      if ("$ref->{transdate}$ref->{source}" eq $sameitem) {
	if ($ref->{fx_transaction}) {
	  $form->{PR}->[$i]->{amount} += $ref->{amount};
	} else {
	  push @{ $form->{PR}->[$i]->{name} }, $ref->{description} if $ref->{description} ne $samename;
	  $form->{PR}->[$i]->{amount} += $ref->{amount};
	  $form->{PR}->[$i]->{id} .= " $ref->{id}" if $form->{PR}->[$i]->{id} !~ /$ref->{id}/;
	}
      } else {
	push @{ $ref->{name} }, $ref->{description};
	push @{ $form->{PR} }, $ref;
	$i++;
      }

    } else {
      push @{ $ref->{name} }, $ref->{description};
      push @{ $form->{PR} }, $ref;
    }

    $sameitem = "$ref->{transdate}$ref->{source}";
    $samename = $ref->{description};

  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub reconcile {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT id FROM chart
                 WHERE accno = '$form->{accno}'|;
  my ($chart_id) = $dbh->selectrow_array($query);
  $chart_id *= 1;
  
  my $i;
  my $trans_id;
  my $cleared;
  my $source;

  # clear flags
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"datecleared_$i"} ne $form->{"oldcleared_$i"}) {

      $cleared = ($form->{"cleared_$i"}) ? $form->{recdate} : '';
      $cleared = $form->dbquote($cleared, SQL_DATE);
      $source = ($form->{"source_$i"}) ? qq|AND source = |.$dbh->quote($form->{"source_$i"}) : qq|AND (source = '' OR source IS NULL)|;

      foreach $trans_id (split / /, $form->{"id_$i"}) {
	$query = qq|UPDATE acc_trans SET
	            cleared = $cleared
                    WHERE trans_id = $trans_id 
	            AND transdate = |.$form->dbquote($form->{"transdate_$i"}, SQL_DATE).qq|
	            AND chart_id = $chart_id
                    $source|;
        $dbh->do($query) || $form->dberror($query);
      }
      
    }
  }

  $dbh->disconnect;

}

1;

