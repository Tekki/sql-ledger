#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Account reconciliation module
#
#======================================================================

use SL::RC;

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


sub reconciliation {
  
  RC->paymentaccounts(\%myconfig, \%$form);

  $selectaccno = "";
  for (@{ $form->{PR} }) { $selectaccno .= "$_->{accno}--$_->{description}\n" }

  $form->{title} = $locale->text('Reconciliation');

  if ($form->{report}) {
    $form->{title} = $locale->text('Reconciliation Report');
    $form->{report} = 1;
  }

  if (@{ $form->{all_years} }) {
    # accounting years
    $selectaccountingyear = "\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|$_\n| }
    $selectaccountingmonth = "\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|$_--| . $locale->text($form->{all_month}{$_}).qq|\n| }

    $form->{interval} = "1" unless exists $form->{interval};
    $checked{"$form->{interval}"} = "checked";
    
    $selectfrom = qq|
        <tr>
	  <th align=right>|.$locale->text('Period').qq|</th>
	  <td colspan=3>
	  <select name=month>|.$form->select_option($selectaccountingmonth, $form->{month}, 1, 1).qq|</select>
	  <select name=year>|.$form->select_option($selectaccountingyear, $form->{year}).qq|</select>
	  <input name=interval class=radio type=radio value=0 $checked{0}>&nbsp;|.$locale->text('Current').qq|
	  <input name=interval class=radio type=radio value=1 $checked{1}>&nbsp;|.$locale->text('Month').qq|
	  <input name=interval class=radio type=radio value=3 $checked{3}>&nbsp;|.$locale->text('Quarter').qq|
	  <input name=interval class=radio type=radio value=12 $checked{12}>&nbsp;|.$locale->text('Year').qq|
	  </td>
	</tr>
|;
  }

  %checked = ();
  $form->{summary} = "1" unless exists $form->{summary};
  $checked{"$form->{summary}"} = "checked";

  $form->{fx_transaction} = "checked" unless exists $form->{fx_transaction};

  $form->helpref("reconciliation", $myconfig{countrycode});
  
  $form->header;

  &calendar;
  
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
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Account').qq|</th>
	  <td colspan=3><select name=accno>|.$form->select_option($selectaccno, $form->{accno}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=fromdate size=11 class=date title="$myconfig{dateformat}" value="$form->{fromdate}"> |.&js_calendar("main", "fromdate").qq|<b>|.$locale->text('To').qq|</b> <input name=todate size=11 class=date title="$myconfig{dateformat}" value="$form->{todate}">|.&js_calendar("main", "todate").qq|</td>
	</tr>
	$selectfrom
        <tr>
	  <td></td>
	  <td colspan=3><input type=radio style=radio name=summary value=1 $checked{1}> |.$locale->text('Summary').qq|
	  <input type=radio style=radio name=summary value=0 $checked{0}> |.$locale->text('Detail').qq|</td>
	</tr>
	<tr>
	  <td></td>
	  <td colspan=3><input type=checkbox class=checkbox name=fx_transaction value=1 $form->{fx_transaction}> |.$locale->text('Include Exchange Rate Difference').qq|</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=hidden name=nextsub value=get_payments>
|;

  $form->hide_form(qw(report path login));

  print qq|
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


sub continue { &{ $form->{nextsub} } };


sub get_payments {

  ($form->{accno}, $form->{account}) = split /--/, $form->{accno};

  RC->payment_transactions(\%myconfig, \%$form);
  
  $ml = ($form->{category} eq 'A') ? -1 : 1;
  $form->{statementbalance} = $form->{endingbalance} * $ml;
  if (! $form->{fx_transaction}) {
    $form->{statementbalance} = ($form->{endingbalance} - $form->{fx_endingbalance}) * $ml;
  }
  
  $form->{statementbalance} = $form->format_amount(\%myconfig, $form->{statementbalance}, $form->{precision}, 0);
  
  &display_form;

}


sub display_form {
  
  if ($form->{report}) {
    @column_index = qw(transdate source name debit credit);
  } else {
    @column_index = qw(transdate source name cleared debit credit balance);
  }
  
  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $action = ($form->{deselect}) ? "deselect_all" : "select_all";
  $column_header{cleared} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); javascript:document.main.submit()"><input type=hidden name=action value="$action"></th>|;
  $column_header{source} = "<th class=listheading>".$locale->text('Source')."</a></th>";
  $column_header{name} = "<th class=listheading>".$locale->text('Description')."</a></th>";
  $column_header{transdate} = "<th class=listheading>".$locale->text('Date')."</a></th>";

  $column_header{debit} = "<th class=listheading>".$locale->text('Debit')."</a></th>";
  $column_header{credit} = "<th class=listheading>".$locale->text('Credit')."</a></th>";
  $column_header{balance} = "<th class=listheading>".$locale->text('Balance')."</a></th>";

  if ($form->{fromdate}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{fromdate}, 1);
  }
  if ($form->{todate}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{todate}, 1);
  }

  $form->{title} = "$form->{accno}--$form->{account} / $form->{company}";
  
  $form->helpref("rec_list", $myconfig{countrycode});
  
  $form->header;
  
  &check_all(qw(allbox checked_));
  
  print qq|
<body>

<form method=post name=main action=$form->{script}>

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
	<tr class=listheading>
|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
        </tr>
|;

  $ml = ($form->{category} eq 'A') ? -1 : 1;
  $form->{beginningbalance} *= $ml;
  $form->{fx_balance} *= $ml;
  
  if (! $form->{fx_transaction}) {
    $form->{beginningbalance} -= $form->{fx_balance};
  }
  $balance = $form->{beginningbalance};
  
  $i = 0;
  $j = 0;
  
  for (qw(cleared transdate source debit credit)) { $column_data{$_} = "<td>&nbsp;</td>" }

  if (! $form->{report}) {
    $column_data{name} = qq|<td>|.$locale->text('Beginning Balance').qq|</td>|;
    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $balance, $form->{precision}, 0)."</td>";
    print qq|
	<tr class=listrow$j>
|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
	</tr>
|;
  }

  $cleared = 0;
  $recdate = $form->datetonum(\%myconfig, $form->{recdate});

  foreach $ref (@{ $form->{PR} }) {

    $i++;

    if (! $form->{fx_transaction}) {
      next if $ref->{fx_transaction};
    }

    $checked = "";
    if ($ref->{cleared}) {
      if ($form->datetonum(\%myconfig, $ref->{cleared}) <= $recdate) {
	$checked = "checked";
      }
    }

    %temp = ();
    if (!$ref->{fx_transaction}) {
      for (qw(name source transdate)) { $temp{$_} = $ref->{$_} }
    }
      
    $column_data{name} = "<td>";
    for (@{ $temp{name} }) { $column_data{name} .= "$_<br>" }
    $column_data{name} .= "</td>";
    $column_data{source} = qq|<td>$temp{source}&nbsp;</td>
    <input type=hidden name="id_$i" value="$ref->{id}">|;
    
    $column_data{debit} = "<td>&nbsp;</td>";
    $column_data{credit} = "<td>&nbsp;</td>";
    
    $balance += $ref->{amount} * $ml;

    if ($ref->{amount} < 0) {
      
      $totaldebits += $ref->{amount} * -1;

      $column_data{debit} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} * -1, $form->{precision}, "&nbsp;")."</td>";
      
    } else {
      
      $totalcredits += $ref->{amount};

      $column_data{credit} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}, "&nbsp;")."</td>";
      
    }

    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $balance, $form->{precision}, 0)."</td>";

    if ($ref->{fx_transaction}) {

      $column_data{cleared} = ($clearfx) ? qq|<td align=center>*</td>| : qq|<td>&nbsp;</td>|;
      $cleared += $ref->{amount} * $ml if $clearfx;
      
    } else {
      
      if ($form->{report}) {
	
	if ($ref->{cleared}) {
	  $column_data{cleared} = qq|<td align=center>*</td>|;
	  $clearfx = 1;
	} else {
	  $column_data{cleared} = qq|<td>&nbsp;</td>|;
	  $clearfx = 0;
	}
	
      } else {

	$cleared += $ref->{amount} * $ml if $checked;
	$clearfx = ($checked) ? 1 : 0;
	$column_data{cleared} = qq|<td align=center><input name="cleared_$i" type=checkbox class=checkbox value=1 $checked></td>
	<input type=hidden name="source_$i" value="|.$form->quote($ref->{source}).qq|">
	<input type=hidden name="datecleared_$i" value="$ref->{cleared}">
	<input type=hidden name="oldcleared_$i" value="$ref->{oldcleared}">|;
	
      }
    }
    
    $column_data{transdate} = qq|<td nowrap>$temp{transdate}&nbsp;</td>
    <input type=hidden name="transdate_$i" value=$ref->{transdate}>|;

    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>
|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>
|;

  }

  $form->{rowcount} = $i;
  
  # print totals
  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{debit} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totaldebits, $form->{precision}, "&nbsp;")."</th>";
  $column_data{credit} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalcredits, $form->{precision}, "&nbsp;")."</th>";
   
  print qq|
	<tr class=listtotal>
|;

  for (@column_index) { print "\n$column_data{$_}" }
 
  $form->{statementbalance} = $form->parse_amount(\%myconfig, $form->{statementbalance});
  $difference = $form->format_amount(\%myconfig, $form->{beginningbalance} + $cleared - $form->{statementbalance}, $form->{precision}, 0);
  $form->{statementbalance} = $form->format_amount(\%myconfig, $form->{statementbalance}, $form->{precision}, 0);

  print qq|
	</tr>
      </table>
    </td>
  </tr>
|;

  
  if ($form->{report}) {

    print qq|
    </tr>
  </table>
|;

  } else {
    
    print qq|
   
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Reconciliation Date').qq|</th>
		<td width=10%></td>
		<td align=right>$form->{recdate}</td>
	      </tr>
	    </table>
	  </td>

	  <td align=right>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Statement Balance').qq|</th>
		<td width=10%></td>
		<td align=right><input name=statementbalance class="inputright" size=11 value=$form->{statementbalance}></td>
	      </tr>

	      <tr>
		<th align=right nowrap>|.$locale->text('Difference').qq|</th>
		<td width=10%></td>
		<td align=right><input name=null class="inputright" size=11 value=$difference></td>
		<input type=hidden name=difference value=$difference>
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

    $form->hide_form(qw(recdate fx_transaction summary rowcount accno account fromdate todate month year interval path login));
    
    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
	       'Select all' => { ndx => 2, key => 'A', value => $locale->text('Select all') },
	       'Deselect all' => { ndx => 3, key => 'A', value => $locale->text('Deselect all') },
	       'Done' => { ndx => 4, key => 'O', value => $locale->text('Done') },
	      );

    if ($form->{deselect}) {
      delete $button{'Select all'};
    } else {
      delete $button{'Deselect all'};
    }
  
    $form->print_button(\%button);
  
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


sub update {
  
  RC->payment_transactions(\%myconfig, \%$form);

  $i = 0;
  foreach $ref (@{ $form->{PR} }) {
    $i++;
    $cleared = ($form->{"datecleared_$i"}) ? $form->{"datecleared_$i"} : $form->{recdate};
    $ref->{cleared} = ($form->{"cleared_$i"}) ? $cleared : "";
  }

  $form->{deselect} = 1 if $form->{allbox};

  &display_form;
  
}


sub select_all {
  
  RC->payment_transactions(\%myconfig, \%$form);

  foreach $ref (@{ $form->{PR} }) {
    $ref->{cleared} = ($form->{"datecleared_$i"}) ? $form->{"datecleared_$i"} : $form->{recdate};
  }

  $form->{deselect} = 1;
  $form->{allbox} = 1;

  &display_form;
  
}


sub deselect_all {
  
  RC->payment_transactions(\%myconfig, \%$form);

  for (@{ $form->{PR} }) { $_->{cleared} = "" }

  $form->{allbox} = "";

  &display_form;
  
}


sub done {

  $form->{callback} = "$form->{script}?path=$form->{path}&action=reconciliation";
  if ($form->{month} && $form->{year}) {
    for (qw(fromdate todate)) { delete $form->{$_} }
  }

  for (qw(login fromdate todate month year interval)) {
    $form->{callback} .= "&$_=$form->{$_}";
  }
  $form->{callback} .= "&accno=".$form->escape("$form->{accno}--$form->{account}",1);

  $form->error($locale->text('Out of balance!')) if ($form->{difference} *= 1);

  RC->reconcile(\%myconfig, \%$form);
  $form->redirect;
  
}


