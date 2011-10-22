########### SSB

sub add {

  $form->{title} = $locale->text('Add Time Card');
  
  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&login=$form->{login}&path=$form->{path}&project=$form->{project}" unless $form->{callback};  
  if ($myconfig{role} eq 'timesheet') {
    $form->{type} = 'assignedtimecard';
  }

  &{ "prepare_$form->{type}" };

  $form->{orphaned} = 1;
  &display_form;
  
}


sub edit {

  $form->{title} = $locale->text('Edit Time Card');
  
  if ($myconfig{role} eq 'timesheet') {
    $form->{type} = 'assignedtimecard';
  }

  &{ "prepare_$form->{type}" };

  $form->{orphaned} = 1;
  &display_form;
  
}


sub prepare_assignedtimecard {

  $dbh = $form->dbconnect(\%myconfig);

  %defaults = $form->get_defaults($dbh, \@{['precision']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  $form->{transdate} ||= $form->current_date(\%myconfig);

  if ($form->{employee}) {
    ($form->{employee}, $form->{employee_id}) = split /--/, $form->{employee};
  } else {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  }

  $dateformat = $myconfig{dateformat};
  $dateformat =~ s/yy/yyyy/;
  $dateformat =~ s/yyyyyy/yyyy/;

  $form->remove_locks($myconfig, $dbh, 'jcitems');
  
  if ($form->{id} *= 1) {
    $query = qq|SELECT j.*, to_char(j.checkedin, 'HH24:MI:SS') AS checkedina,
                to_char(j.checkedout, 'HH24:MI:SS') AS checkedouta,
		to_char(j.checkedin, '$dateformat') AS transdate,
		e.name AS employee, p.partnumber,
		pr.projectnumber, pr.description AS projectdescription,
		pr.production, pr.completed, pr.parts_id AS project,
		pr.customer_id
		FROM jcitems j
		JOIN employee e ON (e.id = j.employee_id)
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

    $form->{partnumber} = "$ref->{partnumber}--$ref->{parts_id}";
    $form->{projectnumber} = "$ref->{projectnumber}--$ref->{project_id}";

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

    $form->create_lock(\%myconfig, $dbh, $form->{id}, 'jcitems');

    $form->{transdatelocked} = 1;
    
  }
  
  $form->all_languages(\%myconfig, $dbh);

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }

  &timecard_links;

  $dbh->disconnect;

  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum(\%myconfig, $form->{transdate}) <= $form->{closedto});

  $form->{formname} = "timecard";
  $form->{format} ||= $myconfig{outputformat};
  
  if ($myconfig{printer}) {
    $form->{format} ||= "postscript";
  } else {
    $form->{format} ||= "pdf";
  } 
  $form->{media} ||= $myconfig{printer};

  $form->{selectformname} = qq|timecard--|.$locale->text('Time Card');

  foreach $item (qw(in out)) {
    ($form->{"${item}hour"}, $form->{"${item}min"}, $form->{"${item}sec"}) = split /:/, $form->{"checked$item"};
    for (qw(hour min sec)) {
      if (($form->{"$item$_"} *= 1) > 0) {
	$form->{"$item$_"} = substr(qq|0$form->{"$item$_"}|,-2);
      } else {
	$form->{"$item$_"} ||= "";
      }
    }
  }

  $form->{checkedin} = $form->{inhour} * 3600 + $form->{inmin} * 60 + $form->{insec};
  $form->{checkedout} = $form->{outhour} * 3600 + $form->{outmin} * 60 + $form->{outsec};

  $form->{clocked} = ($form->{checkedout} - $form->{checkedin}) / 3600;

  $form->{noncharge} = $form->format_amount(\%myconfig, $form->{clocked} - $form->{qty}, 1) if $form->{checkedin} != $form->{checkedout};
  $form->{clocked} = $form->format_amount(\%myconfig, $form->{clocked}, 1);
  $form->{qty} = $form->format_amount(\%myconfig, $form->{qty}, 1);

  for (qw(projectnumber partnumber formname language)) { $form->{"select$_"} = $form->escape($form->{"select$_"}, 1) }
  
}


sub timecard_links {
  
  ##### links for parts and projects
  $query = qq|SELECT a.*, pr.projectnumber, e.name
	      FROM assignemployee a
	      JOIN employee e ON (e.id = a.projectleaderid)
	      JOIN project pr ON (pr.id = a.project_id)
	      WHERE a.employee_id = $form->{employee_id}
	      AND (a.startdate <= '$form->{transdate}' OR a.startdate IS NULL)
	      AND (a.enddate >= '$form->{transdate}' OR a.enddate IS NULL)|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $form->{selectprojectnumber} = "";
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{projectleader} = $ref->{name};
    $form->{selectprojectnumber} .= qq|$ref->{projectnumber}--$ref->{project_id}\n| unless $form->{$ref->{project_id}};
    $form->{$ref->{project_id}} = $ref->{projectnumber};
  }
  $sth->finish;

  if ($form->{projectnumber}) {
    ($null, $form->{project_id}) = split /--/, $form->{projectnumber};
    
    $query = qq|SELECT description
                FROM project
		WHERE id = $form->{project_id}|;
    ($form->{projectdescription}) = $dbh->selectrow_array($query);

  } else {

    # select first entry
    @p = split /\n/, $form->{selectprojectnumber};
    ($null, $form->{project_id}) = split /--/, $p[0];

  }

  if (! $form->{project_id}) {
    $dbh->disconnect;
    $form->error($locale->text('No projects available!'));
  }
  
  $query = qq|SELECT a.parts_id, p.partnumber
	      FROM assignemployee a
	      JOIN parts p ON (p.id = a.parts_id)
	      WHERE a.employee_id = $form->{employee_id}
	      AND a.project_id = $form->{project_id}
	      AND (a.startdate <= '$form->{transdate}' OR a.startdate IS NULL)
	      AND (a.enddate >= '$form->{transdate}' OR a.enddate IS NULL)|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $form->{selectpartnumber} = "";
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{selectpartnumber} .= qq|$ref->{partnumber}--$ref->{parts_id}\n|;
  }
  $sth->finish;

  if ($form->{partnumber}) {
    ($null, $form->{parts_id}) = split /--/, $form->{partnumber};
  } else {
    @p = split /\n/, $form->{selectpartnumber};
    ($null, $form->{parts_id}) = split /--/, $p[0];
  }

  if (! $form->{parts_id}) {
    $dbh->disconnect;
    $form->error($locale->text('No service codes!'));
  }

  $query = qq|SELECT description, sellprice
              FROM assignemployee
	      WHERE employee_id = $form->{employee_id}
	      AND project_id = $form->{project_id}
	      AND parts_id = $form->{parts_id}|;
  ($description, $sellprice) = $dbh->selectrow_array($query);

  $form->{description} ||= $description;
  $form->{sellprice} ||= $sellprice;

  if ($form->{transdatelocked}) {
    # fix selections
    $form->{selectprojectnumber} = $form->{projectnumber};
    $form->{selectpartnumber} = $form->{partnumber};
  }
 
}


sub assignedtimecard_header {
  
  $rows = $form->numtextrows($form->{description}, 50, 8);
  for (qw(transdate checkedin checkedout partnumber projectnumber)) { $form->{"old$_"} = $form->{$_} }
  if ($rows > 1) {
    $description = qq|<textarea name=description rows=$rows cols=46 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=48 value="|.$form->quote($form->{description}).qq|">|;
  }
  
  if (($rows = $form->numtextrows($form->{notes}, 40, 6)) < 2) {
    $rows = 2;
  }

  $notes = qq|<tr>
                <th align=right>|.$locale->text('Notes').qq|</th>
		  <td colspan=3><textarea name="notes" rows=$rows cols=46 wrap=soft>$form->{notes}</textarea>
                </td>
              </tr>
|;

  $clocked = qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('Clocked').qq|</th>
	  <td>$form->{clocked}</td>
        </tr>
|;

  $form->{action} = "update_";

  if ($form->{transdatelocked}) {
    $dateworked = qq|
	  <td>$form->{transdate}</td>|.$form->hide_form(qw(transdate transdatelocked));
  } else {
    $dateworked = qq|
	  <td><input name=transdate size=11 title="$myconfig{dateformat}" value="$form->{transdate}" onChange="javascript:document.forms[0].submit()"></td>|;
  }

  $form->header;

  print qq|
<body>

<form method=post action="$form->{script}">
|;

  $form->hide_form(map { "select$_" } qw(projectnumber partnumber formname language));
  $form->hide_form(qw(id type printed queued closedto locked project title employee employee_id sellprice precision action));

  $form->hide_form(map { "old$_" } qw(transdate checkedin checkedout partnumber projectnumber));

print qq| 
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right nowrap>|.$locale->text('Employee').qq| <font color=red>*</font></th>
	  <td colspan=3>$form->{employee}</td>
        </tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Date worked').qq| <font color=red>*</font></th>
	  $dateworked
        </tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Project').qq| <font color=red>*</font></th>
	  <td><select name=projectnumber onChange="javascript:document.forms[0].submit()">|
	  .$form->select_option($form->{selectprojectnumber}, $form->{projectnumber}, 1)
	  .qq|</select>
	  </td>
	  <td colspan=2>$form->{projectdescription}</td>|
	  .$form->hide_form(qw(projectdescription))
	  .qq|
        </tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Service Code').qq| <font color=red>*</font></th>
	  <td><select name=partnumber onChange="javascript:document.forms[0].submit()">|
	  .$form->select_option($form->{selectpartnumber}, $form->{partnumber}, 1)
	  .qq|</select>
	  </td>
        </tr>
	<tr valign=top>
	  <th align=right nowrap>|.$locale->text('Description').qq|</th>
	  <td colspan=3>$description</td>
        </tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Time In').qq|</th>
	  <td>
	    <table>
	      <tr>
	        <td><input name=inhour title="hh" size=3 maxlength=2 value=$form->{inhour}></td>
		<td><input name=inmin title="mm" size=3 maxlength=2 value=$form->{inmin}></td>
		<td><input name=insec title="ss" size=3 maxlength=2 value=$form->{insec}></td>
              </tr>
            </table>
          </td>
	  <th align=right nowrap>|.$locale->text('Time Out').qq|</th>
	  <td>
	    <table>
	      <tr>
	        <td><input name=outhour title="hh" size=3 maxlength=2 value=$form->{outhour}></td>
		<td><input name=outmin title="mm" size=3 maxlength=2 value=$form->{outmin}></td>
		<td><input name=outsec title="ss" size=3 maxlength=2 value=$form->{outsec}></td>
              </tr>
            </table>
          </td>
        </tr>
        $clocked
	<tr>
	  <th align=right nowrap>|.$locale->text('Non-chargeable').qq|</th>
	  <td><input name=noncharge value=$form->{noncharge}></td>
        </tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Chargeable').qq|</th>
	  <td><input name=qty value=$form->{qty}></td>
        </tr>
	$notes
|;
  
}


sub assignedtimecard_footer {

  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
  <tr>
    <td>
|;

  &print_options;

  print qq|

    </td>
  </tr>
</table>
<br>
|;

  $transdate = $form->datetonum(\%myconfig, $form->{transdate});

  if ($form->{readonly}) {

    &islocked;

  } else {

  %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update ') },
             'Print' => { ndx => 2, key => 'P', value => $locale->text('Print') },
	     'Save' => { ndx => 3, key => 'S', value => $locale->text('Save ') },
	     'Delete' => { ndx => 16, key => 'D', value => $locale->text('Delete') },
	    );

    %a = ();
    
    if ($form->{id}) {
    
      if (!$form->{locked}) {
	for ('Update', 'Print', 'Save') { $a{$_} = 1 }
	
	if ($form->{orphaned}) {
	  $a{'Delete'} = 1;
	}
	
      }

    } else {

      if ($transdate > $form->{closedto}) {
	
	for ('Update', 'Print', 'Save') { $a{$_} = 1 }

      }
    }
  }

  for (keys %button) { delete $button{$_} if ! $a{$_} }
  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
  
  $form->hide_form(qw(callback path login orphaned));
  
  print qq|

</form>

</body>
</html>
|;

}


sub update_ {

  $dbh = $form->dbconnect(\%myconfig);
 
  ### transdate, rebuild projects
  if ($form->{transdate} ne $form->{oldtransdate}) {
    &timecard_links;
  }
  
  if ($form->{projectnumber} ne $form->{oldprojectnumber}) {
    ($null, $id) = split /--/, $form->{projectnumber};

    $query = qq|SELECT description
                FROM project
		WHERE id = $id|;
    ($form->{projectdescription}) = $dbh->selectrow_array($query);

    $form->fdld(\%myconfig, \%locale);

    # set selectpartnumber for project
    $query = qq|SELECT p.id, p.partnumber
		FROM assignemployee a
		JOIN parts p ON (p.id = a.parts_id)
		WHERE a.project_id = $id
		AND a.employee_id = $form->{employee_id}
		AND (a.enddate >= '$form->{fdm}' OR a.enddate IS NULL)
		AND (a.startdate <= '$form->{ldm}' OR a.startdate IS NULL)|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    $form->{selectpartnumber} = "";
    while (($id, $partnumber) = $sth->fetchrow_array) {
      $form->{selectpartnumber} .= "$partnumber--$id\n";
    }
    chop $form->{selectpartnumber};

    @p = split /\n/, $form->{selectpartnumber};

    ($partnumber, $id) = split /--/, $p[0];
    $id *= 1;

    $form->{partnumber} = "$partnumber--$id";
  }

  ($null, $form->{parts_id}) = split /--/, $form->{partnumber};
  if ($form->{partnumber} ne $form->{oldpartnumber}) {
    $query = qq|SELECT description, sellprice
                FROM parts
		WHERE id = $form->{parts_id}|;
    ($form->{description}, $form->{sellprice}) = $dbh->selectrow_array($query);
  }
  
  $dbh->disconnect;

  $form->{qty} = $form->parse_amount(\%myconfig, $form->{qty});
  $form->{noncharge} = $form->parse_amount(\%myconfig, $form->{noncharge});
  
  &calc_clocked;

  $form->{sellprice} = $form->format_amount(\%myconfig, $form->{sellprice}, $form->{precision});
  $form->{qty} = $form->format_amount(\%myconfig, $form->{qty}, 1);
  $form->{noncharge} = $form->format_amount(\%myconfig, $form->{noncharge}, 1);

  &display_form;

}


sub calc_clocked {
  
  %hour = ( in => 0, out => 0 );
  for $t (qw(in out)) {
    if ($form->{"${t}sec"} > 60) {
      $form->{"${t}sec"} -= 60;
      $form->{"${t}min"}++;
    }
    if ($form->{"${t}min"} > 60) {
      $form->{"${t}min"} -= 60;
      $form->{"${t}hour"}++;
    }
    $hour{$t} = $form->{"${t}hour"};
  }

  $form->{checkedin} = $hour{in} * 3600 + $form->{inmin} * 60 + $form->{insec};
  $form->{checkedout} = $hour{out} * 3600 + $form->{outmin} * 60 + $form->{outsec};

  if ($form->{checkedin} && $form->{checkedout}) {
    $form->{clocked} = ($form->{checkedout} - $form->{checkedin}) / 3600;

    $form->{qty} = $form->{clocked} - $form->{noncharge};
    
    $form->{clocked} = $form->format_amount(\%myconfig, $form->{clocked}, 1);
  }

}
  

sub save_ {

  if ($form->{type}) {
    &{ "save_$form->{type}" };
  }
  
} 


sub save_inonego {

  $dbh = $form->dbconnect_noauto(\%myconfig);
  
  ($null, $employee_id) = split /--/, $form->{employee};

  $query = qq|INSERT INTO jcitems (project_id, parts_id, description,
              sellprice, qty, allocated, employee_id, checkedin, checkedout)
              VALUES (?,?,?,?,?,0,$employee_id,?,?)|;
  $jth = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|INSERT INTO jcitems (id, project_id, parts_id, description,
              sellprice, qty, allocated, employee_id, checkedin, checkedout)
              VALUES (?,?,?,?,?,?,0,$employee_id,?,?)|;
  $ith = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM jcitems
              WHERE id = ?|;
  $dth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT description, sellprice
              FROM assignemployee
	      WHERE employee_id = $employee_id
	      AND project_id = ?
	      AND parts_id = ?|;
  $pth = $dbh->prepare($query) || $form->dberror($query);

  
  for (split / /, $form->{projects}) {
    ($project_id, $parts_id) = split /--/, $_;

    $pth->execute($project_id, $parts_id);
    ($description, $sellprice) = $pth->fetchrow_array;
    $pth->finish;

    $query = qq|SELECT id
		FROM jcitems
		WHERE project_id = $project_id
		AND parts_id = $parts_id
		AND to_char(checkedin, 'YYYYMMDD') = ?
		AND employee_id = $employee_id|;
    $cth = $dbh->prepare($query) || $form->dberror($query);
   
    for $i (1 .. $form->{days}) {
      $cth->execute($form->{fdm}-1+$i);
      ($id) = $cth->fetchrow_array;
      $cth->finish;

      if ($id) {
	$dth->execute($id);
	$dth->finish;
      }
      
      if ($form->{"${_}_$i"}) {
	
        $qty = $form->round_amount($form->parse_amount(\%myconfig, $form->{"${_}_$i"}),1);

	if ($id) {
	  $ith->execute($id, $project_id, $parts_id, $description, $sellprice, $qty, $form->{fdm}-1+$i, $form->{fdm}-1+$i);
	  $ith->finish;
	} else {
	  $jth->execute($project_id, $parts_id, $description, $sellprice, $qty, $form->{fdm}-1+$i, $form->{fdm}-1+$i);
	  $jth->finish;
	}
	  
      }
    }
  }
    
  $rc = $dbh->commit;
  $dbh->disconnect;

  $form->redirect($locale->text('Timesheet saved!'));

}


sub save_assignedtimecard {

  $form->{type} = "timecard";
  ($null, $form->{parts_id}) = split /--/, $form->{partnumber};

  if ($form->{transdate} ne $form->{oldtransdate}) {
    &update_;
    exit;
  }

  &calc_clocked;

  $form->{qty} = $form->format_amount(\%myconfig, $form->{qty}, 1);
  
  &save;

}


sub employee_timecards {
  
  $dbh = $form->dbconnect(\%myconfig);

  ($null, $id) = $form->get_employee($dbh);
  $form->{employee} = "--$id";
 
  # accounting years
  $form->all_years(\%myconfig, $dbh);

  $dbh->disconnect;
  

  if (@{ $form->{all_years} }) {
    $selectaccountingyear = "<option>\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|<option>$_\n| }

    $selectaccountingmonth = "<option>\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|<option value=$_>|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
        <tr>
	  <th align=right>|.$locale->text('Period').qq|</th>
	  <td colspan=3>
	  <select name=month>$selectaccountingmonth</select>
	  <select name=year>$selectaccountingyear</select>
	  <input name=interval class=radio type=radio value=0 checked>&nbsp;|.$locale->text('Current').qq|
	  <input name=interval class=radio type=radio value=1>&nbsp;|.$locale->text('Month').qq|
	  <input name=interval class=radio type=radio value=3>&nbsp;|.$locale->text('Quarter').qq|
	  <input name=interval class=radio type=radio value=12>&nbsp;|.$locale->text('Year').qq|
	  </td>
	</tr>
|;
  }

  $fromto = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Startdate').qq|</th>
	  <td>|.$locale->text('From').qq| <input name=startdatefrom size=11 title="$myconfig{dateformat}">
	  |.$locale->text('To').qq| <input name=startdateto size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
|;

  $form->{title} = $locale->text('Time & Stores Cards');
  if ($form->{type} eq 'timecard') {
    $form->{title} = $locale->text('Time Cards');
  }
  if ($form->{type} eq 'storescard') {
    $form->{title} = $locale->text('Stores Cards');
  }

   
  @a = ();
  push @a, qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked> |.$locale->text('Date');
  push @a, qq|<input name="l_projectnumber" class=checkbox type=checkbox value=Y checked> $projectnumberlabel|;
  push @a, qq|<input name="l_projectdescription" class=checkbox type=checkbox value=Y checked> $projectdescriptionlabel|;
  push @a, qq|<input name="l_id" class=checkbox type=checkbox value=Y checked> |.$locale->text('ID');
  push @a, qq|<input name="l_partnumber" class=checkbox type=checkbox value=Y checked> $partnumberlabel|;
  push @a, qq|<input name="l_description" class=checkbox type=checkbox value=Y checked> |.$locale->text('Description');
  push @a, qq|<input name="l_notes" class=checkbox type=checkbox value=Y checked> |.$locale->text('Notes');
  push @a, qq|<input name="l_qty" class=checkbox type=checkbox value=Y checked> |.$locale->text('Qty');
  push @a, qq|<input name=l_time class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Time');
  push @a, qq|<input name=l_allocated class=checkbox type=checkbox value=Y> |.$locale->text('Allocated');

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
	$fromto
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table>
	      <tr>
       		<td nowrap><input name=open class=checkbox type=checkbox value=Y checked> |.$locale->text('Open').qq|</td>
		<td nowrap><input name=closed class=checkbox type=checkbox value=Y> |.$locale->text('Closed').qq|</td>
	      </tr>
|;

  while (@a) {
    for (1 .. 5) {
      print qq|<td nowrap>|. shift @a;
      print qq|</td>\n|;
    }
    print qq|</tr>\n|;
  }

  print qq|
	      <tr>
	        <td><input name=l_subtotal class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|</td>
	      </tr>
	    </table>
	  </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->{nextsub} = "list_cards";
  $form->{sort} = "transdate";
  
  $form->hide_form(qw(nextsub sort path login project type employee));

  print qq|
<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
</form>
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|

</body>
</html>
|;

}



sub timesheet {
  
  $dbh = $form->dbconnect(\%myconfig);

  $form->all_employees(\%myconfig, $dbh);

  if ($myconfig{role} eq 'timesheet') {
    ($name, $id) = $form->get_employee($dbh);
    $form->{employee} = "$name--$id";
    $selectemployee = qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('Employee').qq|</th>
	  <td>$name</td>
        </tr>
|.$form->hide_form(qw(employee));
  } else {
    if (@{ $form->{all_employee} }) {
      $form->{selectemployee} = "";
      for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }

      $selectemployee = qq|
	  <tr>
	    <th align=right nowrap>|.$locale->text('Employee').qq|</th>
	    <td><select name=employee>|
	    .$form->select_option($form->{selectemployee}, undef, 1)
	    .qq|
	    </select></td>
	  </tr>
  |;
    } else {
      $form->error($locale->text('No Employees on file!'));
    }
  }
  
 
  # accounting years
  $form->all_years(\%myconfig, $dbh);

  $dbh->disconnect;

  if (@{ $form->{all_years} }) {
    $selectaccountingyear = "";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|<option>$_\n| }

    $selectaccountingmonth = "";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|<option value=$_>|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
        <tr>
	  <th align=right>|.$locale->text('Period').qq|</th>
	  <td>
	  <select name=month>$selectaccountingmonth</select>
	  <select name=year>$selectaccountingyear</select>
	  </td>
	</tr>
|;
  }

  $form->{title} = $locale->text('Timesheet');
  
  $form->header;

  print qq|
<body>

<form method=post action="$form->{script}">

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        $selectemployee
	$selectfrom
      </table>
    </td>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->{action} = "continue";
  $form->{nextsub} = "display_timesheet";

  $form->hide_form(qw(type action nextsub path login));

  print qq|
<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
</form>
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|

</body>
</html>
|;

}


sub prepare_timesheet {

  ($name, $id) = split /--/, $form->{employee};

  $form->{transdate} = "$form->{year}$form->{month}01";
  $temp = $myconfig{dateformat};
  $myconfig{dateformat} = "yyyymmdd";
  
  $form->fdld(\%myconfig, \%locale);
  $form->{days} = substr($form->{ldm},-2);

  $myconfig{dateformat} = $temp;
  
  $dbh = $form->dbconnect(\%myconfig);
  
  $query = qq|SELECT a.project_id, a.parts_id, a.projectleaderid,
              pr.projectnumber, p.partnumber,
              to_char(a.startdate, 'YYYYMMDD') AS startdate,
	      to_char(a.enddate, 'YYYYMMDD') AS enddate
              FROM assignemployee a
	      JOIN project pr ON (pr.id = a.project_id)
	      JOIN parts p ON (p.id = a.parts_id)
	      WHERE a.employee_id = $id
	      AND (a.enddate >= '$form->{fdm}' OR a.enddate IS NULL)
	      AND (a.startdate < '$form->{"fdm+1"}' OR a.startdate IS NULL)
	      ORDER BY pr.projectnumber|;
  $sth = $dbh->prepare($query);

  $query = qq|SELECT qty, extract(day from checkedin),
              to_char(checkedin, 'YYYYMMDD')
              FROM jcitems
	      WHERE project_id = ?
	      AND parts_id = ?
	      AND employee_id = $id
	      AND checkedin >= date '$form->{fdm}'
	      AND checkedin < date '$form->{"fdm+1"}'|;
  $jth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute || $form->dberror($query);

  $form->{projects} = "";
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{projectleaderid} = $ref->{projectleaderid};
    $form->{$ref->{project_id}} = $ref->{projectnumber};
    $form->{"$ref->{project_id}--$ref->{parts_id}_startdate"} = $ref->{startdate};
    $form->{"$ref->{project_id}--$ref->{parts_id}_enddate"} = $ref->{enddate};
    $form->{$ref->{parts_id}} = $ref->{partnumber};
    $form->{projects} .= "$ref->{project_id}--$ref->{parts_id} ";
    
    $jth->execute($ref->{project_id}, $ref->{parts_id});
    while (($qty, $day, $transdate) = $jth->fetchrow_array) {
      $form->{"$ref->{project_id}--$ref->{parts_id}_${day}_qty"} += $qty;
      $form->{"$ref->{project_id}--$ref->{parts_id}_${day}_transdate"} = $transdate;
    }
    $jth->finish;
  }
  $sth->finish;

  $query = qq|SELECT to_char(date '$form->{fdm}', 'D')|;
  ($form->{weekday}) = $dbh->selectrow_array($query);
  
  $dbh->disconnect;

  chop $form->{projects};

  $form->error($locale->text('No projects assigned for time period!')) unless $form->{projects};

  %weekday = ( 0 => $locale->text('Mon'),
               1 => $locale->text('Tue'),
               2 => $locale->text('Wed'),
               3 => $locale->text('Thu'),
               4 => $locale->text('Fri'),
               5 => $locale->text('Sat'),
               6 => $locale->text('Sun'),
	     );

  for (1 .. $form->{days}) {
    $d = ($form->{weekday} - 3 + $_) % 7;
    $form->{"weekday_$_"} = $weekday{$d};
  }

}


sub display_timesheet {

  &prepare_timesheet;

  $form->{type} = "timesheet";

  $form->{title} = $locale->text('Timesheet');

  ($employee) = split /--/, $form->{employee};

  %month = &monthlabel(1);

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr>
    <td>|.$locale->text('Employee').qq| : $employee
    <br>|.$locale->text('Period').qq| : $month{$form->{month}} $form->{year}</td>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
|;

  print qq|
        <tr class=listheading>
|;

  @columns = split / /, $form->{projects};
  print qq|<th class=listheading>&nbsp;</th>
           <th class=listheading>&nbsp;</th>
|;
  for (@columns) {
    ($project_id, $parts_id) = split /--/, $_;
    print qq|
          <th class=listheading>$form->{$project_id}<br>$form->{$parts_id}</th>|;
  }
  print qq|<th class=listheading>|.$locale->text('Total').qq|</th>
        </tr>
|;

  $callback = $form->escape("$form->{script}?action=display_timesheet&employee=$form->{employee}&month=$form->{month}&year=$form->{year}&path=$form->{path}&login=$form->{login}",1);
  $employee = $form->escape($form->{employee},1);
  $href = "$form->{script}?action=edit_timesheet&employee=$employee&path=$form->{path}&login=$form->{login}&callback=$callback";
  
  for $i (1 .. $form->{days}) {
    $j++; $j %= 2;
    
    $j = 2 if $form->{"weekday_$i"} =~ /(Sat|Sun)/;

    $total = 0;
    print qq|
        <tr class=listrow$j>
          <td align=right>$i</td>
          <td>$form->{"weekday_$i"}</td>
|;
    for (@columns) {
      ($project_id, $parts_id) = split /--/, $_;
      
      $total += $form->{"${_}_${i}_qty"};
      $form->{"${_}_total"} += $form->{"${_}_${i}_qty"};
      $form->{total} += $form->{"${_}_${i}_qty"};
      $qty = $form->format_amount(\%myconfig, $form->{"${_}_${i}_qty"}, 1);
      $transdate = $form->{fdm} + $i - 1;
      if ($form->{"${_}_startdate"} <= $transdate) {
	$qty = "-" unless $qty;
	$add = ($qty eq "-");
	print qq|
          <td align=right><a href=$href&project_id=$project_id&parts_id=$parts_id&transdate=$transdate&add=$add>$qty</a></td>|;
      } else {
	print qq|
          <td align=right>$qty</td>|;
      }
    }

    print qq|<td align=right>|.$form->format_amount(\%myconfig, $total, 1, " ").qq|</td>
        </tr>
|;
  }

  print qq|<tr class=listtotal>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
|;
  for (@columns) {
    print qq|
        <th align=right class=listtotal>|.$form->format_amount(\%myconfig, $form->{"${_}_total"}, 1, " ").qq|</th>|;
  }
  print qq|<th align=right>|.$form->format_amount(\%myconfig, $form->{total}, 1, " ").qq|</th>
        </tr>
|;
 
    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->hide_form(qw(type path login projects employee));

  print qq|
</form>

</body>
</html>
|;

}


sub monthlabel {
  my ($longformat) = @_;
  
  if ($longformat) {
    %m = ( '01' => $locale->text('January'),
           '02' => $locale->text('February'),
           '03' => $locale->text('March'),
           '04' => $locale->text('April'),
           '05' => $locale->text('May'),
           '06' => $locale->text('June'),
           '07' => $locale->text('July'),
           '08' => $locale->text('August'),
           '09' => $locale->text('September'),
           '10' => $locale->text('October'),
           '11' => $locale->text('November'),
           '12' => $locale->text('December')
	 );
  } else {
    %m = ( '01' => $locale->text('Jan'),
           '02' => $locale->text('Feb'),
           '03' => $locale->text('Mar'),
           '04' => $locale->text('Apr'),
           '05' => $locale->text('May'),
           '06' => $locale->text('Jun'),
           '07' => $locale->text('Jul'),
           '08' => $locale->text('Aug'),
           '09' => $locale->text('Sep'),
           '10' => $locale->text('Oct'),
           '11' => $locale->text('Nov'),
           '12' => $locale->text('Dec')
	 );
  }

  %m;
  
}


sub edit_timesheet {
  
  $dbh = $form->dbconnect(\%myconfig);

  ($employee, $employee_id) = split /--/, $form->{employee};
  
  $form->{project_id} *= 1;
  $form->{parts_id} *= 1;

  # check if more than one entry
  $query = qq|SELECT count(*)
              FROM jcitems
	      WHERE project_id = $form->{project_id}
	      AND parts_id = $form->{parts_id}
	      AND to_char(checkedin, 'YYYYMMDD') = '$form->{transdate}'
	      AND employee_id = $employee_id|;
  ($count) = $dbh->selectrow_array($query);

  if ($count > 1) {
    $dbh->disconnect;

    $form->{projectnumber} = "--$form->{project_id}";
    $form->{startdatefrom} = $form->{transdate};
    $form->{startdateto} = $form->{transdate};
    $form->{type} = "timecard";
    $form->{project} = "project";

    &list_assignedtimecards;
    exit;

  }
  
  $query = qq|SELECT id
              FROM jcitems
	      WHERE project_id = $form->{project_id}
	      AND parts_id = $form->{parts_id}
	      AND to_char(checkedin, 'YYYYMMDD') = '$form->{transdate}'
	      AND employee_id = $employee_id|;
  ($form->{id}) = $dbh->selectrow_array($query);
 
  $query = qq|SELECT projectnumber
              FROM project
	      WHERE id = $form->{project_id}|;
  ($project) = $dbh->selectrow_array($query);
  
  $query = qq|SELECT partnumber
              FROM parts
	      WHERE id = $form->{parts_id}|;
  ($partnumber) = $dbh->selectrow_array($query);

  $dbh->disconnect;
  
  # lock project and transaction date
  $form->{transdate} = $form->{transdatelocked} = $form->format_date($myconfig{dateformat}, $form->{transdate});

  $form->{projectnumber} = "$project--$form->{project_id}";
  $form->{partnumber} = "$partnumber--$form->{parts_id}";

  $form->{type} = "timecard";
  $form->{project} = "project";

  if ($form->{add}) {
    &add;
  } else {
    &edit;
  }
  
}


sub inonego {
  
  $dbh = $form->dbconnect(\%myconfig);

  $form->all_employees(\%myconfig, $dbh);

  if ($myconfig{role} eq 'timesheet') {
    ($name, $id) = $form->get_employee($dbh);
    $form->{employee} = "$name--$id";
    $selectemployee = qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('Employee').qq|</th>
	  <td>$name</td>
        </tr>
|.$form->hide_form(qw(employee));
  } else {
    if (@{ $form->{all_employee} }) {
      $form->{selectemployee} = "";
      for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }

      $selectemployee = qq|
	  <tr>
	    <th align=right nowrap>|.$locale->text('Employee').qq|</th>
	    <td><select name=employee>|
	    .$form->select_option($form->{selectemployee}, undef, 1)
	    .qq|
	    </select></td>
	  </tr>
  |;
    } else {
      $form->error($locale->text('No Employees on file!'));
    }
  }
  
 
  # accounting years
  $form->all_years(\%myconfig, $dbh);

  $dbh->disconnect;

  if (@{ $form->{all_years} }) {
    $selectaccountingyear = "";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|<option>$_\n| }

    $selectaccountingmonth = "";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|<option value=$_>|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
        <tr>
	  <th align=right>|.$locale->text('Period').qq|</th>
	  <td>
	  <select name=month>$selectaccountingmonth</select>
	  <select name=year>$selectaccountingyear</select>
	  </td>
	</tr>
|;
  }

  $form->{title} = $locale->text('Timesheet');
  
  $form->header;

  print qq|
<body>

<form method=post action="$form->{script}">

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        $selectemployee
	$selectfrom
      </table>
    </td>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->{action} = "continue";
  $form->{nextsub} = "display_inonego";
  $form->{type} = "inonego";

  $form->hide_form(qw(type action nextsub path login));

  print qq|
<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
</form>
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|

</body>
</html>
|;

}


sub display_inonego {

  &prepare_timesheet;
  
  $form->{type} = "inonego";
  
  $form->{title} = $locale->text('Timesheet');

  ($employee) = split /--/, $form->{employee};

  %month = ( '01' => $locale->text('January'),
             '02' => $locale->text('February'),
             '03' => $locale->text('March'),
             '04' => $locale->text('April'),
             '05' => $locale->text('May'),
             '06' => $locale->text('June'),
             '07' => $locale->text('July'),
             '08' => $locale->text('August'),
             '09' => $locale->text('September'),
             '10' => $locale->text('October'),
             '11' => $locale->text('November'),
             '12' => $locale->text('December')
	   );
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr>
    <td>|.$locale->text('Employee').qq| : $employee
    <br>|.$locale->text('Period').qq| : $month{$form->{month}} $form->{year}</td>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
|;

  print qq|
        <tr class=listheading>
|;

  @columns = split / /, $form->{projects};
  print qq|<th class=listheading>&nbsp;</th>
           <th class=listheading>&nbsp;</th>
|;
  for (@columns) {
    ($project_id, $parts_id) = split /--/, $_;
    print qq|
          <th class=listheading>$form->{$project_id}<br>$form->{$parts_id}</th>|;
  }
  print qq|<th class=listheading>|.$locale->text('Total').qq|</th>
        </tr>
|;

  $employee = $form->escape($form->{employee},1);
  
  for $i (1 .. $form->{days}) {
    $j++; $j %= 2;
    
    $j = 2 if $form->{"weekday_$i"} =~ /(Sat|Sun)/;

    $total = 0;
    print qq|
        <tr class=listrow$j>
          <td align=right>$i</td>
          <td>$form->{"weekday_$i"}</td>
|;
    for (@columns) {
      ($project_id, $parts_id) = split /--/, $_;
      
      $total += $form->{"${_}_${i}_qty"};
      $form->{"${_}_total"} += $form->{"${_}_${i}_qty"};
      $form->{total} += $form->{"${_}_${i}_qty"};
      $qty = $form->format_amount(\%myconfig, $form->{"${_}_${i}_qty"}, 1);
      $transdate = $form->{fdm} + $i - 1;
      if ($form->{"${_}_startdate"} <= $transdate) {
	print qq|
          <td align=right><input name="${project_id}--${parts_id}_$i" size=4 value="$qty"></td>|;
      } else {
	print qq|
          <td align=right>$qty</td>|;
      }
    }

    print qq|<td align=right>|.$form->format_amount(\%myconfig, $total, 1, " ").qq|</td>
        </tr>
|;
  }

  print qq|<tr class=listtotal>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
|;
  for (@columns) {
    print qq|
        <th align=right class=listtotal>|.$form->format_amount(\%myconfig, $form->{"${_}_total"}, 1, " ").qq|</th>|;
  }
  print qq|<th align=right>|.$form->format_amount(\%myconfig, $form->{total}, 1, " ").qq|</th>
        </tr>
|;
 
    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->hide_form(qw(projectleaderid fdm days type path login projects employee));
  
  %button = ('Save' => { ndx => 1, key => 'S', value => $locale->text('Save ') },
             'Print' => { ndx => 2, key => 'P', value => $locale->text('Print ') },
	     'E-Mail' => { ndx => 3, key => 'M', value => $locale->text('E-Mail') },
	    );

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
 
  print qq|
</form>

</body>
</html>
|;

}


sub list_assignedtimecards {

  $form->{title} = $locale->text('Time Cards');

  ($employee) = split /--/, $form->{employee};

  JC->jcitems(\%myconfig, \%$form);
  
  @column_index = qw(transdate id projectnumber projectname partnumber description qty);
  
  $column_data{id} = "<th class=listheading>".$locale->text('ID')."</th>";
  $column_data{transdate} = "<th class=listheading>".$locale->text('Date')."</th>";
  $column_data{description} = "<th class=listheading>".$locale->text('Description')."</th>";
  $column_data{projectnumber} = "<th class=listheading>".$locale->text('Project Number')."</th>";
  $column_data{partnumber} = "<th class=listheading>".$locale->text('Service Code')."</th>";
  $column_data{projectname} = "<th class=listheading>".$locale->text('Project Name')."</th>";
  $column_data{qty} = "<th class=listheading>".$locale->text('Qty')."</th>";

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr>
	  <th colspan=2 align=left>
	    $employee
          </th>
	</tr>
	<tr class=listheading>
|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;

  $callback = $form->escape($form->{callback},1);
  
  foreach $ref (@{ $form->{transactions} }) {

    for (qw(description)) { $ref->{$_} =~ s/\n/<br>/g }
    for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
    $column_data{qty} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{qty}, undef, "&nbsp;")."</td>";
    $column_data{id} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&type=$ref->{type}&path=$form->{path}&login=$form->{login}&project=$ref->{project}&callback=$callback>$ref->{id}</a></td>";
    $j++; $j %= 2;
    print qq|
        <tr class=listrow$j>
|;
    for (@column_index) { print "\n$column_data{$_}" }
    print qq|
        </tr>
|;
  }

  print qq|
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

</body>
</html>
|;

    
}


sub delete_assignedtimecard {

  $form->{type} = "timecard";
  &{ "delete_$form->{type}" };
  
}


sub e_mail {
  
  use SL::Mailer;
  
  $mail = new Mailer;
  
  $dbh = $form->dbconnect(\%myconfig);

  $query = qq|SELECT email
              FROM employee
	      WHERE id = $form->{projectleaderid}|;
  ($to) = $dbh->selectrow_array($query);

  ($name, $id) = split /--/, $form->{employee};
  
  $query = qq|SELECT email
              FROM employee
	      WHERE id = $id|;
  ($from) = $dbh->selectrow_array($query);

  $dbh->disconnect;

  $form->error($locale->text('No E-mail for projectleader!')) unless $to;
  
  %month = &monthlabel;
  
  $form->{year} = substr($form->{fdm},0,4);
  $form->{month} = substr($form->{fdm},4,2);
  $mm = $month{$form->{month}};
  
  $mail->{$version} = $form->{version};
  $mail->{to} = $to;
  $mail->{from} = qq|"$name" <$from>|;
  $mail->{contenttype} = "text/plain";
  
  $mail->{subject} = $locale->text('Timesheet').qq| / $name / $mm $form->{year}|;
  
  $mail->{message} = $locale->text('Timesheet for').qq| $name |.$locale->text('is ready.');
  
  $mail->send($sendmail);

  $form->redirect($locale->text('Timesheet notification sent!'));

}


sub print_ {
  
  %month = &monthlabel;
  
  $form->{year} = substr($form->{fdm},0,4);
  $form->{month} = substr($form->{fdm},4,2);

  &prepare_timesheet;
  
  $form->{type} = "timesheet";

  $form->{title} = $locale->text('Timesheet');

  ($employee) = split /--/, $form->{employee};

  %month = &monthlabel(1);

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr>
    <td>|.$locale->text('Employee').qq| : $employee
    <br>|.$locale->text('Period').qq| : $month{$form->{month}} $form->{year}</td>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
|;

  print qq|
        <tr class=listheading>
|;

  @columns = split / /, $form->{projects};
  print qq|<th class=listheading width=1%>&nbsp;</th>
           <th class=listheading width=1%>&nbsp;</th>
|;

  $width = 100 / ($#columns + 2);
  
  for (@columns) {
    ($project_id, $parts_id) = split /--/, $_;
    print qq|
          <th class=listheading width=${width}%>$form->{$project_id}<br>$form->{$parts_id}</th>|;
  }
  print qq|<th class=listheading width=${width}%>|.$locale->text('Total').qq|</th>
        </tr>
|;

  for $i (1 .. $form->{days}) {
    $j++; $j %= 2;
    
    $j = 2 if $form->{"weekday_$i"} =~ /(Sat|Sun)/;

    $total = 0;
    print qq|
        <tr class=listrow$j>
          <td align=right>$i</td>
          <td>$form->{"weekday_$i"}</td>
|;
    for (@columns) {
      ($project_id, $parts_id) = split /--/, $_;
      
      $total += $form->{"${_}_${i}_qty"};
      $form->{"${_}_total"} += $form->{"${_}_${i}_qty"};
      $form->{total} += $form->{"${_}_${i}_qty"};
      $qty = $form->format_amount(\%myconfig, $form->{"${_}_${i}_qty"}, 1);
      $transdate = $form->{fdm} + $i - 1;
      if ($form->{"${_}_startdate"} <= $transdate) {
	$qty = "-" unless $qty;
	print qq|
          <td align=right>$qty</td>|;
      } else {
	print qq|
          <td align=right>$qty</td>|;
      }
    }

    print qq|<td align=right>|.$form->format_amount(\%myconfig, $total, 1, " ").qq|</td>
        </tr>
|;
  }

  print qq|<tr class=listtotal>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
|;
  for (@columns) {
    print qq|
        <th align=right class=listtotal>|.$form->format_amount(\%myconfig, $form->{"${_}_total"}, 1, " ").qq|</th>|;
  }
  print qq|<th align=right>|.$form->format_amount(\%myconfig, $form->{total}, 1, " ").qq|</th>
        </tr>
|;
 
    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

</body>
</html>
|;

}


1;

