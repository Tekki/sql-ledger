#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#=====================================================================
#
# POS
#
#=====================================================================

1;
# end


sub add {

  $form->{callback} = "$form->{script}?action=$form->{nextsub}&path=$form->{path}&login=$form->{login}" unless $form->{callback};
  
  $form->{type} =  "pos_invoice";
  $form->{parentgroups} = 1;
  
  $ENV{REMOTE_ADDR} =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
  $form->{till} = $4;

  &invoice_links;
  
  for (qw(cashdrawer poledisplay)) { $form->{$_} = $form->escape($form->{$_},1) }
  
  $form->{format} = "txt";
  $form->{media} = "screen";
  $form->{media} = $myconfig{printer} if $form->{selectprinter} =~ /$myconfig{printer}/;
  $form->{rowcount} = 0;

  $form->{readonly} = ($myconfig{acs} =~ /POS--Sale/) ? 1 : 0;

  $form->{lookup} = "";
  for (@{ $form->{all_partsgroup} }) {
    if ($_->{pos}) {
      $form->{lookup} .= "$_->{partsgroup}--$_->{translation}--$_->{image}\n";
    }
  }

  $form->helpref("pos_invoice", $myconfig{countrycode});

  $focus = "partnumber_1";

  &display_form;

}


sub openinvoices {

  $ENV{REMOTE_ADDR} =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
  $form->{till} = $4;
  
  $form->{sort} = 'transdate';

  for (qw(open l_invnumber l_transdate l_name l_amount l_curr l_till l_subtotal summary)) { $form->{$_} = 'Y'; }

  if ($form->{admin}) {
    $form->{l_employee} = 'Y';
  }

  $form->helpref("open_pos_invoices", $myconfig{countrycode});

  $form->{title} = $locale->text('Open');
  
  &transactions;

}


sub edit {

  $form->{callback} = "$form->{script}?action=$form->{nextsub}&path=$form->{path}&login=$form->{login}" unless $form->{callback};
  
  $form->{type} =  "pos_invoice";
  $form->{parentgroups} = 1;
  
  &invoice_links;
  &prepare_invoice;

  $form->{format} = "txt";
  $form->{media} = ($myconfig{printer}) ? $myconfig{printer} : "screen";

  if (! $form->{readonly}) {
    $form->{readonly} = ($myconfig{acs} =~ /POS--Sale/) ? 1 : 0;
  }

  $form->{lookup} = "";
  for (@{ $form->{all_partsgroup} }) {
    if ($_->{pos}) {
      $form->{lookup} .= "$_->{partsgroup}--$_->{translation}--$_->{image}\n";
    }
  }

  $form->helpref("pos_invoice", $myconfig{countrycode});
  
  &display_form;

}


sub form_header {

  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

  if ($form->{defaultcurrency}) {
    $exchangerate = qq|
              <tr>
                <th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td>
		  <table>
		    <tr>
		    
		<td><select name=currency onChange="javascript:main.submit()">|
		.$form->select_option($form->{selectcurrency}, $form->{currency})
		.qq|</select></td>|;

    if ($form->{currency} ne $form->{defaultcurrency}) {
      $fdm = $form->dayofmonth($myconfig{dateformat}, $form->{transdate}, 'fdm');   
      $ldm = $form->dayofmonth($myconfig{dateformat}, $form->{transdate});

      $exchangerate .= qq|
      <th align=right nowrap>|.$locale->text('Exchange Rate').qq|</th>
      <td nowrap><input name="exchangerate" class="inputright" size="10" value="$form->{exchangerate}">
	  <a href=am.pl?action=list_exchangerates&transdatefrom=$fdm&transdateto=$ldm&currency=$form->{currency}&login=$form->{login}&path=$form->{path} target=_blank>?</a></td>|;
    }
    $exchangerate .= qq|</tr></table></td></tr>
|;
  }

  $vcref = qq|<a href=ct.pl?action=edit&db=$form->{vc}&id=$form->{"$form->{vc}_id"}&login=$form->{login}&path=$form->{path} target=_blank>?</a>|;
  
  if ($form->{selectcustomer}) {
    $customer = qq|
              <tr>
	        <th align=right nowrap>|.$locale->text('Customer').qq| <font color=red>*</font></th>
		<td><select name=customer onChange="javascript:main.submit()">|.$form->select_option($form->{selectcustomer}, $form->{customer}, 1).qq|</select>
		$vcref
		</td>
	      </tr>
	      <tr>
	        <th align=right nowrap>|.$locale->text('Customer Number').qq|</th>
		<td>|.$form->quote($form->{customernumber}).qq|
		</td>
	      </tr>
| . $form->hide_form(customernumber);

  } else {
    $customer = qq|
              <tr>
	        <th align=right nowrap>|.$locale->text('Customer').qq| <font color=red>*</font></th>
		<td><input name=customer value="|.$form->quote($form->{customer}).qq|" size=35>
		$vcref
		</td>
	      </tr>
	      <tr>
	        <th align=right nowrap>|.$locale->text('Customer Number').qq|</th>
		<td><input name=customernumber value="|.$form->quote($form->{customernumber}).qq|" size=35>
		</td>
	      </tr>
|;
  }


  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td><select name=department onChange="javascript:document.main.submit()">|
		.$form->select_option($form->{selectdepartment}, $form->{department}, 1)
		.qq|</select>
		</td>
	      </tr>
| if $form->{selectdepartment};

  $warehouse = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Warehouse').qq|</th>
		<td><select name=warehouse onChange="javascript:document.main.submit()">|
		.$form->select_option($form->{selectwarehouse}, $form->{warehouse}, 1).qq|
		</select>
		</td>
              </tr>
| if $form->{selectwarehouse};

   $form->{oldwarehouse} = $form->{warehouse};

   $employee = qq|
	      <tr>
	        <th align=right nowrap>|.$locale->text('Salesperson').qq|</th>
		<td><select name=employee>|
		.$form->select_option($form->{selectemployee}, $form->{employee}, 1)
		.qq|</select>
		</td>
	      </tr>
| if $form->{selectemployee};


  if (($rows = $form->numtextrows($form->{description}, 60, 5)) > 1) {
    $description = qq|<textarea name="description" rows=$rows cols=60 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=60 value="|.$form->quote($form->{description}).qq|">|;
  }
  $description = qq|
              <tr valign=top>
	        <th align=right nowrap>|.$locale->text('Description').qq|</th>
		<td>$description</td>
              </tr> 
|;

  if ($form->{change} != $form->{oldchange}) {
    $form->{creditremaining} -= $form->{oldchange};
  }
  $n = ($form->{creditremaining} < 0) ? "0" : "1";

  if ($form->{business}) {
    $business = qq|
              <tr>
	        <th align=right nowrap>|.$locale->text('Business').qq|</th>
		<td nowrap>$form->{business}
		&nbsp;&nbsp;&nbsp;
		<b>|.$locale->text('Trade Discount').qq|</b> |
		.$form->format_amount(\%myconfig, $form->{tradediscount} * 100).qq| %</td>
	      </tr>
|;
  }

  if ($form->{selectlanguage}) {
    if ($form->{language_code} ne $form->{oldlanguage_code}) {
      # rebuild partsgroup
      $form->get_partsgroup(\%myconfig, { language_code => $form->{language_code}, searchitems => 'nolabor'});
      $form->{lookup} = "";
      for (@{ $form->{all_partsgroup} }) {
	if ($_->{pos}) {
	  $form->{lookup} .= "$_->{partsgroup}--$_->{translation}--$_->{image}\n";
	}
      }
      $form->{oldlanguage_code} = $form->{language_code};
    }

    $lang = qq|
	      <tr>
                <th align=right>|.$locale->text('Language').qq|</th>
		<td><select name=language_code>|
		.$form->select_option($form->{selectlanguage}, $form->{language_code}, undef, 1)
		.qq|</select>
		</td>
	      </tr>
|;
  }

  if ($form->{pricegroup}) {
    $pricegroup = qq|
  	      <tr>
                <th align=right>|.$locale->text('Pricegroup').qq|</th>
		<td>$form->{pricegroup}</td>
	      </tr>
|;
  }

  $form->{poledisplayon} = "checked" if $form->{poledisplayon};

  $form->{vc} = "customer";
  $form->{action} = "update";
  

  $form->header;
 
  print qq|
<body onLoad="document.main.${focus}.focus()" />

<form method="post" name="main" action="$form->{script}" />
|;

  $form->hide_form(map { "select$_" } qw(currency customer department warehouse employee language AR AR_paid paymentmethod printer));
  $form->hide_form(qw(id till type format printed title discount creditlimit creditremaining tradediscount business address1 address2 city state zipcode country pricegroup closedto locked customer_id payment_accno precision roundchange cashovershort action vc cashdrawer poledisplay parentgroups helpref));
  $form->hide_form(map { "old$_" } qw(transdate customer language customernumber));

  print qq|

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr valign=top>
	  <td>
	    <table>
	      $customer
	      <tr>
	        <th align=right nowrap>|.$locale->text('Address').qq|</th>
		<td>$form->{address1} $form->{address2} $form->{zipcode} $form->{city} $form->{state} $form->{country}</td>
	      </tr>
	      $pricegroup

	      <tr>
		<th align=right nowrap>|.$locale->text('Credit Limit').qq|</th>
		<td>
		  <table>
		    <tr>
		      <td>|.$form->format_amount(\%myconfig, $form->{creditlimit}, $form->{precision}, "0").qq|</td>
		      <td width=10></td>
		      <th align=right nowrap>|.$locale->text('Remaining').qq|</th>
		      <td class="plus$n" width=99%>|.$form->format_amount(\%myconfig, $form->{creditremaining}, $form->{precision}, "0").qq|</font></td>
		    </tr>
		  </table>
		</td>
	      </tr>
	      $business
	      <tr>
		<th align=right nowrap>|.$locale->text('Record in').qq|</th>
		<td><select name=AR>|
		.$form->select_option($form->{selectAR}, $form->{AR})
		.qq|</select>
		</td>
	      </tr>
	      $department
	      $warehouse
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $employee
	      <tr>
		<th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
		<td>$form->{invnumber}</td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Invoice Date').qq|</th>
		<td>$form->{transdate}</td>
	      </tr>
	      $exchangerate
	      $lang
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        $description
      </table>
    </td>
  </tr>
|;

  $form->hide_form(qw(city state country taxaccounts duedate invnumber transdate defaultcurrency oldwarehouse olddepartment));

  foreach $accno (split / /, $form->{taxaccounts}) { $form->hide_form(map {"${accno}_$_" } qw(rate description taxnumber)) }

}



sub form_footer {

  $form->{invtotal} = $form->{invsubtotal};

  $form->{taxincluded} = ($form->{taxincluded}) ? "checked" : "";

  $taxincluded = "";
  if ($form->{taxaccounts}) {
    $taxincluded = qq|
              <tr height="5"></tr>
	      <tr>
	        <td align=right>
		<input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded} onChange="javascript:document.main.submit()"></td><th align=left>|.$locale->text('Tax Included').qq|</th>
	      </tr>
|;
  }

  $tax = "";
  @taxaccounts = split / /, $form->{taxaccounts};
 
  if ($form->{taxincluded}) {

    $ml = 1;

    for (0 .. 1) {
      $taxrate = 0;
      for (@taxaccounts) { $taxrate += $form->{"${_}_rate"} if ($form->{"${_}_rate"} * $ml) > 0 }

      for (@taxaccounts) {
	if (($form->{"${_}_rate"} * $ml) > 0) {
	  
	  $totaltax = 0;
	  if ($taxrate > 0) {
	    $totaltax = $form->round_amount($form->{"${_}_base"} * $taxrate / (1 + $taxrate), $form->{precision});
	  
	    $form->{"${_}_total"} = $form->format_amount(\%myconfig, $totaltax * $form->{"${_}_rate"} / $taxrate, $form->{precision});
	  }
	  
	  $tax .= qq|
		  <tr>
		    <th align=right>$form->{"${_}_description"}</th>
		    <td align=right>$form->{"${_}_total"}</td>
		  </tr>
|;
	}
      }
      $ml *= -1;
    }

  } else {
    
    for (@taxaccounts) {
      if ($form->{"${_}_base"}) {
	$form->{"${_}_total"} = $form->round_amount($form->{"${_}_base"} * $form->{"${_}_rate"}, $form->{precision});
	$form->{invtotal} += $form->{"${_}_total"};
	$form->{"${_}_total"} = $form->format_amount(\%myconfig, $form->{"${_}_total"}, $form->{precision}, 0);
	
	$tax .= qq|
	      <tr>
		<th align=right>$form->{"${_}_description"}</th>
		<td align=right>$form->{"${_}_total"}</td>
	      </tr>
|;
      }
    }
  }
  
  $subtotal = qq|
	      <tr>
		<th align=right>|.$locale->text('Subtotal').qq|</th>
		<td align=right>|.$form->format_amount(\%myconfig, $form->{invsubtotal}, $form->{precision}, 0).qq|</td>
	      </tr>
|;

  @column_index = qw(paid source memo);
  push @column_index, "paymentmethod" if $form->{selectpaymentmethod};
  push @column_index, "AR_paid";

  $column_data{paid} = "<th>".$locale->text('Amount')."</th>";
  $column_data{source} = "<th>".$locale->text('Source')."</th>";
  $column_data{memo} = "<th>".$locale->text('Memo')."</th>";
  $column_data{paymentmethod} = "<th>&nbsp;</th>";
  $column_data{AR_paid} = "<th>&nbsp;</th>";
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr valign=top>
	  <td>
	    <table>
	      <tr>
|;

  for (@column_index) { print "$column_data{$_}\n"; }
  
  print qq|
	      </tr>
|;

  $totalpaid = 0;
  
  $form->{paidaccounts}++ if ($form->{"paid_$form->{paidaccounts}"});
  $form->{"AR_paid_$form->{paidaccounts}"} ||= $form->unescape($form->{payment_accno});
  $form->{"paymentmethod_$form->{paidaccounts}"} ||= $form->unescape($form->{payment_method});

  $roundto = 0;
  if ($form->{roundchange}) {
    %roundchange = split /[=;]/, $form->unescape($form->{roundchange});
    $roundto = $roundchange{''};
  }

  for $i (1 .. $form->{paidaccounts}) {
  
    # format amounts
    $totalpaid += $form->{"paid_$i"};
    
    $form->{"paid_$i"} = $form->format_amount(\%myconfig, $form->{"paid_$i"}, $form->{precision});
    $form->{"exchangerate_$i"} = $form->{exchangerate};

    $column_data{paid} = qq|<td align=center><input name="paid_$i" class="inputright" size="11" value="$form->{"paid_$i"}"></td>|;
    $column_data{source} = qq|<td align=center><input name="source_$i" size=10 value="|.$form->quote($form->{"source_$i"}).qq|"></td>|;
    $column_data{memo} = qq|<td align=center><input name="memo_$i" size=20 value="|.$form->quote($form->{"memo_$i"}).qq|"></td>|;

    if ($form->{selectpaymentmethod}) {

      if ($form->{"paid_$i"}) {
	$roundto = $roundchange{$form->{"paymentmethod_$i"}};
      }

      $column_data{paymentmethod} = qq|<td align=center><select name="paymentmethod_$i">|.$form->select_option($form->{"selectpaymentmethod"}, $form->{"paymentmethod_$i"}, 1).qq|</select></td>|;
    }
    
    $column_data{AR_paid} = qq|<td align=center><select name="AR_paid_$i">|.$form->select_option($form->{selectAR_paid}, $form->{"AR_paid_$i"}).qq|</select></td>|;

    print qq|
	      <tr>
|;
    for (@column_index) { print "$column_data{$_}\n"; }
  
    print qq|
	      </tr>
|;

    $form->hide_form(map { "${_}_$i" } qw(cleared exchangerate));

  }

  $totalpaid = $form->round_amount($totalpaid, $form->{precision});
  $form->{invtotal} = $form->round_amount($form->{invtotal}, $form->{precision});
  $change = $outstanding = 0;
  $form->{change} = 0;
  if ($totalpaid > $form->{invtotal}) {
    $change = $form->{change} = $totalpaid - $form->{invtotal};
    if ($roundto > 0.01) {
      $invtotal = $form->round_amount($form->{invtotal} / $roundto, 0) * $roundto;
      $form->{change} = $totalpaid - $invtotal;
      $change = $form->{change} = $form->round_amount($form->{change} / $roundto, 0) * $roundto;
    }
  } else {

    $roundto = $roundchange{$form->{"paymentmethod_$form->{paidaccounts}"}};

    $outstanding = $form->{outstanding} = $form->{invtotal} - $totalpaid;
    if ($roundto > 0.01) {
      $outstanding = $form->{outstanding} = $form->round_amount($form->{outstanding} / $roundto, 0) * $roundto;
    }
  }
  
  $form->{oldchange} = $form->{change};
  $form->{oldinvtotal} = $form->{invtotal};

  for (qw(change invtotal outstanding)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $form->{precision}, 0) }
  $form->{totalpaid} = $form->format_amount(\%myconfig, $totalpaid, $form->{precision});

  if ($change) {
    print qq|
	      <tr>
		<th align=right>|.$locale->text('Change').qq|</th>
		<th align=right>$form->{change}</th>
	      </tr>
|;
  }
  if ($outstanding) {
    print qq|
	      <tr>
		<th align=right>|.$locale->text('Outstanding').qq|</th>
		<th align=right>$form->{outstanding}</th>
	      </tr>
|;
  }

  print qq|
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $taxincluded
	      $subtotal
	      $tax
	      <tr>
		<th align=right>|.$locale->text('Total').qq|</th>
		<td align=right>$form->{invtotal}</td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
 
  <tr>
    <td>
|;


  if ($form->{oldtotalpaid} != $totalpaid) {
    &poledisplay(0);
  }
  
  $form->{oldtotalpaid} = $totalpaid;
  $form->{datepaid} = $form->{transdate};
  
  $form->hide_form(map { "old$_" } qw(invtotal change totalpaid));
  $form->hide_form(qw(datepaid paidaccounts change invtotal));

  $poledisplay = 0;
  
  for $i (1 .. $form->{rowcount}) {

    for (qw(qty discount sellprice)) {
      $temp{$_} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"});
      if ($form->{"old${_}_$i"} != $temp{$_}) {
	$poledisplay = 1;
      }
      
      $form->{"old${_}_$i"} = $temp{$_};
    }

    if ($poledisplay) {
      &poledisplay($i);
      $poledisplay = 0;
    }

    $form->hide_form(map { "old${_}_$i" } keys %temp);

  }

  &print_options;

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $transdate = $form->datetonum(\%myconfig, $form->{transdate});

  if ($form->{readonly}) {

    &islocked;

  } else {

    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
               'Main Groups' => { ndx => 2, key => 'M', value => $locale->text('Main Groups') },
	       'Print' => { ndx => 3, key => 'P', value => $locale->text('Print') },
	       'Open Drawer' => { ndx => 4, key => 'C', value => $locale->text('Open Drawer') },
	       'Preview' => { ndx => 5, key => 'V', value => $locale->text('Preview') },
	       'Post' => { ndx => 6, key => 'O', value => $locale->text('Post') },
	       'Print and Post' => { ndx => 7, key => 'R', value => $locale->text('Print and Post') },
	       'Assign Number' => { ndx => 8, key => 'A', value => $locale->text('Assign Number') },
	       'Delete' => { ndx => 9, key => 'D', value => $locale->text('Delete') }
	      );

    delete $button{'Main Groups'} if $form->{parentgroups};

    if ($transdate > $form->{closedto}) {

      if (! $form->{id}) {
	delete $button{'Delete'};
      }

      delete $button{'Print and Post'} unless $latex;
      
      for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) {
	print qq|<input class=pos type=submit name=action value="$button{$_}{value}" accesskey="$button{$_}{key}" title="$button{$_}{value} [$button{$_}{key}]">\n|;
      }

      print qq|<p>
      <input class=pos type=text size=1 value="B" accesskey="B" title="[B]">\n|;

      if ($form->{lookup}) {
	$spc = ($form->{path} =~ /lynx/) ? "." : " ";

        $form->{nextsub} = "lookup_partsgroup";
	$form->hide_form(qw(lookup nextsub));

	$form->{lookup} =~ s/\r//g;
	foreach $item (split /\n/, $form->{lookup}) {
	  ($partsgroup, $translation, $image) = split /--/, $item;
	  $item = ($translation) ? $translation : $partsgroup;
	  $item = $form->quote($item);
	  print qq| <button name="action" value="$spc$item" type="submit" class="pos" title="$item"><img src="$image" height="32" alt="$item">\n| if $item;
	}
      }
    }
  }

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }
  
  $form->hide_form(qw(rowcount callback path login));
  
  print qq|
</form>

</body>
</html>
|;

}


sub post {

  $form->isblank("customer", $locale->text('Customer missing!'));

  # if oldcustomer ne customer redo form
  $customer = $form->{customer};
  $customer =~ s/--.*//g;
  $customer .= "--$form->{customer_id}";
  if ($customer ne $form->{oldcustomer}) {
    &update;
    exit;
  }
  
  &validate_items;

  $form->isblank("exchangerate", $locale->text('Exchange rate missing!')) if ($form->{currency} ne $form->{defaultcurrency});
  
  $paid = 0;
  $roundto = 0;
  
  if ($form->{roundchange}) {
    %roundchange = split /[=;]/, $form->unescape($form->{roundchange});
    $roundto = $roundchange{''};
  }

  my $i = 1;
  for (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$_"}) {
      $i = $_;
      $paid += $form->parse_amount(\%myconfig, $form->{"paid_$i"});
      if ($form->{selectpaymentmethod}) {
	$roundto = $roundchange{$form->{"paymentmethod_$i"}};
      }
    }
  }
  delete $form->{datepaid} unless $paid;
  
  $AR_paid = $form->{"AR_paid_$form->{paidaccounts}"};
  $paymentmethod = $form->{"paymentmethod_$form->{paidaccounts}"};

  $paid = $form->round_amount($paid, $form->{precision});
  $total = $form->parse_amount(\%myconfig, $form->{invtotal});

  $cashover = 0;
  # deduct change
  if ($paid > $total) {

    $change = $form->round_amount($paid - $total, $form->{precision});
    if ($roundto > 0.01) {
      $invtotal = $form->round_amount($total / $roundto, 0) * $roundto;
      $change = $form->round_amount($paid - $invtotal, $form->{precision});
      $cashover = $form->round_amount($paid - $invtotal - ($paid - $total), $form->{precision});
    }

    $form->{"paid_$i"} = $form->format_amount(\%myconfig, $form->parse_amount(\%myconfig, $form->{"paid_$i"}) - $change, $form->{precision});

  } else {

    if ($roundto > 0.01) {
      $invtotal = $form->round_amount($total / $roundto, 0) * $roundto;
      $change = $form->round_amount($paid - $invtotal, $form->{precision});
      if ($change == 0) {
	$cashover = $form->round_amount($change - ($paid - $total), $form->{precision});
      }
    }
  }

  if ($cashover) {
    # add payment
    $i = ++$form->{paidaccounts};
    $form->{"paid_$i"} = $form->format_amount(\%myconfig, $cashover, $form->{precision});
    $form->{"AR_paid_$i"} = $form->{cashovershort};
  }

  $i = ++$form->{paidaccounts};
  $form->{"AR_paid_$i"} = $AR_paid;
  $form->{"paymentmethod_$i"} = $paymentmethod;

  if (IS->post_invoice(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Posted!'));
  } else {
    $form->error($locale->text('Cannot post transaction!'));
  }
  
}


sub display_row {
  my $numrows = shift;

  @column_index = qw(partnumber itemhref description partsgroup qty onhand unit sellprice discount linetotal);
    
  $form->{invsubtotal} = 0;

  for (split / /, $form->{taxaccounts}) { $form->{"${_}_base"} = 0; }
  
  $column_data{partnumber} = qq|<th class=listheading>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_data{qty} = qq|<th class=listheading>|.$locale->text('Qty').qq|</th>|;
  $column_data{onhand} = qq|<th class=listheading>|.$locale->text('OH').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading>|.$locale->text('Unit').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading>|.$locale->text('Price').qq|</th>|;
  $column_data{linetotal} = qq|<th class=listheading>|.$locale->text('Extended').qq|</th>|;
  $column_data{discount} = qq|<th class=listheading>%</th>|;
  $column_data{itemhref} = qq|<th class=listheading></th>|;
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}"; };

  print qq|
        </tr>
|;

  $exchangerate = $form->parse_amount(\%myconfig, $form->{exchangerate});
  $exchangerate *= 1;

  for $i (1 .. $numrows) {
    # undo formatting
    for (qw(qty discount sellprice)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}); }

    ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

    if (($form->{"qty_$i"} != $form->{"oldqty_$i"}) || ($form->{currency} ne $form->{oldcurrency})) {
      # check for a pricematrix
      @a = split / /, $form->{"pricematrix_$i"};
      if (scalar @a) {
	foreach $item (@a) {
	  ($q, $p) = split /:/, $item;
	  if (($p * 1) && ($form->{"qty_$i"} >= ($q * 1))) {
	    ($dec) = ($p =~ /\.(\d+)/);
	    $dec = length $dec;
	    $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};
	    $form->{"sellprice_$i"} = $form->round_amount($p / $exchangerate, $decimalplaces);
	  }
	}
      }
    }

    
    if ($i < $numrows) {
      $column_data{discount} = qq|<td align=right><input name="discount_$i" class="inputright" size="3" value="|.$form->format_amount(\%myconfig, $form->{"discount_$i"}).qq|"></td>|;
      
      $column_data{itemhref} = qq|<td><a href="ic.pl?login=$form->{login}&path=$form->{path}&action=edit&id=$form->{"id_$i"}" target=_blank>?</a></td>|;
      
      $itemhistory = qq| <a href="ic.pl?action=history&login=$form->{login}&path=$form->{path}&pickvar=sellprice_$i&id=$form->{"id_$i"}" target=popup>?</a>|;
    } else {
      $column_data{discount} = qq|<td></td>|;
      $column_data{itemhref} = qq|<td></td>|;
      $itemhistory = "";
    }
    
    $discount = $form->round_amount($form->{"sellprice_$i"} * $form->{"discount_$i"}/100, $decimalplaces);
    $form->{"linetotal_$i"} = $form->round_amount($form->{"sellprice_$i"} - $discount, $decimalplaces);
    $form->{"linetotal_$i"} = $form->round_amount($form->{"linetotal_$i"} * $form->{"qty_$i"}, $form->{precision});
    
    for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $form->{"linetotal_$i"}; }
  
    $form->{invsubtotal} += $form->{"linetotal_$i"};

    $form->{"linetotal_$i"} = $form->format_amount(\%myconfig, $form->{"linetotal_$i"}, $form->{precision});
    $form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces);
    $form->{"qty_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"});

    for (qw(partnumber sku barcode description partsgroup unit)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}); }
    
    $column_data{partnumber} = qq|<td><input name="partnumber_$i" size=20 value="|.$form->quote($form->{"partnumber_$i"}).qq|" accesskey="$i" title="[$i]"></td>|;

    if (($rows = $form->numtextrows($form->{"description_$i"}, 40, 6)) > 1) {
      $column_data{description} = qq|<td><textarea name="description_$i" rows=$rows cols=46 wrap=soft>$form->{"description_$i"}</textarea></td>|;
    } else {
      $column_data{description} = qq|<td><input name="description_$i" size=48 value="|.$form->quote($form->{"description_$i"}).qq|"></td>|;
    }

    $column_data{qty} = qq|<td align=right><input name="qty_$i" class="inputright" size="8" value="$form->{"qty_$i"}" title="$form->{"onhand_$i"}"></td>|;
    $column_data{onhand} = qq|<td align=right>$form->{"onhand_$i"}</td>|;
    $column_data{unit} = qq|<td>$form->{"unit_$i"}</td>|;
    $column_data{sellprice} = qq|<td align=right nowrap><input name="sellprice_$i" class="inputright" size="11" value="$form->{"sellprice_$i"}">$itemhistory</td>|;
    $column_data{linetotal} = qq|<td align=right>$form->{"linetotal_$i"}</td>|;
    
    print qq|
        <tr valign=top>|;

    for (@column_index) { print "\n$column_data{$_}"; }
  
    print qq|
        </tr>
|;

    for (qw(id linetotal listprice lastcost taxaccounts pricematrix sku barcode partsgroup unit onhand inventory_accno_id income_accno_id expense_accno_id)) { $form->hide_form("${_}_$i") }
    
  }

  print qq|
      </table>
    </td>
  </tr>

<input type=hidden name=oldcurrency value=$form->{currency}>

|;

}


sub assign_number {
  
  $form->{invnumber} = $form->update_defaults(\%myconfig, "sinumber") unless $form->{invnumber};
  &update;

}


sub main_groups {

  # rebuild partsgroup
  $form->get_partsgroup(\%myconfig, { language_code => $form->{language_code}, searchitems => 'nolabor', parentgroup => 1, pos => 1});
  $form->{lookup} = "";
  for (@{ $form->{all_partsgroup} }) {
    if ($_->{pos}) {
      $form->{lookup} .= "$_->{partsgroup}--$_->{translation}--$_->{image}\n";
    }
  }

  $form->{parentgroups} = 1;

  $focus = "partnumber_$form->{rowcount}";
  $form->{rowcount}--;

  &display_form;

}


sub open_drawer {

  if ($form->{cashdrawer}) {
    system($form->unescape($form->{cashdrawer})) == 0 or $form->error($locale->text('Open drawer command failed!'));
  } else {
    $form->error($locale->text('Open drawer command not defined!'));
  }

  &update;
  
}


sub poledisplay {
  my ($i) = @_;

  my %temp;

  if ($form->{poledisplay} && $form->{poledisplayon}) {
    for (qw(partnumber description qty sellprice discount linetotal)) {
      $temp{$_} = $form->{$_};
      $form->{$_} = $form->{"${_}_$i"};
    }
    
    my $arg = $form->format_line($form->unescape($form->{poledisplay}));
    $errfile = time;
    $errfile = "$userspath/$errfile";

    $rc = system("$arg 2>$errfile");
    
    if (-f "$errfile") {
      open FH, "$errfile";
      @err = <FH>;
      close(FH);
      unlink "$errfile";
    }

    if ($rc != 0) {
      if (@err) {
	$form->info(@err);
      } else {
	$form->info($locale->text('Unknown Error!'));
      }
    }

    for (keys %temp) { $form->{$_} = $temp{$_} }

  }
  
}


sub preview {

  $form->{invnumber} ||= "-";
  $form->{media} = "screen";

  &print;

}


sub print {
  
  if (!$form->{invnumber}) {
    if ($form->{media} eq 'screen') {
      $form->{invnumber} = "-";
    } else {
      $form->{invnumber} = $form->update_defaults(\%myconfig, "sinumber");
    }
  }

  $oldform = new Form;
  for (keys %$form) { $oldform->{$_} = $form->{$_}; }
  
  for (qw(employee department)) { $form->{$_} =~ s/--.*//g }
  $form->{invdate} = $form->{transdate};
  @t = localtime;
  for (0 .. 4) { $t[$_] = substr("0$t[$_]", -2) }
  $t[5] += 1900;
  $t[4]++;
  $form->{dateprinted} = $locale->date(\%myconfig, "$t[5]$t[4]$t[3]", $form->{longformat}) . " $t[2]:$t[1]:$t[0]";

  &print_form($oldform);

  for (keys %temp) { $form->{$_} = $temp{$_} }

}


sub print_form {
  my $oldform = shift;
  
  # if oldcustomer ne customer redo form
  $customer = $form->{customer};
  $customer =~ s/--.*//g;
  $customer .= "--$form->{customer_id}";
  if ($customer ne $form->{oldcustomer}) {
    &update;
    exit;
  }

  AA->company_details(\%myconfig, \%$form);

  @a = ();
  for (1 .. $form->{rowcount}) { push @a, ("partnumber_$_", "description_$_"); }
  for (split / /, $form->{taxaccounts}) { push @a, "${_}_description"; }
  $form->format_string(@a);

  # format payment dates
  for (1 .. $form->{paidaccounts}) { $form->{"datepaid_$_"} = $locale->date(\%myconfig, $form->{"datepaid_$_"}); }
 
  IS->invoice_details(\%myconfig, \%$form);

  if (($form->{total} = $form->parse_amount(\%myconfig, $form->{total})) <= 0) {
    $form->{total} = 0;
  } else {
    $form->{change} = 0;
  }

  if ($form->{roundto} > 0.01) {
    $form->{total} = $form->round_amount($form->{total} / $form->{roundto}, 0) * $form->{roundto};
  }

  $form->{total} = $form->format_amount(\%myconfig, $form->{total}, $form->{precision});

  $form->{username} = $myconfig{name};

  push @a, qw(company address tel fax businessnumber companyemail companywebsite username);
  $form->format_string(@a);

  $form->{templates} = "$templates/$myconfig{dbname}";
  $form->{IN} = "$form->{type}.$form->{format}";

  if ($form->{format} =~ /(ps|pdf)/) {
    $form->{IN} =~ s/$&$/tex/;
  }
  
  if ($form->{media} ne 'screen') {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;
  }

  $form->{discount} = $form->format_amount(\%myconfig, $form->{discount} * 100);
  
  $form->{rowcount}--;
  $form->{pre} = "<body bgcolor=#ffffff>\n<pre>";
  delete $form->{stylesheet};

  $form->parse_template(\%myconfig, $userspath, $dvipdf, $xelatex);

  if ($form->{printed} !~ /$form->{formname}/) {
    $form->{printed} .= " $form->{formname}";
    $form->{printed} =~ s/^ //;
    
    $form->update_status(\%myconfig);
  }
  $oldform->{printed} = $form->{printed};

  # if we got back here restore the previous form
  if ($form->{media} ne 'screen') {
    # restore and display form
    for (keys %$oldform) { $form->{$_} = $oldform->{$_}; }
    $form->{exchangerate} = $form->parse_amount(\%myconfig, $form->{exchangerate});

    for $i (1 .. $form->{paidaccounts}) {
      for (qw(paid exchangerate)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}); }
    }

    delete $form->{pre};

    if (! $form->{printandpost}) {
      $form->{rowcount}--;
      &display_form;
    }
  }

}


sub print_and_post {

  $form->error($locale->text('Select a Printer!')) if ($form->{media} eq 'screen');
  $form->{printandpost} = 1;
  &print;
  &post;

}


sub lookup_partsgroup {

  $form->{action} =~ s/\r//;
  $form->{action} = substr($form->{action}, 1);

  if ($form->{language_code}) {
    # get english
    foreach $item (split /\n/, $form->{lookup}) {
      if ($item =~ /$form->{action}/) {
	($partsgroup) = split /--/, $item;
	$form->{action} = $partsgroup;
	last;
      }
    }
  }
  
  $form->{"partsgroup_$form->{rowcount}"} = $form->{action};

  &update;

}



sub print_options {

  $form->{PD}{$form->{type}} = "checked";
  
  print qq|
<table width=100%>
  <tr>
|;

  $form->{formname} = $form->{type};
  $form->hide_form(qw(format formname));
 
  $media = qq|
    <td><input class="radio" type="radio" name="media" value="screen"></td>
    <td>|.$locale->text('Screen').qq|</td>|;

  if ($form->{selectprinter}) {
    for (split /\n/, $form->unescape($form->{selectprinter})) { $media .= qq|
    <td><input class="radio" type="radio" name="media" value="$_"></td>
    <td nowrap>$_</td>
|;
    }
  }

  $media =~ s/(value="\Q$form->{media}\E")/$1 checked/;

  print qq|
  $media
  <td nowrap align=right width=20%><input name=poledisplayon type=checkbox class=checkbox $form->{poledisplayon}> |.$locale->text('Poledisplay').qq|</td>
  <td width=99%>&nbsp;</td>|;
  
  if ($form->{printed} =~ /$form->{type}/) {
    print qq|
    <th>\||.$locale->text('Printed').qq|\|</th>|;
  }
  
  print qq|
  </tr>
</table>
|;

}


sub receipts {

  $form->{title} = $locale->text('Receipts');

  $form->{vc} = 'customer';
  $form->{db} = 'ar';
  RP->paymentaccounts(\%myconfig, \%$form);
  
  $form->{paymentaccounts} = "";
  for (@{ $form->{PR} } ) { $form->{paymentaccounts} .= "$_->{accno} "; }

  if (@{ $form->{all_years} }) {
    # accounting years
    $selectaccountingyear = "\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|$_\n| }
    $selectaccountingmonth = "\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|$_--|.$locale->text($form->{all_month}{$_}).qq|\n|; }

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

  $form->header;
  
  &calendar;
  
  print qq|
<body>

<form method="post" name="main" action="$form->{script}">
|;

  $form->{sort} = "transdate";	  
  $form->{till} = 1;
  $form->{subtotal} = 1;
  $form->{nextsub} = "list_payments";

  $form->helpref("pos_receipts", $myconfig{countrycode});

  $form->hide_form(qw(nextsub sort title paymentaccounts till subtotal helpref));

  @a = qw(transdate reference name customernumber description paid curr source till);
  for (@a) { $form->{"l_$_"} = "Y" }
  $form->hide_form(map { "l_$_" } @a);
  
  print qq|
<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td colspan=3>
	    <table>
	      <tr>
		<td nowrap><input name=fromdate size=11 class=date title="$myconfig{dateformat}" value=$form->{fromdate}>|.&js_calendar("main", "fromdate").qq|</td>
		<th align=right>|.$locale->text('To').qq|</th>
		<td nowrap><input name=todate size=11 class=date title="$myconfig{dateformat}">|.&js_calendar("main", "todate").qq|</td>
	      </tr>
	    </table>
	  </td>
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
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
|;

  $form->hide_form(qw(vc db path login));

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


