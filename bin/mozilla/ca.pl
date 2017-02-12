#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# module for Chart of Accounts, Income Statement and Balance Sheet
# search and edit transactions posted by the GL, AR and AP
# 
#======================================================================

use SL::CA;
require "$form->{path}/js.pl";


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


sub chart_of_accounts {

  $form->{excludeclosed} = 1;

  CA->all_accounts(\%myconfig, \%$form);

  @column_index = qw(accno gifi_accno description debit credit closed);

  $column_header{accno} = qq|<th class=listtop>|.$locale->text('Account').qq|</th>\n|;
  $column_header{gifi_accno} = qq|<th class=listtop>|.$locale->text('GIFI').qq|</th>\n|;
  $column_header{description} = qq|<th class=listtop>|.$locale->text('Description').qq|</th>\n|;
  $column_header{debit} = qq|<th class=listtop>|.$locale->text('Debit').qq|</th>\n|;
  $column_header{credit} = qq|<th class=listtop>|.$locale->text('Credit').qq|</th>\n|;
  $column_header{closed} = qq|<th width=1% class=listtop>|.$locale->text('Closed').qq|</th>\n|;
  
  $form->helpref("coa", $myconfig{countrycode});
  
  $form->{title} = $locale->text('Chart of Accounts') . " / $form->{company}";

  $colspan = $#column_index + 1;
  
  $form->header;

  print qq|
<body>
  
<table border=0 width=100%>
  <tr>
    <th class=listtop colspan=$colspan>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr class=listheading>|;

  for (@column_index) { print $column_header{$_} }

  print qq|
  </tr>
|;

  
  foreach $ca (@{ $form->{CA} }) {

    $description = $form->escape($ca->{description});
    $gifi_description = $form->escape($ca->{gifi_description});
    
    $href = qq|$form->{script}?path=$form->{path}&action=list&accno=$ca->{accno}&login=$form->{login}&description=$description&gifi_accno=$ca->{gifi_accno}&gifi_description=$gifi_description|;
    
    if ($ca->{charttype} eq "H") {
      print qq|<tr class=listheading>|;
      for (qw(accno description)) { $column_data{$_} = "<th class=listheading>$ca->{$_}</th>" }
      $column_data{gifi_accno} = "<th class=listheading>$ca->{gifi_accno}&nbsp;</th>";
    } else {
      $i++; $i %= 2;
      print qq|<tr class=listrow$i>|;
      $column_data{accno} = "<td><a href=$href>$ca->{accno}</a></td>";
      $column_data{gifi_accno} = "<td><a href=$href&accounttype=gifi>$ca->{gifi_accno}</a>&nbsp;</td>";
      $column_data{description} = "<td>$ca->{description}</td>";
    }
      
    $column_data{debit} = "<td align=right>".$form->format_amount(\%myconfig, $ca->{debit}, $form->{precision}, "&nbsp;")."</td>\n";
    $column_data{credit} = "<td align=right>".$form->format_amount(\%myconfig, $ca->{credit}, $form->{precision}, "&nbsp;")."</td>\n";
    $column_data{closed} = ($ca->{closed}) ? "<td align=center>*</td>" : "<td></td>";
    
    $totaldebit += $ca->{debit};
    $totalcredit += $ca->{credit};

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
</tr>
|;
  }

  for (qw(accno gifi_accno description)) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{debit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totaldebit, $form->{precision}, 0)."</th>";
  $column_data{credit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totalcredit, $form->{precision}, 0)."</th>";
  
  print "<tr class=listtotal>";

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
</tr>
<tr>
  <td colspan=$colspan><hr size=3 noshade></td>
</tr>
</table>

</body>
</html>
|;

}


sub list {

  $form->{title} = $locale->text('List Transactions');
  if ($form->{accounttype} eq 'gifi') {
    $form->{title} .= " - ".$locale->text('GIFI')." $form->{gifi_accno} - $form->{gifi_description}";
  } else {
    $form->{title} .= " - ".$locale->text('Account')." $form->{accno} - $form->{description}";
  }

  # get departments
  $form->all_departments(\%myconfig);
  if (@{ $form->{all_department} }) {
    $selectdepartment = "<option>\n";

    for (@{ $form->{all_department} }) { $selectdepartment .= qq|<option value="|.$form->quote($_->{description}).qq|--$_->{id}">$_->{description}\n| }
  }

  $department = qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('Department').qq|</th>
	  <td colspan=3><select name=department>$selectdepartment</select></td>
	</tr>
| if $selectdepartment;

  if (@{ $form->{all_years} }) {
    # accounting years
    $selectaccountingyear = "\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|$_\n| }
    $selectaccountingmonth = "\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|$_--|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
        <tr>
	<th align=right>|.$locale->text('Period').qq|</th>
	<td colspan=3>
	<select name=month>|.$form->select_option($selectaccountingmonth, undef, 1, 1).qq|</select>
	<select name=year>|.$form->select_option($selectaccountingyear).qq|</select>
	<input name=interval class=radio type=radio value=0 checked>&nbsp;|.$locale->text('Current').qq|
	<input name=interval class=radio type=radio value=1>&nbsp;|.$locale->text('Month').qq|
	<input name=interval class=radio type=radio value=3>&nbsp;|.$locale->text('Quarter').qq|
	<input name=interval class=radio type=radio value=12>&nbsp;|.$locale->text('Year').qq|
	</td>
      </tr>
|;
  }


  $form->helpref("account_transactions", $myconfig{countrycode});
  
  $form->header;
  
  &calendar;
 
  print qq|
<body>

<form method="post" name="main" action="$form->{script}">
|;

  $form->hide_form(qw(accno description accounttype gifi_accno gifi_description login path));
  
  print qq|
<input type=hidden name=sort value=transdate>
<input type=hidden name=oldsort value=transdate>

<table border=0 width=100%>
  <tr><th class=listtop>$form->{helpref}$form->{title}</a></th></tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        $department
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 class=date title="$myconfig{dateformat}">|.&js_calendar("main", "fromdate").qq|<b>|.$locale->text('To').qq|</b>
	  <input name=todate size=11 class=date title="$myconfig{dateformat}">|.&js_calendar("main", "todate").qq|</td>
	</tr>
	$selectfrom
	<tr>
	  <th align=right>|.$locale->text('Include in Report').qq|</th>
	  <td colspan=3>
	  <input name=l_accno class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('AR/AP').qq|
	  <input name=l_subtotal class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>

<br><input class=submit type=submit name=action value="|.$locale->text('List Transactions').qq|">
</form>

</body>
</html>
|;

}


sub list_transactions {

  CA->all_transactions(\%myconfig, \%$form);
  
  $department = $form->escape($form->{department});
  $projectnumber = $form->escape($form->{projectnumber});
  $title = $form->escape($form->{title});

  # construct href
  $href = "$form->{script}?action=list_transactions&department=$department&projectnumber=$projectnumber&title=$title";
  for (qw(path oldsort accno login fromdate todate accounttype gifi_accno l_heading l_subtotal l_accno)) { $href .= "&$_=$form->{$_}" }

  $drilldown = $href;
  $drilldown .= "&sort=$form->{sort}";

  $href .= "&direction=$form->{direction}";
  
  $form->sort_order();

  $drilldown .= "&direction=$form->{direction}";

  $form->{prevreport} = $href unless $form->{prevreport};
  $href .= "&prevreport=".$form->escape($form->{prevreport});
  $drilldown .= "&prevreport=".$form->escape($form->{prevreport});
 
  # figure out which column comes first
  $column_header{transdate} = qq|<th><a class=listheading href=$href&sort=transdate>|.$locale->text('Date').qq|</a></th>|;
  $column_header{reference} = qq|<th><a class=listheading href=$href&sort=reference>|.$locale->text('Reference').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_header{cleared} = qq|<th class=listheading>|.$locale->text('R').qq|</th>|;
  $column_header{source} = qq|<th class=listheading>|.$locale->text('Source').qq|</th>|;
  $column_header{debit} = qq|<th class=listheading>|.$locale->text('Debit').qq|</th>|;
  $column_header{credit} = qq|<th class=listheading>|.$locale->text('Credit').qq|</th>|;
  $column_header{balance} = qq|<th class=listheading>|.$locale->text('Balance').qq|</th>|;
  $column_header{accno} = qq|<th class=listheading>|.$locale->text('AR/AP').qq|</th>|;

  @columns = qw(transdate reference description debit credit);
  if ($form->{link} =~ /_paid/) {
    @columns = qw(transdate reference description source cleared debit credit);
  }
  push @columns, "accno" if $form->{l_accno};
  @column_index = $form->sort_columns(@columns);

 
  if ($form->{accounttype} eq 'gifi') {
    for (qw(accno description)) { $form->{$_} = $form->{"gifi_$_"} }
  }
  if ($form->{accno}) {
    push @column_index, "balance";
  }
    
  $form->{title} = ($form->{accounttype} eq 'gifi') ? $locale->text('GIFI') : $locale->text('Account');
  
  $form->{title} .= " $form->{accno} - $form->{description} / $form->{company}";

  if ($form->{department}) {
    ($department) = split /--/, $form->{department};
    $options = $locale->text('Department')." : $department<br>";
  }
  if ($form->{projectnumber}) {
    ($projectnumber) = split /--/, $form->{projectnumber};
    $options .= $locale->text('Project Number')." : $projectnumber<br>";
  }


  if ($form->{fromdate} || $form->{todate}) {

    if ($form->{fromdate}) {
      $fromdate = $locale->date(\%myconfig, $form->{fromdate}, 1);
    }
    if ($form->{todate}) {
      $todate = $locale->date(\%myconfig, $form->{todate}, 1);
    }
    
    $form->{period} = "$fromdate - $todate";
  } else {
    $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);
  }

  $form->{period} = "<a href=$form->{prevreport}>$form->{period}</a>" if $form->{prevreport};
  
  $options .= $form->{period};


  # construct callback
  $department = $form->escape($form->{department},1);
  $projectnumber = $form->escape($form->{projectnumber},1);
  $title = $form->escape($form->{title},1);
  $form->{prevreport} = $form->escape($form->{prevreport},1);
 
  $form->{callback} = "$form->{script}?action=list_transactions&department=$department&projectnumber=$projectnumber&title=$title";
  for (qw(path direction oldsort accno login fromdate todate accounttype gifi_accno l_heading l_subtotal l_accno prevreport)) { $form->{callback} .= "&$_=$form->{$_}" }

  $form->helpref("account_transactions", $myconfig{countrycode});
  
  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$options</td>
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

  # add sort to callback
  $form->{callback} = $form->escape($form->{callback} . "&sort=$form->{sort}");

  if (@{ $form->{CA} }) {
    $sameitem = $form->{CA}->[0]->{$form->{sort}};
  }

  $ml = ($form->{category} =~ /(A|E)/) ? -1 : 1;
  $ml *= -1 if $form->{contra};

  if ($form->{accno} && $form->{balance}) {
    
    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $form->{balance} * $ml, $form->{precision}, 0)."</td>";

    $i++; $i %= 2;
    
    print qq|
        <tr class=listrow$i>
|;
    for (@column_index) { print "$column_data{$_}\n" }
    print qq|
       </tr>
|;

  }
    
  foreach $ca (@{ $form->{CA} }) {

    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ca->{$form->{sort}}) {
	&ca_subtotal;
      }
    }
    
    # construct link to source
    $href = "<a href=$ca->{module}.pl?path=$form->{path}&action=edit&id=$ca->{id}&login=$form->{login}&callback=$form->{callback}>$ca->{reference}</a>";

    
    $column_data{debit} = "<td align=right>".$form->format_amount(\%myconfig, $ca->{debit}, $form->{precision}, "&nbsp;")."</td>";
    $column_data{credit} = "<td align=right>".$form->format_amount(\%myconfig, $ca->{credit}, $form->{precision}, "&nbsp;")."</td>";
    
    $form->{balance} += $ca->{amount};
    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $form->{balance} * $ml, $form->{precision}, 0)."</td>";

    $subtotaldebit += $ca->{debit};
    $subtotalcredit += $ca->{credit};
    
    $totaldebit += $ca->{debit};
    $totalcredit += $ca->{credit};
    
    $column_data{transdate} = qq|<td nowrap>$ca->{transdate}</td>|;
    $column_data{reference} = qq|<td>$href</td>|;

    if ($ca->{vc_id}) {
      $href = "<a href=ct.pl?path=$form->{path}&action=edit&id=$ca->{vc_id}&db=$ca->{db}&login=$form->{login}&callback=$form->{callback}>$ca->{description}</a>";
      $column_data{description} = qq|<td>$href</td>|;
    } else {
      $column_data{description} = qq|<td>$ca->{description}&nbsp;</td>|;
    }
    
    $column_data{cleared} = ($ca->{cleared}) ? qq|<td>*</td>| : qq|<td>&nbsp;</td>|;
    $column_data{source} = qq|<td>$ca->{source}&nbsp;</td>|;
    
    $column_data{accno} = qq|<td>|;
    for (@{ $ca->{accno} }) { $column_data{accno} .= "<a href=$drilldown&accno=$_>$_</a> " }
    $column_data{accno} .= qq|&nbsp;</td>|;
  
    if ($ca->{id} != $sameid) {
      $i++; $i %= 2;
    }
    $sameid = $ca->{id};

    print qq|
        <tr class=listrow$i>
|;

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
        </tr>
|;

  }
 

  if ($form->{l_subtotal} eq 'Y') {
    &ca_subtotal;
  }
 

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $column_data{debit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totaldebit, $form->{precision}, "&nbsp;")."</th>";
  $column_data{credit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totalcredit, $form->{precision}, "&nbsp;")."</th>";
  $column_data{balance} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $form->{balance} * $ml, $form->{precision}, 0)."</th>";

  print qq|
	<tr class=listtotal>
|;

  for (@column_index) { print "$column_data{$_}\n" }
  
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


sub ca_subtotal {

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $column_data{debit} = "<th align=right class=listsubtotal>".$form->format_amount(\%myconfig, $subtotaldebit, $form->{precision}, "&nbsp;") . "</th>";
  $column_data{credit} = "<th align=right class=listsubtotal>".$form->format_amount(\%myconfig, $subtotalcredit, $form->{precision}, "&nbsp;") . "</th>";
       
  $subtotaldebit = 0;
  $subtotalcredit = 0;

  $sameitem = $ca->{$form->{sort}};

  print qq|
      <tr class=listsubtotal>
|;

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
      </tr>
|;

}

