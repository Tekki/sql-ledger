#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Genereal Ledger
#
#======================================================================


use SL::GL;
use SL::PE;
use SL::VR;

require "$form->{path}/arap.pl";

1;
# end of main


# this is for our long dates
# $locale->text('January')
# $locale->text('February')
# $locale->text('March')
# $locale->text('April')
# $locale->text('May ')
# $locale->text('June')
# $locale->text('July')
# $locale->text('August')
# $locale->text('September')
# $locale->text('October')
# $locale->text('November')
# $locale->text('December')

# this is for our short month
# $locale->text('Jan')
# $locale->text('Feb')
# $locale->text('Mar')
# $locale->text('Apr')
# $locale->text('May')
# $locale->text('Jun')
# $locale->text('Jul')
# $locale->text('Aug')
# $locale->text('Sep')
# $locale->text('Oct')
# $locale->text('Nov')
# $locale->text('Dec')


sub add {
  
  if ($form->{batch}) {
    $form->{title} = $locale->text('Add General Ledger Voucher');
    $form->helpref("gl_voucher", $myconfig{countrycode});
    if ($form->{batchdescription}) {
      $form->{title} .= " / $form->{batchdescription}";
    }
  } else {
    if ($form->{fxadj}) {
      $form->{title} = $locale->text('Add FX Adjustment');
      $form->helpref("fx_adjustment", $myconfig{countrycode});
    } else {
      $form->{title} = $locale->text('Add General Ledger Transaction');
      $form->helpref("gl_transaction", $myconfig{countrycode});
    }
  }
  
  $form->{callback} = "$form->{script}?action=add&fxadj=$form->{fxadj}&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  $transdate = $form->{transdate};
  
  &create_links;

  $form->{transdate} = $transdate if $transdate;

  $form->{rowcount} = ($form->{fxadj}) ? 3 : 9;
  $form->{oldtransdate} = $form->{transdate};
  $form->{focus} = "reference";

  $form->{currency} = $form->{defaultcurrency};

  &display_form(1);
  
}


sub edit {

  &create_links;
 
  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum(\%myconfig, $form->{transdate}) <= $form->{closedto});

  if ($form->{batch}) {
    $form->{title} = $locale->text('Edit General Ledger Voucher');
    $form->helpref("gl_voucher", $myconfig{countrycode});
    if ($form->{batchdescription}) {
      $form->{title} .= " / $form->{batchdescription}";
    }
  } else {
    if ($form->{fxadj}) {
      $form->{title} = $locale->text('Edit FX Adjustment');
      $form->helpref("fx_adjustment", $myconfig{countrycode});
    } else {
      $form->{title} = $locale->text('Edit General Ledger Transaction');
      $form->helpref("gl_transaction", $myconfig{countrycode});
    }
  }
 

  $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate});

  $i = 1;
  foreach $ref (@{ $form->{GL} }) {
    $form->{"accno_$i"} = "$ref->{accno}--$ref->{description}";

    $form->{"projectnumber_$i"} = "$ref->{projectnumber}--$ref->{project_id}" if $ref->{project_id};
    for (qw(fx_transaction source memo cleared)) { $form->{"${_}_$i"} = $ref->{$_} }
    
    if ($ref->{amount} < 0) {
      $form->{totaldebit} -= $ref->{amount};
      $form->{"debit_$i"} = $ref->{amount} * -1;
    } else {
      $form->{totalcredit} += $ref->{amount};
      $form->{"credit_$i"} = $ref->{amount};
    }

    $i++;
  }

  $form->{rowcount} = $i;
  $form->{focus} = "debit_$i";

  # readonly
  if (! $form->{readonly}) {
    if ($form->{batch}) { 
      $form->{readonly} = 1 if $myconfig{acs} =~ /VR--General Ledger/ || $form->{approved};
    } else {
      $form->{readonly} = 1 if $myconfig{acs} =~ /General Ledger--Add Transaction/; 
    }
  }
 
  &form_header;
  &display_rows;
  &form_footer;
  
}



sub create_links {
  
  GL->transaction(\%myconfig, \%$form);

  for (@{ $form->{all_accno} }) { $form->{selectaccno} .= "$_->{accno}--$_->{description}\n" }

  $form->{oldcurrency} = $form->{currency};

  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};

  for (@curr) { $form->{selectcurrency} .= "$_\n" }
 
  # projects
  if (@{ $form->{all_project} }) {
    $form->{selectprojectnumber} = "\n";
    $form->{projectnumber} ||= "";
    for (@{ $form->{all_project} }) { $form->{selectprojectnumber} .= qq|$_->{projectnumber}--$_->{id}\n| }
  }

  # departments
  $form->{department} = "$form->{department}--$form->{department_id}" if $form->{department_id};
  &rebuild_departments;

  # references
  &all_references;

  for (qw(department projectnumber accno currency)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }
  
}


sub search {

  $form->{title} = $locale->text('General Ledger')." ".$locale->text('Reports');

  $form->{reportcode} = 'gl';
  $form->{dateformat} = $myconfig{dateformat};
  
  $form->all_departments(\%myconfig);

  # departments
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "\n";
    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|$_->{description}--$_->{id}\n| }

    $l_department = 1;

    $department = qq|
  	<tr>
	  <th align=right>|.$locale->text('Department').qq|</th>
	  <td><select name=department>|
	  .$form->select_option($form->{selectdepartment}, $form->{department}, 1)
	  .qq|
	  </select></td>
	</tr>
|;
  }

  if (@{ $form->{all_years} }) {
    # accounting years
    $selectaccountingyear = "\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|$_\n| }
    $selectaccountingmonth = "\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|$_--|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
        <tr>
	<th align=right>|.$locale->text('Period').qq|</th>
	<td>
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

  for (qw(transdate reference description debit credit accno)) { $form->{"l_$_"} = "checked" }

  @checked = qw(l_subtotal);
  @input = qw(reference description name vcnumber lineitem notes source memo datefrom dateto month year accnofrom accnoto amountfrom amountto sort direction reportlogin);
  for (qw(department)) {
    push @input, $_ if exists $form->{$_};
  }
  %radio = ( interval => { 0 => 0, 1 => 1, 3 => 2, 12 => 3 },
             category => { X => 0, A => 1, L => 2, Q => 3, I => 4, E => 5 }
           );

  $i = 1;
  $includeinreport{id} = { ndx => $i++, sort => id, checkbox => 1, html => qq|<input name="l_id" class=checkbox type=checkbox value=Y $form->{l_id}>|, label => $locale->text('ID') };
  $includeinreport{transdate} = { ndx => $i++, sort => transdate, checkbox => 1, html => qq|<input name="l_transdate" class=checkbox type=checkbox value=Y $form->{l_transdate}>|, label => $locale->text('Date') };
  $includeinreport{reference} = { ndx => $i++, sort => reference, checkbox => 1, html => qq|<input name="l_reference" class=checkbox type=checkbox value=Y $form->{l_reference}>|, label => $locale->text('Reference') };
  $includeinreport{description} = { ndx => $i++, sort => description, checkbox => 1, html => qq|<input name="l_description" class=checkbox type=checkbox value=Y $form->{l_description}>|, label => $locale->text('Description') };
  $includeinreport{name} = { ndx => $i++, sort => name, checkbox => 1, html => qq|<input name="l_name" class=checkbox type=checkbox value=Y $form->{l_name}>|, label => $locale->text('Company Name') };
  $includeinreport{vcnumber} = { ndx => $i++, sort => vcnumber, checkbox => 1, html => qq|<input name="l_vcnumber" class=checkbox type=checkbox value=Y $form->{l_vcnumber}>|, label => $locale->text('Company Number') };
  $includeinreport{address} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_address" class=checkbox type=checkbox value=Y $form->{l_address}>|, label => $locale->text('Address') };
  $includeinreport{department} = { ndx => $i++, sort => department, checkbox => 1, html => qq|<input name="l_department" class=checkbox type=checkbox value=Y $form->{l_department}>|, label => $locale->text('Department') } if $l_department;
  $includeinreport{notes} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_notes" class=checkbox type=checkbox value=Y $form->{l_notes}>|, label => $locale->text('Notes') };
  $includeinreport{debit} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_debit" class=checkbox type=checkbox value=Y $form->{l_debit}>|, label => $locale->text('Debit') };
  $includeinreport{credit} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_credit" class=checkbox type=checkbox value=Y $form->{l_credit}>|, label => $locale->text('Credit') };
  $includeinreport{source} = { ndx => $i++, sort => source, checkbox => 1, html => qq|<input name="l_source" class=checkbox type=checkbox value=Y $form->{l_source}>|, label => $locale->text('Source') };
  $includeinreport{memo} = { ndx => $i++, sort => memo, checkbox => 1, html => qq|<input name="l_memo" class=checkbox type=checkbox value=Y $form->{l_memo}>|, label => $locale->text('Memo') };
  $includeinreport{lineitem} = { ndx => $i++, sort => lineitem, checkbox => 1, html => qq|<input name="l_lineitem" class=checkbox type=checkbox value=Y $form->{l_lineitem}>|, label => $locale->text('Line Item') };
  $includeinreport{accno} = { ndx => $i++, sort => accno, checkbox => 1, html => qq|<input name="l_accno" class=checkbox type=checkbox value=Y $form->{l_accno}>|, label => $locale->text('Account') };
  $includeinreport{gifi_accno} = { ndx => $i++, sort => gifi_accno, checkbox => 1, html => qq|<input name="l_gifi_accno" class=checkbox type=checkbox value=Y $form->{l_gifi_accno}>|, label => $locale->text('GIFI') };
  $includeinreport{contra} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_contra" class=checkbox type=checkbox value=Y $form->{l_contra}>|, label => $locale->text('Contra') };

  @f = ();
  $form->{flds} = "";
  
  for (sort { $includeinreport{$a}->{ndx} <=> $includeinreport{$b}->{ndx} } keys %includeinreport) {
    $form->{flds} .= "$_=$includeinreport{$_}->{label}=$includeinreport{$_}->{sort},";
    push @checked, "l_$_";
    if ($includeinreport{$_}->{checkbox}) {
      push @f, "$includeinreport{$_}->{html} $includeinreport{$_}->{label}";
    }
  }
  chop $form->{flds};

  $form->helpref("search_gl_transactions", $myconfig{countrycode});
  
  $form->header;

  &calendar;
  
  &change_report(\%$form, \@input, \@checked, \%radio);
  
  print qq|
<body>

<form method="post" name="main" action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        $reportform
	<tr>
	  <th align=right>|.$locale->text('Reference').qq| / |.$locale->text('Invoice Number').qq|</th>
	  <td><input name=reference size=20></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Company Name').qq|</th>
	  <td><input name=name size=35></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Company Number').qq|</th>
	  <td><input name=vcnumber size=35></td>
	</tr>

      	$department
	
	<tr>
	  <th align=right>|.$locale->text('Line Item').qq|</th>
	  <td><input name=lineitem size=30></td>
	</tr>

	<tr>
	  <th align=right>|.$locale->text('Notes').qq|</th>
	  <td><input name=notes size=40></td>
	</tr>

	<tr>
	  <th align=right>|.$locale->text('Source').qq|</th>
	  <td><input name=source size=20></td>
	</tr>
	
	<tr>
	  <th align=right>|.$locale->text('Memo').qq|</th>
	  <td><input name=memo size=30></td>
	</tr>

	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=datefrom size=11 class=date title="$myconfig{dateformat}"> <b>|.&js_calendar("main", "datefrom").$locale->text('To').qq|</b> <input name=dateto size=11 class=date title="$myconfig{dateformat}">|.&js_calendar("main", "dateto").qq|</td>
	</tr>
	
	$selectfrom
	
	<tr>
	  <th align=right>|.$locale->text('Account').qq| >=</th>
	  <td><input name=accnofrom> <b>|.$locale->text('Account').qq| <=</b> <input name=accnoto></td>
	</tr>
	
	<tr>
	  <th align=right>|.$locale->text('Amount').qq| >=</th>
	  <td><input name=amountfrom size=11> <b>|.$locale->text('Amount').qq| <=</b> <input name=amountto size=11></td>
	</tr>
	
	<tr>
	  <th align=right>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table>
	      <tr>
		<td>
		  <input name="category" class=radio type=radio value=X checked>&nbsp;|.$locale->text('All').qq|
		  <input name="category" class=radio type=radio value=A>&nbsp;|.$locale->text('Asset').qq|
		  <input name="category" class=radio type=radio value=L>&nbsp;|.$locale->text('Liability').qq|
		  <input name="category" class=radio type=radio value=Q>&nbsp;|.$locale->text('Equity').qq|
		  <input name="category" class=radio type=radio value=I>&nbsp;|.$locale->text('Income').qq|
		  <input name="category" class=radio type=radio value=E>&nbsp;|.$locale->text('Expense').qq|
		</td>
	      </tr>
	      
	      <tr>
	        <td>
		  <table>
|;

  while (@f) {
    print qq|<tr>\n|;
    for (1 .. 5) {
      print qq|<td nowrap>|. shift @f;
      print qq|</td>\n|;
    }
    print qq|</tr>\n|;
  }

  print qq|
		    <tr>
		      <td nowrap><input name="l_subtotal" class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|</td>
		    </tr>
		  </table>
		</td>
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
<br>
|;


  %button = ('Continue' => { ndx => 1, key => 'C', value => $locale->text('Continue') } );
  
  $form->print_button(\%button);
  
  $form->{sort} ||= "transdate";
  $form->{direction} ||= "ASC";
  
  $form->{nextsub} = "transactions";
  $form->{initreport} = 1;
 
  $form->hide_form(qw(sort direction reportlogin nextsub initreport path login flds));
 
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


sub transactions {

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};
  $form->{sort} ||= "transdate";
  $form->{reportcode} = 'gl';

  GL->transactions(\%myconfig, \%$form);

  $href = "$form->{script}?action=transactions";
  for (qw(direction oldsort path login month year interval reportlogin)) { $href .= "&$_=$form->{$_}" }
  for (qw(report flds)) { $href .= "&$_=".$form->escape($form->{$_}) }

  $form->sort_order();

  $callback = "$form->{script}?action=transactions";
  for (qw(direction oldsort path login month year interval reportlogin)) { $callback .= "&$_=$form->{$_}" }
  for (qw(report flds)) { $callback .= "&$_=".$form->escape($form->{$_}) }
  
  %acctype = ( 'A' => $locale->text('Asset'),
               'L' => $locale->text('Liability'),
	       'Q' => $locale->text('Equity'),
	       'I' => $locale->text('Income'),
	       'E' => $locale->text('Expense'),
	     );
  
  $form->{title} = $locale->text('General Ledger') . " / $form->{company}";
  
  $ml = ($form->{category} =~ /(A|E)/) ? -1 : 1;

  unless ($form->{category} eq 'X') {
    $form->{title} .= " : ".$locale->text($acctype{$form->{category}});
  }
  if ($form->{accno}) {
    $href .= "&accno=".$form->escape($form->{accno});
    $callback .= "&accno=".$form->escape($form->{accno},1);
    $option = $locale->text('Account')." : $form->{accno} $form->{account_description}";
  }
  if ($form->{gifi_accno}) {
    $href .= "&gifi_accno=".$form->escape($form->{gifi_accno});
    $callback .= "&gifi_accno=".$form->escape($form->{gifi_accno},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('GIFI')." : $form->{gifi_accno} $form->{gifi_account_description}";
  }
  if ($form->{reference}) {
    $href .= "&reference=".$form->escape($form->{reference});
    $callback .= "&reference=".$form->escape($form->{reference},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Reference')." / ".$locale->text('Invoice Number')." : $form->{reference}";
  }
  if ($form->{description}) {
    $href .= "&description=".$form->escape($form->{description});
    $callback .= "&description=".$form->escape($form->{description},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Description')." : $form->{description}";
  }
  if ($form->{name}) {
    $href .= "&name=".$form->escape($form->{name});
    $callback .= "&name=".$form->escape($form->{name},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Company Name')." : $form->{name}";
  }
  if ($form->{vcnumber}) {
    $href .= "&vcnumber=".$form->escape($form->{vcnumber});
    $callback .= "&vcnumber=".$form->escape($form->{vcnumber},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Company Number')." : $form->{vcnumber}";
  }
  if ($form->{department}) {
    $href .= "&department=".$form->escape($form->{department});
    $callback .= "&department=".$form->escape($form->{department},1);
    ($department) = split /--/, $form->{department};
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Department')." : $department";
  }
  if ($form->{notes}) {
    $href .= "&notes=".$form->escape($form->{notes});
    $callback .= "&notes=".$form->escape($form->{notes},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Notes')." : $form->{notes}";
  }
  if ($form->{lineitem}) {
    $href .= "&lineitem=".$form->escape($form->{lineitem});
    $callback .= "&lineitem=".$form->escape($form->{lineitem},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Line Item')." : $form->{lineitem}";
  }
  if ($form->{source}) {
    $href .= "&source=".$form->escape($form->{source});
    $callback .= "&source=".$form->escape($form->{source},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Source')." : $form->{source}";
  }
  if ($form->{memo}) {
    $href .= "&memo=".$form->escape($form->{memo});
    $callback .= "&memo=".$form->escape($form->{memo},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Memo')." : $form->{memo}";
  }
  if ($form->{datefrom}) {
    $href .= "&datefrom=$form->{datefrom}";
    $callback .= "&datefrom=$form->{datefrom}";
    $option .= "\n<br>" if $option;
    $option .= $locale->text('From')." ".$locale->date(\%myconfig, $form->{datefrom}, 1);
  }
  if ($form->{dateto}) {
    $href .= "&dateto=$form->{dateto}";
    $callback .= "&dateto=$form->{dateto}";
    if ($form->{datefrom}) {
      $option .= " ";
    } else {
      $option .= "\n<br>" if $option;
    }
    $option .= $locale->text('To')." ".$locale->date(\%myconfig, $form->{dateto}, 1);
  }
  if ($form->{accnofrom}) {
    $href .= "&accnofrom=$form->{accnofrom}";
    $callback .= "&accnofrom=$form->{accnofrom}";
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Account')." >= $form->{accnofrom} $form->{accnofrom_description}";
    $form->{l_contra} = "";
  }
  if ($form->{accnoto}) {
    $href .= "&accnoto=$form->{accnoto}";
    $callback .= "&accnoto=$form->{accnoto}";
    if ($form->{accnofrom}) {
      $option .= " <= ";
    } else {
      $option .= "\n<br>" if $option;
      $option .= $locale->text('Account')." <= ";
    }
    $option .= "$form->{accnoto} $form->{accnoto_description}";
    $form->{l_contra} = "";
  }
  if ($form->{amountfrom}) {
    $href .= "&amountfrom=$form->{amountfrom}";
    $callback .= "&amountfrom=$form->{amountfrom}";
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Amount')." >= ".$form->format_amount(\%myconfig, $form->{amountfrom}, $form->{precision});
  }
  if ($form->{amountto}) {
    $href .= "&amountto=$form->{amountto}";
    $callback .= "&amountto=$form->{amountto}";
    if ($form->{amountfrom}) {
      $option .= " <= ";
    } else {
      $option .= "\n<br>" if $option;
      $option .= $locale->text('Amount')." <= ";
    }
    $option .= $form->format_amount(\%myconfig, $form->{amountto}, $form->{precision});
  }

  @columns = ();
  for (split /,/, $form->{flds}) {
    ($column, $label, $sort) = split /=/, $_;
    push @columns, $column;
    $column_data{$column} = $label;
    $column_sort{$column} = $sort;
  }

  push @columns, "gifi_contra";
  $column_data{gifi_contra} = $column_data{contra};
  $form->{l_gifi_contra} = "Y" if ($form->{l_gifi_accno} && $form->{l_contra});
  delete $form->{l_contra} unless $form->{l_accno};
  
  $columns{debit} = 1;
  $columns{credit} = 1;
  
  
  if ($form->{link} =~ /_paid/) {
    push @columns, "cleared";
    $column_data{cleared} = $locale->text('R');
    $form->{l_cleared} = "Y";
  }
  @columns = grep !/department/, @columns if $form->{department};

  $i = 0;
  if ($form->{column_index}) {
    for (split /,/, $form->{column_index}) {
      s/=.*//;
      push @column_index, $_;
      $column_index{$_} = ++$i;
      $form->{"l_$_"} = "Y";
    }
  } else {
    for (@columns) {
      if ($form->{"l_$_"} eq "Y") {
	push @column_index, $_;
	$column_index{$_} = ++$i;
	$form->{column_index} .= "$_=$columns{$_},";
      }
    }
    chop $form->{column_index};
  }
  
  if ($form->{accno} || $form->{gifi_accno}) {
    @column_index = grep !/(accno|gifi_accno|contra|gifi_contra)/, @column_index;
    push @column_index, "balance";
    $column_data{balance} = $locale->text('Balance');
    for (qw(l_contra l_gifi_contra)) { delete $form->{$_} }
  }

  if ($form->{l_contra}) {
    $form->{l_gifi_contra} = "Y" if $form->{l_gifi_accno};
    $form->{l_contra} = "" if ! $form->{l_accno};
  }

  if ($form->{initreport}) {
    if ($form->{movecolumn}) {
      @column_index = $form->sort_column_index;
    } else {
      @column_index = ();
      $form->{column_index} = "";
      $i = 0;
      $j = 0;
      for (split /,/, $form->{report_column_index}) {
	s/=.*//;
	$j++;

	if ($form->{"l_$_"}) {
	  push @column_index, $_;
	  $form->{column_index} .= "$_=$columns{$_},";
	  delete $column_index{$_};
	  $i++;
	}
      }

      for (sort { $column_index{$a} <=> $column_index{$b} } keys %column_index) {
	push @column_index, $_;
      }

      $form->{column_index} = "";
      for (@column_index) { $form->{column_index} .= "$_=$columns{$_}," }
      chop $form->{column_index};

    }
  } else {
    if ($form->{movecolumn}) {
      @column_index = $form->sort_column_index;
    }
  }
  
  for (@columns) {
    if ($form->{"l_$_"} eq "Y") {
      # add column to href and callback
      $callback .= "&l_$_=Y";
      $href .= "&l_$_=Y";
    }
  }
  

  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
    $href .= "&l_subtotal=Y";
  }
  $href .= "&column_index=".$form->escape($form->{column_index});
  $callback .= "&column_index=".$form->escape($form->{column_index});

  $href .= "&category=$form->{category}";
  $callback .= "&category=$form->{category}";

  $form->helpref("list_gl_transactions", $myconfig{countrycode});
  
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
|;

  $l = $#column_index;

  print qq|<tr>
|;

  if (!($form->{accno} || $form->{gifi_accno})) {
    if ($l > 0) {
      $revhref = $href;
      $direction = ($form->{direction} eq 'DESC') ? "ASC" : "DESC";
      $revhref =~ s/direction=$direction/direction=$form->{direction}/;
     
      print "\n<td align=center><a href=$revhref&movecolumn=$column_index[0],right><img src=$images/right.png border=0></td>";
      for (1 .. $l - 1) {
	print "\n<td align=center><a href=$revhref&movecolumn=$column_index[$_],left><img src=$images/left.png border=0><a href=$href&movecolumn=$column_index[$_],right><img src=$images/right.png border=0></td>";
      }
      print "\n<td align=center><a href=$revhref&movecolumn=$column_index[$l],left><img src=$images/left.png border=0></td>";
    }
  }

  print qq|
        </tr>
	<tr class=listheading>
|;

  for (0 .. $l) {
    if ($column_sort{$column_index[$_]}) {
      $sort = "";
      if ($form->{sort} eq $column_sort{$column_index[$_]}) {
	if ($form->{direction} eq 'ASC') {
	  $sort = qq|<img src=$images/up.png>&nbsp;&nbsp;&nbsp;|;
	} else {
	  $sort = qq|<img src=$images/down.png>&nbsp;&nbsp;&nbsp;|;
	}
      }
      print qq|\n<th nowrap>$sort<a class=listheading href=$href&sort=$column_sort{$column_index[$_]}>$column_data{$column_index[$_]}</a></th>|;
    } else {
      print qq|\n<th nowrap class=listheading>$column_data{$column_index[$_]}</th>|;
    }
  }
  
  print qq|
        </tr>
|;


  # add sort to callback
  $form->{callback} = "$callback&sort=$form->{sort}";
  $callback = $form->escape($form->{callback});

  $cml = 1;
  # initial item for subtotals
  if (@{ $form->{GL} }) {
    $sameitem = $form->{GL}->[0]->{$form->{sort}};
    $cml = -1 if $form->{contra};
  }
  
  if (($form->{accno} || $form->{gifi_accno}) && $form->{balance}) {

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $form->{balance} * $ml * $cml, $form->{precision}, 0)."</td>";
    
    if ($ref->{id} != $sameid) {
      $i++; $i %= 2;
    }
   
    print qq|
        <tr class=listrow$i>
|;
    for (@column_index) { print "$column_data{$_}\n" }
    
    print qq|
        </tr>
|;
  }

  # reverse href
  $direction = ($form->{direction} eq 'ASC') ? "ASC" : "DESC";
  $form->sort_order();
  $href =~ s/direction=$form->{direction}/direction=$direction/;

  $i = 0;
  foreach $ref (@{ $form->{GL} }) {

    # if item ne sort print subtotal
    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&gl_subtotal;
      }
    }
    
    $form->{balance} += $ref->{amount};
    
    $subtotaldebit += $ref->{debit};
    $subtotalcredit += $ref->{credit};
    
    $totaldebit += $ref->{debit};
    $totalcredit += $ref->{credit};

    $ref->{debit} = $form->format_amount(\%myconfig, $ref->{debit}, $form->{precision}, "&nbsp;");
    $ref->{credit} = $form->format_amount(\%myconfig, $ref->{credit}, $form->{precision}, "&nbsp;");
    
    $column_data{id} = "<td>$ref->{id}</td>";
    $column_data{transdate} = "<td nowrap>$ref->{transdate}</td>";

    $ref->{reference} ||= "&nbsp;";
    $column_data{reference} = "<td><a href=$ref->{module}.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{reference}</td>";

    for (qw(department name vcnumber address)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
    
    for (qw(lineitem description source memo notes)) {
      $ref->{$_} =~ s/\r?\n/<br>/g;
      $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>";
    }
    
    if ($ref->{vc_id}) {
      $column_data{name} = "<td><a href=ct.pl?action=edit&id=$ref->{vc_id}&db=$ref->{db}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{name}</td>";
    }
    
    $column_data{debit} = "<td align=right>$ref->{debit}</td>";
    $column_data{credit} = "<td align=right>$ref->{credit}</td>";
    
    $column_data{accno} = "<td><a href=$href&accno=$ref->{accno}&callback=$callback>$ref->{accno}</a></td>";
    $column_data{contra} = "<td>";
    for (split / /, $ref->{contra}) {
      $column_data{contra} .= qq|<a href=$href&accno=$_&callback=$callback>$_</a>&nbsp;|
    }
    $column_data{contra} .= "</td>";
    $column_data{gifi_accno} = "<td><a href=$href&gifi_accno=$ref->{gifi_accno}&callback=$callback>$ref->{gifi_accno}</a>&nbsp;</td>";
    $column_data{gifi_contra} = "<td>";
    for (split / /, $ref->{gifi_contra}) {
      $column_data{gifi_contra} .= qq|<a href=$href&gifi_accno=$_&callback=$callback>$_</a>&nbsp;|
    }
    $column_data{gifi_contra} .= "</td>";

    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $form->{balance} * $ml * $cml, $form->{precision}, 0)."</td>";
    $column_data{cleared} = ($ref->{cleared}) ? "<td>*</td>" : "<td>&nbsp;</td>";

    if ($ref->{id} != $sameid) {
      $i++; $i %= 2;
    }
    print "
        <tr class=listrow$i>";
    for (@column_index) { print "$column_data{$_}\n" }
    print "</tr>";
    
    $sameid = $ref->{id};
  }


  &gl_subtotal if ($form->{l_subtotal} eq 'Y');


  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $column_data{debit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totaldebit, $form->{precision}, "&nbsp;")."</th>";
  $column_data{credit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totalcredit, $form->{precision}, "&nbsp;")."</th>";
  $column_data{balance} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $form->{balance} * $ml * $cml, $form->{precision}, 0)."</th>";
  
  print qq|
	<tr class=listtotal>
|;

  for (@column_index) { print "$column_data{$_}\n" }

  
  %button = ('General Ledger--Add Transaction' => { ndx => 1, key => 'G', value => $locale->text('GL Transaction') },
  'AR--Add Transaction' => { ndx => 2, key => 'R', value => $locale->text('AR Transaction') },
  'AR--Sales Invoice' => { ndx => 3, key => 'I', value => $locale->text('Sales Invoice ') },
  'AR--Credit Invoice' => { ndx => 4, key => 'C', value => $locale->text('Credit Invoice ') },
  'AP--Add Transaction' => { ndx => 5, key => 'P', value => $locale->text('AP Transaction') },
  'AP--Vendor Invoice' => { ndx => 6, key => 'V', value => $locale->text('Vendor Invoice ') },
  'AP--Vendor Invoice' => { ndx => 7, key => 'D', value => $locale->text('Debit Invoice ') },
  'Save Report' => { ndx => 8, key => 'S', value => $locale->text('Save Report') }
            );

  if (!$form->{admin}) {
    delete $button{'Save Report'} unless $form->{savereport};
  }
    
  if ($myconfig{acs} =~ /General Ledger--General Ledger/) {
    delete $button{'General Ledger--Add Transaction'};
  }
  if ($myconfig{acs} =~ /AR--AR/) {
    delete $button{'AR--Add Transaction'};
    delete $button{'AR--Sales Invoice'};
    delete $button{'AR--Credit Invoice'};
  }
  if ($myconfig{acs} =~ /AP--AP/) {
    delete $button{'AP--AP Transaction'};
    delete $button{'AP--Vendor Invoice'};
    delete $button{'AP--Debit Invoice'};
  }

  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }

  if ($form->{accno} || $form->{gifi_accno}) {
    delete $button{'Save Report'};
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

<br>

<form method=post action=$form->{script}>
|;

  if ($form->{year} && $form->{month}) {
    for (qw(datefrom dateto)) { delete $form->{$_} }
  }
  $form->hide_form(qw(department reference description name vcnumber lineitem notes source memo datefrom dateto month year accnofrom accnoto amountfrom amountto interval category l_subtotal));
  
  $form->hide_form(qw(callback path login report reportcode reportlogin column_index flds sort direction));
  
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


sub gl_subtotal {
      
  $subtotaldebit = $form->format_amount(\%myconfig, $subtotaldebit, $form->{precision}, "&nbsp;");
  $subtotalcredit = $form->format_amount(\%myconfig, $subtotalcredit, $form->{precision}, "&nbsp;");
  
  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{debit} = "<th align=right class=listsubtotal>$subtotaldebit</td>";
  $column_data{credit} = "<th align=right class=listsubtotal>$subtotalcredit</td>";

  
  print "<tr class=listsubtotal>";
  for (@column_index) { print "$column_data{$_}\n" }
  print "</tr>";

  $subtotaldebit = 0;
  $subtotalcredit = 0;

  $sameitem = $ref->{$form->{sort}};

}


sub update {

  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{exchangerate} = $form->parse_amount(\%myconfig, $form->{exchangerate});
  }
  
  if ($form->{transdate} ne $form->{oldtransdate}) {
    if ($form->{selectprojectnumber}) {
      $form->all_projects(\%myconfig, undef, $form->{transdate});
      if (@{ $form->{all_project} }) {
	$form->{selectprojectnumber} = "\n";
	for (@{ $form->{all_project} }) { $form->{selectprojectnumber} .= qq|$_->{projectnumber}--$_->{id}\n| }
	$form->{selectprojectnumber} = $form->escape($form->{selectprojectnumber},1);
      }
    }
    $form->{oldtransdate} = $form->{transdate};
    
    $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate});
    $form->{oldcurrency} = $form->{currency};
  }
  
  $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}) if $form->{currency} ne $form->{oldcurrency};
  
  $form->{oldcurrency} = $form->{currency};

  &rebuild_departments if $form->{department} ne $form->{olddepartment};

  @f = ();
  $count = 0;
  @flds = qw(accno debit credit projectnumber source memo cleared fx_transaction);

  for $i (1 .. $form->{rowcount}) {
    unless (($form->{"debit_$i"} eq "") && ($form->{"credit_$i"} eq "")) {
      for (qw(debit credit)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
      
      push @f, {};
      $j = $#f;
      
      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }


  for $i (1 .. $count) {
    $j = $i - 1;
    for (@flds) { $form->{"${_}_$i"} = $f[$j]->{$_} }
  }

  for $i ($count + 1 .. $form->{rowcount}) {
    for (@flds) { delete $form->{"${_}_$i"} }
  }

  $form->{rowcount} = $count + 1;

  &display_form;
  
}


sub display_form {
  my ($init) = @_;

  &form_header;
  &display_rows($init);
  &form_footer;

}


sub display_rows {
  my ($init) = @_;

  $form->{totaldebit} = 0;
  $form->{totalcredit} = 0;

  for $i (1 .. $form->{rowcount}) {

    $source = qq|
    <td><input name="source_$i" size=10 value="|.$form->quote($form->{"source_$i"}).qq|"></td>|;
    $memo = qq|
    <td><input name="memo_$i" value="|.$form->quote($form->{"memo_$i"}).qq|"></td>|;

    if ($init) {
      $accno = qq|
      <td><select name="accno_$i">|.$form->select_option($form->{selectaccno}).qq|</select></td>|;
      
      if ($form->{selectprojectnumber}) {
	$project = qq|
    <td><select name="projectnumber_$i">|.$form->select_option($form->{selectprojectnumber}, undef, 1).qq|</select></td>|;
      }

      if ($form->{fxadj}) {
	$fx_transaction = qq|
	<td><input name="fx_transaction_$i" class=checkbox type=checkbox value=1></td>
|;
      }
    
    } else {
   
      $form->{totaldebit} += $form->{"debit_$i"};
      $form->{totalcredit} += $form->{"credit_$i"};

      for (qw(debit credit)) { $form->{"${_}_$i"} = ($form->{"${_}_$i"}) ? $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $form->{precision}) : "" }

      if ($i < $form->{rowcount}) {
	
	$accno = qq|<td>$form->{"accno_$i"}</td>|;

	if ($form->{selectprojectnumber}) {
	  $project = $form->{"projectnumber_$i"};
	  $project =~ s/--.*//;
	  $project = qq|<td>$project</td>|;
	}

	if ($form->{fxadj}) {
	  $checked = ($form->{"fx_transaction_$i"}) ? "1" : "";
	  $x = ($checked) ? "x" : "";
	  $fx_transaction = qq|
      <td><input type=hidden name="fx_transaction_$i" value="$checked">$x</td>
|;
	}
      
	$form->hide_form(map { "${_}_$i"} qw(accno projectnumber));
	
      } else {
	
	$accno = qq|
      <td><select name="accno_$i">|.$form->select_option($form->{selectaccno}).qq|</select></td>|;

	if ($form->{selectprojectnumber}) {
	  $project = qq|
      <td><select name="projectnumber_$i">|.$form->select_option($form->{selectprojectnumber}, undef, 1).qq|</select></td>|;
	}

	if ($form->{fxadj}) {
	  $fx_transaction = qq|
      <td><input name="fx_transaction_$i" class=checkbox type=checkbox value=1></td>
|;
	}
      }
    }
    
    print qq|<tr valign=top>
    $accno
    $fx_transaction
    <td><input name="debit_$i" class="inputright" size=12 value="$form->{"debit_$i"}" accesskey=$i></td>
    <td><input name="credit_$i" class="inputright" size=12 value=$form->{"credit_$i"}></td>
    $source
    $memo
    $project
  </tr>
|;

    $form->hide_form("cleared_$i");
    
  }

  $form->hide_form(qw(rowcount));
  $form->hide_form(map { "select$_" } qw(accno projectnumber));
  
}


sub form_header {

  for (qw(reference description notes)) { $form->{$_} = $form->quote($form->{$_}) }
  
  $reference_documents = &references;

  if (($rows = $form->numtextrows($form->{description}, 50)) > 1) {
    $description = qq|<textarea name=description rows=$rows cols=50 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=50 value="|.$form->quote($form->{description}).qq|">|;
  }
  
  if (($rows = $form->numtextrows($form->{notes}, 50)) > 1) {
    $notes = qq|<textarea name=notes rows=$rows cols=50 wrap=soft>$form->{notes}</textarea>|;
  } else {
    $notes = qq|<input name=notes size=50 value="|.$form->quote($form->{notes}).qq|">|;
  }


  if (!$form->{fxadj}) {
    $exchangerate = qq|<input type=hidden name=action value="Update">
                <th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td>
		  <table>
		    <tr>
                      <td><select name=currency onChange="javascript:document.main.submit()">|
		      .$form->select_option($form->{selectcurrency}, $form->{currency})
		      .qq|</select></td>|;

    if ($form->{currency} ne $form->{defaultcurrency}) {

      $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});
      
      $exchangerate .= qq|
      <th align=right nowrap>|.$locale->text('Exchange Rate').qq| <font color=red>*</font></th>
      <td><input name=exchangerate class="inputright" size=10 value=$form->{exchangerate}></td>|;
    }
    $exchangerate .= qq|</tr></table></td></tr>|;
  }
  
  $department = qq|
	  <th align=right nowrap>|.$locale->text('Department').qq|</th>
	  <td><select name=department onChange="javascript:document.main.submit()">|
          .$form->select_option($form->{selectdepartment}, $form->{department}, 1)
          .qq|</select></td>
| if $form->{selectdepartment};

  $project = qq| 
	  <th class=listheading>|.$locale->text('Project').qq|</th>
| if $form->{selectprojectnumber};

  if ($form->{fxadj}) {
    $fx_transaction = qq|
          <th class=listheading>|.$locale->text('FX').qq|</th>
|;
  }

  $focus = ($form->{focus}) ? $form->{focus} : "debit_$form->{rowcount}";
  
  if ($form->{batch} && ! $form->{approved}) {
    $transdate = qq|
	  <td>$form->{transdate}</td>
	  <input type=hidden name=transdate value=$form->{transdate}>
|;
  } else {
    $transdate = qq|
	  <td><input name=transdate size=11 class=date title="$myconfig{dateformat}" value=$form->{transdate}>|.&js_calendar("main", "transdate").qq|</td>
|;
  }

  $form->header;
  
  &calendar;

  print qq|
<body onload="document.main.${focus}.focus()" />

<form method="post" name="main" action="$form->{script}">
|;

  $form->hide_form(qw(id fxadj closedto locked oldtransdate oldcurrency recurring batch batchid batchnumber batchdescription defaultcurrency precision helpref reference_rows referenceurl olddepartment));
  $form->hide_form(map { "select$_" } qw(accno department currency));
  
  print qq|
<input type=hidden name=title value="|.$form->quote($form->{title}).qq|">

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Reference').qq|</th>
	  <td><input name=reference size=20 value="|.$form->quote($form->{reference}).qq|"></td>
	  <th align=right>|.$locale->text('Date').qq| <font color=red>*</font></th>
	  $transdate
	</tr>
	<tr>
	  $department
	  $exchangerate
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td colspan=3>$description</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Notes').qq|</th>
	  <td colspan=3>$notes</td>
	</tr>
	$reference_documents
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
	  <th class=listheading>|.$locale->text('Account').qq|</th>
	  $fx_transaction
	  <th class=listheading>|.$locale->text('Debit').qq|</th>
	  <th class=listheading>|.$locale->text('Credit').qq|</th>
	  <th class=listheading>|.$locale->text('Source').qq|</th>
	  <th class=listheading>|.$locale->text('Memo').qq|</th>
	  $project
	</tr>
|;

}


sub form_footer {

  $difference = $form->{totaldebit} - $form->{totalcredit};
  if ($difference > 0) {
    $form->{differencecredit} = $form->format_amount(\%myconfig, $difference, $form->{precision}, "&nbsp;");
  } else {
    $form->{differencedebit} = $form->format_amount(\%myconfig, $difference * -1, $form->{precision}, "&nbsp;");
  }

  for (qw(totaldebit totalcredit)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $form->{precision}, "&nbsp;") }


  $project = qq|
	  <th>&nbsp;</th>
| if $form->{selectprojectnumber};

  if ($form->{fxadj}) {
    $fx_transaction = qq|
          <th>&nbsp;</th>
|;
  }

  if ($difference) {
    $difference = qq|
        <tr>
          <th>&nbsp;</th>
          $fx_transaction
          <th align=right>$form->{differencedebit}</th>
          <th align=right>$form->{differencecredit}</th>
          <th>&nbsp;</th>
          <th>&nbsp;</th>
          $project
        </tr>
|;
  } else {
    $difference = "";
  }

  print qq|
        <tr class=listtotal>
	  <th>&nbsp;</th>
	  $fx_transaction
	  <th class=listtotal align=right>$form->{totaldebit}</th>
	  <th class=listtotal align=right>$form->{totalcredit}</th>
	  <th>&nbsp;</th>
	  <th>&nbsp;</th>
	  $project
        </tr>
        $difference
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->hide_form(qw(path login callback));
  
  $transdate = $form->datetonum(\%myconfig, $form->{transdate});

  if ($form->{readonly}) {

    &islocked;

  } else {

    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
               'Post' => { ndx => 3, key => 'O', value => $locale->text('Post') },
	       'Post as new' => { ndx => 6, key => 'N', value => $locale->text('Post as new') },
	       'Schedule' => { ndx => 7, key => 'H', value => $locale->text('Schedule') },
	       'New Number' => { ndx => 10, key => 'M', value => $locale->text('New Number') },
	       'Delete' => { ndx => 11, key => 'D', value => $locale->text('Delete') },
	      );
    
    %f = ();
    
    if ($form->{id}) {
      for ('Update', 'Post as new', 'Schedule', 'New Number') { $f{$_} = 1 }
      
      if (! $form->{locked}) {
	if ($transdate > $form->{closedto}) {
	  for ('Post', 'Delete') { $f{$_} = 1 }
	}
      }
      
    } else {
      if ($transdate > $form->{closedto}) {
	for ("Update", "Post", "Schedule", "New Number") { $f{$_} = 1 }
      }
    }

    $f{'Schedule'} = 0 if $form->{batch};
    
    for (keys %button) { delete $button{$_} if ! $f{$_} }

    $form->print_button(\%button);
    
  }
  
  if ($form->{recurring}) {
    print qq|<div align=right>|.$locale->text('Scheduled').qq|</div>|;
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


sub delete {

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  delete $form->{action};

  $form->hide_form;
  
  print qq|
<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>

<h4>|.$locale->text('Are you sure you want to delete Transaction').qq| $form->{reference}</h4>

<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>
|;

}


sub yes {

  if (GL->delete_transaction(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Transaction deleted!'));
  } else {
    $form->error($locale->text('Cannot delete transaction!'));
  }
  
}


sub post {

  $form->isblank("transdate", $locale->text('Transaction Date missing!'));

  $transdate = $form->datetonum(\%myconfig, $form->{transdate});

  $form->error($locale->text('Cannot post transaction for a closed period!')) if ($transdate <= $form->{closedto});
  
  # add up debits and credits
  for $i (1 .. $form->{rowcount}) {
    $dr = $form->parse_amount(\%myconfig, $form->{"debit_$i"});
    $cr = $form->parse_amount(\%myconfig, $form->{"credit_$i"});
    
    if ($dr && $cr) {
      $form->error($locale->text('Cannot post transaction with a debit and credit entry for the same account!'));
    }
    $debit += $dr;
    $credit += $cr;
  }
  
  if ($form->round_amount($debit, $form->{precision}) != $form->round_amount($credit, $form->{precision})) {
    $form->error($locale->text('Out of balance transaction!'));
  }

  if (! $form->{repost}) {
    if ($form->{id} && ! $form->{batch}) {
      &repost;
      exit;
    }
  }

  $form->{userspath} = $userspath;
  
  if ($form->{batch}) {
    $rc = VR->post_transaction(\%myconfig, \%$form);
  } else {
    $rc = GL->post_transaction(\%myconfig, \%$form);
  }
  
  if ($form->{callback}) {
    $form->{callback} =~ s/(batch|batchid|batchdescription)=.*?&//g;
    $form->{callback} .= "&batch=$form->{batch}&batchid=$form->{batchid}&transdate=$form->{transdate}&batchdescription=".$form->escape($form->{batchdescription},1);
  }

  if ($rc) {
    $form->redirect($locale->text('Transaction posted!'));
  } else {
    $form->error($locale->text('Cannot post transaction!'));
  }
 
}


