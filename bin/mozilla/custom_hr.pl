
1;

##### SSB

sub employee_links {

  HR->get_employee(\%myconfig, \%$form);

  for (keys %$form) { $form->{$_} = $form->quote($form->{$_}) }

  if (@{ $form->{all_deduction} }) {
    $form->{selectdeduction} = "\n";
    for (@{ $form->{all_deduction} }) { $form->{selectdeduction} .= qq|$_->{description}--$_->{id}\n| }
  }

  $form->{manager} = "$form->{manager}--$form->{managerid}" if $form->{managerid};

  if (@{ $form->{all_manager} }) {
    $form->{selectmanager} = "\n";
    for (@{ $form->{all_manager} }) { $form->{selectmanager} .= qq|$_->{name}--$_->{id}\n| }
  }

  %role = ( user	=> $locale->text('User'),
            timesheet	=> $locale->text('Timesheet'),
            supervisor	=> $locale->text('Supervisor'),
	    manager	=> $locale->text('Manager'),
            admin	=> $locale->text('Administrator')
	  );
  
  $form->{selectrole} = "\n";
  for (qw(user timesheet supervisor manager admin)) { $form->{selectrole} .= "$_--$role{$_}\n" }

  $i = 1;
  foreach $ref (@{ $form->{all_employeededuction} }) {
    $form->{"deduction_$i"} = "$ref->{description}--$ref->{id}" if $ref->{id};
    for (qw(before after rate)) { $form->{"${_}_$i"} = $ref->{$_} }
    $i++;
  }
  $form->{deduction_rows} = $i - 1;

  for (qw(deduction manager role)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }

  if (! $form->{readonly}) {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Add Employee/;
  }

  &employee_header;
  &employee_footer;

}


sub list_employees {

  HR->employees(\%myconfig, \%$form);
  
  $href = "$form->{script}?action=list_employees&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&status=$form->{status}";
  
  $form->sort_order();

  $callback = "$form->{script}?action=list_employees&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&status=$form->{status}";
  
  @columns = $form->sort_columns(qw(id employeenumber name address city state zipcode country workphone workfax workmobile homephone email startdate enddate ssn dob iban bic sales role manager login notes));
  unshift @columns, "ndx";

  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      # add column to href and callback
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }

  %role = ( user	=> $locale->text('User'),
            timesheet	=> $locale->text('Timesheet'),
            supervisor	=> $locale->text('Supervisor'),
	    manager	=> $locale->text('Manager'),
            admin	=> $locale->text('Administrator')
	  );
  
  $option = $locale->text('All');

  if ($form->{status} eq 'sales') {
    $option = $locale->text('Sales');
  }
  if ($form->{status} eq 'orphaned') {
    $option = $locale->text('Orphaned');
  }
  if ($form->{status} eq 'active') {
    $option = $locale->text('Active');
  }
  if ($form->{status} eq 'inactive') {
    $option = $locale->text('Inactive');
  }
  
  if ($form->{employeenumber}) {
    $callback .= "&employeenumber=".$form->escape($form->{employeenumber},1);
    $href .= "&employeenumber=".$form->escape($form->{employeenumber});
    $option .= "\n<br>".$locale->text('Employee Number')." : $form->{employeenumber}";
  }
  if ($form->{name}) {
    $callback .= "&name=".$form->escape($form->{name},1);
    $href .= "&name=".$form->escape($form->{name});
    $option .= "\n<br>".$locale->text('Employee Name')." : $form->{name}";
  }
  if ($form->{startdatefrom}) {
    $callback .= "&startdatefrom=$form->{startdatefrom}";
    $href .= "&startdatefrom=$form->{startdatefrom}";
    $fromdate = $locale->date(\%myconfig, $form->{startdatefrom}, 1);
  }
  if ($form->{startdateto}) {
    $callback .= "&startdateto=$form->{startdateto}";
    $href .= "&startdateto=$form->{startdateto}";
    $todate = $locale->date(\%myconfig, $form->{startdateto}, 1);
  }
  if ($fromdate || $todate) {
    $option .= "\n<br>".$locale->text('Startdate')." $fromdate - $todate";
  }
  
  if ($form->{notes}) {
    $callback .= "&notes=".$form->escape($form->{notes},1);
    $href .= "&notes=".$form->escape($form->{notes});
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Notes')." : $form->{notes}";
  }

  $form->{callback} = "$callback&sort=$form->{sort}";
  $callback = $form->escape($form->{callback});

  $column_header{ndx} = qq|<th class=listheading width=1%>&nbsp;</th>|;
  $column_header{id} = qq|<th class=listheading>|.$locale->text('ID').qq|</th>|;
  $column_header{employeenumber} = qq|<th><a class=listheading href=$href&sort=employeenumber>|.$locale->text('Number').qq|</a></th>|;
  $column_header{name} = qq|<th><a class=listheading href=$href&sort=name>|.$locale->text('Name').qq|</a></th>|;
  $column_header{manager} = qq|<th><a class=listheading href=$href&sort=manager>|.$locale->text('Manager').qq|</a></th>|;
  $column_header{address} = qq|<th class=listheading>|.$locale->text('Address').qq|</a></th>|;
  $column_header{city} = qq|<th><a class=listheading href=$href&sort=city>|.$locale->text('City').qq|</a></th>|;
  $column_header{state} = qq|<th><a class=listheading href=$href&sort=state>|.$locale->text('State/Province').qq|</a></th>|;
  $column_header{zipcode} = qq|<th><a class=listheading href=$href&sort=zipcode>|.$locale->text('Zip/Postal Code').qq|</a></th>|;
  $column_header{country} = qq|<th><a class=listheading href=$href&sort=country>|.$locale->text('Country').qq|</a></th>|;
  $column_header{workphone} = qq|<th><a class=listheading href=$href&sort=workphone>|.$locale->text('Work Phone').qq|</a></th>|;
  $column_header{workfax} = qq|<th><a class=listheading href=$href&sort=workfax>|.$locale->text('Work Fax').qq|</a></th>|;
  $column_header{workmobile} = qq|<th><a class=listheading href=$href&sort=workmobile>|.$locale->text('Work Mobile').qq|</a></th>|;
  $column_header{homephone} = qq|<th><a class=listheading href=$href&sort=homephone>|.$locale->text('Home Phone').qq|</a></th>|;
  
  $column_header{startdate} = qq|<th><a class=listheading href=$href&sort=startdate>|.$locale->text('Startdate').qq|</a></th>|;
  $column_header{enddate} = qq|<th><a class=listheading href=$href&sort=enddate>|.$locale->text('Enddate').qq|</a></th>|;
  $column_header{notes} = qq|<th><a class=listheading href=$href&sort=notes>|.$locale->text('Notes').qq|</a></th>|;
  $column_header{role} = qq|<th><a class=listheading href=$href&sort=role>|.$locale->text('Role').qq|</a></th>|;
  $column_header{login} = qq|<th><a class=listheading href=$href&sort=login>|.$locale->text('Login').qq|</a></th>|;
  
  $column_header{sales} = qq|<th class=listheading>|.$locale->text('S').qq|</th>|;
  $column_header{email} = qq|<th><a class=listheading href=$href&sort=email>|.$locale->text('E-mail').qq|</a></th>|;
  $column_header{ssn} = qq|<th><a class=listheading href=$href&sort=ssn>|.$locale->text('SSN').qq|</a></th>|;
  $column_header{dob} = qq|<th><a class=listheading href=$href&sort=dob>|.$locale->text('DOB').qq|</a></th>|;
  $column_header{iban} = qq|<th><a class=listheading href=$href&sort=iban>|.$locale->text('IBAN').qq|</a></th>|;
  $column_header{bic} = qq|<th><a class=listheading href=$href&sort=bic>|.$locale->text('BIC').qq|</a></th>|;
  
  $form->{title} = $locale->text('Employees') . " / $form->{company}";

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

  for (@column_index) { print "$column_header{$_}\n" }
  
  print qq|
        </tr>
|;

  $i = 0;
  foreach $ref (@{ $form->{all_employee} }) {

    $i++;
    
    $ref->{notes} =~ s/\r?\n/<br>/g;
    for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

    $column_data{ndx} = "<td align=right>$i</td>";
    
    $column_data{sales} = ($ref->{sales}) ? "<td>x</td>" : "<td>&nbsp;</td>";
    $column_data{role} = qq|<td>$role{"$ref->{role}"}&nbsp;</td>|;
    $column_date{address} = qq|$ref->{address1} $ref->{address2}|;

    $column_data{name} = "<td><a href=$form->{script}?action=edit&db=employee&id=$ref->{id}&path=$form->{path}&login=$form->{login}&status=$form->{status}&callback=$callback>$ref->{name}&nbsp;</td>";

    if ($ref->{email}) {
      $email = $ref->{email};
      $email =~ s/</\&lt;/;
      $email =~ s/>/\&gt;/;
      
      $column_data{email} = qq|<td><a href="mailto:$ref->{email}">$email</a></td>|;
    }

    $j++; $j %= 2;
    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
        </tr>
|;
    
  }

  $i = 1;
  $button{'HR--Employees--Add Employee'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Employee').qq|"> |;
  $button{'HR--Employees--Add Employee'}{order} = $i++;

  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(callback db path login));
  
  foreach $item (sort { $a->{order} <=> $b->{order} } %button) {
    print $item->{code};
  }

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
  </form>

</body>
</html>
|;
 
}


