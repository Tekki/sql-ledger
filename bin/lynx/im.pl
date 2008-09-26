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

1;
# end of main


sub import {

  %title = ( parts => 'Parts',
             sales_invoice => 'Sales Invoices'
	   );

  $msg = "Import $title{$form->{type}}";
  $form->{title} = $locale->text($msg);
  
  $form->header;

  $form->{nextsub} = "do_import";
  $form->{action} = "continue";
 
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

  $form->hide_form(qw(title type action nextsub login path));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub do_import {

  $form->error($locale->text('Import File missing!')) if ! $form->{data};

  $i = 0;
  @column_index = qw(ndx transdate invnumber customer customernumber city invoicedescription total curr totalqty unit duedate employee);
  @flds = @column_index;
  shift @flds;
  push @flds, qw(ordnumber quonumber customer_id datepaid shippingpoint shipvia waybill terms notes intnotes language_code ponumber cashdiscount discountterms employee_id parts_id description sellprice discount qty unit serialnumber projectnumber deliverydate AR taxincluded);
  unshift @column_index, "runningnumber";
  
  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }
  
  $form->{delimiter} ||= ',';

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
      $a[0] =~ s/(^"|"$)//;
      $a[0] =~ s/"$form->{delimiter}"/$form->{delimiter}/g;
    }
      
    for (split /$form->{delimiter}/, $a[0]) {
      $form->{$form->{type}}{$_} = { field => $_, length => "", ndx => $i++ };
    }
  }

  
  $form->{nextsub} = "import_$form->{type}";
  
  if ($form->{type} eq 'sales_invoice') {
    $form->{vc} = 'customer';
    IM->sales_invoice(\%myconfig, \%$form);
  }

  $column_header{runningnumber} = "&nbsp;";
  $column_header{transdate} = $locale->text('Invoice Date');
  $column_header{invnumber} = $locale->text('Invoice Number');
  $column_header{invoicedescription} = $locale->text('Description');
  $column_header{customer} = $locale->text('Customer');
  $column_header{customernumber} = $locale->text('Customer Number');
  $column_header{city} = $locale->text('City');
  $column_header{total} = $locale->text('Total');
  $column_header{totalqty} = $locale->text('Qty');
  $column_header{curr} = $locale->text('Curr');
  $column_header{unit} = $locale->text('Unit');
  $column_header{duedate} = $locale->text('Due Date');
  $column_header{employee} = $locale->text('Salesperson');

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

  for (@column_index) { print "\n<th>$column_header{$_}</th>" }

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
      for (qw(total)) { $column_data{$_} = qq|<td align=right>|.$form->format_amount(\%myconfig, $form->{"${_}_$i"}, $form->{precision}).qq|</td>| }
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
   
  $form->hide_form(qw(vc rowcount ndx nextsub type login path callback));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Import Sales Invoices').qq|">
</form>

</body>
</html>
|;

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


sub continue { &{ $form->{nextsub} } };


