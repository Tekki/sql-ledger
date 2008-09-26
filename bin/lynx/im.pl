#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2007
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# import/export
#
#======================================================================


use SL::IM;
use SL::CP;
 
1;
# end of main


sub import {

  %title = ( sales_invoice => 'Sales Invoices',
	     payment => 'Payments'
	   );

# $locale->text('Import Sales Invoices')
# $locale->text('Import Payments')

  $msg = "Import $title{$form->{type}}";
  $form->{title} = $locale->text($msg);
  
  $form->header;

  $form->{nextsub} = "im_$form->{type}";
  $form->{action} = "continue";

  if ($form->{type} eq 'payment') {
    IM->paymentaccounts(\%myconfig, \%$form);
    if (@{ $form->{all_paymentaccount} }) {
      @curr = split /:/, $form->{currencies};
      $form->{defaultcurrency} = $curr[0];
      chomp $form->{defaultcurrency};

      for (@curr) { $form->{selectcurrency} .= "$_\n" }
      
      $selectpaymentaccount = "";
      for (@{ $form->{all_paymentaccount} }) { $selectpaymentaccount .= qq|$_->{accno}--$_->{description}\n| }
      $paymentaccount = qq|
         <tr>
	  <th align=right>|.$locale->text('Account').qq|</th>
	  <td>
	    <select name=paymentaccount>|.$form->select_option($selectpaymentaccount)
	    .qq|</select>
	  </td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Currency').qq|</th>
	  <td><select name=currency>|
	  .$form->select_option($form->{selectcurrency}, $form->{currency})
	  .qq|</select></td>
	</tr>
|;
    }
  }
  
print qq|
<body>

<form enctype="multipart/form-data" method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        $paymentaccount
        <tr>
	  <th align=right>|.$locale->text('File to Import').qq|</th>
	  <td>
	    <input name=data size=60 type=file>
	  </td>
	</tr>
	<tr valign=top>
	  <th align=right>|.$locale->text('Type of File').qq|</th>
	  <td>
	    <table>
	      <tr>
	        <td><input name=filetype type=radio class=radio value=CSV checked>&nbsp;|.$locale->text('CSV').qq|</td>
		<td width=20></td>
		<th align=right>|.$locale->text('Delimiter').qq|</th>
		<td><input name=delimiter size=2 value=","></td>
	      </tr>
	      <tr>
		<th align=right colspan=2>|.$locale->text('Tab delimited file').qq|</th>
		<td align=left><input name=tabdelimited type=checkbox class=checkbox></td>
	      </tr>
	    </table>
	  </td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Mapfile').qq|</th>
	  <td><input name=mapfile type=radio class=radio value=1>&nbsp;|.$locale->text('Yes').qq|&nbsp;
	      <input name=mapfile type=radio class=radio value=0 checked>&nbsp;|.$locale->text('No').qq|
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

  $form->hide_form(qw(defaultcurrency title type action nextsub login path));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub export {

  %title = ( payment => 'Payments'
	   );

# $locale->text('Export Payments')

  $form->{file} ||= time;

  $msg = "Export $title{$form->{type}}";
  $form->{title} = $locale->text($msg);
  
  $form->header;

  $form->{nextsub} = "ex_$form->{type}";
  $form->{action} = "continue";

  if ($form->{type} eq 'payment') {
    IM->paymentaccounts(\%myconfig, \%$form);
    if (@{ $form->{all_paymentaccount} }) {
      @curr = split /:/, $form->{currencies};
      $form->{defaultcurrency} = $curr[0];
      chomp $form->{defaultcurrency};

      for (@curr) { $form->{selectcurrency} .= "$_\n" }
      
      $form->{selectpaymentaccount} = "";
      for (@{ $form->{all_paymentaccount} }) { $form->{selectpaymentaccount} .= qq|$_->{accno}--$_->{description}\n| }
	
      if (@{ $form->{all_paymentmethod} }) {
	$form->{selectpaymentmethod} = "\n";
	for (@{ $form->{all_paymentmethod} }) { $form->{selectpaymentmethod} .= qq|$_->{description}--$_->{id}\n| }
      }

      $paymentaccount = qq|
         <tr>
	  <th align=right>|.$locale->text('Account').qq|</th>
	  <td>
	    <select name=paymentaccount>|.$form->select_option($form->{selectpaymentaccount})
	    .qq|</select>
	  </td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Currency').qq|</th>
	  <td><select name=currency>|
	  .$form->select_option($form->{selectcurrency}, $form->{currency})
	  .qq|</select></td>
	</tr>
|;

      if ($form->{selectpaymentmethod}) {
	$paymentaccount .= qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Payment Method').qq|</th>
	  <td><select name=paymentmethod>|
	  .$form->select_option($form->{selectpaymentmethod}, $form->{paymentmethod}, 1)
	  .qq|</select></td>
	</tr>
|;
      }
    }
  }

  @a = ();
  push @a, qq|<input name="l_invnumber" class=checkbox type=checkbox value=Y checked> |.$locale->text('Invoice Number');
  push @a, qq|<input name="l_description" class=checkbox type=checkbox value=Y> |.$locale->text('Description');
  push @a, qq|<input name="l_dcn" class=checkbox type=checkbox value=Y checked> |.$locale->text('DCN');
  push @a, qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> |.$locale->text('Company Name');
  push @a, qq|<input name="l_companynumber" class=checkbox type=checkbox value=Y> |.$locale->text('Company Number');
  push @a, qq|<input name="l_datepaid" class=checkbox type=checkbox value=Y checked> |.$locale->text('Date Paid');
  push @a, qq|<input name="l_amount" class=checkbox type=checkbox value=Y checked> |.$locale->text('Amount');
  push @a, qq|<input name="l_curr" class=checkbox type=checkbox value=Y> |.$locale->text('Currency');
  push @a, qq|<input name="l_paymentmethod" class=checkbox type=checkbox value=Y> |.$locale->text('Payment Method');
  push @a, qq|<input name="l_source" class=checkbox type=checkbox value=Y checked> |.$locale->text('Source');
  push @a, qq|<input name="l_memo" class=checkbox type=checkbox value=Y> |.$locale->text('Memo');
  
  
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
        $paymentaccount
        <tr>
	  <th align=right>|.$locale->text('Filename').qq|</th>
	  <td>
	    <input name=file size=20 value="$form->{file}">
	  </td>
	</tr>
	<tr valign=top>
	  <th align=right>|.$locale->text('Type of File').qq|</th>
	  <td>
	    <table>
	      <tr>
	        <td><input name=filetype type=radio class=radio value=CSV checked>&nbsp;|.$locale->text('CSV').qq|</td>
		<td width=20></td>
		<th align=right>|.$locale->text('Delimiter').qq|</th>
		<td><input name=delimiter size=2 value=","></td>
	      </tr>
	      <tr>
		<th align=right colspan=2>|.$locale->text('Tab delimited file').qq|</th>
		<td align=left><input name=tabdelimited type=checkbox class=checkbox></td>
		<th align=right>|.$locale->text('Include Header').qq|</th>
		<td align=left><input name=includeheader type=checkbox class=checkbox checked></td>
	      </tr>

	    </table>
	  </td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table>
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

  $form->hide_form(qw(defaultcurrency title type action nextsub login path));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub im_sales_invoice {

  $form->error($locale->text('Import File missing!')) if ! $form->{data};

  @column_index = qw(ndx transdate invnumber customer customernumber city invoicedescription total curr totalqty unit duedate employee);
  @flds = @column_index;
  shift @flds;
  push @flds, qw(ordnumber quonumber customer_id datepaid shippingpoint shipvia waybill terms notes intnotes language_code ponumber cashdiscount discountterms employee_id parts_id description sellprice discount qty unit serialnumber projectnumber deliverydate AR taxincluded);
  unshift @column_index, "runningnumber";
    
  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }

  &xrefhdr;
  
  $form->{vc} = 'customer';
  IM->sales_invoice(\%myconfig, \%$form);

  $column_data{runningnumber} = "&nbsp;";
  $column_data{transdate} = $locale->text('Invoice Date');
  $column_data{invnumber} = $locale->text('Invoice Number');
  $column_data{invoicedescription} = $locale->text('Description');
  $column_data{customer} = $locale->text('Customer');
  $column_data{customernumber} = $locale->text('Customer Number');
  $column_data{city} = $locale->text('City');
  $column_data{total} = $locale->text('Total');
  $column_data{totalqty} = $locale->text('Qty');
  $column_data{curr} = $locale->text('Curr');
  $column_data{unit} = $locale->text('Unit');
  $column_data{duedate} = $locale->text('Due Date');
  $column_data{employee} = $locale->text('Salesperson');

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
        <tr class=listheading>
|;

  for (@column_index) { print "\n<th>$column_data{$_}</th>" }

  print qq|
        </tr>
|;

  @ndx = split / /, $form->{ndx};
  $ndx = shift @ndx;
  $k = 0;

  for $i (1 .. $form->{rowcount}) {
    
    if ($i == $ndx) {
      $k++;
      $j++; $j %= 2;
      $ndx = shift @ndx;
   
      print qq|
        <tr class=listrow$j>
|;

      $total += $form->{"total_$i"};
      
      for (@column_index) { $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>| }
      $column_data{total} = qq|<td align=right>|.$form->format_amount(\%myconfig, $form->{"total_$i"}, $form->{precision}).qq|</td>|;
      $column_data{totalqty} = qq|<td align=right>|.$form->format_amount(\%myconfig, $form->{"totalqty_$i"}).qq|</td>|;

      $column_data{runningnumber} = qq|<td align=right>$k</td>|;
      
      if ($form->{"customer_id_$i"}) {
	$column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox checked></td>|;
      } else {
	$column_data{ndx} = qq|<td>&nbsp;</td>|;
      }

      for (@column_index) { print $column_data{$_} }

      print qq|
	</tr>
|;
    
    }

    $form->hide_form(map { "${_}_$i" } @flds);
    
  }

  # print total
  for (@column_index) { $column_data{$_} = qq|<td>&nbsp;</td>| }
  $column_data{total} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $total, $form->{precision}, "&nbsp;")."</th>";

  print qq|
        <tr class=listtotal>
|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
        </tr>
      </table>
    </td>
  </tr>
|;

  if ($form->{missingparts}) {
    print qq|
    <tr>
      <td>|;
      $form->info($locale->text('The following parts could not be found:')."\n\n");
      for (split /\n/, $form->{missingparts}) {
	$form->info("$_\n");
      }
    print qq|
      </td>
    </tr>
|;
  }

  print qq|
  <tr>
    <td><hr size=3 noshade></td>
  </tr>

</table>
|;
   
  $form->hide_form(qw(vc rowcount ndx type login path callback));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Import Sales Invoices').qq|">
</form>

</body>
</html>
|;

}


sub xrefhdr {
  
  $form->{delimiter} ||= ',';
 
  $i = 0;

  if ($form->{mapfile}) {
    open(FH, "$myconfig{templates}/import.map") or $form->error($!);

    while (<FH>) {
      next if /^(#|;|\s)/;
      chomp;

      s/\s*(#|;).*//g;
      s/^\s*(.*?)\s*$/$1/;

      last if $xrefhdr && $_ =~ /^\[/;

      if (/^\[$form->{type}\]/) {
	$xrefhdr = 1;
	next;
      }

      if ($xrefhdr) {
	($key, $value) = split /=/, $_;
	@a = split /,/, $value;
	$form->{$form->{type}}{$a[0]} = { field => $key, length => $a[1], ndx => $i++ };
      }
    }
    close FH;
    
  } else {
    # get first line
    @a = split /\n/, $form->{data};

    if ($form->{tabdelimited}) {
      $form->{delimiter} = '\t';
    } else {
      $a[0] =~ s/(^"|"$)//g;
      $a[0] =~ s/"$form->{delimiter}"/$form->{delimiter}/g;
    }
      
    for (split /$form->{delimiter}/, $a[0]) {
      $form->{$form->{type}}{$_} = { field => $_, length => "", ndx => $i++ };
    }
  }

}


sub import_sales_invoices {

  my $numberformat = $myconfig{numberformat};
  $myconfig{numberformat} = "1000.00";

  my %ndx = ();
  my @ndx = split / /, $form->{ndx};
  
  my $i;
  my $j = shift @ndx;
  my $k = shift @ndx;
  $k ||= $j;

  for $i (1 .. $form->{rowcount}) {
    if ($i == $k) {
      $j = $k;
      $k = shift @ndx;
    }
    push @{$ndx{$j}}, $i;
  }

  my $total = 0;
  
  $newform = new Form;

  my $m = 0;
  
  for $k (keys %ndx) {
    
    if ($form->{"ndx_$k"}) {

      $m++;

      for (keys %$newform) { delete $newform->{$_} };

      $newform->{precision} = $form->{precision};

      for (qw(invnumber ordnumber quonumber transdate customer customer_id datepaid duedate shippingpoint shipvia waybill terms notes intnotes curr language_code ponumber cashdiscount discountterms AR taxincluded)) { $newform->{$_} = $form->{"${_}_$k"} }
      $newform->{description} = $form->{"invoicedescription_$k"};

      $newform->{employee} = qq|--$form->{"employee_id_$k"}|;
      $newform->{department} = qq|--$form->{"department_id_$k"}|;
      $newform->{warehouse} = qq|--$form->{"warehouse_id_$k"}|;

      $newform->{type} = "invoice";

      $j = 1; 

      for $i (@{ $ndx{$k} }) {

        $total += $form->{"sellprice_$i"} * $form->{"qty_$i"};
	
	$newform->{"id_$j"} = $form->{"parts_id_$i"};
	for (qw(qty discount)) { $newform->{"${_}_$j"} = $form->format_amount($myconfig, $form->{"${_}_$i"}) }
	for (qw(description unit deliverydate serialnumber itemnotes projectnumber)) { $newform->{"${_}_$j"} = $form->{"${_}_$i"} }
	$newform->{"sellprice_$j"} = $form->format_amount($myconfig, $form->{"sellprice_$i"});

	$j++; 
      }
      
      $newform->{rowcount} = $j;
      
      # post invoice
      $form->info("${m}. ".$locale->text('Posting Invoice ...'));
      if (IM->import_sales_invoice(\%myconfig, \%$newform)) {
	$form->info(qq| $newform->{invnumber}, $newform->{description}, $newform->{customernumber}, $newform->{name}, $newform->{city}, |);
	$myconfig{numberformat} = $numberformat;
	$form->info($form->format_amount(\%myconfig, $form->{"total_$k"}, $form->{precision}));
	$myconfig{numberformat} = "1000.00";
	$form->info(" ... ".$locale->text('ok')."\n");
      } else {
	$form->error($locale->text('Posting failed!'));
      }
    }
  }

  $myconfig{numberformat} = $numberformat;
  $form->info("\n".$locale->text('Total:')." ".$form->format_amount(\%myconfig, $total, $form->{precision}));
  
}


sub im_payment {

  $form->error($locale->text('Import File missing!')) if ! $form->{data};

  @column_index = qw(runningnumber ndx invnumber description dcn name companynumber city datepaid amount);
  push @column_index, "exchangerate" if $form->{currency} ne $form->{defaultcurrency};
  @flds = @column_index;
  shift @flds;
  shift @flds;
  push @flds, qw(id source memo paymentmethod arap vc);
  
  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }
  
  &xrefhdr;
  
  IM->payments(\%myconfig, \%$form);

  $column_data{runningnumber} = "&nbsp;";
  $column_data{datepaid} = $locale->text('Date Paid');
  $column_data{invnumber} = $locale->text('Invoice');
  $column_data{description} = $locale->text('Description');
  $column_data{name} = $locale->text('Company');
  $column_data{company} = $locale->text('Company Number');
  $column_data{city} = $locale->text('City');
  $column_data{dcn} = $locale->text('DCN');
  $column_data{amount} = $locale->text('Paid');
  $column_data{exchangerate} = $locale->text('Exch');

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
        <tr class=listheading>
|;

  for (@column_index) { print "\n<th>$column_data{$_}</th>" }

  print qq|
        </tr>
|;

  for $i (1 .. $form->{rowcount}) {
    
    $j++; $j %= 2;
 
    print qq|
      <tr class=listrow$j>
|;

    $total += $form->{"amount_$i"};
    
    for (@column_index) { $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>| }
    $column_data{amount} = qq|<td align=right>|.$form->format_amount(\%myconfig, $form->{"amount_$i"}, $form->{precision}).qq|</td>|;

    $column_data{runningnumber} = qq|<td align=right>$i</td>|;
    $column_data{exchangerate} = qq|<td><input name="exchangerate_$i" size=10 value=|.$form->format_amount(\%myconfig, $form->{"exchangerate_$i"}).qq|></td>|;
    
    $column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox checked></td>|;

    for (@column_index) { print $column_data{$_} }

    print qq|
	</tr>
|;
    
    $form->{"paymentmethod_$i"} = qq|--$form->{"paymentmethod_id_$i"}|;
    $form->hide_form(map { "${_}_$i" } @flds);
    
  }

  # print total
  for (@column_index) { $column_data{$_} = qq|<td>&nbsp;</td>| }
  $column_data{amount} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $total, $form->{precision}, "&nbsp;")."</th>";

  print qq|
        <tr class=listtotal>
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
|;
  
  $form->{paymentaccount} =~ s/--.*//;

  $form->hide_form(qw(precision rowcount type paymentaccount currency defaultcurrency login path callback));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Import Payments').qq|">
</form>

</body>
</html>
|;

}


sub import_payments {

  my $m = 0;

  $newform = new Form;
  
  for my $i (1 .. $form->{rowcount}) {
    
    if ($form->{"ndx_$i"}) {

      $m++;
      
      for (keys %$newform) { delete $newform->{$_} };

      for (qw(precision currency defaultcurrency)) { $newform->{$_} = $form->{$_} }
      for (qw(vc arap exchangerate datepaid amount source memo paymentmethod)) { $newform->{$_} = $form->{"${_}_$i"} }
      $newform->{ARAP} = uc $newform->{arap};

      $newform->{rowcount} = 1;
      $newform->{"$newform->{ARAP}_paid"} = $form->{paymentaccount};
      $newform->{"paid_1"} = $form->{"amount_$i"};
      $newform->{"checked_1"} = 1;
      $newform->{"id_1"} = $form->{"id_$i"};
      
      $form->info("${m}. ".$locale->text('Posting Payment ...'));

      if (CP->post_payment(\%myconfig, \%$newform)) {
	$form->info(qq| $form->{"invnumber_$i"}, $form->{"description_$i"}, $form->{"companynumber_$i"}, $form->{"name_$i"}, $form->{"city_$i"}, |);
	$form->info($form->format_amount(\%myconfig, $form->{"amount_$i"}, $form->{precision}));
	$form->info(" ... ".$locale->text('ok')."\n");
      } else {
	$form->error($locale->text('Posting failed!'));
      }
    }
  }

}


sub ex_payment {

  %columns = ( invnumber => { ndx => 1 },
               description => { ndx => 2 },
	       dcn => { ndx => 3 },
	       name => { ndx => 4 },
	       companynumber => { ndx => 5 },
	       datepaid => { ndx => 6 },
	       amount => { ndx => 7, numeric => 1 },
	       curr => { ndx => 8 },
	       paymentmethod => { ndx => 9 },
	       source => { ndx => 10 },
	       memo => { ndx => 11 }
	     );
  
  @column_index = qw(runningnumber ndx);
  $form->{column_index} = "";
 
  for (sort { $columns{$a}->{ndx} <=> $columns{$b}->{ndx} } keys %columns) {
    push @flds, $_;
    if ($form->{"l_$_"} eq "Y") {
      push @column_index, $_;
      $form->{column_index} .= "$_=$columns{$_}->{numeric},";
    }
  }
  chop $form->{column_index};
  
  push @flds, "id";

 
  $form->{callback} = "$form->{script}?action=export";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }
  
  &xrefhdr;
  
  IM->unreconciled_payments(\%myconfig, \%$form);

  $column_data{runningnumber} = "&nbsp;";
  $column_data{ndx} = qq|<input name="allbox" type=checkbox class=checkbox value="1" checked onChange="CheckAll();">|;
  
  $column_data{datepaid} = $locale->text('Date Paid');
  $column_data{invnumber} = $locale->text('Invoice');
  $column_data{description} = $locale->text('Description');
  $column_data{name} = $locale->text('Company');
  $column_data{companynumber} = $locale->text('Company Number');
  $column_data{city} = $locale->text('City');
  $column_data{dcn} = $locale->text('DCN');
  $column_data{amount} = $locale->text('Paid');
  $column_data{paymentmethod} = $locale->text('Payment Method');
  $column_data{source} = $locale->text('Source');
  $column_data{memo} = $locale->text('Memo');
  $column_data{curr} = $locale->text('Curr');

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

  for (@column_index) { print "\n<th>$column_data{$_}</th>" }

  print qq|
        </tr>
|;

  $i = 0;
  foreach $ref (@{ $form->{TR} }) {
    
    $j++; $j %= 2;
 
    print qq|
      <tr class=listrow$j>
|;

    $i++;
    
    $total += $ref->{amount};
    
    for (@column_index) { $column_data{$_} = qq|<td>$ref->{$_}</td>| }
    $column_data{amount} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}).qq|</td>|;

    $column_data{runningnumber} = qq|<td align=right>$i</td>|;
    
    $column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox checked></td>|;

    for (@column_index) { print $column_data{$_} }

    print qq|
	</tr>
|;

    for (@flds) { $form->{"${_}_$i"} = $ref->{$_} };
    $form->hide_form(map { "${_}_$i" } @flds);
    
  }

  $form->{rowcount} = $i;

  # print total
  for (@column_index) { $column_data{$_} = qq|<td>&nbsp;</td>| }
  $column_data{amount} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $total, $form->{precision}, "&nbsp;")."</th>";

  print qq|
        <tr class=listtotal>
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
|;
  
  $form->hide_form(qw(column_index rowcount file filetype delimiter tabdelimited includeheader type paymentaccount paymentmethod currency defaultcurrency login path callback));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Export Payments').qq|">
</form>

</body>
</html>
|;

}


sub export_payments {

  open(OUT, ">-") or $form->error("STDOUT : $!");
  
  binmode(OUT);
  
  print qq|Content-Type: application/file;
Content-Disposition: attachment; filename="$form->{file}.$form->{filetype}"\n\n|;

  @column_index = split /,/, $form->{column_index};
  for (@column_index) {
    ($f, $n) = split /=/, $_;
    $column_index{$f} = $n;
  }
  @column_index = grep { s/=.*// } @column_index;

  if ($form->{tabdelimited}) {
    $form->{delimiter} = "\t";
    for (@column_index) { $column_index{$_} = 1 }
  }

  # print header
  $line = "";
  if ($form->{includeheader}) {
    for (@column_index) {
      if ($form->{tabdelimited}) {
	$line .= qq|$_$form->{delimiter}|;
      } else {
	$line .= qq|"$_"$form->{delimiter}|;
      }
    }
    chop $line;
    print OUT "$line\n";
  }
  
  for $i (1 .. $form->{rowcount}) {
    $line = "";
    if ($form->{"ndx_$i"}) {
      for (@column_index) {
	if ($column_index{$_}) {
	  $line .= qq|$form->{"${_}_$i"}$form->{delimiter}|;
	} else {
	  $line .= qq|"$form->{"${_}_$i"}"$form->{delimiter}|;
	}
      }
      chop $line;
      print OUT "$line\n";
    }
  }
  
  close(OUT);
  
}


sub continue { &{ $form->{nextsub} } };


