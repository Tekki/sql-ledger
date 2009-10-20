#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# administration
#
#======================================================================


use SL::AM;
use SL::CA;
use SL::Form;
use SL::User;
use SL::RP;
use SL::GL;

1;
# end of main



sub add { &{ "add_$form->{type}" } };
sub edit { &{ "edit_$form->{type}" } };
sub save { &{ "save_$form->{type}" } };
sub delete { &{ "delete_$form->{type}" } };


sub save_as_new {

  delete $form->{id};

  &save;

}


sub add_account {
  
  $form->{title} = $locale->text('Add Account');
  $form->{charttype} = "A";
  
  $form->{callback} = "$form->{script}?action=list_account&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &account_header;
  &form_footer;
  
}


sub edit_account {
  
  $form->{title} = $locale->text('Edit Account');
  
  $form->{accno} =~ s/\\'/'/g;
  $form->{accno} =~ s/\\\\/\\/g;
 
  AM->get_account(\%myconfig, \%$form);
  
  for (split(/:/, $form->{link})) { $form->{$_} = "checked" }

  &account_header;
  &form_footer;

}


sub account_header {

  my %checked;
  $checked{$form->{charttype}} = "checked";
  $checked{contra} = "checked" if $form->{contra};
  $checked{"$form->{category}_"} = "checked";
  
  for (qw(accno description)) { $form->{$_} = $form->quote($form->{$_}) }

  $form->{type} = "account";
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=account>
|;

  $form->hide_form(qw(id type));
  $form->hide_form(map { "${_}_accno_id" } qw(inventory income expense fxgain fxloss));

  print qq|
<table border=0 width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Account Number').qq| <font color=red>*</font></th>
	  <td><input name=accno size=20 value="|.$form->quote($form->{accno}).qq|"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40 value="|.$form->quote($form->{description}).qq|"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Account Type').qq| <font color=red>*</font></th>
	  <td>
	    <table>
	      <tr valign=top>
		<td><input name=category type=radio class=radio value=A $checked{A_}>&nbsp;|.$locale->text('Asset').qq|<br>
		<input name=category type=radio class=radio value=L $checked{L_}>&nbsp;|.$locale->text('Liability').qq|<br>
		<input name=category type=radio class=radio value=Q $checked{Q_}>&nbsp;|.$locale->text('Equity').qq|<br>
		<input name=category type=radio class=radio value=I $checked{I_}>&nbsp;|.$locale->text('Income').qq|<br>
		<input name=category type=radio class=radio value=E $checked{E_}>&nbsp;|.$locale->text('Expense')
		.qq|</td>
		<td>
		<input name=contra class=checkbox type=checkbox value=1 $checked{contra}>&nbsp;|.$locale->text('Contra').qq|
		</td>
		<td>
		<input name=charttype type=radio class=radio value="H" $checked{H}>&nbsp;|.$locale->text('Heading').qq|<br>
		<input name=charttype type=radio class=radio value="A" $checked{A}>&nbsp;|.$locale->text('Account')
		.qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;


if ($form->{charttype} eq "A") {
  print qq|
	<tr>
	  <td colspan=2>
	    <table>
	      <tr>
		<th align=left>|.$locale->text('Is this a summary account to record').qq|</th>
		<td>
		<input name=AR class=checkbox type=checkbox value=AR $form->{AR}>&nbsp;|.$locale->text('AR')
		.qq|&nbsp;<input name=AP class=checkbox type=checkbox value=AP $form->{AP}>&nbsp;|.$locale->text('AP')
		.qq|&nbsp;<input name=IC class=checkbox type=checkbox value=IC $form->{IC}>&nbsp;|.$locale->text('Inventory')
		.qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
	<tr>
	  <th colspan=2>|.$locale->text('Include in drop-down menus').qq|</th>
	</tr>
	<tr valign=top>
	  <td colspan=2>
	    <table width=100%>
	      <tr>
		<th align=left>|.$locale->text('Receivables').qq|</th>
		<th align=left>|.$locale->text('Payables').qq|</th>
		<th align=left>|.$locale->text('Tracking Items').qq|</th>
		<th align=left>|.$locale->text('Non-tracking Items').qq|</th>
	      </tr>
	      <tr valign=top>
		<td>
		<input name=AR_amount class=checkbox type=checkbox value=AR_amount $form->{AR_amount}>&nbsp;|.$locale->text('Income').qq|<br>
		<input name=AR_paid class=checkbox type=checkbox value=AR_paid $form->{AR_paid}>&nbsp;|.$locale->text('Payment').qq|<br>
		<input name=AR_discount class=checkbox type=checkbox value=AR_discount $form->{AR_discount}>&nbsp;|.$locale->text('Discount').qq|<br>
		<input name=AR_tax class=checkbox type=checkbox value=AR_tax $form->{AR_tax}>&nbsp;|.$locale->text('Tax') .qq|
		</td>
		<td>
		<input name=AP_amount class=checkbox type=checkbox value=AP_amount $form->{AP_amount}>&nbsp;|.$locale->text('Expense/Asset').qq|<br>
		<input name=AP_paid class=checkbox type=checkbox value=AP_paid $form->{AP_paid}>&nbsp;|.$locale->text('Payment').qq|<br>
		<input name=AP_discount class=checkbox type=checkbox value=AP_discount $form->{AP_discount}>&nbsp;|.$locale->text('Discount').qq|<br>
		<input name=AP_tax class=checkbox type=checkbox value=AP_tax $form->{AP_tax}>&nbsp;|.$locale->text('Tax') .qq|
		</td>
		<td>
		<input name=IC_sale class=checkbox type=checkbox value=IC_sale $form->{IC_sale}>&nbsp;|.$locale->text('Income').qq|<br>
		<input name=IC_cogs class=checkbox type=checkbox value=IC_cogs $form->{IC_cogs}>&nbsp;|.$locale->text('COGS').qq|<br>
		<input name=IC_taxpart class=checkbox type=checkbox value=IC_taxpart $form->{IC_taxpart}>&nbsp;|.$locale->text('Tax') .qq|
		</td>
		<td>
		<input name=IC_income class=checkbox type=checkbox value=IC_income $form->{IC_income}>&nbsp;|.$locale->text('Income').qq|<br>
		<input name=IC_expense class=checkbox type=checkbox value=IC_expense $form->{IC_expense}>&nbsp;|.$locale->text('Expense').qq|<br>
		<input name=IC_taxservice class=checkbox type=checkbox value=IC_taxservice $form->{IC_taxservice}>&nbsp;|.$locale->text('Tax') .qq|
		</td>
	      </tr>
	    </table>
	  </td>  
	</tr>  
|;
}

print qq|
        <tr>
	  <th align=right>|.$locale->text('GIFI').qq|</th>
	  <td><input name=gifi_accno size=9 value="|.$form->quote($form->{gifi_accno}).qq|"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub form_footer {

  $form->hide_form(qw(callback path login));

  my %button;
  
  if ($form->{id}) {
    $button{'Save'} = { ndx => 3, key => 'S', value => $locale->text('Save') };
    $button{'Save as new'} = { ndx => 7, key => 'N', value => $locale->text('Save as new') } if $form->{type} ne 'currency';
    
    if ($form->{orphaned}) {
      $button{'Delete'} = { ndx => 16, key => 'D', value => $locale->text('Delete') };
    }
  } else {
    $button{'Save'} = { ndx => 3, key => 'S', value => $locale->text('Save') };
  }

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

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

  
sub save_account {

  $form->isblank("accno", $locale->text('Account Number missing!'));
  $form->isblank("category", $locale->text('Account Type missing!'));
  
  # check for conflicting accounts
  if ($form->{AR} || $form->{AP} || $form->{IC}) {
    my $a = "";
    for (qw(AR AP IC)) { $a .= $form->{$_} }
    $form->error($locale->text('Cannot set account for more than one of AR, AP or IC')) if length $a > 2;

    for (qw(AR_amount AR_tax AR_paid AP_amount AP_tax AP_paid IC_taxpart IC_taxservice IC_sale IC_cogs IC_income IC_expense)) { $form->error("$form->{AR}$form->{AP}$form->{IC} ". $locale->text('account cannot be set to any other type of account')) if $form->{$_} }
  }

  foreach my $item (qw(AR AP)) {
    my $i = 0;
    for ("${item}_amount", "${item}_paid", "${item}_discount", "${item}_tax") { $i++ if $form->{$_} }
    $form->error($locale->text('Cannot set multiple options for')." $item") if $i > 1;
  }
  
  if (AM->save_account(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Account saved!'));
  } else {
    $form->error($locale->text('Cannot save account!'));
  }

}


sub list_account {

  CA->all_accounts(\%myconfig, \%$form);

  $form->{title} = $locale->text('Chart of Accounts');
  
  # construct callback
  my $callback = "$form->{script}?action=list_account&path=$form->{path}&login=$form->{login}";

  my @column_index = qw(accno gifi_accno description debit credit link);

  my %column_data;
  
  $column_data{accno} = qq|<th class=listtop>|.$locale->text('Account').qq|</a></th>|;
  $column_data{gifi_accno} = qq|<th class=listtop>|.$locale->text('GIFI').qq|</a></th>|;
  $column_data{description} = qq|<th class=listtop>|.$locale->text('Description').qq|</a></th>|;
  $column_data{debit} = qq|<th class=listtop>|.$locale->text('Debit').qq|</a></th>|;
  $column_data{credit} = qq|<th class=listtop>|.$locale->text('Credit').qq|</a></th>|;
  $column_data{link} = qq|<th class=listtop>|.$locale->text('Link').qq|</a></th>|;


  $form->header;
  
  my $colspan = $#column_index + 1;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop colspan=$colspan>$form->{title}</th>
  </tr>
  <tr height=5></tr>
  <tr class=listheading>
|;

  for (@column_index) { print "$column_data{$_}\n" }
  
  print qq|
</tr>
|;

  # escape callback
  $callback = $form->escape($callback);
  
  foreach my $ref (@{ $form->{CA} }) {
    
    $ref->{debit} = "&nbsp;";
    $ref->{credit} = "&nbsp;";

    if ($ref->{amount} > 0) {
      $ref->{credit} = $form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}, "&nbsp;");
    }
    if ($ref->{amount} < 0) {
      $ref->{debit} = $form->format_amount(\%myconfig, $ref->{amount} * -1, $form->{precision}, "&nbsp;");
    }

    $ref->{link} =~ s/:/<br>/og;

    my $gifi_accno = $form->escape($ref->{gifi_accno});
    
    if ($ref->{charttype} eq "H") {
      print qq|<tr class=listheading>|;

      $column_data{accno} = qq|<th><a class=listheading href=$form->{script}?action=edit_account&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{accno}</a></th>|;
      $column_data{gifi_accno} = qq|<th class=listheading><a href=$form->{script}?action=edit_gifi&accno=$gifi_accno&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{gifi_accno}</a>&nbsp;</th>|;
      $column_data{description} = qq|<th class=listheading>$ref->{description}&nbsp;</th>|;
      $column_data{debit} = qq|<th>&nbsp;</th>|;
      $column_data{credit} = qq| <th>&nbsp;</th>|;
      $column_data{link} = qq|<th>&nbsp;</th>|;

    } else {
      $i++; $i %= 2;
      print qq|
<tr valign=top class=listrow$i>|;
      $column_data{accno} = qq|<td><a href=$form->{script}?action=edit_account&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{accno}</a></td>|;
      $column_data{gifi_accno} = qq|<td><a href=$form->{script}?action=edit_gifi&accno=$ref->{gifi_accno}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{gifi_accno}</a>&nbsp;</td>|;
      $column_data{description} = qq|<td>$ref->{description}&nbsp;</td>|;
      $column_data{debit} = qq|<td align=right>$ref->{debit}</td>|;
      $column_data{credit} = qq|<td align=right>$ref->{credit}</td>|;
      $column_data{link} = qq|<td>$ref->{link}&nbsp;</td>|;
      
    }

    for (@column_index) { print "$column_data{$_}\n" }
    
    print "</tr>\n";
  }
  
  print qq|
  <tr><td colspan=$colspan><hr size=3 noshade></td></tr>
</table>

</body>
</html>
|;

}


sub delete_account {

  $form->{title} = $locale->text('Delete Account');

  for (qw(inventory_accno_id income_accno_id expense_accno_id fxgain_accno_id fxloss_accno_id)) {
    if ($form->{id} == $form->{$_}) {
      $form->error($locale->text('Cannot delete default account!'));
    }
  }

  if (AM->delete_account(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Account deleted!'));
  } else {
    $form->error($locale->text('Cannot delete account!'));
  }

}


sub list_gifi {

  @{ $form->{fields} } = qw(accno description);
  $form->{table} = "gifi";
  
  AM->gifi_accounts(\%myconfig, \%$form);

  $form->{title} = $locale->text('GIFI');
  
  # construct callback
  my $callback = "$form->{script}?action=list_gifi&path=$form->{path}&login=$form->{login}";

  my @column_index = qw(accno description);

  my %column_data;
  
  $column_data{accno} = qq|<th class=listheading>|.$locale->text('GIFI').qq|</a></th>|;
  $column_data{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</a></th>|;


  $form->header;

  my $colspan = $#column_index + 1;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop colspan=$colspan>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr class=listheading>
|;

  for (@column_index) { print "$column_data{$_}\n" }
  
  print qq|
</tr>
|;

  # escape callback
  $callback = $form->escape($callback);
  
  my $i;
  
  foreach my $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
<tr valign=top class=listrow$i>|;
    
    my $accno = $form->escape($ref->{accno});
    $column_data{accno} = qq|<td><a href=$form->{script}?action=edit_gifi&coa=1&accno=$accno&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{accno}</td>|;
    $column_data{description} = qq|<td>$ref->{description}&nbsp;</td>|;
    
    for (@column_index) { print "$column_data{$_}\n" }
    
    print "</tr>\n";
  }
  
  print qq|
  <tr>
    <td colspan=$colspan><hr size=3 noshade></td>
  </tr>
</table>

</body>
</html>
|;

}


sub add_gifi {
  
  $form->{title} = $locale->text('Add GIFI');
  
  # construct callback
  $form->{callback} = "$form->{script}?action=list_gifi&path=$form->{path}&login=$form->{login}";

  $form->{coa} = 1;
  
  &gifi_header;
  &gifi_footer;
  
}


sub edit_gifi {
  
  $form->{title} = $locale->text('Edit GIFI');
  
  AM->get_gifi(\%myconfig, \%$form);

  $form->error($locale->text('Account does not exist!')) unless $form->{accno};
  
  &gifi_header;
  &gifi_footer;
  
}


sub gifi_header {

  for (qw(accno description)) { $form->{$_} = $form->quote($form->{$_}) }

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value="$form->{accno}">
<input type=hidden name=type value=gifi>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('GIFI').qq|</th>
	  <td><input name=accno size=20 value="|.$form->quote($form->{accno}).qq|"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td><input name=description size=60 value="|.$form->quote($form->{description}).qq|"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub gifi_footer {

  $form->hide_form(qw(callback path login));
  
  my %button;
  
  $button{'Save'} = { ndx => 3, key => 'S', value => $locale->text('Save') };
  
  if ($form->{accno}) {
    if ($form->{orphaned}) {
      $button{'Delete'} = { ndx => 16, key => 'D', value => $locale->text('Delete') };
    }
  }
    
  if ($form->{coa}) {
    $button{'Copy to COA'} = { ndx => 7, key => 'C', value => $locale->text('Copy to COA') };
  }

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

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


sub save_gifi {

  $form->isblank("accno", $locale->text('GIFI missing!'));
  AM->save_gifi(\%myconfig, \%$form);
  $form->redirect($locale->text('GIFI saved!'));

}


sub copy_to_coa {

  $form->isblank("accno", $locale->text('GIFI missing!'));

  AM->save_gifi(\%myconfig, \%$form);

  delete $form->{id};
  $form->{gifi_accno} = $form->{accno};
  
  $form->{title} = "Add";
  $form->{charttype} = "A";
  
  &account_header;
  &form_footer;
  
}


sub delete_gifi {

  AM->delete_gifi(\%myconfig, \%$form);
  $form->redirect($locale->text('GIFI deleted!'));

}


sub add_department {

  $form->{title} = $locale->text('Add Department');
  $form->{role} = "P";
  
  $form->{callback} = "$form->{script}?action=add_department&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &department_header;
  &form_footer;

}


sub edit_department {

  $form->{title} = $locale->text('Edit Department');

  AM->get_department(\%myconfig, \%$form);

  &department_header;
  &form_footer;

}


sub list_department {

  AM->departments(\%myconfig, \%$form);

  my $href = "$form->{script}?action=list_department&direction=$form->{direction}&path=$form->{path}&login=$form->{login}";

  $form->sort_order();
  
  $form->{callback} = "$form->{script}?action=list_department&direction=$form->{direction}&path=$form->{path}&login=$form->{login}";
  
  my $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Departments');

  my @column_index = qw(description cost profit);

  my %column_data;
  
  $column_data{description} = qq|<th width=90%><a class=listheading href=$href>|.$locale->text('Description').qq|</a></th>|;
  $column_data{cost} = qq|<th class=listheading nowrap>|.$locale->text('Cost Center').qq|</th>|;
  $column_data{profit} = qq|<th class=listheading nowrap>|.$locale->text('Profit Center').qq|</th>|;

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

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
|;

  my $i;
  my $costcenter;
  my $profitcenter;
  
  foreach my $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $costcenter = ($ref->{role} eq "C") ? "*" : "&nbsp;";
   $profitcenter = ($ref->{role} eq "P") ? "*" : "&nbsp;";
   
   $column_data{description} = qq|<td><a href=$form->{script}?action=edit_department&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{description}</td>|;
   $column_data{cost} = qq|<td align=center>$costcenter</td>|;
   $column_data{profit} = qq|<td align=center>$profitcenter</td>|;

   for (@column_index) { print "$column_data{$_}\n" }

   print qq|
	</tr>
|;
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

  $form->{type} = "department";
  
  $form->hide_form(qw(type callback path login));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add Department').qq|">|;

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


sub department_header {

  $form->{description} = $form->quote($form->{description});

  my $rows;
  my $description;
  
  if (($rows = $form->numtextrows($form->{description}, 60)) > 1) {
    $description = qq|<textarea name="description" rows=$rows cols=60 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=60 value="|.$form->quote($form->{description}).qq|">|;
  }

  my %checked;
  
  $checked{C} = "checked" if $form->{role} eq "C";
  $checked{P} = "checked" if $form->{role} eq "P";
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=department>

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align=right>|.$locale->text('Description').qq|</th>
    <td>$description</td>
  </tr>
  <tr>
    <td></td>
    <td><input type=radio class=radio name=role value="C" $checked{C}> |.$locale->text('Cost Center').qq|
        <input type=radio class=radio name=role value="P" $checked{P}> |.$locale->text('Profit Center').qq|
    </td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_department {

  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_department(\%myconfig, \%$form);
  $form->redirect($locale->text('Department saved!'));

}


sub delete_department {

  AM->delete_department(\%myconfig, \%$form);
  $form->redirect($locale->text('Department deleted!'));

}


sub add_business {

  $form->{title} = "Add";
  
  $form->{callback} = "$form->{script}?action=add_business&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &business_header;
  &form_footer;

}


sub edit_business {

  $form->{title} = $locale->text('Edit Business');

  AM->get_business(\%myconfig, \%$form);

  &business_header;

  $form->{orphaned} = 1;
  &form_footer;

}


sub list_business {

  AM->business(\%myconfig, \%$form);

  my $href = "$form->{script}?action=list_business&direction=$form->{direction}&path=$form->{path}&login=$form->{login}";

  $form->sort_order();
  
  $form->{callback} = "$form->{script}?action=list_business&direction=$form->{direction}&path=$form->{path}&login=$form->{login}";
  
  my $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Type of Business');

  my @column_index = qw(description discount);

  my %column_data;
  
  $column_data{description} = qq|<th width=90%><a class=listheading href=$href>|.$locale->text('Description').qq|</a></th>|;
  $column_data{discount} = qq|<th class=listheading>|.$locale->text('Discount').qq| %</th>|;

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

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
|;

  my $i;
  my $discount;
  
  foreach my $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $discount = $form->format_amount(\%myconfig, $ref->{discount} * 100, $form->{precision}, "&nbsp");
   
   $column_data{description} = qq|<td><a href=$form->{script}?action=edit_business&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{description}</td>|;
   $column_data{discount} = qq|<td align=right>$discount</td>|;
   
   for (@column_index) { print "$column_data{$_}\n" }

   print qq|
	</tr>
|;
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

  $form->{type} = "business";
  
  $form->hide_form(qw(type callback path login));

  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add Business').qq|">|;

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


sub business_header {

  $form->{description} = $form->quote($form->{description});
  $form->{discount} = $form->format_amount(\%myconfig, $form->{discount} * 100);

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=business>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Type of Business').qq|</th>
	  <td><input name=description size=30 value="|.$form->quote($form->{description}).qq|"></td>
	<tr>
	<tr>
	  <th align=right>|.$locale->text('Discount').qq| %</th>
	  <td><input name=discount size=5 value=$form->{discount}></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_business {

  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_business(\%myconfig, \%$form);
  $form->redirect($locale->text('Business saved!'));

}


sub delete_business {

  AM->delete_business(\%myconfig, \%$form);
  $form->redirect($locale->text('Business deleted!'));

}



sub add_payment_method {

  $form->{title} = "Add Payment Method";
  
  $form->{callback} = "$form->{script}?action=add_payment_method&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &paymentmethod_header;
  &form_footer;

}


sub edit_paymentmethod {

  $form->{title} = $locale->text('Edit Payment Method');

  AM->get_paymentmethod(\%myconfig, \%$form);

  &paymentmethod_header;

  $form->{orphaned} = 1;
  &form_footer;

}


sub list_paymentmethod {

  AM->paymentmethod(\%myconfig, \%$form);

  my $href = "$form->{script}?action=list_paymentmethod&direction=$form->{direction}&path=$form->{path}&login=$form->{login}";

  $form->sort_order();
  
  $form->{callback} = "$form->{script}?action=list_paymentmethod&direction=$form->{direction}&path=$form->{path}&login=$form->{login}";
  
  my $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Method of Payment');

  my @column_index = qw(rn description fee plus minus);

  my %column_data;
  
  $column_data{rn} = qq|<th><a class=listheading href=$href&sort=rn>|.$locale->text('No').qq|</a></th>|;
  $column_data{description} = qq|<th width=90%><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_data{fee} = qq|<th class=listheading>|.$locale->text('Fee').qq|</th>|;
  $column_data{plus} = qq|<th class=listheading>&nbsp;</th>|;
  $column_data{minus} = qq|<th class=listheading>&nbsp;</th>|;
  
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

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
|;

  my $i;
  my $fee;
  
  foreach my $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $fee = $form->format_amount(\%myconfig, $ref->{fee}, $form->{precision}, "&nbsp");
   
   $column_data{rn} = qq|<td align=right>$ref->{rn}</td>|;
   $column_data{description} = qq|<td><a href=$form->{script}?action=edit_paymentmethod&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{description}</td>|;
   $column_data{fee} = qq|<td align=right>$fee</td>|;
   $column_data{plus} = qq|<td><a href=$form->{script}?action=move&db=paymentmethod&fld=id&id=$ref->{id}&move=up&path=$form->{path}&login=$form->{login}&callback=$callback><img src=$images/up.png alt="+" border=0></td>|;
   $column_data{minus} = qq|<td><a href=$form->{script}?action=move&db=paymentmethod&fld=id&id=$ref->{id}&move=down&path=$form->{path}&login=$form->{login}&callback=$callback><img src=$images/down.png alt="-" border=0></td>|;
  
   for (@column_index) { print "$column_data{$_}\n" }

   print qq|
	</tr>
|;
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

  $form->{type} = "paymentmethod";
  
  $form->hide_form(qw(type callback path login));

  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add Payment Method').qq|">|;

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


sub paymentmethod_header {

  $form->{description} = $form->quote($form->{description});
  $form->{fee} = $form->format_amount(\%myconfig, $form->{fee}, $form->{precision});

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=paymentmethod>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Payment Method').qq|</th>
	  <td><input name=description size=30 value="|.$form->quote($form->{description}).qq|"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Fee').qq|</th>
	  <td><input name=fee size=12 value=$form->{fee}></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_paymentmethod {

  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_paymentmethod(\%myconfig, \%$form);
  $form->redirect($locale->text('Payment Method saved!'));

}


sub delete_paymentmethod {

  AM->delete_paymentmethod(\%myconfig, \%$form);
  $form->redirect($locale->text('Payment Method deleted!'));

}


sub add_sic {

  $form->{title} = $locale->text('Add SIC');
  
  $form->{callback} = "$form->{script}?action=add_sic&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &sic_header;
  &form_footer;

}


sub edit_sic {

  $form->{title} = $locale->text('Edit SIC');

  $form->{code} =~ s/\\'/'/g;
  $form->{code} =~ s/\\\\/\\/g;
  
  AM->get_sic(\%myconfig, \%$form);
  $form->{id} = $form->{code};

  &sic_header;

  $form->{orphaned} = 1;
  &form_footer;

}


sub list_sic {

  AM->sic(\%myconfig, \%$form);

  my $href = "$form->{script}?action=list_sic&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}";
  
  $form->sort_order();

  $form->{callback} = "$form->{script}?action=list_sic&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}";
  
  my $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Standard Industrial Codes');

  my @column_index = $form->sort_columns(qw(code description));

  my %column_data;
  
  $column_data{code} = qq|<th><a class=listheading href=$href&sort=code>|.$locale->text('Code').qq|</a></th>|;
  $column_data{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

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

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
|;

  my $i;
  
  foreach my $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    if ($ref->{sictype} eq 'H') {
      print qq|
        <tr valign=top class=listheading>
|;
      $column_data{code} = qq|<th><a href=$form->{script}?action=edit_sic&code=$ref->{code}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{code}</th>|;
      $column_data{description} = qq|<th>$ref->{description}</th>|;
     
    } else {
      print qq|
        <tr valign=top class=listrow$i>
|;

      $column_data{code} = qq|<td><a href=$form->{script}?action=edit_sic&code=$ref->{code}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{code}</td>|;
      $column_data{description} = qq|<td>$ref->{description}</td>|;

   }
    
   for (@column_index) { print "$column_data{$_}\n" }

   print qq|
	</tr>
|;
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

  $form->{type} = "sic";
  
  $form->hide_form(qw(type callback path login));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add SIC').qq|">|;

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


sub sic_header {

  for (qw(code description)) { $form->{$_} = $form->quote($form->{$_}) }

  my %checked;
  $checked{H} = ($form->{sictype} eq 'H') ? "checked" : "";

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=sic>
<input type=hidden name=id value="$form->{code}">

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align=right>|.$locale->text('Code').qq|</th>
    <td><input name=code size=10 value="|.$form->quote($form->{code}).qq|"></td>
  </tr>
  <tr>
    <td></td>
    <th align=left><input name=sictype class=checkbox type=checkbox value="H" $checked{H}> |.$locale->text('Heading').qq|</th>
  </tr>
  <tr>
    <th align=right>|.$locale->text('Description').qq|</th>
    <td><input name=description size=60 value="|.$form->quote($form->{description}).qq|"></td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_sic {

  $form->isblank("code", $locale->text('Code missing!'));
  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_sic(\%myconfig, \%$form);
  $form->redirect($locale->text('SIC saved!'));

}


sub delete_sic {

  AM->delete_sic(\%myconfig, \%$form);
  $form->redirect($locale->text('SIC deleted!'));

}


sub add_language {

  $form->{title} = $locale->text('Add Language');
  
  $form->{callback} = "$form->{script}?action=add_language&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &language_header;
  &form_footer;

}


sub edit_language {

  $form->{title} = $locale->text('Edit Language');

  $form->{code} =~ s/\\'/'/g;
  $form->{code} =~ s/\\\\/\\/g;
  
  AM->get_language(\%myconfig, \%$form);
  $form->{id} = $form->{code};

  &language_header;

  $form->{orphaned} = 1;
  &form_footer;

}


sub list_language {

  AM->language(\%myconfig, \%$form);

  my $href = "$form->{script}?action=list_language&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}";
  
  $form->sort_order();

  $form->{callback} = "$form->{script}?action=list_language&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}";
  
  my $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Languages');

  my @column_index = $form->sort_columns(qw(code description));

  my %column_data;
  
  $column_data{code} = qq|<th><a class=listheading href=$href&sort=code>|.$locale->text('Code').qq|</a></th>|;
  $column_data{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

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

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
|;

  my $i;
  
  foreach my $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;

    print qq|
        <tr valign=top class=listrow$i>
|;

    $column_data{code} = qq|<td><a href=$form->{script}?action=edit_language&code=$ref->{code}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{code}</td>|;
    $column_data{description} = qq|<td>$ref->{description}</td>|;
    
   for (@column_index) { print "$column_data{$_}\n" }

   print qq|
	</tr>
|;
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

  $form->{type} = "language";

  $form->hide_form(qw(type callback path login));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add Language').qq|">|;

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


sub language_header {

  for (qw(code description)) { $form->{$_} = $form->quote($form->{$_}) }

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=language>
<input type=hidden name=id value="$form->{code}">

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align=right>|.$locale->text('Code').qq|</th>
    <td><input name=code size=10 value="$form->{code}"></td>
  </tr>
  <tr>
    <th align=right>|.$locale->text('Description').qq|</th>
    <td><input name=description size=60 value="|.$form->quote($form->{description}).qq|"></td>
  </tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_language {

  $form->isblank("code", $locale->text('Code missing!'));
  $form->isblank("description", $locale->text('Description missing!'));

  $form->{code} =~ s/(\.\.|\*)//g;
  
  AM->save_language(\%myconfig, \%$form);

  if (! -d "$myconfig{templates}/$form->{code}") {
      
    umask(002);
    
    if (mkdir "$myconfig{templates}/$form->{code}", oct("771")) {
      
      umask(007);

      opendir TEMPLATEDIR, "$myconfig{templates}" or $form->error("$myconfig{templates} : $!");
      my @templates = grep !/^(\.|\.\.)/, readdir TEMPLATEDIR;
      closedir TEMPLATEDIR;

      foreach my $file (@templates) {
	if (-f "$myconfig{templates}/$file") {
	  open(TEMP, "$myconfig{templates}/$file") or $form->error("$myconfig{templates}/$file : $!");

	  open(NEW, ">$myconfig{templates}/$form->{code}/$file") or $form->error("$myconfig{templates}/$form->{code}/$file : $!");

	  while (my $line = <TEMP>) {
	    print NEW $line;
	  }
	  close(TEMP);
	  close(NEW);
	}
      }
    } else {
      $form->error("${templates}/$form->{code} : $!");
    }
  }
    
  $form->redirect($locale->text('Language saved!'));

}


sub delete_language {

  $form->{title} = $locale->text('Confirm!');

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  for (qw(action nextsub)) { delete $form->{$_} }
  
  $form->hide_form;

  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|.$locale->text('Deleting a language will also delete the templates for the language').qq| $form->{invnumber}</h4>

<input type=hidden name=action value=continue>
<input type=hidden name=nextsub value=yes_delete_language>
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub yes_delete_language {
  
  AM->delete_language(\%myconfig, \%$form);

  # delete templates
  my $dir = "$myconfig{templates}/$form->{code}";
  if (-d $dir) {
    unlink <$dir/*>;
    rmdir "$myconfig{templates}/$form->{code}";
  }
  $form->redirect($locale->text('Language deleted!'));

}


sub display_stylesheet {
  
  $form->{file} = "css/$myconfig{stylesheet}";
  &display_form;
  
}


sub list_templates {

  AM->language(\%myconfig, \%$form);
  
  if (! @{ $form->{ALL} }) {
    &display_form;
    exit;
  }

  unshift @{ $form->{ALL} }, { code => '.', description => $locale->text('Default Template') };
  
  my $href = "$form->{script}?action=list_templates&direction=$form->{direction}&oldsort=$form->{oldsort}&file=$form->{file}&path=$form->{path}&login=$form->{login}";
  
  $form->sort_order();

  $form->{callback} = "$form->{script}?action=list_templates&direction=$form->{direction}&oldsort=$form->{oldsort}&file=$form->{file}&path=$form->{path}&login=$form->{login}";
  
  my $callback = $form->escape($form->{callback});

  chomp $myconfig{templates};
  $form->{file} =~ s/$myconfig{templates}//;
  $form->{file} =~ s/\///;
  $form->{title} = $form->{file};

  my @column_index = $form->sort_columns(qw(code description));

  my %column_data;
  
  $column_data{code} = qq|<th><a class=listheading href=$href&sort=code>|.$locale->text('Code').qq|</a></th>|;
  $column_data{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

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

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
|;

  my $i;
  
  foreach my $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;

    print qq|
        <tr valign=top class=listrow$i>
|;

    $column_data{code} = qq|<td><a href=$form->{script}?action=display_form&file=$myconfig{templates}/$ref->{code}/$form->{file}&path=$form->{path}&login=$form->{login}&code=$ref->{code}&callback=$callback>$ref->{code}</td>|;
    $column_data{description} = qq|<td>$ref->{description}</td>|;
    
   for (@column_index) { print "$column_data{$_}\n" }

   print qq|
	</tr>
|;
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

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=type value=language>
|;

  $form->hide_form(qw(path login));
  
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


sub display_form {

  $form->{file} =~ s/^(.:)*?\/|\.\.\///g; 
  $form->{file} =~ s/^\/*//g;
  $form->{file} =~ s/$userspath//;
  $form->{file} =~ s/$memberfile//;
  
  $form->error("$!: $form->{file}") unless -f $form->{file};

  AM->load_template(\%$form);

  $form->{title} = $form->{file};

  $form->{body} =~ s/<%include (.*?)%>/<a href=$form->{script}\?action=display_form&file=$myconfig{templates}\/$form->{code}\/$1&path=$form->{path}&login=$form->{login}>$1<\/a>/g;

  # if it is anything but html
  if ($form->{file} !~ /\.html$/) {
    $form->{body} = "<pre>\n$form->{body}\n</pre>";
  }
    
  $form->header;

  print qq|
<body>

$form->{body}

<form method=post action=$form->{script}>
|;

  $form->{type} = "template";

  $form->hide_form(qw(code file type path login));
  
  print qq|
<input name=action type=submit class=submit value="|.$locale->text('Edit').qq|">|;

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


sub edit_template {

  AM->load_template(\%$form);

  $form->{title} = $locale->text('Edit Template');
  # convert &nbsp to &amp;nbsp;
  $form->{body} =~ s/&nbsp;/&amp;nbsp;/gi;
  
  $form->{callback} = "$form->{script}?action=display_form&file=$form->{file}&code=$form->{code}&path=$form->{path}&login=$form->{login}";
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input name=file type=hidden value=$form->{file}>
<input name=type type=hidden value=template>

<textarea name=body rows=25 cols=70>
$form->{body}</textarea>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">|;

  $form->hide_form(qw(path login callback));
  
  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print q|
  </form>

</body>
</html>
|;

}


sub save_template {

  AM->save_template(\%$form);
  $form->redirect($locale->text('Template saved!'));
  
}


sub taxes {
  
  # get tax account numbers
  AM->taxes(\%myconfig, \%$form);

  my $i = 0;
  foreach my $ref (@{ $form->{taxrates} }) {
    $i++;
    $form->{"taxrate_$i"} = $ref->{rate};
    $form->{"taxdescription_$i"} = $ref->{description};
    
    for (qw(taxnumber validto)) { $form->{"${_}_$i"} = $ref->{$_} }
    $form->{taxaccounts} .= "$ref->{id}_$i ";
  }
  chop $form->{taxaccounts};
  
  &display_taxes;

}


sub display_taxes {
  
  $form->{title} = $locale->text('Taxes');
  
  $form->{type} = "taxes";

  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th></th>
	  <th>|.$locale->text('Rate').qq| (%)</th>
	  <th>|.$locale->text('Number').qq|</th>
	  <th>|.$locale->text('Valid To').qq|</th>
	</tr>
|;

  for (split(/ /, $form->{taxaccounts})) {
    
    my ($null, $i) = split /_/, $_;

    $form->{"taxrate_$i"} = $form->format_amount(\%myconfig, $form->{"taxrate_$i"}, undef, 0);
    
    $form->hide_form("taxdescription_$i");
    
    print qq|
	<tr>
	  <th align=right>|;
	  
    if ($form->{"taxdescription_$i"} eq $sametax) {
      print "";
    } else {
      print qq|$form->{"taxdescription_$i"}|;
    }
    
    print qq|</th>
	  <td><input name="taxrate_$i" size=6 value=$form->{"taxrate_$i"}></td>
	  <td><input name="taxnumber_$i" value="$form->{"taxnumber_$i"}"></td>
	  <td><input name="validto_$i" size=11 class=date value="$form->{"validto_$i"}" title="$myconfig{dateformat}"></td>
	</tr>
|;
    my $sametax = $form->{"taxdescription_$i"};
    
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

  $form->hide_form(qw(type taxaccounts path login));

  print qq|
<input type=submit class=submit name=action value="|.$locale->text('Update').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">|;

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

  &{ "update_$form->{type}" }

}


sub update_taxes {

  my @a = split / /, $form->{taxaccounts};
  my $ndx = $#a + 1;
  my @t;
  my $j;
  my $k;
  
  foreach my $item (@a) {
    my ($accno, $i) = split /_/, $item;
    push @t, $accno;

    if ($form->{"validto_$i"}) {
      $j = $i + 1;
      if ($form->{"taxdescription_$i"} ne $form->{"taxdescription_$j"}) {
	#insert line
	for ($j = $ndx + 1; $j > $i; $j--) {
	  $k = $j - 1;
	  for (qw(taxrate taxdescription taxnumber validto)) { $form->{"${_}_$j"} = $form->{"${_}_$k"} }
	}
	$ndx++;
	$k = $i + 1;
	for (qw(taxdescription taxnumber)) { $form->{"${_}_$k"} = $form->{"${_}_$i"} }
	for (qw(taxrate validto)) { $form->{"${_}_$k"} = "" }
	push @t, $accno;
      }
    } else {
      # remove line
      $j = $i + 1;
      if ($form->{"taxdescription_$i"} eq $form->{"taxdescription_$j"}) {
	  for ($j = $i + 1; $j <= $ndx; $j++) {
	    $k = $j + 1;
	    for (qw(taxrate taxdescription taxnumber validto)) { $form->{"${_}_$j"} = $form->{"${_}_$k"} }
	  }
	  $ndx--;
	  splice @t, $i-1, 1;
	}
    }
	
  }

  $i = 1;
  $form->{taxaccounts} = "";
  for (@t) {
    $form->{taxaccounts} .= "${_}_$i ";
    $i++;
  }
  chop $form->{taxaccounts};

  &display_taxes;
  
}


sub defaults {
  
  # get defaults for account numbers and last numbers
  AM->defaultaccounts(\%myconfig, \%$form);

  foreach my $key (keys %{ $form->{accno} }) {
    foreach my $accno (sort keys %{ $form->{accno}{$key} }) {
      $form->{"select$key"} .= "$accno--$form->{accno}{$key}{$accno}{description}\n";
      if ($form->{accno}{$key}{$accno}{id} == $form->{defaults}{$key}) {
	$form->{$key} = qq|$accno--$form->{accno}{$key}{$accno}{description}|;
      }
    }
  }

  for (qw(accno defaults)) { delete $form->{$_} }

  my %checked;
  
  $checked{cash} = "checked" if $form->{method} eq 'cash';
  $checked{cdt} = "checked" if $form->{cdt};
  $checked{name} = "checked";
  if ($form->{namesbynumber}) {
    $checked{name} = "";
    $checked{number} = "checked";
  }
  
  $form->{title} = $locale->text('System Defaults');
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=defaults>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right>|.$locale->text('Company Name').qq|</th>
	  <td><input name=company size=35 value="|.$form->quote($form->{company}).qq|"></td>
	</tr>
	<tr valign=top>
	  <th align=right>|.$locale->text('Address').qq|</th>
	  <td><textarea name=address rows=3 cols=35>$form->{address}</textarea></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Phone').qq|</th>
	  <td><input name=tel size=14 value="$form->{tel}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Fax').qq|</th>
	  <td><input name=fax size=14 value="$form->{fax}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('E-Mail').qq|</th>
	  <td><input name=companyemail size=25 value="$form->{companyemail}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Website').qq|</th>
	  <td><input name=companywebsite size=25 value="$form->{companywebsite}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Business Number').qq|</th>
	  <td><input name=businessnumber size=25 value="|.$form->quote($form->{businessnumber}).qq|"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Reporting Method').qq|</th>
	  <td><input name=method class=checkbox type=checkbox value=cash $checked{cash}>&nbsp;|.$locale->text('Cash').qq|</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Cash Discount').qq|</th>
	  <td><input name=cdt class=checkbox type=checkbox value="1" $checked{cdt}>&nbsp;|.$locale->text('Taxable').qq|</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Sort Names by').qq|</th>
	  <td><input name=namesbynumber value="" type=radio $checked{name}>
	  <b>|.$locale->text('Name').qq|</b>
	  <input name=namesbynumber value="1" type=radio $checked{number}>
	  <b>|.$locale->text('Number').qq|</b>
	  </td>
	</tr>
	
	<tr>
	  <th align=right>|.$locale->text('Precision').qq|</th>
	  <td><input name=precision size=5 value="$form->{precision}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Weight Unit').qq|</th>
	  <td><input name=weightunit size=5 value="$form->{weightunit}"></td>
	</tr>

      </table>
    </td>
  </tr>
  <tr>
    <th class=listheading>|.$locale->text('Last Numbers & Default Accounts').qq|</th>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Inventory').qq|</th>
	  <td><select name=IC>|.$form->select_option($form->{"selectIC"}, $form->{IC}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Income').qq|</th>
	  <td><select name=IC_income>|.$form->select_option($form->{"selectIC_income"}, $form->{IC_income}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Expense').qq|</th>
	  <td><select name=IC_expense>|.$form->select_option($form->{"selectIC_expense"}, $form->{IC_expense}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Foreign Exchange Gain').qq|</th>
	  <td><select name=FX_gain>|.$form->select_option($form->{"selectFX_gain"}, $form->{FX_gain}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Foreign Exchange Loss').qq|</th>
	  <td><select name=FX_loss>|.$form->select_option($form->{"selectFX_loss"}, $form->{FX_loss}).qq|</select></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('GL Reference Number').qq|</th>
	  <td><input name=glnumber size=40 value="$form->{glnumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Sales Invoice/AR Transaction Number').qq|</th>
	  <td><input name=sinumber size=40 value="$form->{sinumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Sales Order Number').qq|</th>
	  <td><input name=sonumber size=40 value="$form->{sonumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Vendor Invoice/AP Transaction Number').qq|</th>
	  <td><input name=vinumber size=40 value="$form->{vinumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Batch Number').qq|</th>
	  <td><input name=batchnumber size=40 value="$form->{batchnumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Voucher Number').qq|</th>
	  <td><input name=vouchernumber size=40 value="$form->{vouchernumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Purchase Order Number').qq|</th>
	  <td><input name=ponumber size=40 value="$form->{ponumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Sales Quotation Number').qq|</th>
	  <td><input name=sqnumber size=40 value="$form->{sqnumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('RFQ Number').qq|</th>
	  <td><input name=rfqnumber size=40 value="$form->{rfqnumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Part Number').qq|</th>
	  <td><input name=partnumber size=40 value="$form->{partnumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Job/Project Number').qq|</th>
	  <td><input name=projectnumber size=40 value="$form->{projectnumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Employee Number').qq|</th>
	  <td><input name=employeenumber size=40 value="$form->{employeenumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Customer Number').qq|</th>
	  <td><input name=customernumber size=40 value="$form->{customernumber}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Vendor Number').qq|</th>
	  <td><input name=vendornumber size=40 value="$form->{vendornumber}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->{optional} = "company address tel fax companyemail companywebsite yearend weightunit businessnumber closedto revtrans audittrail method cdt namesbynumber typeofcontact";
  
  $form->hide_form(qw(optional closedto revtrans audittrail path login));

  print qq|
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">|;

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


sub config {

  for (qw(mm-dd-yy mm/dd/yy dd-mm-yy dd/mm/yy dd.mm.yy yyyy-mm-dd)) { $form->{selectdateformat} .= "$_\n" }
  $form->{selectdateformat} = "yyyy-mm-dd" if $myconfig{dbdriver} eq 'mysql';

  for (qw(1,000.00 1000.00 1.000,00 1000,00 1'000.00)) { $form->{selectnumberformat} .= "$_\n" }

  for (qw(name signature)) { $myconfig{$_} = $form->quote($myconfig{$_}) }
  
  $myconfig{signature} =~ s/\\n/\n/g;

  my %countrycodes = User->country_codes;
  
  for (sort { $countrycodes{$a} cmp $countrycodes{$b} } keys %countrycodes) {
    $form->{selectcountrycode} .= qq|${_}--$countrycodes{$_}|;
  }
  $form->{selectcountrycode} = qq|--English\n$form->{selectcountrycode}|;

  opendir CSS, "css/.";
  my @all = grep /.*\.css$/, readdir CSS;
  closedir CSS;

  for (@all) { $form->{selectstylesheet} .= "$_\n" }
  $form->{selectstylesheet} .= "\n";
  
  my $printer;
  
  if (%printer) {
    $form->{selectprinter} = "\n";
    for (sort keys %printer) { $form->{selectprinter} .= "$_\n" }

    $printer = qq|
	      <tr>
		<th align=right>|.$locale->text('Printer').qq|</th>
		<td><select name=printer>|
		.$form->select_option($form->{selectprinter}, $myconfig{printer})
		.qq|</select></td>
	      </tr>
|;

    $myconfig{outputformat} ||= "Postscript";
    
  }
  
  my $selectoutputformat = "html--html";
  $selectoutputformat .= "\npostscript--Postscript\npdf--PDF" if $latex;
  
  my $outputformat = qq|
 	      <tr>
		<th align=right>|.$locale->text('Output Format').qq|</th>
		<td><select name=outputformat>|
                .$form->select_option($selectoutputformat, $myconfig{outputformat}, undef, 1)
		.qq|</select></td>
	      </tr>
|;
 
  $form->{title} = $locale->text('Edit Preferences for').qq| $form->{login}|;

  $form->{old_password} = $myconfig{password};

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=preferences>
<input type=hidden name=role value=$myconfig{role}>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Name').qq|</th>
		<td><input name=name size=20 value="|.$form->quote($myconfig{name}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('E-mail').qq|</th>
		<td><input name=email size=35 value="$myconfig{email}"></td>
	      </tr>
	      <tr valign=top>
		<th align=right>|.$locale->text('Signature').qq|</th>
		<td><textarea name=signature rows=3 cols=35>$myconfig{signature}</textarea></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Phone').qq|</th>
		<td><input name=tel size=14 value="$myconfig{tel}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Fax').qq|</th>
		<td><input name=fax size=14 value="$myconfig{fax}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Password').qq|</th>
		<td><input type=password name=new_password value="$myconfig{password}" size=10></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Confirm').qq|</th>
		<td><input type=password name=confirm_password value="$myconfig{password}" size=10></td>
	      </tr>
	    </table>
	  </td>
	  <td>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Date Format').qq|</th>
		<td><select name=dateformat>|
		.$form->select_option($form->{selectdateformat}, $myconfig{dateformat})
		.qq|</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Number Format').qq|</th>
		<td><select name=numberformat>|
		.$form->select_option($form->{selectnumberformat}, $myconfig{numberformat})
		.qq|</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Dropdown Limit').qq|</th>
		<td><input name=vclimit size=10 value="$myconfig{vclimit}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Menu Width').qq|</th>
		<td><input name=menuwidth size=10 value="$myconfig{menuwidth}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Language').qq|</th>
		<td><select name=countrycode>|
		.$form->select_option($form->{selectcountrycode}, $myconfig{countrycode}, undef, 1)
		.qq|</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Session Timeout').qq|</th>
		<td><input name=timeout size=10 value="$myconfig{timeout}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Stylesheet').qq|</th>
		<td><select name=usestylesheet>|
		.$form->select_option($form->{selectstylesheet}, $myconfig{stylesheet})
		.qq|</select></td>
	      </tr>
	      $outputformat
	      $printer
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->hide_form(qw(old_password path login));
  
  print qq|
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">|;

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


sub save_defaults {

  if (AM->save_defaults(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Defaults saved!'));
  } else {
    $form->error($locale->text('Cannot save defaults!'));
  }

}


sub save_taxes {
  
  if (AM->save_taxes(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Taxes saved!'));
  } else {
    $form->error($locale->text('Cannot save taxes!'));
  }

}


sub save_preferences {

  $form->{stylesheet} = $form->{usestylesheet};

  if ($form->{new_password} eq $form->{old_password}) {
    $form->{encrypted} = 1;
  } else {
    if ($form->{new_password} ne $form->{confirm_password}) {
      $form->error($locale->text('Password does not match!'));
    }
    $form->error($locale->text('Password may only contain alphanumeric characters!')) if $form->{new_password} =~ /\W/;
  }
  $form->{password} = $form->{new_password}; 

  if (AM->save_preferences(\%myconfig, \%$form, $memberfile, $userspath)) {
    $form->redirect($locale->text('Preferences saved!'));
  } else {
    $form->error($locale->text('Cannot save preferences!'));
  }

}


sub backup {

  if ($form->{media} eq 'email') {
    $form->error($locale->text('No email address for')." $myconfig{name}") unless ($myconfig{email});
    
    $form->{OUT} = "$sendmail";

  }

  $SIG{INT} = 'IGNORE';
  AM->backup(\%myconfig, \%$form, $userspath, $gzip);

  if ($form->{media} eq 'email') {
    $form->redirect($locale->text('Backup sent to').qq| $myconfig{email}|);
  }

}



sub audit_control {

  $form->{title} = $locale->text('Audit Control');

  AM->closedto(\%myconfig, \%$form);
  
  my %checked;
  for (qw(revtrans audittrail aruniq apuniq gluniq souniq pouniq trackingitemsuniq nontrackingitemsuniq)) { $checked{$_} = "checked" if $form->{$_} }
 
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Enforce transaction reversal for all dates').qq|</th>
	  <td><input name=revtrans class=checkbox type=checkbox value="1" $checked{revtrans}></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Close Books up to').qq|</th>
	  <td><input name=closedto size=11 class=date title="$myconfig{dateformat}" value=$form->{closedto}></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Activate Audit trail').qq|</th>
	  <td><input name=audittrail class=checkbox type=checkbox value="1" $checked{audittrail}></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Remove Audit trail up to').qq|</th>
	  <td><input name=removeaudittrail size=11 class=date title="$myconfig{dateformat}"></td>
	</tr>
<!--
	<tr>
	  <th align=right>|.$locale->text('Enforce unique numbers for').qq|</th>
	  <td>
	  <input name=aruniq type=checkbox value='1' $checked{aruniq}">|
	  .$locale->text('AR').qq|
	  <input name=apuniq type=checkbox value='1' $checked{apuniq}">|
	  .$locale->text('AP').qq|
	  <input name=gluniq type=checkbox value='1' $checked{gluniq}">|
	  .$locale->text('GL').qq|
	  <input name=souniq type=checkbox value='1' $checked{souniq}">|
	  .$locale->text('SO').qq|
	  <input name=pouniq type=checkbox value='1' $checked{pouniq}">|
	  .$locale->text('PO').qq|
	  <input name=trackingitemsuniq type=checkbox value='1' $checked{trackingitemsuniq}">|
	  .$locale->text('Tracking Items').qq|
	  <input name=nontrackingitemsuniq type=checkbox value='1' $checked{nontrackingitemsuniq}">|
	  .$locale->text('Non-Tracking Items').qq|
	  </td>
	</tr>
-->
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<br>
<input type=hidden name=nextsub value=doclose>
<input type=hidden name=action value=continue>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
|;

  $form->hide_form(qw(login path));

  print qq|
</form>

</body>
</html>
|;

}

sub doclose {

  AM->closebooks(\%myconfig, \%$form);

  my $msg;
  if ($form->{revtrans}) {
    $msg = $locale->text('Transaction reversal enforced for all dates');
  } else {
    
    if ($form->{closedto}) {
      $msg = $locale->text('Books closed up to')
      ." ".$locale->date(\%myconfig, $form->{closedto}, 1);
    } else {
      $msg = $locale->text('Books are open');
    }
  }

  $msg .= "<p>";
  if ($form->{audittrail}) {
    $msg .= $locale->text('Audit trail enabled');
  } else {
    $msg .= $locale->text('Audit trail disabled');
  }

  $msg .= "<p>";
  if ($form->{removeaudittrail}) {
    $msg .= $locale->text('Audit trail removed up to')
    ." ".$locale->date(\%myconfig, $form->{removeaudittrail}, 1);
  }

  %uniq = ( aruniq => $locale->text('AR'),
            apuniq => $locale->text('AP'),
	    gluniq => $locale->text('GL'),
	    souniq => $locale->text('Sales Orders'),
	    pouniq => $locale->text('Purchase Orders'),
	    trackingitemsuniq => $locale->text('Tracking Items'),
	    nontrackingitemsuniq => $locale->text('Non-tracking Items')
	  );
  
  for (keys %uniq) {
    if ($form->{$_}) {
      $msg .= "<p>";
      $msg .= $locale->text('Unique numbers enforced for')
      ." ".$uniq{$_}; 
    }
  }
	   
  $form->redirect($msg);
  
}


sub add_warehouse {

  $form->{title} = $locale->text('Add Warehouse');
  
  $form->{callback} = "$form->{script}?action=add_warehouse&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &warehouse_header;
  &form_footer;

}


sub edit_warehouse {

  $form->{title} = $locale->text('Edit');

  AM->get_warehouse(\%myconfig, \%$form);

  &warehouse_header;
  &form_footer;

}


sub list_warehouse {

  AM->warehouses(\%myconfig, \%$form);

  my $href = "$form->{script}?action=list_warehouse&direction=$form->{direction}&path=$form->{path}&login=$form->{login}";

  $form->sort_order();
  
  $form->{callback} = "$form->{script}?action=list_warehouse&direction=$form->{direction}&path=$form->{path}&login=$form->{login}";

  my $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Warehouses');

  my @column_index = qw(description address);

  my %column_data;
  
  $column_data{description} = qq|<th width=30%><a class=listheading href=$href>|.$locale->text('Description').qq|</a></th>|;
  $column_data{address} = qq|<th class=listheading>|.$locale->text('Address').qq|</th>|;

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

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
|;

  my $i;
  
  foreach my $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $column_data{description} = qq|<td><a href=$form->{script}?action=edit_warehouse&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{description}</td>|;
   $column_data{address} = qq|<td>$ref->{address1} $ref->{address2} $ref->{city} $ref->{state} $ref->{zipcode} $ref->{country}</td>|;

   for (@column_index) { print "$column_data{$_}\n" }

   print qq|
	</tr>
|;
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

  $form->{type} = "warehouse";

  $form->hide_form(qw(type callback path login));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add Warehouse').qq|">|;

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



sub warehouse_header {

  $form->{description} = $form->quote($form->{description});

  my $description;
  my $rows;
  
  if (($rows = $form->numtextrows($form->{description}, 60)) > 1) {
    $description = qq|<textarea name="description" rows=$rows cols=60 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=60 value="|.$form->quote($form->{description}).qq|">|;
  }

  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=warehouse>

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align=right>|.$locale->text('Description').qq|</th>
    <td>$description</td>
  </tr>
  <tr>
    <th align=right nowrap>|.$locale->text('Address').qq|</th>
    <td><input name=address1 size=35 maxlength=32 value="|.$form->quote($form->{address1}).qq|"></td>
  </tr>
  <tr>
    <th></th>
    <td><input name=address2 size=35 maxlength=32 value="|.$form->quote($form->{address2}).qq|"></td>
  </tr>
  <tr>
    <th align=right nowrap>|.$locale->text('City').qq|</th>
    <td><input name=city size=35 maxlength=32 value="|.$form->quote($form->{city}).qq|"></td>
  </tr>
  <tr>
    <th align=right nowrap>|.$locale->text('State/Province').qq|</th>
    <td><input name=state size=35 maxlength=32 value="|.$form->quote($form->{state}).qq|"></td>
  </tr>
  <tr>
    <th align=right nowrap>|.$locale->text('Zip/Postal Code').qq|</th>
    <td><input name=zipcode size=10 maxlength=10 value="|.$form->quote($form->{zipcode}).qq|"></td>
  </tr>
  <tr>
    <th align=right nowrap>|.$locale->text('Country').qq|</th>
    <td><input name=country size=35 maxlength=32 value="|.$form->quote($form->{country}).qq|"></td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_warehouse {

  $form->isblank("description", $locale->text('Description missing!'));
  if (AM->save_warehouse(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Warehouse saved!'));
  }
  
  $form->error($locale->text('Failed to save Warehouse!'));

}


sub delete_warehouse {

  if (AM->delete_warehouse(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Warehouse deleted!'));
  }
  
  $form->error($locale->text('Failed to delete Warehouse!'));

}


sub yearend {

  AM->earningsaccounts(\%myconfig, \%$form);
  
  for (@{ $form->{chart} }) { $form->{selectchart} .= "$_->{accno}--$_->{description}\n" }
  
  $checked{accrual} = "checked" if $form->{method} eq 'accrual';
  $checked{cash} = "checked" if $form->{method} eq 'cash';
  
  $form->{title} = $locale->text('Yearend');
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=decimalplaces value=$form->{precision}>
<input type=hidden name=l_accno value=Y>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Date').qq| <font color=red>*</font></th>
	  <td><input name=todate size=11 class=date title="$myconfig{dateformat}" value=$todate></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Reference').qq|</th>
	  <td><input name=reference size=20></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td><textarea name=description rows=3 cols=50 wrap=soft></textarea></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Retained Earnings').qq|</th>
	  <td><select name=accno>|
	  .$form->select_option($form->{selectchart})
	  .qq|</select></td>
	</tr>
	<tr>
          <th align=right>|.$locale->text('Method').qq|</th>
          <td><input name=method class=radio type=radio value=accrual $checked{accrual}>&nbsp;|.$locale->text('Accrual').qq|&nbsp;<input name=method class=radio type=radio value=cash $checked{cash}>&nbsp;|.$locale->text('Cash').qq|</td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<input type=hidden name=nextsub value=generate_yearend>
|;

  $form->hide_form(qw(path login));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

}


sub generate_yearend {

  $form->isblank("todate", $locale->text('Yearend date missing!'));

  RP->yearend_statement(\%myconfig, \%$form);
  
  $form->{transdate} = $form->{todate};

  my $earnings = 0;
  my $ok;
  
  $form->{rowcount} = 1;
  for (keys %{ $form->{I} }) {
    if ($form->{I}{$_}{charttype} eq "A") {
      $form->{"debit_$form->{rowcount}"} = $form->{I}{$_}{this};
      $earnings += $form->{I}{$_}{this};
      $form->{"accno_$form->{rowcount}"} = $_;
      $form->{rowcount}++;
      $ok = 1;
    }
  }

  for (keys %{ $form->{E} }) {
    if ($form->{E}{$_}{charttype} eq "A") {
      $form->{"credit_$form->{rowcount}"} = $form->{E}{$_}{this} * -1;
      $earnings += $form->{E}{$_}{this};
      $form->{"accno_$form->{rowcount}"} = $_;
      $form->{rowcount}++;
      $ok = 1;
    }
  }
  if ($earnings > 0) {
    $form->{"credit_$form->{rowcount}"} = $earnings;
    $form->{"accno_$form->{rowcount}"} = $form->{accno}
  } else {
    $form->{"debit_$form->{rowcount}"} = $earnings * -1;
    $form->{"accno_$form->{rowcount}"} = $form->{accno}
  }
  
  if ($ok) {
    if (AM->post_yearend(\%myconfig, \%$form)) {
      $form->redirect($locale->text('Yearend posted!'));
    } else {
      $form->error($locale->text('Yearend posting failed!'));
    }
  } else {
    $form->error('Nothing to do!');
  }
  
}



sub company_logo {
  
  $myconfig{dbhost} = $locale->text('localhost') unless $myconfig{dbhost};

  AM->company_defaults(\%myconfig, \%$form);
  $form->{address} =~ s/\n/<br>/g;
  
  $form->{stylesheet} = $myconfig{stylesheet};

  $form->{title} = $locale->text('About');
  
  # create the logo screen
  $form->header;

  print qq|
<body>

<pre>





</pre>
<center>
<a href="http://www.sql-ledger.org" target=_blank><img src=$images/sql-ledger.gif border=0></a>
<h1 class=login>|.$locale->text('Version').qq| $form->{version}</h1>

<p>
|.$locale->text('Licensed to').qq|
<p>
<b>
$form->{company}
<br>$form->{address}
</b>

<p>
<table border=0>
  <tr>
    <th align=right>|.$locale->text('User').qq|</th>
    <td>$myconfig{name}</td>
  </tr>
  <tr>
    <th align=right>|.$locale->text('Dataset').qq|</th>
    <td>$myconfig{dbname}</td>
  </tr>
  <tr>
    <th align=right>|.$locale->text('Database Host').qq|</th>
    <td>$myconfig{dbhost}</td>
  </tr>
</table>

</center>

</body>
</html>
|;

}


sub recurring_transactions {

# $locale->text('Day')
# $locale->text('Days')
# $locale->text('Month')
# $locale->text('Months')
# $locale->text('Week')
# $locale->text('Weeks')
# $locale->text('Year')
# $locale->text('Years')

  $form->{stylesheet} = $myconfig{stylesheet};

  $column_data{id} = "";

  AM->recurring_transactions(\%myconfig, \%$form);

  $form->{title} = $locale->text('Recurring Transactions') . " / $form->{company}";

  my $href = "$form->{script}?action=recurring_transactions";
  for (qw(path login)) { $href .= qq|&$_=$form->{$_}| }
  my $callback = $href;
  for (qw(direction oldsort)) { $href .= qq|&$_=$form->{$_}| }
  
  $form->sort_order();
  
  my @column_index = qw(ndx reference description name vcnumber);
  
  push @column_index, qw(nextdate enddate id amount curr repeat howmany recurringemail recurringprint);

  my %column_data;
  
  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $action = ($form->{deselect}) ? "deselect_all" : "select_all";
  $column_data{ndx} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); javascript:document.forms[0].submit()"><input type=hidden name=action value="$action"></th>|;
  
  $column_data{reference} = "<th><a class=listheading href=$href&sort=reference>".$locale->text('Reference').qq"</a></th>";
  $column_data{id} = "<th class=listheading>".$locale->text('ID')."</th>";
  $column_data{description} = "<th><a class=listheading href=$href&sort=description>".$locale->text('Description')."</th>";
  $column_data{name} = "<th nowrap><a class=listheading href=$href&sort=name>".$locale->text('Company Name')."</th>";
  $column_data{vcnumber} = "<th nowrap><a class=listheading href=$href&sort=vcnumber>".$locale->text('Company Number')."</th>";
  $column_data{nextdate} = "<th><a class=listheading href=$href&sort=nextdate>".$locale->text('Next')."</a></th>";
  $column_data{enddate} = "<th><a class=listheading href=$href&sort=enddate>".$locale->text('Ends')."</a></th>";
  $column_data{amount} = "<th class=listheading>".$locale->text('Amount')."</th>";
  $column_data{curr} = "<th class=listheading>&nbsp;</th>";
  $column_data{repeat} = "<th class=listheading>".$locale->text('Every')."</th>";
  $column_data{howmany} = "<th class=listheading>".$locale->text('Times')."</th>";
  $column_data{recurringemail} = "<th class=listheading nowrap>".$locale->text('E-mail')."</th>";
  $column_data{recurringprint} = "<th class=listheading>".$locale->text('Print')."</th>";

  if ($form->{direction} eq 'ASC') {
    $callback .= "&direction=DESC";
  } else {
    $callback .= "&direction=ASC";
  }
  $callback = $form->escape("$callback&sort=$form->{sort}");
  
  # create the logo screen
  $form->header;
 
print qq|
<script language="JavaScript">
<!--

function CheckAll() {

  var frm = document.forms[0]
  var el = frm.elements
  var re = /ndx_/;

  for (i = 0; i < el.length; i++) {
    if (el[i].type == 'checkbox' && re.test(el[i].name)) {
      el[i].checked = frm.allbox.checked
    }
  }

}
// -->
</script>

<body>

<form method=post action=$form->{script}>

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

  my $i = 1;
  my $j;
  my $k;
  my $colspan = $#column_index + 1;
  my %tr = ( ar => $locale->text('AR'),
             ap => $locale->text('AP'),
	     gl => $locale->text('GL'),
	     so => $locale->text('Sales Orders'),
	     po => $locale->text('Purchase Orders'),
	   );
  my %f = &formnames;
  my @f;
  my $ref;
  my $unit;
  my $repeat;
  my $reference;
  my $module;
  my $type;
  
  foreach my $transaction (sort keys %{ $form->{transactions} }) {
    print qq|
        <tr>
	  <th class=listheading colspan=$colspan>$tr{$transaction}</th>
	</tr>
|;
    
    foreach $ref (@{ $form->{transactions}{$transaction} }) {

      for (@column_index) { $column_data{$_} = "<td>$ref->{$_}</td>" }
      for (qw(nextdate enddate)) { $column_data{$_} = "<td nowrap>$ref->{$_}</td>" }

      if ($ref->{repeat} > 1) {
	$unit = $locale->text(ucfirst $ref->{unit});
	$repeat = "$ref->{repeat} $unit";
      } else {
	chop $ref->{unit};
	$unit = $locale->text(ucfirst $ref->{unit});
	$repeat = $unit;
      }

      $column_data{ndx} = qq|<td></td>|;
      
      if (!$ref->{expired}) {
	$k++;
	$checked = "";
	if ($ref->{overdue} <= 0) {
	  $checked = "checked";
	}
	if (exists $form->{deselect}) {
	  $checked = ($form->{deselect}) ? "checked" : "";
	}
	$column_data{ndx} = qq|<td><input name="ndx_$k" class=checkbox type=checkbox value=$ref->{id} $checked></td>|;
	$column_data{nextdate} = qq|<td nowrap><input name="nextdate_$k" size=11 value="$ref->{nextdate}" title="$myconfig{dateformat}"></td>|;
      }
      
      $reference = ($ref->{reference}) ? $ref->{reference} : $locale->text('Next Number');
      $column_data{reference} = qq|<td nowrap><a href=$form->{script}?action=edit_recurring&id=$ref->{id}&vc=$ref->{vc}&path=$form->{path}&login=$form->{login}&module=$ref->{module}&invoice=$ref->{invoice}&transaction=$ref->{transaction}&recurringnextdate=$ref->{nextdate}&callback=$callback>$reference</a></td>|;

      $module = "$ref->{module}.pl";
      $type = "";
      
      if ($ref->{module} eq 'ar') {
	$module = "is.pl" if $ref->{invoice};
	$ref->{amount} /= $ref->{exchangerate};
	$column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{name_id}&db=$ref->{vc}&callback=$callback>$ref->{name}</a></td>|;
      }
      if ($ref->{module} eq 'ap') {
	$module = "ir.pl" if $ref->{invoice};
	$ref->{amount} /= $ref->{exchangerate};
	$column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{name_id}&db=$ref->{vc}&callback=$callback>$ref->{name}</a></td>|;
      }
      if ($ref->{module} eq 'oe') {
	$type = ($ref->{vc} eq 'customer') ? "sales_order" : "purchase_order";
	$column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{name_id}&db=$ref->{vc}&callback=$callback>$ref->{name}</a></td>|;
      }

      $column_data{vcnumber} = qq|<td>$ref->{vcnumber}&nbsp;</td>|;
      $column_data{id} = qq|<td><a href=$module?action=edit&id=$ref->{id}&vc=$ref->{vc}&path=$form->{path}&login=$form->{login}&type=$type&callback=$callback>$ref->{id}</a></td>|;
      
      $column_data{repeat} = "<td align=right nowrap>$repeat</td>";
      $column_data{howmany} = "<td align=right nowrap>".$form->format_amount(\%myconfig, $ref->{howmany})."</td>";
      $column_data{amount} = "<td align=right nowrap>".$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision})."</td>";
      
      $column_data{recurringemail} = "<td nowrap>";
      @f = split /:/, $ref->{recurringemail};
      for (0 .. $#f) { $column_data{recurringemail} .= "$f{$f[$_]}<br>" }
      $column_data{recurringemail} .= "</td>";
      
      $column_data{recurringprint} = "<td nowrap>";
      @f = split /:/, $ref->{recurringprint};
      for (0 .. $#f) { $column_data{recurringprint} .= "$f{$f[$_]}<br>" }
      $column_data{recurringprint} .= "</td>";

      $j++; $j %= 2;
      print qq|
      <tr class=listrow$j>
|;

      for (@column_index) { print "\n$column_data{$_}" }

      print qq|
      </tr>
|;
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

<input name=lastndx type=hidden value=$k>
|;

  $form->hide_form(qw(path login allbox));

  %button = ('Select all' => { ndx => 2, key => 'A', value => $locale->text('Select all') },
               'Deselect all' => { ndx => 3, key => 'A', value => $locale->text('Deselect all') },
	       'Process Transactions' => { ndx => 4, key => 'P', value => $locale->text('Process Transactions') }
	    );

  if ($form->{deselect}) {
    delete $button{'Select all'};
  } else {
    delete $button{'Deselect all'};
  }
  
  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
  

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


sub select_all {

  for (1 .. $form->{rowcount}) { $form->{"ndx_$_"} = 1 }
  $form->{allbox} = 1;
  $form->{deselect} = 1;
  &recurring_transactions;

}


sub deselect_all {

  for (1 .. $form->{rowcount}) { $form->{"ndx_$_"} = "" }
  $form->{allbox} = "";
  $form->{deselect} = 0;
  &recurring_transactions;

}


sub edit_recurring {

  %links = ( ar => 'create_links',
             ap => 'create_links',
	     gl => 'create_links',
	     is => 'invoice_links',
	     ir => 'invoice_links',
	     oe => 'order_links',
	   );
  %prepare = ( is => 'prepare_invoice',
               ir => 'prepare_invoice',
	       oe => 'prepare_order',
             );

  $form->{type} = "transaction";
  
  if ($form->{module} eq 'ar') {
    if ($form->{invoice}) {
      $form->{type} = "invoice";
      $form->{module} = "is";
    }
  }
  if ($form->{module} eq 'ap') {
    if ($form->{invoice}) {
      $form->{type} = "invoice";
      $form->{module} = "ir";
    }
  }
  
  if ($form->{module} eq 'oe') {
    %tr = ( so => sales_order,
            po => purchase_order,
	  );
	    
    $form->{type} = $tr{$form->{transaction}};
  }

  $form->{script} = "$form->{module}.pl";
  do "$form->{path}/$form->{script}";

  &{ $links{$form->{module}} };
  
  # return if transaction doesn't exist
  $form->redirect unless $form->{recurring};
 
  if ($prepare{$form->{module}}) {
    &{ $prepare{$form->{module}} };
  }
  
  $form->{selectformat} = qq|html--html\n|;
  if ($latex) {
    $form->{selectformat} .= qq|
postscript--|.$locale->text('Postscript').qq|
pdf--|.$locale->text('PDF');
  }

  &schedule;
    
}


sub process_transactions {

  # save variables
  my $pt = new Form;
  for (keys %$form) { $pt->{$_} = $form->{$_} }

  my $defaultprinter;
  while (my ($key, $value) = each %printer) {
    if ($value =~ /lpr/) {
      $defaultprinter = $key;
      last;
    }
  }

  $myconfig{vclimit} = 0;
  my %f = &formnames;
  my $invfld;
  my $ok;
  my $ordfld;
  my $flabel;
  my $ordnumber;

  for (my $i = 1; $i <= $pt->{lastndx}; $i++) {
    if ($pt->{"ndx_$i"}) {
      my $id = $pt->{"ndx_$i"};
      
      # process transaction
      AM->recurring_details(\%myconfig, \%$pt, $id);

      $pt->{nextdate} = $pt->{"nextdate_$i"} if $pt->{"nextdate_$i"};

      my $header = $form->{header};
      # reset $form
      for (keys %$form) { delete $form->{$_}; }
      for (qw(login path stylesheet timeout precision)) { $form->{$_} = $pt->{$_}; }
      $form->{id} = $id;
      $form->{header} = $header;

      # post, print, email
      if ($pt->{arid} || $pt->{apid} || $pt->{oeid}) {
	if ($pt->{arid} || $pt->{apid}) {
	  if ($pt->{arid}) {
	    $form->{script} = ($pt->{invoice}) ? "is.pl" : "ar.pl";
	    $form->{ARAP} = "AR";
	    $form->{module} = "ar";
	    $invfld = "sinumber";
	    $buysell = "buy";
	  } else {
	    $form->{script} = ($pt->{invoice}) ? "ir.pl" : "ap.pl";
	    $form->{ARAP} = "AP";
	    $form->{module} = "ap";
	    $invfld = "vinumber";
	    $buysell = "sell";
	  }
	  do "$form->{path}/$form->{script}";

          if ($pt->{invoice}) {
	    &invoice_links;
	    &prepare_invoice;
	    
	    for (keys %$form) { $form->{$_} = $form->unquote($form->{$_}) }

	  } else {
	    &create_links;

            $form->{type} = "transaction";
            for (1 .. $form->{rowcount} - 1) { $form->{"amount_$_"} = $form->format_amount(\%myconfig, $form->{"amount_$_"}, $form->{precision}) }
	    for (split / /, $form->{taxaccounts}) { $form->{"tax_$_"} = $form->format_amount(\%myconfig, $form->{"tax_$_"}, $form->{precision}) }
	  }
	  
	  for (1 .. $form->{paidaccounts}) { $form->{"paid_$_"} = $form->format_amount(\%myconfig, $form->{"paid_$_"}, $form->{precision}) }
	  $form->{discount_paid} = $form->format_amount(\%myconfig, $form->{discount_paid}, $form->{precision});

	  delete $form->{"$form->{ARAP}_links"};
	  for (qw(acc_trans invoice_details)) { delete $form->{$_} }
	  for (qw(department employee language month partsgroup project years)) { delete $form->{"all_$_"} }
	  
	  $form->{invnumber} = $pt->{reference};
	  $form->{description} = $pt->{description};
	  $form->{transdate} = $pt->{nextdate};

          # exchangerate
          if ($form->{currency} ne $form->{defaultcurrency}) {
	    $exchangerate = $form->get_exchangerate(\%myconfig, undef, $form->{currency}, $form->{transdate}, $buysell);
	    $form->{exchangerate} = $form->format_amount(\%myconfig, $exchangerate) if $exchangerate;
	  }

          # tax accounts
	  $form->all_taxaccounts(\%myconfig, undef, $form->{transdate});
	  
	  # calculate duedate
	  $form->{duedate} = $form->add_date(\%myconfig, $form->{transdate}, $pt->{overdue}, "days");

	  if ($pt->{payment}) {
	    # calculate date paid
	    for ($j = 1; $j <= $form->{paidaccounts}; $j++) {
	      $form->{"datepaid_$j"} = $form->add_date(\%myconfig, $form->{transdate}, $pt->{paid}, "days");
	      ($form->{"$form->{ARAP}_paid_$j"}) = split /--/, $form->{"$form->{ARAP}_paid_$j"};
	      delete $form->{"cleared_$j"};

	      if ($form->{currency} ne $form->{defaultcurrency}) {
		$form->{"exchangerate_$j"} = $form->{exchangerate};
		$exchangerate = $form->get_exchangerate(\%myconfig, undef, $form->{currency}, $form->{"datepaid_$j"}, $buysell);
		$form->{"exchangerate_$j"} = $form->format_amount(\%myconfig, $exchangerate) if $exchangerate;
	      }
	    }
	  } else {
	    $form->{paidaccounts} = 1;
	  }

	  for (qw(id recurring printed emailed queued)) { delete $form->{$_} }

	  ($form->{$form->{ARAP}}) = split /--/, $form->{$form->{ARAP}};

	  $form->{invnumber} = $form->update_defaults(\%myconfig, "$invfld") unless $form->{invnumber};
	  $form->{reference} = $form->{invnumber};
	  for (qw(invnumber reference description)) { $form->{$_} = $form->unquote($form->{$_}) }

          if ($pt->{invoice}) {
	    if ($pt->{arid}) {
	      $form->info("\n".$locale->text('Posting')." ".$locale->text('Sales Invoice')." $form->{invnumber} ... ");
	      $ok = IS->post_invoice(\%myconfig, \%$form);
	    } else {
	      $form->info("\n".$locale->text('Posting')." ".$locale->text('Vendor Invoice')." $form->{invnumber} ... ");
	      $ok = IR->post_invoice(\%myconfig, \%$form);
	    }
	  } else {
	    $form->info("\n".$locale->text('Posting')." ".$locale->text('Transaction')." $form->{invnumber} ... ");
	    $ok = AA->post_transaction(\%myconfig, \%$form);
	  }
	  if ($ok) {
	    $form->info($locale->text('ok'));
	  } else {
	    $form->info($locale->text('failed'));
	  }
	  
	  # print form
	  if ($latex && $ok) {
	    $ok = &print_recurring(\%$pt, $defaultprinter);
	  }
	  
	  &email_recurring(\%$pt) if $ok;
	  
	} else {

	  # order
	  $form->{script} = "oe.pl";
	  $form->{module} = "oe";

	  $ordnumber = "ordnumber";
	  if ($pt->{customer_id}) {
	    $form->{vc} = "customer";
	    $form->{type} = "sales_order";
	    $ordfld = "sonumber";
	    $flabel = $locale->text('Sales Order');
	    $buysell = "buy";
	  } else {
	    $form->{vc} = "vendor";
	    $form->{type} = "purchase_order";
	    $ordfld = "ponumber";
	    $flabel = $locale->text('Purchase Order');
	    $buysell = "sell";
	  }
	  require "$form->{path}/$form->{script}";

	  &order_links;
	  &prepare_order;

	  for (keys %$form) { $form->{$_} = $form->unquote($form->{$_}) }
	  
	  $form->{$ordnumber} = $pt->{reference};
	  $form->{description} = $pt->{description};
	  $form->{transdate} = $pt->{nextdate};
	  
	  # exchangerate
          if ($form->{currency} ne $form->{defaultcurrency}) {
	    $exchangerate = $form->get_exchangerate(\%myconfig, undef, $form->{currency}, $form->{transdate}, $buysell);
	    $form->{exchangerate} = $form->format_amount(\%myconfig, $exchangerate) if $exchangerate;
	  }
  
	  # calculate reqdate
	  $form->{reqdate} = $form->add_date(\%myconfig, $form->{transdate}, $pt->{req}, "days") if $form->{reqdate};

	  for (qw(id recurring printed emailed queued)) { delete $form->{$_} }
	  for (1 .. $form->{rowcount}) { delete $form->{"orderitems_id_$_"} }

	  $form->{$ordnumber} = $form->update_defaults(\%myconfig, "$ordfld") unless $form->{$ordnumber};
	  $form->{reference} = $form->{$ordnumber};
	  for ("$ordnumber", "reference", "description") { $form->{$_} = $form->unquote($form->{$_}) }
	  $form->{closed} = 0;

	  $form->info("\n".$locale->text('Saving')." ".$flabel." $form->{$ordnumber} ... ");
	  if ($ok = OE->save(\%myconfig, \%$form)) {
	    $form->info($locale->text('ok'));
	  } else {
	    $form->info($locale->text('failed'));
	  }

	  # print form
	  if ($latex && $ok) {
	    &print_recurring(\%$pt, $defaultprinter);
	  }

	  &email_recurring(\%$pt);

	}

      } else {
	# GL transaction
	GL->transaction(\%myconfig, \%$form);
	
	$form->{reference} = $pt->{reference};
	$form->{description} = $pt->{description};
	$form->{transdate} = $pt->{nextdate};

	$form->{defaultcurrency} = substr($form->{currencies},0,3);
	
	$buysell = "buy";
	
	# exchangerate
	if ($form->{currency} ne $form->{defaultcurrency}) {
	  $exchangerate = $form->get_exchangerate(\%myconfig, undef, $form->{currency}, $form->{transdate}, $buysell);
	  $form->{exchangerate} = $form->format_amount(\%myconfig, $exchangerate) if $exchangerate;
	}

	$j = 1;
	foreach $ref (@{ $form->{GL} }) {
	  $form->{"accno_$j"} = "$ref->{accno}--$ref->{description}";

	  $form->{"projectnumber_$j"} = "$ref->{projectnumber}--$ref->{project_id}" if $ref->{project_id};
	  $form->{"fx_transaction_$j"} = $ref->{fx_transaction};

	  if ($ref->{amount} < 0) {
	    $form->{"debit_$j"} = $ref->{amount} * -1;
	  } else {
	    $form->{"credit_$j"} = $ref->{amount};
	  }

	  $j++;
	}
	
	$form->{rowcount} = $j;

	for (qw(id recurring)) { delete $form->{$_} }
	$form->info("\n".$locale->text('Posting')." ".$locale->text('GL Transaction')." $form->{reference} ... ");
	if ($ok = GL->post_transaction(\%myconfig, \%$form)) {
	  $form->info($locale->text('ok'));
	} else {
	  $form->info($locale->text('failed'));
	}
      }

      AM->update_recurring(\%myconfig, \%$pt, $id) if $ok;

    }
  }

  $form->{callback} = "am.pl?action=recurring_transactions&path=$form->{path}&login=$form->{login}&header=$form->{header}";
  $form->redirect;

}


sub print_recurring {
  my ($pt, $defaultprinter) = @_;

  my %f = &formnames;
  my @f;
  my $ok = 1;
  my $media;
  my @a;
  
  if ($pt->{recurringprint}) {
    @f = split /:/, $pt->{recurringprint};
    for ($j = 0; $j <= $#f; $j += 3) {
      $media = $f[$j+2];
      $media ||= $myconfig->{printer} if $printer{$myconfig->{printer}};
      $media ||= $defaultprinter;
      
      $form->info("\n".$locale->text('Printing')." ".$locale->text($f{$f[$j]})." $form->{reference}");

      @a = ("perl", "$form->{script}", "action=reprint&module=$form->{module}&type=$form->{type}&login=$form->{login}&path=$form->{path}&id=$form->{id}&formname=$f[$j]&format=$f[$j+1]&media=$media&vc=$form->{vc}&ARAP=$form->{ARAP}");

      $ok = !(system(@a));
      
      if ($ok) {
	$form->info(" ... ".$locale->text('ok'));
      } else {
	$form->info(" ... ".$locale->text('failed'));
	last;
      }
    }
  }

  $ok;
  
}


sub email_recurring {
  my ($pt) = @_;

  my %f = &formnames;
  my $ok = 1;
  
  if ($pt->{recurringemail}) {

    my @f = split /:/, $pt->{recurringemail};
    for (my $j = 0; $j <= $#f; $j += 2) {
      
      $form->info("\n".$locale->text('Sending')." ".$locale->text($f{$f[$j]})." $form->{reference} ... ");

      # no email, bail out
      if (!$form->{email}) {
	$form->info($locale->text('E-mail address missing!'));
	last;
      }
      
      $message = $form->escape($pt->{message},1);
      
      @a = ("perl", "$form->{script}", "action=reprint&module=$form->{module}&type=$form->{type}&login=$form->{login}&path=$form->{path}&id=$form->{id}&formname=$f[$j]&format=$f[$j+1]&media=email&vc=$form->{vc}&ARAP=$form->{ARAP}&message=$message");

      $ok = !(system(@a));
      
      if ($ok) {
	$form->info(" ... ".$locale->text('ok'));
      } else {
	$form->info(" ... ".$locale->text('failed'));
	last;
      }
    }
  }

  $ok;
  
}



sub formnames {
  
# $locale->text('Transaction')
# $locale->text('Invoice')
# $locale->text('Credit Invoice')
# $locale->text('Debit Invoice')
# $locale->text('Packing List')
# $locale->text('Pick List')
# $locale->text('Sales Order')
# $locale->text('Work Order')
# $locale->text('Purchase Order')
# $locale->text('Bin List')
 
  return ( transaction => 'Transaction',
       	       invoice => 'Invoice',
        credit_invoice => 'Credit Invoice',
         debit_invoice => 'Debit Invoice',
          packing_list => 'Packing List',
             pick_list => 'Pick List',
           sales_order => 'Sales Order',
            work_order => 'Work Order',
        purchase_order => 'Purchase Order',
 	      bin_list => 'Bin List',
    );

}


sub continue { &{ $form->{nextsub} } };


sub clear_locks {

  $form->error($locale->text('Unauthorized!')) if $myconfig{role} ne 'admin';

  $form->{title} = $locale->text('Confirm!');
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->{action} = "clear_locks";
  $form->hide_form;
  
  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|.$locale->text('Are you sure you want to remove all the locks').qq|</h4>

<input name=action class=submit type=submit value="|.$locale->text('Remove Locks').qq|">
</form>

</body>
</html>
|;

}


sub remove_locks {

  AM->remove_locks(\%myconfig, \%$form);

  $form->redirect($locale->text('Locks removed!'));
  
}


sub bank_accounts {

  AM->bank_accounts(\%myconfig, \%$form);

  $form->{title} = $locale->text('Bank Accounts');
  
  $callback = "$form->{script}?action=bank_accounts";
  for (qw(path login)) { $callback .= "&$_=$form->{$_}" }
  
  @column_index = qw(accno description name iban bic membernumber rvc dcn);
  
  $callback = $form->escape($callback);

  $column_header{accno} = qq|<th class=listheading>|.$locale->text('Account').qq|</th>|;
  $column_header{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_header{name} = qq|<th class=listheading>|.$locale->text('Bank').qq|</th>|;
  $column_header{iban} = qq|<th class=listheading>|.$locale->text('IBAN').qq|</th>|;
  $column_header{bic} = qq|<th class=listheading>|.$locale->text('BIC').qq|</th>|;
  $column_header{address} = qq|<th class=listheading>|.$locale->text('Address').qq|</th>|;
  $column_header{membernumber} = qq|<th class=listheading>|.$locale->text('Member No.').qq|</th>|;
  $column_header{rvc} = qq|<th class=listheading>|.$locale->text('RVC').qq|</th>|;
  $column_header{dcn} = qq|<th class=listheading>|.$locale->text('DCN').qq|</th>|;

  
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

  for (@column_index) { print "$column_header{$_}\n" }

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $ref->{address} =~ s/\n/<br>/g;
    for (qw(name description membernumber rvc dcn)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
    for (qw(iban bic address)) { $column_data{$_} = "<td nowrap>$ref->{$_}&nbsp;</td>" }
    $column_data{accno} = "<td><a href=$form->{script}?action=edit_bank&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{accno}</td>";

    $j++; $j %= 2;
    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
        </tr>
|;

  }

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


sub edit_bank {
  
  AM->get_bank(\%myconfig, \%$form);
  
  &bank_header;
  &bank_footer;

}


sub bank_header {
  
  $form->{title} = $locale->text('Bank Account Details');
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>

  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Bank Account').qq|</th>
	  <td>$form->{account}</td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Bank').qq|</th>
	  <td><input name=name size=32 maxlength=64 value="|.$form->quote($form->{name}).qq|"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('BIC').qq|</th>
	  <td><input name=bic size=11 maxlength=11 value="$form->{bic}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('IBAN').qq|</th>
	  <td><input name=iban size=24 maxlength=34 value="$form->{iban}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Address').qq|</th>
	  <td><input name=address1 size=32 maxlength=32 value="|.$form->quote($form->{address1}).qq|"></td>
	</tr>
	<tr>
	  <th></th>
	  <td><input name=address2 size=32 maxlength=32 value="|.$form->quote($form->{address2}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('City').qq|</th>
	  <td><input name=city size=32 maxlength=32 value="|.$form->quote($form->{city}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('State/Province').qq|</th>
	  <td><input name=state size=32 maxlength=32 value="|.$form->quote($form->{state}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Zip/Postal Code').qq|</th>
	  <td><input name=zipcode size=11 maxlength=10 value="|.$form->quote($form->{zipcode}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Country').qq|</th>
	  <td><input name=country size=32 maxlength=32 value="|.$form->quote($form->{country}).qq|"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Member No.').qq|</th>
	  <td><input name=membernumber value="$form->{membernumber}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('RVC').qq|</th>
	  <td><input name=rvc size=80 value="$form->{rvc}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('DCN').qq|</th>
	  <td><input name=dcn size=60 value="$form->{dcn}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

|;

}


sub bank_footer {

  %button = (
             'Save' => { ndx => 2, key => 'S', value => $locale->text('Save') }
	    );
  
  $form->{type} = "bank";
  
  $form->hide_form(qw(id type login path account callback));
  
  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

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


sub save_bank {
  
  if (!AM->save_bank(\%myconfig, \%$form)) {
    $form->error($locale->text('Failed to save Bank!'));
  }

  $form->redirect($locale->text('Bank saved!'));

}


sub search_exchangerates {

  $form->{title} = $locale->text('Exchange Rates');
  
  AM->exchangerates(\%myconfig, $form);

  $form->{nextsub} = "list_exchangerates";

  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  shift @curr;
  $selectcurrency = "\n";
  for (@curr) { $selectcurrency .= "$_\n" }
  
  if (@curr) {
    $selectcurrency = qq|<tr>
    <th align=right nowrap>|.$locale->text('Currency').qq|</th>
    <td><select name=currency>|
    .$form->select_option($selectcurrency, $form->{currency})
    .qq|</select></td></tr>|;
  } else {
    $form->error($locale->text('No foreign currencies!'));
  }
    
  if (@{ $form->{all_years} }) {
    $selectaccountingyear = "<option>\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|<option>$_\n| }
    $selectaccountingmonth = "<option>\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|<option value=$_>|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
      <tr>
        <th align=right>|.$locale->text('Period').qq|</th>
	<td>
	<select name=month>$selectaccountingmonth</select>
	<select name=year>$selectaccountingyear</select>
	<br>
	<input name=interval class=radio type=radio value=0 checked>&nbsp;|.$locale->text('Current').qq|
	<input name=interval class=radio type=radio value=1>&nbsp;|.$locale->text('Month').qq|
	<input name=interval class=radio type=radio value=3>&nbsp;|.$locale->text('Quarter').qq|
	<input name=interval class=radio type=radio value=12>&nbsp;|.$locale->text('Year').qq|
        </td>
      </tr>
|;
  }
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>


<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        $selectcurrency
	<tr>
	  <th align=right nowrap>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=transdatefrom size=11 class=date title="$myconfig{dateformat}"> <b>|.$locale->text('To').qq|</b> <input name=transdateto size=11 class=date title="$myconfig{dateformat}"></td>
        </tr>
	$selectfrom
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=hidden name=action value=continue>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->{sort} = "transdate";

  $form->hide_form(qw(sort nextsub path login));

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


sub list_exchangerates {

  AM->get_exchangerates(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_exchangerates";
  for (qw(direction oldsort path login)) { $href .= qq|&$_=$form->{$_}| }

  $form->sort_order();

  $callback = "$form->{script}?action=list_exchangerates";
  for (qw(direction oldsort path login)) { $callback .= qq|&$_=$form->{$_}| }
  
  if ($form->{currency}) {
    $callback .= "&currency=".$form->escape($form->{currency},1);
    $href .= "&currency=".$form->escape($form->{currency});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Currency')." : $form->{currency}";
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

  @column_index = qw(transdate);
  
  if ($form->{currency}) {
    @curr = ($form->{currency});
    $form->{currencies} = $form->{currency};
    push @column_index, $form->{currency};
    $column_header{$form->{currency}} = "<th class=listheading colspan=2>$form->{currency}</th>";
  } else {
    @curr = split /:/, $form->{currencies};
    shift @curr;
    $form->{currencies} = join ':', @curr;
    for $curr (@curr) {
      push @column_index, $curr;
      $column_header{$curr} = "<th class=listheading colspan=2>$curr</th>";
    }
  }
 
  $form->{title} = $locale->text('Exchange Rates');

  $column_header{transdate} = "<th><a class=listheading href=$href&sort=$form->{sort}>".$locale->text('Date')."</a></th>";


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

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
        </tr>
|;

  @column_index = qw(transdate);
  
  if ($form->{currency}) {
    for (qw(buy sell)) { push @column_index, "$form->{currency}$_" }
  } else {
    for $curr (@curr) {
      for (qw(buy sell)) { push @column_index, "$curr$_" }
    }
  }
 
  # escape callback for href
  $form->{callback} = $callback .= "&sort=$form->{sort}";
  
  $callback = $form->escape($callback);

  if (@{ $form->{transactions} }) {
    $samedate = $form->{transactions}[0]{transdate};
    foreach $curr (@curr) {
      for (qw(buy sell)) {
	$column_data{"$curr$_"} = "<td>&nbsp;</td>";
      }
    }
  }

  foreach $ref (@{ $form->{transactions} }) {

    if ($ref->{transdate} eq $samedate) {
      $href = "$form->{script}?action=edit_exchangerate&transdate=$ref->{transdate}&currencies=$form->{currencies}&path=$form->{path}&login=$form->{login}&callback=$callback";
      $column_data{transdate} = "<td><a href=$href>$ref->{transdate}</td>";
      for (qw(buy sell)) {
	$column_data{"$ref->{curr}$_"} = "<td>".$form->format_amount(\%myconfig, $ref->{$_}, undef, "&nbsp;").qq|</td>|;
      }
    } else {

      $j++; $j %= 2;

      print qq|
        <tr class=listrow$j>
|;
    
      for (@column_index) { print "\n$column_data{$_}" }

      print qq|
        </tr>
|;

      foreach $curr (@curr) {
	for (qw(buy sell)) {
	  $column_data{"$curr$_"} = "<td>&nbsp;</td>";
	}
      }
      
      $href = "$form->{script}?action=edit_exchangerate&transdate=$ref->{transdate}&currencies=$form->{currencies}&path=$form->{path}&login=$form->{login}&callback=$callback";
      $column_data{transdate} = "<td><a href=$href>$ref->{transdate}</td>";
      for (qw(buy sell)) {
	$column_data{"$ref->{curr}$_"} = "<td>".$form->format_amount(\%myconfig, $ref->{$_}, undef, "&nbsp;").qq|</td>|;
      }
     
      $samedate = $ref->{transdate};

    }

  }
  
  $j++; $j %= 2;

  print qq|
        <tr class=listrow$j>
|;

  for (@column_index) { print "\n$column_data{$_}" }
   
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

  if ($myconfig{acs} !~ /System--System/) {
    $i = 1;
    $button{'System--Exchange Rates'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Exchange Rate').qq|"> |;
  }

  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }
  
  $form->hide_form(qw(currencies sort callback path login));

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


sub edit_exchangerate {
  
  $form->{title} = $locale->text('Edit Exchange Rate');
  
  $form->{callback} = "$form->{script}?action=edit_exchangerate&transdate=$form->{transdate}&currencies=$form->{currencies}&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  for (qw(transdatefrom transdateto)) { $form->{$_} = $form->{transdate} };
  
  $currencies = $form->{currencies};
  for (split /:/, $form->{currencies}) { $curr{$_} = 1 };
  AM->get_exchangerates(\%myconfig, \%$form);
  
  for $ref (@{ $form->{transactions} }) {
    $form->{"$ref->{curr}buy"} = $ref->{buy};
    $form->{"$ref->{curr}sell"} = $ref->{sell};
    $curr{$ref->{curr}} = 1;
  }

  if ($currencies) {
    $form->{currencies} = $currencies;
  } else {
    $form->{currencies} = join ':', sort keys %curr;
  }
    
  &exchangerate_header;
  &form_footer;

}


sub add_exchange_rate {
  
  $form->{title} = $locale->text('Add Exchange Rate');
  
  $form->{callback} = "$form->{script}?action=add_exchange_rate&currencies=$form->{currencies}&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &exchangerate_header;
  &form_footer;

}


sub exchangerate_header {

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
	  <td></td>
	  <td><input name=transdate value="$form->{transdate}" size=11 class=date title="$myconfig{dateformat}"></td>
	  <th>|.$locale->text('Buy').qq|</th>
	  <th>|.$locale->text('Sell').qq|</th>
	</tr>
|;

  for (split /:/, $form->{currencies}) {
    print qq|
	<tr>
	  <td><input type=hidden name="$_" value=1></td>
	  <th align=left>$_</th>
	  <td><input name="${_}buy" value="|.$form->format_amount(\%myconfig, $form->{"${_}buy"}).qq|"></td>
	  <td><input name="${_}sell" value="|.$form->format_amount(\%myconfig, $form->{"${_}sell"}).qq|"></td>
	</tr>
|;
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

  $form->{type} = "exchangerate";
  $form->{oldtransdate} = $form->{transdate};

  $form->hide_form(qw(type id currencies oldtransdate));

}


sub save_exchangerate {

  $form->isblank("transdate", $locale->text('Date missing!'));
  AM->save_exchangerate(\%myconfig, \%$form);
  $form->redirect($locale->text('Exchange Rate saved!'));

}


sub list_currencies {

  AM->currencies(\%myconfig, \%$form);

  my $href = "$form->{script}?action=list_currencies";
  for (qw(direction oldsort path login)) { $href .= qq|&$_=$form->{$_}| }

  $form->sort_order();
  
  my $callback = "$form->{script}?action=list_currencies";
  for (qw(direction oldsort path login)) { $callback .= qq|&$_=$form->{$_}| }

  $form->{callback} = $callback .= "&sort=$form->{sort}";
  $callback = $form->escape($callback);
  
  $form->{title} = $locale->text('Currencies');

  my @column_index = $form->sort_columns(qw(rn curr precision plus minus));

  my %column_data;
  
  $column_data{rn} = qq|<th><a class=listheading href=$href&sort=rn>|.$locale->text('No').qq|</a></th>|;
  $column_data{curr} = qq|<th width=99%><a class=listheading href=$href&sort=curr>|.$locale->text('Currency').qq|</a></th>|;
  $column_data{precision} = qq|<th class=listheading>|.$locale->text('Precision').qq|</th>|;
  $column_data{plus} = qq|<th class=listheading>&nbsp;</th>|;
  $column_data{minus} = qq|<th class=listheading>&nbsp;</th>|;

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

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
|;

  my $i;
  
  foreach my $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $ref->{curr} =~ s/ //g;
   $column_data{rn} = qq|<td align=right>$ref->{rn}</td>|;
   $column_data{curr} = qq|<td><a href=$form->{script}?action=edit_currency&curr=$ref->{curr}&rn=$ref->{rn}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{curr}</td>|;
   $column_data{precision} = qq|<td align=right>$ref->{precision}</td>|;
   $column_data{plus} = qq|<td align=center><a href=$form->{script}?action=move&db=curr&fld=curr&id=$ref->{curr}&move=up&path=$form->{path}&login=$form->{login}&callback=$callback><img src=$images/up.png alt="+" border=0></td>|;
   $column_data{minus} = qq|<td align=center><a href=$form->{script}?action=move&db=curr&fld=curr&id=$ref->{curr}&move=down&path=$form->{path}&login=$form->{login}&callback=$callback><img src=$images/down.png alt="-" border=0></td>|;
   

   for (@column_index) { print "$column_data{$_}\n" }

   print qq|
	</tr>
|;
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

  $form->{type} = "currency";

  $form->hide_form(qw(type callback path login));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add Currency').qq|">|;

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


sub add_currency {

  $form->{title} = $locale->text('Add Currency');
  
  $form->{callback} = "$form->{script}?action=add_currency&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &currency_header;
  &form_footer;

}


sub edit_currency {

  $form->{title} = $locale->text('Edit');

  AM->get_currency(\%myconfig, \%$form);

  $form->{id} = 1;
  &currency_header;
  &form_footer;

}


sub delete_currency {

  if (AM->delete_currency(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Currency deleted!'));
  }
  
  $form->error($locale->text('Failed to delete Currency!'));

}


sub move {

  AM->move(\%myconfig, \%$form);
  $form->redirect;
  
}


sub currency_header {

  $form->header;

  $form->{type} = "currency";
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
  <tr>
    <th align=right>|.$locale->text('Currency').qq|</th>
    <td><input name=curr size=3 maxlength=3 value="$form->{curr}"></td>
    <th align=right>|.$locale->text('Precision').qq|</th>
    <td><input name=precision size=3 value="$form->{precision}"></td>
  </tr>
  </table>
  </td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->hide_form(qw(type rn));

}


sub save_currency {

  $form->isblank("curr", $locale->text('Currency missing!'));
  if (AM->save_currency(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Currency saved!'));
  }
  
  $form->error($locale->text('Failed to save Currency!'));

}


