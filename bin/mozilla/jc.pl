#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Job Costing module
#
#======================================================================

use SL::JC;

require "$form->{path}/cm.pl";
require "$form->{path}/sr.pl";
require "$form->{path}/js.pl";

1;
# end of main



sub add {

  if ($form->{type} eq 'timecard') {
    $form->{title} = $locale->text('Add Time Card');
  }
  if ($form->{type} eq 'storescard') {
    $form->{title} = $locale->text('Add Stores Card');
  }

  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&login=$form->{login}&path=$form->{path}&project=$form->{project}" unless $form->{callback};

  &{ "prepare_$form->{type}" };
  
  $form->{orphaned} = 1;
  &display_form;
  
}


sub edit {

  if ($form->{type} eq 'timecard') {
    $form->{title} = $locale->text('Edit Time Card');
  }
  if ($form->{type} eq 'storescard') {
    $form->{title} = $locale->text('Edit Stores Card');
  }
 
  &{ "prepare_$form->{type}" };
  
  &display_form;
 
}


sub jcitems_links {

  if (@{ $form->{all_project} }) {
    $form->{selectprojectnumber} = "";
    $form->{projectnumber} ||= "";
    foreach $ref (@{ $form->{all_project} }) {
      $form->{selectprojectnumber} .= qq|$ref->{projectnumber}--$ref->{id}\n|;
      if ($form->{projectnumber} eq "$ref->{projectnumber}--$ref->{id}") {
	$form->{projectdescription} = $ref->{description};
      }
    }
  } else {
    if ($form->{project} eq 'job') {
      $form->error($locale->text('No open Jobs!'));
    } else {
      $form->error($locale->text('No open Projects!'));
    }
  }
  
  # employees
  if (@{ $form->{all_employee} }) {
    $form->{selectemployee} = "\n";
    $form->{employee} ||= "";
    for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }
  } else {
    $form->error($locale->text('No Employees on file!'));
  }

  for (qw(projectnumber employee)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }
  
}


sub search {
  
  # accounting years
  $form->all_years(\%myconfig);

  if (@{ $form->{all_years} }) {
    $selectaccountingyear = "\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|$_\n| }
    $selectaccountingmonth = "\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|$_--|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
        <tr>
	  <th align=right>|.$locale->text('Period').qq|</th>
	  <td colspan=3>
	  <select name=month>|.$form->select_option($selectaccountingmonth, $form->{month}, 1, 1).qq|</select>
	  <select name=year>|.$form->select_option($selectaccountingyear, $form->{year}).qq|</select>
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
	  <td>|.$locale->text('From').qq| <input name=startdatefrom size=11 class=date title="$myconfig{dateformat}">|.&js_calendar("main", "startdatefrom")
	  .$locale->text('To').qq| <input name=startdateto size=11 class=date title="$myconfig{dateformat}">|.&js_calendar("main", "startdateto").qq|</td>
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

  $form->{reportcode} = $form->{type};
  $form->{reportcode} ||= 'jc';

  JC->jcitems_links(\%myconfig, \%$form);
  
  if (@{ $form->{all_project} }) {
    $form->{selectprojectnumber} = "\n";
    $form->{projectnumber} ||= "";
    for (@{ $form->{all_project} }) { $form->{selectprojectnumber} .= qq|$_->{projectnumber}--$_->{id}\n| }
  }
  
  if ($form->{project} eq 'job') {
    
    $projectnumberlabel = $locale->text('Job Number');
    $projectdescriptionlabel = $locale->text('Job Name');
    if ($form->{type}) {
      if ($form->{type} eq 'timecard') {
	$partnumberlabel = $locale->text('Labor Code');
      } else {
	$partnumberlabel = $locale->text('Part Number');
      }
    } else {
      $partnumberlabel = $locale->text('Part Number')."/".$locale->text('Labor Code');
    }

  } elsif ($form->{project} eq 'project') {
    
    $projectnumberlabel = $locale->text('Project Number');
    $projectdescriptionlabel = $locale->text('Project Name');
    $partnumberlabel = $locale->text('Service Code');
    
  } else {
    
    $projectnumberlabel = $locale->text('Project Number')."/".$locale->text('Job Number');
    $partnumberlabel = $locale->text('Service Code')."/".$locale->text('Labor Code');
    $projectdescriptionlabel = $locale->text('Project Name')."/".$locale->text('Job Name');
    
  }
  
  if ($form->{selectprojectnumber}) {
    $projectnumber = qq|
      <tr>
	<th align=right nowrap>$projectnumberlabel</th>
	<td colspan=3><select name=projectnumber>|.$form->select_option($form->{selectprojectnumber}, $form->{"projectnumber"}, 1)
	.qq|</select></td>
      </tr>
|;
  }
  
  $partnumber = qq|
	<tr>
	  <th align=right nowrap>$partnumberlabel</th>
	  <td colspan=3><input name=partnumber></td>
        </tr>
|;

 
  if ($form->{type} eq 'timecard') {
    # employees
    if (@{ $form->{all_employee} }) {
      $form->{selectemployee} = "\n";
      $form->{employee} ||= "";
      for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }
    } else {
      $form->error($locale->text('No Employees on file!'));
    }
    
    $employee = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Employee').qq|</th>
	  <td colspan=3><select name=employee>|
	  .$form->select_option($form->{selectemployee}, $form->{employee}, 1)
	  .qq|
	  </select></td>
        </tr>
|;

    $l_time = 1;
    
  }

  if (@{ $form->{all_report} }) {
    $form->{selectreportform} = "\n";
    for (@{ $form->{all_report} }) { $form->{selectreportform} .= qq|$_->{reportdescription}--$_->{reportid}\n| }

    $reportform = qq|
      <tr>
        <th align=right>|.$locale->text('Report').qq|</th>
	<td>
	  <select name=report onChange="ChangeReport();">|.$form->select_option($form->{selectreportform}, undef, 1)
	  .qq|</select>
        </td>
      </tr>
|;
  }
  
  
  $form->{sort} = "transdate";
  
  for (qw(open transdate projectnumber projectdescription id partnumber description notes qty)) { $form->{"l_$_"} = "checked" }
  
  @checked = qw(open closed l_subtotal);
  @input = qw(projectnumber partnumber employee description notes startdatefrom startdateto month year sort direction reportlogin);
  %radio = ( interval => { 0 => 0, 1 => 1, 3 => 2, 12 => 3 },
           );

  $i = 1;
  $includeinreport{transdate} = { ndx => $i++, sort => transdate, checkbox => 1, html => qq|<input name="l_transdate" class=checkbox type=checkbox value=Y $form->{l_transdate}>|, label => $locale->text('Date') };
  $includeinreport{projectnumber} = { ndx => $i++, sort => projectnumber, checkbox => 1, html => qq|<input name="l_projectnumber" class=checkbox type=checkbox value=Y $form->{l_projectnumber}>|, label => $projectnumberlabel };
  $includeinreport{projectdescription} = { ndx => $i++, sort => projectdescription, checkbox => 1, html => qq|<input name="l_projectdescription" class=checkbox type=checkbox value=Y $form->{l_projectdescription}>|, label => $projectdescriptionlabel };
  $includeinreport{id} = { ndx => $i++, sort => id, checkbox => 1, html => qq|<input name="l_id" class=checkbox type=checkbox value=Y $form->{l_id}>|, label => $locale->text('ID') };
  $includeinreport{partnumber} = { ndx => $i++, sort => partnumber, checkbox => 1, html => qq|<input name="l_partnumber" class=checkbox type=checkbox value=Y $form->{l_partnumber}>|, label => $partnumberlabel };
  $includeinreport{description} = { ndx => $i++, sort => description, checkbox => 1, html => qq|<input name="l_description" class=checkbox type=checkbox value=Y $form->{l_description}>|, label => $locale->text('Description') };
  $includeinreport{notes} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_notes" class=checkbox type=checkbox value=Y $form->{l_notes}>|, label => $locale->text('Notes') };
  $includeinreport{qty} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_qty" class=checkbox type=checkbox value=Y $form->{l_qty}>|, label => $locale->text('Qty') };
  $includeinreport{time} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_time" class=checkbox type=checkbox value=Y $form->{l_time}>|, label => $locale->text('Time') };
  $includeinreport{allocated} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_allocated" class=checkbox type=checkbox value=Y $form->{l_allocated}>|, label => $locale->text('Allocated') };


  delete $includeinreport{time} if ! $l_time;
  
  @a = ();
  for (sort { $includeinreport{$a}->{ndx} <=> $includeinreport{$b}->{ndx} } keys %includeinreport) {
    push @checked, "l_$_";
    if ($includeinreport{$_}->{checkbox}) {
      push @a, "$includeinreport{$_}->{html} $includeinreport{$_}->{label}";
    }
  }

  $type = $form->{type} || "stcard";
  $form->helpref("search_$type", $myconfig{countrycode});
  
  $form->header;

  &calendar;
  
  &change_report(\%$form, \@input, \@checked, \%radio);
  
  print qq|
<body>

<form method=post name=main action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        $reportform
        $projectnumber
	$partnumber
	$employee
	
	<tr>
	  <th align=right nowrap>|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Notes').qq|</th>
	  <td><input name=notes size=40></td>
	</tr>
	
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
    print qq|<tr>\n|;
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

  $form->hide_form(qw(path login db nextsub reportcode reportlogin project type sort direction));

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


sub display_form {

  &{ "$form->{type}_header" };
  &{ "$form->{type}_footer" };

}


sub form_header {

  &{ "$form->{type}_header" };

}


sub form_footer {

  &{ "form->{type}_footer" };

}


sub prepare_timecard {

  $form->{formname} = "timecard";
  $form->{format} ||= $myconfig{outputformat};

  if ($myconfig{printer}) {
    $form->{format} ||= "ps";
  }
  $form->{media} ||= $myconfig{printer};
  
  JC->retrieve_card(\%myconfig, \%$form);

  $form->{selectprinter} = "";
  for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" }
  chop $form->{selectprinter};
  
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

  if ($form->{checkedout} && ($form->{checkedin} > $form->{checkedout})) {
    $form->{checkedout} = 86400 - ($form->{checkedin} - $form->{checkedout});
    $form->{checkedin} = 0;
  }

  $form->{clocked} = ($form->{checkedout} - $form->{checkedin}) / 3600;
  if ($form->{clocked}) {
    $form->{oldnoncharge} = $form->{clocked} - $form->{qty};
  }
  $form->{oldqty} = $form->{qty};
  
  $form->{noncharge} = $form->format_amount(\%myconfig, $form->{clocked} - $form->{qty}, 4) if $form->{checkedin} != $form->{checkedout};
  $form->{clocked} = $form->format_amount(\%myconfig, $form->{clocked}, 4);
  
  $form->{amount} = $form->{sellprice} * $form->{qty};
  for (qw(sellprice amount)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $form->{precision}) }
  $form->{qty} = $form->format_amount(\%myconfig, $form->{qty}, 4);
  $form->{allocated} = $form->format_amount(\%myconfig, $form->{allocated}, 4);

  $form->{employee} .= "--$form->{employee_id}";
  $form->{projectnumber} .= "--$form->{project_id}" unless $form->{projectnumber} =~ /--/;
  $form->{oldpartnumber} = $form->{partnumber};
  $form->{oldproject_id} = $form->{project_id};

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    $form->{language_code} ||= "";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }

  &jcitems_links;

  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum(\%myconfig, $form->{transdate}) <= $form->{closedto});
  
  $form->{readonly} = 1 if $myconfig{acs} =~ /Production--Add Time Card/;

  if ($form->{income_accno_id}) {
    $form->{locked} = 1 if $form->{production} == $form->{completed};
  }

  for (qw(formname language printer)) { $form->{"select$_"} = $form->escape($form->{"select$_"}, 1) }
  
  # references
  &all_references;

}


sub timecard_header {
  
  $reference_documents = &references;

  for (qw(transdate checkedin checkedout partnumber)) { $form->{"old$_"} = $form->{$_} }

  if (($rows = $form->numtextrows($form->{description}, 50, 8)) < 2) {
    $rows = 2;
  }
  
  $description = qq|<textarea name=description rows=$rows cols=46 wrap=soft>$form->{description}</textarea>|;
  
  $projectlabel = $locale->text('Project/Job Number');
  $laborlabel = $locale->text('Service/Labor Code');
 
  if ($form->{project} eq 'job') {
    $projectlabel = $locale->text('Job Number');
    $laborlabel = $locale->text('Labor Code');
    $chargeoutlabel = $locale->text('Amount');
  }
  
  if ($form->{project} eq 'project') {
    $projectlabel = $locale->text('Project Number');
    $laborlabel = $locale->text('Service Code');
    $chargeoutlabel = $locale->text('Chargeout Rate');
  }


  if ($form->{type} eq 'timecard') {
    $rate = qq|
	    <tr>
	      <th align=right nowrap>$chargeoutlabel</th>
	      <td><input name=sellprice class="inputright" size=10 value=$form->{sellprice}></td>|;
    $rate .= qq|<th align=right nowrap>|.$locale->text('Total').qq|</th>
	      <td>$form->{amount}</td>| if $form->{amount};
    $rate .= qq|
	    </tr>
	    <tr>
	      <th align=right nowrap>|.$locale->text('Allocated').qq|</th>
	      <td><input name=allocated class="inputright" size=10 value=$form->{allocated}></td>
	    </tr>
|;
  } else {
    $rate = qq|
	    <tr>
	      <th align=right nowrap>$chargeoutlabel</th>
	      <td><input name=sellprice class="inputright" size=10 value=$form->{sellprice}></td>|;
    $rate .= qq|<th align=right nowrap>|.$locale->text('Total').qq|</th>
	      <td>$form->{amount}</td>| if $form->{amount};
    $rate .= qq|
	    </tr>
	    <tr>
	      <th align=right nowrap>|.$locale->text('Allocated').qq|</th>
	      <td>$form->{allocated}</td>
	    </tr>|
	    .$form->hide_form(qw(allocated));
  }
  
  $charge = qq|<input name=qty class="inputright" size=10 value=$form->{qty}>|;
  
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

  $lookup = qq|
          <a href="ic.pl?login=$form->{login}&path=$form->{path}&action=edit&id=$form->{"parts_id"}" target=_blank>?</a>| if $form->{"parts_id"};

  $form->helpref($form->{type}, $myconfig{countrycode});

  $form->{action} = "update";
 
  $form->header;
  
  &calendar;
  
  print qq|
<body>

<form method="post" name="main" action="$form->{script}">
|;

  $form->hide_form(map { "select$_" } qw(projectnumber employee formname language printer));
  $form->hide_form(qw(id type printed queued title closedto locked project pricematrix parts_id precision orphaned action));
  $form->hide_form(map { "old$_" } qw(transdate checkedin checkedout partnumber qty noncharge project_id));


  print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Employee').qq| <font color=red>*</font></th>
	  <td colspan=3><select name=employee>|
	  .$form->select_option($form->{selectemployee}, $form->{employee}, 1)
	  .qq|</select>
	  </td>
	</tr>
	<tr>
	  <th align=right nowrap>$projectlabel <font color=red>*</font></th>
	  <td><select name=projectnumber onChange="javascript:document.main.submit()">|
	  .$form->select_option($form->{selectprojectnumber}, $form->{projectnumber}, 1)
	  .qq|</select>
	  </td>
	  <td colspan=2>$form->{projectdescription}</td>|
	  .$form->hide_form(qw(projectdescription))
	  .qq|
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Date worked').qq| <font color=red>*</font></th>
	  <td nowrap><input name=transdate size=11 class=date title="$myconfig{dateformat}" value=$form->{transdate}>|.&js_calendar("main", "transdate").qq|</td>
	</tr>
	<tr>
	  <th align=right nowrap>$laborlabel <font color=red>*</font></th>
	  <td><input name=partnumber value="|.$form->quote($form->{partnumber})
	  .qq|">
          $lookup
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
		<td><input name=inhour class="inputright" title="hh" size=3 maxlength=2 value=$form->{inhour}></td>
		<td><input name=inmin class="inputright" title="mm" size=3 maxlength=2 value=$form->{inmin}></td>
		<td><input name=insec class="inputright" title="ss" size=3 maxlength=2 value=$form->{insec}></td>
	      </tr>
	    </table>
	  </td>
	  <th align=right nowrap>|.$locale->text('Time Out').qq|</th>
	  <td>
	    <table>
	      <tr>
		<td><input name=outhour class="inputright" title="hh" size=3 maxlength=2 value=$form->{outhour}></td>
		<td><input name=outmin class="inputright" title="mm" size=3 maxlength=2 value=$form->{outmin}></td>
		<td><input name=outsec class="inputright" title="ss" size=3 maxlength=2 value=$form->{outsec}></td>
	      </tr>
	    </table>
	  </td>
	</tr>
	$clocked
	<tr>
	  <th align=right nowrap>|.$locale->text('Non-chargeable').qq|</th>
	  <td><input name=noncharge class="inputright" size=10 value=$form->{noncharge}></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Chargeable').qq|</th>
	  <td>$charge</td>
	</tr>
	$rate
	$notes
	<tr>
	$reference_documents
	</tr>
|;

}


sub timecard_footer {

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

  %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
             'Check In' => { ndx => 2, key => 'C', value => $locale->text('Check In') },
             'Check Out' => { ndx => 2, key => 'C', value => $locale->text('Check Out') },
             'Preview' => { ndx => 3, key => 'V', value => $locale->text('Preview') },
             'Print' => { ndx => 4, key => 'P', value => $locale->text('Print') },
	     'Save' => { ndx => 5, key => 'S', value => $locale->text('Save') },
	     'Print and Save' => { ndx => 6, key => 'R', value => $locale->text('Print and Save') },
	     'Save as new' => { ndx => 7, key => 'N', value => $locale->text('Save as new') },
	     'Print and Save as new' => { ndx => 8, key => 'W', value => $locale->text('Print and Save as new') },
	     
	     'Delete' => { ndx => 16, key => 'D', value => $locale->text('Delete') },
	    );

    %a = ();

    if ($form->{inhour} + $form->{inmin} + $form->{insec}) {
      if (! ($form->{outhour} + $form->{outmin} + $form->{outsec}) ) {
	$a{'Check Out'} = 1;
      }
    } else {
      $a{'Check In'} = 1;
    }

    if ($form->{id}) {
    
      if (!$form->{locked}) {
	for ('Update', 'Print', 'Save', 'Save as new') { $a{$_} = 1 }
	
	if ($latex) {
	  for ('Preview', 'Print and Save', 'Print and Save as new') { $a{$_} = 1 }
	}

	if ($form->{orphaned}) {
	  $a{'Delete'} = 1;
	}
	
      }

    } else {

      if ($transdate > $form->{closedto}) {
	
	for ('Update', 'Print', 'Save') { $a{$_} = 1 }

	if ($latex) {
	  for ('Print and Save', 'Preview') { $a{$_}  = 1 }
	}

      }
    }
  }

  for (keys %button) { delete $button{$_} if ! $a{$_} }

  $form->print_button(\%button);
  
  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  $form->hide_form(qw(reference_rows callback path login));
  
  print qq|

</form>

</body>
</html>
|;

}


sub check_in {

  ($form->{insec},$form->{inmin},$form->{inhour}) = localtime;
  &update;
  
}

sub check_out {

  ($form->{outsec},$form->{outmin},$form->{outhour}) = localtime;
  &update;
  
}


sub prepare_storescard {

  $form->{formname} = "storescard";
  $form->{format} ||= $myconfig{outputformat};
  $form->{media} = $myconfig{printer};

  if ($myconfig{printer}) {
    $form->{format} ||= "ps";
  }

  JC->retrieve_card(\%myconfig, \%$form);

  $form->{selectprinter} = "";
  for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" }
  chop $form->{selectprinter};
  
  $form->{selectformname} = qq|storescard--|.$locale->text('Stores Card');
  
  $form->{amount} = $form->{sellprice} * $form->{qty};
  for (qw(sellprice amount)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $form->{precision}) }
  $form->{qty} = $form->format_amount(\%myconfig, $form->{qty});

  $form->{employee} .= "--$form->{employee_id}";
  $form->{projectnumber} .= "--$form->{project_id}" unless $form->{projectnumber} =~ /--/;
  $form->{oldpartnumber} = $form->{partnumber};
  $form->{oldproject_id} = $form->{project_id};

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    $form->{language_code} ||= "";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }

  &jcitems_links;

  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum(\%myconfig, $form->{transdate}) <= $form->{closedto});
  
  $form->{readonly} = 1 if $myconfig{acs} =~ /Production--Add Time Card/;

  if ($form->{income_accno_id}) {
    $form->{locked} = 1 if $form->{production} == $form->{completed};
  }

  for (qw(formname language printer)) { $form->{"select$_"} = $form->escape($form->{"select$_"}, 1) }

  # references
  &all_references;

}


sub storescard_header {

  $reference_documents = &references;

  for (qw(transdate partnumber)) { $form->{"old$_"} = $form->{$_} }

  if (($rows = $form->numtextrows($form->{description}, 50, 8)) < 2) {
    $rows = 2;
  }
  
  $description = qq|<textarea name=description rows=$rows cols=46 wrap=soft>$form->{description}</textarea>|;

  $charge = qq|<tr>
                 <th align=right nowrap>|.$locale->text('Amount').qq|</th>
                 <td><input name=sellprice class="inputright" size=10 value=$form->{sellprice}></td>|;
    $charge .= qq|<th align=right nowrap>|.$locale->text('Total').qq|</th>
               <td>$form->{amount}</td>| if $form->{amount};
    $charge .= qq|
	       </tr>|;

  $lookup = qq|
          <a href="ic.pl?login=$form->{login}&path=$form->{path}&action=edit&id=$form->{"parts_id"}" target=_blank>?</a>| if $form->{"parts_id"};

  $form->helpref("storescard", $myconfig{countrycode});

  $form->{action} = "update";

  delete $form->{allocated} unless $form->{allocated};

  $form->header;

  &calendar;

  print qq|
<body>

<form method="post" name="main" action="$form->{script}">
|;

  $form->hide_form(map { "select$_" } qw(projectnumber formname language printer));
  $form->hide_form(qw(id type printed queued title closedto locked project parts_id employee precision orphaned action));
  $form->hide_form(map { "old$_" } qw(transdate partnumber));

  print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right nowrap>|.$locale->text('Job Number').qq| <font color=red>*</font></th>
	  <td colspan=2><select name=projectnumber onChange="javascript:document.main.submit()">|
	  .$form->select_option($form->{selectprojectnumber}, $form->{projectnumber}, 1)
	  .qq|</select>
	  </td>
	  <td>$form->{projectdescription}</td>|
	  .$form->hide_form(qw(projectdescription))
	  .qq|
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Date').qq| <font color=red>*</font></th>
	  <td colspan=3><input name=transdate size=11 class=date title="$myconfig{dateformat}" value=$form->{transdate}>|.&js_calendar("main", "transdate").qq|</td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Part Number').qq| <font color=red>*</font></th>
	  <td colspan=3><input name=partnumber value="|.$form->quote($form->{partnumber}) .qq|"> 
	  $lookup
	  </td>
	</tr>
	<tr valign=top>
	  <th align=right nowrap>|.$locale->text('Description').qq|</th>
	  <td colspan=3>$description</td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Qty').qq|</th>
	  <td><input name=qty class="inputright" size=6 value=$form->{qty}></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Allocated').qq|</th>
	  <td><input name=allocated class="inputright" size=6 value=$form->{allocated}></td>
	</tr>
	$charge
	<tr>
	$reference_documents
	</tr>
|;

}


sub storescard_footer {

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

  if (! $form->{readonly}) {

    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
               'Preview' => { ndx => 2, key => 'V', value => $locale->text('Preview') },
               'Print' => { ndx => 3, key => 'P', value => $locale->text('Print') },
	       'Save' => { ndx => 4, key => 'S', value => $locale->text('Save') },
	       'Print and Save' => { ndx => 6, key => 'R', value => $locale->text('Print and Save') },
	       'Save as new' => { ndx => 7, key => 'N', value => $locale->text('Save as new') },
	       'Print and Save as new' => { ndx => 8, key => 'W', value => $locale->text('Print and Save as new') },
	       'Delete' => { ndx => 16, key => 'D', value => $locale->text('Delete') },
	      );
    
    %a = ();
    
    if ($form->{id}) {
      
      if (!$form->{locked}) {
	for ('Update', 'Print', 'Save', 'Save as new') { $a{$_} = 1 }
	if ($latex) {
	  for ('Preview', 'Print and Save', 'Print and Save as new') { $a{$_} = 1 }
	}
	if ($form->{orphaned}) {
	  $a{'Delete'} = 1;
	}
      }
      
    } else {

      if ($transdate > $form->{closedto}) {
	for ('Update', 'Print', 'Save') { $a{$_} = 1 }

	if ($latex) {
	  for ('Preview', 'Print and Save') { $a{$_} = 1 }
	}
      }
    }

    for (keys %button) { delete $button{$_} if ! $a{$_} }

    $form->print_button(\%button);
    
  }

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  $form->hide_form(qw(reference_rows callback path login));
  
  print qq|

</form>

</body>
</html>
|;

}



sub update {

  (undef, $form->{project_id}) = split /--/, $form->{projectnumber};

  for (qw(transdate project_id)) {
    if ($form->{"old$_"} ne $form->{$_}) {
      JC->jcitems_links(\%myconfig, \%$form);
      &jcitems_links;
      last;
    }
  }

  if ($form->{oldpartnumber} ne $form->{partnumber}) {
    $form->error($locale->text('Project/Job Number missing!')) if ! $form->{project};
    if ($form->{project} eq 'project') {
      $form->error($locale->text('Project Number missing!')) if ! $form->{projectnumber};
    }
    if ($form->{project} eq 'job') {
      $form->error($locale->text('Job Number missing!')) if ! $form->{projectnumber}; 
    }

    JC->retrieve_item(\%myconfig, \%$form);

    $rows = scalar @{ $form->{item_list} };

    if ($rows) {

      if ($rows > 1) {
	&select_item;
	exit;
      } else {
	for (keys %{ $form->{item_list}[0] }) { $form->{$_} = $form->{item_list}[0]{$_} }
	
	($dec) = ($form->{sellprice} =~ /\.(\d+)/);
	$dec = length $dec;
	$decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};
	
	$form->{sellprice} = $form->format_amount(\%myconfig, $form->{sellprice}, $decimalplaces);
      }

    } else {
      &new_item;
      exit;
    }
  }

  if ($form->{type} eq 'timecard') {

    # time clocked
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

    if ($form->{checkedin} > $form->{checkedout}) {
      $form->{checkedout} = 86400 - ($form->{checkedin} - $form->{checkedout});
      $form->{checkedin} = 0;
    }

    $form->{clocked} = ($form->{checkedout} - $form->{checkedin}) / 3600;

    for (qw(sellprice qty noncharge allocated)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
    
    $checkmatrix = 1 if $form->{oldqty} != $form->{qty};
    
    if (($form->{oldcheckedin} != $form->{checkedin}) || ($form->{oldcheckedout} != $form->{checkedout})) {
      $checkmatrix = 1;
      $form->{oldqty} = $form->{qty} = $form->{clocked} - $form->{noncharge};
      $form->{oldnoncharge} = $form->{noncharge};
    }

    if (($form->{qty} != $form->{oldqty}) && $form->{clocked}) {
      $form->{oldnoncharge} = $form->{noncharge} = $form->{clocked} - $form->{qty};
      $checkmatrix = 1;
    }

    if (($form->{oldnoncharge} != $form->{noncharge}) && $form->{clocked}) {
      $form->{oldqty} = $form->{qty} = $form->{clocked} - $form->{noncharge};
      $checkmatrix = 1;
    }
    
    if ($checkmatrix) {
      @a = split / /, $form->{pricematrix};
      if (scalar @a > 2) {
	for (@a) {
	  ($q, $p) = split /:/, $_;
	  if (($p * 1) && ($form->{qty} >= ($q * 1))) {
	    $form->{sellprice} = $p;
	  }
	}
      }
    }
      
    $form->{amount} = $form->{sellprice} * $form->{qty};
	
    $form->{clocked} = $form->format_amount(\%myconfig, $form->{clocked}, 4);
    for (qw(sellprice amount)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $form->{precision}) }
    for (qw(qty noncharge)) {
      $form->{"old$_"} = $form->{$_};
      $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, 4);
    }
    
  } else {
    
    for (qw(sellprice qty allocated)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }

    if ($form->{oldqty} != $form->{qty}) {
      @a = split / /, $form->{pricematrix};
      if (scalar @a > 2) {
	for (@a) {
	  ($q, $p) = split /:/, $_;
	  if (($p * 1) && ($form->{qty} >= ($q * 1))) {
	    $form->{sellprice} = $p;
	  }
	}
      }
    }
    
    $form->{amount} = $form->{sellprice} * $form->{qty};
    for (qw(sellprice amount)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $form->{precision}) }
    $form->{oldqty} = $form->{qty};
    $form->{qty} = $form->format_amount(\%myconfig, $form->{qty});
 
  }

  $form->{allocated} = $form->format_amount(\%myconfig, $form->{allocated});
    
  &display_form;

}


sub save {

  if ($form->{save_report}) {
    &do_save_report;
    exit;
  }

  $form->isblank("transdate", $locale->text('Date missing!'));

  if ($form->{project} eq 'project') {
    $form->isblank("projectnumber", $locale->text('Project Number missing!'));
    $form->isblank("partnumber", $locale->text('Service Code missing!'));
  } else {
    $form->isblank("projectnumber", $locale->text('Job Number missing!'));
    $form->isblank("partnumber", $locale->text('Labor Code missing!'));
  }

  $transdate = $form->datetonum(\%myconfig, $form->{transdate});
  
  $msg = ($form->{type} eq 'timecard') ? $locale->text('Cannot save time card for a closed period!') : $locale->text('Cannot save stores card for a closed period!');
  $form->error($msg) if ($transdate <= $form->{closedto});

  if (! $form->{resave}) {
    if ($form->{id}) {
      &resave;
      exit;
    }
  }

  $form->{userspath} = $userspath;
  
  $rc = JC->save(\%myconfig, \%$form);
  
  if ($form->{type} eq 'timecard') {
    $form->error($locale->text('Cannot change time card for a completed job!')) if ($rc == -1);
    $form->error($locale->text('Cannot add time card for a completed job!')) if ($rc == -2);
    
    if ($rc) {
      $form->redirect($locale->text('Time Card saved!'));
    } else {
      $form->error($locale->text('Cannot save time card!'));
    }
    
  } else {
    $form->error($locale->text('Cannot change stores card for a completed job!')) if ($rc == -1);
    $form->error($locale->text('Cannot add stores card for a completed job!')) if ($rc == -2);

    if ($rc) {
      $form->redirect($locale->text('Stores Card saved!'));
    } else {
      $form->error($locale->text('Cannot save stores card!'));
    }
  }
  
}


sub save_as_new {

  if ($form->{save_report}) {
    &save_report_as_new;
    exit;
  }

  delete $form->{id};
  &save;

}


sub print_and_save_as_new {

  delete $form->{id};
  &print_and_save;

}


sub resave {

  if ($form->{print_and_save}) {
    $form->{nextsub} = "print_and_save";
    $msg = $locale->text('You are printing and saving an existing transaction!');
  } else {
    $form->{nextsub} = "save";
    $msg = $locale->text('You are saving an existing transaction!');
  }
  
  $form->{resave} = 1;
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

|;

  delete $form->{action};

  $form->hide_form;

  print qq|
<h2 class=confirm>|.$locale->text('Warning!').qq|</h2>

<h4>$msg</h4>

<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub print_and_save {

  $form->error($locale->text('Select postscript or PDF!')) if $form->{format} !~ /(ps|pdf)/;
  $form->error($locale->text('Select a Printer!')) if $form->{media} eq 'screen';

  if (! $form->{resave}) {
    if ($form->{id}) {
      $form->{print_and_save} = 1;
      &resave;
      exit;
    }
  }

  $oldform = new Form;
  $form->{display_form} = "save";
  for (keys %$form) { $oldform->{$_} = $form->{$_} }

  &{ "print_$form->{formname}" }($oldform);

}


sub delete_timecard {

  $form->header;

  $employee = $form->{employee};
  $employee =~ s/--.*//g;
  $projectnumber = $form->{projectnumber};
  $projectnumber =~ s/--.*//g;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  delete $form->{action};

  $form->hide_form;

  print qq|
<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>

<h4>|.$locale->text('Are you sure you want to delete time card for').qq|
<p>$form->{transdate}
<br>$employee
<br>$projectnumber
</h4>

<p>
<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>
|;

}


sub delete_storescard {

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  delete $form->{action};

  $form->hide_form;

  print qq|
<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>

<h4>|.$locale->text('Are you sure you want to delete stores card').qq|
</h4>

<p>
<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>
|;

}



sub delete {
  
  if ($form->{save_report}) {
    &delete_report;
    exit;
  }
  
  &{ "delete_$form->{type}" };

}

sub yes { &{ "yes_delete_$form->{type}" } };


sub yes_delete_timecard {
  
  if (JC->delete(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Time Card deleted!'));
  } else {
    $form->error($locale->text('Cannot delete time card!'));
  }

}


sub yes_delete_storescard {

  if (JC->delete(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Stores Card deleted!'));
  } else {
    $form->error($locale->text('Cannot delete stores card!'));
  }

}


sub list_cards {

  JC->jcitems(\%myconfig, \%$form);

  if (! exists $form->{title}) {
    $form->{title} = $locale->text('Time and Stores Cards');
    $form->{title} = $locale->text('Stores Cards') if $form->{type} eq 'storescard';
    $form->{title} = $locale->text('Time Cards') if $form->{type} eq 'timecard';
    
    $form->{title} .= " / $form->{company}";
  }

  $form->{reportcode} = $form->{type};
  $form->{reportcode} ||= 'jc';

  @a = qw(type direction oldsort path login project open closed reportcode reportlogin);
  $href = "$form->{script}?action=list_cards";
  for (@a) { $href .= "&$_=$form->{$_}" }

  for (qw(title report)) { $href .= "&$_=".$form->escape($form->{$_}) }

  $form->sort_order();

  $callback = "$form->{script}?action=list_cards";
  for (@a) { $callback .= "&$_=$form->{$_}" }

  @columns = $form->sort_columns(qw(transdate id projectnumber projectname partnumber description notes));

  @column_index = ();
  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }

  foreach $item (qw(subtotal qty allocated sellprice)) {
    if ($form->{"l_$item"} eq "Y") {
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }

  for (qw(title report)) { $callback .= "&$_=".$form->escape($form->{$_},1) }
  
  if (@{ $form->{transactions} }) {
    $sameitem = $form->{transactions}->[0]->{$form->{sort}};
    if ($form->{type} eq 'timecard') {
      $sameemployeenumber = $form->{transactions}->[0]->{employeenumber};
      $employee = $form->{transactions}->[0]->{employee};
      $sameweek = $form->{transactions}->[0]->{workweek};
    }
  }

  
  if ($form->{type} eq 'timecard') {
    push @column_index, (qw(1 2 3 4 5 6 7)) if ($form->{l_qty} || $form->{l_time});
  } else {
    push @column_index, (qw(qty sellprice)) if $form->{l_qty};
  }
  
  push @column_index, "allocated" if $form->{l_allocated};
  
  if ($form->{project} eq 'job') {
    $joblabel = $locale->text('Job Number');
    if ($form->{type} eq 'timecard') {
      $laborlabel = $locale->text('Labor Code');
    } elsif ($form->{type} eq 'storescard') {
      $laborlabel = $locale->text('Part Number');
    } else {
      $laborlabel = $locale->text('Part Number')."/".$locale->text('Labor Code');
    }
    $desclabel = $locale->text('Job Name');
  } elsif ($form->{project} eq 'project') {
    $joblabel = $locale->text('Project Number');
    $laborlabel = $locale->text('Service Code');
    $desclabel = $locale->text('Project Name');
  } else {
    $joblabel = $locale->text('Project Number')."/".$locale->text('Job Number');
    $laborlabel = $locale->text('Service Code')."/".$locale->text('Labor Code');
    $desclabel = $locale->text('Project Description')."/".$locale->text('Job Name');
  }
  
  if ($form->{projectnumber}) {
    $callback .= "&projectnumber=".$form->escape($form->{projectnumber},1);
    $href .= "&projectnumber=".$form->escape($form->{projectnumber});
    ($var) = split /--/, $form->{projectnumber};
    $option .= "\n<br>" if ($option);
    $option .= "$joblabel : $var";
    @column_index = grep !/(projectnumber|projectdescription)/, @column_index;
    $option .= "\n<br>$desclabel : ".$form->{transactions}->[0]->{projectdescription};
  }
  if ($form->{partnumber}) {
    $callback .= "&partnumber=".$form->escape($form->{partnumber},1);
    $href .= "&partnumber=".$form->escape($form->{partnumber});
    $option .= "\n<br>" if ($option);
    $option .= "$laborlabel : $form->{partnumber}";
  }
  if ($form->{employee}) {
    $callback .= "&employee=".$form->escape($form->{employee},1);
    $href .= "&employee=".$form->escape($form->{employee});
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $href .= "&description=".$form->escape($form->{description});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Description')." : $form->{description}";
  }
  if ($form->{notes}) {
    $callback .= "&notes=".$form->escape($form->{notes},1);
    $href .= "&notes=".$form->escape($form->{notes});
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Notes')." : $form->{notes}";
  }

  if ($form->{startdatefrom}) {
    $callback .= "&startdatefrom=$form->{startdatefrom}";
    $href .= "&startdatefrom=$form->{startdatefrom}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{startdatefrom}, 1);
  }
  if ($form->{startdateto}) {
    $callback .= "&startdateto=$form->{startdateto}";
    $href .= "&startdateto=$form->{startdateto}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{startdateto}, 1);
  }
  if ($form->{open}) {
    $callback .= "&open=$form->{open}";
    $href .= "&open=$form->{open}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Open');
  }
  if ($form->{closed}) {
    $callback .= "&closed=$form->{closed}";
    $href .= "&closed=$form->{closed}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Closed');
  }

  if ($form->{type} eq 'timecard') {

    %weekday = ( 1 => $locale->text('Su'),
                 2 => $locale->text('Mo'),
		 3 => $locale->text('Tu'),
		 4 => $locale->text('We'),
		 5 => $locale->text('Th'),
		 6 => $locale->text('Fr'),
		 7 => $locale->text('Sa')
	       );
    
    for (keys %weekday) { $column_header{$_} = "<th class=listheading width=25>$weekday{$_}</th>" }
  }
  
  $column_header{id} = "<th><a class=listheading href=$href&sort=id>".$locale->text('ID')."</a></th>";
  $column_header{transdate} = "<th><a class=listheading href=$href&sort=transdate>".$locale->text('Date')."</a></th>";
  $column_header{description} = "<th><a class=listheading href=$href&sort=description>".$locale->text('Description')."</th>";
  $column_header{projectnumber} = "<th><a class=listheading href=$href&sort=projectnumber>$joblabel</a></th>";
  $column_header{partnumber} = "<th><a class=listheading href=$href&sort=partnumber>$laborlabel</a></th>";
  $column_header{projectdescription} = "<th><a class=listheading href=$href&sort=projectdescription>$desclabel</a></th>";
  $column_header{notes} = "<th class=listheading>".$locale->text('Notes')."</th>";
  $column_header{qty} = "<th class=listheading>".$locale->text('Qty')."</th>";
  $column_header{allocated} = "<th class=listheading>".$locale->text('Allocated')."</th>";
  $column_header{sellprice} = "<th class=listheading>".$locale->text('Amount')."</th>";

  
  $form->helpref("list_$form->{type}", $myconfig{countrycode});
  
  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th colspan=2 align=left>
	    $employee
	  </th>
	  <th align=left>
	    $sameemployeenumber
	  </th>
        <tr class=listheading>
|;

  for (@column_index) { print "\n$column_header{$_}" }
  
  print qq|
        </tr>
|;

  # add sort and escape callback, this one we use for the add sub
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);

  %total = ();
  
  foreach $ref (@{ $form->{transactions} }) {

    if ($form->{type} eq 'timecard') {
      if ($sameemployeenumber ne $ref->{employeenumber}) {
	$sameemployeenumber = $ref->{employeenumber};
	$sameweek = $ref->{workweek};

	if ($form->{l_subtotal}) {
	  print qq|
        <tr class=listsubtotal>
|;

	  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

	  $weektotal = 0;
	  for (keys %weekday) {
	    $column_data{$_} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotal{$_}, undef, "&nbsp;")."</th>";
	    $weektotal += $subtotal{$_};
	    $subtotal{$_} = 0;
	  }
      
	  $column_data{$form->{sort}} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $weektotal, undef, "&nbsp;")."</th>";
	
	  for (@column_index) { print "\n$column_data{$_}" }
	}

	# print total
	print qq|
        <tr class=listtotal>
|;

	for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

	$total = 0;
	for (keys %weekday) {
	  $column_data{$_} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $total{$_}, undef, "&nbsp;")."</th>";
	  $total += $total{$_};
	  $total{$_} = 0;
	}
  
	$column_data{$form->{sort}} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $total, undef, "&nbsp;")."</th>";
	
	for (@column_index) { print "\n$column_data{$_}" }

	print qq|
	<tr height=30 valign=bottom>
	  <th colspan=2 align=left>
	    $ref->{employee}
	  </th>
	  <th align=left>
	    $ref->{employeenumber}
	  </th>
        <tr class=listheading>
|;

	for (@column_index) { print "\n$column_header{$_}" }
  
	print qq|
        </tr>
|;

      }
    }

    if ($form->{l_subtotal}) {
      for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
      
      if ($form->{type} eq 'timecard') {
	if ($ref->{workweek} != $sameweek) {
	  $weektotal = 0;
	  for (keys %weekday) {
	    $column_data{$_} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotal{$_}, undef, "&nbsp;")."</th>";
	    $weektotal += $subtotal{$_};
	    $subtotal{$_} = 0
	  }
	  $column_data{$form->{sort}} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $weektotal, undef, "&nbsp;")."</th>";
	  $sameweek = $ref->{workweek};
	  
	  print qq|
	  <tr class=listsubtotal>
|;
	  for (@column_index) { print "\n$column_data{$_}" }
	
	  print qq|
        </tr>
|;
	}

      } else {
	if ($sameitem ne $ref->{$form->{sort}}) {
	  $column_data{qty} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotal{qty}, undef, "&nbsp;")."</th>";
	  $column_data{sellprice} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotal{sellprice}, $form->{precision})."</th>";
	  
	  $sameitem = $ref->{$form->{sort}};
	  $subtotal{qty} = 0;
	  $subtotal{sellprice} = 0;

          print qq|
        <tr class=listsubtotal>
|;
	  for (@column_index) { print "\n$column_data{$_}" }
      
	  print qq|
        </tr>
|;
	}
      }
    }

    for (qw(description notes)) { $ref->{$_} =~ s/\n/<br>/g }
    
    for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
    
    for (keys %weekday) { $column_data{$_} = "<td>&nbsp;</td>" }
    
    $column_data{qty} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{qty}, undef, "&nbsp;")."</td>";
    $column_data{allocated} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{allocated}, undef, "&nbsp;")."</td>";
    $column_data{sellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig,$ref->{qty} * $ref->{sellprice}, $form->{precision})."</td>";
    
    $column_data{$ref->{weekday}} = "<td align=right>";
    $column_data{$ref->{weekday}} .= $form->format_amount(\%myconfig, $ref->{qty}, undef, "&nbsp;") if $form->{l_qty};
    
    if ($form->{l_time}) {
      $column_data{$ref->{weekday}} .= "<br>" if $form->{l_qty};
      $column_data{$ref->{weekday}} .= "$ref->{checkedin}<br>$ref->{checkedout}";
    }
    $column_data{$ref->{weekday}} .= "</td>";
    
    $column_data{id} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&type=$ref->{type}&path=$form->{path}&login=$form->{login}&project=$ref->{project}&callback=$callback>$ref->{id}</a></td>";

    $subtotal{$ref->{weekday}} += $ref->{qty};
    $total{$ref->{weekday}} += $ref->{qty};

    $total{qty} += $ref->{qty};
    $total{sellprice} += $ref->{sellprice} * $ref->{qty};
    $subtotal{qty} += $ref->{qty};
    $subtotal{sellprice} += $ref->{sellprice} * $ref->{qty};

    $j++; $j %= 2;
    print qq|
        <tr class=listrow$j>
|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;
  }

  # print last subtotal
  if ($form->{l_subtotal}) {
    print qq|
        <tr class=listsubtotal>
|;

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    if ($form->{type} eq 'timecard') {
      $weektotal = 0;
      for (keys %weekday) {
	$column_data{$_} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotal{$_}, undef, "&nbsp;")."</th>";
	$weektotal += $subtotal{$_};
      }
    
      $column_data{$form->{sort}} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $weektotal, undef, "&nbsp;")."</th>";
	  
    } else {
      $column_data{qty} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotal{qty}, undef, "&nbsp;")."</th>";
      $column_data{sellprice} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotal{sellprice}, $form->{precision})."</th>";
    }

    for (@column_index) { print "\n$column_data{$_}" }
  }

  # print last total
  print qq|
        <tr class=listtotal>
|;

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  if ($form->{type} eq 'timecard') {
    $total = 0;
    for (keys %weekday) {
      $column_data{$_} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $total{$_}, undef, "&nbsp;")."</th>";
      $total += $total{$_};
      $total{$_} = 0;
    }
    
    $column_data{$form->{sort}} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $total, undef, "&nbsp;")."</th>";
    
  } else {

    $column_data{qty} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $total{qty}, undef, "&nbsp;")."</th>";
    $column_data{sellprice} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $total{sellprice}, $form->{precision})."</th>";

  }

  for (@column_index) { print "\n$column_data{$_}" }


  $i = 1;
  if ($form->{project} eq 'job') {
    if ($form->{type} eq 'timecard') {
      if ($myconfig{acs} !~ /Production--Add Time Card/) {
	$button{'Production--Add Time Card'} = { ndx => $i++, key => 'T',  value => $locale->text('Add Time Card') };
      }
    } elsif ($form->{type} eq 'storescard') {
      if ($myconfig{acs} !~ /Production--Add Stores Card/) {
	$button{'Production--Add Stores Card'} = { ndx => $i++, key => 'T',  value => $locale->text('Add Stores Card') };
      }
    } else {
      $i = 1;
      if ($myconfig{acs} !~ /Production--Add Time Card/) {
	$button{'Production--Add Time Card'} = { ndx => $i++, key => 'T',  value => $locale->text('Add Time Card') };
      }
      
      if ($myconfig{acs} !~ /Production--Add Stores Card/) {
	$button{'Production--Add Stores Card'} = { ndx => $i++, key => 'T',  value => $locale->text('Add Stores Card') };
      }
    }
  } elsif ($form->{project} eq 'project') {
    if ($myconfig{acs} !~ /Projects--Projects/) {
      $button{'Production--Add Time Card'} = { ndx => $i++, key => 'T',  value => $locale->text('Add Time Card') };
    }
  } else {
    if ($myconfig{acs} !~ /Time Cards--Time Cards/) {
      $button{'Production--Add Time Card'} = { ndx => $i++, key => 'T',  value => $locale->text('Add Time Card') };
    }
  }

  
  $button{'Save Report'} = { ndx => $i++, key => 'S', value => $locale->text('Save Report') };

  if (!$form->{admin}) {
    if ($form->{reportid}) {
      $login = $form->{login};
      $login =~ s/\@.*//;
      if ($form->{reportlogin} ne $login) {
	delete $button{'Save Report'};
      }
    }
  }
 
  for (split /;/, $myconfig{acs}) { delete $button{$_} }

  print qq|
        </tr>
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

  if ($form->{year} && $form->{month}) {
    for (qw(startdatefrom startdateto)) { delete $form->{$_} }
  }
  $form->hide_form(qw(projectnumber partnumber employee description notes startdatefrom startdateto month year open closed l_subtotal l_transdate l_projectnumber l_projectdescription l_id l_partnumber l_description l_notes l_qty l_time l_allocated interval));
  
  $form->hide_form(qw(callback path login project report reportcode reportlogin));

  $form->print_button(\%button);
  
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


sub continue { &{ $form->{nextsub} } };

sub add_time_card {

  $form->{type} = "timecard";
  &add;

}


sub add_stores_card {

  $form->{type} = "storescard";
  &add;

}


sub print_options {

  if ($form->{selectlanguage}) {
    $lang = qq|<select name=language_code>|.$form->select_option($form->{selectlanguage}, $form->{language_code}, undef, 1).qq|</select>|;
  }
  
  $type = qq|<select name=formname>|.$form->select_option($form->{selectformname}, $form->{formname}, undef, 1).qq|</select>|;

  $media = qq|<select name=media>
          <option value="screen">|.$locale->text('Screen');

  $form->{selectformat} = qq|<option value="html">html\n|;
  
  if ($form->{selectprinter} && $latex) {
    for (split /\n/, $form->unescape($form->{selectprinter})) { $media .= qq| 
          <option value="$_">$_| }
  }

  if ($latex) {
    $media .= qq|
          <option value="queue">|.$locale->text('Queue');
	  
    $form->{selectformat} .= qq|
            <option value="ps">|.$locale->text('Postscript').qq|
	    <option value="pdf">|.$locale->text('PDF');
  }

  $format = qq|<select name=format>$form->{selectformat}</select>|;
  $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;
  $format .= qq|
  <input type=hidden name=selectformat value="|.$form->escape($form->{selectformat},1).qq|">|;
  $media .= qq|</select>|;
  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

  print qq|
  <table width=100%>
    <tr>
      <td>$type</td>
      <td>$lang</td>
      <td>$format</td>
      <td>$media</td>
      <td align=right width=90%>
  |;

  if ($form->{printed} =~ /$form->{formname}/) {
    print $locale->text('Printed').qq|<br>|;
  }

  if ($form->{queued} =~ /$form->{formname}/) {
    print $locale->text('Queued');
  }

  print qq|
      </td>
    </tr>
  </table>
|;

}


sub print {

  if ($form->{media} !~ /screen/) {
    $form->error($locale->text('Select postscript or PDF!')) if $form->{format} !~ /(ps|pdf)/;
    $oldform = new Form;
    for (keys %$form) { $oldform->{$_} = $form->{$_} }
  }

  &print_form($oldform);

}


sub print_form {
  my ($oldform) = @_;
  
  $display_form = ($form->{display_form}) ? $form->{display_form} : "update";

  $form->{description} =~ s/^\s+//g;
  $form->{projectnumber} =~ s/--.*//;

  if ($form->{type} eq 'timecard') {
    @a = qw(hour min sec);
    foreach $item (qw(in out)) {
      for (@a) { $form->{"$item$_"} = substr(qq|00$form->{"$item$_"}|, -2) }
      $form->{"checked$item"} = qq|$form->{"${item}hour"}:$form->{"${item}min"}:$form->{"${item}sec"}|;
    }
  }
  
  JC->company_defaults(\%myconfig, \%$form);
  
  @a = ();
  push @a, qw(partnumber description projectnumber projectdescription);
  push @a, qw(company address tel fax businessnumber companyemail companywebsite username useremail);
  
  $form->format_string(@a);

  $form->{total} = $form->format_amount(\%myconfig, $form->parse_amount(\%myconfig, $form->{qty}) * $form->parse_amount(\%myconfig, $form->{sellprice}), $form->{precision});

  
  ($form->{employee}, $form->{employee_id}) = split /--/, $form->{employee};

  $form->{templates} = "$templates/$myconfig{templates}";
  $form->{IN} = "$form->{formname}.$form->{format}";

  if ($form->{format} =~ /(ps|pdf)/) {
    $form->{IN} =~ s/$&$/tex/;
  }

  $form->{pre} = "<body bgcolor=#ffffff>\n<pre>" if $form->{format} eq 'txt';

  if ($form->{media} !~ /(screen|queue)/) {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;

    if ($form->{printed} !~ /$form->{formname}/) {
      $form->{printed} .= " $form->{formname}";
      $form->{printed} =~ s/^ //;

      $form->update_status(\%myconfig);
    }

    %audittrail = ( tablename   => jcitems,
                    reference   => $form->{id},
		    formname    => $form->{formname},
		    action      => 'printed',
		    id          => $form->{id} );

    %status = ();
    for (qw(printed queued audittrail)) { $status{$_} = $form->{$_} }

    $status{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);

  }

  if ($form->{media} eq 'queue') {
    %queued = split / /, $form->{queued};

    if ($filename = $queued{$form->{formname}}) {
      $form->{queued} =~ s/$form->{formname} $filename//;
      unlink "$spool/$myconfig{dbname}/$filename";
      $filename =~ s/\..*$//g;
    } else {
      $filename = time;
      $filename .= int rand 10000;
    }

    $filename .= ".$form->{format}";
    $form->{OUT} = ">$spool/$myconfig{dbname}/$filename";
    
    $form->{queued} = "$form->{formname} $filename";
    $form->update_status(\%myconfig);

    %audittrail = ( tablename   => jcitems,
                    reference   => $form->{id},
		    formname    => $form->{formname},
		    action      => 'queued',
		    id          => $form->{id} );

    %status = ();
    for (qw(printed queued audittrail)) { $status{$_} = $form->{$_} }

    $status{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
  }

  $form->parse_template(\%myconfig, $userspath, $dvipdf, $xelatex);

  if ($oldform) {

    for (keys %$oldform) { $form->{$_} = $oldform->{$_} }
    for (qw(printed queued audittrail)) { $form->{$_} = $status{$_} }
    
    &{ "$display_form" };
    
  }
  
}


sub select_item {

  @column_index = qw(ndx partnumber description sellprice);

  $column_data{ndx} = qq|<th class=listheading width=1%>&nbsp;</th>|;
  $column_data{partnumber} = qq|<th class=listheading>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading>|;
  $column_data{sellprice} .= ($form->{project} eq 'project') ? $locale->text('Sell Price') : $locale->text('Cost');
  $column_data{sellprice} .= qq|</th>|;
  
  $helpref = $form->{helpref};
  $form->helpref("select_item", $myconfig{countrycode});
  
  # list items with radio button on a form
  $form->header;

  $title = $locale->text('Select items');

  print qq|
<body>

<form method=post action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$title</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
        </tr>
|;

  my $i = 0;
  foreach $ref (@{ $form->{item_list} }) {
    $i++;

    for (qw(partnumber description)) { $ref->{$_} = $form->quote($ref->{$_}) }

    $column_data{ndx} = qq|<td><input name="ndx" class=radio type=radio value=$i></td>|;
    
    for (qw(partnumber description)) { $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>| }
    
    $column_data{sellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice}, $form->{precision}, "&nbsp;").qq|</td>|;
    
    $j++; $j %= 2;
    print qq|
        <tr class=listrow$j>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

    for (qw(partnumber description sellprice pricematrix parts_id)) {
      print qq|<input type=hidden name="new_${_}_$i" value="|.$form->quote($ref->{$_}).qq|">\n|;
    }
  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input name=lastndx type=hidden value=$i>

|;

  # delete variables
  for (qw(nextsub item_list)) { delete $form->{$_} }

  $form->{action} = "item_selected";
  $form->{helpref} = $helpref;
  
  $form->hide_form;
  
  print qq|
<input type=hidden name=nextsub value=item_selected>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}



sub item_selected {

  for (qw(partnumber description sellprice pricematrix parts_id)) {
    $form->{$_} = $form->{"new_${_}_$form->{ndx}"};
  }

  ($dec) = ($form->{sellprice} =~ /\.(\d+)/);
  $dec = length $dec;
  $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};
  
  # format amounts
  $form->{sellprice} = $form->format_amount(\%myconfig, $form->{sellprice}, $decimalplaces);
  for (qw(partnumber transdate project_id)) { $form->{"old$_"} = $form->{$_} }

  &update;

}


sub new_item {

  # change callback
  $form->{oldcallback} = $form->escape($form->{callback},1);
  $form->{callback} = $form->escape("$form->{script}?action=update",1);

  # delete action
  delete $form->{action};

  # save all other form variables in a previousform variable
  foreach $key (keys %$form) {
    # escape ampersands
    $form->{$key} =~ s/&/%26/g;
    $form->{previousform} .= qq|$key=$form->{$key}&|;
  }
  chop $form->{previousform};

  $form->{callback} = qq|ic.pl?action=add|;
  
  for (qw(path login)) { $form->{callback} .= qq|&$_=$form->{$_}| }
  for (qw(partnumber description previousform)) { $form->{callback} .= qq|&$_=|.$form->escape($form->{$_},1) }
  
  if ($form->{type} eq 'timecard') {
    if ($form->{project} eq 'project') {
      $form->error($locale->text('You are not authorized to add a new item!')) if $myconfig{acs} =~ /Goods \& Services--Add Service/;
      $form->{callback} .= qq|&item=service|;
    } else {
      $form->error($locale->text('You are not authorized to add a new item!')) if $myconfig{acs} =~ /Goods \& Services--Add Labor\/Overhead/;
      $form->{callback} .= qq|&item=labor|;
    }
  } else {
    $form->error($locale->text('You are not authorized to add a new item!')) if $myconfig{acs} =~ /Goods \& Services--Add Part/;
    $form->{callback} .= qq|&item=part|;
  }

  $form->redirect;

}


sub islocked {

  print "<p><font color=red>".$locale->text('Locked by').": $form->{haslock}</font>" if $form->{haslock};

}


sub preview {

  $form->{format} = "pdf";
  $form->{media} = "screen";

  &print;

}

