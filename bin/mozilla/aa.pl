#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# AR / AP
#
#======================================================================

# any custom scripts for this one
if (-f "$form->{path}/custom_aa.pl") {
      eval { require "$form->{path}/custom_aa.pl"; };
}
if (-f "$form->{path}/$form->{login}_aa.pl") {
      eval { require "$form->{path}/$form->{login}_aa.pl"; };
}

use SL::VR;

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

# $locale->text('Add AR Transaction')
# $locale->text('Edit AR Transaction')
# $locale->text('Add AP Transaction')
# $locale->text('Edit AP Transaction')
# $locale->text('Add AP Voucher')
# $locale->text('Edit AP Voucher')

# $locale->text('Add Credit Note')
# $locale->text('Edit Credit Note')
# $locale->text('Add Debit Note')
# $locale->text('Edit Debit Note')


sub add {

  &create_links;
  
  %title = ( transaction => "$form->{ARAP} Transaction",
             credit_note => 'Credit Note',
	     debit_note => 'Debit Note' );
  
  if ($form->{batch}) {
    $title = "Add $form->{ARAP} Voucher";
    $form->{title} = $locale->text($title);
    if ($form->{batchdescription}) {
      $form->{title} .= " / $form->{batchdescription}";
    }
  } else {
    $title = "Add $title{$form->{type}}";
    $form->{title} = $locale->text($title);
  }
  
  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  $form->{focus} = "amount_1";
  &display_form;
  
}


sub edit {

  &create_links;
  
  %title = ( transaction => "$form->{ARAP} Transaction",
             credit_note => 'Credit Note',
	     debit_note => 'Debit Note' );
  
  if ($form->{batch}) {
    $title = "Edit $form->{ARAP} Voucher";
    $form->{title} = $locale->text($title);
    if ($form->{batchdescription}) {
      $form->{title} .= " / $form->{batchdescription}";
    }
  } else {
    $title = "Edit $title{$form->{type}}";
    $form->{title} = $locale->text($title);
  }
 
  &display_form;

}


sub display_form {

  &form_header;
  &form_footer;

}


sub create_links {

  $readonly = $form->{readonly};
  $form->create_links($form->{ARAP}, \%myconfig, $form->{vc});
  $form->{readonly} ||= $readonly;

  @a = qw(duedate taxincluded terms cashdiscount discountterms payment_accno payment_method);
  push @a, $form->{ARAP};
  for (@a) { $temp{$_} = $form->{$_} }

  if (exists $form->{oldinvtotal} && $form->{oldinvtotal} < 0) {
    $form->{type} = ($form->{vc} eq 'customer') ? 'credit_note' : 'debit_note';
    for (qw(invtotal totalpaid)) { $form->{"old$_"} *= -1 }
  }

  $form->{type} ||= "transaction";
  $form->{formname} ||= $form->{type};
  $form->{format} ||= $myconfig{outputformat};

  if ($myconfig{printer}) {
    $form->{format} ||= "postscript";
  } else {
    $form->{format} ||= "pdf";
  }
  $form->{media} ||= $myconfig{printer};


# $locale->text('Transaction')
# $locale->text('Credit Note')
# $locale->text('Debit Note')

  %selectform = ( transaction => 'Transaction',
                  credit_note => 'Credit Note',
		  debit_note => 'Debit Note' );
  
  $form->{selectformname} = qq|$form->{type}--|.$locale->text($selectform{$form->{type}});
      
  if ($latex) {
    if (!$form->{batch}) {
      if ($form->{ARAP} eq 'AR') {
	if ($form->{type} eq 'credit_note') {
	  $form->{selectformname} .= qq|\ncheck--|.$locale->text('Check');
	} else {
	  $form->{selectformname} .= qq|\nreceipt--|.$locale->text('Receipt');
	}
      } else {
	if ($form->{type} eq 'debit_note') { 
	  $form->{selectformname} .= qq|\nreceipt--|.$locale->text('Receipt');
	} else {
	  $form->{selectformname} .= qq|\ncheck--|.$locale->text('Check');
	}
      }
    }
  }
  
  if (!$form->{batch}) {
    if ($form->{ARAP} eq 'AR') {
      if ($form->{type} eq 'transaction') {
	$form->{selectformname} .= qq|\nremittance_voucher--|.$locale->text('Remittance Voucher') if $form->{remittancevoucher};
      }
    }
  }
  
  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};

  for (@curr) { $form->{selectcurrency} .= "$_\n" }

  AA->get_name(\%myconfig, \%$form);

  $form->{currency} =~ s/ //g;
  $form->{duedate} = $temp{duedate} if $temp{duedate};

  if ($form->{id}) {
    for (@a) { $form->{$_} = $temp{$_} };
  }
  
  $form->{notes} = $form->{intnotes} if !$form->{id};
  
  $form->{"old$form->{vc}"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
  $form->{"old$form->{vc}number"} = $form->{"$form->{vc}number"};
  for (qw(transdate duedate currency)) { $form->{"old$_"} = $form->{$_} }

  # customers/vendors
  $form->{"select$form->{vc}"} = "";
  if (@{ $form->{"all_$form->{vc}"} }) {
    $form->{$form->{vc}} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
    for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|$_->{name}--$_->{id}\n| }
  }
  
  # departments
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "\n";
    $form->{department} = "$form->{department}--$form->{department_id}" if $form->{department_id};
    
    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|$_->{description}--$_->{id}\n| }
  }
  
  $form->{employee} = "$form->{employee}--$form->{employee_id}";
  # sales staff
  if (@{ $form->{all_employee} }) {
    $form->{selectemployee} = "";
    for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }
  }
  
  # projects
  if (@{ $form->{all_project} }) {
    $form->{selectprojectnumber} = "\n";
    for (@{ $form->{all_project} }) { $form->{selectprojectnumber} .= qq|$_->{projectnumber}--$_->{id}\n| }
  }

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }

  # paymentmethod
  if (@{ $form->{all_paymentmethod} }) {
    $form->{selectpaymentmethod} = "\n";
    $form->{paymentmethod} = "$form->{paymentmethod}--$form->{paymentmethod_id}" if $form->{paymentmethod_id};

    for (@{ $form->{all_paymentmethod} }) { $form->{selectpaymentmethod} .= qq|$_->{description}--$_->{id}\n| }
  }

  $form->{"select$form->{vc}"} = $form->escape($form->{"select$form->{vc}"},1);
  for (qw(formname currency department employee projectnumber language paymentmethod)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }
  
  $netamount = 0;
  $tax = 0;
  $taxrate = 0;
  $ml = ($form->{ARAP} eq 'AR') ? 1 : -1;
  $ml *= -1 if $form->{type} =~ /_note/;

  foreach $key (keys %{ $form->{"$form->{ARAP}_links"} }) {
    
    $form->{"select$key"} = "";
    foreach $ref (@{ $form->{"$form->{ARAP}_links"}{$key} }) {
      if ($key eq "$form->{ARAP}_tax") {
	$form->{"select$form->{ARAP}_tax_$ref->{accno}"} = $form->escape("$ref->{accno}--$ref->{description}",1);
	next;
      }
      $form->{"select$key"} .= "$ref->{accno}--$ref->{description}\n";
    }
    $form->{"select$key"} = $form->escape($form->{"select$key"},1);
    
    # if there is a value we have an old entry
    for $i (1 .. scalar @{ $form->{acc_trans}{$key} }) {

      if ($key eq "$form->{ARAP}_paid") {
	$form->{"$form->{ARAP}_paid_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
	$form->{"paid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{amount} * -1 * $ml;
	$form->{"datepaid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{transdate};
	$form->{"olddatepaid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{transdate};
	$form->{"source_$i"} = $form->{acc_trans}{$key}->[$i-1]->{source};
	$form->{"memo_$i"} = $form->{acc_trans}{$key}->[$i-1]->{memo};
	
	$form->{"exchangerate_$i"} = $form->{acc_trans}{$key}->[$i-1]->{exchangerate};
	$form->{"cleared_$i"} = $form->{acc_trans}{$key}->[$i-1]->{cleared};
	$form->{"vr_id_$i"} = $form->{acc_trans}{$key}->[$i-1]->{vr_id};

	$form->{"paymentmethod_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{paymentmethod}--$form->{acc_trans}{$key}->[$i-1]->{paymentmethod_id}";
	
	$form->{paidaccounts}++;

      } elsif ($key eq "$form->{ARAP}_discount") {

	$form->{"$form->{ARAP}_discount_paid"} = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[0]->{description}";
	$form->{"discount_paid"} = $form->{acc_trans}{$key}->[0]->{amount} * -1 * $ml;
	$form->{"discount_datepaid"} = $form->{acc_trans}{$key}->[0]->{transdate};
	$form->{"olddiscount_datepaid"} = $form->{acc_trans}{$key}->[0]->{transdate};
	$form->{"discount_source"} = $form->{acc_trans}{$key}->[0]->{source};
	$form->{"discount_memo"} = $form->{acc_trans}{$key}->[0]->{memo};
	
	$form->{"discount_exchangerate"} = $form->{acc_trans}{$key}->[0]->{exchangerate};
	$form->{"discount_cleared"} = $form->{acc_trans}{$key}->[0]->{cleared};
	$form->{"discount_paymentmethod"} = "$form->{acc_trans}{$key}->[0]->{paymentmethod_id}--$form->{acc_trans}{$key}->[0]->{paymentmethod}";

      } else {
     
	$akey = $key;
	$akey =~ s/$form->{ARAP}_//;
	
        if ($key eq "$form->{ARAP}_tax") {
	  if (! $form->{acc_trans}{$key}->[$i-1]->{id}) {
	    $form->{"${key}_$form->{acc_trans}{$key}->[$i-1]->{accno}"} = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";

	    $amount = $form->{acc_trans}{$key}->[$i-1]->{amount} * $ml;
	    $form->{"${akey}_$form->{acc_trans}{$key}->[$i-1]->{accno}"} += $amount;
	  }

	} else {
	  $form->{"${akey}_$i"} = $form->{acc_trans}{$key}->[$i-1]->{amount} * $ml;

	  if ($akey eq 'amount') {
	    $form->{"description_$i"} = $form->{acc_trans}{$key}->[$i-1]->{memo};
	    $form->{rowcount}++;
	    $netamount += $form->{"${akey}_$i"};

            $form->{"projectnumber_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{projectnumber}--$form->{acc_trans}{$key}->[$i-1]->{project_id}" if $form->{acc_trans}{$key}->[$i-1]->{project_id};
	  } else {
	    $form->{invtotal} = $form->{acc_trans}{$key}->[$i-1]->{amount} * -1 * $ml;
	  }
	  $form->{"${key}_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
	}
      }
    }
  }
  
  if ($form->{paidaccounts}) {
    $i = $form->{paidaccounts} + 1;
  } else {
    $i = $form->{paidaccounts} = 1;
  }
  
  $form->{"$form->{ARAP}_paid_$i"} = $form->{payment_accno} if $form->{payment_accno};
  $form->{"paymentmethod_$i"} = $form->{payment_method} if $form->{payment_method};


  $tax = $form->{oldinvtotal} - $netamount;
  @taxaccounts = split / /, $form->{taxaccounts};

  if ($form->{taxincluded}) {
    $diff = 0;
    # add tax to individual amounts
    for $i (1 .. $form->{rowcount}) {
      if ($netamount) {
	$amount = $form->{"amount_$i"} * (1 + $tax / $netamount);
	$form->{"amount_$i"} = $form->round_amount($amount, $form->{precision});
      }
    }
  }

  if ($form->{type} =~ /_note/) {
    $form->{"select$form->{ARAP}_discount"} = "";
  } else {
    $form->{cd_available} = ($form->{taxincluded}) ? ($netamount + $tax) * $form->{cashdiscount} : $netamount * $form->{cashdiscount};
  }

  $form->{invtotal} = $netamount + $tax;
  

  if ($form->{id}) {

    $cdt = ($form->{cdt}) ? ($netamount - $form->{discount_paid}) : $netamount;
    
    for (@taxaccounts) {
      $tax = $form->round_amount($cdt * $form->{"${_}_rate"}, $form->{precision});
      if ($tax) {
	if ($form->{"tax_$_"} == $tax) {
	  $form->{"calctax_$_"} = 1;
	}
      }
    }

  } else {
    for (@taxaccounts) { $form->{"calctax_$_"} = 1 }
  }

  for (qw(payment discount)) { $form->{"${_}_accno"} = $form->escape($form->{"${_}_accno"},1) }
  $form->{payment_method} = $form->escape($form->{payment_method}, 1);

  $form->{cashdiscount} *= 100;

  $form->{rowcount}++ if ($form->{id} || !$form->{rowcount});

  $form->{$form->{ARAP}} ||= $form->{"$form->{ARAP}_1"};
  $form->{rowcount} = 1 unless $form->{"$form->{ARAP}_amount_1"};
  
  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum(\%myconfig, $form->{transdate}) <= $form->{closedto});

  # readonly
  if (! $form->{readonly}) {
    if ($form->{batch}) {
      $form->{readonly} = 1 if $myconfig{acs} =~ /Vouchers--Payable Batch/ || $form->{approved};
    } else {
      $form->{readonly} = 1 if $myconfig{acs} =~ /$form->{ARAP}--(Add Transaction| Note)/;
    }
  }

}


sub form_header {

  $form->{taxincluded} = ($form->{taxincluded}) ? "checked" : "";

  # format amounts
  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});
  
  if ($form->{defaultcurrency}) {
    $exchangerate = qq|<tr>|;
    $exchangerate .= qq|
                <th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td>
		  <table>
		    <tr>
		    
		<td><select name=currency onChange="javascript:document.forms[0].submit()">|
		.$form->select_option($form->{selectcurrency}, $form->{currency})
		.qq|</select></td>|;
  
    if ($form->{currency} ne $form->{defaultcurrency}) {
      $exchangerate .= qq|
      <th align=right nowrap>|.$locale->text('Exchange Rate').qq| <font color=red>*</font></th>
      <td><input name=exchangerate size=10 value=$form->{exchangerate}></td>|;
    }
    $exchangerate .= qq|</tr></table></td></tr>|;
  }
 
  $taxincluded = "";
  if ($form->{taxaccounts}) {
    $taxincluded = qq|
	      <tr>
		<td align=right><input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}></td>
		<th align=left nowrap>|.$locale->text('Tax Included').qq|</th>
	      </tr>
|;
  }

 
  if (($rows = $form->numtextrows($form->{notes}, 50) - 1) < 2) {
    $rows = 2;
  }
  $notes = qq|<textarea name=notes rows=$rows cols=50 wrap=soft>$form->{notes}</textarea>|;
  
  $department = qq|
	      <tr>
		<th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td colspan=3><select name=department>|
		.$form->select_option($form->{selectdepartment}, $form->{department}, 1)
		.qq|
		</select>
		</td>
	      </tr>
| if $form->{selectdepartment};

 
  $n = ($form->{creditremaining} < 0) ? "0" : "1";

  if ($form->{vc} eq 'customer') {
    $vclabel = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
  } else {
    $vclabel = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
  }
  
  $vc = qq|<input type=hidden name=action value="Update">
	      <tr>
		<th align=right nowrap>$vclabel <font color=red>*</font></th>
|;

  if ($form->{"select$form->{vc}"}) {
    $vc .= qq|
                <td colspan=3><select name="$form->{vc}" onChange="javascript:document.forms[0].submit()">|.$form->select_option($form->{"select$form->{vc}"}, $form->{$form->{vc}}, 1).qq|</select>
                </td>
              </tr>
|;
  } else {
    $vc .= qq|
               <td colspan=3><input name="$form->{vc}" value="$form->{$form->{vc}}" size=35>
                </td>
	      </tr>
	      <tr>
		<th align=right nowrap>$vcnumber</th>
		<td colspan=3><input name="$form->{vc}number" value="$form->{"$form->{vc}number"}" size=35></td>
	      </tr>
|;
  }

  $employee = $form->hide_form(qw(employee));

  if ($form->{selectemployee}) {
    $label = ($form->{ARAP} eq 'AR') ? $locale->text('Salesperson') : $locale->text('Employee');
    
    $employee = qq|
	      <tr>
		<th align=right nowrap>$label</th>
		<td><select name=employee>|
		.$form->select_option($form->{selectemployee}, $form->{employee}, 1)
		.qq|
		</select>
		</td>
	      </tr>
|;
  }

  for (qw(terms discountterms)) { $form->{$_} = "" if ! $form->{$_} }

  $focus = ($form->{focus}) ? $form->{focus} : "amount_$form->{rowcount}";

  if ($form->{"select$form->{ARAP}_discount"}) {
    $terms = qq|
 	      <tr>
		<th align="right" nowrap>|.$locale->text('Terms').qq|</th>
		<th align=left colspan=3 nowrap>
		<input name=cashdiscount size=3 value=|.$form->format_amount(\%myconfig, $form->{cashdiscount}).qq|> / 
		<input name=discountterms size=3 value=$form->{discountterms}> |.$locale->text('Net').qq|
		<input name=terms size=3 value=$form->{terms}> |.$locale->text('days').qq|
		</th>
	      </tr>
|;
  } else {
    $terms = qq|
 	      <tr>
		<th align="right" nowrap>|.$locale->text('Terms').qq|</th>
		<th align=left colspan=3 nowrap>
		|.$locale->text('Net').qq|
		<input name=terms size=3 value=$form->{terms}> |.$locale->text('days').qq|
		</th>
	      </tr>
|;
  }

  if ($form->{batch} && ! $form->{approved}) {
    $transdate = qq|
		<td>$form->{transdate}</td>
		<input type=hidden name=transdate value=$form->{transdate}>
|;
  } else {
    $transdate = qq|
		<td><input name=transdate size=11 class=date title="$myconfig{dateformat}" value=$form->{transdate}></td>
|;
  }

  if ($form->{vc} eq 'vendor') {
    $dcn = qq|
              <tr>
	        <th align=right nowrap>|.$locale->text('DCN').qq|</th>
		<td><input name=dcn size=60 value="|.$form->quote($form->{dcn}).qq|"></td>
	      </tr>
|;
  } else {
    $dcn = qq|
              <tr valign=top>
	        <th align=right nowrap>|.$locale->text('DCN').qq|</th>
		<td>$form->{dcn}</td>
	      </tr>
| .$form->hide_form('dcn');
  }
    
  if (($rows = $form->numtextrows($form->{description}, 60, 5)) > 1) {
    $description = qq|<textarea name="description" rows=$rows cols=60 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=60 value="|.$form->quote($form->{description}).qq|">|;
  }
  $description = qq|
              <tr valign=top>
	        <th align=right nowrap>|.$locale->text('Description').qq|</th>
		<td colspan=3>$description</td>
              </tr>
|;


  $form->{onhold} = ($form->{onhold}) ? "checked" : "";

  $form->header;
  
  print qq|
<body onload="document.forms[0].${focus}.focus()" />

<form method=post action=$form->{script}>

<input type=hidden name=title value="|.$form->quote($form->{title}).qq|">
|;

  $form->hide_form(qw(id type printed emailed sort closedto locked oldtransdate oldduedate oldcurrency audittrail recurring checktax creditlimit creditremaining defaultcurrency rowcount oldterms batch batchid batchnumber batchdescription cdt precision remittancevoucher));
  $form->hide_form("select$form->{vc}");
  $form->hide_form(map { "select$_" } qw(formname currency department employee projectnumber language paymentmethod));
  $form->hide_form("old$form->{vc}", "$form->{vc}_id", "old$form->{vc}number");
  $form->hide_form(map { "select$_" } ("$form->{ARAP}_amount", "$form->{ARAP}", "$form->{ARAP}_paid", "$form->{ARAP}_discount"));

  print qq|

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      $vc
	      <tr>
		<td></td>
		<td colspan=3>
		  <table>
		    <tr>
		      <td colspan=4>$form->{city}, $form->{state} $form->{country}</td>
		    </tr>
		    <tr>
		      <th align=right nowrap>|.$locale->text('Credit Limit').qq|</th>
		      <td>|.$form->format_amount(\%myconfig, $form->{creditlimit}, 0, "0").qq|</td>
		      <td width=10></td>
		      <th align=right nowrap>|.$locale->text('Remaining').qq|</th>
		      <td class="plus$n">|.$form->format_amount(\%myconfig, $form->{creditremaining}, 0, "0").qq|</td>
		    </tr>
		  </table>
		</td>
	      </tr>
	      $exchangerate
              <tr>
	        <td>&nbsp;</td>
	      </tr>
	      <tr>
		<td align=right><input name=onhold type=checkbox class=checkbox value=1 $form->{onhold}></td>
		<th align=left nowrap>|.$locale->text('On Hold').qq|</font></th>
	      </tr>
	      $taxincluded
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $department
	      $employee
	      <tr>
		<th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
		<td><input name=invnumber size=20 value="|.$form->quote($form->{invnumber}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Order Number').qq|</th>
		<td><input name=ordnumber size=20 value="|.$form->quote($form->{ordnumber}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Invoice Date').qq| <font color=red>*</font></th>
		$transdate
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Due Date').qq|</th>
		<td><input name=duedate size=11 class=date title="$myconfig{dateformat}" value=$form->{duedate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('PO Number').qq|</th>
		<td><input name=ponumber size=20 value="|.$form->quote($form->{ponumber}).qq|"></td>
	      </tr>
	      $terms
	    </table>
	  </td>
	</tr>
	<tr>
	  <td>
	    <table>
	      $dcn
	      $description
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
|;
    
    if ($form->{selectprojectnumber}) {
      $project = qq|
	  <th>|.$locale->text('Project').qq|</th>
|;
    }

     print qq|
	<tr>
	  <th>|.$locale->text('Amount').qq|</th>
	  <th></th>
	  <th>|.$locale->text('Account').qq|</th>
	  <th>|.$locale->text('Description').qq|</th>
	  $project
	</tr>
|;
 
  $form->{subtotal} = 0;
  
  for $i (1 .. $form->{rowcount}) {

    if ($form->{selectprojectnumber}) {
      $project = qq|
	  <td align=right><select name="projectnumber_$i">|
          .$form->select_option($form->{selectprojectnumber}, $form->{"projectnumber_$i"}, 1)
	  .qq|</select></td>
|;
    }

    if (($rows = $form->numtextrows($form->{"description_$i"}, 40)) > 1) {
      $description = qq|<td><textarea name="description_$i" rows=$rows cols=40>$form->{"description_$i"}</textarea></td>|;
    } else {
      $description = qq|<td><input name="description_$i" size=40 value="|.$form->quote($form->{"description_$i"}).qq|"></td>|;
    }
    
    $form->{subtotal} += $form->{"amount_$i"};
    
    print qq|
	<tr valign=top>
	  <td><input name="amount_$i" size=11 value="|
	  .$form->format_amount(\%myconfig, $form->{"amount_$i"}, $form->{precision})
	  .qq|" accesskey="$i"></td>
	  <td></td>
	  <td><select name="$form->{ARAP}_amount_$i">|
	  .$form->select_option($form->{"select$form->{ARAP}_amount"}, $form->{"$form->{ARAP}_amount_$i"})
	  .qq|</select></td>
	  $description
	  $project
	</tr>
|;
  }

  foreach $item (split / /, $form->{taxaccounts}) {

    $form->{"calctax_$item"} = ($form->{"calctax_$item"}) ? "checked" : "";

    $form->{"tax_$item"} = $form->format_amount(\%myconfig, $form->{"tax_$item"}, $form->{precision});

    print qq|
        <tr>
	  <td><input name="tax_$item" size=11 value=$form->{"tax_$item"}></td>
	  <td align=right><input name="calctax_$item" class=checkbox type=checkbox value=1 $form->{"calctax_$item"}></td>
	  <td><select name="$form->{ARAP}_tax_$item">|.$form->select_option($form->{"select$form->{ARAP}_tax_$item"}).qq|</select></td>
	</tr>
|;
  
    $form->hide_form(map { "${item}_$_" } qw(rate description taxnumber));
    $form->hide_form("select$form->{ARAP}_tax_$item");
  }


  if (!$form->{"$form->{ARAP}_discount_paid"}) {
    $form->{"$form->{ARAP}_discount_paid"} = $form->unescape($form->{discount_accno});
  }
  
  if ($form->{currency} eq $form->{defaultcurrency}) {
    @column_index = qw(datepaid source memo paid);
  } else {
    @column_index = qw(datepaid source memo paid exchangerate);
  }
  push @column_index, "paymentmethod" if $form->{selectpaymentmethod};
  push @column_index, "ARAP_paid";

  $column_data{datepaid} = "<th nowrap>".$locale->text('Date')." <font color=red>*</font></th>";
  $column_data{paid} = "<th>".$locale->text('Amount')." <font color=red>*</font></th>";
  $column_data{exchangerate} = "<th>".$locale->text('Exch')." <font color=red>*</font></th>";
  $column_data{ARAP_paid} = "<th>".$locale->text('Account')." <font color=red>*</font></th>";
  $column_data{source} = "<th>".$locale->text('Source')."</th>";
  $column_data{memo} = "<th>".$locale->text('Memo')."</th>";
  $column_data{paymentmethod} = "<th>".$locale->text('Method')."</th>";
  
 
  $total = "";
  $cashdiscount = "";
  $payments = "";
  
  $totalpaid = 0;
  
  if ($form->{cashdiscount}) {
    $discountavailable = qq|
  <tr>
    <td><b>|.$locale->text('Cash Discount').qq|:</b> |.$form->format_amount(\%myconfig, $form->{cd_available}, $form->{precision}).qq|</td>
  </tr>
|;

    $cashdiscount = qq|
  <tr class=listheading>
    <th class=listheading>|.$locale->text('Cash Discount').qq|</th>
  </tr>

  <tr>
    <td>
      <table width=100%>
        <tr>
|;
 
    for (@column_index) { $cashdiscount .= qq|$column_data{$_}\n| }
   
   
    $totalpaid = $form->{"discount_paid"};
   
    $cashdiscount .= qq|
        </tr>
|;
   
    $exchangerate = qq|&nbsp;|;
    if ($form->{currency} ne $form->{defaultcurrency}) {
      $form->{discount_exchangerate} = $form->format_amount(\%myconfig, $form->{discount_exchangerate});
      $exchangerate = qq|<input name="discount_exchangerate" size=10 value=$form->{"discount_exchangerate"}>|.$form->hide_form(qw(olddiscount_datepaid));
    }

    $column_data{paid} = qq|<td align=center><input name="discount_paid" size=11 value=|.$form->format_amount(\%myconfig, $form->{"discount_paid"}, $form->{precision}).qq|></td>|;
    $column_data{ARAP_paid} = qq|<td align=center><select name="$form->{ARAP}_discount_paid">|.$form->select_option($form->{"select$form->{ARAP}_discount"}, $form->{"$form->{ARAP}_discount_paid"}).qq|</select></td>|;
    $column_data{datepaid} = qq|<td align=center nowrap><input name="discount_datepaid" size=11 class=date title="$myconfig{dateformat}" value=$form->{"discount_datepaid"}></td>|;
    $column_data{exchangerate} = qq|<td align=center>$exchangerate</td>|;
    $column_data{source} = qq|<td align=center><input name="discount_source" size=11 value="|.$form->quote($form->{"discount_source"}).qq|"></td>|;
    $column_data{memo} = qq|<td align=center><input name="discount_memo" size=11 value="|.$form->quote($form->{"discount_memo"}).qq|"></td>|;
    $column_data{paymentmethod} = qq|<td align=center><select name="discount_paymentmethod">|.$form->select_option($form->{"selectpaymentmethod"}, $form->{discount_paymentmethod}, 1).qq|</select></td>|;
    
    $cashdiscount .= qq|
        <tr>
|;
  
    for (@column_index) { $cashdiscount .= qq|$column_data{$_}\n| }
    
    $cashdiscount .= qq|
        </tr>
|;

    $cashdiscount .= $form->hide_form(map { "discount_$_" } qw(cleared));

    $payments = qq|
  <tr class=listheading>
    <th class=listheading colspan=7>|.$locale->text('Payments').qq|</th>
  </tr>
|;

  } else {
    $payments = qq|
  <tr class=listheading>
    <th class=listheading>|.$locale->text('Payments').qq|</th>
  </tr>

  <tr>
    <td>
      <table width=100%>
        <tr>
|;
  
  for (@column_index) { $payments .= qq|$column_data{$_}\n| }
  
  $payments .= qq|
        </tr>
|;
  }

  if ($form->{batch}) {
    $cashdiscount = "";
    $payments = "";
    $form->{paidaccounts} = 0;
  }

  $cd_tax = 0;
  if ($form->{discount_paid} && $form->{cdt}) {
    $cdtp = $form->{discount_paid} / $form->{subtotal} if $form->{subtotal};
    for (split / /, $form->{taxaccounts}) {
      $cd_tax += $form->round_amount($form->{"tax_$_"} * $cdtp, $form->{precision});
    }
  }

 
  $form->{subtotal} = $form->format_amount(\%myconfig, $form->{subtotal} - $form->{discount_paid}, $form->{precision});
  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, $form->{precision});
 
  $form->hide_form(qw(oldinvtotal oldtotalpaid taxaccounts));

   
  print qq|
        <tr>
	  <th align=left>$form->{invtotal}</th>
	  <td></td>
	  <td><select name="$form->{ARAP}">|
	  .$form->select_option($form->{"select$form->{ARAP}"}, $form->{$form->{ARAP}})
	  .qq|</select></td>
        </tr>
	<tr>
	  <th align=right>|.$locale->text('Notes').qq|</th>
	  <td></td>
	  <td colspan=3>$notes</td>
	</tr>
      </table>
    </td>
  </tr>
  $discountavailable
  $cashdiscount
  $payments
|;  

  $form->{paidaccounts}++ if ($form->{"paid_$form->{paidaccounts}"});
  $form->{"$form->{ARAP}_paid_$form->{paidaccounts}"} = $form->unescape($form->{payment_accno});
  $form->{"paymentmethod_$form->{paidaccounts}"} = $form->unescape($form->{payment_method});

  for $i (1 .. $form->{paidaccounts}) {

    print qq|
        <tr>
|;

    $form->{"exchangerate_$i"} = $form->format_amount(\%myconfig, $form->{"exchangerate_$i"});

    $exchangerate = qq|&nbsp;|;
    if ($form->{currency} ne $form->{defaultcurrency}) {
      $exchangerate = qq|<input name="exchangerate_$i" size=10 value=$form->{"exchangerate_$i"}>|.$form->hide_form("olddatepaid_$i");
    }
    
    $form->hide_form(map { "${_}_$i" } qw(vr_id cleared));
    
    $totalpaid += $form->{"paid_$i"};
    
    $column_data{paid} = qq|<td align=center><input name="paid_$i" size=11 value=|.$form->format_amount(\%myconfig, $form->{"paid_$i"}, $form->{precision}).qq|></td>|;
    $column_data{ARAP_paid} = qq|<td align=center><select name="$form->{ARAP}_paid_$i">|.$form->select_option($form->{"select$form->{ARAP}_paid"}, $form->{"$form->{ARAP}_paid_$i"}).qq|</select></td>|;
    $column_data{exchangerate} = qq|<td align=center>$exchangerate</td>|;
    $column_data{datepaid} = qq|<td align=center><input name="datepaid_$i" size=11 class=date title="$myconfig{dateformat}" value=$form->{"datepaid_$i"}></td>|;
    $column_data{source} = qq|<td align=center><input name="source_$i" size=11 value="|.$form->quote($form->{"source_$i"}).qq|"></td>|;
    $column_data{memo} = qq|<td align=center><input name="memo_$i" size=11 value="|.$form->quote($form->{"memo_$i"}).qq|"></td>|;
    $column_data{paymentmethod} = qq|<td align=center><select name="paymentmethod_$i">|.$form->select_option($form->{"selectpaymentmethod"}, $form->{"paymentmethod_$i"}, 1).qq|</select></td>|;

    for (@column_index) { print qq|$column_data{$_}\n| }
    
    print "
        </tr>
";
  }

  $outstanding = $form->round_amount($form->{oldinvtotal} - $totalpaid, $form->{precision});

  if ($outstanding) {
    # print total
    print qq|
	  <tr>
            <td colspan=4><b>|.$locale->text('Outstanding').":</b> ".$form->format_amount(\%myconfig, $outstanding, $form->{precision}).qq|</td>
	  </tr>
|;
  }
 
  $form->hide_form(qw(city state country paidaccounts payment_accno discount_accno payment_method));
  
  print qq|
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
  
  $transdate = $form->datetonum(\%myconfig, $form->{transdate});

  if ($form->{readonly}) {

    &islocked;

  } else {

    &print_options;

    print "<br>";

    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
               'Print' => { ndx => 2, key => 'P', value => $locale->text('Print') },
	       'Post' => { ndx => 3, key => 'O', value => $locale->text('Post') },
	       'Print and Post' => { ndx => 4, key => 'R', value => $locale->text('Print and Post') },
	       'Post as new' => { ndx => 5, key => 'N', value => $locale->text('Post as new') },
	       'Print and Post as new' => { ndx => 6, key => 'W', value => $locale->text('Print and Post as new') },
	       'Schedule' => { ndx => 7, key => 'H', value => $locale->text('Schedule') },
	       'New Number' => { ndx => 10, key => 'M', value => $locale->text('New Number') },
	       'Delete' => { ndx => 11, key => 'D', value => $locale->text('Delete') },
	      );

    delete $button{'Schedule'} if $form->{batch};

    if ($form->{id}) {

      if ($form->{locked} || $transdate <= $form->{closedto}) {
	for ("Post", "Print and Post", "Delete") { delete $button{$_} }
      }
	
      if (!$latex) {
	for ("Print and Post", "Print and Post as new") { delete $button{$_} }
      }

    } else {
      
      for ("Post as new", "Print and Post as new", "Delete") { delete $button{$_} }
      delete $button{"Print and Post"} if ! $latex;
      
      if ($transdate <= $form->{closedto}) {
	for ("Post", "Print and Post") { delete $button{$_} }
      }
    }

    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
    
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
  my $display = shift;

  if (!$display) {

    $form->{invtotal} = 0;
    
    $form->{exchangerate} = $form->parse_amount(\%myconfig, $form->{exchangerate});

    @flds = ("amount", "$form->{ARAP}_amount", "projectnumber", "description");
    $count = 0;
    @a = ();
    for $i (1 .. $form->{rowcount}) {
      $form->{"amount_$i"} = $form->parse_amount(\%myconfig, $form->{"amount_$i"});
      if ($form->{"amount_$i"}) {
	push @a, {};
	$j = $#a;

	for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
      }
    }

    $form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
    $form->{rowcount} = $count + 1;

    for (1 .. $form->{rowcount}) { $form->{invtotal} += $form->{"amount_$_"} }

    if ($form->{transdate} ne $form->{oldtransdate} || $form->{currency} ne $form->{oldcurrency}) {
      $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, ($form->{ARAP} eq 'AR') ? 'buy' : 'sell');
    }

    $form->{cashdiscount} = $form->parse_amount(\%myconfig, $form->{cashdiscount});
    $form->{discount_paid} = $form->parse_amount(\%myconfig, $form->{discount_paid});
    
    if ($newname = &check_name($form->{vc})) {
      $form->{notes} = $form->{intnotes} unless $form->{id};
      &rebuild_vc($form->{vc}, $form->{ARAP}, $form->{transdate});
    }
    
    if ($form->{oldterms} != $form->{terms}) {
      $form->{duedate} = $form->add_date(\%myconfig, $form->{transdate}, $form->{terms}, 'days');
      $newterms = 1;
      $form->{oldterms} = $form->{terms};
      $form->{oldduedate} = $form->{duedate};
    }

    if ($form->{duedate} ne $form->{oldduedate}) {
      $form->{terms} = $form->datediff(\%myconfig, $form->{transdate}, $form->{duedate});
      $newterms = 1;
      $form->{oldterms} = $form->{terms};
      $form->{oldduedate} = $form->{duedate};
    }
    
    if ($form->{transdate} ne $form->{oldtransdate}) {
      $form->{duedate} = $form->add_date(\%myconfig, $form->{transdate}, $form->{terms}, 'days') if ! $newterms;
      $form->{oldtransdate} = $form->{transdate};
      $newproj = &rebuild_vc($form->{vc}, $form->{ARAP}, $form->{transdate}) if ! $newname;
      if (! $newproj) {
	$form->all_projects(\%myconfig, undef, $form->{transdate});
	$form->{selectprojectnumber} = "";
	if (@{ $form->{all_project} }) {
	  $form->{selectprojectnumber} = "\n";
	  for (@{ $form->{all_project} }) { $form->{selectprojectnumber} .= qq|$_->{projectnumber}--$_->{id}\n| }
	  $form->{selectprojectnumber} = $form->escape($form->{selectprojectnumber},1);
	}
      }

      $form->{selectemployee} = "";
      if (@{ $form->{all_employee} }) {
	for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }
	$form->{selectemployee} = $form->escape($form->{selectemployee},1);
      }
    }
  }

  # recalculate taxes
  @taxaccounts = split / /, $form->{taxaccounts};
  
  for (@taxaccounts) { $form->{"tax_$_"} = $form->parse_amount(\%myconfig, $form->{"tax_$_"}) }
  
  if ($form->{taxincluded}) {

    $ml = 1;
    
    for (0 .. 1) {
      $taxrate = 0;
      $diff = 0;
      
      for (@taxaccounts) {
	if (($form->{"${_}_rate"} * $ml) > 0) {
	  if ($form->{"calctax_$_"}) {
	    $taxrate += $form->{"${_}_rate"};
	  } else {
	    if ($form->{checktax}) {
	      if ($form->{"tax_$_"}) {
		$taxrate += $form->{"${_}_rate"};
	      }
	    }
	  }
	}
      }
      
      $taxrate *= $ml;

      foreach $item (@taxaccounts) {
	if (($form->{"${item}_rate"} * $ml) > 0) {

	  if ($taxrate) {
	    $a = ($form->{cdt}) ? ($form->{invtotal} - $form->{discount_paid}) : $form->{invtotal};
	    $a *= $form->{"${item}_rate"} / (1 + $taxrate);
	    $b = $form->round_amount($a, $form->{precision});
	    $tax = $form->round_amount($a - $diff, $form->{precision});
	    $diff = $b - ($a - $diff);
	  }
	  $form->{"tax_$item"} = $tax if $form->{"calctax_$item"};

	  $form->{"select$form->{ARAP}_tax_$item"} = qq|$item--$form->{"${item}_description"}|;
	  $totaltax += $form->{"tax_$item"};
	}
      }
      $ml *= -1;
    }
    $totaltax += $form->round_amount($diff, $form->{precision});

    $form->{checktax} = 1;
    
  } else {
    foreach $item (@taxaccounts) {
      $form->{"calctax_$item"} = 1 if $form->{calctax};
      
      if ($form->{"calctax_$item"}) {
	$a = ($form->{cdt}) ? $form->{invtotal} - $form->{discount_paid} : $form->{invtotal};
	$form->{"tax_$item"} = $form->round_amount($a * $form->{"${item}_rate"}, $form->{precision});
      }
      $form->{"select$form->{ARAP}_tax_$item"} = qq|$item--$form->{"${item}_description"}|;
      $totaltax += $form->{"tax_$item"};
    }
  }
  
  # redo payment discount
  $form->{cd_available} = $form->{invtotal} * $form->{cashdiscount} / 100;

  if ($form->{taxincluded}) {
    $netamount = $form->{invtotal} - $totaltax;
  } else {
    $netamount = $form->{invtotal};
    $form->{invtotal} += $totaltax;
  }

  if ($form->{discount_paid}) {
    if ($form->{discount_datepaid} ne $form->{olddiscount_datepaid} || $form->{currency} ne $form->{oldcurrency}) {
      $form->{discount_exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{discount_datepaid}, ($form->{ARAP} eq 'AR') ? 'buy' : 'sell');
    }
    $form->{olddiscount_datepaid} = $form->{discount_datepaid};
  }

  $form->{oldcurrency} = $form->{currency};

  $totalpaid = $form->{discount_paid};
  
  $j = 1;
  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      for (qw(olddatepaid datepaid source memo cleared paymentmethod)) { $form->{"${_}_$j"} = $form->{"${_}_$i"} }
      for (qw(paid exchangerate)) { $form->{"${_}_$j"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }

      $totalpaid += $form->{"paid_$j"};

      if ($form->{"datepaid_$j"} ne $form->{"olddatepaid_$j"} || $form->{currency} ne $form->{oldcurrency}) {
	$form->{"exchangerate_$j"} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{"datepaid_$j"}, ($form->{ARAP} eq 'AR') ? 'buy' : 'sell');
      }
      
      $form->{"olddatepaid_$j"} = $form->{"datepaid_$j"};

      if ($j++ != $i) {
	for (qw(olddatepaid datepaid source memo paid exchangerate cleared)) { delete $form->{"${_}_$i"} }
      }
    } else {
      for (qw(olddatepaid datepaid source memo paid exchangerate cleared)) { delete $form->{"${_}_$i"} }
    }
  }

  $form->{payment_accno} = $form->escape($form->{"$form->{ARAP}_paid_$form->{paidaccounts}"},1);
  $form->{payment_method} = $form->escape($form->{"paymentmethod_$form->{paidaccounts}"},1);

  $form->{paidaccounts} = $j;

  $ml = ($form->{type} =~ /_note/) ? -1 : 1;
  $form->{creditremaining} -= ($form->{invtotal} - $totalpaid + $form->{oldtotalpaid} - $form->{oldinvtotal}) * $ml;
  $form->{oldinvtotal} = $form->{invtotal};
  $form->{oldtotalpaid} = $totalpaid;

  &display_form;
  
}


sub post {

  $label = ($form->{vc} eq 'customer') ? $locale->text('Customer missing!') : $locale->text('Vendor missing!');
  
  # check if there is an invoice number, invoice and due date
  $form->isblank("transdate", $locale->text('Invoice Date missing!'));
  $form->isblank($form->{vc}, $label);
  
  $transdate = $form->datetonum(\%myconfig, $form->{transdate});

  $form->error($locale->text('Cannot post transaction for a closed period!')) if ($transdate <= $form->{closedto});

  $form->isblank("exchangerate", $locale->text('Exchange rate missing!')) if ($form->{currency} ne $form->{defaultcurrency});
  
  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      $datepaid = $form->datetonum(\%myconfig, $form->{"datepaid_$i"});
      
      $form->isblank("datepaid_$i", $locale->text('Payment date missing!'));

      $form->error($locale->text('Cannot post payment for a closed period!')) if ($datepaid <= $form->{closedto});

      if ($form->{currency} ne $form->{defaultcurrency}) {
	$form->{"exchangerate_$i"} = $form->{exchangerate} if ($transdate == $datepaid);
	$form->isblank("exchangerate_$i", $locale->text('Exchange rate for payment missing!'));
      }
    }
  }
  
  # if oldname ne name redo form
  ($name) = split /--/, $form->{$form->{vc}};
  if ($form->{"old$form->{vc}"} ne qq|$name--$form->{"$form->{vc}_id"}|) {
    &update;
    exit;
  }

  if (! $form->{repost}) {
    if ($form->{id} && ! $form->{batch}) {
      &repost;
      exit;
    }
  }
  
  # add discount to payments
  $i = $form->{paidaccounts} + 1;
  for (qw(paid datepaid source memo exchangerate cleared)) { $form->{"${_}_$i"} = $form->{"discount_$_"} }
  $form->{discount_index} = $i;
  $form->{"$form->{ARAP}_paid_$i"} = $form->{"$form->{ARAP}_discount_paid"};
  
  if ($form->{"paid_$i"}) {
    $form->{paidaccounts}++;
    
    $datepaid = $form->datetonum(\%myconfig, $form->{"datepaid_$i"});
    $expired = $form->datetonum(\%myconfig, $form->add_date(\%myconfig, $form->{transdate}, $form->{discountterms}, 'days'));
    
    $form->isblank("datepaid_$i", $locale->text('Cash Discount date missing!'));

    $form->error($locale->text('Cannot post cash discount for a closed period!')) if ($datepaid <= $form->{closedto});

    $form->error($locale->text('Date for cash discount past due!')) if ($datepaid > $expired);

    $form->error($locale->text('Cash discount exceeds available discount!')) if $form->parse_amount(\%myconfig, $form->{"paid_$i"}) > ($form->{oldinvtotal} * $form->{cashdiscount});
    
    if ($form->{currency} ne $form->{defaultcurrency}) {
      $form->{"exchangerate_$i"} = $form->{exchangerate} if ($transdate == $datepaid);
      $form->isblank("exchangerate_$i", $locale->text('Exchange rate for cash discount missing!'));
    }
  }

  if ($form->{batch}) {
    $rc = VR->post_transaction(\%myconfig, \%$form);
  } else {
    $rc = AA->post_transaction(\%myconfig, \%$form);
  }

  if ($form->{callback}) {
    $form->{callback} =~ s/(batch|batchid|batchdescription)=.*?&//g;
    $form->{callback} .= "&batch=$form->{batch}&batchid=$form->{batchid}&transdate=$form->{transdate}&batchdescription=".$form->escape($form->{batchdescription},1);
  }
  
  if ($rc) {
    $form->redirect($locale->text('Transaction posted!'));
  } else {
    $form->error($locale->text('Cannot post transaction!'));
  }
  
}


sub delete {

  $form->{title} = $locale->text('Confirm!');
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->{action} = "yes";
  $form->hide_form;

  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|.$locale->text('Are you sure you want to delete Transaction').qq| $form->{invnumber}</h4>

<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>

</body>
</html>
|;

}



sub yes {

  if (AA->delete_transaction(\%myconfig, \%$form, $spool)) {
    $form->redirect($locale->text('Transaction deleted!'));
  } else {
    $form->error($locale->text('Cannot delete transaction!'));
  }

}


sub search {

  $form->create_links($form->{ARAP}, \%myconfig, $form->{vc});
  
  $form->{"select$form->{ARAP}"} = "<option>\n";
  for (@{ $form->{"$form->{ARAP}_links"}{$form->{ARAP}} }) { $form->{"select$form->{ARAP}"} .= "<option>".$form->quote("$_->{accno}--$_->{description}")."\n" }
  
  $vclabel = $locale->text('Customer');
  $vcnumber = $locale->text('Customer Number');
  $l_name = qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> $vclabel|;
  $l_customernumber = qq|<input name="l_customernumber" class=checkbox type=checkbox value=Y> $vcnumber|;
  $l_till = qq|<input name="l_till" class=checkbox type=checkbox value=Y> |.$locale->text('Till');
  
  if ($form->{vc} eq 'vendor') {
    $vclabel = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
    $l_till = "";
    $l_customernumber = "";
    $l_name = qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> $vclabel|;
    $l_vendornumber = qq|<input name="l_vendornumber" class=checkbox type=checkbox value=Y> $vcnumber|;
  }

  if (@{ $form->{"all_$form->{vc}"} }) {
    $form->{"select$form->{vc}"} = "";
    for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|<option value="|.$form->quote($_->{name}).qq|--$_->{id}">$_->{name}\n| }
    $vc = qq|
              <tr>
	        <th align=right nowrap>$vclabel</th>
	        <td colspan=3><select name="$form->{vc}"><option>\n$form->{"select$form->{vc}"}</select>
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

  # departments 
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "<option>\n";

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|<option value="|.$form->quote($_->{description}).qq|--$_->{id}">$_->{description}\n| }

    $l_department = qq|<input name="l_department" class=checkbox type=checkbox value=Y> |.$locale->text('Department');
   
    $department = qq| 
        <tr> 
	  <th align=right nowrap>|.$locale->text('Department').qq|</th>
	  <td><select name=department>$form->{selectdepartment}</select></td>
	</tr>
|;
  }

  if (@{ $form->{all_warehouse} }) {
    $form->{selectwarehouse} = "\n";
    $form->{warehouse} = qq|$form->{warehouse}--$form->{warehouse_id}|;

    for (@{ $form->{all_warehouse} }) { $form->{selectwarehouse} .= qq|$_->{description}--$_->{id}\n| }

    $warehouse = qq|
            <tr>
	      <th align=right>|.$locale->text('Warehouse').qq|</th>
	      <td><select name=warehouse>|
	      .$form->select_option($form->{selectwarehouse}, undef, 1)
	      .qq|</select>
	      </td>
	      <input type=hidden name=selectwarehouse value="|
	      .$form->escape($form->{selectwarehouse},1).qq|">
	    </tr>
|;

    $l_warehouse = qq|<input name="l_warehouse" class=checkbox type=checkbox value=Y> |.$locale->text('Warehouse');
    
  }


  if (@{ $form->{all_employee} }) {
    $form->{selectemployee} = "<option>\n";
    for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|<option value="|.$form->quote($_->{name}).qq|--$_->{id}">$_->{name}\n| }

    $employeelabel = ($form->{ARAP} eq 'AR') ? $locale->text('Salesperson') : $locale->text('Employee');

    $employee = qq|
        <tr>
	  <th align=right nowrap>$employeelabel</th>
	  <td><select name=employee>$form->{selectemployee}</select></td>
	</tr>
|;

    $l_employee = qq|<input name="l_employee" class=checkbox type=checkbox value=Y> $employeelabel|;

    $l_manager = qq|<input name="l_manager" class=checkbox type=checkbox value=Y> |.$locale->text('Manager');

  }


  $form->{title} = ($form->{ARAP} eq 'AR') ? $locale->text('AR Transactions') : $locale->text('AP Transactions');

  $invnumber = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
	  <td><input name=invnumber size=20></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Order Number').qq|</th>
	  <td><input name=ordnumber size=20></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('PO Number').qq|</th>
	  <td><input name=ponumber size=20></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Source').qq|</th>
	  <td><input name=source size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Line Item').qq|</th>
	  <td><input name=memo size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Notes').qq|</th>
	  <td><input name=notes size=40></td>
	</tr>
|;

  $openclosed = qq|
	      <tr>
		<td nowrap><input name=open class=checkbox type=checkbox value=Y checked> |.$locale->text('Open').qq|</td>
		<td nowrap><input name=closed class=checkbox type=checkbox value=Y> |.$locale->text('Closed').qq|</td>
		<td nowrap><input name=onhold class=checkbox type=checkbox value=Y> |.$locale->text('On Hold').qq|</td>
		<td nowrap><input name=paidlate class=checkbox type=checkbox value=Y> |.$locale->text('Paid Late').qq|</td>
		<td nowrap><input name=paidearly class=checkbox type=checkbox value=Y> |.$locale->text('Paid Early').qq|</td>
	      </tr>
|;

  $summary = qq|
              <tr>
		<td><input name=summary type=radio class=radio value=1 checked> |.$locale->text('Summary').qq|</td>
		<td><input name=summary type=radio class=radio value=0> |.$locale->text('Detail').qq|
		</td>
	      </tr>
|;


  if ($form->{outstanding}) {
    $form->{title} = ($form->{ARAP} eq 'AR') ? $locale->text('AR Outstanding') : $locale->text('AP Outstanding');
    $invnumber = "";
    $openclosed = "";
    $summary = "";
  }

  if (@{ $form->{all_years} }) {
    # accounting years
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


  
  @a = ();
  push @a, qq|<input name="l_runningnumber" class=checkbox type=checkbox value=Y> |.$locale->text('No.');
  push @a, qq|<input name="l_id" class=checkbox type=checkbox value=Y> |.$locale->text('ID');
  push @a, qq|<input name="l_invnumber" class=checkbox type=checkbox value=Y checked> |.$locale->text('Invoice Number');
  push @a, qq|<input name="l_ordnumber" class=checkbox type=checkbox value=Y> |.$locale->text('Order Number');
  push @a, qq|<input name="l_description" class=checkbox type=checkbox value=Y checked> |.$locale->text('Description');
  push @a, qq|<input name="l_ponumber" class=checkbox type=checkbox value=Y> |.$locale->text('PO Number');
  push @a, qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked> |.$locale->text('Invoice Date');
  push @a, $l_name;
  push @a, $l_customernumber if $l_customernumber;
  push @a, $l_vendornumber if $l_vendornumber;
  push @a, qq|<input name="l_address" class=checkbox type=checkbox value=Y> |.$locale->text('Address');
  push @a, $l_employee if $l_employee;
  push @a, $l_manager if $l_employee;
  push @a, $l_department if $l_department;
  push @a, qq|<input name="l_netamount" class=checkbox type=checkbox value=Y> |.$locale->text('Amount');
  push @a, qq|<input name="l_tax" class=checkbox type=checkbox value=Y> |.$locale->text('Tax');
  push @a, qq|<input name="l_amount" class=checkbox type=checkbox value=Y checked> |.$locale->text('Total');
  push @a, qq|<input name="l_curr" class=checkbox type=checkbox value=Y> |.$locale->text('Currency');
  push @a, qq|<input name="l_datepaid" class=checkbox type=checkbox value=Y> |.$locale->text('Date Paid');
  push @a, qq|<input name="l_paymentdiff" class=checkbox type=checkbox value=Y> |.$locale->text('Payment Difference');
  push @a, qq|<input name="l_paid" class=checkbox type=checkbox value=Y checked> |.$locale->text('Paid');
  push @a, qq|<input name="l_paymentmethod" class=checkbox type=checkbox value=Y> |.$locale->text('Payment Method');
  push @a, qq|<input name="l_duedate" class=checkbox type=checkbox value=Y> |.$locale->text('Due Date');
  push @a, qq|<input name="l_due" class=checkbox type=checkbox value=Y> |.$locale->text('Due');
  push @a, qq|<input name="l_memo" class=checkbox type=checkbox value=Y> |.$locale->text('Line Item');
  push @a, qq|<input name="l_notes" class=checkbox type=checkbox value=Y> |.$locale->text('Notes');
  push @a, $l_till if $l_till;
  push @a, $l_warehouse if $l_warehouse;
  push @a, qq|<input name="l_shippingpoint" class=checkbox type=checkbox value=Y> |.$locale->text('Shipping Point');
  push @a, qq|<input name="l_shipvia" class=checkbox type=checkbox value=Y> |.$locale->text('Ship via');
  push @a, qq|<input name="l_waybill" class=checkbox type=checkbox value=Y> |.$locale->text('Waybill');
  push @a, qq|<input name="l_dcn" class=checkbox type=checkbox value=Y> |.$locale->text('DCN');
  
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
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Account').qq|</th>
		<td colspan=3><select name=$form->{ARAP}>$form->{"select$form->{ARAP}"}</select></td>
	      </tr>
	      $vc
	      $invnumber
	      <tr>
		<th align=right nowrap>|.$locale->text('From').qq|</th>
		<td colspan=3><input name=transdatefrom size=11 class=date title="$myconfig{dateformat}"> <b>|.$locale->text('To').qq|</b> <input name=transdateto size=11 class=date title="$myconfig{dateformat}"></td>
	      </tr>
	      $selectfrom
	    </table>
	  </td>

	  <td>
	    <table>
	      $employee
	      $department
	      $warehouse
	      <tr>
		<th align=right>|.$locale->text('Shipping Point').qq|</th>
		<td colspan=3><input name=shippingpoint size=40></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Ship via').qq|</th>
		<td colspan=3><input name=shipvia size=40></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Waybill').qq|</th>
		<td colspan=3><input name=waybill size=40></td>
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
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table width=100%>
	      $openclosed
	      $summary
|;

  $form->{sort} = "transdate";
  $form->hide_form(qw(title outstanding sort));
  

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
<input type=hidden name=action value=continue>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->hide_form(qw(nextsub path login));
  
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


sub transactions {

  if ($form->{$form->{vc}}) {
    ($form->{$form->{vc}}, $form->{"$form->{vc}_id"}) = split(/--/, $form->{$form->{vc}});
  }
  
  AA->transactions(\%myconfig, \%$form);

  $href = "$form->{script}?action=transactions";
  for (qw(direction oldsort till outstanding path login summary)) { $href .= qq|&$_=$form->{$_}| }
  $href .= "&title=".$form->escape($form->{title});

  $form->sort_order();
  
  $callback = "$form->{script}?action=transactions";
  for (qw(direction oldsort till outstanding path login summary)) { $callback .= qq|&$_=$form->{$_}| }
  $callback .= "&title=".$form->escape($form->{title},1);

  if ($form->{$form->{ARAP}}) {
    $callback .= "&$form->{ARAP}=".$form->escape($form->{$form->{ARAP}},1);
    $href .= "&$form->{ARAP}=".$form->escape($form->{$form->{ARAP}});
    $form->{$form->{ARAP}} =~ s/--/ /;
    $option = $locale->text('Account')." : $form->{$form->{ARAP}}";
  }
  
  if ($form->{$form->{vc}}) {
    $callback .= "&$form->{vc}=".$form->escape($form->{$form->{vc}},1).qq|--$form->{"$form->{vc}_id"}|;
    $href .= "&$form->{vc}=".$form->escape($form->{$form->{vc}}).qq|--$form->{"$form->{vc}_id"}|;
    $option .= "\n<br>" if ($option);
    $name = ($form->{vc} eq 'customer') ? $locale->text('Customer') : $locale->text('Vendor');
    $option .= "$name : $form->{$form->{vc}}";
  }
  if ($form->{"$form->{vc}number"}) {
    $callback .= "&$form->{vc}number=".$form->escape($form->{"$form->{vc}number"},1);
    $href .= "&$form->{vc}number=".$form->escape($form->{"$form->{vc}number"});
    $option .= "\n<br>" if ($option);
    $name = ($form->{vc} eq 'customer') ? $locale->text('Customer Number') : $locale->text('Vendor Number');
    $option .= qq|$name : $form->{"$form->{vc}number"}|;
  }

  if ($form->{department}) {
    $callback .= "&department=".$form->escape($form->{department},1);
    $href .= "&department=".$form->escape($form->{department});
    ($department) = split /--/, $form->{department};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Department')." : $department";
  }
  if ($form->{employee}) {
    $callback .= "&employee=".$form->escape($form->{employee},1);
    $href .= "&employee=".$form->escape($form->{employee});
    ($employee) = split /--/, $form->{employee};
    $option .= "\n<br>" if ($option);
    if ($form->{ARAP} eq 'AR') {
      $option .= $locale->text('Salesperson');
    } else {
      $option .= $locale->text('Employee');
    }
    $option .= " : $employee";
  }

  if ($form->{invnumber}) {
    $callback .= "&invnumber=".$form->escape($form->{invnumber},1);
    $href .= "&invnumber=".$form->escape($form->{invnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Invoice Number')." : $form->{invnumber}";
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $href .= "&description=".$form->escape($form->{description});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Description')." : $form->{description}";
  }
  if ($form->{ordnumber}) {
    $callback .= "&ordnumber=".$form->escape($form->{ordnumber},1);
    $href .= "&ordnumber=".$form->escape($form->{ordnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Order Number')." : $form->{ordnumber}";
  }
  if ($form->{ponumber}) {
    $callback .= "&ponumber=".$form->escape($form->{ponumber},1);
    $href .= "&ponumber=".$form->escape($form->{ponumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('PO Number')." : $form->{ponumber}";
  }
  if ($form->{notes}) {
    $callback .= "&notes=".$form->escape($form->{notes},1);
    $href .= "&notes=".$form->escape($form->{notes});
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Notes')." : $form->{notes}";
  }
  if ($form->{warehouse}) {
    $callback .= "&warehouse=".$form->escape($form->{warehouse},1);
    $href .= "&warehouse=".$form->escape($form->{warehouse});
    ($warehouse) = split /--/, $form->{warehouse};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Warehouse')." : $warehouse";
    delete $form->{l_warehouse};
  }
  if ($form->{shippingpoint}) {
    $callback .= "&shippingpoint=".$form->escape($form->{shippingpoint},1);
    $href .= "&shippingpoint=".$form->escape($form->{shippingpoint});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Shipping Point')." : $form->{shippingpoint}";
  }
  if ($form->{shipvia}) {
    $callback .= "&shipvia=".$form->escape($form->{shipvia},1);
    $href .= "&shipvia=".$form->escape($form->{shipvia});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Ship via')." : $form->{shipvia}";
  }
  if ($form->{waybill}) {
    $callback .= "&waybill=".$form->escape($form->{waybill},1);
    $href .= "&waybill=".$form->escape($form->{waybill});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Waybill')." : $form->{waybill}";
  }
  if ($form->{memo}) {
    $callback .= "&memo=".$form->escape($form->{memo},1);
    $href .= "&memo=".$form->escape($form->{memo});
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Line Item')." : $form->{memo}";
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
  if ($form->{onhold}) {
    $callback .= "&onhold=$form->{onhold}";
    $href .= "&onhold=$form->{onhold}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('On Hold');
  }
  if ($form->{paidlate}) {
    $callback .= "&paidlate=$form->{paidlate}";
    $href .= "&paidlate=$form->{paidlate}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Paid Late');
  }
  if ($form->{paidearly}) {
    $callback .= "&paidearly=$form->{paidearly}";
    $href .= "&paidearly=$form->{paidearly}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Paid Early');
  }


  @columns = $form->sort_columns(qw(transdate id invnumber ordnumber ponumber description name customernumber vendornumber address netamount tax amount paid paymentmethod due curr datepaid duedate memo notes till employee manager warehouse shippingpoint shipvia waybill dcn paymentdiff department));
  pop @columns if $form->{department};
  unshift @columns, "runningnumber";

  @column_index = ();
  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      if ($form->{l_curr} && $item =~ /(amount|tax|paid|due)/) {
	push @column_index, "fx_$item";
      }

      # add column to href and callback
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }

  if (!$form->{summary}) {
    @a = grep !/memo/, @column_index;
    @column_index = (@a, (qw(source debit credit accno memo projectnumber)));
  }

  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
    $href .= "&l_subtotal=Y";
  }
  
  if ($form->{vc} eq 'customer') {
    $employee = $locale->text('Salesperson');
    $name = $locale->text('Customer');
    $namenumber = $locale->text('Customer Number');
    $namefld = "customernumber";
  } else {
    $employee = $locale->text('Employee');
    $name = $locale->text('Vendor');
    $namenumber = $locale->text('Vendor Number');
    $namefld = "vendornumber";
  }
  
  $column_data{runningnumber} = qq|<th class=listheading>&nbsp;</th>|;
  $column_data{id} = "<th><a class=listheading href=$href&sort=id>".$locale->text('ID')."</a></th>";
  $column_data{transdate} = "<th><a class=listheading href=$href&sort=transdate>".$locale->text('Date')."</a></th>";
  $column_data{duedate} = "<th><a class=listheading href=$href&sort=duedate>".$locale->text('Due Date')."</a></th>";
  $column_data{invnumber} = "<th><a class=listheading href=$href&sort=invnumber>".$locale->text('Invoice')."</a></th>";
  $column_data{ordnumber} = "<th><a class=listheading href=$href&sort=ordnumber>".$locale->text('Order')."</a></th>";
  $column_data{ponumber} = "<th><a class=listheading href=$href&sort=ponumber>".$locale->text('PO Number')."</a></th>";
  $column_data{name} = "<th><a class=listheading href=$href&sort=name>$name</a></th>";
  $column_data{$namefld} = "<th><a class=listheading href=$href&sort=$namefld>$namenumber</a></th>";
  $column_data{address} = "<th class=listheading>" . $locale->text('Address') . "</th>";
  $column_data{netamount} = "<th class=listheading>" . $locale->text('Amount') . "</th>";
  $column_data{tax} = "<th class=listheading>" . $locale->text('Tax') . "</th>";
  $column_data{amount} = "<th class=listheading>" . $locale->text('Total') . "</th>";
  $column_data{paid} = "<th class=listheading>" . $locale->text('Paid') . "</th>";
  $column_data{paymentmethod} = "<th><a class=listheading href=$href&sort=paymentmethod>" . $locale->text('Payment Method') . "</a></th>";
  $column_data{datepaid} = "<th><a class=listheading href=$href&sort=datepaid>" . $locale->text('Date Paid') . "</a></th>";
  $column_data{due} = "<th class=listheading>" . $locale->text('Due') . "</th>";
  $column_data{notes} = "<th class=listheading>".$locale->text('Notes')."</th>";
  $column_data{employee} = "<th><a class=listheading href=$href&sort=employee>$employee</a></th>";
  $column_data{manager} = "<th><a class=listheading href=$href&sort=manager>".$locale->text('Manager')."</a></th>";
  $column_data{till} = "<th><a class=listheading href=$href&sort=till>".$locale->text('Till')."</a></th>";
  
  $column_data{warehouse} = qq|<th><a class=listheading href=$href&sort=warehouse>|.$locale->text('Warehouse').qq|</a></th>|;
  
  $column_data{shippingpoint} = "<th><a class=listheading href=$href&sort=shippingpoint>" . $locale->text('Shipping Point') . "</a></th>";
  $column_data{shipvia} = "<th><a class=listheading href=$href&sort=shipvia>" . $locale->text('Ship via') . "</a></th>";
  $column_data{waybill} = "<th><a class=listheading href=$href&sort=waybill>" . $locale->text('Waybill') . "</a></th>";
  $column_data{dcn} = "<th><a class=listheading href=$href&sort=dcn>" . $locale->text('DCN') . "</a></th>";
  $column_data{paymentdiff} = "<th><a class=listheading href=$href&sort=paymentdiff>" . $locale->text('+/-') . "</a></th>";

  $column_data{curr} = "<th><a class=listheading href=$href&sort=curr>" . $locale->text('Curr') . "</a></th>";
  for (qw(amount tax netamount paid due)) { $column_data{"fx_$_"} = "<th>&nbsp;</th>" }

  $column_data{department} = "<th><a class=listheading href=$href&sort=department>" . $locale->text('Department') . "</a></th>";
  
  $column_data{accno} = "<th><a class=listheading href=$href&sort=accno>" . $locale->text('Account') . "</a></th>";
  $column_data{source} = "<th><a class=listheading href=$href&sort=source>" . $locale->text('Source') . "</a></th>";
  $column_data{debit} = "<th class=listheading>" . $locale->text('Debit') . "</th>";
  $column_data{credit} = "<th class=listheading>" . $locale->text('Credit') . "</th>";
  $column_data{projectnumber} = "<th><a class=listheading href=$href&sort=projectnumber>" . $locale->text('Project') . "</a></th>";
  $column_data{description} = "<th><a class=listheading href=$href&sort=description>" . $locale->text('Description') . "</a></th>";
  $column_data{memo} = "<th class=listheading>" . $locale->text('Line Item') . "</th>";

  $form->{title} = ($form->{title}) ? $form->{title} : $locale->text('AR Transactions');

  $form->{title} .= " / $form->{company}";

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

  for (@column_index) { print "\n$column_data{$_}" }

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
  
  # sums and tax on reports by Antonio Gallardo
  #
  $i = 0;
  foreach $ref (@{ $form->{transactions} }) {

    $i++;
    
    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&subtotal;
	$sameitem = $ref->{$form->{sort}};
      }
    }

    if ($form->{l_curr}) {
      for (qw(netamount amount paid)) { $ref->{"fx_$_"} = $ref->{$_}/$ref->{exchangerate} }

      for (qw(netamount amount paid)) { $column_data{"fx_$_"} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{"fx_$_"}, $form->{precision}, "&nbsp;")."</td>" }
      
      $column_data{fx_tax} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{fx_amount} - $ref->{fx_netamount}, $form->{precision}, "&nbsp;")."</td>";
      $column_data{fx_due} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{fx_amount} - $ref->{fx_paid}, $form->{precision}, "&nbsp;")."</td>";

      $subtotalfxnetamount += $ref->{fx_netamount};
      $subtotalfxamount += $ref->{fx_amount};
      $subtotalfxpaid += $ref->{fx_paid};
      
      $totalfxnetamount += $ref->{fx_netamount};
      $totalfxamount += $ref->{fx_amount};
      $totalfxpaid += $ref->{fx_paid};
      
    }
    
    $column_data{runningnumber} = "<td align=right>$i</td>";

    for (qw(netamount amount paid debit credit)) { $column_data{$_} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}, "&nbsp;")."</td>" }
    
    $column_data{tax} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} - $ref->{netamount}, $form->{precision}, "&nbsp;")."</td>";
    $column_data{due} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} - $ref->{paid}, $form->{precision}, "&nbsp;")."</td>";
    
    
    $subtotalnetamount += $ref->{netamount};
    $subtotalamount += $ref->{amount};
    $subtotalpaid += $ref->{paid};
    $subtotaldebit += $ref->{debit};
    $subtotalcredit += $ref->{credit};
    
    $totalnetamount += $ref->{netamount};
    $totalamount += $ref->{amount};
    $totalpaid += $ref->{paid};
    $totaldebit += $ref->{debit};
    $totalcredit += $ref->{credit};
    
    $module = ($ref->{invoice}) ? ($form->{ARAP} eq 'AR') ? "is.pl" : "ir.pl" : $form->{script};
    $module = ($ref->{till}) ? "ps.pl" : $module;

    $column_data{invnumber} = "<td><a href=$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{invnumber}&nbsp;</a></td>";
    
    for (qw(notes description memo)) { $ref->{$_} =~ s/\r?\n/<br>/g }
    for (qw(transdate datepaid duedate)) { $column_data{$_} = "<td nowrap>$ref->{$_}&nbsp;</td>" }
    for (qw(department ordnumber ponumber notes warehouse shippingpoint shipvia waybill employee manager till source memo description projectnumber address dcn paymentmethod)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
    $column_data{$namefld} = "<td>$ref->{$namefld}&nbsp;</td>";
    
    if ($ref->{paymentdiff} <= 0) {
      $column_data{paymentdiff} = qq|<td class="plus1" align=right>$ref->{paymentdiff}&nbsp;</td>|;
    } else {
      $column_data{paymentdiff} = qq|<td class="plus0" align=right>+$ref->{paymentdiff}&nbsp;</td>|;
    }

    for (qw(id curr)) { $column_data{$_} = "<td>$ref->{$_}</td>" }

    $column_data{accno} = qq|<td><a href=ca.pl?path=$form->{path}&login=$form->{login}&action=list_transactions&accounttype=standard&accno=$ref->{accno}&fromdate=$form->{transdatefrom}&todate=$form->{transdateto}&sort=transdate&l_subtotal=$form->{l_subtotal}&prevreport=$callback>$ref->{accno}</a></td>|;
    
    $column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{"$form->{vc}_id"}&db=$form->{vc}&callback=$callback>$ref->{name}</a></td>|;
   
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
  
  $column_data{netamount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalnetamount, $form->{precision}, "&nbsp;")."</th>";
  $column_data{tax} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount - $totalnetamount, $form->{precision}, "&nbsp;")."</th>";
  $column_data{amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount, $form->{precision}, "&nbsp;")."</th>";
  $column_data{paid} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalpaid, $form->{precision}, "&nbsp;")."</th>";
  $column_data{due} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount - $totalpaid, $form->{precision}, "&nbsp;")."</th>";
  $column_data{debit} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totaldebit, $form->{precision}, "&nbsp;")."</th>";
  $column_data{credit} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalcredit, $form->{precision}, "&nbsp;")."</th>";

  if ($form->{l_curr} && $form->{sort} eq 'curr' && $form->{l_subtotal}) {
    $column_data{fx_netamount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxnetamount, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_tax} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxamount - $totalfxnetamount, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxamount, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_paid} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxpaid, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_due} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxamount - $totalfxpaid, $form->{precision}, "&nbsp;")."</th>";
  }

  for (@column_index) { print "\n$column_data{$_}" }

  if ($myconfig{acs} !~ /$form->{ARAP}--$form->{ARAP}/) {
    $i = 1;
    if ($form->{ARAP} eq 'AR') {
      $button{'AR--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('AR Transaction').qq|"> |;
      $button{'AR--Add Transaction'}{order} = $i++;
      $button{'AR--Sales Invoice'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Sales Invoice.').qq|"> |;
      $button{'AR--Sales Invoice'}{order} = $i++;
    } else {
      $button{'AP--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('AP Transaction').qq|"> |;
      $button{'AP--Add Transaction'}{order} = $i++;
      $button{'AP--Vendor Invoice'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Vendor Invoice.').qq|"> |;
      $button{'AP--Vendor Invoice'}{order} = $i++;
    }

    foreach $item (split /;/, $myconfig{acs}) {
      delete $button{$item};
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

  $form->hide_form("$form->{vc}", "$form->{vc}_id");
  $form->hide_form(qw(callback path login));
  
  if (! $form->{till}) {
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


sub subtotal {

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $column_data{tax} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount - $subtotalnetamount, $form->{precision}, "&nbsp;")."</th>";
  $column_data{amount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount, $form->{precision}, "&nbsp;")."</th>";
  $column_data{paid} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalpaid, $form->{precision}, "&nbsp;")."</th>";
  $column_data{due} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount - $subtotalpaid, $form->{precision}, "&nbsp;")."</th>";
  $column_data{debit} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotaldebit, $form->{precision}, "&nbsp;")."</th>";
  $column_data{credit} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalcredit, $form->{precision}, "&nbsp;")."</th>";

  if ($form->{l_curr} && $form->{sort} eq 'curr' && $form->{l_subtotal}) {
    $column_data{fx_tax} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxamount - $subtotalfxnetamount, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_amount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxamount, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_paid} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxpaid, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_due} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxmount - $subtotalfxpaid, $form->{precision}, "&nbsp;")."</th>";
  }
  
  $subtotalnetamount = 0;
  $subtotalamount = 0;
  $subtotalpaid = 0;
  $subtotaldebit = 0;
  $subtotalcredit = 0;
  
  $subtotalfxnetamount = 0;
  $subtotalfxamount = 0;
  $subtotalfxpaid = 0;
 
  print "<tr class=listsubtotal>";

  for (@column_index) { print "\n$column_data{$_}" }

print "
</tr>
";
 
}

