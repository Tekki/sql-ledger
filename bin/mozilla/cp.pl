#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Payment module
#
#======================================================================


use SL::CP;
use SL::OP;
use SL::AA;
use SL::VR;

require "$form->{path}/arap.pl";
require "$form->{path}/js.pl";

1;
# end of main


sub edit {
  
  $form->{payment} = 'payment';
  
  if ($form->{type} eq 'receipt') {
    $form->{ARAP} = "AR";
    $form->{arap} = "ar";
    $form->{vc} = "customer";
    $form->{formname} = "receipt";
  }
  if ($form->{type} eq 'check') {
    $form->{ARAP} = "AP";
    $form->{arap} = "ap";
    $form->{vc} = "vendor";
    $form->{formname} = "check";
  }

  CP->retrieve(\%myconfig, \%$form);

  # departments
  if (@{ $form->{all_department} }) { 
    $form->{selectdepartment} = "\n";
    $form->{department} = "$form->{department}--$form->{department_id}" if $form->{department};

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|$_->{description}--$_->{id}\n| }
  }

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }

  $form->{"select$form->{ARAP}"} = "";
  $form->{"select$form->{ARAP}_paid"} = "";
  $form->{"select$form->{ARAP}_discount"} = "";

  for (@{ $form->{PR}{"$form->{ARAP}_discount"} }) { $form->{"select$form->{ARAP}_discount"} .= "$_->{accno}--$_->{description}\n" }
  for (@{ $form->{PR}{"$form->{ARAP}_paid"} }) { $form->{"select$form->{ARAP}_paid"} .= "$_->{accno}--$_->{description}\n" }
  for (@{ $form->{PR}{$form->{ARAP}} }) { $form->{"select$form->{ARAP}"} .= "$_->{accno}--$_->{description}\n" }

  $form->error($locale->text('Payment account missing!')) unless $form->{"select$form->{ARAP}_paid"};
  
# $locale->text('AR account missing!')
# $locale->text('AP account missing!')
  $form->error($locale->text("$form->{ARAP} account missing!")) unless $form->{"select$form->{ARAP}"};

  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};

  $form->{selectcurrency} = "";
  for (@curr) { $form->{selectcurrency} .= "$_\n" }

  $form->{currency} ||= $form->{defaultcurrency};

  $form->{olddatepaid} = $form->{datepaid};

  $form->{$form->{ARAP}} = $form->{"old$form->{ARAP}"} = $form->{arap_accno};

  for ("$form->{vc}", "$form->{ARAP}", "$form->{ARAP}_paid", "$form->{ARAP}_discount") { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }
  for (qw(currency department business language account)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }
  
  $form->{media} ||= $myconfig{printer};
  $form->{format} ||= $myconfig{outputformat};
  $form->{format} ||= "pdf" unless $myconfig{printer};

  if ($form->{batch}) {
    if ($form->{transdate}) {
      $form->{olddatepaid} = $form->{datepaid} = $form->{transdate};
    }
  }

  # recreate payments
  $form->{rowcount} = 0;

  $i = 0;
  if (@{ $form->{transactions} }) {
    $form->{currency} = $form->{transactions}->[0]->{curr};
    
    foreach $ref (@{ $form->{transactions} }) {
      $i++;

      for (qw(id invnumber invdescription transdate duedate calcdiscount discountterms cashdiscount)) { $form->{"${_}_$i"} = $ref->{$_} }
      $ref->{exchangerate} ||= 1;
      $form->{"netamount_$i"} = $form->round_amount($ref->{netamount} / $ref->{exchangerate}, $form->{precision});
      $form->{amount} += $ref->{paid};
      $ref->{due} = $ref->{amount} / $ref->{exchangerate};
      $ref->{total} = $ref->{paid} + $ref->{discount};
      for (qw(amount paid due discount total)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}) }
      $form->{"checked_$i"} = 1;
    }
  }
  $form->{rowcount} = $i;
  
  $form->{oldcurrency} = $form->{currency};
  $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{datepaid});

  if (! $form->{readonly}) {
    if ($form->{batch}) {
      $form->{readonly} = 1 if $myconfig{acs} =~ /Vouchers--Payment Batch/ || $form->{approved};
    }
  }

  &payment_header;
  &list_invoices;
  &payment_footer;
  
}


sub payment {

  if ($form->{type} eq 'receipt') {
    $form->{ARAP} = "AR";
    $form->{arap} = "ar";
    $form->{vc} = "customer";
    $form->{formname} = "receipt";
    
    $form->helpref("receipt", $myconfig{countrycode});
  }
  if ($form->{type} eq 'check') {
    $form->{ARAP} = "AP";
    $form->{arap} = "ap";
    $form->{vc} = "vendor";
    $form->{formname} = "check";
    
    if ($form->{batch}) {
      $form->helpref("payment_voucher", $myconfig{countrycode});
    } else {
      $form->helpref("payment", $myconfig{countrycode});
    }
  }

  $form->{payment} = "payment";
  
  $form->{callback} = "$form->{script}?action=payment&path=$form->{path}&login=$form->{login}&all_vc=$form->{all_vc}&type=$form->{type}" unless $form->{callback};
  
  # setup customer/vendor selection for open invoices
  if ($form->{all_vc}) {
    $form->all_vc(\%myconfig, $form->{vc}, $form->{ARAP}, undef, $form->{datepaid});
  } else {
    CP->get_openvc(\%myconfig, \%$form);
    if ($myconfig{vclimit} > 0) {
      $form->{"all_$form->{vc}"} = $form->{name_list};
    }
    if (@{ $form->{"all_$form->{vc}"} }) {
      $form->{$form->{vc}} = qq|$form->{"all_$form->{vc}"}->[0]->{name}--$form->{"all_$form->{vc}"}->[0]->{id}|;
      $form->{"old$form->{vc}"} = $form->{$form->{vc}};

      $form->{"$form->{vc}_id"} = $form->{"all_$form->{vc}"}->[0]->{id};

      for (qw(address1 address2 city zipcode state country)) {
        $form->{$_} = $form->{"all_$form->{vc}"}->[0]->{$_};
      }
    }

  }

  $form->{"select$form->{vc}"} = "";
  if (@{ $form->{"all_$form->{vc}"} }) {
    for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|$_->{name}--$_->{id}\n| }
  }

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }

  CP->paymentaccounts(\%myconfig, \%$form);

  foreach $item (qw(department business paymentmethod)) {
    if (@{ $form->{"all_$item"} }) { 
      $form->{"select$item"} = "\n";
      $form->{$item} = qq|$form->{$item}--$form->{"${item}_id"}| if $form->{$item};

      for (@{ $form->{"all_$item"} }) { $form->{"select$item"} .= qq|$_->{description}--$_->{id}\n| }
    }
  }

  $form->{selectprinter} = "";
  for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" }
  chop $form->{selectprinter};
  
  
  $form->{"select$form->{ARAP}"} = "\n";
  $form->{"select$form->{ARAP}_paid"} = "";
  $form->{"select$form->{ARAP}_discount"} = "";

  for (@{ $form->{PR}{"$form->{ARAP}_discount"} }) { $form->{"select$form->{ARAP}_discount"} .= "$_->{accno}--$_->{description}\n" }
  for (@{ $form->{PR}{"$form->{ARAP}_paid"} }) { $form->{"select$form->{ARAP}_paid"} .= "$_->{accno}--$_->{description}\n" }
  for (@{ $form->{PR}{$form->{ARAP}} }) { $form->{"select$form->{ARAP}"} .= "$_->{accno}--$_->{description}\n" }

  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};

  $form->{selectcurrency} = "";
  for (@curr) { $form->{selectcurrency} .= "$_\n" }

  $form->{currency} = $form->{defaultcurrency};
  $form->{oldcurrency} = $form->{currency};

  $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{datepaid});

  $form->{olddatepaid} = $form->{datepaid};

  for ("$form->{vc}", "$form->{ARAP}", "$form->{ARAP}_paid", "$form->{ARAP}_discount") { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }
  for (qw(currency department business language account paymentmethod printer)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }
  
  $form->{media} ||= $myconfig{printer};
  $form->{format} ||= $myconfig{outputformat};
  $form->{format} ||= "pdf" unless $myconfig{printer};

  if ($form->{batch}) {
    if (! $form->{transdate}) {
      $form->{transdate} = $form->{datepaid};
    }
    $form->{olddatepaid} = $form->{datepaid} = $form->{transdate};
    $form->{memo} ||= $form->{batchdescription};
  }

  &payment_header;
  &payment_footer;

}


sub prepare_payments_header {

  if ($form->{type} eq 'receipt') {
    $form->{title} = $locale->text('Receipt');
  }
  if ($form->{type} eq 'check') {
    $form->{title} = $locale->text('Payment');
  }

  if ($form->{batch}) {
    $form->{title} .= " ".$locale->text('Voucher');
    if ($form->{batchdescription}) {
      $form->{title} .= " / $form->{batchdescription}";
    }
  }

  for $i (1 .. $form->{rowcount}) {
    if ($form->{"detail_$i"}) {
      $form->{"$form->{vc}_id"} = $form->{"$form->{vc}_id_$i"};
      $form->{$form->{vc}} = qq|$form->{"name_$i"}--$form->{"$form->{vc}_id_$i"}|;
      $form->{"$form->{vc}number"} = $form->{"$form->{vc}number_$i"};
      $form->{"old$form->{vc}number"} = $form->{"$form->{vc}number_$i"};
      $form->{"old$form->{vc}"} = qq|$form->{"name_$i"}--$form->{"$form->{vc}_id_$i"}|;
      $form->{"select$form->{vc}"} = $form->escape($form->{$form->{vc}},1);

      for (qw(datepaid duedatefrom duedateto)) { $form->{"old$_"} = $form->{$_} }
      last;
    }
  }

  $form->{payment} = "payment";
  $form->{allbox} = 1;

  CP->get_openinvoices(\%myconfig, \%$form);

  for ("currency","$form->{ARAP}","$form->{ARAP}_paid","$form->{ARAP}_discount","department","business","paymentmethod") {
    $form->{"old$_"} = $form->{$_};
  }

  $exchangerate = $form->{exchangerate};
  
  AA->get_name(\%myconfig, \%$form);

  for ("currency","$form->{ARAP}","$form->{ARAP}_paid","$form->{ARAP}_discount","department","business","paymentmethod") {
    $form->{$_} = $form->{"old$_"};
  }

  $form->{$form->{vc}} = qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;

  $form->{exchangerate} = $exchangerate;
  $form->{rowcount} = 0;

  $i = 0;
  foreach $ref (@{ $form->{PR} }) {
    $i++;

    for (qw(id invnumber invdescription transdate duedate calcdiscount discountterms cashdiscount netamount)) { $form->{"${_}_$i"} = $ref->{$_} }
    $ref->{exchangerate} ||= 1;
    $due = ($form->{edit}) ? $ref->{amount} : $ref->{amount} - $ref->{paid};
    $due = $form->round_amount($due / $ref->{exchangerate}, $form->{precision});
    $netamount = $form->round_amount($ref->{netamount} / $ref->{exchangerate}, $form->{precision});
    
    if ($ref->{calcdiscount}) {
      $discount = $form->round_amount($netamount * $ref->{cashdiscount}, $form->{precision})
    }

    $form->{amount} += $due - $discount;

    $form->{"due_$i"} = $form->format_amount(\%myconfig, $due, $form->{precision});
    $form->{"discount_$i"} = $form->format_amount(\%myconfig, $discount, $form->{precision});
    $form->{"amount_$i"} = $form->format_amount(\%myconfig, $ref->{amount} / $ref->{exchangerate}, $form->{precision});
    $form->{"netamount_$i"} = $form->format_amount(\%myconfig, $netamount, $form->{precision});

    $form->{"olddiscount_$i"} = $form->{"discount_$i"};
      
    $form->{"checked_$i"} = 1;
    $form->{"paid_$i"} = $form->format_amount(\%myconfig, $due - $discount, $form->{precision});
    $form->{"total_$i"} = $form->format_amount(\%myconfig, $due, $form->{precision});
  }
  $form->{rowcount} = $i;

  ($accno) = split /--/, $form->{"$form->{ARAP}_paid"};
  $form->{source} = $form->{"$form->{type}_$accno"};

  &payment_header;

}


sub payments {
  
  if ($form->{type} eq 'receipt') {
    $form->{ARAP} = "AR";
    $form->{arap} = "ar";
    $form->{vc} = "customer";
    $form->{formname} = "receipt";
    
    $form->helpref("receipts", $myconfig{countrycode});
  }
  if ($form->{type} eq 'check') {
    $form->{ARAP} = "AP";
    $form->{arap} = "ap";
    $form->{vc} = "vendor";
    $form->{formname} = "check";

    if ($form->{batch}) {
      $form->helpref("payments_voucher", $myconfig{countrycode});
    } else {
      $form->helpref("payments", $myconfig{countrycode});
    }
  }
  

  $form->{payment} = "payments";

  $form->{callback} = "$form->{script}?action=payments&path=$form->{path}&login=$form->{login}&type=$form->{type}" unless $form->{callback};
  
  CP->paymentaccounts(\%myconfig, \%$form);

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }
  
  foreach $item (qw(department business paymentmethod)) {
    if (@{ $form->{"all_$item"} }) { 
      $form->{"select$item"} = "\n";
      $form->{$item} = qq|$form->{$item}--$form->{"${item}_id"}| if $form->{$item};

      for (@{ $form->{"all_$item"} }) { $form->{"select$item"} .= qq|$_->{description}--$_->{id}\n| }
    }
  }

  $form->{"select$form->{ARAP}"} = "\n";
  $form->{"select$form->{ARAP}_paid"} = "";
  $form->{"select$form->{ARAP}_discount"} = "";

  for (@{ $form->{PR}{"$form->{ARAP}_paid"} }) { $form->{"select$form->{ARAP}_paid"} .= "$_->{accno}--$_->{description}\n" }
  for (@{ $form->{PR}{"$form->{ARAP}_discount"} }) { $form->{"select$form->{ARAP}_discount"} .= "$_->{accno}--$_->{description}\n" }
  for (@{ $form->{PR}{$form->{ARAP}} }) { $form->{"select$form->{ARAP}"} .= "$_->{accno}--$_->{description}\n" }

  $form->{selectprinter} = "";
  for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" }
  chop $form->{selectprinter};

  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};

  $form->{selectcurrency} = "";
  for (@curr) { $form->{selectcurrency} .= "$_\n" }

  $form->{oldcurrency} = $form->{currency} = $form->{defaultcurrency};
  $form->{oldduedateto} = $form->{datepaid};
  $form->{olddatepaid} = $form->{datepaid};

  for ("$form->{vc}", "$form->{ARAP}", "$form->{ARAP}_paid", "$form->{ARAP}_discount") { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }
  for (qw(currency department business language account paymentmethod printer)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }

  $form->{media} = $myconfig{printer};
  $form->{format} ||= $myconfig{outputformat};
  $form->{format} ||= "pdf" unless $myconfig{printer};
  
  if ($form->{batch}) {
    if (! $form->{transdate}) {
      $form->{transdate} = $form->{datepaid};
    }
    $form->{olddatepaid} = $form->{datepaid} = $form->{transdate};
  }

  &payments_header;
  &invoices_due;
  &payments_footer;

}


sub payments_header {

  if ($form->{type} eq 'receipt') {
    $form->{title} = $locale->text('Receipts');
  }
  if ($form->{type} eq 'check') {
    $form->{title} = $locale->text('Payments');
  }
  
  if ($form->{batch}) {
    $form->{title} .= " ".$locale->text('Voucher');
    if ($form->{batchdescription}) {
      $form->{title} .= " / $form->{batchdescription}";
    }
  }

  if ($form->{defaultcurrency}) {
    $exchangerate = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td><select name=currency onChange="javascript:document.main.submit()">|
		.$form->select_option($form->{selectcurrency}, $form->{currency})
		.qq|</select></td>
	      </tr>
|;
  }
 
  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

    $exchangerate .= qq|
 	      <tr>
		<th align=right nowrap>|.$locale->text('Exchange Rate').qq|</th>
		<td colspan=3><input name=exchangerate class="inputright" size=10 value=$form->{exchangerate}></td>
	      </tr>
|;
  }

  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td><select name=department onChange="javascript:document.main.submit()">|
		.$form->select_option($form->{selectdepartment}, $form->{department}, 1).qq|
		</select>
	      </td>
	    </tr>
| if $form->{selectdepartment};

  $business = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Type of Business').qq|</th>
		<td><select name=business onChange="javascript:document.main.submit()">|
		.$form->select_option($form->{selectbusiness}, $form->{business}, 1).qq|
		</select>
	      </td>
	    </tr>
| if $form->{selectbusiness};

  $paymentmethod = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Payment Method').qq|</th>
		<td><select name=paymentmethod onChange="javascript:document.main.submit()">|
		.$form->select_option($form->{selectpaymentmethod}, $form->{paymentmethod}, 1).qq|
		</select>
	      </td>
	    </tr>
| if $form->{selectpaymentmethod};


  $cashdiscount = qq|
 	      <tr>
		<th align=right nowrap>|.$locale->text('Cash Discount').qq|</th>
		<td colspan=3><select name="$form->{ARAP}_discount">|
		.$form->select_option($form->{"select$form->{ARAP}_discount"}, $form->{"$form->{ARAP}_discount"}).qq|</select>
		</td>
	      </tr>
| if $form->{"select$form->{ARAP}_discount"};


  if ($form->{batch}) {
    $datepaid = qq|
		<td>$form->{datepaid}</td>
		<input type=hidden name=datepaid value="$form->{datepaid}"></td>
|;
  } else {
    $datepaid = qq|
		<td><input name=datepaid value="$form->{datepaid}" title="$myconfig{dateformat}" size=11 class=date>|.&js_calendar("main", "datepaid").qq|</td>
|;
  }


  $form->header;

  &calendar;

  &check_all(qw(allbox checked_));
  
  print qq|
<script language="javascript">
<!--
javascript:window.history.forward(1);
// -->
</script>
 
<body>

<form method="post" name="main" action="$form->{script}">
|;

  $form->hide_form(qw(defaultcurrency closedto vc type formname arap ARAP title payment batch batchid batchnumber batchdescription transdate edit voucherid employee cdt precision));
  $form->hide_form(map { "old$_" } qw(currency datepaid duedatefrom duedateto department business paymentmethod));
  $form->hide_form(map { "old$_" } ("$form->{ARAP}", "$form->{ARAP}_paid", "$form->{vc}", "$form->{vc}number"));
  $form->hide_form(map { "select$_" } qw(currency department business language account paymentmethod printer));
  $form->hide_form(map { "select$_" } ("$form->{ARAP}", "$form->{ARAP}_paid", "$form->{ARAP}_discount"));
  
  for (split /%0a/, $form->{"select$form->{ARAP}_paid"}) {
    ($accno) = split /--/, $_;
    $form->hide_form("$form->{type}_$accno");
  }

  print qq|
<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
          <th align=right>|.$locale->text('Due Date').qq|</th>
          <td>
            <table>
              <tr>
                <th align=right>|.$locale->text('From').qq|</th>
                <td><input name=duedatefrom value="$form->{duedatefrom}" title="$myconfig{dateformat}" size=11 class=date>|.&js_calendar("main", "duedatefrom").qq|</td>
                <th align=right>|.$locale->text('To').qq|</th>
                <td><input name=duedateto value="$form->{duedateto}" title="$myconfig{dateformat}" size=11 class=date>|.&js_calendar("main", "duedateto").qq|</td>
              </tr>
            </table>
          </td>
              </tr>
              $department
              $business
            </table>
          </td>
          <td>
            <table>
              <tr>
                <th align=right nowrap>|.$locale->text($form->{ARAP}).qq|</th>
                <td colspan=3><select name=$form->{ARAP} onChange="javascript:document.main.submit()">|
                .$form->select_option($form->{"select$form->{ARAP}"}, $form->{"$form->{ARAP}"}).qq|</select>
                </td>
              </tr>
              <tr>
                <th align=right nowrap>|.$locale->text('Payment').qq|</th>
                <td colspan=3><select name="$form->{ARAP}_paid" onChange="javascript:document.main.submit()">|
                .$form->select_option($form->{"select$form->{ARAP}_paid"}, $form->{"$form->{ARAP}_paid"}).qq|</select>
                </td>
              </tr>
              $paymentmethod
              $cashdiscount
              <tr>
                <th align=right nowrap>|.$locale->text('Date').qq|</th>
                $datepaid
              </tr>
              $exchangerate
            </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
|;

}


sub invoices_due {

  @column_index = ();
  push @column_index, qw(detail name);
  push @column_index, "$form->{vc}number";
  push @column_index, qw(amount due checked paid memo source);
  push @column_index, "language" if $form->{selectlanguage};
  
  $colspan = $#column_index + 1;

  $invoice = $locale->text('Invoices');

  if ($form->{vc} eq 'customer') {
    $vcname = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
  } else {
    $vcname = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
  }

  print qq|
  <tr>
    <td>
      <table width=100%>
        <tr>
          <th class=listheading colspan=$colspan>$invoice</th>
        </tr>
|;

  $column_data{detail} = qq|<th></th>|;
  $column_data{"$form->{vc}number"} = qq|<th>$vcnumber</th>|;
  $column_data{name} = qq|<th>$vcname</th>|;
  $column_data{amount} = qq|<th>|.$locale->text('Amount')."</th>";
  $column_data{due} = qq|<th>|.$locale->text('Due')."</th>";
  $column_data{paid} = qq|<th>|.$locale->text('Paid')."</th>";
 
  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  
  $column_data{checked} = qq|<th><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); javascript:document.main.submit()"><input type=hidden name=action value="update"></th>|;
 
  $column_data{memo} = qq|<th>|.$locale->text('Memo')."</th>";
  $column_data{source} = qq|<th>|.$locale->text('Source')."</th>";
  $column_data{language} = qq|<th>|.$locale->text('Language')."</th>";
  
  print qq|
        <tr>
|;
  for (@column_index) { print "$column_data{$_}\n" }
  print qq|
        </tr>
|;

  $sameid = 0;

  for $i (1 .. $form->{rowcount}) {

    for (qw(amount paid due)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    $totalamount += $form->{"amount_$i"};
    $totaldue += $form->{"due_$i"};
    $totalpaid += $form->{"paid_$i"};

    for (qw(amount due paid)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $form->{precision}) }
    
    $form->hide_form(map { "${_}_$i" } qw(name id amount due));
    
    for (qw(amount due)) { $column_data{$_} = qq|<td align=right>$form->{"${_}_$i"}</td>| }
    
    $column_data{paid} = qq|<td align=center><input name="paid_$i" class="inputright" size=11 value=$form->{"paid_$i"}></td>|;

    $form->hide_form("$form->{vc}_id_$i", "$form->{vc}number_$i");
    
    $form->{"checked_$i"} = ($form->{"checked_$i"}) ? "checked" : "";
    $column_data{checked} = qq|<td align=center><input name="checked_$i" type=checkbox class=checkbox $form->{"checked_$i"} onChange="javascript:document.main.submit()"></td>|;
    
    $form->{"detail_$i"} = ($form->{"detail_$i"}) ? "checked" : "";
    $column_data{detail} = qq|<td align=center><input name="detail_$i" type=checkbox class=checkbox $form->{"detail_$i"} onChange="javascript:document.main.submit()"></td>|;

    $column_data{"$form->{vc}number"} = qq|<td>$form->{"$form->{vc}number_$i"}</td>|;
    $column_data{name} = qq|<td>$form->{"name_$i"}</td>|;
    
    $column_data{memo} = qq|<td align=center><input name="memo_$i" size=20 value="|.$form->quote($form->{"memo_$i"}).qq|"></td>|;
    $column_data{source} = qq|<td align=center><input name="source_$i" size=10 value="|.$form->quote($form->{"source_$i"}).qq|"></td>|;

    if ($form->{selectlanguage}) {
      $column_data{language} = qq|<td><select name="language_code_$i">|.$form->select_option($form->{selectlanguage}, $form->{"language_code_$i"}, undef, 1).qq|</select></td>|;
    }
    
    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>
|;
    for (@column_index) { print "$column_data{$_}\n" }
    print qq|
        </tr>
|;

    $sameid = $form->{"$form->{vc}_id_$i"};
    
  }

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{amount} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totalamount, $form->{precision}, "&nbsp;").qq|</th>|;
  $column_data{due} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totaldue, $form->{precision}, "&nbsp;").qq|</th>|;
  $column_data{paid} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totalpaid, $form->{precision}, "&nbsp;").qq|</th>|;

  print qq|
        <tr class=listtotal>
|;
  for (@column_index) { print "$column_data{$_}\n" }
  print qq|
        </tr>
      </table>
    </td>
  </tr>
|;

}


sub payments_footer {
  
  $form->{DF}{$form->{format}} = "selected";

  $transdate = $form->datetonum(\%myconfig, $form->{datepaid});
  
  $media = qq|<select name=media>
	<option value=screen>|.$locale->text('Screen');
  if ($form->{selectprinter}) {
    for (split /\n/, $form->unescape($form->{selectprinter})) { $media .= qq|
	  <option value="$_">$_| }
  }
  $media .= qq|</select>|;
  
  $format = qq|<select name=format>
  <option value="html" $form->{DF}{html}>|.$locale->text('html').qq|
  <option value="xml" $form->{DF}{xml}>|.$locale->text('XML').qq|
  <option value="txt" $form->{DF}{txt}>|.$locale->text('Text');
  
  if ($latex) {
    $format .= qq|
            <option value="ps" $form->{DF}{ps}>|.$locale->text('Postscript').qq|
	    <option value="pdf" $form->{DF}{pdf}>|.$locale->text('PDF');
  }
  $format .= qq|</select>|;

  print qq|
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
	     'Select all' => { ndx => 3, key => 'A', value => $locale->text('Select all') },
	     'Deselect all' => { ndx => 4, key => 'A', value => $locale->text('Deselect all') },
             'Preview' => { ndx => 5, key => 'V', value => $locale->text('Preview') },
             'Print' => { ndx => 6, key => 'P', value => $locale->text('Print') },
	     'Post' => { ndx => 7, key => 'O', value => $locale->text('Post') },
	    ); 

  if ($form->{allbox}) {
    delete $button{'Select all'};
  } else { 
    delete $button{'Deselect all'};
  }

  if (! $latex) {
    for ('Print', 'Preview') { delete $button{$_} }
  }

  if ($transdate <= $form->{closedto}) {
    for ('Post', 'Print', 'Preview') { delete $button{$_} }
    $media = $format = "";
  }

  if (! $form->{payments_detail}) {
    delete $button{'Back'};
  }
  
  $form->print_button(\%button);

  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

  print qq|
  $format
  $media
|;

  $form->hide_form(qw(helpref callback rowcount path login));
 
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

  unless ($form->{payment}) {
    $form->{callback} =~ s/(allbox|deselect)=//g;
    $form->{callback} .= "&allbox=1&deselect=1";
    for (1 .. $form->{rowcount}) { $form->{callback} .= "&id_${_}=1" }

    $form->redirect;
  }

  $source = $form->{"source_1"};

  $form->{"checked_1"} = 1;
  
  for (2 .. $form->{rowcount}) {
    $form->{"checked_$_"} = 1;
    $source =~ s/(\d+)/$1 + 1/e;
    $form->{"source_$_"} = $source;
  }
  
  for (1 .. $form->{rowcount}) {
    $due = $form->parse_amount(\%myconfig, $form->{"due_$_"});
    if ($form->{"calcdiscount_$_"}) {
      $form->{"discount_$_"} = $form->parse_amount(\%myconfig, $form->{"netamount_$_"}) * $form->{"cashdiscount_$_"};
    }

    $form->{"paid_$_"} = $form->format_amount(\%myconfig, $due - $form->{"discount_$_"}, $form->{precision});
  }
 
  $form->{allbox} = 1;

  &{"update_$form->{payment}"};

}


sub deselect_all {

  $form->redirect unless $form->{payment};

  for (1 .. $form->{rowcount}) {
    for my $item (qw(vc checked source memo)) { $form->{"${item}_$_"} = "" };
  }
  
  $form->{amount} = 0;
  $form->{allbox} = "";

  &{"update_$form->{payment}"};
  
}


sub update { &{"update_$form->{payment}"} }


sub update_payments {

  for (1 .. $form->{rowcount}) {
    if ($form->{"detail_$_"}) {
      $form->{payments_detail} = 1;
      &prepare_payments_header;
      &list_invoices;
      &payment_footer;
      exit;
    }
  }

  $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{datepaid});
  for ("datepaid", "duedatefrom", "duedateto", "department", "business", "currency", "$form->{ARAP}", "$form->{ARAP}_paid", "paymentmethod") {
    if ($form->{$_} ne $form->{"old$_"}) {
      if (!$form->{redo}) {
	$form->remove_locks(\%myconfig, undef, $form->{arap});
	CP->get_openinvoices(\%myconfig, \%$form);
	$form->{redo} = 1;
      }
    }
    $form->{"old$_"} = $form->{$_};
  }
 
  if ($form->{redo}) {
    
    for $i (1 .. $form->{rowcount}) {
      for (qw(id amount due paid totaldue)) { $form->{"${_}_$i"} = "" }
    }
      
    $i = 0;
    foreach $ref (@{ $form->{PR} }) {

      if ($ref->{"$form->{vc}_id"} != $sameid) {
        chop $form->{"id_$i"};
        $i++;
      }

      $amount = $form->round_amount($ref->{amount} / $ref->{exchangerate}, $form->{precision});
      $paid = $form->round_amount($ref->{paid} / $ref->{exchangerate}, $form->{precision});

      $form->{"amount_$i"} += $amount;
      $form->{"due_$i"} += $amount - $paid;

      if ($form->{"checked_$i"}) {
        $form->{"paid_$i"} += $amount - $paid;
        $form->{"totaldue_$i"} += $amount - $paid;
      }

      $form->{"id_$i"} .= "$ref->{id} ";

      $form->{"name_$i"} = $ref->{name};
      for (qw(_id number)) { $form->{"$form->{vc}${_}_$i"} = $ref->{"$form->{vc}$_"} };

      $sameid = $ref->{"$form->{vc}_id"};

    }
    $form->{rowcount} = $i;
    chop $form->{"id_$i"};

    # format paid
    for $i (1 .. $form->{rowcount}) {
      for (qw(amount paid due)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $form->{precision}) }
    }

  }

  $ndx = 1;
  $source = "";
  $done = 0;
  ($accno) = split /--/, $form->{"$form->{ARAP}_paid"};

  for (1 .. $form->{rowcount}) {
    $form->{"totaldue_$_"} = 0;

    if ($form->{"checked_$_"}) {
      $form->{"source_$_"} = $form->{"$form->{type}_$accno"} if $form->{redo} || $form->{"source_$_"} eq "";
      if (! $done) {
        $ndx = $_;
        $source = $form->{"source_$_"};
        $source =~ s/(\d+)/$1 - 1/e;
        $done = 1;
      }
    } else {
      $form->{"source_$_"} = "";
      $form->{"paid_$_"} = "";
    }
  }

  for ($ndx .. $form->{rowcount}) {
    if ($form->{"checked_$_"}) {
      $source =~ s/(\d+)/$1 + 1/e;
      $form->{"source_$_"} = $source;
      if (! $form->{"paid_$_"}) {
        $form->{"paid_$_"} = $form->{"due_$_"};
      }
    }
  }

  &payments_header;
  &invoices_due;
  &payments_footer;
  
}


sub update_payment {

  if ($form->{"$form->{vc}"}) {
    if ($form->{"$form->{vc}"} !~ /--/) {
      $name = qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;
      $new_name_selected = 1 if $name ne $form->{"old$form->{vc}"};
    } else {
      $new_name_selected = 1 if $form->{"$form->{vc}"} ne $form->{"old$form->{vc}"};
    }
  }

  if ($new_name_selected) {
    for ("$form->{ARAP}", "$form->{ARAP}_paid", "department", "business", "currency", "paymentmethod") {
      $form->{$_} = $form->{"old$_"};
    }
  }

  ($accno) = split /--/, $form->{"$form->{ARAP}_paid"};
  if ($form->{"old$form->{ARAP}_paid"} ne $form->{"$form->{ARAP}_paid"}) {
    $form->{source} = $form->{"$form->{type}_$accno"};
  }
  $form->{source} = ($form->{"$form->{type}_$accno"}) unless $form->{source};
  
  $department = $form->{department};
  $business = $form->{business};
  $currency = $form->{currency};
  $paymentmethod = $form->{paymentmethod};
  $arappaid = $form->{"$form->{ARAP}_paid"};

  if (! $form->{all_vc}) {

    if ($form->{$form->{ARAP}} ne $form->{"old$form->{ARAP}"} ||
        $form->{business} ne $form->{oldbusiness} ||
        $form->{department} ne $form->{olddepartment}) {

      for ("$form->{ARAP}", "business", "department") { $form->{"old$_"} = $form->{$_}}

      $form->remove_locks(\%myconfig, undef, $form->{arap});
      $form->{redo} = 1;
      $form->{locks_removed} = 1;
      $rv = CP->get_openvc(\%myconfig, \%$form);
      
      if ($myconfig{vclimit} > 0) {
        $form->{"all_$form->{vc}"} = $form->{name_list};
      } else {

        if ($rv > 1) {
          # assign old values
          for ("$form->{ARAP}", "department", "business", "currency") {
            $form->{"old$_"} = $form->{$_};
          }
          &select_name($form->{vc});
          exit;
        }
	
        if ($rv == 1) {
          # we got one name
          $form->{"$form->{vc}_id"} = $form->{name_list}[0]->{id};
          $form->{$form->{vc}} = $form->{name_list}[0]->{name};
          $form->{"$form->{vc}number"} = $form->{name_list}[0]->{"$form->{vc}number"};
          $form->{"old$form->{vc}"} = "";
          $form->{"old$form->{vc}number"} = "";
        } else {
          # nothing open
          $form->{"$form->{vc}"} = "";
          $form->{"$form->{vc}_id"} = 0;
          $form->{"$form->{vc}number"} = "";
        }

      }

      $form->{"select$form->{vc}"} = "";
      if (@{ $form->{"all_$form->{vc}"} }) {
        for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|$_->{name}--$_->{id}\n| }
      }
      $form->{"select$form->{vc}"} = $form->escape($form->{"select$form->{vc}"},1);
    }
  }

  # get customer/vendor
  &check_openvc;

  $form->{"$form->{ARAP}_paid"} = $arappaid;
  $form->{department} = $department;
  $form->{business} = $business;
  $form->{currency} = $currency;
  $form->{paymentmethod} = $paymentmethod;

  if ($form->{datepaid} ne $form->{olddatepaid}) {
    $form->{olddatepaid} = $form->{datepaid};
    $form->{redo} = 1;
    $form->{oldall_vc} = !$form->{oldall_vc} if $form->{all_vc};
  }

  for ("duedatefrom", "duedateto", "department", "business", "$form->{ARAP}", "currency", "paymentmethod") {
    if ($form->{$_} ne $form->{"old$_"}) {
      $form->{redo} = 1;
    }
    $form->{"old$_"} = $form->{$_};
  }

  if ($form->{redo}) {
    $form->remove_locks(\%myconfig, undef, $form->{arap}) unless $form->{locks_removed};
  }

  # if we switched to all_vc
  if ($form->{all_vc} ne $form->{oldall_vc}) {

    $form->{redo} = 1;
    
    $form->{"select$form->{vc}"} = "";
    $form->{selectbusiness} = "";
    $form->{selectpaymentmethod} = "";
    $business = "";
    $paymentmethod = "";

    if ($form->{all_vc}) {
      $form->{business} = "";
      $form->{oldbusiness} = "";
      $form->{paymentmethod} = "";
      $form->{oldpaymentmethod} = "";
      
      $form->all_vc(\%myconfig, $form->{vc}, $form->{ARAP}, undef, $form->{datepaid});
      
      if (@{ $form->{"all_$form->{vc}"} }) {
        for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|$_->{name}--$_->{id}\n| }
        $form->{"select$form->{vc}"} = $form->escape($form->{"select$form->{vc}"},1);
      }
      
    } else {
      if ($myconfig{vclimit} > 0) {
        $form->{$form->{vc}} = "";
        $form->{"$form->{vc}number"} = "";
      }
     
      $form->remove_locks(\%myconfig, undef, $form->{arap}) unless $form->{locks_removed};

      CP->get_openvc(\%myconfig, \%$form);

      if ($myconfig{vclimit} > 0) {
        $form->{"all_$form->{vc}"} = $form->{name_list};
      }

      if (@{ $form->{"all_$form->{vc}"} }) {
        $newvc = qq|$form->{"all_$form->{vc}"}[0]->{name}--$form->{"all_$form->{vc}"}[0]->{id}|;
        for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|$_->{name}--$_->{id}\n| }

        # if the name is not the same
        if ($form->{"select$form->{vc}"} !~ /$form->{$form->{vc}}/) {
          $form->{$form->{vc}} = $newvc;
          &check_openvc;
        }

        $form->{"select$form->{vc}"} = $form->escape($form->{"select$form->{vc}"},1);
      }

      foreach $item (qw(business paymentmethod)) {
        if (@{ $form->{"all_$item"} }) { 
          $form->{"select$item"} = "\n";
          $form->{$item} = qq|$form->{$item}--$form->{"${item}_id"}| if $form->{$item};

          for (@{ $form->{"all_$item"} }) { $form->{"select$item"} .= qq|$_->{description}--$_->{id}\n| }
        }
      }

    }

    if (@{ $form->{all_language} }) {
      $form->{selectlanguage} = "\n";
      for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
      $form->{selectlanguage} = $form->escape($form->{selectlanguage},1);
    }

  }

  if ($new_name_selected || $form->{redo}) {
    CP->get_openinvoices(\%myconfig, \%$form);

    ($newvc) = split /--/, $form->{$form->{vc}};
    $form->{"old$form->{vc}"} = qq|$newvc--$form->{"$form->{vc}_id"}|;
    $form->{redo} = 1;
  }

  $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{datepaid});

  if ($form->{redo}) {
    $form->{rowcount} = 0;
    $form->{allbox} = "" if $new_name_selected;
    $form->{amount} = 0;
    $form->{oldamount} = 0;

    $i = 0;
    foreach $ref (@{ $form->{PR} }) {
      $i++;

      for (qw(id invnumber invdescription transdate duedate calcdiscount discountterms cashdiscount netamount)) { $form->{"${_}_$i"} = $ref->{$_} }
      $ref->{exchangerate} ||= 1;
      $due = ($form->{edit}) ? $ref->{amount} : $ref->{amount} - $ref->{paid};

      $form->{"due_$i"} = $form->format_amount(\%myconfig, $due / $ref->{exchangerate}, $form->{precision});
      $form->{"amount_$i"} = $form->format_amount(\%myconfig, $ref->{amount} / $ref->{exchangerate}, $form->{precision});
      $form->{"netamount_$i"} = $form->format_amount(\%myconfig, $ref->{netamount} / $ref->{exchangerate}, $form->{precision});
      if ($new_name_selected) {
        for (qw(checked paid discount total)) { $form->{"${_}_$i"} = "" }
      }
    }
    $form->{rowcount} = $i;
    $form->{allbox_select} = "" if $i == 0;
  }

  $form->{amount} = $form->parse_amount(\%myconfig, $form->{amount});

  # recalculate
  $amount = 0;
  for $i (1 .. $form->{rowcount}) {

    for (qw(amount due paid discount)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }

    if ($form->{"checked_$i"}) {
      $ok = 1;
      # calculate discount
      if ($form->{"calcdiscount_$i"}) {
        if (! $form->{"olddiscount_$i"}) {
          $form->{"discount_$i"} = $form->parse_amount(\%myconfig, $form->{"netamount_$i"}) * $form->{"cashdiscount_$i"};
          $form->{"olddiscount_$i"} = $form->{"discount_$i"};
        }
      }

      # calculate paid_$i
      if (!$form->{"paid_$i"}) {
        $form->{"paid_$i"} = $form->{"due_$i"} - $form->{"discount_$i"};
      }
      
      $amount += $form->{"paid_$i"};
      $form->{redo} = 1;
    } else {
      for (qw(paid discount)) { $form->{"${_}_$i"} = "" }
    }

    for (qw(amount due paid discount)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $form->{precision}) }
  }

  $form->{amount} += ($amount - $form->{oldamount}) if $form->{redo};

  if (! $ok) {
    $form->{amount} = 0;
    $form->{source} = "";
  }

  $form->{"old$form->{ARAP}_paid"} = $form->{"$form->{ARAP}_paid"};

  &payment_header;
  &list_invoices;
  &payment_footer;
  
}




sub payment_header {

  if ($form->{type} eq 'receipt') {
    $form->{title} = $locale->text('Receipt');
  }
  if ($form->{type} eq 'check') {
    $form->{title} = $locale->text('Payment');
  }

  if ($form->{batch}) {
    $form->{title} .= " ".$locale->text('Voucher');
    if ($form->{batchdescription}) {
      $form->{title} .= " / $form->{batchdescription}";
    }
  }

# $locale->text('Customer')
# $locale->text('Customer Number')
# $locale->text('Vendor')
# $locale->text('Vendor Number')

  if ($form->{$form->{vc}} eq "") {
    for (qw(address1 address2 city zipcode state country)) { $form->{$_} = "" }
  }
  
  if ($form->{defaultcurrency}) {
    $exchangerate = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td><select name=currency onChange="javascript:document.main.submit()">|
		.$form->select_option($form->{selectcurrency}, $form->{currency})
		.qq|</select></td>
	      </tr>
|;
  }

  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

    $exchangerate .= qq|
 	      <tr>
		<th align=right nowrap>|.$locale->text('Exchange Rate').qq|</th>
		<td colspan=3><input name=exchangerate class="inputright" size=11 value=$form->{exchangerate}></td>
	      </tr>
|;
  }
  
  $allvc = ($form->{all_vc}) ? "checked" : "";
  $allvc = qq|
  	      <tr>
	        <td align=right>
		<input name=all_vc type=checkbox class=checkbox value=Y $allvc onChange="javascript:main.submit()">
		<input type=hidden name="oldall_vc" value="$form->{all_vc}"></td>
		<input type=hidden name="action" value="update">
		<th align=left>|.$locale->text('All').qq|</th>
	      </tr>
|;

 
  %vc = ( customer => { name => 'Customer', number => 'Customer Number' },
          vendor => { name => 'Vendor', number => 'Vendor Number' }
	);
  
  $vc = qq|
	      <tr>
		<th align=right>|.$locale->text($vc{$form->{vc}}{name}).qq|</th>
|;

  $duedate = qq|
	      <tr>
		<th align=right>|.$locale->text('Due Date').qq|</th>
		<td>
		  <table>
		    <tr>
		      <th align=right>|.$locale->text('From').qq|</th>
		      <td><input name=duedatefrom value="$form->{duedatefrom}" title="$myconfig{dateformat}" size=11 class=date>|.&js_calendar("main", "duedatefrom").qq|</td>
		      <th align=right>|.$locale->text('To').qq|</th>
		      <td><input name=duedateto value="$form->{duedateto}" title="$myconfig{dateformat}" size=11 class=date>|.&js_calendar("main", "duedateto").qq|</td>
		    </tr>
		  </table>
		</td>
	      </tr>
|;

  if ($form->{payments_detail}) {
    $allvc = "";

    $name = $form->{"$form->{vc}"};
    $name =~ s/--.*//;
    $vc .= qq|<td>|.$form->quote($name).qq|</td>
              </tr>
	      <tr>
	      <th align=right>|.$locale->text($vc{$form->{vc}}{number}).qq|</th>
	      <td>|.$form->quote($form->{"$form->{vc}number"}).qq|</td>
	      </tr>
|.$form->hide_form("payments_detail","$form->{vc}","$form->{vc}number");

    if ($form->{duedatefrom} || $form->{duedateto}) {
      $duedate = qq|
	      <tr>
		<th align=right>|.$locale->text('Due Date').qq|</th>
		<td>
		  <table>
		    <tr>
		      <th align=right>|.$locale->text('From').qq|</th>
		      <td>$form->{duedatefrom}|.&js_calendar("main", "duedatefrom").qq|</td>
		      <th align=right>|.$locale->text('To').qq|</th>
		      <td>$form->{duedateto}|.&js_calendar("main", "duedateto").qq|</td>
		    </tr>
		  </table>
		</td>
	      </tr>
|;
    } else {
      $duedate = "";
    }

    $duedate .= $form->hide_form(qw(duedatefrom duedateto));

  } else {
    if ($form->{"select$form->{vc}"}) {
      $vc .= qq|<td><select name="$form->{vc}" onChange="javascript:document.main.submit()">|.$form->select_option($form->{"select$form->{vc}"}, $form->{$form->{vc}}, 1).qq|</select></td>
      <input name=action type=hidden value=update>
		</tr>
  |;
    } else {
      $vc .= qq|<td><input name="$form->{vc}" size=35 value="|.$form->quote($form->{$form->{vc}}).qq|"></td>
		</tr>
		<tr>
		<th align=right>|.$locale->text($vc{$form->{vc}}{number}).qq|</th>
		<td><input name="$form->{vc}number" size=35 value="|.$form->quote($form->{"$form->{vc}number"}).qq|"></td>
		</tr>
  |;
    }
  }


# $locale->text('AR')
# $locale->text('AP')

  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td><select name=department onChange="javascript:document.main.submit()">|
		.$form->select_option($form->{selectdepartment}, $form->{department}, 1).qq|
		</select>
	      </td>
	    </tr>
| if $form->{selectdepartment};

  $business = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Type of Business').qq|</th>
		<td><select name=business onChange="javascript:document.main.submit()">|
		.$form->select_option($form->{selectbusiness}, $form->{business}, 1).qq|
		</select>
	      </td>
	    </tr>
| if $form->{selectbusiness};

  $paymentmethod = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Payment Method').qq|</th>
		<td><select name=paymentmethod onChange="javascript:document.main.submit()">|
		.$form->select_option($form->{selectpaymentmethod}, $form->{paymentmethod}, 1).qq|
		</select>
	      </td>
	    </tr>
| if $form->{selectpaymentmethod};

  $cashdiscount = qq|
 	      <tr>
		<th align=right nowrap>|.$locale->text('Cash Discount').qq|</th>
		<td colspan=3><select name="$form->{ARAP}_discount">|
		.$form->select_option($form->{"select$form->{ARAP}_discount"}, $form->{"$form->{ARAP}_discount"}).qq|</select>
		</td>
	      </tr>
| if $form->{"select$form->{ARAP}_discount"};


  if ($form->{batch}) {
    $datepaid = qq|
		<td>$form->{datepaid}</td>
		<input type=hidden name=datepaid value="$form->{datepaid}"></td>
|;
  } else {
    $datepaid = qq|
		<td><input name=datepaid value="$form->{datepaid}" title="$myconfig{dateformat}" size=11 class=date>|.&js_calendar("main", "datepaid").qq|</td>
|;
  }


  $form->header;

  &calendar;
  
  &check_all(qw(allbox checked_));
  
  print qq|
<script language="javascript">
<!--
javascript:window.history.forward(1);
// -->
</script>
  
<body>

<form method="post" name="main" action="$form->{script}">
|;

  for (split /%0a/, $form->{"select$form->{ARAP}_paid"}) {
    ($accno) = split /--/, $_;
    $form->hide_form("$form->{type}_$accno");
  }

  $form->hide_form(qw(defaultcurrency closedto vc type ARAP arap title formname payment batch batchid batchnumber batchdescription transdate edit voucherid vouchernumber employee precision));
  $form->hide_form("$form->{vc}_id");
  $form->hide_form(map { "old$_" } qw(currency datepaid duedatefrom duedateto department business paymentmethod));
  $form->hide_form(map { "old$_" } ("$form->{ARAP}", "$form->{ARAP}_paid", "$form->{vc}", "$form->{vc}number"));
  $form->hide_form(map { "select$_" } qw(currency department business paymentmethod printer));
  $form->hide_form(map { "select$_" } ("$form->{ARAP}", "$form->{ARAP}_paid", "$form->{ARAP}_discount", "$form->{vc}"));

  print qq|

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      $allvc

	      $duedate
	      
        $vc

	      <tr valign=top>
          <th align=right nowrap>|.$locale->text('Address').qq|</th>
          <td colspan=2>
		  <table>
		    <tr>
		      <td>$form->{address1}</td>
		    </tr>
		    <tr>
		      <td>$form->{address2}</td>
		    </tr>
		      <td>$form->{city}</td>
		    </tr>
		    </tr>
		      <td>$form->{state}</td>
		    </tr>
		    </tr>
		      <td>$form->{zipcode}</td>
		    </tr>
		    <tr>
		      <td>$form->{country}</td>
		    </tr>
		  </table>
		</td>
	      </tr>
	      <tr>
          <th align=right>|.$locale->text('Memo').qq|</th>
          <td colspan=2><input name="memo" size=30 value="|.$form->quote($form->{memo}).qq|"></td>
              </tr>
            </table>
          </td>
          <td align=right>
            <table>
              $department
              $business
              <tr>
                <th align=right nowrap>|.$locale->text($form->{ARAP}).qq|</th>
                <td colspan=3><select name=$form->{ARAP} onChange="javascript:document.main.submit()">|
                .$form->select_option($form->{"select$form->{ARAP}"}, $form->{"$form->{ARAP}"}).qq|</select>
                </td>
              </tr>
              <tr>
                <th align=right nowrap>|.$locale->text('Payment').qq|</th>
                <td colspan=3><select name="$form->{ARAP}_paid" onChange="javascript:document.main.submit()">|
                .$form->select_option($form->{"select$form->{ARAP}_paid"}, $form->{"$form->{ARAP}_paid"}).qq|</select>
                </td>
                $paymentmethod
              </tr>
              $cashdiscount
              <tr>
                <th align=right nowrap>|.$locale->text('Date').qq|</th>
                $datepaid
              </tr>
              $exchangerate
              <tr>
                <th align=right nowrap>|.$locale->text('Source').qq|</th>
                <td colspan=3><input name=source value="|.$form->quote($form->{source}).qq|" size=11></td>
              </tr>
              <tr>
                <th align=right nowrap>|.$locale->text('Amount').qq|</th>
                <td colspan=3><input name=amount class="inputright" size=11 value=|.$form->format_amount(\%myconfig, $form->{amount}, $form->{precision}).qq|></td>
                <input type=hidden name=oldamount value=|.$form->round_amount($form->{amount}, $form->{precision}).qq|>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
|;

  $form->hide_form(qw(address1 address2 city state zipcode country));

}


sub list_invoices {

  @column_index = qw(invnumber transdate duedate amount due checked paid discount total);
  
  $colspan = $#column_index + 1;

  $invoice = $locale->text('Invoices');
  
  print qq|
  <input type=hidden name=column_index value="id @column_index">
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th class=listheading colspan=$colspan>$invoice</th>
	</tr>
|;

  $column_data{invnumber} = qq|<th>|.$locale->text('Invoice')."</th>";
  $column_data{transdate} = qq|<th>|.$locale->text('Invoice Date')."</th>";
  $column_data{duedate} = qq|<th>|.$locale->text('Due Date')."</th>";
  $column_data{amount} = qq|<th>|.$locale->text('Amount')."</th>";
  $column_data{due} = qq|<th>|.$locale->text('Due')."</th>";
  $column_data{paid} = qq|<th>|.$locale->text('Paid')."</th>";
  $column_data{discount} = qq|<th>|.$locale->text('Discount')."</th>";
  $column_data{total} = qq|<th>|.$locale->text('Total')."</th>";

  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  
  $column_data{checked} = qq|<th><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); javascript:document.main.submit()" ><input type=hidden name=action value="update"></th>|;
  
  print qq|
        <tr>
|;
  for (@column_index) { print "$column_data{$_}\n" }
  print qq|
        </tr>
|;

  for $i (1 .. $form->{rowcount}) {

    for (qw(amount due paid discount)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }

    $form->{"olddiscount_$i"} = $form->{"discount_$i"};
    
    $totalamount += $form->{"amount_$i"};
    $totaldue += $form->{"due_$i"};
    $totalpaid += $form->{"paid_$i"};
    $totaldiscount += $form->{"discount_$i"};
    $form->{"total_$i"} = $form->{"paid_$i"} + $form->{"discount_$i"};
    $totaltotal += $form->{"total_$i"};

    for (qw(amount due paid discount total)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $form->{precision}) }

    $column_data{invnumber} = qq|<td width=30%>$form->{"invnumber_$i"}</td>|;
    $column_data{transdate} = qq|<td width=30% nowrap>$form->{"transdate_$i"}</td>|;
    $column_data{duedate} = qq|<td width=30% nowrap>$form->{"duedate_$i"}</td>|;
    $column_data{amount} = qq|<td align=right>$form->{"amount_$i"}</td>|;
    $column_data{due} = qq|<td align=right>$form->{"due_$i"}</td>|;
    $column_data{total} = qq|<td align=right>$form->{"total_$i"}</td>|;

    $form->hide_form(map { "${_}_$i" } qw(id invnumber invdescription transdate duedate due calcdiscount discountterms cashdiscount amount netamount olddiscount));
    
    $column_data{paid} = qq|<td align=center><input name="paid_$i" class="inputright" size=11 value=$form->{"paid_$i"}></td>|;
    
    if ($form->{"calcdiscount_$i"}) {
      $column_data{discount} = qq|<td align=center><input name="discount_$i" class="inputright" size=11 value=$form->{"discount_$i"}></td>|;
    } else {
      $column_data{discount} = qq|<td></td>|;
    }

    $form->{"checked_$i"} = ($form->{"checked_$i"}) ? "checked" : "";
    $column_data{checked} = qq|<td align=center><input name="checked_$i" type=checkbox class=checkbox $form->{"checked_$i"} onChange="javascript:document.main.submit()"></td>|;

    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>
|;
    for (@column_index) { print "$column_data{$_}\n" }
    print qq|
        </tr>
|;
  }

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{due} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totaldue, $form->{precision}, "&nbsp;").qq|</th>|;
  $column_data{paid} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totalpaid, $form->{precision}, "&nbsp;").qq|</th>|;
  $column_data{discount} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totaldiscount, $form->{precision}, "&nbsp;").qq|</th>|;
  $column_data{amount} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totalamount, $form->{precision}, "&nbsp;").qq|</th>|;
  $column_data{total} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totaltotal, $form->{precision}, "&nbsp;").qq|</th>|;

  print qq|
        <tr class=listtotal>
|;
  for (@column_index) { print "$column_data{$_}\n" }
  print qq|
        </tr>
      </table>
    </td>
  </tr>
|;

}


sub payment_footer {

  $form->{DF}{$form->{format}} = "selected";

  $transdate = $form->datetonum(\%myconfig, $form->{datepaid});

  if (!$form->{readonly}) {
    
    $media = qq|<select name=media>
	  <option value=screen>|.$locale->text('Screen');

    if ($form->{selectprinter}) {
      for (split /\n/, $form->unescape($form->{selectprinter})) { $media .= qq|
	    <option value="$_">$_| }
    }
    $media .= qq|</select>|;

    $format = qq|<select name=format>
    <option value="html" $form->{DF}{html}>|.$locale->text('html').qq|
    <option value="xml" $form->{DF}{xml}>|.$locale->text('XML').qq|
    <option value="txt" $form->{DF}{txt}>|.$locale->text('Text');
   
    if ($latex) {
      if ($form->{selectlanguage}) {
        $lang = qq|<select name=language_code>|.$form->select_option($form->{"selectlanguage"}, $form->{language_code}, undef, 1).qq|</select>|;
        $form->hide_form(qw(selectlanguage));
      }
      
      $format .= qq|
	      <option value=ps $form->{DF}{ps}>|.$locale->text('Postscript').qq|
	      <option value=pdf $form->{DF}{pdf}>|.$locale->text('PDF');
    }
    $format .= qq|</select>|;

    print qq|
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
|;

    $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;
    if ($transdate <= $form->{closedto}) {
      $media = $format = "";
    }

    print qq|
  <tr>
    <td>
    $lang
    $format
    $media
    </td>
  </tr>
</table>
<p>
|;

    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
	       'Select all' => { ndx => 2, key => 'A', value => $locale->text('Select all') },
	       'Deselect all' => { ndx => 3, key => 'A', value => $locale->text('Deselect all') },
               'Preview' => { ndx => 4, key => 'V', value => $locale->text('Preview') },
	       'Print' => { ndx => 5, key => 'P', value => $locale->text('Print') },
	       'Post' => { ndx => 6, key => 'O', value => $locale->text('Post') },
	       'Back' => { ndx => 7, key => 'B', value => $locale->text('Back') }
	      ); 

    if ($form->{allbox}) {
      delete $button{'Select all'};
    } else {
      delete $button{'Deselect all'};
    }

    if (! $latex) {
      for ('Print', 'Preview') { delete $button{$_} }
    }

    if ($transdate <= $form->{closedto}) {
      for ('Post', 'Print', 'Preview') { delete $button{$_} }
    }

    if (! $form->{payments_detail}) {
      delete $button{'Back'};
    }

    $form->print_button(\%button);
  }

  $form->hide_form(qw(helpref callback rowcount path login));
 
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



sub back {

  $form->{olddatepaid} = "";
  $form->{redo} = "";
  for $i (1 .. $form->{rowcount}) {
    for (qw(checked amount due paid totaldue id)) { $form->{"${_}_$i"} = "" }
  }
  $form->{payment} = "payments";
  $form->{rowcount} = 0;
  $form->{allbox} = 0;

  &update_payments;

}


sub post { &{"post_$form->{payment}"} }



sub post_payments {

  $msg = $locale->text('Posting Payment');
  
  %oldform = ();
  for (keys %$form) { $oldform{$_} = $form->{$_} };
  
  CP->invoice_ids(\%myconfig, \%$form);

  $i = 0;
  $j = 0;
  foreach $ref (@{ $form->{PR} }) {
    $i++;

    if ($ref->{"$form->{vc}_id"} ne $sameid) {
      $j++;
      $sameid = $ref->{"$form->{vc}_id"};
      $paid = $form->parse_amount(\%myconfig, $oldform{"paid_$j"});
    }

    for (qw(checked source memo)) { $form->{"${_}_$i"} = $oldform{"${_}_$j"} }
    for (qw(id invnumber transdate duedate)) { $form->{"${_}_$i"} = $ref->{$_} }

    $form->{"$form->{vc}_id_$i"} = $ref->{"$form->{vc}_id"};
    $form->{"$form->{vc}number_$i"} = $ref->{"$form->{vc}number"};
    $form->{"name_$i"} = $ref->{name};
    $ref->{exchangerate} ||= 1;

 
    # check if we can apply a discount
    if (!$ref->{discount}) {
      if ($ref->{calcdiscount}) {
	$netamount = $form->round_amount($ref->{netamount} / $ref->{exchangerate}, $form->{precision});
	$form->{"discount_$i"} = $form->round_amount($netamount * $ref->{cashdiscount}, $form->{precision});
      }
    }

    $due = $form->round_amount(($ref->{amount} - $ref->{paid}) / $ref->{exchangerate}, $form->{precision});

    $form->{"paid_$i"} = ($paid > $due) ? $due : $paid;
  
    $paid = $form->round_amount($paid - $form->{"paid_$i"}, $form->{precision});

    $form->{"paid_$i"} = $form->format_amount(\%myconfig, $form->{"paid_$i"} - $form->{"discount_$i"}, $form->{precision});
    $form->{"discount_$i"} = $form->format_amount(\%myconfig, $form->{"discount_$i"}, $form->{precision});

  }

  $rowcount = $i;

  delete $form->{PR};
  
  $ok = 0;
  $j = 0;
  $k = 1;
 
  $form->{"$form->{vc}_id"} = $form->{"$form->{vc}_id_1"};
 
  for $i (1 .. $rowcount) {

    $j++;

    $form->{amount} = $oldform{"paid_$k"};
    $form->{rowcount} = $j;

    for (qw(source memo)) { $form->{$_} = $form->{"${_}_$i"} }

    for (qw(id invnumber checked paid)) { $form->{"${_}_$j"} = $form->{"${_}_$i"} }

    $form->{"$form->{vc}number"} = $form->{"$form->{vc}number_$i"};
    $form->{name} = $form->{"name_$i"};

    $n = $i + 1;
    next if $form->{"$form->{vc}_id_$n"} eq $form->{"$form->{vc}_id_$i"};

    if ($form->{"checked_$i"}) {
      if ($form->{batch}) {
        $batchid = $form->{batchid};
        VR->post_transaction(\%myconfig, \%$form);
      } else {
        CP->post_payment(\%myconfig, \%$form);
      }
      $oldform{header} = 1;

      $form->info(qq|$msg $form->{amount}, $form->{name} $form->{"$form->{vc}number"}\n|);
    }

    $k++;
    $j = 0;
   
  }


  for (keys %$form) { $form->{$_} = "" }
  for (keys %oldform) { $form->{$_} = $oldform{$_} }

  $form->{callback} .= "&header=$oldform{header}" if $form->{callback};

  $form->remove_locks(\%myconfig, undef, $form->{arap});
  
  $form->redirect;

}



sub post_payment {

  &check_form;
  
  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->error($locale->text('Exchange rate missing!')) unless $form->{exchangerate};
  }

  $msg1 = $locale->text('Payment posted!');
  $msg2 = $locale->text('Posting failed!');

  $form->{amount} = $form->format_amount(\%myconfig, $form->{amount}, $form->{precision});

  $source = $form->{source};
  $source =~ s/(\d+)/$1 + 1/e;
  
  if ($form->{callback}) {
    $form->{callback} .= "&source=$source";
  }

  if ($form->{batch}) {
    $batchid = $form->{batchid};
    if ($rc = VR->post_transaction(\%myconfig, \%$form)) {
      if ($form->{callback}) {
	$form->{callback} .= "&batch=$form->{batch}&batchdescription=".$form->escape($form->{batchdescription},1);
	if (!$batchid) {
	  $form->{callback} .= "&batchid=$form->{batchid}&type=$form->{type}";
	}
      }
      $form->redirect($locale->text($msg1));
    }
  } else {
    if ($rc = CP->post_payment(\%myconfig, \%$form)) {
      $form->redirect($locale->text($msg1));
    }
  }

  $form->error($locale->text($msg2)) if ! $rc;

}


sub print {
  
  &{ "print_$form->{payment}" };
  &update if $form->{media} ne 'screen';
  
}



sub print_payments {

  $form->error($locale->text('Select postscript or PDF!')) if ($form->{format} !~ /(ps|pdf)/);
  
  %oldform = ();
  for (keys %$form) { $oldform{$_} = $form->{$_} };
  
  CP->invoice_ids(\%myconfig, \%$form);
  
  $i = 0;
  $j = 0;
  foreach $ref (@{ $form->{PR} }) {
    $i++;

    if ($ref->{"$form->{vc}_id"} ne $sameid) {
      $j++;
      $sameid = $ref->{"$form->{vc}_id"};
      $paid = $form->parse_amount(\%myconfig, $oldform{"paid_$j"});
    }

    for (qw(checked source memo language_code)) { $form->{"${_}_$i"} = $oldform{"${_}_$j"} }

    for (qw(id invnumber invdescription transdate duedate)) { $form->{"${_}_$i"} = $ref->{$_} }
    $form->{"$form->{vc}_id_$i"} = $ref->{"$form->{vc}_id"};
    
    $ref->{exchangerate} ||= 1;
    $due = $form->round_amount(($ref->{amount} - $ref->{paid}) / $ref->{exchangerate}, $form->{precision});

    $form->{"due_$i"} = $due;
    $form->{"amount_$i"} = $form->round_amount($ref->{amount} / $ref->{exchangerate}, $form->{precision});

    $form->{"paid_$i"} = ($paid > $due) ? $due : $paid;
    
    $paid -= $due;
    $paid = 0 if $paid < 0;
    
  }

  $temp{rowcount} = $i;

  delete $form->{PR};

  for $i (1 .. $temp{rowcount}) {
    for (qw(due amount paid)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $form->{precision}) }
  }
  
  $ok = 0;
  $j = 0;
  $k = 0;
  
  $SIG{INT} = 'IGNORE';

  $msg = ($form->{vc} eq 'vendor') ? $locale->text('Printing check for') : $locale->text('Printing receipt for');
  
  $form->{"$form->{vc}_id"} = "";

  for $i (1 .. $temp{rowcount}) {

    if ($form->{"$form->{vc}_id_$i"} ne $form->{"$form->{vc}_id"}) {
      $k++;

      $form->{rowcount} = $j;
      for (1 .. $j) { $form->{"id_$_"} = $temp{"id_$_"} }

      if ($ok) {
        &print_form;
        $oldform{header} = 1;
        $form->info(qq|$msg $form->{name} $form->{"$form->{vc}number"}\n|);
      }

      $ok = 0;
      $j = 0;
      $form->{amount} = 0;
      for (qw(invnumber invdescription invdate due paid)) { @{ $form->{$_} } = () }
      for (qw(language_code source memo)) { $form->{$_} = $form->{"${_}_$i"} }

    }

    if ($form->{"checked_$i"}) {
      $j++;
      $ok = 1;
      $temp{"id_$j"} = $form->{"id_$i"};
      $form->{"invdate_$i"} = $form->{"transdate_$i"};
      for (qw(invnumber invdescription invdate due paid)) { push @{ $form->{$_} }, $form->{"${_}_$i"} }
      $form->{amount} = $form->parse_amount(\%myconfig, $oldform{"paid_$k"});
    }

    $form->{"$form->{vc}_id"} = $form->{"$form->{vc}_id_$i"};
    
  }

  $form->{rowcount} = $j;
  for (1 .. $j) { $form->{"id_$_"} = $temp{"id_$_"} }
  
  if ($ok) {
    &print_form;
    $oldform{header} = 1;
    $form->info(qq|$msg $form->{name} $form->{"$form->{vc}number"}\n|);
  }

  for (keys %$form) { $form->{$_} = "" }
  for (keys %oldform) { $form->{$_} = $oldform{$_} }

}


sub print_form {
       
  $c = CP->new(($form->{language_code}) ? $form->{language_code} : $myconfig{countrycode});
  $c->init;

  ($whole, $form->{decimal}) = split /\./, $form->{amount};
  $form->{amount} = $form->format_amount(\%myconfig, $form->{amount}, $form->{precision});
  $form->{decimal} .= "00";
  $form->{decimal} = substr($form->{decimal}, 0, 2);
  $form->{text_decimal} = $c->num2text($form->{decimal} * 1);
  $form->{text_amount} = $c->num2text($whole);
  $form->{integer_amount} = $whole;

  $datepaid = $form->datetonum(\%myconfig, $form->{datepaid});
  ($form->{yyyy}, $form->{mm}, $form->{dd}) = $datepaid =~ /(....)(..)(..)/;
  
  AA->company_details(\%myconfig, \%$form);

  $form->format_string(qw(company address companyemail companywebsite));

  $form->{templates} = "$templates/$myconfig{dbname}";
  $form->{IN} = "$form->{formname}.tex";

  if ($form->{media} ne 'screen') {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;
  }

  $form->parse_template(\%myconfig, $userspath, $dvipdf, $xelatex);

}


sub print_payment {
 
  &check_form;
  
  @a = qw(name text_amount text_decimal address1 address2 city state zipcode country memo);

  %temp = ();
  for (@a) { $temp{$_} = $form->{$_} }

  $form->format_string(@a);

  &print_form;
 
  for (keys %temp) { $form->{$_} = $temp{$_} }

}



sub check_form {
  
  &check_openvc;

  if ($form->{currency} ne $form->{oldcurrency}) {
    &update;
    exit;
  }
  
  $form->error($locale->text('Date missing!')) unless $form->{datepaid};

  $datepaid = $form->datetonum(\%myconfig, $form->{datepaid});
  
  $form->error($locale->text('Cannot post payment for a closed period!')) if ($datepaid <= $form->{closedto});

  # this is just to format the year
  $form->{datepaid} = $locale->date(\%myconfig, $form->{datepaid});
  
  $amount = $form->parse_amount(\%myconfig, $form->{amount});
  $form->{amount} = $amount;
  
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"paid_$i"}) {
      $amount -= $form->parse_amount(\%myconfig, $form->{"paid_$i"});
      
      push(@{ $form->{paid} }, $form->{"paid_$i"});
      push(@{ $form->{discount} }, $form->{"discount_$i"});
      push(@{ $form->{due} }, $form->{"due_$i"});
      push(@{ $form->{invnumber} }, $form->{"invnumber_$i"});
      push(@{ $form->{invdescription} }, $form->{"invdescription_$i"});
      push(@{ $form->{invdate} }, $form->{"transdate_$i"});
    }
  }

  if ($form->round_amount($amount, $form->{precision}) != 0) {
    push(@{ $form->{paid} }, $form->format_amount(\%myconfig, $amount, $form->{precision}));
    push(@{ $form->{due} }, $form->format_amount(\%myconfig, 0, $form->{precision}));
    push(@{ $form->{discount} }, $form->format_amount(\%myconfig, 0, $form->{precision}));
    push(@{ $form->{invnumber} }, ($form->{ARAP} eq 'AR') ? $locale->text('Deposit') : $locale->text('Prepayment'));
    push(@{ $form->{invdate} }, $form->{datepaid});
  }
   
}


sub check_openvc {

  ($new_name, $new_id) = split /--/, $form->{$form->{vc}};
  $new_id ||= $form->{"$form->{vc}_id"};

  if ($form->{all_vc}) {
    if ($form->{"select$form->{vc}"}) {
      $redo = ($form->{"old$form->{vc}"} ne $form->{$form->{vc}});
    } else {
      $redo = ($form->{"old$form->{vc}"} ne qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|);
      $redo = ($form->{"old$form->{vc}number"} ne qq|$form->{"$form->{vc}number"}|) if ! $redo;
    }

    if ($redo) {
      $form->remove_locks(\%myconfig, undef, $form->{arap});
      $form->{redo} = 1;
      $form->{locks_removed} = 1;

      if ($form->{"select$form->{vc}"}) {
        $form->{"$form->{vc}_id"} = $new_id;
        AA->get_name(\%myconfig, \%$form);
        $form->{$form->{vc}} = $form->{"old$form->{vc}"} = "$new_name--$new_id";
      } else {
        &check_name($form->{vc});
      }
    }
    
  } else {
    
    # if we use a selection
    if ($form->{"select$form->{vc}"}) {

      if ($form->{"old$form->{vc}"} ne $form->{$form->{vc}}) {

        for (qw(address1 address2 city state zipcode country)) { $form->{$_} = "" }

        $form->remove_locks(\%myconfig, undef, $form->{arap});
        $form->{locks_removed} = 1;
          
        $form->{"$form->{vc}_id"} = $new_id;
        AA->get_name(\%myconfig, \%$form);

        if ($form->{"$form->{vc}_id"}) {
          $form->{$form->{vc}} = $form->{"old$form->{vc}"} = "$new_name--$new_id";
        } else {
          $form->{$form->{vc}} = $form->{"old$form->{vc}"} = "";
        }

        $form->{redo} = 1;
      }
    } else {

      # check name, combine name and id
      if ($form->{"old$form->{vc}"} ne qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|) {
        if ($form->{"$form->{vc}number"} eq $form->{"old$form->{vc}number"}) {
          $form->{"$form->{vc}number"} = $form->{"old$form->{vc}number"} = "";
        }
        $redo = 1;
      }
      
      if ($form->{"old$form->{vc}number"} ne $form->{"$form->{vc}number"}) {
        $form->{$form->{vc}} = "";
        $redo = 1;
      }
	
      if ($redo) {

        $form->remove_locks(\%myconfig, undef, $form->{arap});
        $form->{locks_removed} = 1;

        # return one name or a list of names in $form->{name_list}
        if (($rv = CP->get_openvc(\%myconfig, \%$form)) > 1) {
          $form->{redo} = 1;
          &select_name($form->{vc});
          exit;
        }

        if ($rv == 1) {
          # we got one name
          $form->{"$form->{vc}_id"} = $form->{name_list}[0]->{id};
          $form->{$form->{vc}} = $form->{name_list}[0]->{name};
          $form->{"old$form->{vc}"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
          $form->{"old$form->{vc}number"} = $form->{name_list}[0]->{"$form->{vc}number"};

          AA->get_name(\%myconfig, \%$form);

        } else {
          # nothing open
          $form->{$form->{vc}} = "";
          $form->{"$form->{vc}number"} = "";
          $form->{"$form->{vc}_id"} = 0;
        }
        
        $form->{redo} = 1;
      }
    }
  }

  if ($form->{redo}) {
    $form->{$form->{ARAP}} = $form->{"old$form->{ARAP}"};
    $form->{"$form->{ARAP}_paid"} = $form->{"old$form->{ARAP}_paid"};
    $form->{paymentmethod} = $form->{oldpaymentmethod};
    $form->{"$form->{ARAP}_discount"} = $form->{"old$form->{ARAP}_discount"};
  }

}


sub payment_register {

  $form->{vc} = ($form->{ARAP} eq 'AP') ? 'vendor' : 'customer';

  $form->create_links($form->{ARAP}, \%myconfig, $form->{vc});

  CP->paymentaccounts(\%myconfig, \%$form);
  
  $form->{"selectaccno"} = "\n" unless $form->{reissue};
  for (@{ $form->{PR}{"$form->{ARAP}_paid"} }) { $form->{"selectaccno"} .= "$_->{accno}--$_->{description}\n" }
  
  $vclabel = $locale->text('Customer');
  $vcnumber = $locale->text('Customer Number');
  
  if ($form->{vc} eq 'vendor') {
    $vclabel = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
  }

  if (@{ $form->{"all_$form->{vc}"} }) {
    $form->{"select$form->{vc}"} = "\n";
    for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|$_->{name}--$_->{id}\n| }
    $vc = qq|
              <tr>
	        <th align=right nowrap>$vclabel</th>
	        <td colspan=3><select name="$form->{vc}">|
		.$form->select_option($form->{"select$form->{vc}"}, undef, 1)
		.qq|</select>
	        </td>
	      </tr>
|;
  } else {
    $vc = qq|
              <tr>
	        <th align=right nowrap>$vclabel</th>
	        <td colspan=3><input name=$form->{vc} size=35>
		</td>
	      </tr>
	      <tr>
	        <th align=right nowrap>$vcnumber</th>
		<td colspan=3><input name="$form->{vc}number" size=35>
		</td>
	      </tr>
|;
  }

  if ($form->{ARAP} eq 'AR') {
    $rglabel = $locale->text('Void Receipt') if $form->{void};
    $rglabel = $locale->text('Reissue Receipt') if $form->{reissue};
    $form->{title} = $locale->text('Deposit Register')." / ".$rglabel;
    $form->helpref("deposits", $myconfig{countrycode});
  } else {
    $rglabel = $locale->text('Void Check') if $form->{void};
    $rglabel = $locale->text('Reissue Check') if $form->{reissue};
    $form->{title} = $locale->text('Payment Register')." / ".$rglabel;
    $form->helpref("checks", $myconfig{countrycode});
  }
  
  $checknumber = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Source').qq|</th>
          <td>
            <table>
              <tr>
                <th>|.$locale->text('From').qq|</th>
	        <td><input name=checknumberfrom size=10></td>
	        <th>|.$locale->text('To').qq|</th>
                <td><input name=checknumberto size=10></td>
              </tr>
            </table>
          </td>
	</tr>
|;


  if (@{ $form->{all_years} }) {
    # accounting years
    $selectaccountingyear = "\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|$_\n| }
    $selectaccountingmonth = "\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|$_--|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $form->{interval} = "1" unless exists $form->{interval};
    $checked{$form->{interval}} = "checked";

    $selectfrom = qq|
      <tr>
	<th align=right>|.$locale->text('Period').qq|</th>
	<td>
	<select name=month>|.$form->select_option($selectaccountingmonth, undef, 1, 1).qq|</select>
	<select name=year>|.$form->select_option($selectaccountingyear, undef, 1).qq|</select>
	<input name=interval class=radio type=radio value=0 $checked{0}>&nbsp;|.$locale->text('Current').qq|
	<input name=interval class=radio type=radio value=1 $checked{1}>&nbsp;|.$locale->text('Month').qq|
	<input name=interval class=radio type=radio value=3 $checked{3}>&nbsp;|.$locale->text('Quarter').qq|
	<input name=interval class=radio type=radio value=12 $checked{12}>&nbsp;|.$locale->text('Year').qq|
	</td>
      </tr>
|;
  }

  if ($form->{ARAP} eq 'AR') {
    @options = ( { option => all, description => $locale->text('All')},
                 { option => void, description => $locale->text('Void Receipt') },
                 { option => exclude, description => $locale->text('Exclude Void Receipts') },
                 { option => printed, description => $locale->text('Printed Receipts') },
                 { option => notprinted, description => $locale->text('Unprinted Receipts') }
               );
  } else {
    @options = ( { option => all, description => $locale->text('All')},
                 { option => void, description => $locale->text('Void Checks') },
                 { option => exclude, description => $locale->text('Exclude Void Checks') },
                 { option => printed, description => $locale->text('Printed Checks') },
                 { option => notprinted, description => $locale->text('Unprinted Checks') }
               );
  }

  for (@options) { $selectoption .= "$_->{description}--$_->{option}\n" }

  $display = qq|
              <tr>
	        <th align=right nowrap>|.$locale->text('Display').qq|</th>
	        <td><select name=option>|
		.$form->select_option($selectoption, undef, 1)
		.qq|</select>
	        </td>
	      </tr>
|;

  $form->header;

  &calendar;
  
  print qq|
<body>

<form method=post name=main action=$form->{script}>

<table width=100%>
  <tr><th class=listtop>$form->{helpref}$form->{title}</a></th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Account').qq|</th>
		<td colspan=3><select name=accno>|
		.$form->select_option($form->{"selectaccno"})
		.qq|</select></td>
	      </tr>
	      $vc
	      $checknumber
	      <tr>
		<th align=right nowrap>|.$locale->text('Date Issued').qq|</th>
                <td>
                  <table>
                    <tr>
                      <th>|.$locale->text('From').qq|</th>
		      <td><input name=datepaidfrom size=11 class=date title="$myconfig{dateformat}" value="$form->{datepaidfrom}" />|.&js_calendar("main", "datepaidfrom").qq|</td>
                      <th>|.$locale->text('To').qq|</th>
                      <td><input name=datepaidto size=11 class=date title="$myconfig{dateformat}" value="$form->{datepaidto}" />|.&js_calendar("main", "datepaidto").qq|</td>
                    </tr>
                  </table>
                </td>
	      </tr>
	      $selectfrom
              $display
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
<input type=hidden name=action value=continue>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->{sort} = "datepaid";
  $form->{nextsub} = "list_checks";

  $form->hide_form(qw(title sort helpref));
  $form->hide_form(qw(ARAP void reissue nextsub path login));
  
  print qq|
</form>
 
</body>
</html>
|;

}


sub list_checks {

  $form->{vc} = ($form->{ARAP} eq 'AP') ? 'vendor' : 'customer';

  (undef, $form->{"$form->{vc}_id"}) = split /--/, $form->{$form->{vc}};

  $form->sort_order();

  CP->payment_register(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_checks";
  for (qw(ARAP void reissue direction oldsort path login)) { $href .= qq|&$_=$form->{$_}| }
  $href .= "&title=".$form->escape($form->{title});
  $href .= "&helpref=".$form->escape($form->{helpref});

  $form->sort_order();

  $callback = "$form->{script}?action=list_checks";
  for (qw(ARAP void reissue direction oldsort path login)) { $callback .= qq|&$_=$form->{$_}| }
  $callback .= "&title=".$form->escape($form->{title},1);
  $callback .= "&helpref=".$form->escape($form->{helpref},1);

  if ($form->{accno}) {
    $callback .= "&accno=".$form->escape($form->{accno},1);
    $href .= "&accno=".$form->escape($form->{accno});
    $option = $locale->text('Account')." : $form->{accno}";
  }
  if ($form->{$form->{vc}}) {
    $callback .= "&$form->{vc}=".$form->escape($form->{$form->{vc}},1);
    $href .= "&$form->{vc}=".$form->escape($form->{$form->{vc}});
    $option .= "\n<br>" if ($option);
    $name = ($form->{vc} eq 'customer') ? $locale->text('Customer') : $locale->text('Vendor');
    ($vc) = split /--/, $form->{$form->{vc}};
    $option .= "$name : $vc";
  }
  if ($form->{"$form->{vc}number"}) {
    $callback .= "&$form->{vc}number=".$form->escape($form->{"$form->{vc}number"},1);
    $href .= "&$form->{vc}number=".$form->escape($form->{"$form->{vc}number"});
    $option .= "\n<br>" if ($option);
    $name = ($form->{vc} eq 'customer') ? $locale->text('Customer Number') : $locale->text('Vendor Number');
    $option .= qq|$name : $form->{"$form->{vc}number"}|;
  }
  if ($form->{checknumberfrom} || $form->{checknumberto}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Check Number')." : ";
  }
  if ($form->{checknumberfrom}) {
    $callback .= "&checknumberfrom=".$form->escape($form->{checknumberfrom},1);
    $href .= "&checknumberfrom=".$form->escape($form->{checknumberfrom});
    $option .= $form->{checknumberfrom};
  }
  if ($form->{checknumberto}) {
    $callback .= "&checknumberto=".$form->escape($form->{checknumberto},1);
    $href .= "&checknumberto=".$form->escape($form->{checknumberto});
    $option .= " - $form->{checknumberto}";
  }
  if ($form->{datepaidfrom} || $form->{datepaidto}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Date Issued')." : ";
  }
  if ($form->{datepaidfrom}) {
    $callback .= "&datepaidfrom=$form->{datepaidfrom}";
    $href .= "&datepaidfrom=$form->{datepaidfrom}";
    $option .= $locale->date(\%myconfig, $form->{datepaidfrom}, 1);
  }
  if ($form->{datepaidto}) {
    $callback .= "&datepaidto=$form->{datepaidto}";
    $href .= "&datepaidto=$form->{datepaidto}";
    $option .= " - ".$locale->date(\%myconfig, $form->{datepaidto}, 1);
  }
  if ($form->{option}) {
    $callback .= "&option=$form->{option}";
    $href .= "&option=$form->{option}";
    $option .= "\n<br>" if ($option);
    ($opt) = split /--/, $form->{option};
    $option .= $opt;
  }

  $name = ucfirst $form->{vc};

  @column_index = $form->sort_columns(qw(datepaid source amount name));
  unshift @column_index, qw(runningnumber id);

  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $action = ($form->{deselect}) ? "deselect_all" : "select_all";
  if ($form->{option} =~ /--void/) {
    $column_data{id} = qq|<th>&nbsp;</th>|;
  } else {
    $column_data{id} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); javascript:document.main.submit()"></th>
    <input type=hidden name=action value=$action>|;
  }
  $column_data{runningnumber} = qq|<th class=listheading>&nbsp;</th>|;
  $column_data{datepaid} = "<th><a class=listheading href=$href&sort=datepaid>".$locale->text('Date Paid')."</a></th>";
  $column_data{name} = "<th><a class=listheading href=$href&sort=name>$name</a></th>";
  $column_data{amount} = "<th class=listheading>" . $locale->text('Amount') . "</th>";
  $column_data{source} = "<th><a class=listheading href=$href&sort=source>" . $locale->text('Source') . "</a></th>";

  $form->{title} = ($form->{title}) ? $form->{title} : $locale->text('Check Register');

  $form->header;

  &check_all(qw(allbox id_));

  print qq|
<body>

<form method=post name=main action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
    <td>$option</td>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
	</tr>
|;


  # add sort and escape callback, this one we use for the add sub
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);
  
  $colspan = $#column_index + 1;

  $void = "(".$locale->text('void').")";

  $arap = ($form->{ARAP} eq 'AP') ? 'ap' : 'ar';
  $title = $form->escape($locale->text('Payments'),1);

  $reportflds = "";
  for (qw(l_transdate l_reference l_name l_description l_paid l_source l_memo)) { $reportflds .= '&'."$_=Y" }

  for $accno (sort keys %{ $form->{CHK} }) {
    $r = 0;

    print "<th colspan=$colspan align=left>$form->{$accno}</th>\n";

    for $ref (@{ $form->{CHK}{$accno} }) {

      $i++;
      $r++;
      
      $column_data{runningnumber} = "<td align=right>$r</td>";

      $form->{"id_$i"} = "checked" if $form->{"id_$i"};
      if ($ref->{source} && $ref->{amount}) {
        $column_data{id} = qq|<td><input name="id_$i" type=checkbox class=checkbox value="$ref->{trans_id}" $form->{"id_$i"}></td>|;
      } else {
        $column_data{id} = qq|<td>&nbsp;</td>|;
      }

      $column_data{amount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}, "&nbsp;")."</td>";

      $column_data{datepaid} = "<td nowrap>$ref->{datepaid}&nbsp;</td>";
      
      $form->{"accno_$i"} = $accno;
      $form->{"source_$i"} = $ref->{source};
      $vd = ($ref->{void}) ? $void : "";
      $column_data{source} = "<td>$ref->{source}&nbsp;$vd</td>";

      $source = '"'.$form->escape($ref->{source},1).'"';
      $account = $form->escape($form->{$accno},1);
      $name = $form->escape($ref->{name},1);
      $column_data{source} = "<td><a href=rp.pl?action=list_payments&account=$account&source=$source&db=$arap&vc=$form->{vc}&$form->{vc}=$name$reportflds&path=$form->{path}&login=$form->{login}&title=$title target=_new>$ref->{source}&nbsp;$vd</a></td>";

      $column_data{source} .= $form->hide_form("source_$i", "accno_$i");
     
      $column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{"$form->{vc}_id"}&db=$form->{vc}&callback=$callback>$ref->{name}</a></td>|;
     
      $j++; $j %= 2;

      print "
          <tr class=listrow$j>
  ";

      for (@column_index) { print "\n$column_data{$_}" }

      print qq|
          </tr>
|;
    }
  }

  $form->{rowcount} = $i;

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

  if ($myconfig{acs} !~ /Cash--/) {
    $button{'Select all'} = { ndx => 1, key => 'S', value => $locale->text('Select all') };
    $button{'Deselect all'} = { ndx => 1, key => 'D', value => $locale->text('Deselect all') };
    if ($form->{ARAP} eq 'AR') {
      $button{'Void Receipts'} = { ndx => 2, key => 'V', value => $locale->text('Void Receipts') };
      $button{'Reissue Receipts'} = { ndx => 3, key => 'R', value => $locale->text('Reissue Receipts') };
    } else {
      $button{'Void Checks'} = { ndx => 2, key => 'V', value => $locale->text('Void Checks') };
      $button{'Reissue Checks'} = { ndx => 3, key => 'R', value => $locale->text('Reissue Payments') };
    }
  }

  if ($form->{deselect}) {
    delete $button{'Select all'};
  } else {
    delete $button{'Deselect all'};
  }

  %button = () if $form->{option} =~ /--void/;

  if ($form->{void}) {
    delete $button{'Reissue Checks'};
    delete $button{'Reissue Receipts'};
  } else {
    delete $button{'Void Checks'};
    delete $button{'Void Receipts'};
  }

  $form->{helpref} = $form->escape($form->{helpref},1);

  $form->hide_form("$form->{vc}", "$form->{vc}_id");
  $form->hide_form(qw(ARAP void reissue rowcount helpref callback path login));
  
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


sub void_receipts { &void_checks }

sub void_checks {

  $form->{title} = $locale->text('Confirm!');

  $source = "";
  for (1 .. $form->{rowcount}) {
    if ($form->{"id_$_"}) {
      $source .= ($source) ? qq|, $form->{"source_$_"}| : $form->{"source_$_"};
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $source;

  if ($form->{ARAP} eq 'AR') {
    $msgaction = $locale->text('Yes, Void Receipts');
    $msgwarn = $locale->text('Are you sure you want to void receipts');
  } else {
    $msgaction = $locale->text('Yes, Void Checks');
    $msgwarn = $locale->text('Are you sure you want to void checks');
  }

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->{action} = "yes__void_payments";
  $form->hide_form;

  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>$msgwarn $source</h4>

<input name=action class=submit type=submit value="$msgaction">
</form>

</body>
</html>
|;

}


sub yes__void_checks { &yes__void_payments }
sub yes__void_receipts { &yes__void_payments }

sub yes__void_payments {

  if (CP->void_payments(\%myconfig, \%$form)) {
    $form->redirect;
  }

  $form->error($locale->text('Could not void payments!'));

}


sub reissue_receipts { &reissue_payments }

sub reissue_payments {

  $ok = 0;
  for (1 .. $form->{rowcount}) { last if $ok = $form->{"id_$_"} }

  $form->error($locale->text('Nothing selected!')) unless $ok;

  CP->create_selects(\%myconfig, \%$form);

  if ($form->{ARAP} eq 'AR') {
    $form->{type} = "receipt";
    $form->{formname} = "receipt";
    $form->{selectformname} = "receipt--".$locale->text('Receipt');
    $form->{title} = $locale->text('Reissue Receipts');
    $msgchk = $locale->text('Reissue Receipts');
    $chknumber = $locale->text('Receipt Number');
  } else {
    $form->{type} = "check";
    $form->{formname} = "check";
    $form->{selectformname} = "check--".$locale->text('Check');
    $form->{title} = $locale->text('Reissue Checks');
    $msgchk = $locale->text('Reissue Checks');
    $chknumber = $locale->text('Check Number');
  }
  $form->{format} ||= $myconfig{outputformat};

  $form->{selectprinter} = "";
  for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" }
  chomp $form->{selectprinter};
  delete $form->{all_printer};

  if ($myconfig{printer}) {
    $form->{format} ||= "postscript";
  } else {
    $form->{format} ||= "pdf";
  }
  $form->{media} ||= $myconfig{printer};

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }
  delete $form->{all_language};


  $source = "";
  for (1 .. $form->{rowcount}) {
    if ($form->{"id_$_"}) {
      $source .= ($source) ? qq|, $form->{"source_$_"}| : $form->{"source_$_"};
    }
  }

  $form->header;

  print qq|
<body>

<form method=post name=main action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
          <th>$msgchk</th><td>$source</td>
        </tr>
        <tr>
          <th>$chknumber</th>
          <td><input name="source" value="$form->{source}"></td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
|;

  require "$form->{path}/arapprn.pl";
  $form->{nohold} = 1;
  &print_options;

  if ($form->{ARAP} eq 'AR') {
    $action = $locale->text('Yes, Reissue Receipts');
    $form->{action} = "yes__reissue_receipts";
  } else {
    $action = $locale->text('Yes, Reissue Checks');
    $form->{action} = "yes__reissue_checks";
  }

  for (qw(action admin format formname media selectformname selectlanguage selectprinter)) { delete $form->{$_} }
  $form->hide_form;

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input name=action class=submit type=submit value="$action">
</form>

</body>
</html>
|;

}


sub yes__reissue_receipts { &yes__reissue_checks }

sub yes__reissue_checks {

  for (1 .. $form->{rowcount}) {
    if ($form->{"id_$_"}) {
      if (CP->reissue_payment(\%myconfig, \%$form, $_)) {
        if (exists $form->{longformat}) {
          $form->{datepaid} = $locale->date(\%myconfig, $form->{datepaid}, $form->{longformat});
        }
        &print_form;
        $form->{source}++;
$form->{file}++;
      } else {
        $form->error($locale->text('Error processing payment!'));
      }
    }
  }

  $form->redirect;

}


