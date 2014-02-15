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
use SL::JS;

require "$form->{path}/sr.pl";

1;
# end of main


sub import {

  %title = ( sales_invoice => 'Sales Invoices',
             sales_order => 'Sales Orders',
             purchase_order => 'Purchase Orders',
	     payment => 'Payments',
	     customer => 'Customers',
	     vendor => 'Vendors',
	     part => 'Parts',
	     service => 'Services',
	     labor => 'Labor/Overhead',
	     partsgroup => 'Groups',
	     coa => 'Chart of Accounts'
	   );

# $locale->text('Import Sales Invoices')
# $locale->text('Import Sales Orders')
# $locale->text('Import Purchase Orders')
# $locale->text('Import Payments')
# $locale->text('Import Customers')
# $locale->text('Import Vendors')
# $locale->text('Import Parts')
# $locale->text('Import Services')
# $locale->text('Import Labor/Overhead')
# $locale->text('Import Groups')
# $locale->text('Import Chart of Accounts')

  $msg = "Import $title{$form->{type}}";
  $form->{title} = $locale->text($msg);
  
  $form->helpref("import_$form->{type}", $myconfig{countrycode});
  
  $form->header;

  $form->{nextsub} = "im_$form->{type}";

  $form->{delimiter} = ",";

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
	  <th align="right">|.$locale->text('Account').qq|</th>
	  <td>
	    <select name=paymentaccount>|.$form->select_option($selectpaymentaccount)
	    .qq|</select>
	  </td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Currency').qq|</th>
	  <td><select name=currency>|
	  .$form->select_option($form->{selectcurrency}, $form->{currency})
	  .qq|</select></td>
	</tr>
|;
    }
    $v11 = qq|
        <tr>
	        <td><input name=filetype type=radio class=radio value=v11>&nbsp;|.$locale->text('.v11').qq|</td>
	</tr>
|;
  }
  
  $form->all_languages(\%myconfig);

  if (@{ $form->{all_language} }) {
    $form->{language_code} = $myconfig{countrycode};
    $form->{selectlanguage_code} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage_code} .= qq|$_->{code}--$_->{description}\n| }

    $lang = qq|
            <select name=language_code>|.$form->select_option($form->{selectlanguage_code}, $form->{language_code}, undef, 1).qq|</select>|;
  }
  
print qq|
<body>

<form enctype="multipart/form-data" method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        $paymentaccount
        <tr>
	  <th align="right">|.$locale->text('File to Import').qq|</th>
	  <td>
	    <input name=data size=60 type=file>
	  </td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Type of File').qq|</th>
	  <td>
	    <table>
	      <tr>
	        <td><input name=filetype type=radio class=radio value=csv checked>&nbsp;|.$locale->text('csv').qq|</td>
		<td>|.$locale->text('Delimiter').qq|</td>
		<td><input name=delimiter size=2 value="$form->{delimiter}"></td>
		<td><input name=tabdelimited type=checkbox class=checkbox>&nbsp;|.$locale->text('Tab delimited').qq|</td>
		<td><input name=stringsquoted type=checkbox class=checkbox checked>&nbsp;|.$locale->text('Strings quoted').qq|</td>
	      </tr>
		$v11
<!--
	      <tr>
	        <td><input name=filetype type=radio class=radio value=xml>&nbsp;|.$locale->text('xml').qq|</td>
	      </tr>
-->
	      <tr>
		<td><input name=mapfile type=checkbox value=1>&nbsp;|.$locale->text('Mapfile').qq|</td><td colspan=3>$lang</td>
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

  $form->hide_form(qw(defaultcurrency title type nextsub login path));

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

  $form->{filename} ||= time;

  $msg = "Export $title{$form->{type}}";
  $form->{title} = $locale->text($msg);
  
  $form->helpref("export_$form->{type}", $myconfig{countrycode});
  
  $form->header;

  $form->{nextsub} = "ex_$form->{type}";
  $form->{action} = "continue";

  $form->{reportcode} = "export_$form->{type}";
  $form->{initreport} = 1;
  
  for (qw(mm-dd-yy mm/dd/yy dd-mm-yy dd/mm/yy dd.mm.yy yyyy-mm-dd mmddyy ddmmyy yymmdd mmddyyyy ddmmyyyy yyyymmdd)) { $selectdateformat .= "$_\n" }
  $form->{dateformat} = $myconfig{dateformat};

  $form->reports(\%myconfig);

  if (@{ $form->{all_report} }) {
    $form->{selectreportform} = "\n";
    for (@{ $form->{all_report} }) { $form->{selectreportform} .= qq|$_->{reportdescription}--$_->{reportid}\n| }
    
    $reportform = qq|
       <tr>
	<th align="right">|.$locale->text('Report').qq|</th>
	<td>
	  <select name=report onChange="ChangeReport();">|.$form->select_option($form->{selectreportform}, undef, 1)
	  .qq|</select>
	</td>
      </tr>
|;
  }


  @checked = qw(tabdelimited includeheader stringsquoted);
  @input = qw(paymentaccount curr paymentmethod dateprepared dateformat delimiter decimalpoint);

  for (qw(invnumber dcn name datepaid amount source)) {
    $form->{"l_$_"} = "checked";
  }
  
  for (qw(includeheader stringsquoted)) {
    $form->{$_} = "checked";
  }

  $form->{filetype} ||= "csv";
  $form->{$form->{filetype}} = 1;
  $form->{UNIX} = 1;

  %radio = (filetype => { csv => 0, txt => 1 },
            linefeed => { UNIX => 0, MAC => 1, DOS => 2, noLF => 3 });
  for $item (keys %radio) {
    for (keys %{ $radio{$item} }) {
      $form->{$_} = "checked" if $form->{$_};
    }
  }

  $form->{delimiter} = ",";
  $form->{decimalpoint} = ".";

  $i = 1;
  $includeinreport{accountnumber} = { ndx => $i++, input => 1, html => qq|<input name="l_accountnumber" class=checkbox type=checkbox value=Y $form->{l_accountnumber}>|, label => $locale->text('Account Number') };
  $includeinreport{curr} = { ndx => $i++, input => 1, html => qq|<input name="l_curr" class=checkbox type=checkbox value=Y $form->{l_curr}>|, label => $locale->text('Currency') };
  $includeinreport{paymentmethod} = { ndx => $i++, input => 1, html => qq|<input name="l_paymentmethod" class=checkbox type=checkbox value=Y $form->{l_paymentmethod}>|, label => $locale->text('Payment Method') };
  $includeinreport{dateprepared} = { ndx => $i++, input => 1, html => qq|<input name="l_dateprepared" class=checkbox type=checkbox value=Y $form->{l_dateprepared}>|, label => $locale->text('Date Prepared') };

  $includeinreport{invnumber} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_invnumber" class=checkbox type=checkbox value=Y $form->{l_invnumber}>|, label => $locale->text('Invoice Number') };
  $includeinreport{description} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_description" class=checkbox type=checkbox value=Y $form->{l_description}>|, label => $locale->text('Description') };
  $includeinreport{dcn} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_dcn" class=checkbox type=checkbox value=Y $form->{l_dcn}>|, label => $locale->text('DCN') };
  $includeinreport{name} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_name" class=checkbox type=checkbox value=Y $form->{l_name}>|, label => $locale->text('Customer/Vendor') };
  $includeinreport{companynumber} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_companynumber" class=checkbox type=checkbox value=Y $form->{l_companynumber}>|, label => $locale->text('Customer/Vendor Number') };
  $includeinreport{address1} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_address1" class=checkbox type=checkbox value=Y $form->{l_address1}>|, label => $locale->text('Address Line 1') };
  $includeinreport{address2} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_address2" class=checkbox type=checkbox value=Y $form->{l_address2}>|, label => $locale->text('Address Line 2') };
  $includeinreport{city} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_city" class=checkbox type=checkbox value=Y $form->{l_city}>|, label => $locale->text('City') };
  $includeinreport{state} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_state" class=checkbox type=checkbox value=Y $form->{l_state}>|, label => $locale->text('State/Province') };
  $includeinreport{zipcode} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_zipcode" class=checkbox type=checkbox value=Y $form->{l_zipcode}>|, label => $locale->text('Zip/Postal Code') };
  $includeinreport{country} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_country" class=checkbox type=checkbox value=Y $form->{l_country}>|, label => $locale->text('Country') };
  $includeinreport{iban} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_iban" class=checkbox type=checkbox value=Y $form->{l_iban}>|, label => $locale->text('IBAN') };
  $includeinreport{clearingnumber} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_clearingnumber" class=checkbox type=checkbox value=Y $form->{l_clearingnumber}>|, label => $locale->text('BC Number') };
  $includeinreport{membernumber} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_membernumber" class=checkbox type=checkbox value=Y $form->{l_membernumber}>|, label => $locale->text('Member Number') };
  $includeinreport{datepaid} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_datepaid" class=checkbox type=checkbox value=Y $form->{l_datepaid}>|, label => $locale->text('Date Paid') };
  $includeinreport{amount} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_amount" class=checkbox type=checkbox value=Y $form->{l_amount}>|, label => $locale->text('Amount') };
  $includeinreport{source} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_source" class=checkbox type=checkbox value=Y $form->{l_source}>|, label => $locale->text('Source') };
  $includeinreport{memo} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_memo" class=checkbox type=checkbox value=Y $form->{l_memo}>|, label => $locale->text('Memo') };
  $includeinreport{company} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_company" class=checkbox type=checkbox value=Y $form->{l_company}>|, label => $locale->text('Our Company Name') };


  if ($form->{type} eq 'payment') {
    IM->paymentaccounts(\%myconfig, \%$form);
    if (@{ $form->{all_paymentaccount} }) {
      @curr = split /:/, $form->{currencies};
      $form->{defaultcurrency} = $curr[0];
      chomp $form->{defaultcurrency};
      $form->{curr} = $form->{defaultcurrency};

      for (@curr) { $form->{selectcurrency} .= "$_\n" }
      
      $form->{selectpaymentaccount} = "";
      for (@{ $form->{all_paymentaccount} }) { $form->{selectpaymentaccount} .= qq|$_->{accno}--$_->{description}\n| }

      $form->{paymentaccount} = @{ $form->{all_paymentaccount} }[0]->{accno}.qq|--|.@{ $form->{all_paymentaccount} }[0]->{description};

      if (@{ $form->{all_paymentmethod} }) {
	$form->{selectpaymentmethod} = "\n";
	for (@{ $form->{all_paymentmethod} }) { $form->{selectpaymentmethod} .= qq|$_->{description}--$_->{id}\n| }
      }

      $paymentaccount = qq|
         <tr>
	  <th align="right">|.$locale->text('Account').qq|</th>
	  <td>
	    <select name=paymentaccount>|.$form->select_option($form->{selectpaymentaccount})
	    .qq|</select>
	  </td>
	  <td>$includeinreport{accountnumber}->{html}</td>
|;

      $currency = qq|
	<tr>
	  <th align="right" nowrap>|.$locale->text('Currency').qq|</th>
	  <td><select name=curr>|
	  .$form->select_option($form->{selectcurrency})
	  .qq|</select>
	  </td>
	  <td>$includeinreport{curr}->{html}</td>
	</tr>
|;

      if ($form->{selectpaymentmethod}) {
	$paymentmethod = qq|
	<tr>
	  <th align="right" nowrap>|.$locale->text('Payment Method').qq|</th>
	  <td><select name=paymentmethod>|
	  .$form->select_option($form->{selectpaymentmethod}, undef, 1)
	  .qq|</select></td>
	  <td>$includeinreport{paymentmethod}->{html}</td>
	</tr>
|;
      }
    } else {
      $form->error($locale->text('Payment account missing!'));
    }
  }

  $j = 0;
  for (split /\n/, $form->{address}) {
    $j++;
    $includeinreport{"companyaddress$j"} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_companyaddress$j" class=checkbox type=checkbox value=Y $form->{"l_companyaddress$j"}>|, label => $locale->text('Our Address Line')." $j" };
  }

  $includeinreport{accountclearingnumber} = { ndx => $i++, checkbox => 1, html => qq|<input name="l_accountclearingnumber" class=checkbox type=checkbox value=Y $form->{l_accountclearingnumber}>|, label => $locale->text('Our BC Number') };

  @f = ();
  for (sort { $includeinreport{$a}->{ndx} <=> $includeinreport{$b}->{ndx} } keys %includeinreport) {
    push @checked, "l_$_";
    if ($includeinreport{$_}->{checkbox}) {
      push @f, "$includeinreport{$_}->{html} $includeinreport{$_}->{label}";
    }
  }


  JS->change_report(\%$form, \@input, \@checked, \%radio);
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        $reportform
        $paymentaccount
	$currency
	$paymentmethod
	<tr>
	  <th align="right">|.$locale->text('Date Prepared').qq|</th>
	  <td>
	    <input name=dateprepared value="$form->{dateprepared}" title="$myconfig{dateformat}">
	  </td>
	  <td>$includeinreport{dateprepared}->{html}</td>
	</tr>
        <tr>
	  <th align="right">|.$locale->text('Date Format').qq|</th>
	  <td>
	    <select name=dateformat>|
	    .$form->select_option($selectdateformat, $form->{dateformat})
	    .qq|
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Type of File').qq|</th>
	  <td>
	    <table>
	      <tr>
	        <td><input name=filetype type=radio class=radio value=csv $form->{csv}>&nbsp;|.$locale->text('csv').qq|</td>
		<td>|.$locale->text('Delimiter').qq|&nbsp;<input name=delimiter size=2 value="$form->{delimiter}"></td>
		<td><input name=tabdelimited type=checkbox class=checkbox $form->{tabdelimited}>&nbsp;|.$locale->text('Tab delimited').qq|</td>
		<td><input name=includeheader type=checkbox class=checkbox $form->{includeheader}>&nbsp;|.$locale->text('Include Header').qq|</td>
		<td><input name=stringsquoted type=checkbox class=checkbox $form->{stringsquoted}>&nbsp;|.$locale->text('Strings quoted').qq|</td>
	      </tr>
	      <tr>
	        <td><input name=filetype type=radio class=radio value=txt $form->{txt}>&nbsp;|.$locale->text('Fixed Length Text').qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Linefeed').qq|</th>
	  <td>
	    <table>
	      <tr>
		<td><input name=linefeed type=radio class=radio value="UNIX" $form->{UNIX}>&nbsp;|.$locale->text('UNIX').qq|</td>
		<td><input name=linefeed type=radio class=radio value="MAC" $form->{CR}>&nbsp;|.$locale->text('MAC').qq|</td>
		<td><input name=linefeed type=radio class=radio value="DOS" $form->{DOS}>&nbsp;|.$locale->text('DOS').qq|</td>
		<td><input name=linefeed type=radio class=radio value="noLF" $form->{noLF}>&nbsp;|.$locale->text('None').qq|</td>
	      </tr>
	    </td>
	  </table>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Decimal Point').qq|</th>
	  <td><input name=decimalpoint size=2 value="$form->{decimalpoint}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
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
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
|;

  $form->hide_form(qw(initreport reportcode defaultcurrency title type action nextsub login path));

  $form->{flds} = "";
  for (sort { $includeinreport{$a}->{ndx} <=> $includeinreport{$b}->{ndx} } keys %includeinreport) { $form->{flds} .= "$_=$includeinreport{$_}->{label}," }
  chop $form->{flds};
  $form->hide_form(qw(flds));

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


sub im_sales_invoice {

  &import_file;
  
  @column_index = qw(runningnumber ndx transdate invnumber name customernumber city invoicedescription total curr totalqty unit duedate employee);
  
  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }

  &xrefhdr;

  $form->{vc} = 'customer';

  @flds = ();
  for (keys %{ $form->{$form->{type}} }) {
    push @flds, $_;
  }
  push @flds, "parts_id";
  push @flds, "$form->{vc}_id";

  $form->{reportcode} = "import_$form->{type}";
  IM->sales_invoice_links(\%myconfig, \%$form);

  $column_data{runningnumber} = "&nbsp;";
  $column_data{transdate} = $locale->text('Invoice Date');
  $column_data{invnumber} = $locale->text('Invoice Number');
  $column_data{invoicedescription} = $locale->text('Description');
  $column_data{name} = $locale->text('Customer');
  $column_data{customernumber} = $locale->text('Customer Number');
  $column_data{city} = $locale->text('City');
  $column_data{total} = $locale->text('Total');
  $column_data{totalqty} = $locale->text('Qty');
  $column_data{curr} = $locale->text('Curr');
  $column_data{unit} = $locale->text('Unit');
  $column_data{duedate} = $locale->text('Due Date');
  $column_data{employee} = $locale->text('Salesperson');

  $form->helpref("import_$form->{type}", $myconfig{countrycode});
  
  $form->header;
 
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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
      
      if ($form->{"missing_$i"}) {
	$column_data{ndx} = qq|<td>&nbsp;</td>|;
      } else {
	$column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox checked></td>|;
      }

      for (@column_index) { print $column_data{$_} }

      print qq|
	</tr>
|;
    
    }

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

  if ($form->{missingcustomer}) {
    print qq|
    <tr>
      <td>|;
      $form->info($locale->text('The following customers are not on file:')."\n\n");
      for (split /\n/, $form->{missingcustomer}) {
	$form->info("$_\n");
      }
    print qq|
      </td>
    </tr>
|;
  }

  if ($form->{missingpart}) {
    print qq|
    <tr>
      <td>|;
      $form->info($locale->text('The following parts are not on file:')."\n\n");
      for (split /\n/, $form->{missingpart}) {
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

  $form->hide_form(qw(delimiter tabdelimited mapfile stringsquoted vc rowcount ndx type login path callback));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Import Sales Invoices').qq|">
</form>

</body>
</html>
|;

}


sub im_sales_order {
  
  $form->{vc} = "customer";
  &im_order;
  
}


sub im_purchase_order {
  
  $form->{vc} = "vendor";
  &im_order;

}


sub im_order {
  
  &import_file;

  @column_index = qw(runningnumber ndx transdate ordnumber name);
  push @column_index, "$form->{vc}number";
  push @column_index, qw(city orderdescription total curr);
  
  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }
  
  if ($form->{filetype} eq 'xml') {
    &xmlorder;
  }

  &xrefhdr;

  @flds = ();
  for (keys %{ $form->{$form->{type}} }) {
    push @flds, $_;
  }
  push @flds, "parts_id";
  push @flds, "$form->{vc}_id";

  $form->{reportcode} = "import_$form->{type}";
  IM->order_links(\%myconfig, \%$form);

  $column_data{runningnumber} = "&nbsp;";
  $column_data{transdate} = $locale->text('Order Date');
  $column_data{ordnumber} = $locale->text('Order Number');
  $column_data{orderdescription} = $locale->text('Description');
  $column_data{name} = ($form->{vc} eq 'customer') ? $locale->text('Customer') : $locale->text('Vendor');
  $column_data{customernumber} = $locale->text('Customer Number');
  $column_data{vendornumber} = $locale->text('Vendor Number');
  $column_data{city} = $locale->text('City');
  $column_data{total} = $locale->text('Total');
  $column_data{curr} = $locale->text('Curr');

  $form->helpref("import_$form->{type}", $myconfig{countrycode});
  
  $form->header;
 
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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

      $column_data{runningnumber} = qq|<td align=right>$k</td>|;
      
      if ($form->{"missing_$i"}) {
	$column_data{ndx} = qq|<td>&nbsp;</td>|;
      } else {
	$column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox checked></td>|;
      }

      for (@column_index) { print $column_data{$_} }

      print qq|
	</tr>
|;
    
    }

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

  $msg = ($form->{vc} eq 'customer') ? $locale->text('The following customers are not on file:') : $locale->text('The following vendors are not on file:');
  
  if ($form->{"missing$form->{vc}"}) {
    print qq|
    <tr>
      <td>|;
      $form->info("$msg\n\n");
      for (split /\n/, $form->{"missing$form->{vc}"}) {
	$form->info("$_\n");
      }
    print qq|
      </td>
    </tr>
|;
  }


  if ($form->{missingpart}) {
    print qq|
    <tr>
      <td>|;
      $form->info($locale->text('The following parts are not on file:')."\n\n");
      for (split /\n/, $form->{missingpart}) {
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

  $form->hide_form(qw(delimiter tabdelimited mapfile stringsquoted vc rowcount ndx type login path callback));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Import Orders').qq|">
</form>

</body>
</html>
|;

}


sub im_coa {

  &import_file;

  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }

  &xrefhdr;
  
  @column_index = qw();

  for (sort { $form->{$form->{type}}{$a}{ndx} <=> $form->{$form->{type}}{$b}{ndx} } keys %{ $form->{$form->{type}} }) {
    push @column_index, $_;
  }

  $form->{reportcode} = "import_$form->{type}";

  $column_data{accno} = $locale->text('Account');
  $column_data{description} = $locale->text('Description');
  $column_data{charttype} = $locale->text('Type');
  $column_data{category} = $locale->text('Category');
  $column_data{link} = $locale->text('Link');
  $column_data{gifi_accno} = $locale->text('GIFI');
  $column_data{contra} = $locale->text('C');
  
  IM->prepare_import_data(\%myconfig, \%$form);
 
  $form->helpref("import_$form->{type}", $myconfig{countrycode});
  
  $form->header;
 
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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

      for (@column_index) { $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>| }

      $column_data{contra} = ($form->{"contra_$i"}) ? qq|<td>*</td>| : qq|<td>&nbsp;</td>|;
      
      for (@column_index) { print $column_data{$_} }

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
|;

  $form->hide_form(qw(delimiter tabdelimited mapfile stringsquoted rowcount type login path callback));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Import Chart of Accounts').qq|">
</form>

</body>
</html>
|;

}


sub import_chart_of_accounts {

  $form->{reportcode} = "import_$form->{type}";
  IM->import_coa(\%myconfig, \%$form);

  if ($form->{added}) {
    $form->info($locale->text('Added').":\n$form->{added}\n");
  }
  if ($form->{updated}) {
    $form->info($locale->text('Updated').":\n$form->{updated}\n");
  }

  $form->info;

}


sub xmlorder {

  @data = split /\n/, $form->{data};

  %xml = &xmlin(undef, \@data);
  
  for (keys %xml) {
    if ($xml{$_} =~ 'ARRAY') {
      &xmlcsvhdr($xml{$_}, \%hdr);
    }
  }

  $form->{data} = "";
  
  $i = 0;
  for (keys %hdr) {
    $order{$_} = $i;
    $form->{data} .= qq|"$_",|;
    $i++;
  }
  chop $form->{data};
  $form->{data} .= "\n";
  
  %data = ();
  
  for (keys %xml) {
    if ($xml{$_} =~ 'ARRAY') {
      &xmldata(\@{$xml{$_}}, \%data);
    }
  }
  
#  for (keys %data) {
#    warn "$_";
#    for $item (@{$data{$_}}) {
#      warn $item;
#    }
#  }

}


sub xmlin {
  my ($tag, $data) = @_;

  my $key;
  my %xml;
  
  unless ($tag) {
    $_ = shift @{$data};
    s/<\?xml //;
    s/\?>//;
    
    %xml = split /[ =]/, $_;
    
    for (keys %xml) { 
      $xml{$_} =~ s/(^"|"$)//g;
    }
  }

  while (@{$data}) {
    $_ = shift @{$data};

    if (/<(\w+)/) {
      $key = $1;
      if (/<\/$key>/) {  # endkey?
	s/^\s*//;
	s/<$key.*?>?//;
	s/<\/$key>//;
	$xml{$key} = $_;
      } else {
	push @{ $xml{$key} }, ();
	$l = @{$xml{$key}};
	%{ $xml{$key}[$l] } = &xmlin($key, $data);
      }
    }
    last if ($tag && /<\/$tag>/);
  }
  
  %xml;
  
}



sub xmlcsvhdr {
  my ($xml, $hdr) = @_;

  for $ref (@{$xml}) {
    for (keys %{$ref}) {
      if ($ref->{$_} =~ 'ARRAY') {
	&xmlcsvhdr($ref->{$_}, $hdr);
      } else {
	$hdr->{$_} = 1;
      }
    }
  }
  
}


sub xmlform {
  my ($tag, $xml, $form) = @_;

  my $i;

  for $ref (@{$xml}) {
    $i++ if $tag;

    for (keys %{$ref}) {
      if ($ref->{$_} =~ 'ARRAY') {
	&xmlform($_, $ref->{$_}, $form);
      } else {
	if ($i) {
	  $form->{"${_}_$i"} = $ref->{$_};
	} else {
	  $form->{$_} = $ref->{$_};
	}
      }
    }
  }
  
}


sub xmldata {
  my ($xml, $data) = @_;

  if ($xml =~ 'ARRAY') {
    for (@{$xml}) {
      if ($_ =~ 'ARRAY' || $_ =~ 'HASH') {
	&xmldata($_, $data);
      } else {
	push @{$data->{$_}}, $xml->{$_};
      }
    }
  } elsif ($xml =~ 'HASH') {
    for (keys %{$xml}) {
      if ($_ =~ 'ARRAY' || $_ =~ 'HASH') {
	&xmldata($_, $data);
      } else {
	push @{$data->{$_}}, $xml->{$_};
      }
    }
  }
    
}


sub xrefhdr {
  
  $form->{delimiter} ||= ',';
 
  $i = 1;

  if ($form->{mapfile}) {
    open(FH, "$templates/$myconfig{dbname}/$form->{language_code}/import.map") or $form->error($!);

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
	@f = split /,/, $value;
	$form->{$form->{type}}{$f[0]} = { field => $key, length => $f[1], ndx => $i++ };
      }
    }
    delete $form->{$form->{type}}{''};
    close FH;
    
  } else {
    # get first line
    $str = (split /\n/, $form->{data})[0];
    chomp $str;

    if ($form->{tabdelimited}) {
      $form->{delimiter} = '\t';
    } else {
      if ($form->{stringsquoted}) {
	$str =~ s/(^"|"$)//g;
	$str =~ s/"$form->{delimiter}"/$form->{delimiter}/g;
      }
    }
      
    for (split /$form->{delimiter}/, $str) {
      $form->{$form->{type}}{$_} = { field => $_, length => "", ndx => $i++ };
    }
  }

}


sub import_sales_invoices {

  $form->{reportcode} = "import_$form->{type}";

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
  
  for $k (sort keys %ndx) {
    
    if ($form->{"ndx_$k"}) {

      $m++;

      for (keys %$newform) { delete $newform->{$_} };

      for (qw(login reportcode)) { $newform->{$_} = $form->{$_} }

      $newform->{type} = "invoice";

      # post invoice
      $form->info("${m}. ".$locale->text('Posting Invoice ...'));
      if (IM->import_sales_invoice(\%myconfig, \%$newform, \@{ $ndx{$k} })) {
	$form->{precision} = $newform->{precision};

	$form->info(qq| $newform->{invnumber}, $newform->{description}, $newform->{customernumber}, $newform->{name}, $newform->{city}, |);
	$form->info($form->format_amount(\%myconfig, $newform->{invamount}, $newform->{precision}));
	$form->info(" ... ");
	
	if ($newform->{rejected}) {
	  $form->info($locale->text('rejected')."\n");
	} elsif ($newform->{updated}) {
	  $form->info($locale->text('updated')."\n");
	} else {
	  $form->info($locale->text('added')."\n");
	}
	
      } else {
	$form->error($locale->text('Posting failed!'));
      }

      $total += $newform->{invamount};

    }
  }

  $form->info("\n".$locale->text('Total:')." ".$form->format_amount(\%myconfig, $total, $form->{precision}));
  
}



sub import_orders {

  $form->{reportcode} = "import_$form->{type}";

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
  
  for $k (sort keys %ndx) {
    
    if ($form->{"ndx_$k"}) {

      $m++;

      for (keys %$newform) { delete $newform->{$_} };

      for (qw(login reportcode type vc)) { $newform->{$_} = $form->{$_} }

      # save order
      $form->info("${m}. ".$locale->text('Saving Order ...'));
      if (IM->import_order(\%myconfig, \%$newform, \@{ $ndx{$k} })) {
	$form->{precision} = $newform->{precision};

	$form->info(qq| $newform->{ordnumber}, $newform->{description}, $newform->{"$form->{vc}number"}, $newform->{name}, $newform->{city}, |);
	$form->info($form->format_amount(\%myconfig, $newform->{ordtotal}, $newform->{precision}));
	$form->info(" ... ");
	
	if ($newform->{updated}) {
	  $form->info($locale->text('updated')."\n");
	} else {
	  $form->info($locale->text('added')."\n");
	}
	
      } else {
	$form->error($locale->text('Save failed!'));
      }

      $total += $newform->{ordtotal};

    }
  }

  $form->info("\n".$locale->text('Total:')." ".$form->format_amount(\%myconfig, $total, $form->{precision}));
  
}



sub im_payment {
  
  &import_file;
 
  &{ "im_$form->{filetype}_payment" }

}


sub im_v11_payment {

  # convert post format to csv
  @data = split /\n/, $form->{data};

  pop @data;

  $form->{data} = qq|"datepaid","debit","credit","dcn"|;

  while ($_ = shift @data) {
    $form->{data} .= "\n";
    $dcn = substr($_, 12, 27);
    $credit = substr($_, 39, 10);
    $whole = substr($credit, 0, 8) * 1;
    $decimal = substr($credit, -2);
    $credit = "${whole}.$decimal";
    $debit = 0;
    $transdate = "20" . substr($_, 71, 6);

    $neg = substr($_, 0, 3);
    if (! $neg % 5) {
      $debit = $credit;
      $credit = 0;
    }

    $form->{data} .= qq|"$transdate",$debit,$credit,"$dcn"|;
  }

  $form->{filetype} = "csv";
  $form->{delimiter} = ",";
  $form->{stringsquoted} = 1;
  for (qw(tabdelimited mapfile)) { delete $form->{$_} }
  
  &{ "im_$form->{filetype}_payment" };

}


sub im_csv_payment {

  @column_index = qw(runningnumber ndx invnumber description dcn name companynumber city datepaid amount);
  push @column_index, "exchangerate" if $form->{currency} ne $form->{defaultcurrency};
  @flds = @column_index;
  shift @flds;
  shift @flds;
  push @flds, qw(id source memo paymentmethod arap vc outstanding);
  
  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }
  
  &xrefhdr;

  IM->payment_links(\%myconfig, \%$form);
  
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

  $form->helpref("import_$form->{type}", $myconfig{countrycode});

  $form->header;
 
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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

    $total += $form->parse_amount(\%myconfig, $form->{"amount_$i"});
    
    for (@column_index) { $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>| }
    $column_data{amount} = qq|<td align=right>$form->{"amount_$i"}</td>|;

    $column_data{runningnumber} = qq|<td align=right>$i</td>|;
    $column_data{exchangerate} = qq|<td><input name="exchangerate_$i" size=10 value=|.$form->format_amount(\%myconfig, $form->{"exchangerate_$i"}).qq|></td>|;

    if ($form->{"id_$i"}) {
      $column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox checked></td>|;
    } else {
      $column_data{ndx} = qq|<td></td>|;
    }

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


sub import_file {
  
  open(FH, "$userspath/$form->{tmpfile}") or $form->error("$userspath/$form->{tmpfile} : $!");
  while (<FH>) {
    $form->{data} .= $_;
  }
  close(FH);
  unlink "$userspath/$form->{tmpfile}";

  $form->error($locale->text('Import File missing!')) unless $form->{filename};
  $form->error($locale->text('No data!')) unless $form->{data};

}


sub import_payments {

  my $m = 0;

  $form->error($locale->text('Nothing to import!')) unless $form->{rowcount};
  
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
	$form->info(qq| $form->{"invnumber_$i"}, $form->{"description_$i"}, $form->{"companynumber_$i"}, $form->{"name_$i"}, $form->{"city_$i"}, $form->{"amount_$i"} ... | . $locale->text('ok'));

	$ou = $form->round_amount($form->{"outstanding_$i"} - $form->parse_amount(\%myconfig, $form->{"amount_$i"}), $form->{precision});
	if ($ou) {
	  if ($ou > 0) {
	    $ou = $form->format_amount(\%myconfig, $ou, $form->{precision});
	    $form->info(", $ou " . $locale->text('Outstanding'));
	  } else {
	    $ou = $form->format_amount(\%myconfig, $ou * -1, $form->{precision});
	    $form->info(", $ou " . $locale->text('Overpaid'));
	  }
	}

	$form->info("\n");
	
      } else {
	$form->error($locale->text('Posting failed!'));
      }
    }
  }

  $form->error($locale->text('Nothing to import!')) unless $m;

}


sub im_customer { &im_vc }
sub im_vendor { &im_vc }


sub im_vc {

  &import_file;

  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }

  &xrefhdr;
    
  @column_index = qw(runningnumber ndx);

  for (sort { $form->{$form->{type}}{$a}{ndx} <=> $form->{$form->{type}}{$b}{ndx} } keys %{ $form->{$form->{type}} }) {
    push @column_index, $_;
  }

  $column_data{runningnumber} = "&nbsp;";
  $column_data{ndx} = "&nbsp;";
  $column_data{name} = $locale->text('Name');
  $column_data{customernumber} = $locale->text('Customer Number');
  $column_data{vendornumber} = $locale->text('Vendor Number');
  $column_data{address1} = $locale->text('Street');
  $column_data{address2} = "&nbsp;";
  $column_data{city} = $locale->text('City');
  $column_data{zipcode} = $locale->text('Zipcode');
  $column_data{state} = $locale->text('State');
  $column_data{country} = $locale->text('Country');
  $column_data{cc} = $locale->text('Cc');
  $column_data{bcc} = $locale->text('Bcc');
  $column_data{notes} = $locale->text('Notes');
  $column_data{terms} = $locale->text('Terms');
  $column_data{business} = $locale->text('Business');
  $column_data{taxnumber} = $locale->text('Taxnumber');
  $column_data{sic_code} = $locale->text('SIC');
  $column_data{discount} = $locale->text('Discount');
  $column_data{creditlimit} = $locale->text('Credit Limit');
  $column_data{employee} = $locale->text('Salesperson');
  $column_data{language_code} = $locale->text('Language');
  $column_data{pricegroup} = $locale->text('Pricegroup');
  $column_data{curr} = $locale->text('Currency');
  $column_data{startdate} = $locale->text('Startdate');
  $column_data{enddate} = $locale->text('Enddate');

  $column_data{arap_accno} = ($form->{type} eq 'customer') ? $locale->text('AR') : $locale->text('AP');
  
  $column_data{payment_accno} = $locale->text('Payment');
  $column_data{discount_accno} = $locale->text('Discount');
  
  $column_data{taxaccounts} = $locale->text('Tax');
  
  $column_data{cashdiscount} = $locale->text('%');
  $column_data{discountterms} = $locale->text('Terms');
  $column_data{threshold} = $locale->text('Threshold');
  $column_data{paymentmethod} = $locale->text('Method');
  $column_data{remittancevoucher} = $locale->text('RV');

  $column_data{firstname} = $locale->text('Firstname');
  $column_data{lastname} = $locale->text('Lastname');
  $column_data{salutation} = $locale->text('Salutation');
  $column_data{contacttitle} = $locale->text('Title');
  $column_data{occupation} = $locale->text('Occupation');
  $column_data{phone} = $locale->text('Phone');
  $column_data{fax} = $locale->text('Fax');
  $column_data{email} = $locale->text('E-mail');
  $column_data{mobile} = $locale->text('Mobile');
  $column_data{gender} = $locale->text('Gender');
  $column_data{typeofcontact} = $locale->text('Type');
  
  $column_data{taxincluded} = $locale->text('T');
  $column_data{iban} = $locale->text('IBAN');
  $column_data{bic} = $locale->text('BIC');
  $column_data{bankname} = $locale->text('Bank');
  $column_data{bankaddress1} = $locale->text('Street');
  $column_data{bankcity} = $locale->text('City');
  $column_data{bankstate} = $locale->text('State');
  $column_data{bankzipcode} = $locale->text('Zipcode');
  $column_data{bankcountry} = $locale->text('Country');

  $form->helpref("import_$form->{type}", $myconfig{countrycode});
  
  $form->header;
 
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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

  $form->{reportcode} = "import_$form->{type}";
  IM->prepare_import_data(\%myconfig, \%$form);
  
  for $i (1 .. $form->{rowcount}) {

    $j++; $j %= 2;

    print qq|
	<tr class=listrow$j>
|;

    for (@column_index) {
      $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>|;
    }
      
    for (qw(address1 address2 city zipcode state country)) {
      if ($form->{"${_}_$i"}) {
	$form->{"address_$i"} .= qq|$form->{"${_}_$i"} |;
      }
    }
    chop $form->{"address_$i"};
    $column_data{address} = qq|<td>$form->{"address_$i"}</td>|;
    
    $column_data{runningnumber} = qq|<td align=right>$i</td>|;
    $column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox checked></td>|;
 
    for (@column_index) { print $column_data{$_} }
      
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
|;
  
  $form->hide_form(qw(rowcount type login path callback));

  if ($form->{type} eq 'customer') {
    %button = ('Import Customers' => { ndx => 1, key => 'I', value => $locale->text('Import Customers') });
  } else {
    %button = ('Import Vendors' => { ndx => 1, key => 'I', value => $locale->text('Import Vendors') });
  }

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
  
  print qq|
</form>

</body>
</html>
|;

}


sub import_customers { &import_vc }
sub import_vendors { &import_vc }
  
sub import_vc {

  $form->{reportcode} = "import_$form->{type}";

  IM->import_vc(\%myconfig, \%$form);

  if ($form->{added}) {
    $form->info($locale->text('Added').":\n$form->{added}");
  }
  if ($form->{updated}) {
    $form->info($locale->text('Updated').":\n$form->{updated}");
  }

  $form->info;

}


sub im_part { &im_item }
sub im_service { &im_item }
sub im_labor { &im_item }


sub im_item {
  
  &import_file;

  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }

  &xrefhdr;
    
  @column_index = qw(runningnumber ndx);

  for (sort { $form->{$form->{type}}{$a}{ndx} <=> $form->{$form->{type}}{$b}{ndx} } keys %{ $form->{$form->{type}} }) {
    push @column_index, $_;
  }

  $column_data{runningnumber} = "&nbsp;";
  $column_data{ndx} = "&nbsp;";
  $column_data{partnumber} = $locale->text('SKU');
  $column_data{description} = $locale->text('Description');
  $column_data{unit} = $locale->text('Unit');
  $column_data{listprice} = $locale->text('Listprice');
  $column_data{sellprice} = $locale->text('Sellprice');
  $column_data{lastcost} = $locale->text('Lastcost');
  $column_data{weight} = $locale->text('Weight');
  $column_data{notes} = $locale->text('Notes');
  $column_data{make} = $locale->text('Make');
  $column_data{model} = $locale->text('Model');
  $column_data{rop} = $locale->text('ROP');
  $column_data{inventory_accno} = $locale->text('Inventory');
  $column_data{income_accno} = $locale->text('Income');
  $column_data{expense_accno} = $locale->text('Expense');
  $column_data{taxaccounts} = $locale->text('Tax');
  $column_data{bin} = $locale->text('Bin');
  $column_data{image} = $locale->text('Image');
  $column_data{drawing} = $locale->text('Drawing');
  $column_data{microfiche} = $locale->text('Microfiche');
  $column_data{partsgroup} = $locale->text('Partsgroup');
  $column_data{code} = $locale->text('Partsgroup Code');
  $column_data{tariff_hscode} = $locale->text('Tariff');
  $column_data{countryorigin} = $locale->text('Origin');
  $column_data{barcode} = $locale->text('Barcode');
  $column_data{toolnumber} = $locale->text('Toolnumber');
  $column_data{priceupdate} = $locale->text('Updated');
  
  $column_data{vendornumber} = $locale->text('Vendor Number');
  $column_data{vendorpartnumber} = $locale->text('Part Number');
  $column_data{leadtime} = $locale->text('Leadtime');
  $column_data{vendorcurr} = $locale->text('Curr');

  $form->helpref("import_$form->{type}", $myconfig{countrycode});
  
  $form->header;
 
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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

  $form->{reportcode} = "import_$form->{type}";
  IM->prepare_import_data(\%myconfig, \%$form);
  
  for $i (1 .. $form->{rowcount}) {

    $j++; $j %= 2;

    print qq|
      <tr class=listrow$j>
|;

    for (@column_index) {
      $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>|;
    }
      
    $column_data{runningnumber} = qq|<td align=right>$i</td>|;
    $column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox checked></td>|;
 
    for (@column_index) { print $column_data{$_} }
      
    print qq|
	</tr>
|;
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
|;
  
  $form->hide_form(qw(rowcount type login path callback));

  %button = ('part' => { ndx => 1, key => 'I', value => $locale->text('Import Parts') },
             'service' => { ndx => 1, key => 'I', value => $locale->text('Import Services') },
	     'labor' => { ndx => 1, key => 'I', value => $locale->text('Import Labor/Overhead') }
            );

  $form->print_button(\%button, $form->{type});
  
  print qq|
</form>

</body>
</html>
|;

}


sub import_parts { &import_items }
sub import_services { &import_items }
sub import_labor { &import_items }


sub import_items {

  $form->{reportcode} = "import_$form->{type}";
  IM->import_item(\%myconfig, \%$form);

  if ($form->{added}) {
    $form->info($locale->text('Added').":\n$form->{added}\n");
  }
  if ($form->{updated}) {
    $form->info($locale->text('Updated').":\n$form->{updated}\n");
  }
  if ($form->{missingvendor}) {
    $form->info($locale->text('Missing Vendors').":\n$form->{missingvendor}\n");
  }

  $form->info;

}


sub im_partsgroup {

  &import_file;

  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }

  &xrefhdr;
    
  @column_index = qw(runningnumber ndx);

  for (sort { $form->{$form->{type}}{$a}{ndx} <=> $form->{$form->{type}}{$b}{ndx} } keys %{ $form->{$form->{type}} }) {
    push @column_index, $_;
  }

  $column_data{runningnumber} = "&nbsp;";
  $column_data{ndx} = "&nbsp;";
  $column_data{partsgroup} = $locale->text('Group');
  $column_data{code} = $locale->text('Code');
  $column_data{pos} = $locale->text('POS');
  
  $form->helpref("import_$form->{type}", $myconfig{countrycode});

  $form->header;
 
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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

  $form->{reportcode} = "import_$form->{type}";
  IM->prepare_import_data(\%myconfig, \%$form);
  
  for $i (1 .. $form->{rowcount}) {

    $j++; $j %= 2;

    print qq|
      <tr class=listrow$j>
|;

    for (@column_index) {
      $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>|;
    }
      
    $column_data{runningnumber} = qq|<td align=right>$i</td>|;
    $column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox checked></td>|;
 
    for (@column_index) { print $column_data{$_} }
      
    print qq|
	</tr>
|;
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
|;
  
  $form->hide_form(qw(rowcount type login path callback));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Import Groups').qq|">
</form>

</body>
</html>
|;

}


sub import_groups {

  $form->{reportcode} = "import_$form->{type}";
  IM->import_groups(\%myconfig, \%$form);

  if ($form->{added}) {
    $form->info($locale->text('Added').":\n$form->{added}");
  }
  if ($form->{updated}) {
    $form->info($locale->text('Updated').":\n$form->{updated}");
  }

  $form->info;

}


sub ex_payment {

  $form->retrieve_form(\%myconfig);

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};

  if ($form->{initreport} && $form->{reportid}) {
    $form->retrieve_report(\%myconfig);
  }
  
  @columns = ();
  for (split /,/, $form->{flds}) {
    ($column, $label) = split /=/, $_;
    push @columns, $column;
    $column_data{$column} = $label;
  }

  $columns{amount} = 1;

  @flds = ();
  
  @column_index = qw(ndx);

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

  push @flds, "id";

  $form->{callback} = "$form->{script}?action=export";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }
  
  &xrefhdr;

  $form->{nextsub} = "ex_payment";

  if ($form->{editcolumn}) {
    delete $form->{id};
    &edit_column;
    exit;
  }

  IM->unreconciled_payments(\%myconfig, \%$form);

  if ($form->{initreport}) {
    
    @column_index = ();
    $form->{column_index} = "";
    
    $i = 0;
    $j = 0;
    
    for (split /,/, $form->{report_column_index}) {
      $_ =~ s/=.*//;

      $j++;

      # if it is not a column turn on l_
      if (! $column_data{$_}) {
	$form->{"l_$_"} = 1;
	$label = $_;
	$label =~ s/_/ /g;

	$form->{flds} .= qq|,$_=$label|;
	$columns{$_};
	$column_data{$_} = $label;
      }
      
      if ($form->{"l_$_"}) {
	push @column_index, $_;
	delete $column_index{$_};
	$i++;
	
	for $item (qw(a w f)) {
	  $form->{"${item}_$i"} = $form->{"report_${item}_$j"};
	  $form->{"t_${item}_$i"} = $form->{"report_t_${item}_$j"};
	  $form->{"h_${item}_$i"} = $form->{"report_h_${item}_$j"};
	}
      }
      
    }

    for (sort { $column_index{$a} <=> $column_index{$b} } keys %column_index) {
      push @column_index, $_;
    }
    
    $form->{column_index} = "";
    for (@column_index) { $form->{column_index} .= "$_=$columns{$_}," }
    chop $form->{column_index};

    unshift @column_index, qw(ndx);

  } else {
    if ($form->{movecolumn}) {
      @column_index = $form->sort_column_index;
      unshift @column_index, qw(ndx);
    }
  }

  delete $form->{initreport};
  
  $i = 0;
  %column_index = ();
  for (@column_index) {
    $column_index{$_} = $i++;
  }

  $form->save_form(\%myconfig);
  
  $href = "$form->{script}?action=ex_payment";
  for (qw(path login id)) { $href .= qq|&$_=$form->{$_}| }

  $form->{decimalpoint} = "" unless $form->{precision};
  $myconfig{numberformat} = "1000$form->{decimalpoint}" . "0" x $form->{precision};

  if ($form->{filetype} eq 'txt') {
    $lf = "\n";
    $br = "<br>";
  } else {
    $lf = $br = " ";
  }
    
  $column_data{ndx} = qq|<input name="allbox" type=checkbox class=checkbox value="1" checked onChange="CheckAll();">|;
  
  $form->helpref("export_$form->{type}", $myconfig{countrycode});
  
  $form->header;

  JS->check_all(qw(allbox ndx_));

  print qq|
  
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
|;

  $l = $#column_index;
  
  print qq|<tr>
	     <td></td>|;

  if ($l > 1) {
    for (1 .. $l) {
      print "\n<td align=center><a href=$href&movecolumn=$column_index[$_],left><img src=$images/left.png border=0><a href=$href&movecolumn=$column_index[$_],right><img src=$images/right.png border=0></td>";
    }
  }
  
  print qq|
	</tr>
|;

  for $i (1 .. $l) {
    $form->hide_form(map { "${_}_$i" } qw(f a w t_f t_a t_w h_f h_a h_w));
  }

  $dateprepared = $form->format_date($form->{dateformat}, $form->datetonum(\%myconfig, $form->{dateprepared}));
  $hdateprepared = $form->pad($dateprepared, $form->{"h_f_$column_index{dateprepared}"}, $form->{"h_a_$column_index{dateprepared}"}, $form->{"h_w_$column_index{dateprepared}"}, 1);
  $tdateprepared = $form->pad($dateprepared, $form->{"t_f_$column_index{dateprepared}"}, $form->{"t_a_$column_index{dateprepared}"}, $form->{"t_w_$column_index{dateprepared}"}, 1);
  
  $txtheader = 0;
  for (1 .. $#column_index) {
    if ($form->{"h_w_$_"}) {
      $txtheader = 1;
      last;
    }
  }

  # print header
  if (($form->{filetype} eq 'txt') &! $txtheader) {
    $column_h{ndx} = qq|<td>&nbsp;</td>|;
    
    for (1 .. $#column_index) {
      $f = "&nbsp;" x $form->{"w_$_"};
      $column_h{$column_index[$_]} = qq|<th><a href="$href&editcolumn=$column_index[$_],$_,h">$f</a></th>|;
    }
    
    print qq|
        <tr>
|;

    for (@column_index) { print "\n$column_h{$_}" }
  
    print qq|
        </tr>
|; 

  }

  print qq|
      <tr class=listheading>
|;

  print "\n<th class=listheading nowrap>$column_data{$column_index[0]}</th>";
  for (1 .. $l) {
    $class = "listheading";
    if ($form->{filetype} eq 'txt') {
      $class = "undefined" unless ($form->{"w_$_"});
    }

    print qq|\n<th nowrap><a class="$class" href="$href&editcolumn=$column_index[$_],$_">$column_data{$column_index[$_]}</a></th>|;
  }

  print qq|
      </tr>
|;

  $j = 0;
  for (split /\n/, $form->{address}) {
    $j++;
    $form->{"companyaddress$j"} = $_;
    $companyaddress = $j;
  }

  $idateprepared = $form->pad($dateprepared, $form->{"f_$column_index{dateprepared}"}, $form->{"a_$column_index{dateprepared}"}, $form->{"w_$column_index{dateprepared}"}, 1);
  
  $i = 0;
  $k = 1;
  $s = 0;
  $l = $#{ $form->{TR} } + 1;

  foreach $ref (@{ $form->{TR} }) {

    $i++;
    $s++;

    for (qw(accountnumber curr paymentmethod accountclearingnumber company)) { $ref->{$_} = $form->{$_} }
    for (1 .. $companyaddress) {
      $ref->{"companyaddress$_"} = $form->{"companyaddress$_"};
    }

    if (($ref->{datepaid} ne $sameday) && $txtheader) {
      $column_data{ndx} = qq|<td>&nbsp;</td>|;
      
      print qq|
      <tr class=listtop>
|;

      for (1 .. $#column_index) {

	if ($form->{"h_w_$_"}) {
	  $f = $ref->{"$column_index[$_]"};

	  if (! exists $ref->{"$column_index[$_]"}) {
	    $f = $form->{"h_f_$_"};
	  
	    if ($f =~ /-(-|\+)??\d+/) {
	      $f =~ s/-((-|\+)??\d+)//;
	      $c = $1;
	      if ($f =~ /s/i) {
		$f = $s + $c;
	      } else {
		$f = $k + $c;
	      }
	    }
	  }
	} else {
	  $f = "&nbsp;" x $form->{"w_$_"};
	}
	
	$column_data{$column_index[$_]} = qq|<th align="$form->{"h_a_$_"}"><a class=listtop href="$href&editcolumn=$column_index[$_],$_,h">|.$form->pad($f, $form->{"h_f_$_"}, $form->{"h_a_$_"}, $form->{"h_w_$_"}, 1).qq|</a></th>|;

      }

      $column_data{dateprepared} = qq|<th nowrap align="$form->{"h_a_$column_index{dateprepared}"}"><a class=listtop href="$href&editcolumn=dateprepared,$column_index{dateprepared},h">$hdateprepared</th>| if $form->{"h_w_$column_index{dateprepared}"};

      for (@column_index) { print $column_data{$_} }
      
      print qq|
        </tr>
|; 

    }

    $j++; $j %= 2;
 
    print qq|
      <tr class=listrow$j>
|;

    $total += $ref->{amount};
    $subtotal += $ref->{amount};

    for (@column_index) {
      $f = $ref->{$_};
      if (! exists $ref->{$_}) {
	$f = $form->{"f_$column_index{$_}"};
	if ($f =~ /-(-|\+)??\d+/) {
	  $f =~ s/-((-|\+)??\d+)//;
	  $c = $1;
	  if ($f =~ /s/i) {
	    $f = $s + $c
	  } else {
	    $f = $k + $c;
	  }
	}
      }

      $column_data{$_} = qq|<td nowrap align="$form->{"a_$column_index{$_}"}">|.$form->pad($f, $form->{"f_$column_index{$_}"}, $form->{"a_$column_index{$_}"}, $form->{"w_$column_index{$_}"}, 1).qq|</td>|;
    }

    $column_data{dateprepared} = qq|<td nowrap align="$form->{"a_$column_index{dateprepared}"}">$idateprepared</td>| if $form->{"w_$column_index{dateprepared}"};

    if ($form->{filetype} eq 'txt') {
      $column_data{amount} = qq|<td nowrap align="$form->{"a_$column_index{amount}"}">|.$form->pad($form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}), $form->{"f_$column_index{amount}"}, $form->{"a_$column_index{amount}"}, $form->{"w_$column_index{amount}"}, 1).qq|</td>|;
    } else {
      $column_data{amount} = qq|<td nowrap align="right">|.$form->pad($form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}), $form->{"f_$column_index{amount}"}, $form->{"a_$column_index{amount}"}, $form->{"w_$column_index{amount}"}, 1).qq|</td>|;
    }

    $column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox value=$ref->{id} checked></td>
    <input type=hidden name="datepaid_$i" value="$ref->{datepaid}">|;

    for (@column_index) { print $column_data{$_} }

    print qq|
	</tr>
|;

    $sameday = $ref->{datepaid};
    $nextday = "";
    if ($i < $l) {
      $nextday = $form->{TR}->[$i]->{datepaid};
    }

    # subtotal
    if (($nextday ne $sameday) && $txtheader) {
      $column_data{ndx} = qq|<td>&nbsp;</td>|;
      
      for (1 .. $#column_index) {

	if ($form->{"t_w_$_"}) {
	  $f = $ref->{"$column_index[$_]"};
	  if (! exists $ref->{"$column_index[$_]"}) {
	    $f = $form->{"t_f_$_"};
	    
	    if ($f =~ /-(-|\+)??\d+/) {
	      $f =~ s/-((-|\+)??\d+)//;
	      $c = $1;
	      if ($f =~ /s/i) {
		$f = $s + $c
	      } else {
		$f = $k + $c;
	      }
	    }
	  }
	} else {
	  $f = "&nbsp;" x $form->{"w_$_"};
	}
	
	$column_data{$column_index[$_]} = qq|<th align="$form->{"t_a_$_"}"><a class=listsubtotal href="$href&editcolumn=$column_index[$_],$_,t">|.$form->pad($f, $form->{"t_f_$_"}, $form->{"t_a_$_"}, $form->{"t_w_$_"}, 1).qq|</a></th>|;
      }
     
      $column_data{dateprepared} = qq|<th nowrap align="$form->{"t_a_$column_index{dateprepared}"}"><a class=listsubtotal href="$href&editcolumn=dateprepared,$column_index{dateprepared},t">$tdateprepared</th>| if $form->{"t_w_$column_index{dateprepared}"};
      
      $column_data{amount} = qq|<th align="$form->{"t_a_$column_index{amount}"}"><a class=listsubtotal href="$href&editcolumn=amount,$column_index{amount},t">|.$form->pad($form->format_amount(\%myconfig, $subtotal, $form->{precision}), $form->{"t_f_$column_index{amount}"}, $form->{"t_a_$column_index{amount}"}, $form->{"t_w_$column_index{amount}"}, 1).qq|</a></th>|;

      $subtotal = 0;
      $s = 0;
      
      $k++;

      print qq|
	<tr class=listsubtotal>
|;

      for (@column_index) { print $column_data{$_} }
      
      print qq|
        </tr>
|; 

    }

    if (! $txtheader) {
      $k++;
    }

  }

  $form->{rowcount} = $i + 1;

  # print total
  if ($form->{filetype} eq 'txt') {
    if (! $txtheader) {
      $column_data{ndx} = qq|<td>&nbsp;</td>|;
      
      for (1 .. $#column_index) {

	if ($form->{"t_w_$_"}) {
	  $f = $form->{$column_index[$_]};
	  
	  if ($form->{"t_f_$_"} =~ /-(-|\+)??\d+/) {
	    $f = $form->{"t_f_$_"};
	    $f =~ s/-((-|\+)??\d+)//;
	    $f = $1 + $form->{rowcount};
	  }
	} else {
	  $f = "&nbsp;" x $form->{"w_$_"};
	}
	
	$column_data{$column_index[$_]} = qq|<th align="$form->{"t_a_$_"}"><a class=listtotal href="$href&editcolumn=$column_index[$_],$_,t">|.$form->pad($f, $form->{"t_f_$_"}, $form->{"t_a_$_"}, $form->{"t_w_$_"}, 1).qq|</a></th>|;
      }
      
      $column_data{dateprepared} = qq|<th nowrap align="$form->{"t_a_$column_index{dateprepared}"}"><a class=listsubtotal href="$href&editcolumn=dateprepared,$column_index{dateprepared},t">$tdateprepared</th>| if $form->{"t_w_$column_index{dateprepared}"};
      
      $column_data{amount} = qq|<th align="$form->{"t_a_$column_index{amount}"}"><a class=listtotal href="$href&editcolumn=amount,$column_index{amount},t">|.$form->pad($form->format_amount(\%myconfig, $total, $form->{precision}), $form->{"t_f_$column_index{amount}"}, $form->{"t_a_$column_index{amount}"}, $form->{"t_w_$column_index{amount}"}, 1).qq|</a></th>|;

      print qq|
        <tr class=listtotal>
|;

      for (@column_index) { print "\n$column_data{$_}" }
    
      print qq|
        </tr>
|;

    }

  } else {
    for (@column_index) { $column_data{$_} = qq|<td>&nbsp;</td>| }
    $column_data{amount} = qq|<th class=listtotal align="right">|.$form->format_amount(\%myconfig, $total, $form->{precision}).qq|</th>|;
    
    print qq|
        <tr class=listtotal>
|;

    for (@column_index) { print "\n$column_data{$_}" }
  
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
|;
  
  $form->hide_form(qw(login path report reportcode paymentaccount curr paymentmethod dateprepared dateformat filetype delimiter decimalpoint tabdelimited includeheader stringsquoted defaultcurrency type flds column_index rowcount linefeed callback nextsub title));
  
  %button = ('Export Payments' => { ndx => 1, key => 'E', value => $locale->text('Export Payments') },
             'Reconcile Payments' => { ndx => 2, key => 'R', value => $locale->text('Reconcile Payments') },
             'Add Column' => { ndx => 3, key => 'A', value => $locale->text('Add Column') },
             'Save Report' => { ndx => 4, key => 'S', value => $locale->text('Save Report') }
	    );

  delete $button{'Export Payments'} if ! $form->{rowcount};

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


sub export_payments {

  for (1 .. $form->{rowcount}) {
    $id{$form->{"ndx_$_"}} = $_;
    delete $form->{"datepaid_$_"};
  }

  # get transactions
  IM->unreconciled_payments(\%myconfig, \%$form);

  $j = 0;
  for (split /\n/, $form->{address}) {
    $j++;
    $form->{"companyaddress$j"} = $_;
  }

  $i = 1;
  for (split /,/, $form->{column_index}) {
    $_ =~ s/=.*//;
    $column_index{$_} = $i++;
  }

  %lf = ( UNIX => "\n", MAC => "\r", DOS => "\r\n" );
  $lf = $lf{$form->{linefeed}};

  $dateprepared = $form->{dateprepared};

  $form->{dateprepared} = $form->format_date($form->{dateformat}, $form->datetonum(\%myconfig, $form->{dateprepared}));

  $myconfig{numberformat} = "1000$form->{decimalpoint}" . "0" x $form->{precision};
  
  $txtheader = 0;
  if ($form->{filetype} eq 'txt') {
    for (keys %column_index) {
      if ($form->{"h_w_$column_index{$_}"}) {
	$txtheader = 1;
	last;
      }
    }
  }

  $i = 0;
  $j = 0;
  $l = $#{ $form->{TR} } + 1;
  $total = 0;
  $k = 1;
  $s = 0;

  foreach $ref (@{ $form->{TR} }) {
    if ($id{$ref->{id}}) {
      $j++;
      $s++;

      if (($ref->{datepaid} ne $sameday) && $txtheader) {

	$i++;
	
	for (keys %column_index) {

	  if ($form->{"h_w_$column_index{$_}"}) {

	    if (exists $ref->{$_}) {
	      $f = $ref->{$_};
	    } else {
	      $f = $form->{"h_f_$column_index{$_}"};
	     
	      if ($f =~ /-(-|\+)??\d+/) {
		$f =~ s/-((-|\+)??\d+)//;
		$c = $1;
		if ($f =~ /s/i) {
		  $f = $s + $c
		} else {
		  $f = $k + $c;
		}
	      } else {
		$f = $form->{$_};
	      }
	    }
	  
	    $form->{"${_}_$i"} = $form->pad($f, $form->{"h_f_$column_index{$_}"}, $form->{"h_a_$column_index{$_}"}, $form->{"h_w_$column_index{$_}"});

	  }
	}
      }

      $total += $ref->{amount};
      $subtotal += $ref->{amount};
      $i++;
      
      $ref->{amount} = $form->format_amount(\%myconfig, $ref->{amount}, $form->{precision});

      for (keys %column_index) {

        if ($form->{filetype} eq 'txt') {
	  next unless $form->{"w_$column_index{$_}"};
	}

	if (exists $ref->{$_}) {
	  $f = $ref->{$_};
	} else {
	  $f = $form->{"f_$column_index{$_}"};

	  if ($f =~ /-(-|\+)??\d+/) {
	    $f =~ s/-((-|\+)??\d+)//;
	    $c = $1;
	    if ($f =~ /s/i) {
	      $f = $s + $c
	    } else {
	      $f = $k + $c;
	    }
	  } else {
	    $f = $form->{$_};
	  }
	}

	$form->{"${_}_$i"} = $form->pad($f, $form->{"f_$column_index{$_}"}, $form->{"a_$column_index{$_}"}, $form->{"w_$column_index{$_}"});

      }

      # subtotal
      $sameday = $ref->{datepaid};
      $nextday = "";
      if ($j < $l) {
	$nextday = $form->{TR}->[$j]->{datepaid};
      }

      # subtotal
      if (($nextday ne $sameday) && $txtheader) {

	$i++;

	for (keys %column_index) {

	  if ($form->{"t_w_$column_index{$_}"}) {
	    
	    if (exists $ref->{$_}) {
	      $f = $ref->{$_};
	    } else {
	      $f = $form->{"t_f_$column_index{$_}"};
	    
	      if ($f =~ /-(-|\+)??\d+/) {
		$f =~ s/-((-|\+)??\d+)//;
		$c = $1;
		if ($f =~ /s/i) {
		  $f = $s + $c
		} else {
		  $f = $k + $c;
		}
	      } else {
		$f = $form->{$_};
	      }
	    }

	    $form->{"${_}_$i"} = $form->pad($f, $form->{"t_f_$column_index{$_}"}, $form->{"t_a_$column_index{$_}"}, $form->{"t_w_$column_index{$_}"});
	  }
	}
	
	$form->{"amount_$i"} = $form->pad($form->format_amount(\%myconfig, $subtotal, $form->{precision}), $form->{"t_f_$column_index{amount}"}, $form->{"t_a_$column_index{amount}"}, $form->{"t_w_$column_index{amount}"}) if $form->{"t_w_$column_index{amount}"};
	
	$subtotal = 0;
	$s = 0;
	$k++;
	
      }

      $k++ unless $txtheader;

    }
  }
  
  $form->{rowcount} = $i;

  if ($form->{filetype} eq 'txt') {

    if (! $txtheader) {
      
      for (keys %column_index) {
	if ($form->{"t_w_$column_index{$_}"}) {
	  $summaryrecord = 1;
	  last;
	}
      }
      
      if ($summaryrecord) {
	
	$form->{rowcount} = ++$i;

	for (keys %column_index) {

	  if ($form->{"t_w_$column_index{$_}"}) {
	    $f = $form->{"t_f_$column_index{$_}"};
	    
	    if ($form->{"t_f_$column_index{$_}"} =~ /-(-|\+)??\d+/) {
	      $f =~ s/-((-|\+)??\d+)//;
	      $f = $1 + $form->{rowcount};
	    } else {
	      $f ||= $form->{$_};
	    }
       
	    $form->{"${_}_$i"} = $form->pad($f, $form->{"t_f_$column_index{$_}"}, $form->{"t_a_$column_index{$_}"}, $form->{"t_w_$column_index{$_}"});
	  }
	}

	$form->{"amount_$i"} = $form->pad($form->format_amount(\%myconfig, $total, $form->{precision}), $form->{"t_f_$column_index{amount}"}, $form->{"t_a_$column_index{amount}"}, $form->{"t_w_$column_index{amount}"}) if $form->{"t_w_$column_index{amount}"};
	
      }
    }
  }

  $form->{filename} ||= time;

  open(OUT, ">-") or $form->error("STDOUT : $!");
  
  binmode(OUT);

  print qq|Content-Type: application/file;
Content-Disposition: attachment; filename="$form->{filename}.$form->{filetype}"\n\n|;


  if ($form->{filetype} eq 'csv') {
    &export_payments_csv;
  }

  if ($form->{filetype} eq 'txt') {
    &export_payments_txt;
  }
  
  close(OUT);

  $form->{dateprepared} = $dateprepared;

}


sub export_payments_csv {
  
  @column_index = ();
  for (split /,/, $form->{column_index}) {
    ($f, $n) = split /=/, $_;
    $column_index{$f} = $n;
    push @column_index, $f;
  }

  if ($form->{tabdelimited}) {
    $form->{delimiter} = "\t";
    for (@column_index) { $column_index{$_} = 1 }
  }
  
  %lf = ( UNIX => "\n", MAC => "\r", DOS => "\r\n" );
  $lf = $lf{$form->{linefeed}};
  $lf ||= "\n";

  # print header
  $line = "";
  if ($form->{includeheader}) {
    for (@column_index) {
      if ($form->{tabdelimited}) {
	$line .= qq|$_$form->{delimiter}|;
      } else {
	if ($form->{stringsquoted}) {
	  $line .= qq|"$_"$form->{delimiter}|;
	} else {
	  $column_index{$_} = 1;
	  $line .= qq|$_$form->{delimiter}|;
	}
      }
    }
    chop $line;
    print OUT "$line$lf";
  }
  
  for $i (1 .. $form->{rowcount}) {
    $line = "";
    for (@column_index) {
      if ($column_index{$_}) {
	$line .= qq|$form->{"${_}_$i"}$form->{delimiter}|;
      } else {
	$line .= qq|"$form->{"${_}_$i"}"$form->{delimiter}|;
      }
    }
    chop $line;
    print OUT "$line$lf";
  }

}


sub export_payments_txt {
  
  @column_index = ();
  $i = 1;
  for (split /,/, $form->{column_index}) {
    $_ =~ s/=.*//;
    $column_index{$_} = $i++;
    push @column_index, $_;
  }

  %lf = ( UNIX => "\n", MAC => "\r", DOS => "\r\n" );
  $lf = $lf{$form->{linefeed}};
  
  for $i (1 .. $form->{rowcount}) {
    $line = "";
    for (@column_index) { $line .= $form->{"${_}_$i"} }
    print OUT "$line$lf";
  }

}


sub reconcile_payments {

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form;

  print qq|
<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>

<h4>|.$locale->text('Are you sure you want to reconcile all marked payments').qq|</h4>
<p>
<input name=action class=submit type=submit value="|.$locale->text('Yes, reconcile payments').qq|">
</form>

</body>
</html>
|;

}


sub yes__reconcile_payments {

  # reconcile payments
  IM->reconcile_payments(\%myconfig, \%$form);

  $form->redirect;

}



sub continue { &{ $form->{nextsub} } };


