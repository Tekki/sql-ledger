#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Project module
# also used for partsgroups
#
#======================================================================

package PE;


sub projects {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{sort} ||= "projectnumber";
  
  my $query;
  my $where = "WHERE pr.parts_id = 0 OR pr.parts_id IS NULL";
  
  $query = qq|SELECT pr.*, c.name
	      FROM project pr
	      LEFT JOIN customer c ON (c.id = pr.customer_id)|;

  if ($form->{type} eq 'job') {
    $where = qq|WHERE pr.id NOT IN (SELECT DISTINCT id
			            FROM parts
			            WHERE project_id > 0)|;
  }
  
  my $var;
  if ($form->{projectnumber} ne "") {
    $var = $form->like(lc $form->{projectnumber});
    $where .= " AND lower(pr.projectnumber) LIKE '$var'";
  }
  if ($form->{description} ne "") {
    $var = $form->like(lc $form->{description});
    $where .= " AND lower(pr.description) LIKE '$var'";
  }

  unless ($form->{startdatefrom} || $form->{startdateto}) {
    ($form->{startdatefrom}, $form->{startdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
  
  if ($form->{startdatefrom}) {
    $where .= " AND (pr.startdate IS NULL OR pr.startdate >= '$form->{startdatefrom}')";
  }
  if ($form->{startdateto}) {
    $where .= " AND (pr.startdate IS NULL OR pr.startdate <= '$form->{startdateto}')";
  }
  
  if ($form->{status} eq 'orphaned') {
    $where .= qq| AND pr.id NOT IN (SELECT DISTINCT project_id
                                    FROM acc_trans
				    WHERE project_id > 0
                                 UNION
                                    SELECT DISTINCT project_id
		                    FROM invoice
				    WHERE project_id > 0
				 UNION
		                    SELECT DISTINCT project_id
		                    FROM orderitems
				    WHERE project_id > 0
				 UNION
		                    SELECT DISTINCT project_id
		                    FROM jcitems
				    WHERE project_id > 0)
		|;

  }
  if ($form->{status} eq 'active') {
    $where .= qq| AND (pr.enddate IS NULL OR pr.enddate >= current_date)|;
  }
  if ($form->{status} eq 'inactive') {
    $where .= qq| AND pr.enddate <= current_date|;
  }

  $query .= qq| $where|;
  my @sf = ($form->{sort});
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $i = 0;
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_project} }, $ref;
    $i++;
  }
  $sth->finish;

  $dbh->disconnect;
  
  $i;

}


sub get_project {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $sth;
  my $ref;
  my $where;
  
  if ($form->{id} *= 1) {

    $where = "WHERE pr.id = $form->{id}" if $form->{id};
    
    $query = qq|SELECT pr.*,
                c.name AS customer
		FROM project pr
		LEFT JOIN customer c ON (c.id = pr.customer_id)
		$where|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;

    # check if it is orphaned
    $query = qq|SELECT count(*)
		FROM acc_trans
		WHERE project_id = $form->{id}
	     UNION
		SELECT count(*)
		FROM invoice
		WHERE project_id = $form->{id}
	     UNION
		SELECT count(*)
		FROM orderitems
		WHERE project_id = $form->{id}
	     UNION
		SELECT count(*)
		FROM jcitems
		WHERE project_id = $form->{id}
	       |;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $count;
    while (($count) = $sth->fetchrow_array) {
      $form->{orphaned} += $count;
    }
    $sth->finish;
    $form->{orphaned} = !$form->{orphaned};
  }

  &get_customer("", $myconfig, $form, $dbh);

  $form->all_references($dbh);
  
  $dbh->disconnect;

}


sub save_project {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{customer_id} ||= 'NULL';
  
  if ($form->{id} *= 1) {
    $query = qq|SELECT id FROM project
                WHERE id = $form->{id}|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }

  if (!$form->{id}) {
    my $uid = localtime;
    $uid .= $$;
    
    $query = qq|INSERT INTO project (projectnumber)
                VALUES ('$uid')|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT id FROM project
                WHERE projectnumber = '$uid'|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }

  $form->{projectnumber} = $form->update_defaults($myconfig, "projectnumber", $dbh) unless $form->{projectnumber};

  $query = qq|UPDATE project SET
	      projectnumber = |.$dbh->quote($form->{projectnumber}).qq|,
	      description = |.$dbh->quote($form->{description}).qq|,
	      startdate = |.$form->dbquote($form->{startdate}, SQL_DATE).qq|,
	      enddate = |.$form->dbquote($form->{enddate}, SQL_DATE).qq|,
	      customer_id = $form->{customer_id}
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $form->save_reference($dbh, 'project');

  $dbh->commit;
  $dbh->disconnect;

}


sub list_stock {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $var;
  my $where = "1 = 1";

  if ($form->{status} eq 'active') {
    $where = qq|(pr.enddate IS NULL
                 OR pr.enddate >= current_date)
                 AND pr.completed < pr.production|;
  }
  if ($form->{status} eq 'inactive') {
    $where = qq|pr.completed = pr.production|;
  }
 
  if ($form->{projectnumber}) {
    $var = $form->like(lc $form->{projectnumber});
    $where .= " AND lower(pr.projectnumber) LIKE '$var'";
  }
  
  if ($form->{description}) {
    $var = $form->like(lc $form->{description});
    $where .= " AND lower(pr.description) LIKE '$var'";
  }
  
  $form->{sort} ||= "projectnumber";

  my $query = qq|SELECT pr.*, p.partnumber
	         FROM project pr
		 JOIN parts p ON (p.id = pr.parts_id)
		 WHERE $where|;

  my @sf = ($form->{sort});
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_project} }, $ref;
  }
  $sth->finish;

  $form->all_warehouses($myconfig, $dbh);

  $form->{stockingdate} ||= $form->current_date($myconfig);
  
  $dbh->disconnect;
  
}


sub jobs {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
 
  $form->{sort} = "projectnumber" unless $form->{sort};

  my $query = qq|SELECT pr.*, p.partnumber, p.onhand, c.name
	         FROM project pr
	         JOIN parts p ON (p.id = pr.parts_id)
		 LEFT JOIN customer c ON (c.id = pr.customer_id)
		 WHERE 1=1|;

  if ($form->{projectnumber} ne "") {
    $var = $form->like(lc $form->{projectnumber});
    $query .= " AND lower(pr.projectnumber) LIKE '$var'";
  }
  if ($form->{description} ne "") {
    $var = $form->like(lc $form->{description});
    $query .= " AND lower(pr.description) LIKE '$var'";
  }

  unless ($form->{startdatefrom} || $form->{startdateto}) {
    ($form->{startdatefrom}, $form->{startdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
  
  if ($form->{startdatefrom}) {
    $query .= " AND pr.startdate >= '$form->{startdatefrom}'";
  }
  if ($form->{startdateto}) {
    $query .= " AND pr.startdate <= '$form->{startdateto}'";
  }

  if ($form->{status} eq 'active') { 
    $query .= qq| AND NOT pr.production = pr.completed|;
  } 
  if ($form->{status} eq 'inactive') { 
    $query .= qq| AND pr.production = pr.completed|;
  }
  if ($form->{status} eq 'orphaned') {
    $query .= qq| AND pr.completed = 0
                  AND pr.id NOT IN (SELECT DISTINCT project_id
                                    FROM invoice
				    WHERE project_id > 0
		                    UNION
				    SELECT DISTINCT project_id
				    FROM orderitems
				    WHERE project_id > 0
                                    UNION
				    SELECT DISTINCT project_id
				    FROM jcitems
				    WHERE project_id > 0
				    )|;
  }

  my @sf = ($form->{sort});
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);
 
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_project} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub get_job {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $sth;
  my $ref;

  my %defaults = $form->get_defaults($dbh, \@{['weightunit', 'precision']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  if ($form->{id} *= 1) {
    
    $query = qq|SELECT pr.*,
                p.partnumber, p.description AS partdescription,
		p.unit, p.listprice,
		p.sellprice, p.priceupdate, p.weight, p.notes, p.bin,
		p.partsgroup_id,
		ch.accno AS income_accno, ch.description AS income_description,
		pr.customer_id, c.name AS customer,
		pg.partsgroup
		FROM project pr
		LEFT JOIN parts p ON (p.id = pr.parts_id)
		LEFT JOIN chart ch ON (ch.id = p.income_accno_id)
		LEFT JOIN customer c ON (c.id = pr.customer_id)
		LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
		WHERE pr.id = $form->{id}|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;

  } else {

    $form->{startdate} = $form->current_date($myconfig);
    
  }


  if ($form->{id}) {
    # check if it is orphaned
    $query = qq|SELECT count(*)
		FROM invoice
		WHERE project_id = $form->{id}
	     UNION
		SELECT count(*)
		FROM orderitems
		WHERE project_id = $form->{id}
	     UNION
		SELECT count(*)
		FROM jcitems
		WHERE project_id = $form->{id}
	       |;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $count;
    while (($count) = $sth->fetchrow_array) {
      $form->{orphaned} += $count;
    }
    $sth->finish;

  }

  $form->{orphaned} = !$form->{orphaned};
  
  $query = qq|SELECT c.accno, c.description, c.link,
              l.description AS translation
              FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.link LIKE '%IC%'
	      ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    for (split /:/, $ref->{link}) {
      if (/IC/) {
	$ref->{description} = $ref->{translation} if $ref->{translation};

	push @{ $form->{IC_links}{$_} }, { accno => $ref->{accno},
                             description => $ref->{description} };
      }
    }
  }
  $sth->finish;

  if ($form->{id}) {
    $query = qq|SELECT ch.accno
		FROM parts p
		JOIN partstax pt ON (pt.parts_id = p.id)
		JOIN chart ch ON (pt.chart_id = ch.id)
		WHERE p.id = $form->{id}|;
		
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $form->{amount}{$ref->{accno}} = $ref->{accno};
    }
    $sth->finish;
  }
  
  &get_customer("", $myconfig, $form, $dbh);

  $form->all_references($dbh);
  
  $dbh->disconnect;

}


sub get_customer {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my $disconnect = 0;

  if (! $dbh) {
    $dbh = $form->dbconnect($myconfig);
    $disconnect = 1;
  }

  my $query;
  my $sth;
  my $ref;

  if (! $form->{startdate}) {
    $form->{startdate} = $form->current_date($myconfig);
  }
  
  my $where = qq|(startdate >= '$form->{startdate}' OR startdate IS NULL OR enddate IS NULL)|;
  
  if ($form->{enddate}) {
    $where .= qq| AND (enddate >= '$form->{enddate}' OR enddate IS NULL)|;
  } else {
    $where .= qq| AND (enddate >= current_date OR enddate IS NULL)|;
  }
  
  $query = qq|SELECT count(*)
              FROM customer
	      WHERE $where|;
  my ($count) = $dbh->selectrow_array($query);

  if ($count < $myconfig->{vclimit}) {
    $query = qq|SELECT id, name
		FROM customer
		WHERE $where|;

    if ($form->{customer_id} *= 1) {
      $query .= qq|
		UNION SELECT id,name
		FROM customer
		WHERE id = $form->{customer_id}|;
    }

    $query .= qq| ORDER BY name|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    @{ $form->{all_customer} } = ();
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{all_customer} }, $ref;
    }
    $sth->finish;
  }

  $dbh->disconnect if $disconnect;

}


sub save_job {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my ($income_accno) = split /--/, $form->{IC_income};
  
  my ($partsgroup, $partsgroup_id) = split /--/, $form->{partsgroup};
  $partsgroup_id ||= 'NULL';
  
  if ($form->{id} *= 1) {
    $query = qq|SELECT id FROM project
                WHERE id = $form->{id}|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }

  if (!$form->{id}) {
    my $uid = localtime;
    $uid .= $$;
    
    $query = qq|INSERT INTO project (projectnumber)
                VALUES ('$uid')|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT id FROM project
                WHERE projectnumber = '$uid'|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }

  $form->{projectnumber} = $form->update_defaults($myconfig, "projectnumber", $dbh) unless $form->{projectnumber};
  
  $query = qq|UPDATE project SET
	      projectnumber = |.$dbh->quote($form->{projectnumber}).qq|,
	      description = |.$dbh->quote($form->{description}).qq|,
	      startdate = |.$form->dbquote($form->{startdate}, SQL_DATE).qq|,
	      enddate = |.$form->dbquote($form->{enddate}, SQL_DATE).qq|,
	      parts_id = $form->{id},
              production = |.$form->parse_amount($myconfig, $form->{production}).qq|,
	      customer_id = $form->{customer_id}
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);


  #### add/edit assembly
  $query = qq|SELECT id FROM parts
              WHERE id = $form->{id}|;
  my ($id) = $dbh->selectrow_array($query);

  if (!$id) {
    $query = qq|INSERT INTO parts (id)
                VALUES ($form->{id})|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  my $partnumber = ($form->{partnumber}) ? $form->{partnumber} : $form->{projectnumber};
  
  $query = qq|UPDATE parts SET
              partnumber = |.$dbh->quote($partnumber).qq|,
	      description = |.$dbh->quote($form->{partdescription}).qq|,
	      priceupdate = |.$form->dbquote($form->{priceupdate}, SQL_DATE).qq|,
	      listprice = |.$form->parse_amount($myconfig, $form->{listprice}).qq|,
	      sellprice = |.$form->parse_amount($myconfig, $form->{sellprice}).qq|,
	      weight = |.$form->parse_amount($myconfig, $form->{weight}).qq|,
	      bin = '$form->{bin}',
	      unit = |.$dbh->quote($form->{unit}).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      income_accno_id = (SELECT id FROM chart
	                         WHERE accno = '$income_accno'),
	      partsgroup_id = $partsgroup_id,
	      assembly = '1',
	      obsolete = '1',
	      project_id = $form->{id}
	      WHERE id = $form->{id}|;

  $dbh->do($query) || $form->dberror($query);

  $query = qq|DELETE FROM partstax
              WHERE parts_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  for (split / /, $form->{taxaccounts}) {
    if ($form->{"IC_tax_$_"}) {
      $query = qq|INSERT INTO partstax (parts_id, chart_id)
                  VALUES ($form->{id},
		          (SELECT id
			   FROM chart
			   WHERE accno = '$_'))|;
      $dbh->do($query) || $form->dberror($query);
    }
  }
  
  $form->save_reference($dbh, 'job');
  
  $dbh->commit;
  $dbh->disconnect;

}


sub stock_assembly {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $ref;
  
  my $query = qq|SELECT *
                 FROM project
 	         WHERE id = ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT COUNT(*)
              FROM parts
	      WHERE project_id = ?|;
  my $rvh = $dbh->prepare($query) || $form->dberror($query);

  if (! $form->{stockingdate}) {
    $form->{stockingdate} = $form->current_date($myconfig);
  }
  
  $query = qq|SELECT *
              FROM parts
	      WHERE id = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);
 
  $query = qq|SELECT j.*, p.listprice
              FROM jcitems j
              JOIN parts p ON (p.id = j.parts_id)
              WHERE j.project_id = ?
	      AND j.checkedin <= '$form->{stockingdate}'
	      ORDER BY j.parts_id|;
  my $jth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|INSERT INTO assembly (id, parts_id, qty, bom, adj)
              VALUES (?, ?, ?, '0', '0')|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);

  (undef, $form->{employee_id}) = $form->get_employee($dbh);
  $query = qq|INSERT INTO inventory (warehouse_id, parts_id, qty, shippingdate, employee_id)
              VALUES (?, ?, ?, '$form->{stockingdate}', $form->{employee_id})|;
  my $ith = $dbh->prepare($query) || $form->dberror($query);

  my $i = 0;
  my $sold;
  my $ship;
  
  while (1) {
    $i++;
    last unless $form->{"id_$i"};
    
    $stock = $form->parse_amount($myconfig, $form->{"stock_$i"});
    
    if ($stock) {
      $sth->execute($form->{"id_$i"});
      $ref = $sth->fetchrow_hashref(NAME_lc);

      if ($stock > ($ref->{production} - $ref->{completed})) {
	$stock = $ref->{production} - $ref->{completed};
      }
      if (($stock * -1) > $ref->{completed}) {
	$stock = $ref->{completed} * -1;
      }
      
      $pth->execute($form->{"id_$i"});
      $pref = $pth->fetchrow_hashref(NAME_lc);

      my %assembly = ();
      my $sellprice = 0;
      my $listprice = 0;
      my $lastcost = 0;
      
      $jth->execute($form->{"id_$i"});
      while ($jref = $jth->fetchrow_hashref(NAME_lc)) {
	$assembly{qty}{$jref->{parts_id}} += ($jref->{qty} - $jref->{allocated});
	$assembly{parts_id}{$jref->{parts_id}} = $jref->{parts_id};
	$assembly{jcitems}{$jref->{id}} = $jref->{id};
	$lastcost += $form->round_amount(($jref->{sellprice} * ($jref->{qty} - $jref->{allocated})), $form->{precision});
	
	$sellprice += $form->round_amount(($pref->{sellprice} * ($jref->{qty} - $jref->{allocated})), $form->{precision});
	$listprice += $form->round_amount(($pref->{listprice} * ($jref->{qty} - $jref->{allocated})), $form->{precision});
	
      }
      $jth->finish;

      $uid = localtime;
      $uid .= $$;
      
      $query = qq|INSERT INTO parts (partnumber)
                  VALUES ('$uid')|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|SELECT id
                  FROM parts
                  WHERE partnumber = '$uid'|;
      ($uid) = $dbh->selectrow_array($query);

      $lastcost = $form->round_amount($lastcost / ($ref->{production} / $stock), $form->{precision});
      $sellprice = ($pref->{sellprice}) ? $pref->{sellprice} : $form->round_amount($sellprice / ($ref->{production} / $stock), $form->{precision});
      $listprice = ($pref->{listprice}) ? $pref->{listprice} : $form->round_amount($listprice / ($ref->{production} / $stock), $form->{precision});

      $rvh->execute($form->{"id_$i"});
      my ($rev) = $rvh->fetchrow_array;
      $rvh->finish;
      
      $query = qq|UPDATE parts SET
                  partnumber = '$pref->{partnumber}-$rev',
		  description = '$pref->{description}',
		  priceupdate = '$form->{stockingdate}',
		  unit = '$pref->{unit}',
		  listprice = $listprice,
		  sellprice = $sellprice,
		  lastcost = $lastcost,
		  weight = $pref->{weight},
		  onhand = $stock,
		  notes = '$pref->{notes}',
		  assembly = '1',
		  income_accno_id = $pref->{income_accno_id},
		  bin = '$pref->{bin}',
		  project_id = $form->{"id_$i"}
		  WHERE id = $uid|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|INSERT INTO partstax (parts_id, chart_id)
                  SELECT '$uid', chart_id FROM partstax
		  WHERE parts_id = $pref->{id}|;
      $dbh->do($query) || $form->dberror($query);
		  
      $pth->finish;
      
      for (keys %{$assembly{parts_id}}) {
	if ($assembly{qty}{$_}) {
	  $ath->execute($uid, $assembly{parts_id}{$_}, $form->round_amount($assembly{qty}{$_} / $stock, 4));
	  $ath->finish;
	}
      }

      if ($form->{"warehouse_$i"}) {
        (undef, $form->{warehouse_id}) = split /--/, $form->{"warehouse_$i"};
        $ith->execute($form->{warehouse_id}, $uid, $stock);
        $ith->finish;
      }
     
      $form->update_balance($dbh,
                            "project",
			    "completed",
			    qq|id = $form->{"id_$i"}|,
			    $stock);
      
      $query = qq|UPDATE jcitems SET
                  allocated = qty
	          WHERE allocated != qty
	          AND checkedin <= '$form->{stockingdate}'
		  AND project_id = $form->{"id_$i"}|;
      $dbh->do($query) || $form->dberror($query);

      $sth->finish;
      
    }
  }

  my $rc = $dbh->commit;
  $dbh->disconnect;
  
  $rc;

}


sub delete_project {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{id} *= 1;
  
  $query = qq|DELETE FROM project
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM translation
	      WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $form->delete_references($dbh);

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}


sub delete_partsgroup {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{id} *= 1;
  
  $query = qq|DELETE FROM partsgroup
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM translation
	      WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}


sub delete_pricegroup {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{id} *= 1;
  
  $query = qq|DELETE FROM pricegroup
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub delete_job {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{id} *= 1;
  
  my %audittrail = ( tablename  => 'project',
                     reference  => $form->{id},
		     formname   => $form->{type},
		     action     => 'deleted',
		     id         => $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);
 
  my $query = qq|DELETE FROM project
                 WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM translation
	      WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # delete all the assemblies
  $query = qq|DELETE FROM assembly
              WHERE aid IN
              (SELECT id FROM parts
               WHERE project_id = $form->{id})|;
  $dbh->do($query) || $form->dberror($query);
	
  $query = qq|DELETE FROM parts
	      WHERE project_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $form->delete_references($dbh);
  
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub partsgroups {
  my ($self, $myconfig, $form) = @_;
  
  my $var;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  $form->{sort} ||= "partsgroup";

  my $query = qq|SELECT g.*
                 FROM partsgroup g|;

  my $where = "1 = 1";
  
  if ($form->{partsgroup} ne "") {
    $var = $form->like(lc $form->{partsgroup});
    $where .= " AND lower(g.partsgroup) LIKE '$var'";
  }
  if ($form->{partsgroupcode} ne "") {
    $var = $form->like(lc $form->{partsgroupcode});
    $where .= " AND lower(g.code) LIKE '$var'";
  }

  $query .= qq| WHERE $where|;
 
  if ($form->{status} eq 'orphaned') {
    $query = qq|SELECT g.*
                FROM partsgroup g
                LEFT JOIN parts p ON (p.partsgroup_id = g.id)
		WHERE $where
                EXCEPT
                SELECT g.*
	        FROM partsgroup g
	        JOIN parts p ON (p.partsgroup_id = g.id)
	        WHERE $where|;
  }

  my @sf = qw(partsgroup);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $i = 0;
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{item_list} }, $ref;
    $i++;
  }

  $sth->finish;
  $dbh->disconnect;
  
  $i;

}


sub save_partsgroup {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query;
  
  $form->{pos} *= 1;
  
  if ($form->{id} *= 1) {
    $query = qq|UPDATE partsgroup SET
                partsgroup = |.$dbh->quote($form->{partsgroup}).qq|,
                code = |.$dbh->quote($form->{code}).qq|,
		image = |.$dbh->quote($form->{image}).qq|,
		pos = '$form->{pos}'
		WHERE id = $form->{id}|;
  } else {
    $query = qq|INSERT INTO partsgroup
                (partsgroup, code, image, pos)
                VALUES (|.$dbh->quote($form->{partsgroup}).qq|,|
                .$dbh->quote($form->{code}).qq|,|
                .$dbh->quote($form->{image}).qq|,
		'$form->{pos}')|;
  }
  $dbh->do($query) || $form->dberror($query);

  $dbh->disconnect;

}


sub get_partsgroup {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;
  
  my $query = qq|SELECT *
                 FROM partsgroup
	         WHERE id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
 
  for (keys %$ref) { $form->{$_} = $ref->{$_} }

  $sth->finish;

  # check if it is orphaned
  $query = qq|SELECT count(*)
              FROM parts
	      WHERE partsgroup_id = $form->{id}|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  ($form->{orphaned}) = $sth->fetchrow_array;
  $form->{orphaned} = !$form->{orphaned};
       
  $sth->finish;
  
  $dbh->disconnect;

}


sub pricegroups {
  my ($self, $myconfig, $form) = @_;
  
  my $var;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  $form->{sort} ||= "pricegroup";

  my $query = qq|SELECT g.*
                 FROM pricegroup g|;

  my $where = "1 = 1";
  
  if ($form->{pricegroup} ne "") {
    $var = $form->like(lc $form->{pricegroup});
    $where .= " AND lower(g.pricegroup) LIKE '$var'";
  }
  $query .= qq| WHERE $where|;
  
  if ($form->{status} eq 'orphaned') {
    $query = qq|SELECT g.*
                FROM pricegroup g
		WHERE $where
		AND g.id NOT IN (SELECT DISTINCT pricegroup_id
		                 FROM partscustomer
				 WHERE pricegroup_id > 0)|;
  }

  my @sf = (pricegroup);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $i = 0;
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{item_list} }, $ref;
    $i++;
  }

  $sth->finish;
  $dbh->disconnect;
  
  $i;

}


sub save_pricegroup {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  if ($form->{id} *= 1) {
    $query = qq|UPDATE pricegroup SET
                pricegroup = |.$dbh->quote($form->{pricegroup}).qq|
		WHERE id = $form->{id}|;
  } else {
    $query = qq|INSERT INTO pricegroup
                (pricegroup)
                VALUES (|.$dbh->quote($form->{pricegroup}).qq|)|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub get_pricegroup {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;
  
  my $query = qq|SELECT *
                 FROM pricegroup
	         WHERE id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
 
  for (keys %$ref) { $form->{$_} = $ref->{$_} }

  $sth->finish;

  # check if it is orphaned
  $query = qq|SELECT count(*)
              FROM partscustomer
	      WHERE pricegroup_id = $form->{id}|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  ($form->{orphaned}) = $sth->fetchrow_array;
  $form->{orphaned} = !$form->{orphaned};

  $sth->finish;
  
  $dbh->disconnect;

}


sub description_translations {
  my ($self, $myconfig, $form) = @_;

  my $where = "1 = 1";
  my $var;
  my $ref;
  
  $form->{id} *= 1;
  
  for (qw(partnumber description)) {
    if ($form->{$_}) {
      $var = $form->like(lc $form->{$_});
      $where .= " AND lower(p.$_) LIKE '$var'";
    }
  }
  
  $where .= " AND p.obsolete = '0'";
  $where .= " AND p.id = $form->{id}" if $form->{id};

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %ordinal = ( 'partnumber' => 2,
                  'description' => 3
		);
  
  my @sf = qw(partnumber description);
  my $sortorder = $form->sort_order(\@sf, \%ordinal);

  my $query = qq|SELECT l.description AS language, t.description AS translation,
                 l.code
                 FROM translation t
		 JOIN language l ON (l.code = t.language_code)
		 WHERE trans_id = ?
		 ORDER BY 1|;
  my $tth = $dbh->prepare($query);
  
  $query = qq|SELECT p.id, p.partnumber, p.description
	      FROM parts p
  	      WHERE $where
	      ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $tra;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{translations} }, $ref;

    # get translations for description
    $tth->execute($ref->{id}) || $form->dberror;

    while ($tra = $tth->fetchrow_hashref(NAME_lc)) {
      $form->{trans_id} = $ref->{id};
      $tra->{id} = $ref->{id};
      push @{ $form->{translations} }, $tra;
    }
    $tth->finish;

  }
  $sth->finish;

  $form->all_languages($myconfig, $dbh) if $form->{id};

  $dbh->disconnect;

}


sub partsgroup_translations {
  my ($self, $myconfig, $form) = @_;

  my $where = "1 = 1";
  my $ref;
  my $var;

  $form->{id} *= 1;
  
  if ($form->{description}) {
    $var = $form->like(lc $form->{description});
    $where .= " AND lower(p.partsgroup) LIKE '$var'";
  }
  $where .= " AND p.id = $form->{id}" if $form->{id};
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT l.description AS language, t.description AS translation,
                 l.code
                 FROM translation t
		 JOIN language l ON (l.code = t.language_code)
		 WHERE trans_id = ?
		 ORDER BY 1|;
  my $tth = $dbh->prepare($query);
  
  $form->sort_order();
  
  $query = qq|SELECT p.id, p.partsgroup AS description
	      FROM partsgroup p
  	      WHERE $where
	      ORDER BY 2 $form->{direction}|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $tra;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{translations} }, $ref;

    # get translations for partsgroup
    $tth->execute($ref->{id}) || $form->dberror;

    while ($tra = $tth->fetchrow_hashref(NAME_lc)) {
      $form->{trans_id} = $ref->{id};
      push @{ $form->{translations} }, $tra;
    }
    $tth->finish;

  }
  $sth->finish;

  $form->all_languages($myconfig, $dbh) if $form->{id};

  $dbh->disconnect;

}


sub project_translations {
  my ($self, $myconfig, $form) = @_;

  my $where = "1 = 1";
  my $var;
  my $ref;
  
  $form->{id} *= 1;
  
  for (qw(projectnumber description)) {
    if ($form->{$_}) {
      $var = $form->like(lc $form->{$_});
      $where .= " AND lower(p.$_) LIKE '$var'";
    }
  }
  
  $where .= " AND p.id = $form->{id}" if $form->{id};

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %ordinal = ( 'projectnumber' => 2,
                  'description' => 3
		);
  
  my @sf = qw(projectnumber description);
  my $sortorder = $form->sort_order(\@sf, \%ordinal);

  my $query = qq|SELECT l.description AS language, t.description AS translation,
                 l.code
                 FROM translation t
		 JOIN language l ON (l.code = t.language_code)
		 WHERE trans_id = ?
		 ORDER BY 1|;
  my $tth = $dbh->prepare($query);
  
  $query = qq|SELECT p.id, p.projectnumber, p.description
	      FROM project p
  	      WHERE $where
	      ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $tra;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{translations} }, $ref;

    # get translations for description
    $tth->execute($ref->{id}) || $form->dberror;

    while ($tra = $tth->fetchrow_hashref(NAME_lc)) {
      $form->{trans_id} = $ref->{id};
      $tra->{id} = $ref->{id};
      push @{ $form->{translations} }, $tra;
    }
    $tth->finish;

  }
  $sth->finish;

  $form->all_languages($myconfig, $dbh) if $form->{id};

  $dbh->disconnect;

}


sub chart_translations {
  my ($self, $myconfig, $form) = @_;

  my $where = "1 = 1";
  my $var;
  my $ref;
  
  $form->{id} *= 1;
  
  for (qw(accno description)) {
    if ($form->{$_}) {
      $var = $form->like(lc $form->{$_});
      $where .= " AND lower(c.$_) LIKE '$var'";
    }
  }
  
  $where .= " AND c.id = $form->{id}" if $form->{id};

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %ordinal = ( 'accno' => 2,
                  'description' => 3
		);
  
  my @sf = qw(accno description);
  my $sortorder = $form->sort_order(\@sf, \%ordinal);

  my $query = qq|SELECT l.description AS language, t.description AS translation,
                 l.code
                 FROM translation t
		 JOIN language l ON (l.code = t.language_code)
		 WHERE trans_id = ?
		 ORDER BY 1|;
  my $tth = $dbh->prepare($query);
  
  $query = qq|SELECT c.id, c.accno, c.description
	      FROM chart c
  	      WHERE $where
	      ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $tra;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{translations} }, $ref;

    # get translations for description
    $tth->execute($ref->{id}) || $form->dberror;

    while ($tra = $tth->fetchrow_hashref(NAME_lc)) {
      $form->{trans_id} = $ref->{id};
      $tra->{id} = $ref->{id};
      push @{ $form->{translations} }, $tra;
    }
    $tth->finish;

  }
  $sth->finish;

  $form->all_languages($myconfig, $dbh) if $form->{id};

  $dbh->disconnect;

}



sub save_translation {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  $form->{id} *= 1;
  
  my $query = qq|DELETE FROM translation
                 WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|INSERT INTO translation (trans_id, language_code, description)
              VALUES ($form->{id}, ?, ?)|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  foreach my $i (1 .. $form->{translation_rows}) {
    if ($form->{"language_code_$i"} ne "") {
      $sth->execute($form->{"language_code_$i"}, $form->{"translation_$i"});
      $sth->finish;
    }
  }
  $dbh->commit;
  $dbh->disconnect;

}


sub delete_translation {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;
  
  my $query = qq|DELETE FROM translation
  	         WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub project_sales_order {
   my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  
  my $transdate = $form->current_date($myconfig);
  
  $form->all_years($myconfig, $dbh);
  
  $form->all_projects($myconfig, $dbh, $transdate);
  
  $form->all_employees($myconfig, $dbh, $transdate);

  $dbh->disconnect;

}


sub get_jcitems {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};

  my $var;
  my $where;
  
  if ($form->{projectnumber}) {
    (undef, $var) = split /--/, $form->{projectnumber};
    $where .= " AND j.project_id = $var";
  }
  
  if ($form->{employee}) {
    (undef, $var) = split /--/, $form->{employee};
    $where .= " AND j.employee_id = $var";
  }

  unless ($form->{transdatefrom} || $form->{transdateto}) {
    ($form->{transdatefrom}, $form->{transdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
  
  if ($form->{transdatefrom}) {
    $where .= " AND j.checkedin >= '$form->{transdatefrom}'";
  }
  if ($form->{transdateto}) {
    $where .= " AND j.checkedout <= (date '$form->{transdateto}' + interval '1 days')";
  }

  my $query;
  my $ref;
  $form->{vc} = ($form->{vc} eq 'customer') ? 'customer' : 'vendor';

  $query = qq|SELECT j.id, j.description, j.qty - j.allocated AS qty,
	       j.sellprice, j.parts_id, pr.$form->{vc}_id, j.project_id,
	       j.checkedin::date AS transdate, j.notes,
         c.name AS $form->{vc}, c.$form->{vc}number, pr.projectnumber,
	       p.partnumber, p.unit, e.name AS employee
         FROM jcitems j
	       JOIN project pr ON (pr.id = j.project_id)
	       JOIN employee e ON (e.id = j.employee_id)
	       JOIN parts p ON (p.id = j.parts_id)
	       LEFT JOIN $form->{vc} c ON (c.id = pr.$form->{vc}_id)
	       WHERE pr.parts_id IS NULL
	       AND j.allocated != j.qty
	       $where
	       ORDER BY pr.projectnumber, c.name, j.checkedin::date|;

  if ($form->{summary}) {
    $query =~ s/j\.description/p\.description/;
    $query =~ s/c\.name,/c\.name, j\.parts_id, /;
  }
    
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  # tax accounts
  $query = qq|SELECT c.accno
              FROM chart c
              JOIN partstax pt ON (pt.chart_id = c.id)
              WHERE pt.parts_id = ?|;
  my $tth = $dbh->prepare($query) || $form->dberror($query);
  my $ptref;

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    
    $tth->execute($ref->{parts_id});
    $ref->{taxaccounts} = "";
    while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
      $ref->{taxaccounts} .= "$ptref->{accno} ";
    }
    $tth->finish;
    chop $ref->{taxaccounts};
    
    $ref->{amount} = $ref->{sellprice} * $ref->{qty};

    push @{ $form->{jcitems} }, $ref;
  }

  $sth->finish;

  $form->{currencies} = substr($form->get_currencies($myconfig, $dbh),0,3);
  $form->{defaultcurrency} = $form->{currencies};

  $where = "";
  if ($form->{transdateto}) {
    $where = "WHERE t.validto >= '$form->{transdateto}' OR t.validto IS NULL";
  }
    
  $query = qq|SELECT c.accno, t.rate
              FROM tax t
              JOIN chart c ON (c.id = t.chart_id)
              $where
              ORDER BY c.accno, t.validto|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    if (! exists $tax{$ref->{accno}}) {
      $form->{taxaccounts} .= "$ref->{accno} ";
    }
    $tax{$ref->{accno}} = 1;
    $form->{"$ref->{accno}_rate"} = $ref->{rate};
  }
  chop $form->{taxaccounts};
  $sth->finish;
 
  $dbh->disconnect;
 
}


sub allocate_projectitems {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  for my $i (1 .. $form->{rowcount}) {
    for (split / /, $form->{"jcitems_$i"}) {
      my ($id, $qty) = split /:/, $_;
      $form->update_balance($dbh,
			    'jcitems',
			    'allocated',
			    "id = $id",
			    $qty);
    }
  }
    
  $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
 
}


1;

