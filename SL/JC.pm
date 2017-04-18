#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Job Costing
#
#======================================================================


package JC;

use SL::PM;


sub retrieve_card {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $sth;
  my $query;

  $form->{transdate} = $form->current_date($myconfig);

  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  
  my $dateformat = $myconfig->{dateformat};
  $dateformat =~ s/yy/yyyy/;
  $dateformat =~ s/yyyyyy/yyyy/;
 
  $form->remove_locks($myconfig, $dbh, 'jcitems');
  
  if ($form->{id} *= 1) {
    # retrieve timecard/storescard
    $query = qq|SELECT j.*, to_char(j.checkedin, 'HH24:MI:SS') AS checkedina,
                to_char(j.checkedout, 'HH24:MI:SS') AS checkedouta,
                to_char(j.checkedin, '$dateformat') AS transdate,
                e.name AS employee, p.partnumber, p.id AS parts_id,
                pr.projectnumber, pr.description AS projectdescription,
                pr.production, pr.completed, pr.parts_id AS project,
                pr.customer_id
                FROM jcitems j
                LEFT JOIN employee e ON (e.id = j.employee_id)
                JOIN parts p ON (p.id = j.parts_id)
                JOIN project pr ON (pr.id = j.project_id)
                WHERE j.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $sth->finish;
    $form->{project} = ($form->{project}) ? "job" : "project";
    for (qw(checkedin checkedout)) {
      $form->{$_} = $form->{"${_}a"};
      delete $form->{"${_}a"};
    }

    $query = qq|SELECT s.printed, s.spoolfile, s.formname
                FROM status s
                WHERE s.formname = '$form->{type}'
                AND s.trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $form->{printed} .= "$ref->{formname} " if $ref->{printed};
      $form->{queued} .= "$ref->{formname} $ref->{spoolfile} " if $ref->{spoolfile};
    }
    $sth->finish;
    for (qw(printed queued)) { $form->{$_} =~ s/ +$//g }

    if ($form->{customer_id}) {
      $form->exchangerate_defaults($dbh, $myconfig, $form);
      my $pmh = PM->price_matrix_query($dbh, $form);
      %ref = ();
      $ref->{id} = $form->{parts_id};
      PM->price_matrix($pmh, $ref, $form->datetonum($myconfig, $form->{transdate}), 4, $form, $myconfig);
    }

  }

  $form->create_lock($myconfig, $dbh, $form->{id}, 'jcitems');
  
  JC->jcitems_links($myconfig, $form, $dbh);

  $form->all_languages($myconfig, $dbh);
  
  $form->all_references($dbh, $form->{type});

  $dbh->disconnect;

}


sub jcitems_links {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my $disconnect = 0;

  if (! $dbh) {
    $dbh = $form->dbconnect($myconfig);
    $disconnect = 1;
  }

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};

  $form->get_peripherals($dbh);

  my $query;

  if ($form->{project_id} *= 1) {
    $query = qq|SELECT parts_id
                FROM project
	        WHERE id = $form->{project_id}|;
    if ($dbh->selectrow_array($query)) {
      $form->{project} = 'job';
      if (! exists $form->{orphaned}) {
        $query = qq|SELECT id
		    FROM project
		    WHERE parts_id > 0
		    AND production > completed
		    AND id = $form->{project_id}|;
        ($form->{orphaned}) = $dbh->selectrow_array($query);
      }
    } else {
      $form->{orphaned} = 1;
      $form->{project} = 'project';
    }
  }

  $form->all_employees($myconfig, $dbh, $form->{transdate});
  
  my $where;
  
  if ($form->{transdate}) {
    $where .= qq| AND (enddate IS NULL
                       OR enddate >= '$form->{transdate}')
                  AND (startdate <= '$form->{transdate}'
		       OR startdate IS NULL)|;
  }
  
  if ($form->{project} eq 'job') {
    $query = qq|
		 SELECT *
		 FROM project
		 WHERE parts_id > 0
		 AND production > completed
		 $where|;
  } elsif ($form->{project} eq 'project') {
    $query = qq|
		 SELECT *
		 FROM project
		 WHERE parts_id IS NULL
		 $where|;
  } else {
    $query = qq|
    		 SELECT *
		 FROM project
		 WHERE 1=1
		 $where
		 EXCEPT
		 SELECT *
		 FROM project
		 WHERE parts_id > 0
		 AND production = completed|;
  }

  if ($form->{project_id}) {
    $query .= qq|
	       UNION
	       SELECT *
	       FROM project
	       WHERE id = $form->{project_id}|;
  }

  $query .= qq| ORDER BY projectnumber|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_project} }, $ref;
  }
  $sth->finish;

  $form->reports($myconfig, $dbh, $form->{login});

  $dbh->disconnect if $disconnect;
  
}


sub retrieve_item {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect($myconfig);
  
  my $project_id;
  (undef, $project_id) = split /--/, $form->{projectnumber};
  $project_id *= 1;
  
  my $query = qq|SELECT customer_id
                 FROM project
		 WHERE id = $project_id|;
  ($form->{customer_id}) = $dbh->selectrow_array($query);
  $form->{customer_id} *= 1;
  
  my $var;
  my $where;
  
  if ($form->{partnumber} ne "") {
    $var = $form->like(lc $form->{partnumber});
    $where .= qq| AND lower(p.partnumber) LIKE '$var'|;
  }

  if ($form->{project} eq 'job') {
    if ($form->{type} eq 'storescard') {
      $where .= " AND p.inventory_accno_id > 0
                  AND p.income_accno_id > 0";
    } else {
      $where .= " AND p.income_accno_id IS NULL
                  AND p.inventory_accno_id > 0";
    }
    
    $query = qq|SELECT p.id, p.partnumber, p.description,
                p.sellprice,
                p.unit, t.description AS translation
                FROM parts p
		LEFT JOIN translation t ON (t.trans_id = p.id AND t.language_code = '$form->{language_code}')
	        WHERE p.obsolete = '0'
		$where|;
  }

  if ($form->{project} eq 'project') {
    $where .= " AND p.inventory_accno_id IS NULL
                AND p.income_accno_id > 0";
    
    $query = qq|SELECT p.id, p.partnumber, p.description,
                p.sellprice,
                p.unit, t.description AS translation 
		FROM parts p 
		LEFT JOIN translation t ON (t.trans_id = p.id AND t.language_code = '$form->{language_code}')
		WHERE p.obsolete = '0'
		AND p.assembly = '0'
		$where|;
  }
  
  $query .= qq| ORDER BY 2|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $form->exchangerate_defaults($dbh, $myconfig, $form);
  my $pmh = PM->price_matrix_query($dbh, $form);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    PM->price_matrix($pmh, $ref, $form->datetonum($myconfig, $form->{transdate}), 4, $form, $myconfig);
    $ref->{parts_id} = $ref->{id};
    delete $ref->{id};
    push @{ $form->{item_list} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub delete {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{id} *= 1;
  
  my %audittrail = ( tablename  => 'jcitems',
                     reference  => $form->{id},
		     formname   => $form->{type},
		     action     => 'deleted',
		     id         => $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);
 
  my $query = qq|DELETE FROM jcitems
                 WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # delete spool files
  $query = qq|SELECT spoolfile FROM status
              WHERE formname = '$form->{type}'
	      AND trans_id = $form->{id}
	      AND spoolfile IS NOT NULL|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $spoolfile;
  my @spoolfiles = ();

  while (($spoolfile) = $sth->fetchrow_array) {
    push @spoolfiles, $spoolfile;
  }
  $sth->finish;

  # delete status entries
  $query = qq|DELETE FROM status
              WHERE formname = '$form->{type}'
	      AND trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $form->delete_references($dbh);
  
  $form->remove_locks($myconfig, $dbh, 'jcitems');

  my $rc = $dbh->commit;

  if ($rc) {
    foreach $spoolfile (@spoolfiles) {
      if (-f "$spool/$myconfig->{dbname}/$spoolfile") {
	unlink "$spool/$myconfig->{dbname}/$spoolfile";
      }
    }
  }

  $dbh->disconnect;

  $rc;

}


sub jcitems {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query;
  my $where = "1 = 1";
  my $var;
  
  if ($form->{projectnumber}) {
    (undef, $var) = split /--/, $form->{projectnumber};
    $where .= " AND j.project_id = $var";

    $query = qq|SELECT parts_id
                FROM project
		WHERE id = $var|;
    my ($job) = $dbh->selectrow_array($query);
    $form->{project} = ($job) ? "job" : "project";
  }
  if ($form->{partnumber} ne "") {
    $var = $form->like(lc $form->{partnumber});
    $where .= " AND lower(p.partnumber) LIKE '$var'";

    if ($form->{project}) {
      if ($form->{project} eq 'job') {
	$where .= " AND p.inventory_accno_id > 0";
      }
    } else {
      $query = qq|SELECT inventory_accno_id
		  FROM parts
		  WHERE lower(partnumber) LIKE '$var'|;
      my ($job) = $dbh->selectrow_array($query);
      $form->{project} = ($job) ? "job" : "project";
    }
  }
  if ($form->{employee}) {
    (undef, $var) = split /--/, $form->{employee};
    $where .= " AND j.employee_id = $var";
  }
  if ($form->{description}) {
    $var = $form->like(lc $form->{description});
    $where .= " AND lower(j.description) LIKE '$var'";
  }
  if ($form->{notes}) {
    $var = $form->like(lc $form->{notes});
    $where .= " AND lower(j.notes) LIKE '$var'";
  }

  if ($form->{open} || $form->{closed}) {
    unless ($form->{open} && $form->{closed}) {
      $where .= " AND j.qty != j.allocated" if $form->{open};
      $where .= " AND j.qty = j.allocated" if $form->{closed};
    }
  }
  
  unless ($form->{startdatefrom} || $form->{startdateto}) {
    ($form->{startdatefrom}, $form->{startdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
  
  $where .= " AND j.checkedin >= '$form->{startdatefrom}'" if $form->{startdatefrom};
  $where .= " AND j.checkedout < date '$form->{startdateto}' + 1" if $form->{startdateto};

  my $dateformat = $myconfig->{dateformat};
  $dateformat =~ s/yy$/yyyy/;
  $dateformat =~ s/yyyyyy/yyyy/;
  
  if ($form->{project} eq 'job') {
    $where .= " AND pr.parts_id > 0";
    if ($form->{type} eq 'timecard') {
      $where .= " AND p.income_accno_id IS NULL";
    }
    if ($form->{type} eq 'storescard') {
      $where .= " AND p.income_accno_id > 0";
    }
  }
  if ($form->{project} eq 'project') {
    $where .= " AND pr.parts_id IS NULL";
  }
  
  $query = qq|SELECT j.id, j.description, j.qty, j.allocated,
	      to_char(j.checkedin, 'HH24:MI') AS checkedin,
	      to_char(j.checkedout, 'HH24:MI') AS checkedout,
	      to_char(j.checkedin, 'yyyymmdd') AS transdate,
	      to_char(j.checkedin, '$dateformat') AS transdatea,
	      to_char(j.checkedin, 'D') AS weekday,
	      p.partnumber,
	      pr.projectnumber, pr.description AS projectdescription,
	      e.employeenumber, e.name AS employee,
	      to_char(j.checkedin, 'IW') AS workweek, pr.parts_id,
	      j.sellprice, p.inventory_accno_id, p.income_accno_id,
	      j.notes
	      FROM jcitems j
	      JOIN parts p ON (p.id = j.parts_id)
	      JOIN project pr ON (pr.id = j.project_id)
	      LEFT JOIN employee e ON (e.id = j.employee_id)
	      WHERE $where|;

  my @sf = qw(transdate projectnumber);
  my %ordinal = $form->ordinal_order($dbh, $query);
  my $sortorder;

  if ($form->{type} eq 'timecard') {
    $sortorder = join ',', ($ordinal{employee}, $ordinal{employeenumber});
  }
  if ($sortorder) {
    $query .= qq| ORDER BY $sortorder,| .$form->sort_order(\@sf, \%ordinal);
  } else {
    $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    if ($ref->{parts_id}) {
      $ref->{project} = 'job';
      $ref->{type} = ($ref->{inventory_accno_id} && $ref->{income_accno_id}) ? 'storescard' : 'timecard';
    } else {
      $ref->{project} = 'project';
      $ref->{type} = 'timecard';
    }
    
    $ref->{transdate} = $ref->{transdatea};
    delete $ref->{transdatea};

    push @{ $form->{transactions} }, $ref;
  }
  $sth->finish;

  my %defaults = $form->get_defaults($dbh, \@{[qw(company precision)]});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  $dbh->disconnect;

}


sub save {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $sth;
  my $project_id;
  
  (undef, $project_id) = split /--/, $form->{projectnumber};
  $project_id *= 1;
  
  if ($form->{id} *= 1) {
    # check if it was a job
    $query = qq|SELECT pr.parts_id, pr.production - pr.completed
                FROM project pr
                JOIN jcitems j ON (j.project_id = pr.id)
                WHERE j.id = $form->{id}|;
    my ($job_id, $qty) = $dbh->selectrow_array($query);

    if ($job_id && $qty == 0) {
      $dbh->disconnect;
      return -1;
    }
    
    # check if new one belongs to a job
    if ($project_id) {
      $query = qq|SELECT pr.parts_id, pr.production - pr.completed
                  FROM project pr
                  WHERE pr.id = $project_id|;
      my ($job_id, $qty) = $dbh->selectrow_array($query);

      if ($job_id && $qty == 0) {
        $dbh->disconnect;
        return -2;
      }
    }
    
  } else {
    my $uid = localtime;
    $uid .= $$;

    $query = qq|INSERT INTO jcitems (description, parts_id)
                VALUES ('$uid', $form->{parts_id})|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT id FROM jcitems
                WHERE description = '$uid'|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }

  for (qw(inhour inmin insec outhour outmin outsec)) { $form->{$_} = substr("00$form->{$_}", -2) }
  for (qw(qty sellprice allocated)) { $form->{$_} = $form->parse_amount($myconfig, $form->{$_}) }

  my $checkedin = "$form->{inhour}$form->{inmin}$form->{insec}";
  my $checkedout = "$form->{outhour}$form->{outmin}$form->{outsec}";
  
  my $outdate = $form->{transdate};
  if ($checkedout < $checkedin) {
    $outdate = $form->add_date($myconfig, $form->{transdate}, 1, 'days');
  }

  (undef, $form->{employee_id}) = split /--/, $form->{employee};
  unless ($form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  } 

  $query = qq|UPDATE jcitems SET
              project_id = $project_id,
              parts_id = $form->{parts_id},
              description = |.$dbh->quote($form->{description}).qq|,
              qty = $form->{qty},
              allocated = $form->{allocated},
              sellprice = $form->{sellprice},
              fxsellprice = $form->{sellprice},
              serialnumber = |.$dbh->quote($form->{serialnumber}).qq|,
              checkedin = timestamp '$form->{transdate} $form->{inhour}:$form->{inmin}:$form->{insec}',
              checkedout = timestamp '$outdate $form->{outhour}:$form->{outmin}:$form->{outsec}',
              employee_id = $form->{employee_id},
              notes = |.$dbh->quote($form->{notes}).qq|
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # save printed, queued
  $form->save_status($dbh);
  
  # save references
  $form->save_reference($dbh, $form->{type});

  my %audittrail = ( tablename  => 'jcitems',
                     reference  => $form->{id},
		     formname   => $form->{type},
		     action     => 'saved',
		     id         => $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);

  $form->remove_locks($myconfig, $dbh, 'jcitems');

  my $rc = $dbh->commit;
  
  $rc;

}


sub company_defaults {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['company','address','tel','fax','businessnumber']});

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

  $dbh->disconnect;

}


1;

