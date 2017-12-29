#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# voucher/batch register
#
#======================================================================

use SL::VR;

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


sub add_batch {

  $form->header;

  $transdate = qq|
 	<tr>
	  <th align=right nowrap>|.$locale->text('Posting Date').qq|</th>|;

  if ($form->{batchnumber}) {
    $focus = "batchnumber";
    
    $batchnumber = qq|
 	<tr>
	  <th align=right nowrap>|.$locale->text('Batch Number').qq|</th>
	  <td>$form->{batchnumber}</td>
	</tr>
|;

    $transdate .= qq|
	  <td>$form->{transdate}</td>
	</tr>
|
    .$form->hide_form(qw(transdate));

  } else {
    $focus = "batchdescription";
    
    $transdate .= qq|
	  <td><input name=transdate size=11 class=date title="$myconfig{'dateformat'}" value=$form->{transdate}>|.&js_calendar("main", "transdate").qq|</td>
	</tr>
|;
  }
  
  &calendar;
  
  print qq|
<body onload="document.main.${focus}.focus()" />

<form method="post" name="main" action="$form->{script}" />

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        $batchnumber
	<tr>
	  <th align=right nowrap>|.$locale->text('Description').qq|</th>
	  <td><input name=batchdescription size=40 value="|.$form->quote($form->{batchdescription}).qq|"></td>
	</tr>
	$transdate
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=action value=continue>

<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  $form->hide_form(qw(path login nextsub type batch batchid batchnumber callback));
 
  print qq|
</form>

</body>
</html>
|;

}


sub add_payable_batch { &payable_batch };

sub payable_batch {

  $form->{type} = "transaction";
  $form->{batch} = "ap";
  $form->{title} = $locale->text('Add Payable Batch');

  $form->{script} = "ap.pl";
  $form->{nextsub} = "add";
 
  $form->helpref("payable_batch", $myconfig{countrycode});
  
  &add_batch;

}


sub add_general_ledger_batch { &general_ledger_batch };

sub general_ledger_batch {

  $form->{type} = "transaction";
  $form->{batch} = "gl";
  $form->{title} = $locale->text('Add General Ledger Batch');

  $form->{script} = "gl.pl";
  $form->{nextsub} = "add";

  $form->helpref("gl_batch", $myconfig{countrycode});
  
  &add_batch;

}


sub add_payment_batch { &payment_batch };

sub payment_batch {

  $form->{type} = "check";
  $form->{batch} = "payment";
  $form->{title} = $locale->text('Add Payment Batch');
  $form->{script} = "cp.pl";
  $form->{nextsub} = "payment";
  
  $form->helpref("payment_batch", $myconfig{countrycode});
  
  &add_batch;

}


sub add_payments_batch { &payments_batch };

sub payments_batch {

  $form->{callback} = "$form->{script}?action=add_payments_batch&batch=payment&path=$form->{path}&login=$form->{login}";
  
  $form->{type} = "check";
  $form->{batch} = "payment";
  $form->{title} = $locale->text('Add Payments Batch');
  $form->{script} = "cp.pl";
  $form->{nextsub} = "payments";
  
  $form->helpref("payments_batch", $myconfig{countrycode});
  
  &add_batch;

}


sub add_payment_reversal_batch { &payment_reversal_batch };

sub payment_reversal_batch {

  $form->{title} = $locale->text('Add Payment Reversal Batch');

  $form->{script} = "vr.pl";
  $form->{nextsub} = "edit_payment_reversal";
  $form->{batch} = "payment_reversal";

  $form->helpref("payment_reversal", $myconfig{countrycode});

  &add_batch;

}


sub edit_payment_reversal {

  VR->payment_reversal(\%myconfig, \%$form);

  $form->{memo} ||= $locale->text('Payment Reversal');

  if (@{ $form->{all_accounts} }) {
    for (@{ $form->{all_accounts} }) { $form->{selectaccount} .= qq|$_->{accno}--$_->{description}\n| }
  } else {
    $form->error($locale->text('Payment account missing!'));
  }

  $form->{source} = $form->quote($form->{source});
 
  $form->{transdate} ||= $form->current_date(\%myconfig);

  $form->{title} = $locale->text('Payment Reversal Voucher');
  if ($form->{batchdescription}) {
    $form->{title} .= " / $form->{batchdescription}";
  }

  $form->helpref("payment_reversal", $myconfig{countrycode});

  $form->header;
  
  print qq|
<body onload="document.main.account.focus()" />

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Date').qq|</th>
	  <td>$form->{transdate}</td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Account').qq|</th>
	  <td><select name=account>|
	  .$form->select_option($form->{selectaccount}, $form->{$form->{account}}).qq|</select>
	  </td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Source').qq|</th>
	  <td><input name=source value="$form->{source}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Memo').qq|</th>
	  <td><input name=memo value="$form->{memo}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  if (! $form->{id}) {
    $form->{callback} = "$form->{script}?action=edit_payment_reversal";
    for (qw(transdate memo path login batch batchid batchnumber)) {
      $form->{callback} .= "&$_=$form->{$_}";
      $form->{callback} .= "&batchdescription=".$form->escape($form->{batchdescription},1);
    }
  }
 
  $form->hide_form(qw(id vouchernumber transdate memo path login batch batchid batchnumber batchdescription callback));
  
  %button = ('Delete' => { ndx => 1, key => 'D', value => $locale->text('Delete') },
             'Post' => { ndx => 6, key => 'O', value => $locale->text('Post') },
            );

  delete $button{'Delete'} unless $form->{id};

  $form->print_button(\%button);
  
  print qq|
</form>

</body>
</html>
|;

}


sub post {

  $form->isblank("source", $locale->text('Source missing!'));

  if (VR->post_payment_reversal(\%myconfig, \%$form)) {
    # add batch to callback
    $form->{callback} =~ s/(batch|batchid|batchdescription)=.*?&//g;
    $form->{callback} .= "&batch=$form->{batch}&batchid=$form->{batchid}&batchdescription=".$form->escape($form->{batchdescription},1);

    $form->redirect($locale->text('Voucher posted!'));
  } else {
    $form->error($locale->text('Cannot post voucher!'));
  }

}


sub yes { &{ "$form->{nextsub}" } }


sub delete {

  if (VR->delete_payment_reversal(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Voucher deleted!'));
  } else {
    $form->error($locale->text('Cannot delete voucher!'));
  }
  
}


sub delete_batch {

  $form->{title} = $locale->text('Confirm!');
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->{action} = "yes";
  $form->{nextsub} = "yes_delete_batch";
  delete $form->{callback};
  
  $form->hide_form;

  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|.$locale->text('Are you sure you want to delete Batch').qq| $form->{batchnumber}</h4>

<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>

</body>
</html>
|;

}


sub yes_delete_batch {
  
  $form->{callback} = "$form->{script}?action=search";
  for (qw(path login batch)) {
    $form->{callback} .= "&$_=$form->{$_}";
  }

  if (VR->delete_batch(\%myconfig, \%$form, $spool)) {
    $form->redirect($locale->text('Batch deleted!'));
  } else {
    $form->error($locale->text('Cannot delete batch!'));
  }

}


sub search {

  VR->create_links(\%myconfig, \%$form);
  
  $form->{nextsub} = "list_batches";

  $employeelabel = $locale->text('Employee');
  
  if ($form->{admin}) {
    if (@{ $form->{all_employee} }) {
      $form->{selectemployee} = "<option>\n";
      for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|<option value="|.$form->quote($_->{name}).qq|--$_->{id}">$_->{name}\n| }

      $employee = qq|
	  <tr>
	    <th align=right nowrap>$employeelabel</th>
	    <td colspan=3><select name=employee>$form->{selectemployee}</select></td>
	  </tr>
  |;

    }
  }
  
  $l_employee = qq|<input name="l_employee" class=checkbox type=checkbox value=Y checked> $employeelabel|;

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

  @a = ();
  push @a, qq|<input name="l_runningnumber" class=checkbox type=checkbox value=Y> |.$locale->text('No.');
  push @a, qq|<input name="l_batchid" class=checkbox type=checkbox value=Y> |.$locale->text('ID');
  push @a, qq|<input name="l_batchnumber" class=checkbox type=checkbox value=Y checked> |.$locale->text('Batch Number');
  push @a, qq|<input name="l_description" class=checkbox type=checkbox value=Y checked> |.$locale->text('Description');
  push @a, qq|<input name="l_amount" class=checkbox type=checkbox value=Y checked> |.$locale->text('Total');
  push @a, qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked> |.$locale->text('Posting Date');
  push @a, qq|<input name="l_apprdate" class=checkbox type=checkbox value=Y> |.$locale->text('Approved');
  push @a, $l_employee;

  %title = ( '' => 'All Batches',
             ap => 'Payable Batches',
             gl => 'General Ledger Batches',
	     payment => 'Payment Batches',
	     payment_reversal => 'Payment Reversal Batches'
	   );

# $locale->text('All Batches')
# $locale->text('Payable Batches')
# $locale->text('General Ledger Batches')
# $locale->text('Payment Batches')
# $locale->text('Payment Reversal Batches')

  $form->{title} = $locale->text($title{$form->{batch}});

  if ($form->{batch}) {
    $form->helpref("$form->{batch}_batch", $myconfig{countrycode});
  } else {
    $form->helpref("all_batch", $myconfig{countrycode});
  }
  
  $form->header;
  
  &calendar;

  print qq|
<body>

<form method="post" name="main" action="$form->{script}" />

<table width=100%>
  <tr><th class=listtop>$form->{helpref}$form->{title}</a></th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right>|.$locale->text('Batch Number').qq|</th>
	  <td colspan=3><input name=batchnumber></td>
	</tr>
        <tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td colspan=3><input name=description size=40></td>
	</tr>
	$employee
	<tr>
	  <th align=right nowrap>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=transdatefrom size=11 class=date title="$myconfig{dateformat}">|.&js_calendar("main", "transdatefrom").qq|<b>|.$locale->text('To').qq|</b> <input name=transdateto size=11 class=date title="$myconfig{dateformat}">|.&js_calendar("main", "transdateto").qq|</td>
	</tr>
	$selectfrom
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table width=100%>
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
		<td nowrap><input name="l_subtotal" class=checkbox type=checkbox value=Y> |.$locale->text('Subtotal').qq|</td>
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
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
|;

  $form->{sort} = "batchnumber";
  $form->{action} = $form->{nextsub};
  
  $form->hide_form(qw(title sort helpref action batch nextsub path login));
  
  print qq|
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


sub list_batches {

  VR->list_batches(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_batches";
  for (qw(direction oldsort path login batch)) { $href .= qq|&$_=$form->{$_}| }
  $href .= "&title=".$form->escape($form->{title});
  $href .= "&helpref=".$form->escape($form->{helpref});

  $form->sort_order();
  
  $callback = "$form->{script}?action=list_batches";
  for (qw(direction oldsort path login batch)) { $callback .= qq|&$_=$form->{$_}| }
  $callback .= "&title=".$form->escape($form->{title},1);
  $callback .= "&helpref=".$form->escape($form->{helpref},1);

  $option = "";
  
  if ($form->{employee}) {
    $callback .= "&employee=".$form->escape($form->{employee},1);
    $href .= "&employee=".$form->escape($form->{employee});
    ($employee) = split /--/, $form->{employee};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Employee');
    $option .= " : $employee";
  }

  if ($form->{batchnumber}) {
    $callback .= "&batchnumber=".$form->escape($form->{batchnumber},1);
    $href .= "&batchnumber=".$form->escape($form->{batchnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Batch Number')." : $form->{batchnumber}";
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $href .= "&description=".$form->escape($form->{description});
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Description')." : $form->{description}";
  }
  
  if ($form->{transdatefrom}) {
    $callback .= "&transdatefrom=$form->{transdatefrom}";
    $href .= "&transdatefrom=$form->{transdatefrom}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{transdatefrom}, 1);
  }
  if ($form->{transdateto}) {
    $callback .= "&transdateto=$form->{transdateto}";
    $href .= "&transdateto=$form->{transdateto}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{transdateto}, 1);
  }

  @columns = $form->sort_columns(qw(batchid batchnumber description transdate employee apprdate amount));
  unshift @columns, "runningnumber";

  @column_index = (qw(ndx));
  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      # add column to href and callback
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }

  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
    $href .= "&l_subtotal=Y";
  }

  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $action = ($form->{deselect}) ? "deselect_all" : "select_all";
  $column_header{runningnumber} = qq|<th class=listheading>&nbsp;</th>|;
  $column_header{ndx} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); javascript:main.submit()"><input type=hidden name=action value="$action"></th>|;
  $column_header{batchid} = "<th><a class=listheading href=$href&sort=id>".$locale->text('ID')."</a></th>";
  $column_header{transdate} = "<th><a class=listheading href=$href&sort=transdate>".$locale->text('Posting Date')."</a></th>";
  $column_header{apprdate} = "<th><a class=listheading href=$href&sort=apprdate>".$locale->text('Approved')."</a></th>";
  $column_header{batchnumber} = "<th><a class=listheading href=$href&sort=batchnumber>".$locale->text('Batch Number')."</a></th>";
  $column_header{amount} = "<th class=listheading>" . $locale->text('Total') . "</th>";
  $column_header{description} = "<th><a class=listheading href=$href&sort=description>".$locale->text('Description')."</a></th>";
  $column_header{employee} = "<th><a class=listheading href=$href&sort=employee>".$locale->text('Employee')."</th>";
  
  $title = "$form->{title} / $form->{company}";
  
  $form->header;

  &check_all(qw(allbox checked_));

  print qq|
<body>

<form method=post name=main action="$form->{script}">

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
  
  
  if (@{ $form->{transactions} }) {
    $sameitem = $form->{transactions}->[0]->{$form->{sort}};
  }
  
  $i = 0;
  foreach $ref (@{ $form->{transactions} }) {

    $i++;
    
    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&subtotal;
	$sameitem = $ref->{$form->{sort}};
      }
    }

    $checked = ($form->{"checked_$i"}) ? "checked" : "";

    $column_data{runningnumber} = "<td align=right>$i</td>";

    for (qw(batch batchnumber description)) { $form->{"${_}_$i"} = $ref->{$_} }
    $form->hide_form(map { "${_}_$i" } qw(batch batchnumber description));

    if ($ref->{apprdate}) {
      $column_data{ndx} = qq|<td><input type=hidden name="batchid_$i" value=$ref->{id}>&nbsp;</td>|;
    } else {
      $column_data{ndx} = qq|<td><input name="checked_$i" class=checkbox type=checkbox $checked></td><input type=hidden name="batchid_$i" value=$ref->{id}>|;
    }

    $column_data{amount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}, "&nbsp;")."</td>";
    
    $subtotalamount += $ref->{amount};
    $totalamount += $ref->{amount};
    
    $column_data{batchnumber} = "<td><a href=$form->{script}?action=list_vouchers&batchid=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{batchnumber}</a></td>";

    for (qw(description)) { $ref->{$_} =~ s/\r?\n/<br>/g }
    for (qw(transdate apprdate)) { $column_data{$_} = "<td nowrap>$ref->{$_}&nbsp;</td>" }
    for (qw(description employee)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
    for (qw(id)) { $column_data{$_} = "<td>$ref->{$_}</td>" }

    if ($ref->{id} != $sameid) {
      $j++; $j %= 2;
    }

    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;
    $sameid = $ref->{id};
  }

  $form->{rowcount} = $i;

  if ($form->{l_subtotal} eq 'Y') {
    &subtotal;
    $sameitem = $ref->{$form->{sort}};
  }

  # print totals
  print qq|
        <tr class=listtotal>
|;

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $column_data{amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount, $form->{precision}, "&nbsp;")."</th>";

  for (@column_index) { print "\n$column_data{$_}" }

  if ($myconfig{acs} !~ /Vouchers--Vouchers/) {
    %button = ('ap' => { ndx => 2, key => 'A', value => $locale->text('Add Payable Batch') },
              'gl' => { ndx => 3, key => 'G', value => $locale->text('Add General Ledger Batch') },
              'payment' => { ndx => 4, key => 'P', value => $locale->text('Add Payment Batch') },
              'payment_reversal' => { ndx => 5, key => 'P', value => $locale->text('Add Payment Reversal Batch') }
	      );
    
    if ($form->{batch}) {
      $b{$form->{batch}} = $button{$form->{batch}};
      %button = %b;
    }

    if ($form->{deselect}) {
      $button{'Deselect all'} = { ndx => 1, key => 'S', value => $locale->text('Deselect all') };
    } else {
      $button{'Select all'} = { ndx => 1, key => 'S', value => $locale->text('Select all') };
    }
    
    $button{'Post Batches'} = { ndx => 5, key => 'O', value => $locale->text('Post Batches') };
      
    for (split /;/, $myconfig{acs}) {
      ($module, $function) = split /--/, $_;
      delete $button{$function} if $myconfig{acs} =~ /$_/;
    }
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
|;

  $form->hide_form(qw(helpref callback path login rowcount));
  
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


sub subtotal {

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $column_data{amount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount, $form->{precision}, "&nbsp;")."</th>";

  $subtotalamount = 0;
 
  print "<tr class=listsubtotal>";

  for (@column_index) { print "\n$column_data{$_}" }

print "
</tr>
";
 
}


sub list_vouchers {

  VR->list_vouchers(\%myconfig, \%$form);
  
  $href = "$form->{script}?action=list_vouchers";
  for (qw(batchid direction oldsort path login)) { $href .= qq|&$_=$form->{$_}| }

  $form->sort_order();
  
  $callback = "$form->{script}?action=list_vouchers";
  for (qw(direction batchid oldsort path login)) { $callback .= qq|&$_=$form->{$_}| }


# $locale->text('Payable Vouchers')
# $locale->text('General Ledger Vouchers')
# $locale->('Payment Vouchers')
# $locale->('Payment Reversal Vouchers')

  if (@{ $form->{transactions} }) {
    $sameitem = $form->{transactions}->[0]->{$form->{sort}};
  }

  %title = ( ap => 'Payable Vouchers',
             gl => 'General Ledger Vouchers',
	     payment => 'Payment Vouchers',
	     payment_reversal => 'Payment Reversal Vouchers'
	   );
  
  $form->{title} = $locale->text($title{$form->{batch}});
  
  %module = ( ap => 'ap',
              gl => 'gl',
	      payment => 'cp',
	      payment_reversal => 'vr'
	    );

  @columns = qw(vouchernumber);
 
  if ($form->{batch} eq 'ap') {
    $form->{vc} = "vendor";
    $vcnumber = $locale->text('Vendor Number');
    push @columns, ("invnumber", "$form->{vc}number", "name");
  }
  if ($form->{batch} eq 'gl') {
    push @columns, ("invnumber", "name");
  }
  if ($form->{batch} eq 'payment') {
    $form->{vc} = "vendor";
    $form->{type} = 'check';
    $vcnumber = $locale->text('Vendor Number');
    push @columns, ("$form->{vc}number", "name");
  }
  if ($form->{batch} eq 'payment_reversal') {
    $form->{vc} = "vendor";
    $vcnumber = $locale->text('Vendor Number');
    push @columns, ("source", "$form->{vc}number", "name");
  }
  push @columns, qw(amount);
  
  @column_index = $form->sort_columns(@columns);
  unshift @column_index, "runningnumber";
  
  # add sort and escape callback, this one we use for the add sub
  $form->{callback} = $callback .= "&sort=$form->{sort}";
  
  # escape callback for href
  $callback = $form->escape($callback);
  
  $title = $form->escape($locale->text('Edit Batch'));
  
  if ($form->{apprdate}) {
    $option .= $locale->text('Batch Number')." : $form->{batchnumber}";
  } else {
    $option = qq|<a href="$form->{script}?action=edit_batch&login=$form->{login}&path=$form->{path}&batchid=$form->{batchid}&batch=$form->{batch}&title=$title&callback=$callback">|.$locale->text('Batch Number')." : $form->{batchnumber}</a>";
  }
  
  $option .= "\n<br>".$locale->text('Description')." : $form->{batchdescription}";
  $option .= "\n<br>".$locale->text('Posting Date')." : $form->{transdate}";

  $column_header{runningnumber} = qq|<th class=listheading>&nbsp;</th>|;
  $column_header{id} = "<th><a class=listheading href=$href&sort=id>".$locale->text('ID')."</a></th>";
  $column_header{vouchernumber} = "<th><a class=listheading href=$href&sort=vouchernumber>".$locale->text('Voucher Number')."</a></th>";
  $column_header{invnumber} = "<th><a class=listheading href=$href&sort=invnumber>".$locale->text('Invoice Number')."</a></th>";
  $column_header{amount} = "<th class=listheading>" . $locale->text('Total') . "</th>";
  $column_header{name} = "<th><a class=listheading href=$href&sort=name>".$locale->text('Vendor')."</a></th>";
  $column_header{"$form->{vc}number"} = "<th><a class=listheading href=$href&sort=$form->{vc}number>$vcnumber</a></th>";
  
  $column_header{source} = "<th><a class=listheading href=$href&sort=source>".$locale->text('Source')."</a></th>";
  
  if ($form->{batch} eq 'gl') {
    $column_header{invnumber} = "<th><a class=listheading href=$href&sort=invnumber>".$locale->text('Reference')."</a></th>";
    $column_header{name} = "<th><a class=listheading href=$href&sort=name>".$locale->text('Description')."</a></th>";
  }
    
 
  $form->helpref("list_vouchers", $myconfig{countrycode});
  
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
	<tr class=listheading>
|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
	</tr>
|;

  $batchdescription = $form->escape($form->{batchdescription},1);

  $i = 0;
  foreach $ref (@{ $form->{transactions} }) {

    $i++;
    
    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&subtotal;
	$sameitem = $ref->{$form->{sort}};
      }
    }

    $column_data{runningnumber} = "<td align=right>$i</td>";

    $column_data{amount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}, "&nbsp;")."</td>";
    
    $subtotalamount += $ref->{amount};
    $totalamount += $ref->{amount};

    if ($form->{readonly}) {
      $column_data{vouchernumber} = "<td>$ref->{vouchernumber}</td>";
    } else {
      $column_data{vouchernumber} = qq|<td><a href=$module{$form->{batch}}.pl?action=edit&transdate=$form->{transdate}&type=$form->{type}&batch=$form->{batch}&batchid=$form->{batchid}&id=$ref->{id}&$form->{vc}_id=$ref->{"$form->{vc}_id"}&path=$form->{path}&login=$form->{login}&callback=$callback&batchdescription=$batchdescription>$ref->{vouchernumber} </a></td>|;
    }
    
    for (qw(id invnumber)) { $column_data{$_} = "<td>$ref->{$_}</td>" }
    $column_data{name} = "<td>$ref->{name}&nbsp;</td>";
    $column_data{source} = "<td>$ref->{source}&nbsp;</td>";
    $column_data{"$form->{vc}number"} = qq|<td>$ref->{"$form->{vc}number"}&nbsp;</td>|;

    if ($ref->{id} != $sameid) {
      $j++; $j %= 2;
    }

    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;
    $sameid = $ref->{id};
  }

  if ($form->{l_subtotal} eq 'Y') {
    &subtotal;
    $sameitem = $ref->{$form->{sort}};
  }

  # print totals
  print qq|
        <tr class=listtotal>
|;

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $column_data{amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount, $form->{precision}, "&nbsp;")."</th>";

  for (@column_index) { print "\n$column_data{$_}" }

  if (! $form->{readonly}) {
    if ($myconfig{acs} !~ /Vouchers--Vouchers/) {
      
      if (! $form->{apprdate}) {
	$button{'Add Voucher'} = { ndx => 1, key => 'A', value => $locale->text('Add Voucher') };
	if ($form->{admin}) {
	  $button{'Post Batch'} = { ndx => 2, key => 'O', value => $locale->text('Post Batch') };
	}
      }
      
      $button{'Delete Batch'} = { ndx => 3, key => 'D', value => $locale->text('Delete Batch') };
	
      for (split /;/, $myconfig{acs}) {
	($module, $function) = split /--/, $_;
	delete $button{$function} if $myconfig{acs} =~ /$_/;
      }
    }
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

  $form->hide_form(qw(transdate batchid batchnumber batchdescription batch callback path login));
  
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


sub edit {

  # payment reversal
  &edit_payment_reversal;

}


sub edit_batch {

  $form->{nextsub} = "save_batch";

  VR->edit_batch(\%myconfig, \%$form);

  &add_batch;

}


sub save_batch {

  if (VR->save_batch(\%myconfig, \%$form)) {
    $form->redirect;
  } else {
    $form->error($locale->text('Cannot save Batch'));
  }

}
  

sub add_voucher {

  %module = ( ap => 'ap',
              payment => 'cp',
	      gl => 'gl',
	      payment_reversal => 'vr'
	    );
  
  %sub = ( ap => 'add',
           gl => 'add',
	   payment => 'payment',
	   payment_reversal => 'edit_payment_reversal'
	 );

  %type = ( ap => 'transaction',
            gl => 'transaction',
	    payment => 'check',
	  );
  
  $form->{type} = $type{$form->{batch}};
  
  $form->{callback} = "$module{$form->{batch}}.pl?action=$sub{$form->{batch}}";
  for (qw(path login transdate nextsub type batch batchid)) {
    $form->{callback} .= "&$_=$form->{$_}";
  }
  $form->{callback} .= "&batchdescription=".$form->escape($form->{batchdescription},1);

  $form->redirect;
  
}


sub post_batches {

  $SIG{INT} = 'IGNORE';

  for $i (1 .. $form->{rowcount}) {
    if ($form->{"checked_$i"}) {
      $ok = 1;
      $form->{batchid} = $form->{"batchid_$i"};
      $form->{batch} = $form->{"batch_$i"};
	
      $form->info($locale->text('Posting Batch').qq| $form->{"batchnumber_$i"}|);
      if (VR->post_batch(\%myconfig, \%$form)) {
	$form->info(" ... ".$locale->text('ok')."\n");
      } else {
	$form->error($locale->text('Batch Posting failed!'));
      }
    }
  }

  $form->{callback} .= "&header=1" if $ok;
  $form->redirect;

}


sub post_batch {

  $form->{callback} = "$form->{script}?action=search";
  for (qw(path login batch)) {
    $form->{callback} .= "&$_=$form->{$_}";
  }
  
  if (VR->post_batch(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Batch posted!'));
  } else {
    $form->error($locale->text('Batch Posting failed!'));
  }

}


sub select_all {

  for (1 .. $form->{rowcount}) { $form->{callback} .= "&checked_$_=1" }
  $form->{callback} .= "&allbox=checked&deselect=1";
  
  $form->redirect;

}


sub deselect_all {

  $form->redirect;

}


sub continue { &{ $form->{nextsub} } };

