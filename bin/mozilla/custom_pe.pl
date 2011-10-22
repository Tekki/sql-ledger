#===============================================================
# monthly timesheet entry form
# assign projects to employee to restrict projects and service codes
#
#   Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#


1;

########### SSB
sub assign_projects {

  $form->error($locale->text('Not authorized!')) if $myconfig{acs} =~ /HR--Employees--Assign Projects/;
  
  $dbh = $form->dbconnect(\%myconfig);
  
  if ($form->{all}) {
    $query = qq|SELECT id, name
		FROM employee
		WHERE enddate IS NULL
		ORDER BY name|;
  } else {
    ##### get timesheet employees
    $query = qq|SELECT id, name
		FROM employee
		WHERE role = 'timesheet'
		AND enddate IS NULL
		ORDER BY name|;
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{selectemployee} .= qq|$ref->{name}--$ref->{id}\n|;
    $ok = 1;
  }
  $sth->finish;
 
  $dbh->disconnect;

  $form->error($locale->text('No Employees!')) if !$ok;

  $form->{title} = $locale->text('Assign Projects');
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right nowrap>|.$locale->text('Employee').qq|</th>
	  <td><select name="assignemployee">|
	    .$form->select_option($form->{"selectemployee"}, undef, 1)
	    .qq|</select>
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

  $form->{nextsub} = "assigned_project";
  
  $form->hide_form(qw(nextsub callback path login));

  print qq|
<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub assigned_project {

  $form->{type} = "assigned_project";
  &get_assigned_project;
  &display_form;
  
}


sub get_assigned_project {

  ($name, $id) = split /--/, $form->{assignemployee};
  
  $dbh = $form->dbconnect(\%myconfig);
  
  %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};

  ##### projectleaders
  $query = qq|SELECT id, name
              FROM employee
	      WHERE role != 'timesheet'
	      AND enddate IS NULL
	      AND id != $id
	      ORDER BY name|;

  $sth = $dbh->prepare($query);
  
  $sth->execute || $form->dberror($query);
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{selectleader} .= qq|$ref->{name}--$ref->{id}\n|;
  }
  $sth->finish;
  
  $query = qq|SELECT a.*, p.partnumber, pr.projectnumber,
	      e.name
              FROM assignemployee a
	      JOIN employee e ON (e.id = a.projectleaderid)
              JOIN project pr ON (pr.id = a.project_id)
              JOIN parts p ON (p.id = a.parts_id)
	      WHERE a.employee_id = $id|;
  $sth = $dbh->prepare($query);
  
  $sth->execute || $form->dberror($query);

  $i = 1;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{projectleader} = qq|$ref->{name}--$ref->{projectleaderid}|;
    $form->{"projectnumber_$i"} = qq|$ref->{projectnumber}--$ref->{project_id}|;
    $form->{"partnumber_$i"} = qq|$ref->{partnumber}--$ref->{parts_id}|;
    for (qw(description startdate enddate)) { $form->{"${_}_$i"} = $ref->{$_} }
    $form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $ref->{sellprice}, $form->{precision});
    $i++;
  }
  $sth->finish;

  $form->{rowcount} = $i;
  
  $query = qq|SELECT id, partnumber
              FROM parts
	      WHERE inventory_accno_id IS NULL
	      AND assembly = '0'
	      AND obsolete = '0'|;
  $sth = $dbh->prepare($query);
  
  $sth->execute || $form->dberror($query);
  $form->{selectpart} = "\n";
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{selectpart} .= "$ref->{partnumber}--$ref->{id}\n";
  }
  $sth->finish;

  $query = qq|SELECT id, projectnumber
              FROM project
	      WHERE enddate IS NULL
	      AND parts_id IS NULL|;
  $sth = $dbh->prepare($query);
  
  $sth->execute || $form->dberror($query);
  $form->{selectproject} = "\n";
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{selectproject} .= "$ref->{projectnumber}--$ref->{id}\n";
  }
  $sth->finish;

  $dbh->disconnect;
  
  $form->error($locale->text('None of the employees have rights to be a leader!')) unless $form->{selectleader};

  for (qw(leader project part)) { $form->{"select$_"} = $form->escape($form->{"select$_"}, 1) }

}


sub assigned_project_header {
  
  $form->{title} = $locale->text('Assign Projects');

  ($assignemployee) = split /--/, $form->{assignemployee};
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right nowrap>|.$locale->text('Employee').qq|</th>
	  <td>$assignemployee</td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Project Leader').qq|</th>
	  <td><select name="projectleader">|
	    .$form->select_option($form->{selectleader}, $form->{projectleader}, 1)
	    .qq|</select>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=left nowrap>|.$locale->text('Project Number').qq|</th>
	  <th align=left nowrap>|.$locale->text('Service Code').qq|</th>
	  <th align=left nowrap>|.$locale->text('Description').qq|</th>
	  <th align=left nowrap>|.$locale->text('Sellprice').qq|</th>
	  <th align=left nowrap>|.$locale->text('Startdate').qq|</th>
	  <th align=left nowrap>|.$locale->text('Enddate').qq|</th>
	</tr>
|;

  for $i (1 .. $form->{rowcount}) {
    $description = $form->quote($form->{"description_$i"});

    print qq|
        <tr>
	  <td><select name="projectnumber_$i">|
	    .$form->select_option($form->{selectproject}, $form->{"projectnumber_$i"}, 1)
	    .qq|</select>
          </td>
	  <td><select name="partnumber_$i">|
	    .$form->select_option($form->{selectpart}, $form->{"partnumber_$i"}, 1)
	    .qq|</select>
          </td>
	  <td><input name="description_$i" size=20 value="$description"></td>
	  <td><input name="sellprice_$i" align=right value="$form->{"sellprice_$i"}"></td>
	  <td><input name="startdate_$i" size=11 class=date title="$myconfig{dateformat}" value="$form->{"startdate_$i"}"></td>
	  <td><input name="enddate_$i" size=11 class=date title="$myconfig{dateformat}" value="$form->{"enddate_$i"}"></td>
	</tr>
|;

    $form->{"oldpartnumber_$i"} = $form->{"partnumber_$i"};
    $form->hide_form("oldpartnumber_$i");

  }

  print qq|
      </table>
    </td>	  
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}

sub assigned_project_footer {
  
  $form->hide_form(map { "select$_" } qw(leader part project));
  $form->hide_form(qw(type rowcount assignemployee callback path login));

  %button = ('Update ' => { ndx => 1, key => 'U', value => $locale->text('Update ') },
             'Save ' => { ndx => 3, key => 'S', value => $locale->text('Save ') },
	    );

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

  print qq|
</form>

</body>
</html>
|;

}


sub update_ {

  $dbh = $form->dbconnect(\%myconfig);
  
  %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};
  
  $query = qq|SELECT description, sellprice
              FROM parts
	      WHERE id = ?|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  
  @flds = qw(projectnumber partnumber description sellprice startdate enddate);
  @f = ();
  $count = 0;
  
  # add/delete row
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"projectnumber_$i"} && $form->{"partnumber_$i"}) {

      $form->{"sellprice_$i"} = $form->parse_amount(\%myconfig, $form->{"sellprice_$i"});
      if ($form->{"partnumber_$i"} ne $form->{"oldpartnumber_$i"}) {
	($null, $id) = split /--/, $form->{"partnumber_$i"};
	$sth->execute($id);
	($form->{"description_$i"}, $form->{"sellprice_$i"}) = $sth->fetchrow_array;
	$sth->finish;
      }

      $form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $form->{precision});

      push @f, {};
      $j = $#f;
      
      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
  $form->redo_rows(\@flds, \@f, $count, $form->{rowcount});
  $form->{rowcount} = $count + 1;

  $dbh->disconnect;

  &display_form;

}


sub save_ {
  
  $dbh = $form->dbconnect_noauto(\%myconfig);

  ($name, $employee_id) = split /--/, $form->{assignemployee};

  ($null, $projectleaderid) = split /--/, $form->{projectleader};
  
  $query = qq|DELETE FROM
              assignemployee
	      WHERE employee_id = $employee_id|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|INSERT INTO
              assignemployee (employee_id, parts_id, project_id,
	      projectleaderid, startdate, enddate, description, sellprice) VALUES
	      ($employee_id, ?, ?, $projectleaderid, ?, ?, ?, ?)|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  for $i (1 .. $form->{rowcount}) {
    if ($form->{"projectnumber_$i"} && $form->{"partnumber_$i"}) {

      for (qw(partnumber projectnumber)) {
	($null, $id) = split /--/, $form->{"${_}_$i"};
	$f{$_} = $id;
      }
      
      undef $form->{"startdate_$i"} unless $form->{"startdate_$i"};
      undef $form->{"enddate_$i"} unless $form->{"enddate_$i"};
      $sellprice = $form->parse_amount(\%myconfig, $form->{"sellprice_$i"});
      $sth->execute($f{partnumber}, $f{projectnumber}, $form->{"startdate_$i"}, $form->{"enddate_$i"}, $form->{"description_$i"}, $sellprice);
      $sth->finish;
    }
  }
  
  $dbh->commit;
  $dbh->disconnect;

  $form->redirect($locale->text('Projects assigned to Employee')." : $name");
  
}


sub assigned_projects {

  $dbh = $form->dbconnect(\%myconfig);
  
  %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};

  $form->{sort} ||= "employee";
  
  @sf = (employee);
  $sortorder = $form->sort_order(\@sf);

  $query = qq|SELECT a.*, e.name AS employee, l.name AS projectleader,
              p.partnumber, pr.projectnumber, e.id
              FROM assignemployee a
	      JOIN employee e ON (e.id = a.employee_id)
	      JOIN employee l ON (l.id = a.projectleaderid)
	      JOIN parts p ON (p.id = a.parts_id)
	      JOIN project pr ON (pr.id = a.project_id)
	      ORDER BY $sortorder|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute || $form->dberror($query);

  $href = "$form->{script}?action=assigned_projects";
  for (qw(direction oldsort path login)) { $href .= qq|&$_=$form->{$_}| }

  $form->sort_order();

  $callback = "$form->{script}?action=assigned_projects";
  for (qw(direction oldsort path login)) { $callback .= qq|&$_=$form->{$_}| }

  @column_index = $form->sort_columns(qw(employee projectleader projectnumber partnumber description sellprice startdate enddate));

  $column_data{employee} = "<th><a class=listheading href=$href&sort=employee>".$locale->text('Employee')."</a></th>";
  $column_data{projectleader} = "<th><a class=listheading href=$href&sort=projectleader>".$locale->text('Projectleader')."</a></th>";
  $column_data{projectnumber} = "<th><a class=listheading href=$href&sort=projectnumber>".$locale->text('Projectnumber')."</a></th>";
  $column_data{partnumber} = "<th><a class=listheading href=$href&sort=partnumber>".$locale->text('Service Code')."</a></th>";
  $column_data{description} = "<th><a class=listheading href=$href&sort=description>".$locale->text('Description')."</a></th>";
  $column_data{startdate} = "<th><a class=listheading href=$href&sort=startdate>".$locale->text('Startdate')."</a></th>";
  $column_data{enddate} = "<th><a class=listheading href=$href&sort=enddate>".$locale->text('Enddate')."</a></th>";
  $column_data{sellprice} = "<th class=listheading>".$locale->text('Sellprice')."</th>";

  $form->{title} = $locale->text('Assigned Projects');

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
        <tr class=listheading>
|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;

  $form->{callback} = $callback .= "&sort=$form->{sort}";
  $callback = $form->escape($callback);
  

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    for (@column_index) { $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>| }

    $employee = $form->escape($ref->{employee},1);
    $column_data{employee} = qq|<td><a href=$form->{script}?path=$form->{path}&login=$form->{login}&action=assigned_project&assignemployee=$employee--$ref->{id}&callback=$callback>$ref->{employee}</td>|;
    
    $column_data{sellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice}, $form->{precision}).qq|</td>|;

    $j++; $j %= 2;
    print qq|
        <tr class=listrow$j>
|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

  }
  $sth->finish;
  $dbh->disconnect;

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


