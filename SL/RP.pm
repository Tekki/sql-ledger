#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# backend code for reports
#
#======================================================================

package RP;


sub yearend_statement {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  # if todate < existing yearends, delete GL and yearends
  my $query = qq|SELECT trans_id FROM yearend
                 WHERE transdate >= '$form->{todate}'|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  my @trans_id = ();
  my $id;
  while (($id) = $sth->fetchrow_array) {
    push @trans_id, $id;
  }
  $sth->finish;

  $query = qq|DELETE FROM gl
              WHERE id = ?|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|DELETE FROM acc_trans
              WHERE trans_id = ?|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|DELETE FROM yearend
              WHERE trans_id = ?|;
  my $yth = $dbh->prepare($query) || $form->dberror($query);
	      
  foreach $id (@trans_id) {
    $sth->execute($id);
    $ath->execute($id);
    $yth->execute($id);

    $sth->finish;
    $ath->finish;
    $yth->finish;
  }
  
  for (qw(I E)) {
    %{ $form->{$_} } = &get_accounts($form, $dbh, $form->{fromdate}, $form->{todate}, $_);
  }
  
  # disconnect
  $dbh->disconnect;

}


sub create_links {
  my ($self, $myconfig, $form, $vc) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->all_departments($myconfig, $dbh, $vc);
  
  $form->all_projects($myconfig, $dbh);

  $form->all_languages($myconfig, $dbh);

  $dbh->disconnect;

}


sub income_statement {
  my ($self, $myconfig, $form, $locale) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  unless ($form->{fromdate} || $form->{todate}) {
    ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{fromyear}, $form->{frommonth}, $form->{interval}) if $form->{fromyear} && $form->{frommonth};
  }

  if (!$form->{fromdate}) {
    ($form->{fromdate}) = $dbh->selectrow_array(qq|SELECT transdate FROM acc_trans ORDER BY transdate LIMIT 1|);
  }
  $form->{todate} ||= $form->current_date($myconfig);

  for (qw(fromdate todate)) { $form->{$_} = $form->datetonum($myconfig, $form->{$_}) }

  my $dateformat = $myconfig->{dateformat};
  $myconfig->{dateformat} = "yyyymmdd";

  $form->{transdate} = $form->{fromdate};
  $form->fdld($myconfig, $locale);

  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{exchangerate} = $form->get_exchangerate($myconfig, $dbh, $form->{currency}, $form->{todate});
  }

  $form->{exchangerate} ||= 1;
  $form->{longformat} *= 1;

  my @categories = qw(I E);
  my $fromdate;
  my $todate;
  my $i;
  my $j;
  my $k;
  my %c;
  my $interval;
  my $done;

  for (@categories) {
    $fromdate = $form->{fromdate};
    $todate = $form->{todate};

    $form->{period}{0}{this} = { fromdate => $locale->date($myconfig, $fromdate, $form->{longformat}), todate => $locale->date($myconfig, $todate, $form->{longformat}) };

    %c = &get_accounts($form, $dbh, $fromdate, $todate, $_, 1);
    &add_accounts($form, \%c, 'this', '0', $_);

    if ($form->{includeperiod} eq 'month') {
      $todate = $form->add_date($myconfig, $form->{ldm}, $form->{dd} - 1, "days");
      next if ($todate ge $form->{todate});
      
      $form->{period}{1}{this} = { fromdate => $locale->date($myconfig, $fromdate, $form->{longformat}), todate => $locale->date($myconfig, $todate, $form->{longformat}) };

      %c = &get_accounts($form, $dbh, $fromdate, $todate, $_, 1);
      &add_accounts($form, \%c, 'this', '1', $_);

      $interval = $form->{interval} || 12;
      $done = 0;

      for $i (1 .. $interval - 1) {
        last if $done;

        $fromdate = $form->add_date($myconfig, $form->{"fdm+$i"}, $form->{dd} - 1, "days");
        $todate = $form->add_date($myconfig, $form->{"ldm+$i"}, $form->{dd} - 1, "days");
        $j = $i + 1;

        if ($todate ge $form->{todate}) {
          $todate = $form->{todate};
          $done = 1;
        }

        $form->{period}{$j}{this} = { fromdate => $locale->date($myconfig, $fromdate, $form->{longformat}), todate => $locale->date($myconfig, $todate, $form->{longformat}) };

        %c = &get_accounts($form, $dbh, $fromdate, $todate, $_, 1);
        &add_accounts($form, \%c, 'this', $j, $_);

      }
    }

    if ($form->{includeperiod} eq 'quarter') {
      $todate = $form->add_date($myconfig, $form->{"ldm+2"}, $form->{dd} - 1, "days");
      next if ($todate ge $form->{todate});

      $form->{period}{1}{this} = { fromdate => $locale->date($myconfig, $fromdate, $form->{longformat}), todate => $locale->date($myconfig, $todate, $form->{longformat}) };

      %c = &get_accounts($form, $dbh, $fromdate, $todate, $_, 1);
      &add_accounts($form, \%c, 'this', '1', $_);

      $interval = ($form->{interval} / 3) || 4;
      $done = 0;

      for $i (1 .. $interval - 1) {
        last if $done;

        $j = $i * 3;
        $k = $j + 2;
        $fromdate = $form->add_date($myconfig, $form->{"fdm+$j"}, $form->{dd} - 1, "days");
        $todate = $form->add_date($myconfig, $form->{"ldm+$k"}, $form->{dd} - 1, "days");
        $j = $i + 1;

        if ($todate ge $form->{todate}) {
          $todate = $form->{todate};
          $done = 1;
        }

        $form->{period}{$j}{this} = { fromdate => $locale->date($myconfig, $fromdate, $form->{longformat}), todate => $locale->date($myconfig, $todate, $form->{longformat}) };

        %c = &get_accounts($form, $dbh, $fromdate, $todate, $_, 1);
        &add_accounts($form, \%c, 'this', $j, $_);

      }
    }
  }

  if ($form->{previousyear} && $form->{fromdate}) {
    for (@categories) {
      $fromdate = $form->add_date($myconfig, $form->{fromdate}, -1, "year");
      $todate = $form->add_date($myconfig, $form->{todate}, -1, "year");
      $form->{previousfromdate} = $fromdate;
      $form->{previoustodate} = $todate;

      $form->{period}{0}{previous} = { fromdate => $locale->date($myconfig, $fromdate, $form->{longformat}), todate => $locale->date($myconfig, $todate, $form->{longformat}) };

      %c = &get_accounts($form, $dbh, $fromdate, $todate, $_, 1);
      &add_accounts($form, \%c, 'previous', '0', $_);

      if ($form->{includeperiod} eq 'month') {
        $todate = $form->add_date($myconfig, $form->{ldm}, -1, "year");
        $todate = $form->add_date($myconfig, $todate, $form->{dd} - 1, "days");

        next if ($todate ge $form->{previoustodate});

        $form->{period}{1}{previous} = { fromdate => $locale->date($myconfig, $fromdate, $form->{longformat}), todate => $locale->date($myconfig, $todate, $form->{longformat}) };

        %c = &get_accounts($form, $dbh, $fromdate, $todate, $_, 1);
        &add_accounts($form, \%c, 'previous', '1', $_);

        $interval = $form->{interval} || 12;
        $done = 0;

        for $i (1 .. $interval - 1) {
          last if $done;

          $fromdate = $form->add_date($myconfig, $form->{"fdm+$i"}, -1, "year");
          $fromdate = $form->add_date($myconfig, $fromdate, $form->{dd} - 1, "days");
          $todate = $form->add_date($myconfig, $form->{"ldm+$i"}, -1, "year");
          $todate = $form->add_date($myconfig, $todate, $form->{dd} - 1, "days");

          $j = $i + 1;

          if ($todate ge $form->{previoustodate}) {
            $todate = $form->{previoustodate};
            $done = 1;
          }

          $form->{period}{$j}{previous} = { fromdate => $locale->date($myconfig, $fromdate, $form->{longformat}), todate => $locale->date($myconfig, $todate, $form->{longformat}) };

          %c = &get_accounts($form, $dbh, $fromdate, $todate, $_, 1);
          &add_accounts($form, \%c, 'previous', $j, $_);

        }
      }

      if ($form->{includeperiod} eq 'quarter') {
        $todate = $form->add_date($myconfig, $form->{"ldm+2"}, -1, "year");
        $todate = $form->add_date($myconfig, $todate, $form->{dd} - 1, "days");

        next if ($todate ge $form->{previoustodate});

        $form->{period}{1}{previous} = { fromdate => $locale->date($myconfig, $fromdate, $form->{longformat}), todate => $locale->date($myconfig, $todate, $form->{longformat}) };

        %c = &get_accounts($form, $dbh, $fromdate, $todate, $_, 1);
        &add_accounts($form, \%c, 'previous', '1', $_);

        $interval = ($form->{interval} / 3) || 4;
        $done = 0;

        for $i (1 .. $interval - 1) {
          last if $done;

          $j = $i * 3;
          $k = $j + 2;
          $fromdate = $form->add_date($myconfig, $form->{"fdm+$j"}, -1, "year");
          $fromdate = $form->add_date($myconfig, $fromdate, $form->{dd} - 1, "days");
          $todate = $form->add_date($myconfig, $form->{"ldm+$k"}, -1, "year");
          $todate = $form->add_date($myconfig, $todate, $form->{dd} - 1, "days");

          $j = $i + 1;

          if ($todate ge $form->{previoustodate}) {
            $todate = $form->{previoustodate};
            $done = 1;
          }

          $form->{period}{$j}{previous} = { fromdate => $locale->date($myconfig, $fromdate, $form->{longformat}), todate => $locale->date($myconfig, $todate, $form->{longformat}) };

          %c = &get_accounts($form, $dbh, $fromdate, $todate, $_, 1);
          &add_accounts($form, \%c, 'previous', $j, $_);

        }
      }
    }
  }

  my %defaults = $form->get_defaults($dbh, \@{['company','address','businessnumber','companywebsite','companyemail','tel','fax']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  $form->report_level($myconfig, $dbh);

  # disconnect
  $dbh->disconnect;

  $myconfig->{dateformat} = $dateformat;

}


sub balance_sheet {
  my ($self, $myconfig, $form, $locale) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{todate} = $form->datetonum($myconfig, $form->{todate});

  my $dateformat = $myconfig->{dateformat};
  $myconfig->{dateformat} = "yyyymmdd";

  $form->{decimalplaces} *= 1;
  $form->{longformat} *= 1;

  $form->{todate} ||= $form->current_date($myconfig);

  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{exchangerate} = $form->get_exchangerate($myconfig, $dbh, $form->{currency}, $form->{todate});
  }

  $form->{exchangerate} ||= 1;

  my $var;
  my %c;
  my $p = 1;
  my $i;
  my $j;
  my $k;

  $form->{period}{0}{this} = { todate => $locale->date($myconfig, $form->{todate}, $form->{longformat}) };

  $todate = $form->add_date($myconfig, $form->{todate}, -1, "year");
  $form->{period}{0}{previous} = { todate => $locale->date($myconfig, $todate, $form->{longformat}) };

  for (qw(A L Q)) {
    %c = &get_accounts($form, $dbh, undef, $form->{todate}, $_);
    &add_accounts($form, \%c, 'this', '0', $_);

    if ($form->{includeperiod} eq 'month') {
      $k = 11;
    }
    if ($form->{includeperiod} eq 'quarter') {
      $k = 3;
      $p = 3;
    }

    if ($form->{previousyear}) {
      $todate = $form->add_date($myconfig, $form->{todate}, -1, "year");

      %c = &get_accounts($form, $dbh, undef, $todate, $_);
      &add_accounts($form, \%c, 'previous', '0', $_);
    }

    for $i (1 .. $k) {
      $todate = $form->add_date($myconfig, $form->{todate}, ($i*$p*-1), "month");
      $form->{period}{$i}{this} = { todate => $locale->date($myconfig, $todate, $form->{longformat}) };

      %c = &get_accounts($form, $dbh, undef, $todate, $_);
      &add_accounts($form, \%c, 'this', $i, $_);

      if ($form->{previousyear}) {
        $todate = $form->add_date($myconfig, $todate, -1, "year");
        $form->{period}{$i}{previous} = { todate => $locale->date($myconfig, $todate, $form->{longformat}) };

        %c = &get_accounts($form, $dbh, undef, $todate, $_);
        &add_accounts($form, \%c, 'previous', $i, $_);
      }
    }
  }

  my %defaults = $form->get_defaults($dbh, \@{['company','address','businessnumber','companywebsite','companyemail','tel','fax']});

  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  $form->report_level($myconfig, $dbh);

  # disconnect
  $dbh->disconnect;

  $myconfig->{dateformat} = $dateformat;

}


sub add_accounts {
  my ($form, $c, $year, $period, $category) = @_;

  for my $var (keys %{$c}) {
    next unless $form->round_amount($c->{$var}{amount}, $form->{decimalplaces});

    $form->{accounts}{$var}{description} = $c->{$var}{description};
    $form->{accounts}{$var}{charttype} = $c->{$var}{charttype};

    for my $key (keys %{ $c->{$var} }) {
      $form->{$category}{$var}{$year}{$period}{$key} = $c->{$var}{$key};
    }
  }

}


sub get_accounts {
  my ($form, $dbh, $fromdate, $todate, $category, $excludeyearend) = @_;

  my %c;
  my $department_id;
  my $project_id;
  
  (undef, $department_id) = split /--/, $form->{department};
  (undef, $project_id) = split /--/, $form->{projectnumber};

  my $query;
  my $dpt_where;
  my $dpt_join;
  my $project;
  my $where = "1 = 1";
  my $glwhere = "";
  my $subwhere = "";
  my $yearendwhere = "1 = 1";
  my $item;
 
  # get headings
  $query = qq|SELECT c.accno, c.description, c.category,
              l.description AS translation
	      FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$form->{language_code}')
	      WHERE c.charttype = 'H'
	      AND c.category = '$category'
	      ORDER by c.accno|;

  if ($form->{accounttype} eq 'gifi')
  {
    $query = qq|SELECT g.accno, g.description, c.category,
                '' AS translation
		FROM gifi g
		JOIN chart c ON (c.gifi_accno = g.accno)
		WHERE c.charttype = 'H'
		AND c.category = '$category'
                UNION
                SELECT c.accno, c.description, c.category,
                l.description AS translation
                FROM chart c
                LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$form->{language_code}')
                WHERE c.charttype = 'H'
                AND c.category = '$category'
		ORDER BY 1|;
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  my @headingaccounts = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc))
  {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    
    $c{$ref->{accno}}{description} = $ref->{description};
    $c{$ref->{accno}}{charttype} = "H";
    $c{$ref->{accno}}{accno} = $ref->{accno};

    push @headingaccounts, $ref->{accno};
  }

  $sth->finish;

  if ($form->{method} eq 'cash' && !$todate) {
    $todate = $form->current_date($myconfig);
  }

  if ($fromdate) {
    if ($form->{method} eq 'cash') {
      $subwhere .= " AND ac.transdate >= '$fromdate'";
      $glwhere = " AND ac.transdate >= '$fromdate'";
    } else {
      $where .= " AND ac.transdate >= '$fromdate'";
    }
  }

  if ($todate) {
    $where .= " AND ac.transdate <= '$todate'";
    $subwhere .= " AND ac.transdate <= '$todate'";
    $yearendwhere = "ac.transdate < '$todate'";
  }

  if ($excludeyearend) {
    $ywhere = " AND ac.trans_id NOT IN
               (SELECT trans_id FROM yearend)";
	       
   if ($todate) {
      $ywhere = " AND ac.trans_id NOT IN
		 (SELECT trans_id FROM yearend
		  WHERE transdate <= '$todate')";
    }
       
    if ($fromdate) {
      $ywhere = " AND ac.trans_id NOT IN
		 (SELECT trans_id FROM yearend
		  WHERE transdate >= '$fromdate')";
      if ($todate) {
	$ywhere = " AND ac.trans_id NOT IN
		   (SELECT trans_id FROM yearend
		    WHERE transdate >= '$fromdate'
		    AND transdate <= '$todate')";
      }
    }
  }

  if ($department_id) {
    $dpt_join = qq|
               JOIN department t ON (a.department_id = t.id)
		  |;
    $dpt_where = qq|
               AND t.id = $department_id
	           |;
  }

  if ($project_id) {
    $project = qq|
                 AND ac.project_id = $project_id
		 |;
  }


  if ($form->{accounttype} eq 'gifi') {
    
    if ($form->{method} eq 'cash') {

	$query = qq|
	
	         SELECT g.accno, sum(ac.amount) AS amount,
		 g.description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN ar a ON (a.id = ac.trans_id)
	         JOIN gifi g ON (g.accno = c.gifi_accno)
	         $dpt_join
		 WHERE $where
		 AND a.approved = '1'
		 AND c.category = '$category'
		 $ywhere
		 $dpt_where
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans ac
		     JOIN chart c ON (ac.chart_id = c.id)
		     WHERE c.link LIKE '%AR_paid%'
		     AND ac.approved = '1'
		     $subwhere
		   )
		 $project
		 GROUP BY g.accno, g.description, c.category
		 
       UNION ALL
       
		 SELECT '' AS accno, SUM(ac.amount) AS amount,
		 '' AS description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN ar a ON (a.id = ac.trans_id)
	         $dpt_join
		 WHERE $where
		 AND ac.approved = '1'
                 AND c.category = '$category'
		 $ywhere
		 $dpt_where
		 AND c.gifi_accno = ''
		 AND ac.trans_id IN
		   (
		     SELECT ac.trans_id
		     FROM acc_trans ac
		     JOIN chart c ON (ac.chart_id = c.id)
		     WHERE c.link LIKE '%AR_paid%'
		     AND ac.approved = '1'
		     $subwhere
		   )
		 $project
		 GROUP BY c.category

       UNION ALL

       	         SELECT g.accno, sum(ac.amount) AS amount,
		 g.description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN ap a ON (a.id = ac.trans_id)
	         JOIN gifi g ON (g.accno = c.gifi_accno)
	         $dpt_join
		 WHERE $where
		 AND a.approved = '1'
                 AND c.category = '$category'
		 $ywhere
		 $dpt_where
		 AND ac.trans_id IN
		   (
		     SELECT ac.trans_id
		     FROM acc_trans ac
		     JOIN chart c ON (ac.chart_id = c.id)
		     WHERE c.link LIKE '%AP_paid%'
		     AND ac.approved = '1'
		     $subwhere
		   )
		 $project
		 GROUP BY g.accno, g.description, c.category
		 
       UNION ALL
       
		 SELECT '' AS accno, SUM(ac.amount) AS amount,
		 '' AS description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN ap a ON (a.id = ac.trans_id)
	         $dpt_join
		 WHERE $where
		 AND a.approved = '1'
                 AND c.category = '$category'
		 $ywhere
		 $dpt_where
		 AND c.gifi_accno = ''
		 AND ac.trans_id IN
		   (
		     SELECT ac.trans_id
		     FROM acc_trans ac
		     JOIN chart c ON (ac.chart_id = c.id)
		     WHERE c.link LIKE '%AP_paid%'
		     AND ac.approved = '1'
		     $subwhere
		   )
		 $project
		 GROUP BY c.category

       UNION ALL

-- add gl
	
	         SELECT g.accno, sum(ac.amount) AS amount,
		 g.description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN gifi g ON (g.accno = c.gifi_accno)
	         JOIN gl a ON (a.id = ac.trans_id)
	         $dpt_join
		 WHERE $where
		 AND a.approved = '1'
                 AND c.category = '$category'
		 $ywhere
		 $glwhere
		 $dpt_where
		 AND NOT (c.link = 'AR' OR c.link = 'AP')
		 $project
		 GROUP BY g.accno, g.description, c.category
		 
       UNION ALL
       
		 SELECT '' AS accno, SUM(ac.amount) AS amount,
		 '' AS description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN gl a ON (a.id = ac.trans_id)
	         $dpt_join
		 WHERE $where
		 AND a.approved = '1'
                 AND c.category = '$category'
		 $ywhere
		 $glwhere
		 $dpt_where
		 AND c.gifi_accno = ''
		 AND NOT (c.link = 'AR' OR c.link = 'AP')
		 $project
		 GROUP BY c.category
		 |;

    } else {

      if ($department_id) {
	$dpt_join = qq|
	      JOIN dpt_trans t ON (t.trans_id = ac.trans_id)
	      |;
	$dpt_where = qq|
               AND t.department_id = $department_id
	      |;
      }

      $query = qq|
      
	      SELECT g.accno, SUM(ac.amount) AS amount,
	      g.description, c.category
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      JOIN gifi g ON (c.gifi_accno = g.accno)
	      $dpt_join
	      WHERE $where
	      AND ac.approved = '1'
              AND c.category = '$category'
	      $ywhere
	      $dpt_where
	      $project
	      GROUP BY g.accno, g.description, c.category
	      
	   UNION ALL
	   
	      SELECT '' AS accno, SUM(ac.amount) AS amount,
	      '' AS description, c.category
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      $dpt_join
	      WHERE $where
	      AND ac.approved = '1'
              AND c.category = '$category'
	      $ywhere
	      $dpt_where
	      AND c.gifi_accno = ''
	      $project
	      GROUP BY c.category
	      |;

    }
    
  } else {    # standard account

    if ($form->{method} eq 'cash') {

      $query = qq|
	
	         SELECT c.accno, sum(ac.amount) AS amount,
		 c.description, c.category,
		 l.description AS translation
		 FROM acc_trans ac
		 JOIN chart c ON (c.id = ac.chart_id)
		 JOIN ar a ON (a.id = ac.trans_id)
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$form->{language_code}')
		 $dpt_join
		 WHERE $where
		 AND ac.approved = '1'
                 AND c.category = '$category'
	         $ywhere
		 $dpt_where
		 AND ac.trans_id IN
		   (
		     SELECT ac.trans_id
		     FROM acc_trans ac
		     JOIN chart c ON (ac.chart_id = c.id)
		     WHERE c.link LIKE '%AR_paid%'
		     AND ac.approved = '1'
		     $subwhere
		   )
		     
		 $project
		 GROUP BY c.accno, c.description, c.category, translation
		 
	UNION ALL
	
	         SELECT c.accno, sum(ac.amount) AS amount,
		 c.description, c.category,
		 l.description AS translation
		 FROM acc_trans ac
		 JOIN chart c ON (c.id = ac.chart_id)
		 JOIN ap a ON (a.id = ac.trans_id)
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$form->{language_code}')
		 $dpt_join
		 WHERE $where
		 AND a.approved = '1'
                 AND c.category = '$category'
	         $ywhere
		 $dpt_where
		 AND ac.trans_id IN
		   (
		     SELECT ac.trans_id
		     FROM acc_trans ac
		     JOIN chart c ON (ac.chart_id = c.id)
		     WHERE c.link LIKE '%AP_paid%'
		     AND ac.approved = '1'
		     $subwhere
		   )
		     
		 $project
		 GROUP BY c.accno, c.description, c.category, translation
		 
        UNION ALL

		 SELECT c.accno, sum(ac.amount) AS amount,
		 c.description, c.category,
		 l.description AS translation
		 FROM acc_trans ac
		 JOIN chart c ON (c.id = ac.chart_id)
		 JOIN gl a ON (a.id = ac.trans_id)
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$form->{language_code}')
		 $dpt_join
		 WHERE $where
		 AND a.approved = '1'
                 AND c.category = '$category'
	         $ywhere
		 $glwhere
		 $dpt_where
		 AND NOT (c.link = 'AR' OR c.link = 'AP')
		 $project
		 GROUP BY c.accno, c.description, c.category, translation
		 |;

    } else {
     
      if ($department_id) {
	$dpt_join = qq|
	      JOIN dpt_trans t ON (t.trans_id = ac.trans_id)
	      |;
	$dpt_where = qq|
               AND t.department_id = $department_id
	      |;
      }

	
      $query = qq|
      
		 SELECT c.accno, sum(ac.amount) AS amount,
		 c.description, c.category,
		 l.description AS translation
		 FROM acc_trans ac
		 JOIN chart c ON (c.id = ac.chart_id)
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$form->{language_code}')
		 $dpt_join
		 WHERE $where
		 AND ac.approved = '1'
                 AND c.category = '$category'
	         $ywhere
		 $dpt_where
		 $project
		 GROUP BY c.accno, c.description, c.category, translation
		 |;

    }
  }

  my @accno;
  my $accno;
  my $ref;
  
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $form->{exchangerate} ||= 1;

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    # get last heading account
    @accno = grep { $_ le "$ref->{accno}" } @headingaccounts;
    $accno = pop @accno;

    $ref->{amount} /= $form->{exchangerate};

    if ($accno && ($accno ne $ref->{accno}) ) {
      $c{$accno}{amount} += $ref->{amount};
    }
    
    $ref->{description} = $ref->{translation} if $ref->{translation};

    $c{$ref->{accno}}{accno} = $ref->{accno};
    $c{$ref->{accno}}{description} = $ref->{description};
    $c{$ref->{accno}}{charttype} = "A";

    $c{$ref->{accno}}{amount} += $ref->{amount};
  }
  $sth->finish;

  %c;

}



sub trial_balance {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my ($query, $sth, $ref);
  my %balance = ();
  my %trb = ();
  my $department_id;
  my $project_id;
  my @headingaccounts = ();
  my $dpt_where;
  my $dpt_join;
  my $project;
  
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $where = "ac.approved = '1'";
  my $invwhere = $where;
  
  (undef, $department_id) = split /--/, $form->{department};
  (undef, $project_id) = split /--/, $form->{projectnumber};

  if ($department_id) {
    $dpt_join = qq|
                JOIN dpt_trans t ON (ac.trans_id = t.trans_id)
		  |;
    $dpt_where = qq|
                AND t.department_id = $department_id
		|;
  }
  
  
  if ($project_id) {
    $project = qq|
                AND ac.project_id = $project_id
		|;
  }
  
  unless ($form->{fromdate} || $form->{todate}) {
    ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
   
  # get beginning balances
  if ($form->{fromdate}) {

    if ($form->{accounttype} eq 'gifi') {
      
      $query = qq|SELECT g.accno, c.category, SUM(ac.amount) AS amount,
                  g.description, c.contra
		  FROM acc_trans ac
		  JOIN chart c ON (ac.chart_id = c.id)
		  JOIN gifi g ON (c.gifi_accno = g.accno)
		  $dpt_join
		  WHERE ac.transdate < '$form->{fromdate}'
		  AND ac.approved = '1'
		  $dpt_where
		  $project
		  GROUP BY g.accno, c.category, g.description, c.contra
		  |;
   
    } else {
      
      $query = qq|SELECT c.accno, c.category, SUM(ac.amount) AS amount,
                  c.description, c.contra,
		  l.description AS translation
		  FROM acc_trans ac
		  JOIN chart c ON (ac.chart_id = c.id)
		  LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$form->{language_code}')
		  $dpt_join
		  WHERE ac.transdate < '$form->{fromdate}'
		  AND ac.approved = '1'
		  $dpt_where
		  $project
		  GROUP BY c.accno, c.category, c.description, c.contra, translation
		  |;
		  
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{amount} = $form->round_amount($ref->{amount}, $form->{precision});
      $balance{$ref->{accno}} = $ref->{amount};

      $ref->{description} = $ref->{translation} if $ref->{translation};

      if ($form->{all_accounts}) {
	$trb{$ref->{accno}}{description} = $ref->{description};
	$trb{$ref->{accno}}{charttype} = 'A';
	$trb{$ref->{accno}}{category} = $ref->{category};
	$trb{$ref->{accno}}{contra} = $ref->{contra};
      }

    }
    $sth->finish;

  }
  

  # get headings
  $query = qq|SELECT c.accno, c.description, c.category,
              l.description AS translation
	      FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$form->{language_code}')
	      WHERE c.charttype = 'H'
	      ORDER by c.accno|;

  if ($form->{accounttype} eq 'gifi')
  {
    $query = qq|SELECT g.accno, g.description, c.category, c.contra
		FROM gifi g
		JOIN chart c ON (c.gifi_accno = g.accno)
		WHERE c.charttype = 'H'
		ORDER BY g.accno|;
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc))
  {
    $ref->{description} = $ref->{translation} if $ref->{translation};

    $trb{$ref->{accno}}{description} = $ref->{description};
    $trb{$ref->{accno}}{charttype} = 'H';
    $trb{$ref->{accno}}{category} = $ref->{category};
    $trb{$ref->{accno}}{contra} = $ref->{contra};
   
    push @headingaccounts, $ref->{accno};
  }

  $sth->finish;


  if ($form->{fromdate} || $form->{todate}) {
    if ($form->{fromdate}) {
      $where .= " AND ac.transdate >= '$form->{fromdate}'";
      $invwhere .= " AND a.transdate >= '$form->{fromdate}'";
    }
    if ($form->{todate}) {
      $where .= " AND ac.transdate <= '$form->{todate}'";
      $invwhere .= " AND a.transdate <= '$form->{todate}'";
    }
  }


  if ($form->{accounttype} eq 'gifi') {

    $query = qq|SELECT g.accno, g.description, c.category,
                SUM(ac.amount) AS amount, c.contra
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		JOIN gifi g ON (c.gifi_accno = g.accno)
		$dpt_join
		WHERE $where
		$dpt_where
		$project
		GROUP BY g.accno, g.description, c.category, c.contra
		ORDER BY g.accno|;
    
  } else {

    $query = qq|SELECT c.accno, c.description, c.category,
                SUM(ac.amount) AS amount, c.contra,
		l.description AS translation
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$form->{countrycode}')
		$dpt_join
		WHERE $where
		$dpt_where
		$project
		GROUP BY c.accno, c.description, c.category, c.contra, translation
                ORDER BY c.accno|;

  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  # prepare query for each account
  $query = qq|SELECT (SELECT SUM(ac.amount) * -1
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      $dpt_join
	      WHERE $where
	      $dpt_where
	      $project
	      AND ac.amount < 0
	      AND c.accno = ?) AS debit,
	      
	     (SELECT SUM(ac.amount)
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      $dpt_join
	      WHERE $where
	      $dpt_where
	      $project
	      AND ac.amount > 0
	      AND c.accno = ?) AS credit
	      |;

  if ($form->{accounttype} eq 'gifi') {

    $query = qq|SELECT (SELECT SUM(ac.amount) * -1
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		$dpt_join
		WHERE $where
		$dpt_where
		$project
		AND ac.amount < 0
		AND c.gifi_accno = ?) AS debit,
		
	       (SELECT SUM(ac.amount)
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		$dpt_join
		WHERE $where
		$dpt_where
		$project
		AND ac.amount > 0
		AND c.gifi_accno = ?) AS credit|;
  
  }
  
  $drcr = $dbh->prepare($query);

  # calculate debit and credit for the period
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};

    $trb{$ref->{accno}}{description} = $ref->{description};
    $trb{$ref->{accno}}{charttype} = 'A';
    $trb{$ref->{accno}}{category} = $ref->{category};
    $trb{$ref->{accno}}{contra} = $ref->{contra};
    $trb{$ref->{accno}}{amount} += $ref->{amount};
  }
  $sth->finish;

  my ($debit, $credit);
  
  foreach my $accno (sort keys %trb) {
    $ref = ();
    
    $ref->{accno} = $accno;
    for (qw(description category contra charttype amount)) { $ref->{$_} = $trb{$accno}{$_} }
    
    $ref->{balance} = $balance{$ref->{accno}};

    if ($trb{$accno}{charttype} eq 'A') {
      if ($project_id) {

        if ($ref->{amount} < 0) {
	  $ref->{debit} = $ref->{amount} * -1;
	} else {
	  $ref->{credit} = $ref->{amount};
	}
	next if $form->round_amount($ref->{amount}, $form->{precision}) == 0;

      } else {
	
	# get DR/CR
	$drcr->execute($ref->{accno}, $ref->{accno});
	
	($debit, $credit) = (0,0);
	while (($debit, $credit) = $drcr->fetchrow_array) {
	  $ref->{debit} += $debit;
	  $ref->{credit} += $credit;
	}
	$drcr->finish;

      }

      $ref->{debit} = $form->round_amount($ref->{debit}, $form->{precision});
      $ref->{credit} = $form->round_amount($ref->{credit}, $form->{precision});
    
      if (!$form->{all_accounts}) {
	next if $form->round_amount($ref->{debit} + $ref->{credit}, $form->{precision}) == 0;
      }
    }

    # add subtotal
    @accno = grep { $_ le "$ref->{accno}" } @headingaccounts;
    $accno = pop @accno;
    if ($accno) {
      $trb{$accno}{debit} += $ref->{debit};
      $trb{$accno}{credit} += $ref->{credit};
    }

    push @{ $form->{TB} }, $ref;
    
  }

  $form->report_level($myconfig, $dbh);

  $dbh->disconnect;

  # debits and credits for headings
  foreach $accno (@headingaccounts) {
    foreach $ref (@{ $form->{TB} }) {
      if ($accno eq $ref->{accno}) {
        $ref->{debit} = $trb{$accno}{debit};
        $ref->{credit} = $trb{$accno}{credit};
      }
    }
  }

}


sub aging {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $invoice = ($form->{arap} eq 'ar') ? 'is' : 'ir';

  my $query;

  my $item;
  my $curr;
  
  my @df = qw(company address businessnumber tel fax precision companyemail companywebsite);
  my %defaults = $form->get_defaults($dbh, \@df);
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  $form->get_peripherals($dbh);
  for (@{ $form->{all_printer} }) {
    $form->{"$_->{printer}_printer"} = $_->{command};
  }

  $form->{currencies} = $form->get_currencies($myconfig, $dbh);

  unless ($form->{todate}) {
    (undef, $form->{todate}) = $form->from_to($form->{year}, $form->{month}) if $form->{year} && $form->{month};
  }
  
  if (! $form->{todate}) {
    $form->{todate} = $form->current_date($myconfig);
  }
    
  my $where = "a.approved = '1'";
  my $name;
  my $ref;
  my $transdate = ($form->{overdue}) ? "duedate" : "transdate";

  $form->{vc} =~ s/;//g;

  if ($form->{"$form->{vc}_id"}) {
    $where .= qq| AND vc.id = $form->{"$form->{vc}_id"}|;
  } else {
    if ($form->{$form->{vc}} ne "") {
      $name = $form->like(lc $form->{$form->{vc}});
      $where .= qq| AND lower(vc.name) LIKE '$name'|;
    }
    if ($form->{"$form->{vc}number"} ne "") {
      $name = $form->like(lc $form->{"$form->{vc}number"});
      $where .= qq| AND lower(vc.$form->{vc}number) LIKE '$name'|;
    }
  }

  if ($form->{department}) {
    (undef, $department_id) = split /--/, $form->{department};
    $where .= qq| AND a.department_id = $department_id|;
  }
  
  $form->{sort} =~ s/;//g;
  my $sortorder = $form->{sort} || "name";
  
  # select outstanding vendors or customers
  $query = qq|SELECT DISTINCT vc.id, vc.name, vc.$form->{vc}number,
              vc.language_code
              FROM $form->{vc} vc
	      JOIN $form->{arap} a ON (a.$form->{vc}_id = vc.id)
	      WHERE $where
              AND a.paid != a.amount
              AND (a.$transdate <= '$form->{todate}')
              ORDER BY vc.$sortorder|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror;
  
  my @ot = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @ot, $ref;
  }
  $sth->finish;

  my %interval = ( 'Pg' => {
                        'c0' => "(date '$form->{todate}' - interval '0 days')",
			'c15' => "(date '$form->{todate}' - interval '15 days')",
			'c30' => "(date '$form->{todate}' - interval '30 days')",
			'c45' => "(date '$form->{todate}' - interval '45 days')",
			'c60' => "(date '$form->{todate}' - interval '60 days')",
			'c75' => "(date '$form->{todate}' - interval '75 days')",
			'c90' => "(date '$form->{todate}' - interval '90 days')" },
		  'DB2' => {
		        'c0' => "(date ('$form->{todate}') - 0 days)",
			'c15' => "(date ('$form->{todate}') - 15 days)",
			'c30' => "(date ('$form->{todate}') - 30 days)",
			'c45' => "(date ('$form->{todate}') - 45 days)",
			'c60' => "(date ('$form->{todate}') - 60 days)",
			'c75' => "(date ('$form->{todate}') - 75 days)",
			'c90' => "(date ('$form->{todate}') - 90 days)" }
		);

  $interval{Oracle} = $interval{PgPP} = $interval{Pg};
  
  # for each company that has some stuff outstanding
  $form->{currencies} ||= ":";
  
  $where = qq|
	a.paid != a.amount
	AND a.approved = '1'
	AND c.id = ?
	AND a.curr = ?|;
	
  if ($department_id) {
    $where .= qq| AND a.department_id = $department_id|;
  }

  $form->{AG} = ();

  $query = "";
  my $union = "";

  my %c = (c0 => { flds => '(a.amount - a.paid) AS c0, 0.00 AS c15, 0.00 AS c30, 0.00 AS c45, 0.00 AS c60, 0.00 AS c75, 0.00 AS c90' },
           c15 => { flds => '0.00 AS c0, (a.amount - a.paid) AS c15, 0.00 AS c30, 0.00 AS c45, 0.00 AS c60, 0.00 AS c75, 0.00 AS c90' },
           c30 => { flds => '0.00 AS c0, 0.00 AS c15, (a.amount - a.paid) AS c30, 0.00 AS c45, 0.00 AS c60, 0.00 AS c75, 0.00 AS c90' },
           c45 => { flds => '0.00 AS c0, 0.00 AS c15, 0.00 AS c30, (a.amount - a.paid) AS c45, 0.00 AS c60, 0.00 AS c75, 0.00 AS c90' },
           c60 => { flds => '0.00 AS c0, 0.00 AS c15, 0.00 AS c30, 0.00 AS c45, (a.amount - a.paid) AS c60, 0.00 AS c75, 0.00 AS c90' },
           c75 => { flds => '0.00 AS c0, 0.00 AS c15, 0.00 AS c30, 0.00 AS c45, 0.00 AS c60, (a.amount - a.paid) AS c75, 0.00 AS c90' },
           c90 => { flds => '0.00 AS c0, 0.00 AS c15, 0.00 AS c30, 0.00 AS c45, 0.00 AS c60, 0.00 AS c75, (a.amount - a.paid) AS c90' }
	  );
  
  my @c = ();

  for (qw(c0 c15 c30 c45 c45 c60 c75 c90)) {
    if ($form->{$_}) {
      push @c, $_;
    }
  }

  my %ordinal = ( 'vc_id' => 1,
                  'invnumber' => 16,
                  'transdate' => 17
                );

  my @sf = qw(vc_id transdate invnumber);
  my $sortorder = $form->sort_order(\@sf, \%ordinal);
      
  if (@c) {
    
    $item = $#c;
    $c{$c[$item]}{and} = qq|AND a.$transdate < $interval{$myconfig->{dbdriver}}{$c[$item]}|;

    if ($item > 0) {
      $c{$c[0]}{and} = qq|
	    AND (
		    a.$transdate <= $interval{$myconfig->{dbdriver}}{$c[0]}
		    AND a.$transdate >= $interval{$myconfig->{dbdriver}}{$c[1]}
		)|;
    }
   
    for (1 .. $item - 1) {
      $c{$c[$_]}{and} = qq|
	    AND (
		    a.$transdate < $interval{$myconfig->{dbdriver}}{$c[$_]}
		    AND a.$transdate >= $interval{$myconfig->{dbdriver}}{$c[$_+1]}
		)|;
    }

    for (@c) {
      
      $query .= qq|$union
      SELECT c.id AS vc_id, c.$form->{vc}number, c.name,
      ad.address1, ad.address2, ad.city, ad.state, ad.zipcode, ad.country,
      c.contact,
      c.phone as $form->{vc}phone, c.fax as $form->{vc}fax,
      c.$form->{vc}number, c.taxnumber as $form->{vc}taxnumber,
      a.description AS invdescription,
      a.invnumber, a.transdate, a.till, a.ordnumber, a.ponumber, a.notes,
      $c{$_}{flds},
      a.duedate, a.invoice, a.id, a.curr,
	(SELECT exchangerate FROM exchangerate e
	 WHERE a.curr = e.curr
	 AND e.transdate = a.transdate) AS exchangerate,
      ct.firstname, ct.lastname, ct.salutation, ct.typeofcontact,
      s.*
      FROM $form->{arap} a
      JOIN $form->{vc} c ON (a.$form->{vc}_id = c.id)
      JOIN address ad ON (ad.trans_id = c.id)
      LEFT JOIN contact ct ON (ct.trans_id = c.id)
      LEFT JOIN shipto s ON (a.id = s.trans_id)
      WHERE $where
      $c{$_}{and}
|;

      $union = qq|
      UNION
|;
    }
	    
    $query .= qq| ORDER BY $sortorder|;

    $sth = $dbh->prepare($query) || $form->dberror($query);

    my @var;
    my $i;
    
    foreach $curr (split /:/, $form->{currencies}) {
    
      foreach $item (@ot) {

	@var = ();
	for (@c) { push @var, ($item->{id}, $curr) }
	
        $sth->execute(@var);

        while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
          $ref->{module} = ($ref->{invoice}) ? $invoice : $form->{arap};
          $ref->{module} = 'ps' if $ref->{till};
          $ref->{exchangerate} ||= 1;
          $ref->{language_code} = $item->{language_code};

          push @{ $form->{AG} }, $ref;
        }
        $sth->finish;
      }
    }
  }

  # get language
  $form->all_languages($myconfig, $dbh);
  
  $form->report_level($myconfig, $dbh);

  # disconnect
  $dbh->disconnect;

}


sub reminder {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;

  my $item;
  my $curr;
  
  my @df = qw(company companyemail companywebsite address businessnumber tel fax precision);
  my %defaults = $form->get_defaults($dbh, \@df);
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  $form->get_peripherals($dbh);
  for (@{ $form->{all_printer} }) {
    $form->{"$_->{printer}_printer"} = $_->{command};
  }

  $form->{currencies} = $form->get_currencies($myconfig, $dbh);
  
  my $where = "a.approved = '1'";
  my $name;
  my $vc_id;
  my $ref;

  $form->{vc} =~ s/;//g;

  (undef, $vc_id) = split /--/, $form->{$form->{vc}};
      
  if ($vc_id) {
    $where .= qq| AND vc.id = $vc_id|;
  } else {
    if ($form->{$form->{vc}} ne "") {
      $name = $form->like(lc $form->{$form->{vc}});
      $where .= qq| AND lower(vc.name) LIKE '$name'|;
    }
    if ($form->{"$form->{vc}number"} ne "") {
      $name = $form->like(lc $form->{"$form->{vc}number"});
      $where .= qq| AND lower(vc.$form->{vc}number) LIKE '$name'|;
    }
  }

  if ($form->{department}) {
    (undef, $department_id) = split /--/, $form->{department};
    $where .= qq| AND a.department_id = $department_id|;
  }
  
  $form->{sort} =~ s/;//g;
  my $sortorder = $form->{sort} || "name";
  
  # select outstanding customers
  $query = qq|SELECT DISTINCT vc.id, vc.name, vc.$form->{vc}number,
              vc.language_code
              FROM $form->{vc} vc
              JOIN ar a ON (a.$form->{vc}_id = vc.id)
              WHERE $where
              AND a.paid != a.amount
              ORDER BY vc.$sortorder|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror;

  my @ot = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @ot, $ref;
  }
  $sth->finish;

  $query = qq|SELECT s.formname
              FROM status s
              JOIN ar a ON (a.id = s.trans_id)
              WHERE s.formname LIKE 'reminder_'
              AND s.trans_id = ?
              AND a.curr = ?
              ORDER BY s.formname DESC|;
  my $rth = $dbh->prepare($query);

  # for each company that has some stuff outstanding
  $form->{currencies} ||= ":";
  
  $where = qq|
	a.paid != a.amount
	AND a.approved = '1'
	AND a.duedate <= current_date
	AND c.id = ?
	AND a.curr = ?|;
	
  if ($department_id) {
    $where .= qq| AND a.department_id = $department_id|;
  }

  my %ordinal = ( 'vc_id' => 1,
                  'invnumber' => 19,
                  'transdate' => 20
                );

  my @sf = qw(vc_id transdate invnumber);
  my $sortorder = $form->sort_order(\@sf, \%ordinal);
      
  $query = qq|SELECT c.id AS vc_id, c.$form->{vc}number, c.name, c.terms,
              ad.address1, ad.address2, ad.city, ad.state, ad.zipcode, ad.country,
              c.contact,
              c.phone as $form->{vc}phone, c.fax as $form->{vc}fax,
              c.$form->{vc}number, c.taxnumber as $form->{vc}taxnumber,
              a.dcn, a.bank_id, a.description AS invdescription,
              a.invnumber, a.transdate, a.till, a.ordnumber, a.ponumber, a.notes,
              a.amount - a.paid AS due,
              a.duedate, a.invoice, a.id, a.curr,
          (SELECT exchangerate FROM exchangerate e
           WHERE a.curr = e.curr
           AND e.transdate = a.transdate) AS exchangerate,
              ct.firstname, ct.lastname, ct.salutation, ct.typeofcontact,
              s.*
              FROM ar a
              JOIN $form->{vc} c ON (a.$form->{vc}_id = c.id)
              JOIN address ad ON (ad.trans_id = c.id)
              LEFT JOIN contact ct ON (ct.trans_id = c.id)
              LEFT JOIN shipto s ON (a.id = s.trans_id)
              WHERE a.duedate <= current_date
              AND $where
              ORDER BY $sortorder|;

  $sth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT b.*, a.*
              FROM bank b
              LEFT JOIN address a ON (a.id = b.address_id)
              WHERE b.id = ?|;
  my $bth = $dbh->prepare($query) || $form->dberror($query);
  my $bank;
  
  $form->{AG} = ();
  
  for $curr (split /:/, $form->{currencies}) {
  
    for $item (@ot) {

      $sth->execute($item->{id}, $curr);

      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
        $ref->{module} = ($ref->{invoice}) ? 'is' : 'ar';
        $ref->{module} = 'ps' if $ref->{till};
        $ref->{exchangerate} ||= 1;
        $ref->{language_code} = $item->{language_code};

        $bth->execute($ref->{bank_id});
        $bank = $bth->fetchrow_hashref(NAME_lc);
        for (qw(rvc iban bic membernumber clearingnumber)) {
          $ref->{$_} = $bank->{$_};
          delete $bank->{$_};
        }
        for (keys %$bank) {
          $ref->{"bank$_"} = $bank->{$_};
        }
        $bth->finish;

        $rth->execute($ref->{id}, $curr);
        $found = 0;
        while (($reminder) = $rth->fetchrow_array) {
          $ref->{level} = substr($reminder, -1);
          $ref->{level}++;
          push @{ $form->{AG} }, $ref;
          $found = 1;
        }
        $rth->finish;

        if (! $found) {
          $ref->{level}++;
          push @{ $form->{AG} }, $ref;
        }
      }
      $sth->finish;

    }
  }

  # get language
  $form->all_languages($myconfig, $dbh);

  $form->report_level($myconfig, $dbh);

  # disconnect
  $dbh->disconnect;

}


sub save_level {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;

  $query = qq|DELETE FROM status
              WHERE trans_id = ?
	      AND formname LIKE 'reminder_'|;
  my $dth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|INSERT INTO status (trans_id, formname)
              VALUES (?,?)|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);
  
  for (split / /, $form->{ids}) {
    if ($form->{"ndx_$_"}) {

      $dth->execute($_) || $form->dberror;
      $dth->finish;

      if ($form->{"level_$_"} *= 1) {
	$ath->execute($_, qq|reminder$form->{"level_$_"}|) || $form->dberror;
	$ath->finish;
      }
    }
  }
  
  my $rc = $dbh->commit;

  $dbh->disconnect;
  
  $rc;

}


sub get_customer {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{vc} =~ s/;//g;

  my $query = qq|SELECT name, email, cc, bcc
                 FROM $form->{vc} ct
		 WHERE ct.id = $form->{"$form->{vc}_id"}|;
  ($form->{$form->{vc}}, $form->{email}, $form->{cc}, $form->{bcc}) = $dbh->selectrow_array($query);

  $dbh->disconnect;

}


sub get_taxaccounts {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $ARAP = uc $form->{db};
  
  # get tax accounts
  my $query = qq|SELECT DISTINCT c.accno, c.description,
                 l.description AS translation
                 FROM chart c
		 JOIN tax t ON (c.id = t.chart_id)
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		 WHERE c.link LIKE '%${ARAP}_tax%'
                 AND c.closed = '0'
                 ORDER BY c.accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror;

  my $ref = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc) ) {
    push @{ $form->{taxaccounts} }, $ref;
  }
  $sth->finish;

  # get gifi tax accounts
  my $query = qq|SELECT DISTINCT g.accno, g.description
                 FROM gifi g
		 JOIN chart c ON (c.gifi_accno= g.accno)
		 JOIN tax t ON (c.id = t.chart_id)
		 WHERE c.link LIKE '%${ARAP}_tax%'
                 ORDER BY g.accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror;

  while ($ref = $sth->fetchrow_hashref(NAME_lc) ) {
    push @{ $form->{gifi_taxaccounts} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}



sub tax_report {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $department_id;
  (undef, $department_id) = split /--/, $form->{department};
  
  # build WHERE
  my $where = "a.approved = '1'";
  my $cashwhere = "";
  
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
 
  if ($department_id) {
    $where .= qq|
                 AND a.department_id = $department_id
		|;
  }
  
  my $query;
  my $sth;
  my $accno;
  my $l_gifi;
  my @gifi = split / /, $form->{gifi_taxaccounts};
  my @c;
 
  for (@gifi) {
    if ($form->{"gifi_$_"}) {
      $l_gifi = 1;
      last;
    }
  }

  if ($l_gifi) {
    $accno = qq| AND (|;
    for (@gifi) {
      if ($form->{"gifi_$_"}) {
        push @c, qq| ch.gifi_accno = '$_' |;
      }
    }
    $accno = qq| AND (| . join 'OR', @c;
    $accno .= qq|)|;
  } else {
    $accno = qq| AND (|;
    for (split / /, $form->{taxaccounts}) {
      if ($form->{"accno_$_"}) {
        push @c, qq| ch.accno = '$_' |;
      }
    }
    $accno = qq| AND (| . join 'OR', @c;
    $accno .= qq|)|;
  }
  $accno =~ s/ AND \(\)/ AND (ch.accno = '0')/;

  my $vc;
  my $ARAP;
  
  $form->{db} =~ s/;//g;

  if ($form->{db} eq 'ar') {
    $vc = "customer";
    $ARAP = "AR";
  }
  if ($form->{db} eq 'ap') {
    $vc = "vendor";
    $ARAP = "AP";
  }

  my $transdate = "a.transdate";

  unless ($form->{fromdate} || $form->{todate}) {
    ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
  
  # if there are any dates construct a where
  if ($form->{fromdate} || $form->{todate}) {
    if ($form->{fromdate}) {
      $where .= " AND $transdate >= '$form->{fromdate}'";
    }
    if ($form->{todate}) {
      $where .= " AND $transdate <= '$form->{todate}'";
    }
  }


  if ($form->{method} eq 'cash') {
    $transdate = "a.datepaid";

    my $todate = $form->{todate};
    if (! $todate) {
      $todate = $form->current_date($myconfig);
    }
    
    $cashwhere = qq|
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = chart.id)
		     WHERE link LIKE '%${ARAP}_paid%'
		     AND a.approved = '1'
		     AND $transdate <= '$todate'
		     AND a.paid = a.amount
		   )
		  |;

  }

    
  my $ml = ($form->{db} eq 'ar') ? 1 : -1;
  
  if ($form->{summary}) {
    
    $query = qq|SELECT a.id, a.invoice, $transdate AS transdate,
                a.invnumber, n.name, n.${vc}number, n.taxnumber,
                ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
                a.netamount, a.description,
                sum(ac.amount) * $ml AS tax,
                a.till, n.id AS vc_id, ch.accno
                FROM acc_trans ac
                JOIN $form->{db} a ON (a.id = ac.trans_id)
                JOIN chart ch ON (ch.id = ac.chart_id)
                JOIN $vc n ON (n.id = a.${vc}_id)
                JOIN address ad ON (ad.trans_id = n.id)
                WHERE $where
                $accno
                $cashwhere
                GROUP BY a.id, a.invoice, $transdate, a.invnumber, n.name,
                a.netamount, a.till, n.id, a.description, n.${vc}number,
                n.taxnumber,
                ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
                ch.accno
                |;

    if ($form->{fromdate}) {
      # include open transactions from previous period
      if ($cashwhere) {
        $query .= qq|
            UNION
            
              SELECT a.id, a.invoice, $transdate AS transdate,
              a.invnumber, n.name, n.${vc}number, n.taxnumber,
              ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
              a.netamount, a.description,
              sum(ac.amount) * $ml AS tax,
              a.till, n.id AS vc_id, ch.accno
              FROM acc_trans ac
              JOIN $form->{db} a ON (a.id = ac.trans_id)
              JOIN chart ch ON (ch.id = ac.chart_id)
              JOIN $vc n ON (n.id = a.${vc}_id)
              JOIN address ad ON (ad.trans_id = n.id)
              WHERE a.datepaid >= '$form->{fromdate}'
              $accno
              $cashwhere
              GROUP BY a.id, a.invoice, $transdate, a.invnumber, n.name,
              a.netamount, a.till, n.id, a.description, n.${vc}number,
              n.taxnumber,
              ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
              ch.accno
              |;
      }
    }

  } else {
      
    $query = qq|SELECT a.id, '0' AS invoice, $transdate AS transdate,
                a.invnumber, n.name, n.${vc}number, n.taxnumber,
                ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
                a.netamount, ac.memo AS description,
                ac.amount * $ml AS tax,
                a.till, n.id AS vc_id, ch.accno
                FROM acc_trans ac
                JOIN $form->{db} a ON (a.id = ac.trans_id)
                JOIN chart ch ON (ch.id = ac.chart_id)
                JOIN $vc n ON (n.id = a.${vc}_id)
                JOIN address ad ON (ad.trans_id = n.id)
                WHERE $where
                $accno
                AND a.invoice = '0'
                AND NOT (ch.link LIKE '%_paid' OR ch.link = '$ARAP')
                $cashwhere
          
              UNION ALL
              
                SELECT a.id, '1' AS invoice, $transdate AS transdate,
                a.invnumber, n.name, n.${vc}number, n.taxnumber,
                ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
                i.sellprice * i.qty * $ml AS netamount,
                i.description,
                i.sellprice * i.qty * $ml *
                (SELECT tx.rate FROM tax tx WHERE tx.chart_id = ch.id AND (tx.validto > $transdate OR tx.validto IS NULL) ORDER BY tx.validto LIMIT 1) AS tax,
                a.till, n.id AS vc_id, ch.accno
                FROM acc_trans ac
                JOIN $form->{db} a ON (a.id = ac.trans_id)
                JOIN chart ch ON (ch.id = ac.chart_id)
                JOIN $vc n ON (n.id = a.${vc}_id)
                JOIN address ad ON (ad.trans_id = n.id)
                JOIN ${vc}tax t ON (t.${vc}_id = n.id AND t.chart_id = ch.id)
                JOIN invoice i ON (i.trans_id = a.id)
                JOIN partstax pt ON (pt.parts_id = i.parts_id AND pt.chart_id = ch.id)
                WHERE $where
                $accno
                AND a.invoice = '1'
                AND i.parts_id IN (SELECT parts_id FROM partstax)
                $cashwhere
          |;

    if ($form->{fromdate}) {
      if ($cashwhere) {
       $query .= qq|
            UNION
            
              SELECT a.id, '0' AS invoice, $transdate AS transdate,
              a.invnumber, n.name, n.${vc}number, n.taxnumber,
              ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
              a.netamount, ac.memo AS description,
              ac.amount * $ml AS tax,
              a.till, n.id AS vc_id, ch.accno
              FROM acc_trans ac
              JOIN $form->{db} a ON (a.id = ac.trans_id)
              JOIN chart ch ON (ch.id = ac.chart_id)
              JOIN $vc n ON (n.id = a.${vc}_id)
              JOIN address ad ON (ad.trans_id = n.id)
              WHERE a.datepaid >= '$form->{fromdate}'
              $accno
              AND a.invoice = '0'
              AND NOT (ch.link LIKE '%_paid' OR ch.link = '$ARAP')
              $cashwhere
              
            UNION
            
              SELECT a.id, '1' AS invoice, $transdate AS transdate,
              a.invnumber, n.name, n.${vc}number, n.taxnumber,
              ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
              i.sellprice * i.qty * $ml AS netamount,
              i.description,
              i.sellprice * i.qty * $ml *
              (SELECT tx.rate FROM tax tx WHERE tx.chart_id = ch.id AND (tx.validto > $transdate OR tx.validto IS NULL) ORDER BY tx.validto LIMIT 1) AS tax,
              a.till, n.id AS vc_id, ch.accno
              FROM acc_trans ac
              JOIN $form->{db} a ON (a.id = ac.trans_id)
              JOIN chart ch ON (ch.id = ac.chart_id)
              JOIN $vc n ON (n.id = a.${vc}_id)
              JOIN address ad ON (ad.trans_id = n.id)
              JOIN ${vc}tax t ON (t.${vc}_id = n.id AND t.chart_id = ch.id)
              JOIN invoice i ON (i.trans_id = a.id)
              JOIN partstax pt ON (pt.parts_id = i.parts_id AND pt.chart_id = ch.id)
              WHERE a.datepaid >= '$form->{fromdate}'
              $accno
              AND a.invoice = '1'
              AND i.parts_id IN (SELECT parts_id FROM partstax)
              $cashwhere
              |;
      }
    }
  }


  if ($form->{reportcode} =~ /nontaxable/) {

    if ($form->{summary}) {
      # only gather up non-taxable transactions
      $query = qq|SELECT DISTINCT a.id, a.invoice, $transdate AS transdate,
                  a.invnumber, n.name, n.${vc}number,
                  ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
                  a.netamount, a.description,
                  a.till, n.id AS vc_id
                  FROM acc_trans ac
                  JOIN $form->{db} a ON (a.id = ac.trans_id)
                  JOIN $vc n ON (n.id = a.${vc}_id)
                  JOIN address ad ON (ad.trans_id = n.id)
                  WHERE $where
                  AND a.netamount = a.amount
                  $cashwhere
                  |;

      if ($form->{fromdate}) {
        if ($cashwhere) {
          $query .= qq|
                UNION
                  SELECT DISTINCT a.id, a.invoice, $transdate AS transdate,
                  a.invnumber, n.name, n.${vc}number,
                  ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
                  a.netamount, a.description,
                  a.till, n.id AS vc_id
                  FROM acc_trans ac
                  JOIN $form->{db} a ON (a.id = ac.trans_id)
                  JOIN $vc n ON (n.id = a.${vc}_id)
                  JOIN address ad ON (ad.trans_id = n.id)
                  WHERE a.datepaid >= '$form->{fromdate}'
                  AND a.netamount = a.amount
                  $cashwhere
                  |;
        }
      }
		  
    } else {

      # gather up details for non-taxable transactions
      $query = qq|SELECT a.id, '0' AS invoice, $transdate AS transdate,
                  a.invnumber, n.name, n.${vc}number,
                  ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
                  ac.amount * $ml AS netamount,
                  ac.memo AS description,
                  a.till, n.id AS vc_id
                  FROM acc_trans ac
                  JOIN $form->{db} a ON (a.id = ac.trans_id)
                  JOIN $vc n ON (n.id = a.${vc}_id)
                  JOIN address ad ON (ad.trans_id = n.id)
                  JOIN chart ch ON (ch.id = ac.chart_id)
                  WHERE $where
                  AND a.invoice = '0'
                  AND a.netamount = a.amount
                  AND NOT (ch.link LIKE '%_paid' OR ch.link = '$ARAP')
                  $cashwhere
                
                UNION ALL
                
                  SELECT a.id, '1' AS invoice, $transdate AS transdate,
                  a.invnumber, n.name, n.${vc}number,
                  ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
                  ac.sellprice * ac.qty * $ml AS netamount,
                  ac.description,
                  a.till, n.id AS vc_id
                  FROM invoice ac
                  JOIN $form->{db} a ON (a.id = ac.trans_id)
                  JOIN $vc n ON (n.id = a.${vc}_id)
                  JOIN address ad ON (ad.trans_id = n.id)
                  WHERE $where
                  AND a.invoice = '1'
                  AND a.amount = a.netamount
                  $cashwhere
                  |;

      if ($form->{fromdate}) {
        if ($cashwhere) {
          $query .= qq|
                  UNION
		
                  SELECT a.id, '0' AS invoice, $transdate AS transdate,
                  a.invnumber, n.name, n.${vc}number,
                  ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
                  ac.amount * $ml AS netamount,
                  ac.memo AS description,
                  a.till, n.id AS vc_id
                  FROM acc_trans ac
                  JOIN $form->{db} a ON (a.id = ac.trans_id)
                  JOIN $vc n ON (n.id = a.${vc}_id)
                  JOIN address ad ON (ad.trans_id = n.id)
                  JOIN chart ch ON (ch.id = ac.chart_id)
                  WHERE a.datepaid >= '$form->{fromdate}'
                  AND a.invoice = '0'
                  AND a.netamount = a.amount
                  AND NOT (ch.link LIKE '%_paid' OR ch.link = '$ARAP')
                  $cashwhere
                
                UNION
                
                  SELECT a.id, '1' AS invoice, $transdate AS transdate,
                  a.invnumber, n.name, n.${vc}number,
                  ad.address1, ad.address2, ad.city, ad.zipcode, ad.country,
                  ac.sellprice * ac.qty * $ml AS netamount,
                  ac.description,
                  a.till, n.id AS vc_id
                  FROM invoice ac
                  JOIN $form->{db} a ON (a.id = ac.trans_id)
                  JOIN $vc n ON (n.id = a.${vc}_id)
                  JOIN address ad ON (ad.trans_id = n.id)
                  WHERE a.datepaid >= '$form->{fromdate}'
                  AND a.invoice = '1'
                  AND a.amount = a.netamount
                  $cashwhere
                  |;
        }
      }
    }
  }

  my @sf = qw(transdate invnumber name);
  my %ordinal = $form->ordinal_order($dbh, $query);
  my $sortorder = $form->sort_order(\@sf, \%ordinal);
  $sortorder = "$ordinal{accno} ASC, $sortorder" if $form->{reportcode} !~ /nontaxable/;

  $query .= qq| ORDER by $sortorder|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ( my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{netamount} = $form->round_amount($ref->{netamount}, $form->{precision});
    $ref->{tax} = $form->round_amount($ref->{tax}, $form->{precision});
    $ref->{total} = $ref->{netamount} + $ref->{tax};

    map { $ref->{address} .= "$ref->{$_} " if $ref->{$_} } qw(address1 address2 city zipcode);
    chomp $ref->{address};

    if ($form->{reportcode} =~ /nontaxable/) {
      push @{ $form->{TR} }, $ref if $ref->{netamount};
    } else {
      push @{ $form->{TR} }, $ref if $ref->{tax};
    }
  }

  $sth->finish;

  $form->report_level($myconfig, $dbh);
  
  $dbh->disconnect;

}


sub paymentaccounts {
  my ($self, $myconfig, $form) = @_;
 
  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $ARAP = uc $form->{db};
  
  # get A(R|P)_paid accounts
  my $query = qq|SELECT c.accno, c.description,
                 l.description AS translation
                 FROM chart c
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
                 WHERE c.link LIKE '%${ARAP}_paid%'
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

 
sub payments {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);

  for (qw(db vc)) { $form->{$_} =~ s/;//g }

  my $ml = ($form->{db} eq 'ar') ? -1 : 1;
  my $query;
  my $sth;
  my $dpt_join;
  my $where = "1 = 1";
  my $var;
  my $arapwhere;
  my $gl = ($form->{till} eq "");

  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
    
  if ($form->{department_id}) {
    $dpt_join = qq|
	         JOIN dpt_trans t ON (t.trans_id = ac.trans_id)
		 |;

    $where .= qq|
		 AND t.department_id = $form->{department_id}
		|;
  }

  unless ($form->{fromdate} || $form->{todate}) {
    ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
  
  if ($form->{fromdate}) {
    $where .= " AND ac.transdate >= '$form->{fromdate}'";
  }
  if ($form->{todate}) {
    $where .= " AND ac.transdate <= '$form->{todate}'";
  }
  if (!$form->{fx_transaction}) {
    $where .= " AND ac.fx_transaction = '0'";
  }
  
  if ($form->{description} ne "") {
    $var = $form->like(lc $form->{description});
    $where .= " AND lower(a.description) LIKE '$var'";
  }
  if ($form->{source} ne "") {
    $var = $form->like(lc $form->{source});
    $where .= " AND lower(ac.source) LIKE '$var'";
  }
  if ($form->{memo} ne "") {
    $var = $form->like(lc $form->{memo});
    $where .= " AND lower(ac.memo) LIKE '$var'";
  }
  if ($form->{"$form->{vc}number"} ne "") {
    $var = $form->like(lc $form->{"$form->{vc}number"});
    $where .= " AND lower(c.$form->{vc}number) LIKE '$var'";
    $gl = 0;
  }
  if ($form->{$form->{vc}} ne "") {
    $var = $form->like(lc $form->{$form->{vc}});
    $where .= " AND lower(c.name) LIKE '$var'";
    $gl = 0;
  }

  # cycle through each id
  foreach my $accno (split(/ /, $form->{paymentaccounts})) {

    $query = qq|SELECT c.id, c.accno, c.description,
                l.description AS translation
                FROM chart c
		LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		WHERE c.accno = '$accno'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{PR} }, $ref;
    $sth->finish;

    $query = qq|SELECT a.description, c.name, ac.transdate,
                sum(ac.amount) * $ml AS paid,
                ac.source, ac.memo, e.name AS employee, a.till, a.curr,
		'$form->{db}' AS module, ac.trans_id, c.id AS vcid, a.invoice,
		c.$form->{vc}number, a.invnumber AS reference
		FROM acc_trans ac
	        JOIN $form->{db} a ON (ac.trans_id = a.id)
	        JOIN $form->{vc} c ON (c.id = a.$form->{vc}_id)
		LEFT JOIN employee e ON (a.employee_id = e.id)
	        $dpt_join
		WHERE $where
		AND ac.chart_id = $ref->{id}
		AND ac.approved = '1'|;

    if ($form->{till} ne "") {
      $query .= " AND a.invoice = '1' 
                  AND NOT a.till IS NULL";
    }

    $query .= qq|
                GROUP BY a.description, c.name, ac.transdate, ac.source,
		ac.memo, e.name, a.till, a.curr, ac.trans_id, c.id, a.invoice,
		c.$form->{vc}number, a.invnumber
		|;

    if ($gl) {
      # don't need gl for a till or if there is a name
      
      $query .= qq|
 	UNION ALL
		SELECT a.description, '' AS name, ac.transdate,
		sum(ac.amount) * $ml AS paid, ac.source,
		ac.memo, e.name AS employee, '' AS till, '' AS curr,
		'gl' AS module, ac.trans_id, '0' AS vcid, '0' AS invoice,
		'' AS $form->{vc}number, a.reference
		FROM acc_trans ac
	        JOIN gl a ON (a.id = ac.trans_id)
		LEFT JOIN employee e ON (a.employee_id = e.id)
	        $dpt_join
		WHERE $where
		AND ac.chart_id = $ref->{id}
		AND a.approved = '1'
		AND (ac.amount * $ml) > 0
	GROUP BY a.description, ac.transdate, ac.source, ac.memo, e.name,
	        ac.trans_id, a.reference
		|;

    }

    my @sf = qw(name transdate employee);
    my %ordinal = $form->ordinal_order($dbh, $query);
    $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my $pr = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{$ref->{id}} }, $pr;
    }
    $sth->finish;

  }
  
  $dbh->disconnect;
  
}


1;


