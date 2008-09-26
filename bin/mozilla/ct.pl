#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# customer/vendor module
#
#======================================================================

use SL::CT;

1;
# end of main



sub add {

  $form->{title} = "Add";

  $form->{callback} = "$form->{script}?action=add&db=$form->{db}&typeofcontact=$form->{typeofcontact}&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &create_links;
 
  &form_header;
  &form_footer;

}


sub edit {

  $form->{title} = "Edit";

  &create_links;
  
  &form_header;
  &form_footer;
 
}


sub create_links {
  
  $form->{ARAP} = ($form->{db} eq 'customer') ? 'AR' : 'AP';
  
  CT->create_links(\%myconfig, \%$form);

  for (keys %$form) { $form->{$_} = $form->quote($form->{$_}) }

  for (qw(discount cashdiscount)) { $form->{$_} *= 100 }
  
  $form->{contactid} = $form->{all_contact}->[0]->{id};
  if ($form->{all_contact}->[0]->{typeofcontact}) {
    $form->{typeofcontact} = $form->{all_contact}->[0]->{typeofcontact};
  }
  $form->{typeofcontact} ||= "company";
  for (qw(email phone fax mobile salutation firstname lastname gender contacttitle occupation)) { $form->{$_} = $form->{all_contact}->[0]->{$_} }
  $form->{gender} ||= 'M';
  
  if ($form->{currencies}) {
    # currencies
    for (split /:/, $form->{currencies}) { $form->{selectcurrency} .= "$_\n" }
  }

  # accounts
  foreach $item (qw(arap discount payment)) {
    if (@ { $form->{"${item}_accounts"} }) {
      $form->{"select$item"} = "\n";
      for (@{ $form->{"${item}_accounts"} }) { $form->{"select$item"} .= qq|$_->{accno}--$_->{description}\n| }

      $form->{"select$item"} = $form->escape($form->{"select$item"},1);
    }
  }
  
  if (@{ $form->{all_business} }) {
    $form->{selectbusiness} = qq|\n|;
    for (@{ $form->{all_business} }) { $form->{selectbusiness} .= qq|$_->{description}--$_->{id}\n| }
    $form->{selectbusiness} = $form->escape($form->{selectbusiness},1);
  }
  
  if (@{ $form->{all_paymentmethod} }) {
    $form->{selectpaymentmethod} = qq|\n|;
    for (@{ $form->{all_paymentmethod} }) { $form->{selectpaymentmethod} .= qq|$_->{description}--$_->{id}\n| }
    $form->{selectpaymentmethod} = $form->escape($form->{selectpaymentmethod},1);
  }

  if (@{ $form->{all_pricegroup} } && $form->{db} eq 'customer') {
    $form->{selectpricegroup} = qq|\n|;
    for (@{ $form->{all_pricegroup} }) { $form->{selectpricegroup} .= qq|$_->{pricegroup}--$_->{id}\n| }
    $form->{selectpricegroup} = $form->escape($form->{selectpricegroup},1);
  }
  
  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = qq|\n|;
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
    $form->{selectlanguage} = $form->escape($form->{selectlanguage},1);
  }

  if (@{ $form->{all_employee} }) {
    $form->{selectemployee} = qq|\n|;
    for (@{ $form->{all_employee} }) {
      $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n|;
    }
    $form->{selectemployee} = $form->escape($form->{selectemployee},1);
  }

}

 
sub history {

# $locale->text('Customer History')
# $locale->text('Vendor History')

  $history = 1;
  $label = ucfirst $form->{db};
  $label .= " History";

  if ($form->{db} eq 'customer') {
    $invlabel = $locale->text('Sales Invoices');
    $ordlabel = $locale->text('Sales Orders');
    $quolabel = $locale->text('Quotations');
  } else {
    $invlabel = $locale->text('Vendor Invoices');
    $ordlabel = $locale->text('Purchase Orders');
    $quolabel = $locale->text('Request for Quotations');
  }
  
  $form->{title} = $locale->text($label);
  
  $form->{nextsub} = "list_history";

  $transactions = qq|
 	<tr>
	  <td></td>
	  <td>
	    <table>
	      <tr>
	        <td>
		  <table>
		    <tr>
		      <td><input name=type type=radio class=radio value=invoice checked> $invlabel</td>
		    </tr>
		    <tr>
		      <td><input name=type type=radio class=radio value=order> $ordlabel</td>
		    </tr>
		    <tr>
		      <td><input name="type" type=radio class=radio value=quotation> $quolabel</td>
		    </tr>
		  </table>
		</td>
		<td>
		  <table>
		    <tr>
		      <th>|.$locale->text('From').qq|</th>
		      <td><input name=transdatefrom size=11 class=date title="$myconfig{dateformat}"></td>
		      <th>|.$locale->text('To').qq|</th>
		      <td><input name=transdateto size=11 class=date title="$myconfig{dateformat}"></td>
		    </tr>
		    <tr>
		      <td></td>
		      <td colspan=3>
	              <input name="open" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Open').qq|
	              <input name="closed" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Closed').qq|
		      </td>
		    </tr>
		  </table>
		</td>
	      </tr>
 	    </table>
	  </td>
	</tr>
|;

  $include = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table>
	      <tr>
		<td><input name=history type=radio class=radio value=summary checked> |.$locale->text('Summary').qq|</td>
		<td><input name=history type=radio class=radio value=detail> |.$locale->text('Detail').qq|
		</td>
	      </tr>
	      <tr>
		<td>
		<input name="l_partnumber" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Part Number').qq|
		</td>
		<td>
		<input name="l_description" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Description').qq|
		</td>
		<td>
		<input name="l_sellprice" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Sell Price').qq|
		</td>
		<td>
		<input name="l_curr" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Currency').qq|
		</td>
	      </tr>
	      <tr>
		<td>
		<input name="l_qty" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Qty').qq|
		</td>
		<td>
		<input name="l_unit" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Unit').qq|
		</td>
		<td>
		<input name="l_discount" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Discount').qq|
		</td>
	      <tr>
	      </tr>
		<td>
		<input name="l_deliverydate" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Delivery Date').qq|
		</td>
		<td>
		<input name="l_projectnumber" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Project Number').qq|
		</td>
		<td>
		<input name="l_serialnumber" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Serial Number').qq|
		</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

  &search_name;
  
  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
</body>
</html>
|;

}


sub transactions {

  if ($form->{db} eq 'customer') {
    $translabel = $locale->text('AR Transactions');
    $invlabel = $locale->text('Sales Invoices');
    $ordlabel = $locale->text('Sales Orders');
    $quolabel = $locale->text('Quotations');
  } else {
    $translabel = $locale->text('AP Transactions');
    $invlabel = $locale->text('Vendor Invoices');
    $ordlabel = $locale->text('Purchase Orders');
    $quolabel = $locale->text('Request for Quotations');
  }

 
  $transactions = qq|
 	<tr>
	  <td></td>
	  <td>
	    <table>
	      <tr>
	        <td>
		  <table>
		    <tr>
		      <td><input name="l_transnumber" type=checkbox class=checkbox value=Y> $translabel</td>
		    </tr>
		    <tr>
		      <td><input name="l_invnumber" type=checkbox class=checkbox value=Y> $invlabel</td>
		    </tr>
		    <tr>
		      <td><input name="l_ordnumber" type=checkbox class=checkbox value=Y> $ordlabel</td>
		    </tr>
		    <tr>
		      <td><input name="l_quonumber" type=checkbox class=checkbox value=Y> $quolabel</td>
		    </tr>
		  </table>
		</td>
		<td>
		  <table>
		    <tr>
		      <th>|.$locale->text('From').qq|</th>
		      <td><input name=transdatefrom size=11 class=date title="$myconfig{dateformat}"></td>
		      <th>|.$locale->text('To').qq|</th>
		      <td><input name=transdateto size=11 class=date title="$myconfig{dateformat}"></td>
		    </tr>
		    <tr>
		      <td></td>
		      <td colspan=3>
	              <input name="open" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Open').qq|
	              <input name="closed" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Closed').qq|
		      </td>
		    </tr>
		    <tr>
		      <td></td>
		      <td colspan=3>
	              <input name="l_amount" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Amount').qq|
	              <input name="l_tax" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Tax').qq|
	              <input name="l_total" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Total').qq|
	              <input name="l_subtotal" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|
		      </td>
		    </tr>
		  </table>
		</td>
	      </tr>
 	    </table>
	  </td>
	</tr>
|;

}


sub include_in_report {
  
  if ($form->{db} eq 'customer') {
    $vcname = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
  } else {
    $vcname = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
  }

  @a = ();
  
  push @a, qq|<input name="l_ndx" type=checkbox class=checkbox value=Y> |.$locale->text('No.');
  push @a, qq|<input name="l_id" type=checkbox class=checkbox value=Y> |.$locale->text('ID');
  push @a, qq|<input name="l_name" type=checkbox class=checkbox value=Y $form->{l_name}> $vcname|;
  push @a, qq|<input name="l_$form->{db}number" type=checkbox class=checkbox value=Y> $vcnumber|;
  push @a, qq|<input name="l_contact" type=checkbox class=checkbox value=Y $form->{l_contact}> |.$locale->text('Contact');
  push @a, qq|<input name="l_email" type=checkbox class=checkbox value=Y $form->{l_email}> |.$locale->text('E-mail');
  push @a, qq|<input name="l_address" type=checkbox class=checkbox value=Y> |.$locale->text('Address');
  push @a, qq|<input name="l_city" type=checkbox class=checkbox value=Y> |.$locale->text('City');
  push @a, qq|<input name="l_state" type=checkbox class=checkbox value=Y> |.$locale->text('State/Province');
  push @a, qq|<input name="l_zipcode" type=checkbox class=checkbox value=Y> |.$locale->text('Zip/Postal Code');
  push @a, qq|<input name="l_country" type=checkbox class=checkbox value=Y> |.$locale->text('Country');
  push @a, qq|<input name="l_phone" type=checkbox class=checkbox value=Y $form->{l_phone}> |.$locale->text('Phone');
  push @a, qq|<input name="l_fax" type=checkbox class=checkbox value=Y> |.$locale->text('Fax');
  push @a, qq|<input name="l_cc" type=checkbox class=checkbox value=Y> |.$locale->text('Cc');
  
  if ($myconfig{role} =~ /(admin|manager)/) {
    push @a, qq|<input name="l_bcc" type=checkbox class=checkbox value=Y> |.$locale->text('Bcc');
  }

  push @a, qq|<input name="l_notes" type=checkbox class=checkbox value=Y> |.$locale->text('Notes');
  push @a, qq|<input name="l_discount" type=checkbox class=checkbox value=Y> |.$locale->text('Discount');
  push @a, qq|<input name="l_threshold" type=checkbox class=checkbox value=Y> |.$locale->text('Threshold');
  push @a, qq|<input name="l_accounts" type=checkbox class=checkbox value=Y> |.$locale->text('Accounts');
  push @a, qq|<input name="l_paymentmethod" type=checkbox class=checkbox value=Y> |.$locale->text('Payment Method');
  push @a, qq|<input name="l_taxnumber" type=checkbox class=checkbox value=Y> |.$locale->text('Tax Number');
  
  if ($form->{db} eq 'customer') {
    push @a, qq|<input name="l_employee" type=checkbox class=checkbox value=Y> |.$locale->text('Salesperson');
    push @a, qq|<input name="l_manager" type=checkbox class=checkbox value=Y> |.$locale->text('Manager');
    push @a, qq|<input name="l_pricegroup" type=checkbox class=checkbox value=Y> |.$locale->text('Pricegroup');

  } else {
    push @a, qq|<input name="l_employee" type=checkbox class=checkbox value=Y> |.$locale->text('Employee');
    push @a, qq|<input name="l_manager" type=checkbox class=checkbox value=Y> |.$locale->text('Manager');
    push @a, qq|<input name="l_gifi_accno" type=checkbox class=checkbox value=Y> |.$locale->text('GIFI');

  }

  push @a, qq|<input name="l_sic_code" type=checkbox class=checkbox value=Y> |.$locale->text('SIC');
  push @a, qq|<input name="l_iban" type=checkbox class=checkbox value=Y> |.$locale->text('IBAN');
  push @a, qq|<input name="l_bic" type=checkbox class=checkbox value=Y> |.$locale->text('BIC');
  push @a, qq|<input name="l_business" type=checkbox class=checkbox value=Y> |.$locale->text('Type of Business');
  push @a, qq|<input name="l_creditlimit" type=checkbox class=checkbox value=Y> |.$locale->text('Credit Limit');
  push @a, qq|<input name="l_terms" type=checkbox class=checkbox value=Y> |.$locale->text('Terms');
  push @a, qq|<input name="l_language" type=checkbox class=checkbox value=Y> |.$locale->text('Language');
  push @a, qq|<input name="l_remittancevoucher" type=checkbox class=checkbox value=Y> |.$locale->text('Remittance Voucher');
  push @a, qq|<input name="l_startdate" type=checkbox class=checkbox value=Y> |.$locale->text('Startdate');
  push @a, qq|<input name="l_enddate" type=checkbox class=checkbox value=Y> |.$locale->text('Enddate');

   
  $include = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table>
|;

  while (@a) {
    $include .= qq|<tr>\n|;
    for (1 .. 5) {
      $include .= qq|<td nowrap>|. shift @a;
      $include .= qq|</td>\n|;
    }
    $include .= qq|</tr>\n|;
  }

  $include .= qq|
	    </table>
	  </td>
	</tr>
|;

}


sub search {

# $locale->text('Customers')
# $locale->text('Vendors')

  $form->{title} = $locale->text('Search') unless $form->{title};
  
  for (qw(name contact phone email)) { $form->{"l_$_"} = 'checked' }

  $form->{nextsub} = "list_names";

  $orphan = qq|
        <tr>
          <td></td>
	  <td><input name=status class=radio type=radio value=all checked>&nbsp;|.$locale->text('All').qq|
	  <input name=status class=radio type=radio value=active>&nbsp;|.$locale->text('Active').qq|
	  <input name=status class=radio type=radio value=inactive>&nbsp;|.$locale->text('Inactive').qq|
	  <input name=status class=radio type=radio value=orphaned>&nbsp;|.$locale->text('Orphaned').qq|</td>
	</tr>
|;


  &transactions;
  &include_in_report;
  &search_name;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
	      
</body>
</html>
|;

}


sub search_name {

  if ($form->{db} eq 'customer') {
    $vcname = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
    
    $form->{ARAP} = "AR";
    $employee = qq|
 	  <th align=right nowrap>|.$locale->text('Salesperson').qq|</th>
	  <td><input name=employee size=32></td>
|;
  }
  if ($form->{db} eq 'vendor') {
    $vcname = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
    
    $form->{ARAP} = "AP";
    $employee = qq|
 	  <th align=right nowrap>|.$locale->text('Employee').qq|</th>
	  <td><input name=employee size=32></td>
|;
  }
 
  $focus = "name";

  $form->header;
  
  print qq|
<body onLoad="document.forms[0].${focus}.focus()" />

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
	<tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>$vcname</th>
		<td><input name=name size=32></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Contact').qq|</th>
		<td><input name=contact size=32></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('E-mail').qq|</th>
		<td><input name=email size=32></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Phone').qq|</th>
		<td><input name=phone size=20></td>
	      </tr>
	      <tr>
		$employee
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Notes').qq|</th>
		<td colspan=3><textarea name=notes rows=3 cols=32></textarea></td>
	      </tr>
	    </table>
	  </td>

	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>$vcnumber</th>
		<td><input name=$form->{db}number size=32></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Address').qq|</th>
		<td><input name=address size=32></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('City').qq|</th>
		<td><input name=city size=32></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('State/Province').qq|</th>
		<td><input name=state size=32></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Zip/Postal Code').qq|</th>
		<td><input name=zipcode size=10></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Country').qq|</th>
		<td><input name=country size=32></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Startdate').qq|</th>
		<td>|.$locale->text('From').qq| <input name=startdatefrom size=11 class=date title="$myconfig{dateformat}"> |.$locale->text('To').qq| <input name=startdateto size=11 class=date title="$myconfig{dateformat}"></td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>
      <table>

	$orphan
	$transactions
	$include

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

  $form->hide_form(qw(ARAP db nextsub path login));

  print qq|
</form>
|;

}


sub list_names {

  CT->search(\%myconfig, \%$form);
  
  $href = "$form->{script}?action=list_names";
  for (qw(direction oldsort db ARAP path login status l_subtotal)) { $href .= "&$_=$form->{$_}" }
  
  $form->sort_order();
  
  $callback = "$form->{script}?action=list_names";
  for (qw(direction oldsort db ARAP path login status l_subtotal)) { $callback .= "&$_=$form->{$_}" }
  
  if ($form->{db} eq 'customer') {
    $vcname = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
  } else {
    $vcname = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
  }
  
  @columns = (id, name, "$form->{db}number", address,
             city, state, zipcode, country, contact,
	     phone, fax, email, cc, bcc, employee,
	     manager, notes, discount, terms, creditlimit);

  if ($form->{l_accounts}) {
    for (arap_accno, payment_accno, discount_accno, taxaccounts) {
      $form->{"l_$_"} = "Y";
      push @columns, $_;
    }
    $callback .= "&l_accounts=Y";
    $href .= "&l_accounts=Y";
  }

  push @columns, (
	     paymentmethod,
	     threshold, taxnumber, gifi_accno, sic_code, business,
	     pricegroup, language, iban, bic, remittancevoucher,
	     startdate, enddate,
	     invnumber, invamount, invtax, invtotal,
	     ordnumber, ordamount, ordtax, ordtotal,
	     quonumber, quoamount, quotax, quototal);
  @columns = $form->sort_columns(@columns);
  unshift @columns, "ndx";

  $form->{l_invnumber} = "Y" if $form->{l_transnumber};
  foreach $item (qw(inv ord quo)) {
    if ($form->{"l_${item}number"}) {
      for (qw(amount tax total)) { $form->{"l_$item$_"} = $form->{"l_$_"} }
      $removeemployee = 1;
      $openclosed = 1;
    }
  }
  $form->{open} = $form->{closed} = "" if !$openclosed;


  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;
      # add column to href and callback
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }
  
  foreach $item (qw(amount tax total transnumber)) {
    if ($form->{"l_$item"} eq "Y") { 
      $callback .= "&l_$item=Y"; 
      $href .= "&l_$item=Y"; 
    }
  }


  if ($form->{status} eq 'all') {
    $option = $locale->text('All');
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

  if ($form->{name}) {
    $callback .= "&name=".$form->escape($form->{name},1);
    $href .= "&name=".$form->escape($form->{name});
    $option .= "\n<br>$vcname : $form->{name}";
  }
  if ($form->{address}) {
    $callback .= "&address=".$form->escape($form->{address},1);
    $href .= "&address=".$form->escape($form->{address});
    $option .= "\n<br>".$locale->text('Address')." : $form->{address}";
  }
  if ($form->{city}) {
    $callback .= "&city=".$form->escape($form->{city},1);
    $href .= "&city=".$form->escape($form->{city});
    $option .= "\n<br>".$locale->text('City')." : $form->{city}";
  }
  if ($form->{state}) {
    $callback .= "&state=".$form->escape($form->{state},1);
    $href .= "&state=".$form->escape($form->{state});
    $option .= "\n<br>".$locale->text('State')." : $form->{state}";
  }
  if ($form->{zipcode}) {
    $callback .= "&zipcode=".$form->escape($form->{zipcode},1);
    $href .= "&zipcode=".$form->escape($form->{zipcode});
    $option .= "\n<br>".$locale->text('Zip/Postal Code')." : $form->{zipcode}";
  }
  if ($form->{country}) {
    $callback .= "&country=".$form->escape($form->{country},1);
    $href .= "&country=".$form->escape($form->{country});
    $option .= "\n<br>".$locale->text('Country')." : $form->{country}";
  }
  if ($form->{contact}) {
    $callback .= "&contact=".$form->escape($form->{contact},1);
    $href .= "&contact=".$form->escape($form->{contact});
    $option .= "\n<br>".$locale->text('Contact')." : $form->{contact}";
  }
  if ($form->{employee}) {
    $callback .= "&employee=".$form->escape($form->{employee},1);
    $href .= "&employee=".$form->escape($form->{employee});
    $option .= "\n<br>";
    if ($form->{db} eq 'customer') {
      $option .= $locale->text('Salesperson');
    }
    if ($form->{db} eq 'vendor') {
      $option .= $locale->text('Employee');
    }
    $option .= " : $form->{employee}";
  }

  $fromdate = "";
  $todate = "";
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
    $option .= "\n<br>".$locale->text('Notes')." : $form->{notes}";
  }
  if ($form->{"$form->{db}number"}) {
    $callback .= qq|&$form->{db}number=|.$form->escape($form->{"$form->{db}number"},1);
    $href .= "&$form->{db}number=".$form->escape($form->{"$form->{db}number"});
    $option .= qq|\n<br>$vcnumber : $form->{"$form->{db}number"}|;
  }
  if ($form->{phone}) {
    $callback .= "&phone=".$form->escape($form->{phone},1);
    $href .= "&phone=".$form->escape($form->{phone});
    $option .= "\n<br>".$locale->text('Phone')." : $form->{phone}";
  }
  if ($form->{email}) {
    $callback .= "&email=".$form->escape($form->{email},1);
    $href .= "&email=".$form->escape($form->{email});
    $option .= "\n<br>".$locale->text('E-mail')." : $form->{email}";
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
    if ($form->{transdatefrom}) {
      $option .= " ";
    } else {
      $option .= "\n<br>" if ($option);
    }
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{transdateto}, 1);
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
  

  $form->{callback} = "$callback&sort=$form->{sort}";
  $callback = $form->escape($form->{callback});
  
  $column_header{ndx} = qq|<th class=listheading width=1%>&nbsp;</th>|;
  $column_header{id} = qq|<th class=listheading>|.$locale->text('ID').qq|</th>|;
  $column_header{"$form->{db}number"} = qq|<th><a class=listheading href=$href&sort=$form->{db}number>$vcnumber</a></th>|;
  $column_header{name} = qq|<th><a class=listheading href=$href&sort=name>$vcname</a></th>|;
  $column_header{address} = qq|<th class=listheading>|.$locale->text('Address').qq|</th>|;
  $column_header{city} = qq|<th><a class=listheading href=$href&sort=city>|.$locale->text('City').qq|</a></th>|;
  $column_header{state} = qq|<th><a class=listheading href=$href&sort=state>|.$locale->text('State/Province').qq|</a></th>|;
  $column_header{zipcode} = qq|<th><a class=listheading href=$href&sort=zipcode>|.$locale->text('Zip/Postal Code').qq|</a></th>|;
  $column_header{country} = qq|<th><a class=listheading href=$href&sort=country>|.$locale->text('Country').qq|</a></th>|;
  $column_header{contact} = qq|<th><a class=listheading href=$href&sort=contact>|.$locale->text('Contact').qq|</a></th>|;
  $column_header{phone} = qq|<th><a class=listheading href=$href&sort=phone>|.$locale->text('Phone').qq|</a></th>|;
  $column_header{fax} = qq|<th><a class=listheading href=$href&sort=fax>|.$locale->text('Fax').qq|</a></th>|;
  $column_header{email} = qq|<th><a class=listheading href=$href&sort=email>|.$locale->text('E-mail').qq|</a></th>|;
  $column_header{cc} = qq|<th><a class=listheading href=$href&sort=cc>|.$locale->text('Cc').qq|</a></th>|;
  $column_header{bcc} = qq|<th><a class=listheading href=$href&sort=cc>|.$locale->text('Bcc').qq|</a></th>|;
  $column_header{notes} = qq|<th><a class=listheading href=$href&sort=notes>|.$locale->text('Notes').qq|</a></th>|;
  $column_header{discount} = qq|<th class=listheading>%</th>|;
  $column_header{terms} = qq|<th class=listheading>|.$locale->text('Terms').qq|</th>|;
  $column_header{threshold} = qq|<th class=listheading>|.$locale->text('Threshold').qq|</th>|;
  $column_header{paymentmethod} = qq|<th><a class=listheading href=$href&sort=paymentmethod>|.$locale->text('Payment Method').qq|</a></th>|;
  $column_header{creditlimit} = qq|<th class=listheading>|.$locale->text('Credit Limit').qq|</th>|;

# $locale->text('AR')
# $locale->text('AP')

  $column_header{arap_accno} = qq|<th class=listheading>|.$locale->text($form->{ARAP}).qq|</th>|;
  $column_header{payment_accno} = qq|<th class=listheading>|.$locale->text('Payment').qq|</th>|;
  $column_header{discount_accno} = qq|<th class=listheading>|.$locale->text('Discount').qq|</th>|;
  $column_header{taxaccounts} = qq|<th class=listheading>|.$locale->text('Tax').qq|</th>|;

  $column_header{taxnumber} = qq|<th><a class=listheading href=$href&sort=taxnumber>|.$locale->text('Tax Number').qq|</a></th>|;
  $column_header{gifi_accno} = qq|<th><a class=listheading href=$href&sort=gifi_accno>|.$locale->text('GIFI').qq|</a></th>|;
  $column_header{sic_code} = qq|<th><a class=listheading href=$href&sort=sic_code>|.$locale->text('SIC').qq|</a></th>|;
  $column_header{business} = qq|<th><a class=listheading href=$href&sort=business>|.$locale->text('Type of Business').qq|</a></th>|;
  $column_header{iban} = qq|<th class=listheading>|.$locale->text('IBAN').qq|</th>|;
  $column_header{bic} = qq|<th class=listheading>|.$locale->text('BIC').qq|</th>|;
  $column_header{remittancevoucher} = qq|<th class=listheading>|.$locale->text('RV').qq|</th>|;
  $column_header{startdate} = qq|<th><a class=listheading href=$href&sort=startdate>|.$locale->text('Startdate').qq|</a></th>|;
  $column_header{enddate} = qq|<th><a class=listheading href=$href&sort=enddate>|.$locale->text('Enddate').qq|</a></th>|;
  
  $column_header{invnumber} = qq|<th><a class=listheading href=$href&sort=invnumber>|.$locale->text('Invoice').qq|</a></th>|;
  $column_header{ordnumber} = qq|<th><a class=listheading href=$href&sort=ordnumber>|.$locale->text('Order').qq|</a></th>|;
  $column_header{quonumber} = qq|<th><a class=listheading href=$href&sort=quonumber>|.$locale->text('Quotation').qq|</a></th>|;

  if ($form->{db} eq 'customer') {
    $column_header{employee} = qq|<th><a class=listheading href=$href&sort=employee>|.$locale->text('Salesperson').qq|</a></th>|;
  } else {
    $column_header{employee} = qq|<th><a class=listheading href=$href&sort=employee>|.$locale->text('Employee').qq|</a></th>|;
  }
  $column_header{manager} = qq|<th><a class=listheading href=$href&sort=manager>|.$locale->text('Manager').qq|</a></th>|;

  $column_header{pricegroup} = qq|<th><a class=listheading href=$href&sort=pricegroup>|.$locale->text('Pricegroup').qq|</a></th>|;
  $column_header{language} = qq|<th><a class=listheading href=$href&sort=language>|.$locale->text('Language').qq|</a></th>|;
  

  $amount = $locale->text('Amount');
  $tax = $locale->text('Tax');
  $total = $locale->text('Total');
  
  $column_header{invamount} = qq|<th class=listheading>$amount</th>|;
  $column_header{ordamount} = qq|<th class=listheading>$amount</th>|;
  $column_header{quoamount} = qq|<th class=listheading>$amount</th>|;
  
  $column_header{invtax} = qq|<th class=listheading>$tax</th>|;
  $column_header{ordtax} = qq|<th class=listheading>$tax</th>|;
  $column_header{quotax} = qq|<th class=listheading>$tax</th>|;
  
  $column_header{invtotal} = qq|<th class=listheading>$total</th>|;
  $column_header{ordtotal} = qq|<th class=listheading>$total</th>|;
  $column_header{quototal} = qq|<th class=listheading>$total</th>|;
 

  if ($form->{status}) {
    $form->{title} = ($form->{db} eq 'customer') ? $locale->text('Customers') : $locale->text('Vendors');
  } else {
    $form->{title} = ($form->{db} eq 'customer') ? $locale->text('Customer Transactions') : $locale->text('Vendor Transactions');
  }

  $title = "$form->{title} / $form->{company}";
  
  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$title</th>
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

  $ordertype = ($form->{db} eq 'customer') ? 'sales_order' : 'purchase_order';
  $quotationtype = ($form->{db} eq 'customer') ? 'sales_quotation' : 'request_quotation';
  $subtotal = 0;

  $i = 0;
  foreach $ref (@{ $form->{CT} }) {

    if ($ref->{$form->{sort}} ne $sameitem && $form->{l_subtotal}) {
      # print subtotal
      if ($subtotal) {
	for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
	&list_subtotal;
      }
    }

    if ($ref->{id} eq $sameid) {
      for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
    } else {
    
      $i++;
      
      $ref->{notes} =~ s/\r?\n/<br>/g;
      for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

      $column_data{ndx} = "<td align=right>$i</td>";
      
      if ($ref->{$form->{sort}} eq $sameitem) {
	$column_data{$form->{sort}} = "<td>&nbsp;</td>";
      }
	
      $column_data{address} = "<td>$ref->{address1} $ref->{address2}&nbsp;</td>";
      $column_data{name} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&db=$form->{db}&path=$form->{path}&login=$form->{login}&status=$form->{status}&callback=$callback>$ref->{name}&nbsp;</td>";

      $email = "";
      if ($form->{sort} =~ /(email|cc)/) {
	if ($ref->{$form->{sort}} ne $sameitem) {
	  $email = 1;
	}
      } else {
	$email = 1;
      }
      
      if ($email) {
	foreach $item (qw(email cc bcc)) {
	  if ($ref->{$item}) {
	    $email = $ref->{$item};
	    $email =~ s/</\&lt;/;
	    $email =~ s/>/\&gt;/;
	    
	    $column_data{$item} = qq|<td><a href="mailto:$ref->{$item}">$email</a></td>|;
	  }
	}
      }
    }
    
    if ($ref->{formtype} eq 'invoice') {
      $column_data{invnumber} = "<td><a href=$ref->{module}.pl?action=edit&id=$ref->{invid}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{invnumber}&nbsp;</td>";
      
      $column_data{invamount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{netamount}, $form->{precision}, "&nbsp;")."</td>";
      $column_data{invtax} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} - $ref->{netamount}, $form->{precision}, "&nbsp;")."</td>";
      $column_data{invtotal} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}, "&nbsp;")."</td>";

      $invamountsubtotal += $ref->{netamount};
      $invtaxsubtotal += ($ref->{amount} - $ref->{netamount});
      $invtotalsubtotal += $ref->{amount};
      $subtotal = 1;
    }
     
    if ($ref->{formtype} eq 'order') {
      $column_data{ordnumber} = "<td><a href=$ref->{module}.pl?action=edit&id=$ref->{invid}&type=$ordertype&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{ordnumber}&nbsp;</td>";
      
      $column_data{ordamount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{netamount}, $form->{precision}, "&nbsp;")."</td>";
      $column_data{ordtax} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} - $ref->{netamount}, $form->{precision}, "&nbsp;")."</td>";
      $column_data{ordtotal} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}, "&nbsp;")."</td>";

      $ordamountsubtotal += $ref->{netamount};
      $ordtaxsubtotal += ($ref->{amount} - $ref->{netamount});
      $ordtotalsubtotal += $ref->{amount};
      $subtotal = 1;
    }

    if ($ref->{formtype} eq 'quotation') {
      $column_data{quonumber} = "<td><a href=$ref->{module}.pl?action=edit&id=$ref->{invid}&type=$quotationtype&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{quonumber}&nbsp;</td>";
      
      $column_data{quoamount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{netamount}, $form->{precision}, "&nbsp;")."</td>";
      $column_data{quotax} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} - $ref->{netamount}, $form->{precision}, "&nbsp;")."</td>";
      $column_data{quototal} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}, "&nbsp;")."</td>";

      $quoamountsubtotal += $ref->{netamount};
      $quotaxsubtotal += ($ref->{amount} - $ref->{netamount});
      $quototalsubtotal += $ref->{amount};
      $subtotal = 1;
    }
    
    if ($sameid ne "$ref->{id}") {
      if ($form->{l_discount}) {
	$column_data{discount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{discount} * 100, undef, "&nbsp;")."</td>";
      }
      if ($form->{l_terms}) {
	@a = ();
	push @a, $form->format_amount(\%myconfig, $ref->{cashdiscount} * 100, undef) if $ref->{cashdiscount};
	push @a, $ref->{discountterms} if $ref->{discountterms};
	push @a, $ref->{terms} if $ref->{terms};
	
	$a = join '/', @a;
	$column_data{terms} = "<td>&nbsp;$a</td>";
      }
      if ($form->{l_threshold}) {
	$column_data{threshold} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{threshold}, 0, "&nbsp;")."</td>";
      }
      if ($form->{l_creditlimit}) {
	$column_data{creditlimit} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{creditlimit}, 0, "&nbsp;")."</td>";
      }
      if ($form->{l_remittancevoucher}) {
	$column_data{remittancevoucher} = "<td align=center>". (($ref->{remittancevoucher}) ? "*" : "&nbsp;") . "</td>";
      }
    }
   
    $j++; $j %= 2;
    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
        </tr>
|;
    
    $sameitem = "$ref->{$form->{sort}}";
    $sameid = $ref->{id};

  }

  if ($form->{l_subtotal} && $subtotal) {
    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
    &list_subtotal;
  }
  
  $i = 1;
  if ($myconfig{acs} !~ /AR--AR/) {
    if ($form->{db} eq 'customer') {
      $button{'AR--Customers--Add Customer'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Customer').qq|"> |;
      $button{'AR--Customers--Add Customer'}{order} = $i++;
    }
  }
  if ($myconfig{acs} !~ /AP--AP/) {
    if ($form->{db} eq 'vendor') {
      $button{'AP--Vendors--Add Vendor'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Vendor').qq|"> |;
      $button{'AP--Vendors--Add Vendor'}{order} = $i++;
    }
  }
  
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
  
  if ($form->{status}) {
    foreach $item (sort { $a->{order} <=> $b->{order} } %button) {
      print $item->{code};
    }
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


sub list_subtotal {

	$column_data{invamount} = "<td align=right>".$form->format_amount(\%myconfig, $invamountsubtotal, $form->{precision}, "&nbsp;")."</td>";
	$column_data{invtax} = "<td align=right>".$form->format_amount(\%myconfig, $invtaxsubtotal, $form->{precision}, "&nbsp;")."</td>";
	$column_data{invtotal} = "<td align=right>".$form->format_amount(\%myconfig, $invtotalsubtotal, $form->{precision}, "&nbsp;")."</td>";

	$invamountsubtotal = 0;
	$invtaxsubtotal = 0;
	$invtotalsubtotal = 0;

	$column_data{ordamount} = "<td align=right>".$form->format_amount(\%myconfig, $ordamountsubtotal, $form->{precision}, "&nbsp;")."</td>";
	$column_data{ordtax} = "<td align=right>".$form->format_amount(\%myconfig, $ordtaxsubtotal, $form->{precision}, "&nbsp;")."</td>";
	$column_data{ordtotal} = "<td align=right>".$form->format_amount(\%myconfig, $ordtotalsubtotal, $form->{precision}, "&nbsp;")."</td>";

	$ordamountsubtotal = 0;
	$ordtaxsubtotal = 0;
	$ordtotalsubtotal = 0;

	$column_data{quoamount} = "<td align=right>".$form->format_amount(\%myconfig, $quoamountsubtotal, $form->{precision}, "&nbsp;")."</td>";
	$column_data{quotax} = "<td align=right>".$form->format_amount(\%myconfig, $quotaxsubtotal, $form->{precision}, "&nbsp;")."</td>";
	$column_data{quototal} = "<td align=right>".$form->format_amount(\%myconfig, $quototalsubtotal, $form->{precision}, "&nbsp;")."</td>";

	$quoamountsubtotal = 0;
	$quotaxsubtotal = 0;
	$quototalsubtotal = 0;
	
	print "
        <tr class=listsubtotal>
";
	for (@column_index) { print "$column_data{$_}\n" }

	print qq|
        </tr>
|;
 

}


sub list_history {
  
  CT->get_history(\%myconfig, \%$form);
  
  $href = "$form->{script}?action=list_history&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&type=$form->{type}&transdatefrom=$form->{transdatefrom}&transdateto=$form->{transdateto}&history=$form->{history}";

  $form->sort_order();
  
  $callback = "$form->{script}?action=list_history&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&type=$form->{type}&transdatefrom=$form->{transdatefrom}&transdateto=$form->{transdateto}&history=$form->{history}";
  
  $form->{l_fxsellprice} = $form->{l_curr};
  @columns = $form->sort_columns(partnumber, description, qty, unit, sellprice, fxsellprice, total, curr, discount, deliverydate, projectnumber, serialnumber);

  if ($form->{db} eq 'customer') {
    $vcname = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
  } else {
    $vcname = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
  }
  
  if ($form->{history} eq 'summary') {
    @columns = $form->sort_columns(partnumber, description, qty, unit, sellprice, total, discount);
  }
  $form->{l_total} = "Y" if $form->{l_sellprice};

  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      # add column to href and callback
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }
  
  if ($form->{history} eq 'detail') {
    $option = $locale->text('Detail');
  }
  if ($form->{history} eq 'summary') {
    $option .= $locale->text('Summary');
  }
  if ($form->{name}) {
    $callback .= "&name=".$form->escape($form->{name},1);
    $href .= "&name=".$form->escape($form->{name});
    $option .= "\n<br>$vcname : $form->{name}";
  }
  if ($form->{contact}) {
    $callback .= "&contact=".$form->escape($form->{contact},1);
    $href .= "&contact=".$form->escape($form->{contact});
    $option .= "\n<br>".$locale->text('Contact')." : $form->{contact}";
  }
  if ($form->{"$form->{db}number"}) {
    $callback .= qq|&$form->{db}number=|.$form->escape($form->{"$form->{db}number"},1);
    $href .= "&$form->{db}number=".$form->escape($form->{"$form->{db}number"});
    $option .= qq|\n<br>$vcnumber : $form->{"$form->{db}number"}|;
  }
  if ($form->{email}) {
    $callback .= "&email=".$form->escape($form->{email},1);
    $href .= "&email=".$form->escape($form->{email});
    $option .= "\n<br>".$locale->text('E-mail')." : $form->{email}";
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
    if ($form->{transdatefrom}) {
      $option .= " ";
    } else {
      $option .= "\n<br>" if ($option);
    }
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{transdateto}, 1);
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


  $form->{callback} = "$callback&sort=$form->{sort}";
  $callback = $form->escape($form->{callback});

  $column_header{partnumber} = qq|<th><a class=listheading href=$href&sort=partnumber>|.$locale->text('Part Number').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

  $column_header{total} = qq|<th class=listheading>|.$locale->text('Total').qq|</th>|;
  $column_header{sellprice} = qq|<th class=listheading>|.$locale->text('Sell Price').qq|</th>|;
  $column_header{fxsellprice} = qq|<th>&nbsp;</th>|;
  
  $column_header{curr} = qq|<th class=listheading>|.$locale->text('Curr').qq|</th>|;
  $column_header{discount} = qq|<th class=listheading>|.$locale->text('Disc').qq|</th>|;
  $column_header{qty} = qq|<th class=listheading>|.$locale->text('Qty').qq|</th>|;
  $column_header{unit} = qq|<th class=listheading>|.$locale->text('Unit').qq|</th>|;
  $column_header{deliverydate} = qq|<th><a class=listheading href=$href&sort=deliverydate>|.$locale->text('Delivery Date').qq|</a></th>|;
  $column_header{projectnumber} = qq|<th><a class=listheading href=$href&sort=projectnumber>|.$locale->text('Project Number').qq|</a></th>|;
  $column_header{serialnumber} = qq|<th><a class=listheading href=$href&sort=serialnumber>|.$locale->text('Serial Number').qq|</a></th>|;
  

# $locale->text('Customer History')
# $locale->text('Vendor History')

  $label = ucfirst $form->{db};
  $form->{title} = $locale->text($label." History") . " / $form->{company}";

  $colspan = $#column_index + 1;

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


  $module = 'oe';
  if ($form->{db} eq 'customer') {
    $invlabel = $locale->text('Sales Invoice');
    $ordlabel = $locale->text('Sales Order');
    $quolabel = $locale->text('Quotation');
    
    $ordertype = 'sales_order';
    $quotationtype = 'sales_quotation';
    if ($form->{type} eq 'invoice') {
      $module = 'is';
    }
  } else {
    $invlabel = $locale->text('Vendor Invoice');
    $ordlabel = $locale->text('Purchase Order');
    $quolabel = $locale->text('RFQ');
    
    $ordertype = 'purchase_order';
    $quotationtype = 'request_quotation';
    if ($form->{type} eq 'invoice') {
      $module = 'ir';
    }
  }
    
  $ml = ($form->{db} eq 'vendor') ? -1 : 1;
  $lastndx = $#{$form->{CT}};
  $j = 0;
  $sellprice = 0;
  $discount = 0;
  $qty = 0;

  foreach $ref (@{ $form->{CT} }) {

    if ($ref->{id} ne $sameid) {
      # print the header
      print qq|
        <tr class=listheading>
	  <th colspan=$colspan><a class=listheading href=$form->{script}?action=edit&id=$ref->{ctid}&db=$form->{db}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{name} $ref->{address}</a></th>
	</tr>
|;
    }

    $ref->{fxsellprice} = $ref->{sellprice};
    if ($form->{type} ne 'invoice') {
      $ref->{fxsellprice} = $ref->{sellprice};
    }
    $ref->{sellprice} *= $ref->{exchangerate};

    if ($form->{history} eq 'summary') {
      
      $sellprice += $ref->{sellprice} * $ref->{qty};
      $discount += $ref->{discount} * $ref->{qty};
      $qty += $ref->{qty};

      # check next item
      if ($j < $lastndx) {
	if ($ref->{id} eq $form->{CT}[$j+1]->{id}) {
	  if ($ref->{$form->{sort}} eq $form->{CT}[$j+1]->{$form->{sort}}) {
            $sameid = $ref->{id};
	    $j++;
	    next;
	  }
	}
      }
	
      if ($qty) {
	$ref->{sellprice} = $form->round_amount($sellprice/$qty, $form->{precision});
	$ref->{discount} = $discount/$qty;
	$ref->{qty} = $qty;
      }
      
      $sellprice = 0;
      $discount = 0;
      $qty = 0;
    }

    $j++;
    
    if ($form->{history} eq 'detail' and $ref->{invid} ne $sameinvid) {
      # print inv, ord, quo number
      $i++; $i %= 2;
      
      print qq|
	  <tr class=listrow$i>
|;

      if ($form->{type} eq 'invoice') {
	print qq|<th align=left colspan=$colspan><a href=${module}.pl?action=edit&id=$ref->{invid}&path=$form->{path}&login=$form->{login}&callback=$callback>$invlabel $ref->{invnumber} / $ref->{employee}</a></th>|;
      }
       
      if ($form->{type} eq 'order') {
	print qq|<th align=left colspan=$colspan><a href=${module}.pl?action=edit&id=$ref->{invid}&type=$ordertype&path=$form->{path}&login=$form->{login}&callback=$callback>$ordlabel $ref->{ordnumber} / $ref->{employee}</a></th>|;
      }

      if ($form->{type} eq 'quotation') {
	print qq|<th align=left colspan=$colspan><a href=${module}.pl?action=edit&id=$ref->{invid}&type=$quotationtype&path=$form->{path}&login=$form->{login}&callback=$callback>$quolabel $ref->{quonumber} / $ref->{employee}</a></th>|;
      }

      print qq|
          </tr>
|;
    }

    for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

    if ($form->{l_curr}) {
      $column_data{fxsellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice} / $ref->{exchangerate}, $form->{precision})."</td>";
    }
    $column_data{sellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice}, $form->{precision})."</td>";
    $column_data{total} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice} * $ref->{qty}, $form->{precision})."</td>";
      
    $column_data{qty} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{qty} * $ml)."</td>";
    $column_data{discount} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{discount} * 100, 1, "&nbsp;")."</td>";
    $column_data{partnumber} = qq|<td><a href=ic.pl?action=edit&id=$ref->{pid}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{partnumber}</td>|;
    
   
    $i++; $i %= 2;
    print qq|
        <tr class=listrow$i>
|;

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
        </tr>
|;
    
    $sameid = $ref->{id};
    $sameinvid = $ref->{invid};

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



sub form_header {

  for (qw(creditlimit threshold)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, 0) }
  for (qw(discount cashdiscount)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, undef) }
 
  for (qw(terms discountterms)) { $form->{$_} = "" if ! $form->{$_} }
  
  if ($myconfig{role} =~ /(admin|manager)/) {
    $bcc = qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('Bcc').qq|</th>
	  <td><input name=bcc size=35 value="$form->{bcc}"></td>
	</tr>
|;
  }

  if ($form->{selectcurrency}) {
    $currency = qq|
	  <th align=right>|.$locale->text('Currency').qq|</th>
	  <td><select name=curr>|
	  .$form->select_option($form->{selectcurrency}, $form->{curr})
	  .qq|</select></td>
|;
  }
 
  $taxable = "";
  for (split / /, $form->{taxaccounts}) {
    $form->{"tax_${_}_description"} =~ s/ /&nbsp;/g;
    if ($form->{"tax_$_"}) {
      $taxable .= qq| <input name="tax_$_" value=1 class=checkbox type=checkbox checked>&nbsp;<b>$form->{"tax_${_}_description"}</b>|;
    } else {
      $taxable .= qq| <input name="tax_$_" value=1 class=checkbox type=checkbox>&nbsp;<b>$form->{"tax_${_}_description"}</b>|;
    }
  }

  $form->{taxincluded} = ($form->{taxincluded}) ? "checked" : "";
 
  if ($taxable) {
    $tax = qq|
	  <tr>
	    <td>
	      <table>
	        <tr>
		  <td>$taxable</td>
		  <td><input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}> <b>|.$locale->text('Tax Included').qq|</td>
		</tr>
	      </table>
	    </td>
	  </tr>
|;
  }


  # accounts
  if ($form->{selectarap}) {

    $arapaccount = qq|
        <tr>
 	  <th align=right>|.$locale->text($form->{ARAP}).qq|</th>
	  <td><select name="arap_accno">|
	  .$form->select_option($form->{selectarap}, $form->{arap_accno})
	  .qq|</select>
	  </td>
	  <th align=right>|.$locale->text('Credit Limit').qq|</th>
	  <td><input name=creditlimit size=11 value="$form->{creditlimit}"></td>
	</tr>
|;

  }
  
  $discountaccount = qq|
        <tr>
	  <th align=right>|.$locale->text('Terms').qq|</th>
	  <td><b>|.$locale->text('Net').qq|</b> <input name=terms size=3 value="$form->{terms}"> <b>|.$locale->text('days').qq|</b></td>
	</tr>
|.$form->hide_form(qw(discount_accno cashdiscount discountterms));

  if ($form->{selectdiscount}) {

    $discountaccount = qq|
        <tr>
 	  <th align=right>|.$locale->text('Cash Discount').qq|</th>
	  <td><select name="discount_accno">|
	  .$form->select_option($form->{selectdiscount}, $form->{discount_accno})
	  .qq|</select>
	  </td>
	  <th align=right>|.$locale->text('Terms').qq|</th>
	  <td><input name=cashdiscount size=3 value=$form->{cashdiscount}>% / <input name=discountterms size=3 value=$form->{discountterms}> <b>|.$locale->text('Net').qq|</b> <input name=terms size=3 value="$form->{terms}"> <b>|.$locale->text('days').qq|</b></td>
	</tr>
|;
  }
  
  if ($form->{selectpaymentmethod}) {

    $paymentmethod = qq|
 	  &nbsp;<b>|.$locale->text('Method').qq|</b>
	  <select name=paymentmethod>|
	  .$form->select_option($form->{selectpaymentmethod}, $form->{paymentmethod}, 1)
	  .qq|</select>
|;

  }

  if ($form->{selectpayment}) {

    $paymentaccount = qq|
	<tr>
 	  <th align=right>|.$locale->text('Payment').qq|</th>
	  <td><select name="payment_accno">|
	  .$form->select_option($form->{selectpayment}, $form->{payment_accno})
	  .qq|</select>
	  </td>
	  <th align=right>|.$locale->text('Threshold').qq|</th>
	  <td><input name=threshold size=11 value="$form->{threshold}">
	  $paymentmethod
	  </td>
	</tr>
|;
  }
  
  $typeofbusiness = qq|
          <th></th>
	  <td></td>
|;

  if ($form->{selectbusiness}) {

    $typeofbusiness = qq|
 	  <th align=right>|.$locale->text('Type of Business').qq|</th>
	  <td><select name=business>|
	  .$form->select_option($form->{selectbusiness}, $form->{business}, 1)
	  .qq|</select>
	  </td>
|;

  }
  
  if ($form->{selectpricegroup} && $form->{db} eq 'customer') {
    
    $pricegroup = qq|
 	  <th align=right>|.$locale->text('Pricegroup').qq|</th>
	  <td><select name=pricegroup>|
	  .$form->select_option($form->{selectpricegroup}, $form->{pricegroup}, 1)
	  .qq|</select>
	  </td>
|;
  }
  
  $lang = qq|
          <th></th>
	  <td></td>
|;

  if ($form->{selectlanguage}) {
    
    $lang = qq|
 	  <th align=right>|.$locale->text('Language').qq|</th>
	  <td><select name=language_code>|.$form->select_option($form->{selectlanguage}, $form->{language_code}, undef, 1).qq|</select></td>
|;
  }

  $employeelabel = $locale->text('Salesperson');
 
  if ($form->{db} eq 'vendor') {
    $gifi = qq|
    	  <th align=right>|.$locale->text('Sub-contract GIFI').qq|</th>
	  <td><input name=gifi_accno size=9 value="|.$form->quote($form->{gifi_accno}).qq|"></td>
|;
    $employeelabel = $locale->text('Employee');
  }


  if ($form->{selectemployee}) {
    if ($myconfig{role} eq 'user') {
      if ($form->{id}) {
	$form->{selectemployee} = "\n$form->{employee}";
      }
    }
    
    $employee = qq|
	        <th align=right>$employeelabel</th>
		<td><select name=employee>|
		.$form->select_option($form->{selectemployee}, $form->{employee}, 1)
		.qq|</select>
		</td>
|;
  }


# $locale->text('Add Customer')
# $locale->text('Add Vendor')
# $locale->text('Edit Customer')
# $locale->text('Edit Vendor')

  if ($form->{db} eq 'customer') {
    $vcname = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
    $form->{title} = $locale->text("$form->{title} Customer");
  } else {
    $vcname = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
    $form->{title} = $locale->text("$form->{title} Vendor");
  }

  $typeofcontact{company} = "checked" if $form->{typeofcontact} eq 'company';
  $typeofcontact{person} = "checked" if $form->{typeofcontact} eq 'person';
  
  $typeofcontact = qq|
              <input type=hidden name=action value="update">
	      <tr>
	        <td align=center><b>|.$locale->text('Type').qq|</b>
		<input name=typeofcontact type=radio value="company" $typeofcontact{company} onChange="javascript:document.forms[0].submit()">|.$locale->text('Company').qq|
		<input name=typeofcontact type=radio value="person" $typeofcontact{person} onChange="javascript:document.forms[0].submit()">|.$locale->text('Person').qq|
		</td>
	      </tr>
|;
   

  if ($form->{typeofcontact} eq 'person') {
 
    for (qw(M F)) { $gender{$_} = "checked" if $form->{gender} eq $_ }
      
    $name = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Salutation').qq|</th>
		<td><input name=salutation size=32 maxlength=32 value="|.$form->quote($form->{salutation}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('First Name').qq|</th>
		<td><input name=firstname size=32 maxlength=31 value="|.$form->quote($form->{firstname}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Last Name').qq|</th>
		<td><input name=lastname size=32 maxlength=32 value="|.$form->quote($form->{lastname}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Title').qq|</th>
		<td><input name=contacttitle size=32 maxlength=32 value="|.$form->quote($form->{contacttitle}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Occupation').qq|</th>
		<td><input name=occupation size=32 maxlength=32 value="|.$form->quote($form->{occupation}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right></th>
		<td><input name=gender type=radio value="M" $gender{M}>|.$locale->text('Male').qq|
		<input name=gender type=radio value="F" $gender{F}>|.$locale->text('Female').qq|
		</td>
	      </tr>
|;

  } else {

    $name = qq|
 	      <tr>
		<th align=right nowrap>$vcname <font color=red>*</font></th>
		<td><input name=name size=32 maxlength=64 value="|.$form->quote($form->{name}).qq|"></td>
	      </tr>
|;
    $contact = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Salutation').qq|</th>
		<td><input name=salutation size=32 maxlength=32 value="|.$form->quote($form->{salutation}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('First Name').qq|</th>
		<td><input name=firstname size=32 maxlength=31 value="|.$form->quote($form->{firstname}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Last Name').qq|</th>
		<td><input name=lastname size=32 maxlength=32 value="|.$form->quote($form->{lastname}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Title').qq|</th>
		<td><input name=contacttitle size=32 maxlength=32 value="|.$form->quote($form->{contacttitle}).qq|"></td>
	      </tr>
|.$form->hide_form(qw(gender occupation));

  } 

  $form->{remittancevoucher} = ($form->{remittancevoucher}) ? "checked" : "";

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
      <table width=100%>
	<tr class=listheading>
	  <th class=listheading colspan=2>|.$locale->text('Billing Address').qq|</th>
	</tr>
	      $typeofcontact
        <tr valign=top>
	  <td width=50%>
	    <table>
	      <tr>
		<th align=right nowrap>$vcnumber</th>
		<td><input name="$form->{db}number" size=32 maxlength=32 value="|.$form->quote($form->{"$form->{db}number"}).qq|"></td>
	      </tr>

	      $name
	      
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
	    </table>
	  </td>

	  <td width=50%>
	    <table>
	      $contact
	      <tr>
		<th align=right nowrap>|.$locale->text('Phone').qq|</th>
		<td><input name=phone size=22 maxlength=20 value="$form->{phone}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Fax').qq|</th>
		<td><input name=fax size=22 maxlength=20 value="$form->{fax}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Mobile').qq|</th>
		<td><input name=mobile size=22 maxlength=20 value="$form->{mobile}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('E-mail').qq|</th>
		<td><input name=email size=32 value="$form->{email}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Cc').qq|</th>
		<td><input name=cc size=32 value="$form->{cc}"></td>
	      </tr>
	      $bcc
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
    $tax
  <tr>
    <td>
      <table>
        <tr valign=top>
	  <td>
	    <table>
	      $arapaccount
	      $paymentaccount
	      $discountaccount
	    </table>
	  </td>
	</tr>  
      </table>
    </td>
  </tr>

  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Startdate').qq|</th>
	  <td><input name=startdate size=11 class=date title="$myconfig{dateformat}" value=$form->{startdate}></td>
	  <th align=right>|.$locale->text('Enddate').qq|</th>
	  <td><input name=enddate size=11 class=date title="$myconfig{dateformat}" value=$form->{enddate}></td>
	  <th align=right>|.$locale->text('Discount').qq|</th>
	  <td><input name=discount size=4 value="$form->{discount}">
	  <b>%</b></td>
	</tr>
	<tr>
	  $pricegroup
	  <th align=right>|.$locale->text('Tax Number / SSN').qq|</th>
	  <td><input name=taxnumber size=20 value="|.$form->quote($form->{taxnumber}).qq|"></td>
	  $gifi
	  <th align=right>|.$locale->text('SIC').qq|</th>
	  <td><input name=sic_code size=6 maxlength=6 value="|.$form->quote($form->{sic_code}).qq|"></td>
	</tr>
	<tr>
	  $typeofbusiness
	  $lang
	  $currency
	</tr>
	<tr valign=top>
	  $employee
	  <td colspan=4>
	    <table>
	      <tr valign=top>
		<th align=left nowrap>|.$locale->text('Notes').qq|</th>
		<td><textarea name=notes rows=3 cols=40 wrap=soft>$form->{notes}</textarea></td>
	      </tr>
	    </table>
	  </td>
	</tr>
	<tr valign=top>
	  <td colspan=2>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('IBAN').qq|</th>
		<td><input name=iban size=34 maxlength=34 value="$form->{iban}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('BIC').qq|</th>
		<td><input name=bic size=11 maxlength=11 value="$form->{bic}"></td>
	      </tr>
	      <tr>
		<td align=right><input name=remittancevoucher class=checkbox type=checkbox value=1 $form->{remittancevoucher}></td>
		<th align=left>|.$locale->text('Remittance Voucher').qq|</th>
	      </tr>
	    </table>
	  </td>
	  <td colspan=4>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Bank').qq|</th>
		<td><input name=bankname size=32 maxlength=64 value="|.$form->quote($form->{bankname}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Address').qq|</th>
		<td><input name=bankaddress1 size=32 maxlength=32 value="|.$form->quote($form->{bankaddress1}).qq|"></td>
	      </tr>
	      <tr>
		<th></th>
		<td><input name=bankaddress2 size=32 maxlength=32 value="|.$form->quote($form->{bankaddress2}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('City').qq|</th>
		<td><input name=bankcity size=32 maxlength=32 value="|.$form->quote($form->{bankcity}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('State/Province').qq|</th>
		<td><input name=bankstate size=32 maxlength=32 value="|.$form->quote($form->{bankstate}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Zip/Postal Code').qq|</th>
		<td><input name=bankzipcode size=11 maxlength=10 value="|.$form->quote($form->{bankzipcode}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Country').qq|</th>
		<td><input name=bankcountry size=32 maxlength=32 value="|.$form->quote($form->{bankcountry}).qq|"></td>
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


  $form->hide_form(map { "tax_${_}_description" } (split / /, $form->{taxaccounts})) if $form->{taxaccounts};
  $form->hide_form(map { "select$_" } qw(currency arap discount payment business pricegroup language employee paymentmethod));
  $form->hide_form(map { "shipto$_" } qw(name address1 address2 city state zipcode country contact phone fax email));

}



sub form_footer {

  %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
             'Save' => { ndx => 2, key => 'S', value => $locale->text('Save') },
             'Shipping Address' => { ndx => 3, key => 'H', value => $locale->text('Shipping Address') },
             'Save as new' => { ndx => 4, key => 'N', value => $locale->text('Save as new') },
	     'AR Transaction' => { ndx => 7, key => 'A', value => $locale->text('AR Transaction') },
	     'AP Transaction' => { ndx => 8, key => 'A', value => $locale->text('AP Transaction') },
	     'Sales Invoice' => { ndx => 9, key => 'I', value => $locale->text('Sales Invoice') },
	     'Credit Invoice' => { ndx => 10, key => 'R', value => $locale->text('Credit Invoice') },
	     'POS' => { ndx => 11, key => 'C', value => $locale->text('POS') },
	     'Sales Order' => { ndx => 12, key => 'O', value => $locale->text('Sales Order') },
	     'Quotation' => { ndx => 13, key => 'Q', value => $locale->text('Quotation') },
	     'Vendor Invoice' => { ndx => 14, key => 'I', value => $locale->text('Vendor Invoice') },
	     'Debit Invoice' => { ndx => 15, key => 'R', value => $locale->text('Debit Invoice') },
	     'Purchase Order' => { ndx => 16, key => 'O', value => $locale->text('Purchase Order') },
	     'RFQ' => { ndx => 17, key => 'Q', value => $locale->text('RFQ') },
	     'Pricelist' => { ndx => 18, key => 'P', value => $locale->text('Pricelist') },
	     'Delete' => { ndx => 19, key => 'D', value => $locale->text('Delete') },
	    );
  
  
  %a = ();
  
  if ($form->{db} eq 'customer') {
    if ($myconfig{acs} !~ /AR--Customers--Add Customer/) {
      $a{'Save'} = 1;
      $a{'Shipping Address'} = 1;
      $a{'Update'} = 1;

      if ($form->{id}) {
	$a{'Save as new'} = 1;
	if ($form->{status} eq 'orphaned') {
	  $a{'Delete'} = 1;
	}
      }
    }
    
    if ($myconfig{acs} !~ /AR--AR/) {
      if ($myconfig{acs} !~ /AR--Add Transaction/) {
	$a{'AR Transaction'} = 1;
      }
      if ($myconfig{acs} !~ /AR--Sales Invoice/) {
	$a{'Sales Invoice'} = 1;
      }
      if ($myconfig{acs} !~ /AR--Credit Invoice/) {
	$a{'Credit Invoice'} = 1;
      }
    }
    if ($myconfig{acs} !~ /POS--POS/) {
      if ($myconfig{acs} !~ /POS--Sale/) {
	$a{'POS'} = 1;
      }
    }
    if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
      if ($myconfig{acs} !~ /Order Entry--Sales Order/) {
	$a{'Sales Order'} = 1;
      }
    }
    if ($myconfig{acs} !~ /Quotations--Quotations/) {
      if ($myconfig{acs} !~ /Quotations--Quotation/) {
	$a{'Quotation'} = 1;
      }
    }
  }
  
  if ($form->{db} eq 'vendor') {
    if ($myconfig{acs} !~ /AP--Vendors--Add Vendor/) {
      $a{'Save'} = 1;
      $a{'Shipping Address'} = 1;
      $a{'Update'} = 1;

      if ($form->{id}) {
	$a{'Save as new'} = 1;
	if ($form->{status} eq 'orphaned') {
	  $a{'Delete'} = 1;
	}
      }
    }
 
    if ($myconfig{acs} !~ /AP--AP/) {
      if ($myconfig{acs} !~ /AP--Add Transaction/) {
	$a{'AP Transaction'} = 1;
      }
      if ($myconfig{acs} !~ /AP--Vendor Invoice/) {
	$a{'Vendor Invoice'} = 1;
      }
      if ($myconfig{acs} !~ /AP--Debit Invoice/) {
	$a{'Debit Invoice'} = 1;
      }
    }
    if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
      if ($myconfig{acs} !~ /Order Entry--Purchase Order/) {
	$a{'Purchase Order'} = 1;
      }
    }
    if ($myconfig{acs} !~ /Quotations--Quotations/) {
      if ($myconfig{acs} !~ /Quotations--RFQ/) {
	$a{'RFQ'} = 1;
      }
    }
  }
  
  if ($myconfig{acs} !~ /Goods & Services--Goods & Services/) {
    $myconfig{acs} =~ s/(Goods & Services--)Add (Service|Assembly).*;/$1--Add Part/g;
    if ($myconfig{acs} !~ /Goods & Services--Add Part/) {
      $a{'Pricelist'} = 1;
    }
  }

  $form->{update_contact} = 1;
  $form->hide_form(qw(id ARAP update_contact addressid contactid taxaccounts path login callback db status));
  
  for (keys %button) { delete $button{$_} if ! $a{$_} }
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


sub shipping_address {

  $form->{title} = $locale->text('Shipping Address');

  $form->{name} ||= "$form->{firstname} $form->{lastname}";
  
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
      <table width=100%>
	<tr>
	  <th class=listheading colspan=2>$form->{name}</th>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Name').qq|</th>
	  <td><input name=shiptoname size=32 maxlength=64 value="|.$form->quote($form->{shiptoname}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Address').qq|</th>
	  <td><input name=shiptoaddress1 size=32 maxlength=32 value="|.$form->quote($form->{shiptoaddress1}).qq|"></td>
	</tr>
	<tr>
	  <th></th>
	  <td><input name=shiptoaddress2 size=32 maxlength=32 value="|.$form->quote($form->{shiptoaddress2}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('City').qq|</th>
	  <td><input name=shiptocity size=32 maxlength=32 value="|.$form->quote($form->{shiptocity}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('State/Province').qq|</th>
	  <td><input name=shiptostate size=32 maxlength=32 value="|.$form->quote($form->{shiptostate}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Zip/Postal Code').qq|</th>
	  <td><input name=shiptozipcode size=11 maxlength=10 value="|.$form->quote($form->{shiptozipcode}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Country').qq|</th>
	  <td><input name=shiptocountry size=32 maxlength=32 value="|.$form->quote($form->{shiptocountry}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Contact').qq|</th>
	  <td><input name=shiptocontact size=35 maxlength=64 value="|.$form->quote($form->{shiptocontact}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Phone').qq|</th>
	  <td><input name=shiptophone size=22 maxlength=20 value="$form->{shiptophone}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Fax').qq|</th>
	  <td><input name=shiptofax size=22 maxlength=20 value="$form->{shiptofax}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('E-mail').qq|</th>
	  <td><input name=shiptoemail size=32 value="$form->{shiptoemail}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  for (map { "shipto$_" } qw(name address1 address2 city state zipcode country contact phone fax email)) { delete $form->{$_} }

  $form->{nextsub} = "update";
  $form->{action} = $form->{nextsub};

  $form->hide_form;
  
  print qq|
  <input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
  
</form>

</body>
</html>
|;  

}


sub pricelist {

  if ("$form->{name}$form->{lastname}$form->{firstname}" eq "") {
    $form->error($locale->text('Name missing!'));
  }

  delete $form->{update_contact};
  $form->{display_form} ||= "display_pricelist";

  CT->pricelist(\%myconfig, \%$form);

  $i = 0;
  foreach $ref (@{ $form->{"all_partspricelist"} }) {
    $i++;
    for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }
  }
  $form->{rowcount} = $i;

  # currencies
  for (split /:/, $form->{currencies}) { $form->{selectcurrency} .= "$_\n" }
  $form->{selectcurrency} = $form->escape($form->{selectcurrency},1);
  
  if (@ { $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = "\n";
    foreach $ref (@ { $form->{all_partsgroup} }) {
      $form->{selectpartsgroup} .= qq|$ref->{partsgroup}--$ref->{id}\n|;
    }
    $form->{selectpartsgroup} = $form->escape($form->{selectpartsgroup},1);
  }

  for (qw(currencies all_partsgroup all_partspricelist)) { delete $form->{$_} }

  foreach $i (1 .. $form->{rowcount}) {
    
    if ($form->{db} eq 'customer') {
      
      $form->{"pricebreak_$i"} = $form->format_amount(\%myconfig, $form->{"pricebreak_$i"});

      $form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $form->{"sellprice_$i"});
      
    }
    
    if ($form->{db} eq 'vendor') {
      
      $form->{"leadtime_$i"} = $form->format_amount(\%myconfig, $form->{"leadtime_$i"});
      
      $form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"});
      
    }
  }

  $form->{rowcount}++;
  &{ "$form->{db}_pricelist" };
 
}
  

sub customer_pricelist {

  @flds = qw(runningnumber id partnumber description sellprice unit partsgroup pricebreak curr validfrom validto);

  $form->{rowcount}--;
  
  # remove empty rows
  if ($form->{rowcount}) {

    foreach $i (1 .. $form->{rowcount}) {

      for (qw(pricebreak sellprice)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
      
      ($a, $b) = split /\./, $form->{"pricebreak_$i"};
      $a = length $a;
      $b = length $b;
      $whole = ($whole > $a) ? $whole : $a;
      $dec = ($dec > $b) ? $dec : $b;
    }
    $pad1 = '0' x $whole;
    $pad2 = '0' x $dec;

    foreach $i (1 .. $form->{rowcount}) {
      ($a, $b) = split /\./, $form->{"pricebreak_$i"};
      
      $a = substr("$pad1$a", -$whole);
      $b = substr("$b$pad2", 0, $dec);
      $ndx{qq|$form->{"partnumber_$i"}_$form->{"id_$i"}_$a$b|} = $i;
    }
    
    $i = 1;
    for (sort keys %ndx) { $form->{"runningnumber_$ndx{$_}"} = $i++ }
      
    foreach $i (1 .. $form->{rowcount}) {
      if ($form->{"partnumber_$i"} && $form->{"sellprice_$i"}) {
	if ($form->{"id_$i"} eq $sameid) {
	  $j = $i + 1;
	  next if ($form->{"id_$j"} eq $sameid && !$form->{"pricebreak_$i"});
	}
	
	push @a, {};
	$j = $#a;

	for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
      }
      $sameid = $form->{"id_$i"};
    }
   
    $form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
    $form->{rowcount} = $count;

  }

  $form->{rowcount}++;

  if ($form->{display_form}) {
    &{ "$form->{display_form}" };
  }

}


sub vendor_pricelist {

  @flds = qw(runningnumber id sku partnumber description lastcost unit partsgroup curr leadtime);

  $form->{rowcount}--;
  
  # remove empty rows
  if ($form->{rowcount}) {

    foreach $i (1 .. $form->{rowcount}) {

      for (qw(leadtime lastcost)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
      $var = ($form->{"partnumber_$i"}) ? $form->{"sku_$i"} : qq|_$form->{"sku_$i"}|;
      $ndx{$var} = $i;
      
    }

    $i = 1;
    for (sort keys %ndx) { $form->{"runningnumber_$ndx{$_}"} = $i++ }

    foreach $i (1 .. $form->{rowcount}) {
      if ($form->{"sku_$i"}) {
	push @a, {};
	$j = $#a;

	for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
      }
    }
   
    $form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
    $form->{rowcount} = $count;

  }

  $form->{rowcount}++;

  if ($form->{display_form}) {
    &{ "$form->{display_form}" };
  }

}


sub display_pricelist {
  
  &pricelist_header;
  delete $form->{action};
  $form->hide_form;
  &pricelist_footer;
  
}


sub pricelist_header {
  
  $form->{title} = ($form->{typeofcontact} ne 'company') ? "$form->{firstname} $form->{lastname}" : $form->{name};
 
  $form->header;

  print qq|
<body>

<form method=post action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
|;

  if ($form->{db} eq 'customer') {
    @column_index = qw(partnumber description);
    push @column_index, "partsgroup" if $form->{selectpartsgroup};
    push @column_index, qw(pricebreak sellprice curr validfrom validto);

    $column_header{pricebreak} = qq|<th class=listheading nowrap>|.$locale->text('Break').qq|</th>|;
    $column_header{sellprice} = qq|<th class=listheading nowrap>|.$locale->text('Sell Price').qq|</th>|;
    $column_header{validfrom} = qq|<th class=listheading nowrap>|.$locale->text('From').qq|</th>|;
    $column_header{validto} = qq|<th class=listheading nowrap>|.$locale->text('To').qq|</th>|;
  }

  if ($form->{db} eq 'vendor') {
    @column_index = qw(sku partnumber description);
    push @column_index, "partsgroup" if $form->{selectpartsgroup};
    push @column_index, qw(lastcost curr leadtime);


    $column_header{sku} = qq|<th class=listheading nowrap>|.$locale->text('SKU').qq|</th>|;
    $column_header{leadtime} = qq|<th class=listheading nowrap>|.$locale->text('Leadtime').qq|</th>|;
    $column_header{lastcost} = qq|<th class=listheading nowrap>|.$locale->text('Cost').qq|</th>|;
  }

  $column_header{partnumber} = qq|<th class=listheading nowrap>|.$locale->text('Number').qq|</th>|;
  $column_header{description} = qq|<th class=listheading nowrap width=80%>|.$locale->text('Description').qq|</th>|;
  $column_header{partsgroup} = qq|<th class=listheading nowrap>|.$locale->text('Group').qq|</th>|;
  $column_header{curr} = qq|<th class=listheading nowrap>|.$locale->text('Curr').qq|</th>|;

  print qq|
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  for (@column_index) { print "\n$column_header{$_}" }
  
  print qq|
       </tr>
|;

  $sameid = "";
  foreach $i (1 .. $form->{rowcount}) {
    
    if ($i < $form->{rowcount}) {
      $column_data{partsgroup} = qq|<td>$form->{"partsgroup_$i"}</td>| if $form->{selectpartsgroup};

      if ($form->{"id_$i"} eq $sameid) {
	for (qw(partnumber description partsgroup)) { $column_data{$_} = qq|<td>&nbsp;</td>| }
	$form->hide_form(map { "${_}_$i" } qw(id partnumber description partsgroup partsgroup_id));

      } else {
	
	$column_data{sku} = qq|<td><input name="sku_$i" value="|.$form->quote($form->{"sku_$i"}).qq|"></td>|;
	$column_data{partnumber} = qq|<td><input name="partnumber_$i" value="|.$form->quote($form->{"partnumber_$i"}).qq|"></td>|;

	$column_data{description} = qq|<td>$form->{"description_$i"}&nbsp;</td>|;
	$form->hide_form(map { "${_}_$i" } qw(id description partsgroup partsgroup_id));
      }

    } else {
   
      if ($form->{db} eq 'customer') {
	$column_data{partnumber} = qq|<td><input name="partnumber_$i"></td>|;
      } else {
	$column_data{partnumber} = qq|<td>&nbsp;</td>|;
      }

      $column_data{sku} = qq|<td><input name="sku_$i"></td>|;
      $column_data{description} = qq|<td><input name="description_$i"></td>|;

      if ($form->{selectpartsgroup}) {
	$column_data{partsgroup} = qq|<td><select name="partsgroup_$i">|
	.$form->select_option($form->{selectpartsgroup}, undef, 1)
	.qq|</select>
	</td>
|;
      }
    }


    if ($form->{db} eq 'customer') {
      
      $column_data{pricebreak} = qq|<td align=right><input name="pricebreak_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"pricebreak_$i"}).qq|></td>|;
      $column_data{sellprice} = qq|<td align=right><input name="sellprice_$i" size=11 value=|.$form->format_amount(\%myconfig, $form->{"sellprice_$i"}).qq|></td>|;
      
      $column_data{validfrom} = qq|<td nowrap><input name="validfrom_$i" size=11 value=$form->{"validfrom_$i"}></td>|;
      $column_data{validto} = qq|<td nowrap><input name="validto_$i" size=11 value=$form->{"validto_$i"}></td>|;
    }
    
    if ($form->{db} eq 'vendor') {
      $column_data{leadtime} = qq|<td align=right><input name="leadtime_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"leadtime_$i"}).qq|></td>|;
      $column_data{lastcost} = qq|<td align=right><input name="lastcost_$i" size=11 value=|.$form->format_amount(\%myconfig, $form->{"lastcost_$i"}).qq|></td>|;
    }
      

    $column_data{curr} = qq|<td><select name="curr_$i">|.$form->select_option($form->{selectcurrency}, $form->{"curr_$i"}).qq|</select></td>|;

    
    print qq|<tr valign=top>|;
    
    for (@column_index) { print "\n$column_data{$_}" }

    print qq|</tr>|;

    $sameid = $form->{"id_$i"};

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

  # delete variables
  foreach $i (1 .. $form->{rowcount}) {
    for (@column_index, "id", "partsgroup_id") { delete $form->{"${_}_$i"} }
  }
  for (qw(title titlebar script none)) { delete $form->{$_} }

}


sub pricelist_footer {

  %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
             'Save Pricelist' => { ndx => 3, key => 'S', value => $locale->text('Save Pricelist') },
	    ); 
	     
  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
  
  print qq|
</form>

</body>
</html>
|;  

}


sub update {

  for (qw(creditlimit threshold discount cashdiscount)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
  
  if ($form->{update_contact}) {

    $form->{title} = ($form->{id}) ? 'Edit' : 'Add';

    &form_header;
    &form_footer;

    return;
    
  }


  $i = $form->{rowcount};
  $additem = 0;

  if ($form->{db} eq 'customer') {
    $additem = 1 if ! (($form->{"partnumber_$i"} eq "") && ($form->{"description_$i"} eq "") && ($form->{"partsgroup_$i"} eq ""));
  }
  if ($form->{db} eq 'vendor') {
    if (! (($form->{"sku_$i"} eq "") && ($form->{"description_$i"} eq "") && ($form->{"partsgroup_$i"} eq ""))) {
      $additem = 1;
      $form->{"partnumber_$i"} = $form->{"sku_$i"};
    }
  }

  if ($additem) {

    CT->retrieve_item(\%myconfig, \%$form);

    $rows = scalar @{ $form->{item_list} };

    if ($rows > 0) {
      
      if ($rows > 1) {
	
	&select_item;
	exit;
	
      } else {
	
	$sellprice = $form->{"sellprice_$i"};
	$pricebreak = $form->{"pricebreak_$i"};
	$lastcost = $form->{"lastcost_$i"};
	
	for (qw(partnumber description)) { $form->{item_list}[0]{$_} = $form->quote($form->{item_list}[0]{$_}) }
	for (keys %{ $form->{item_list}[0] }) { $form->{"${_}_$i"} = $form->{item_list}[0]{$_} }

        if ($form->{db} eq 'customer') {
	  
	  if ($sellprice) {
	    $form->{"sellprice_$i"} = $sellprice;
	  }
	  
	  $form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $form->{"sellprice_$i"});
	  
	  $form->{"pricebreak_$i"} = $pricebreak;
	  
	} else {

          foreach $j (1 .. $form->{rowcount} - 1) {
	    if ($form->{"sku_$j"} eq $form->{"partnumber_$i"}) {
	      $form->error($locale->text('Item already on pricelist!'));
	    }
	  }

	  $form->{"lastcost_$i"} ||= $lastcost;
	  $form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"});

	  $form->{"sku_$i"} = $form->{"partnumber_$i"};
	  
	}

	$form->{rowcount}++;

      }
	
    } else {

      $form->error($locale->text('Item not on file!'));
      
    }
  }

  &{ "$form->{db}_pricelist" };
  
}



sub select_item {

  @column_index = qw(ndx partnumber description partsgroup unit sellprice lastcost);

  $column_data{ndx} = qq|<th class=listheading width=1%>&nbsp;</th>|;
  $column_data{partnumber} = qq|<th class=listheading>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_data{partsgroup} = qq|<th class=listheading>|.$locale->text('Group').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading>|.$locale->text('Unit').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading>|.$locale->text('Sell Price').qq|</th>|;
  $column_data{lastcost} = qq|<th class=listheading>|.$locale->text('Cost').qq|</th>|;
  
  $form->header;
  
  $title = $locale->text('Select items');
  
  print qq|
<body>

<form method=post action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$title</th>
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

    for (qw(partnumber description unit)) { $ref->{$_} = $form->quote($ref->{$_}) }
   
    $column_data{ndx} = qq|<td><input name="ndx_$i" class=checkbox type=checkbox value=$i></td>|;

    for (qw(partnumber description partsgroup unit)) { $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>| }

    $column_data{sellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice}, undef, "&nbsp;").qq|</td>|;
    $column_data{lastcost} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{lastcost}, undef, "&nbsp;").qq|</td>|;

    $j++; $j %= 2;

    print qq|
        <tr class=listrow$j>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

    for (qw(partnumber description partsgroup partsgroup_id sellprice lastcost unit id)) {
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

  # delete action variable
  for (qw(nextsub item_list)) { delete $form->{$_} }
  
  $form->{action} = "item_selected";

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

  # add rows
  $i = $form->{rowcount};

  %id = ();
  for $i (1 .. $form->{rowcount} - 1) {
    $id{$form->{"id_$i"}} = 1;
  }
 
  for $j (1 .. $form->{lastndx}) {

    if ($form->{"ndx_$j"}) {

      if ($id{$form->{"new_id_$j"}}) {
	next if $form->{db} eq 'vendor';
      }
      
      for (qw(id partnumber description unit sellprice lastcost partsgroup partsgroup_id)) {
	$form->{"${_}_$i"} = $form->{"new_${_}_$j"};
      }
      
      $form->{"sku_$i"} = $form->{"new_partnumber_$j"};
 
      $i++;
     
    }
  }

  $form->{rowcount} = $i;
 
  # delete all the new_ variables
  for $i (1 .. $form->{lastndx}) {
    for (qw(id partnumber description unit sellprice lastcost partsgroup partsgroup_id)) { delete $form->{"new_${_}_$i"} }
    delete $form->{"ndx_$i"};
  }
  
  for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

  &{ "$form->{db}_pricelist" };

}



    
sub save_pricelist {
 
  CT->save(\%myconfig, \%$form);

  $callback = $form->{callback};
  $form->{callback} = "$form->{script}?action=edit";
  for (qw(db id login path)) { $form->{callback} .= "&$_=$form->{$_}" }
  $form->{callback} .= "&callback=".$form->escape($callback,1);
  
  if (CT->save_pricelist(\%myconfig, \%$form)) {
    $form->redirect;
  } else {
    $form->error($locale->text('Could not save pricelist!'));
  }

}



sub add_transaction {
  
  if ("$form->{name}$form->{lastname}$form->{firstname}" eq "") {
    $form->error($locale->text("Name missing!"));
  }

  CT->save(\%myconfig, \%$form);
  
  $form->{callback} = $form->escape($form->{callback},1);
  $name = $form->escape($form->{name},1);

  $form->{callback} = "$form->{script}?login=$form->{login}&path=$form->{path}&action=add&vc=$form->{db}&$form->{db}_id=$form->{id}&$form->{db}=$name&type=$form->{type}&callback=$form->{callback}";

  $form->redirect;
  
}

sub ap_transaction {

  $form->{script} = "ap.pl";
  $form->{type} = "ap_transaction";
  &add_transaction;

}


sub ar_transaction {

  $form->{script} = "ar.pl";
  $form->{type} = "ar_transaction";
  &add_transaction;

}


sub sales_invoice {

  $form->{script} = "is.pl";
  $form->{type} = "invoice";
  &add_transaction;
  
}


sub credit_invoice {

  $form->{script} = "is.pl";
  $form->{type} = "credit_invoice";
  &add_transaction;
  
}


sub pos {
  
  $form->{script} = "ps.pl";
  $form->{type} = "pos_invoice";
  &add_transaction;

}


sub vendor_invoice {

  $form->{script} = "ir.pl";
  $form->{type} = "invoice";
  &add_transaction;
  
}


sub debit_invoice {

  $form->{script} = "ir.pl";
  $form->{type} = "debit_invoice";
  &add_transaction;
  
}


sub rfq {

  $form->{script} = "oe.pl";
  $form->{type} = "request_quotation";
  &add_transaction;

}


sub quotation {
  
  $form->{script} = "oe.pl";
  $form->{type} = "sales_quotation";
  &add_transaction;

}


sub sales_order {
  
  $form->{script} = "oe.pl";
  $form->{type} = "sales_order";
  &add_transaction;

}


sub purchase_order {

  $form->{script} = "oe.pl";
  $form->{type} = "purchase_order";
  &add_transaction;
  
}


sub save_as_new {
  
  for (qw(id contactid)) { delete $form->{$_} }
  &save;
  
}


sub save {

# $locale->text('Customer saved!')
# $locale->text('Vendor saved!')

  $msg = ucfirst $form->{db};
  $msg .= " saved!";

  if ("$form->{name}$form->{lastname}$form->{firstname}" eq "") {
    $form->error($locale->text("Name missing!"));
  }

  CT->save(\%myconfig, \%$form);
  
  $form->redirect($locale->text($msg));
  
}


sub delete {

# $locale->text('Customer deleted!')
# $locale->text('Cannot delete customer!')
# $locale->text('Vendor deleted!')
# $locale->text('Cannot delete vendor!')

  CT->delete(\%myconfig, \%$form);
  
  $msg = ucfirst $form->{db};
  $msg .= " deleted!";
  $form->redirect($locale->text($msg));
  
}


sub continue { &{ $form->{nextsub} } };

sub add_customer { &add };
sub add_vendor { &add };

