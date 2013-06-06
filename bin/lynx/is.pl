#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Inventory invoicing module
#
#======================================================================


use SL::IS;
use SL::PE;

require "$form->{path}/arap.pl";
require "$form->{path}/io.pl";


1;
# end of main



sub add {

  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&login=$form->{login}&path=$form->{path}" unless $form->{callback};

  &invoice_links;
  &prepare_invoice;
  &display_form;
  
}


sub edit {
  
  $form->{shipto} = 1;
  &invoice_links;
  &prepare_invoice;
  &display_form;
  
}


sub generate {

  $form->{callback} = "$form->{script}?action=generate&type=$form->{type}&login=$form->{login}&path=$form->{path}" unless $form->{callback};

  $form->{generate} = 1;
  
  &invoice_links;
  &prepare_invoice;

  for (qw(notes department)) { delete $form->{$_} }
  $form->{currency} = $form->{defaultcurrency};

  &display_form;
  
}


sub invoice_links {

  $form->{vc} = "customer";
  $readonly = $form->{readonly};
  
  # create links
  $form->create_links("AR", \%myconfig, "customer", 1);

  $form->{readonly} ||= $readonly;

  $form->{selectprinter} = "";
  for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" }
  chop $form->{selectprinter};

  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};

  for (@curr) { $form->{selectcurrency} .= "$_\n" }

  if (@{ $form->{"all_$form->{vc}"} }) {
    unless ($form->{"$form->{vc}_id"}) {
      $form->{"$form->{vc}_id"} = $form->{"all_$form->{vc}"}->[0]->{id};
    }
  }

  if (! $form->{generate}) {
    AA->get_name(\%myconfig, \%$form);
    delete $form->{notes};
    IS->retrieve_invoice(\%myconfig, \%$form);
  }

  $ml = ($form->{type} eq 'invoice') ? 1 : -1;
  $ml = 1 if $form->{type} eq 'pos_invoice';

  $form->{oldlanguage_code} = $form->{language_code};

  $l{language_code} = $form->{language_code};
  $l{searchitems} = 'nolabor';
  $l{all} = 1 if $form->{type} eq 'credit_invoice';
  $l{parentgroup} = 1;
  $l{pos} = 1;
  
  $form->get_partsgroup(\%myconfig, \%l);
  
  if (@{ $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = "\n";
    foreach $ref (@ { $form->{all_partsgroup} }) {
      if ($ref->{translation}) {
	$form->{selectpartsgroup} .= qq|$ref->{translation}--$ref->{id}\n|;
      } else {
	$form->{selectpartsgroup} .= qq|$ref->{partsgroup}--$ref->{id}\n|;
      }
    }
  }
  
  if (@{ $form->{all_project} }) {
    $form->{selectprojectnumber} = "\n";
    for (@{ $form->{all_project} }) { $form->{selectprojectnumber} .= qq|$_->{projectnumber}--$_->{id}\n| }
  }

  $form->{"old$form->{vc}"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
  $form->{"old$form->{vc}number"} = $form->{"$form->{vc}number"};
  for (qw(transdate duedate)) { $form->{"old$_"} = $form->{$_} }
  
  if ($form->{generate}) {
    $form->{"select$form->{vc}"} = "\n";
    $form->{"old$form->{vc}"} = "";
    $form->{"old$form->{vc}number"} = "";
  } else {
    $form->{"select$form->{vc}"} = "";
    if (@{ $form->{"all_$form->{vc}"} }) {
      $form->{$form->{vc}} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
      for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|$_->{name}--$_->{id}\n| }
    }
  }
  
  # departments
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "\n";
    $form->{department} = "$form->{department}--$form->{department_id}" if $form->{department_id};

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|$_->{description}--$_->{id}\n| }
  }

  # warehouses
  if (@{ $form->{all_warehouse} }) {
    $form->{selectwarehouse} = "\n"; 
    $form->{warehouse} = "$form->{warehouse}--$form->{warehouse_id}" if $form->{warehouse_id};

    for (@{ $form->{all_warehouse} }) { $form->{selectwarehouse} .= qq|$_->{description}--$_->{id}\n| }
  }

  $form->{employee} = "$form->{employee}--$form->{employee_id}";
  # sales staff
  if (@{ $form->{all_employee} }) {
    $form->{selectemployee} = "\n";
    for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }
  }
  
  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }

  $form->{roundchange} = "=$form->{roundchange}";

  # paymentmethod
  if (@{ $form->{all_paymentmethod} }) {
    $form->{selectpaymentmethod} = "\n"; 
    for (@{ $form->{all_paymentmethod} }) {
      $form->{selectpaymentmethod} .= qq|$_->{description}--$_->{id}\n|;
      if ($_->{roundchange}) {
	$form->{roundchange} .= ";$_->{description}--$_->{id}=$_->{roundchange}";
      }
    }
  }

  # reference documents
  $i = 0;
  for (@{ $form->{all_reference} }) {
    $i++;
    $form->{"referencedescription_$i"} = $_->{description};
    $form->{"referenceid_$i"} = $_->{id};
  }
  $form->{reference_rows} = $i;

  $form->{"select$form->{vc}"} = $form->escape($form->{"select$form->{vc}"},1);
  for (qw(currency partsgroup projectnumber department warehouse employee language paymentmethod printer)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }
  $form->{roundchange} = $form->escape($form->{roundchange},1);

  
  foreach $key (keys %{ $form->{AR_links} }) {

    $form->{"select$key"} = "";
    foreach $ref (@{ $form->{AR_links}{$key} }) {
      $form->{"select$key"} .= "$ref->{accno}--$ref->{description}\n";
    }
    $form->{"select$key"} = $form->escape($form->{"select$key"},1);

    if ($key eq "AR_paid") {
      for $i (1 .. scalar @{ $form->{acc_trans}{$key} }) {
	$form->{"AR_paid_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
	# reverse paid
	$form->{"paid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{amount} * -1 * $ml;
	$form->{"datepaid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{transdate};
	$form->{"olddatepaid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{transdate};
	$form->{"exchangerate_$i"} = $form->{acc_trans}{$key}->[$i-1]->{exchangerate};
	$form->{"source_$i"} = $form->{acc_trans}{$key}->[$i-1]->{source};
	$form->{"memo_$i"} = $form->{acc_trans}{$key}->[$i-1]->{memo};
	$form->{"cleared_$i"} = $form->{acc_trans}{$key}->[$i-1]->{cleared};
	$form->{"vr_id_$i"} = $form->{acc_trans}{$key}->[$i-1]->{vr_id};
	$form->{"paymentmethod_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{paymentmethod}--$form->{acc_trans}{$key}->[$i-1]->{paymentmethod_id}";
	
	$form->{paidaccounts} = $i;
      }
    } elsif ($key eq "AR_discount") {
      
      $form->{"AR_discount_paid"} = "$form->{acc_trans}{$key}->[0]->{accno}--$form->{acc_trans}{$key}->[0]->{description}";
      $form->{"discount_paid"} = $form->{acc_trans}{$key}->[0]->{amount} * -1 * $ml;
      $form->{"discount_datepaid"} = $form->{acc_trans}{$key}->[0]->{transdate};
      $form->{"olddiscount_datepaid"} = $form->{acc_trans}{$key}->[0]->{transdate};
      $form->{"discount_source"} = $form->{acc_trans}{$key}->[0]->{source};
      $form->{"discount_memo"} = $form->{acc_trans}{$key}->[0]->{memo};
      $form->{"discount_exchangerate"} = $form->{acc_trans}{$key}->[0]->{exchangerate};
      $form->{"discount_cleared"} = $form->{acc_trans}{$key}->[0]->{cleared};
      $form->{"discount_paymentmethod"} = "$form->{acc_trans}{$key}->[0]->{paymentmethod_id}--$form->{acc_trans}{$key}->[0]->{paymentmethod}";

    } else {
      $form->{$key} = "$form->{acc_trans}{$key}->[0]->{accno}--$form->{acc_trans}{$key}->[0]->{description}" if $form->{acc_trans}{$key}->[0]->{accno};
    }
    
  }

  for (qw(AR_links acc_trans)) { delete $form->{$_} }

  for (qw(payment discount)) { $form->{"${_}_accno"} = $form->escape($form->{"${_}_accno"},1) }
  $form->{payment_method} = $form->escape($form->{payment_method}, 1);

  $form->{exchangerate} ||= 1;
  $form->{cd_available} = $form->round_amount($form->{netamount} * $form->{cashdiscount} / $form->{exchangerate}, $form->{precision});
  $form->{cashdiscount} *= 100;

  $form->{paidaccounts} ||= 1;

  $form->{AR} ||= $form->{AR_1};

  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum(\%myconfig, $form->{transdate}) <= $form->{closedto});

  if (! $form->{readonly}) {
    $form->{readonly} = 1 if $myconfig{acs} =~ /AR--Sales Invoice/ && $form->{type} eq 'invoice';
    $form->{readonly} = 1 if $myconfig{acs} =~ /AR--Sales Invoice/ && $form->{type} eq 'credit_invoice';
  }

  if ($form->{id}) {
    %title = ( invoice => $locale->text('Edit Sales Invoice'),
               pos_invoice => $locale->text('Edit POS Invoice'),
	       credit_invoice => $locale->text('Edit Credit Invoice')
	     );
  } else {
    %title = ( invoice => $locale->text('Add Sales Invoice'),
               pos_invoice => $locale->text('Add POS Invoice'),
	       credit_invoice => $locale->text('Add Credit Invoice')
	     );

    if ($form->{generate}) {
      %title = ( invoice => $locale->text('Generate Sales Invoices')
               );
    }
  }
  $form->{title} = $title{$form->{type}};

}


sub prepare_invoice {

  $form->{type} ||= "invoice";
  $form->{formname} ||= "invoice";
  $form->{sortby} ||= "runningnumber";
  $form->{format} ||= $myconfig{outputformat};
  $form->{copies} ||= 1;
  
  if ($myconfig{printer}) {
    $form->{format} ||= "ps";
  }
  $form->{media} ||= $myconfig{printer};

  $ml = 1;

  $form->helpref($form->{type}, $myconfig{countrycode});

  if ($form->{type} eq 'invoice') {
    $form->{selectformname} = qq|invoice--|.$locale->text('Invoice')
.qq|\npick_list--|.$locale->text('Pick List')
.qq|\npacking_list--|.$locale->text('Packing List')
.qq|\nbarcode--|.$locale->text('Barcode');
    $form->{selectformname} .= qq|\nremittance_voucher--|.$locale->text('Remittance Voucher') if $form->{remittancevoucher};

    $generate = ($form->{generate}) ? "generate_" : "";
    $form->helpref("${generate}sales_invoice", $myconfig{countrycode});
    
  }
  if ($form->{type} eq 'credit_invoice') {
    $ml = -1;
    $form->{selectformname} = qq|credit_invoice--|.$locale->text('Credit Invoice')
.qq|\nbin_list--|.$locale->text('Bin List')
.qq|\nbarcode--|.$locale->text('Barcode');
  }
  
  $i = 1;
  $form->{currency} =~ s/ //g;
  $form->{oldcurrency} = $form->{currency};
  
  if ($form->{id}) {
    
    for (qw(invnumber ordnumber ponumber quonumber shippingpoint shipvia waybill notes intnotes)) { $form->{$_} = $form->quote($form->{$_}) }

    foreach $ref (@{ $form->{invoice_details} } ) {
      for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }

      $form->{"projectnumber_$i"} = qq|$ref->{projectnumber}--$ref->{project_id}| if $ref->{project_id};
      $form->{"partsgroup_$i"} = qq|$ref->{partsgroup}--$ref->{partsgroup_id}| if $ref->{partsgroup_id};

      $form->{"discount_$i"} = $form->format_amount(\%myconfig, $form->{"discount_$i"} * 100);

      for (qw(netweight grossweight volume)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }

      ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

      $form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces);
      $form->{"qty_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"} * $ml);
      $form->{"oldqty_$i"} = $form->{"qty_$i"};
      
      for (qw(partnumber sku description unit)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }
      $form->{rowcount} = $i;
      $i++;
    }
  }

  $focus = "partnumber_$i";
  
  $form->{selectformname} = $form->escape($form->{selectformname},1);
  
}



sub form_header {


  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

  $exchangerate = "";

  if ($form->{defaultcurrency}) {
    $exchangerate = qq|<tr>
		<th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td>
		  <table>
		    <tr>
		    
		      <td><select name=currency onChange="javascript:document.forms[0].submit()">|
		.$form->select_option($form->{selectcurrency}, $form->{currency})
		.qq|</select></td>|;

    if ($form->{currency} ne $form->{defaultcurrency}) {
      $fdm = $form->dayofmonth($myconfig{dateformat}, $form->{transdate}, 'fdm');
      $ldm = $form->dayofmonth($myconfig{dateformat}, $form->{transdate});
      
      $exchangerate .= qq|
	      <th align=right nowrap>|.$locale->text('Exchange Rate').qq| <font color=red>*</font></th>
	      <td nowrap><input name="exchangerate" class="inputright" size="10" value="$form->{exchangerate}">
	          <a href=am.pl?action=list_exchangerates&transdatefrom=$fdm&transdateto=$ldm&currency=$form->{currency}&login=$form->{login}&path=$form->{path} target=_blank>?</a></td>|;
    }
    $exchangerate .= qq|</tr></table></td></tr>
|;
  }

  $vcname = $locale->text('Customer');
  $vcnumber = $locale->text('Customer Number');

  $vcref = qq|<a href=ct.pl?action=edit&db=$form->{vc}&id=$form->{"$form->{vc}_id"}&login=$form->{login}&path=$form->{path} target=_blank>?</a>|;

  $vc = qq|<input type="hidden" name="action" value="update">
              <tr>
	        <th align=right nowrap>$vcname <font color=red>*</font></th>
|;

  if ($form->{"select$form->{vc}"}) {
    $vc .= qq|
                <td nowrap><select name="$form->{vc}" onChange="javascript:document.forms[0].submit()">|.$form->select_option($form->{"select$form->{vc}"}, $form->{$form->{vc}}, 1).qq|</select>
		$vcref
		</td>
	      </tr>
	      <tr>
	        <th align=right nowrap>$vcnumber</th>
		<td>$form->{"$form->{vc}number"}</td>
	      </tr>
| . $form->hide_form("$form->{vc}number");
  } else {
    $vc .= qq|
                <td nowrap><input name="$form->{vc}" value="|.$form->quote($form->{$form->{vc}}).qq|" size="35">
		$vcref
		</td>
	      </tr>
	      <tr>
	        <th align=right nowrap>$vcnumber</th>
		<td><input name="$form->{vc}number" value="$form->{"$form->{vc}number"}" size="35"></td>
	      </tr>
|;
  }
  
  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td><select name=department>|
		.$form->select_option($form->{selectdepartment}, $form->{department}, 1)
		.qq|</select>
		</td>
	      </tr>
| if $form->{selectdepartment};

  $warehouse = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Warehouse').qq|</th>
		<td><select name=warehouse>|
		.$form->select_option($form->{selectwarehouse}, $form->{warehouse}, 1).qq|
		</select>
		</td>
	      </tr>
| if $form->{selectwarehouse};


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

  $employee = $form->hide_form(qw(employee));

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
    $description = qq|<input name="description" size="60" value="|.$form->quote($form->{description}).qq|">|;
  }
  $description = qq|
 	      <tr valign=top>
		<th align=right nowrap>|.$locale->text('Description').qq|</th>
		<td>$description</td>
	      </tr>
|;

  $dcn = qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('DCN').qq|</th>
	  <td>|.$form->quote($form->{dcn}).qq|</td>
	</tr>
|;

  $reference_documents = &reference_documents;
  
  %title = ( pick_list => $locale->text('Pick List'),
	     packing_list => $locale->text('Packing List'),
	     bin_list => $locale->text('Bin List')
	   );

  if ($form->{pricegroup}) {
    $pricegroup = qq|
              <tr>
                <th align=right nowrap>|.$locale->text('Pricegroup').qq|</th>
		<td>$form->{pricegroup}</td>
              </tr>
|;
  }

  if ($form->{generate}) {

    $vc = qq|<input type="hidden" name="action" value="update">|;
    $creditlimit = "";
    $pricegroup = "";
    $address = "";

  } else {

    $address = qq|
	      <tr>
	        <th align=right nowrap>|.$locale->text('Address').qq|</th>
		<td>$form->{address1} $form->{address2} $form->{zipcode} $form->{city} $form->{state} $form->{country}</td>
	      </tr>
|;

    $creditlimit = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Credit Limit').qq|</th>
		<td>
		  <table>
		    <tr>
		      <td>|.$form->format_amount(\%myconfig, $form->{creditlimit}, 0, "0").qq|</td>
		      <td width=10></td>
		      <th align=right nowrap>|.$locale->text('Remaining').qq|</th>
		      <td class="plus$n">|.$form->format_amount(\%myconfig, $form->{creditremaining}, 0, "0").qq|</td>
		    </tr>
		  </table>
		</td>
	      </tr>
|;

    if ($form->{formname} !~ /invoice/) {
      $title = " / $title{$form->{formname}}";
    }
  }

  for (qw(terms discountterms)) { $form->{$_} = "" if ! $form->{$_} }

  $form->{onhold} = ($form->{onhold}) ? "checked" : "";


  $form->header;

  print qq|
<body onLoad="document.forms[0].${focus}.focus()" />

<form method=post action="$form->{script}">
|;

  $form->hide_form(qw(id type printed emailed queued title vc discount creditlimit creditremaining tradediscount business closedto locked shipped oldtransdate oldduedate recurring defaultcurrency oldterms cdt precision order_id remittancevoucher reference_rows referenceurl));

  $form->hide_form(map { "select$_" } ("$form->{vc}", "AR", "AR_paid", "AR_discount"));
  $form->hide_form(map { "select$_" } qw(formname currency partsgroup projectnumber department warehouse employee language paymentmethod printer));
  $form->hide_form("$form->{vc}_id", "old$form->{vc}", "quonumber", "old$form->{vc}number");
  
  $terms = qq|
  	      <tr>
	        <th align="right" nowrap>|.$locale->text('Terms').qq|</th>
		<th align=left nowrap>
		|.$locale->text('Net').qq|
		<input name="terms" class="inputright" size="3" value="$form->{terms}"> |.$locale->text('days').qq|
		</th>
	      </tr>
|;

  if ($form->{type} !~ /credit_/) {

    if ($form->{"selectAR_discount"}) {
      $terms = qq|
  	      <tr>
	        <th align="right" nowrap>|.$locale->text('Terms').qq|</th>
		<th align=left nowrap>
		<input name="cashdiscount" class="inputright" size="3" value="|.$form->format_amount(\%myconfig, $form->{cashdiscount}).qq|"> /  
		<input name="discountterms" class="inputright" size="3" value="$form->{discountterms}"> |.$locale->text('Net').qq|
		<input name="terms" class="inputright" size="3" value="$form->{terms}"> |.$locale->text('days').qq|
		</th>
	      </tr>
|;
    }
  }

  print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{helpref}$form->{title}$title</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr valign=top>
	  <td>
	    <table>
	      $vc
	      $address
	      $creditlimit
	      $business
	      <tr>
		<th align=right nowrap>|.$locale->text('Record in').qq|</th>
		<td><select name=AR>|
		.$form->select_option($form->{selectAR}, $form->{AR})
		.qq|</select>
		</td>
	      </tr>
	      $exchangerate
	      $warehouse
	      <tr>
		<th align=right nowrap>|.$locale->text('Shipping Point').qq|</th>
		<td><input name="shippingpoint" size="35" value="|.$form->quote($form->{shippingpoint}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Ship via').qq|</th>
		<td><input name="shipvia" size="35" value="|.$form->quote($form->{shipvia}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Waybill').qq|</th>
		<td><input name="waybill" size="35" value="|.$form->quote($form->{waybill}).qq|"></td>
	      </tr>
	      <tr>
	        <td align=right><input name="onhold" type="checkbox" class="checkbox" value="1" $form->{onhold}></td>
		<th align=left nowrap>|.$locale->text('On Hold').qq|</font></th>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $department
	      $employee
	      <tr>
		<th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
		<td><input name="invnumber" size="20" value="|.$form->quote($form->{invnumber}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Order Number').qq|</th>
		<td><input name="ordnumber" size="20" value="|.$form->quote($form->{ordnumber}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Invoice Date').qq| <font color=red>*</font></th>
		<td><input name="transdate" size="11" class="date" title="$myconfig{dateformat}" value="$form->{transdate}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Due Date').qq|</th>
		<td><input name="duedate" size="11" class="date" title="$myconfig{dateformat}" value="$form->{duedate}"></td>
	      </tr>
	      $terms
	      <tr>
		<th align=right nowrap>|.$locale->text('PO Number').qq|</th>
		<td><input name="ponumber" size="20" value="|.$form->quote($form->{ponumber}).qq|"></td>
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
	  <td colspan=2>
	    $reference_documents
	  </td>
	</tr>
        $dcn
	$description
      </table>
  </td>
</tr>
|;

  $form->hide_form(map { "shipto$_" } qw(name address1 address2 city state zipcode country contact phone fax email));
  $form->hide_form(qw(address1 address2 city state zipcode country message email subject cc bcc taxaccounts dcn pricegroup));
  
  foreach $accno (split / /, $form->{taxaccounts}) { $form->hide_form(map { "${accno}_$_" } qw(rate description taxnumber)) }

}



sub form_footer {

  $form->{invtotal} = $form->{invsubtotal};

  if (($rows = $form->numtextrows($form->{notes}, 35, 8)) < 2) {
    $rows = 2;
  }
  if (($introws = $form->numtextrows($form->{intnotes}, 35, 8)) < 2) {
    $introws = 2;
  }
  $rows = ($rows > $introws) ? $rows : $introws;
  $notes = qq|<textarea name=notes rows=$rows cols=35 wrap=soft>$form->{notes}</textarea>|;
  $intnotes = qq|<textarea name=intnotes rows=$rows cols=35 wrap=soft>$form->{intnotes}</textarea>|;

  $form->{taxincluded} = ($form->{taxincluded}) ? "checked" : "";

  $taxincluded = "";
  if ($form->{taxaccounts}) {
    $taxincluded = qq|
              <tr height="5"></tr>
              <tr>
	        <td align=right><input name="taxincluded" class="checkbox" type="checkbox" value="1" $form->{taxincluded}></td>
		<th align=left>|.$locale->text('Tax Included').qq|</th>
	     </tr>
|;
  }
  
  $form->hide_form("cd_available");

  for (split / /, $form->{taxaccounts}) {
    
    if (!$form->{taxincluded}) {

      if ($form->{"${_}_base"}) {

	$form->{"${_}_total"} = $form->round_amount($form->round_amount($form->{"${_}_base"} * $form->{"${_}_rate"}, 10), $form->{precision});

	if ($form->{discount_paid} && $form->{cdt}) {
	  $cdtp = $form->{discount_paid} / $form->{invsubtotal} if $form->{invsubtotal};
	  $form->{"${_}_total"} -= $form->round_amount($form->{"${_}_total"} * $cdtp, $form->{precision});
	}

	$form->{invtotal} += $form->{"${_}_total"};
      
	$tax .= qq|
	      <tr>
		<th align=right>$form->{"${_}_description"}</th>
		<td align=right>|.$form->format_amount(\%myconfig, $form->{"${_}_total"}, $form->{precision}).qq|</td>
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

  if ($form->{discount_paid}) {
    $discount_paid = qq|
	      <tr>
		<th align=right>|.$locale->text('Discount').qq|</th>
		<td align=right>|.$form->format_amount(\%myconfig, $form->{discount_paid} * -1, $form->{precision}, 0).qq|</td>
	      </tr>
|;
  }

  $form->{invtotal} -= $form->{discount_paid};

  if ($form->{currency} eq $form->{defaultcurrency}) {
    @column_index = qw(datepaid source memo paid);
  } else {
    @column_index = qw(datepaid source memo paid exchangerate);
  }
  push @column_index, "paymentmethod" if $form->{selectpaymentmethod};
  push @column_index, "AR_paid";

  $form->{oldinvtotal} = $form->{invtotal};
  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, $form->{precision}, 0);

  $column_data{datepaid} = "<th>".$locale->text('Date')."</th>";
  $column_data{paid} = "<th>".$locale->text('Amount')."</th>";
  $column_data{exchangerate} = "<th>".$locale->text('Exch')."</th>";
  $column_data{AR_paid} = "<th>".$locale->text('Account')."</th>";
  $column_data{source} = "<th>".$locale->text('Source')."</th>";
  $column_data{memo} = "<th>".$locale->text('Memo')."</th>";
  $column_data{paymentmethod} = "<th>".$locale->text('Method')."</th>";
  
  $cashdiscount = "";
  if ($form->{cashdiscount}) {
    $cashdiscount = qq|
 	      <tr>
	        <td><b>|.$locale->text('Cash Discount').qq|:</b> |
		.$form->format_amount(\%myconfig, $form->{cd_available}, $form->{precision}, 0).qq|</td>
	      </tr>

  <tr class=listheading>
    <th class=listheading>|.$locale->text('Cash Discount').qq|</th>
  </tr>

  <tr>
    <td>
      <table width=100%>
        <tr>
|;

    for (@column_index) { $cashdiscount .= qq|$column_data{$_}\n| }

    $cashdiscount .= qq|
        </tr>
|;

    $exchangerate = qq|&nbsp;|;
    if ($form->{currency} ne $form->{defaultcurrency}) {
      $form->{discount_exchangerate} = $form->format_amount(\%myconfig, $form->{discount_exchangerate});
      $exchangerate = qq|<input name="discount_exchangerate" class="inputright" size="10" value="$form->{discount_exchangerate}">|.$form->hide_form(qw(olddiscount_datepaid));
    }

    $column_data{paid} = qq|<td align=center><input name="discount_paid" class="inputright" size="11" value="|.$form->format_amount(\%myconfig, $form->{"discount_paid"}, $form->{precision}).qq|"></td>|;
    $column_data{AR_paid} = qq|<td align=center><select name="AR_discount_paid">|.$form->select_option($form->{"selectAR_discount"}, $form->{"AR_discount_paid"}).qq|</select></td>|;
    $column_data{datepaid} = qq|<td align=center><input name="discount_datepaid" size="11" class="date" value="$form->{"discount_datepaid"}"></td>|;
    $column_data{exchangerate} = qq|<td align=center>$exchangerate</td>|;
    $column_data{source} = qq|<td align=center><input name="discount_source" size="11" value="|.$form->quote($form->{"discount_source"}).qq|"></td>|;
    $column_data{memo} = qq|<td align=center><input name="discount_memo" size="11" value="|.$form->quote($form->{"discount_memo"}).qq|"></td>|;

    if ($form->{selectpaymentmethod}) {
      $column_data{paymentmethod} = qq|<td align=center><select name="discount_paymentmethod">|.$form->select_option($form->{"selectpaymentmethod"}, $form->{discount_paymentmethod}, 1).qq|</select></td>|;
    }
    
    $cashdiscount .= qq|
        <tr>
|;

    for (@column_index) { $cashdiscount .= qq|$column_data{$_}\n| }

    $cashdiscount .= qq|
          </tr>
|
    .$form->hide_form(map { "discount_$_" } qw(vr_id cleared));
    
    $payments = qq|
    <tr class=listheading>
      <th class=listheading colspan=7>|.$locale->text('Payments').qq|</th>
    </tr>
|;

  } else {
    $payments = qq|
    <tr class=listheading>
      <th class=listheading colspan=7>|.$locale->text('Payments').qq|</th>
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
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr valign=bottom>
	  <td>
	    <table>
	      <tr>
		<th align=left>|.$locale->text('Notes').qq|</th>
		<th align=left>|.$locale->text('Internal Notes').qq|</th>
	      </tr>
	      <tr valign=top>
		<td>$notes</td>
		<td>$intnotes</td>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $taxincluded
	      $subtotal
	      $discount_paid
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

  $cashdiscount
  $payments
|;

  $form->{paidaccounts}++ if ($form->{"paid_$form->{paidaccounts}"});
  $form->{"AR_paid_$form->{paidaccounts}"} = $form->unescape($form->{payment_accno});
  $form->{"paymentmethod_$form->{paidaccounts}"} = $form->unescape($form->{payment_method});
 
  $roundto = 0;
  if ($form->{roundchange}) {
    %roundchange = split /[=;]/, $form->unescape($form->{roundchange});
    $roundto = $roundchange{''};
  }
  
  $totalpaid = 0;    

  for $i (1 .. $form->{paidaccounts}) {

    print "
        <tr>\n";

    # format amounts
    $totalpaid += $form->{"paid_$i"};
    
    $form->{"paid_$i"} = $form->format_amount(\%myconfig, $form->{"paid_$i"}, $form->{precision});
    $form->{"exchangerate_$i"} = $form->format_amount(\%myconfig, $form->{"exchangerate_$i"});

    $exchangerate = qq|&nbsp;|;
    if ($form->{currency} ne $form->{defaultcurrency}) {
      $exchangerate = qq|<input name="exchangerate_$i" class="inputright" size="10" value="$form->{"exchangerate_$i"}">|.$form->hide_form("olddatepaid_$i");
    }

    $form->hide_form(map { "${_}_$i" } qw(cleared vr_id));
    
    $column_data{paid} = qq|<td align=center><input name="paid_$i" class="inputright" size="11" value="$form->{"paid_$i"}"></td>|;
    $column_data{exchangerate} = qq|<td align=center>$exchangerate</td>|;
    $column_data{AR_paid} = qq|<td align=center><select name="AR_paid_$i">|.$form->select_option($form->{selectAR_paid}, $form->{"AR_paid_$i"}).qq|</select></td>|;
    $column_data{datepaid} = qq|<td align=center><input name="datepaid_$i" size="11" class="date" title="$myconfig{dateformat}" value="$form->{"datepaid_$i"}"></td>|;
    $column_data{source} = qq|<td align=center><input name="source_$i" size="11" value="|.$form->quote($form->{"source_$i"}).qq|"></td>|;
    $column_data{memo} = qq|<td align=center><input name="memo_$i" size="11" value="|.$form->quote($form->{"memo_$i"}).qq|"></td>|;

    if ($form->{selectpaymentmethod}) {

      if ($form->{"paymentmethod_$i"}) {
	if ($form->{"paid_$i"}) {
	  $roundto = $roundchange{$form->{"paymentmethod_$i"}};
	}
      }
      
      $column_data{paymentmethod} = qq|<td align=center><select name="paymentmethod_$i">|.$form->select_option($form->{"selectpaymentmethod"}, $form->{"paymentmethod_$i"}, 1).qq|</select></td>|;
    }

    for (@column_index) { print qq|$column_data{$_}\n| }
    print "
        </tr>\n";
  }

  $totalpaid = $form->round_amount($totalpaid, $form->{precision});

  if ($totalpaid == 0) {
    $roundto = $roundchange{$form->{"paymentmethod_$form->{paidaccounts}"}};
  }
  
  if ($roundto > 0.01) {
    $outstanding = $form->round_amount($form->{oldinvtotal} / $roundto, 0) * $roundto;
    $outstanding -= $totalpaid;
    $outstanding = $form->round_amount($outstanding / $roundto, 0) * $roundto;
  } else {
    $outstanding = $form->round_amount($form->{oldinvtotal} - $totalpaid, $form->{precision});
  }

  if ($outstanding) {
    if ($outstanding > 0) {
      print qq|
	<tr>
	  <td colspan=4><b>|.$locale->text('Outstanding').":</b> ".$form->format_amount(\%myconfig, $outstanding, $form->{precision}).qq|</td>
	</tr>
|;
    } else {
      print qq|
	<tr>
	  <td colspan=4><b>|.$locale->text('Overpaid').":</b> ".$form->format_amount(\%myconfig, $outstanding * -1, $form->{precision}).qq|</td>
	</tr>
|;
    }
  }
  
  $form->{oldtotalpaid} = $totalpaid;
  $form->hide_form(qw(paidaccounts oldinvtotal oldtotalpaid payment_accno payment_method roundchange cashovershort));
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
  <tr>
    <td>
|;

  &print_options if ! $form->{generate};

  print qq|
    </td>
  </tr>
</table>
<br>
|;


  $transdate = $form->datetonum(\%myconfig, $form->{transdate});

  if ($form->{readonly}) {

    &islocked;

  } else {

    if ($form->{generate}) {
      
     %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
                'Generate Invoices' => { ndx => 2, key => 'G', value => $locale->text('Generate Invoices') }
              );

    } else {
    
    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
	       'Preview' => { ndx => 3, key => 'V', value => $locale->text('Preview') },
	       'Print' => { ndx => 4, key => 'P', value => $locale->text('Print') },
	       'Post' => { ndx => 5, key => 'O', value => $locale->text('Post') },
	       'Ship to' => { ndx => 6, key => 'T', value => $locale->text('Ship to') },
	       'E-mail' => { ndx => 7, key => 'E', value => $locale->text('E-mail') },
	       'Print and Post' => { ndx => 8, key => 'R', value => $locale->text('Print and Post') },
	       'Post as new' => { ndx => 9, key => 'N', value => $locale->text('Post as new') },
	       'Print and Post as new' => { ndx => 10, key => 'W', value => $locale->text('Print and Post as new') },
	       'Sales Order' => { ndx => 11, key => 'L', value => $locale->text('Sales Order') },
	       'Schedule' => { ndx => 12, key => 'H', value => $locale->text('Schedule') },
	       'New Number' => { ndx => 13, key => 'M', value => $locale->text('New Number') },
	       'Delete' => { ndx => 14, key => 'D', value => $locale->text('Delete') },
	      );
    }

    if ($form->{id}) {
      
      delete $button{'Sales Order'} if $myconfig{acs} =~ /(Order Entry--Order Entry|Order Entry--Sales Order)/;
      
      if ($form->{locked} || $transdate <= $form->{closedto}) {
	for ("Post", "Print and Post", "Delete") { delete $button{$_} }
      }
     
      if (!$latex) {
	for ("Preview", "Print and Post", "Print and Post as new") { delete $button{$_} }
      }

    } else {

      if ($transdate > $form->{closedto}) {
	
	for ("Update", "Ship to", "Print", "E-mail", "Post", "Schedule", "New Number") { $ab{$_} = 1 }
	if ($latex) {
	  $ab{'Print and Post'} = 1;
	  $ab{'Preview'} = 1;
	}

	$ab{'Generate Invoices'} = 1 if $form->{generate};
	
      }
      for (keys %button) { delete $button{$_} if ! $ab{$_} }
    }
    
    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

  }

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  $form->hide_form(qw(helpref generate rowcount callback path login));
  
  print qq|
</form>

</body>
</html>
|;

}


sub update {

  for (qw(exchangerate cashdiscount discount_paid)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
  
  if ($newname = &check_name(customer)) {
    &rebuild_vc(customer, AR, $form->{transdate}, 1);
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
    &rebuild_vc(customer, AR, $form->{transdate}, 1) if ! $newname;

    $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate});
    $form->{oldcurrency} = $form->{currency};

    if (@{ $form->{all_employee} }) {
      $form->{selectemployee} = "\n";
      for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }
      $form->{selectemployee} = $form->escape($form->{selectemployee},1);
    }
  }

  $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}) if $form->{currency} ne $form->{oldcurrency};
  $form->{oldcurrency} = $form->{currency};

  $form->{discount_exchangerate} = "";
  
  if ($form->{discount_paid}) {
    if ($form->{discount_datepaid} ne $form->{olddiscount_datepaid} || $form->{currency} ne $form->{oldcurrency}) {
      if ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{discount_datepaid})) {
	$form->{discount_exchangerate} = $exchangerate;
      }
    }

    $expired = $form->add_date(\%myconfig, $form->{transdate}, $form->{discountterms}, 'days');
    if ($form->datetonum(\%myconfig, $form->{discount_datepaid}) > $form->datetonum(\%myconfig, $expired)) {
      $form->{discount_datepaid} = $expired;
    }
    $form->{olddiscount_datepaid} = $form->{discount_datepaid};
  }
  
  $totalpaid = $form->{discount_paid};
  
  $form->{payment_accno} = $form->escape($form->{"AR_paid_$form->{paidaccounts}"},1);
  $form->{payment_method} = $form->escape($form->{"paymentmethod_$form->{paidaccounts}"},1);
 
  $j = 1;
  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      for (qw(olddatepaid datepaid source memo cleared vr_id paymentmethod)) { $form->{"${_}_$j"} = $form->{"${_}_$i"} }
      for (qw(paid exchangerate)) { $form->{"${_}_$j"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }

      if ($form->{"datepaid_$j"} ne $form->{"olddatepaid_$j"} || $form->{currency} ne $form->{oldcurrency}) {
	if ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{"datepaid_$j"})) {
	  $form->{"exchangerate_$j"} = $exchangerate;
	}
      }
      
      $form->{"olddatepaid_$j"} = $form->{"datepaid_$j"};
      
      if ($j++ != $i) {
	for (qw(olddatepaid datepaid source memo cleared paid exchangerate vr_id paymentmethod)) { delete $form->{"${_}_$i"} }
      }
    } else {
      for (qw(olddatepaid datepaid source memo cleared paid exchangerate vr_id paymentmethod)) { delete $form->{"${_}_$i"} }
    }
  }

  $form->{paidaccounts} = $j;

  $i = $form->{rowcount};
  $form->{exchangerate} ||= 1;
    
  # if last row empty, check the form otherwise retrieve new item
  if (($form->{"partnumber_$i"} eq "") && ($form->{"description_$i"} eq "") && ($form->{"partsgroup_$i"} eq "" && $form->{"partsgroupcode_$i"} eq "")) {

    &check_form;

  } else {

    IS->retrieve_item(\%myconfig, \%$form);
  
    $rows = scalar @{ $form->{item_list} };

    if ($form->{language_code} && $rows == 0) {
      $language_code = $form->{language_code};
      $form->{language_code} = "";
      
      IS->retrieve_item(\%myconfig, \%$form);
      
      $form->{language_code} = $language_code;
      $rows = scalar @{ $form->{item_list} };
    }

    if ($form->{rebuildpartsgroup}) {
     ######### pos
     $form->{lookup} = "";
      for (@{ $form->{all_partsgroup} }) {
	if ($_->{pos}) {
	  $form->{lookup} .= "\n$_->{partsgroup}--$_->{translation}--$_->{image}";
	}
      }
    }

    if ($rows) {
      
      if ($rows > 1) {
	
	&select_item;
	exit;
	
      } else {

	$form->{"qty_$i"} = ($form->{"qty_$i"} * 1) ? $form->{"qty_$i"} : 1;

	$sellprice = $form->parse_amount(\%myconfig, $form->{"sellprice_$i"});

        for (qw(partnumber description unit)) { $form->{item_list}[$i]{$_} = $form->quote($form->{item_list}[$i]{$_}) }

	for (keys %{ $form->{item_list}[0] }) {
	  $form->{"${_}_$i"} = $form->{item_list}[0]{$_};
	}

	$form->{"discount_$i"} ||= $form->{discount} * 100;

	if ($sellprice) {
	  $form->{"sellprice_$i"} = $sellprice;
	  
	  ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
	  $dec = length $dec;
	  $decimalplaces1 = ($dec > $form->{precision}) ? $dec : $form->{precision};
	} else {
	  ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
	  $dec = length $dec;
	  $decimalplaces1 = ($dec > $form->{precision}) ? $dec : $form->{precision};
	  
	  $form->{"sellprice_$i"} /= $form->{exchangerate};
	}
	
	($dec) = ($form->{"lastcost_$i"} =~ /\.(\d+)/);
	$dec = length $dec;
	$decimalplaces2 = ($dec > $form->{precision}) ? $dec : $form->{precision};

	# if there is an exchange rate adjust prices
	for (qw(listprice lastcost)) { $form->{"${_}_$i"} /= $form->{exchangerate} }
	$form->{"sell_$i"} = $form->{"sellprice_$i"};
	
	$sellprice = $form->{"sellprice_$i"} * (1 - $form->{"discount_$i"} / 100);
	$amount = $sellprice * $form->{"qty_$i"};
	for (split / /, $form->{taxaccounts}) { $form->{"${_}_base"} = 0 }
	for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $amount }
	if (!$form->{taxincluded}) {
	  for (split / /, $form->{"taxaccounts_$i"}) { $amount += ($form->{"${_}_base"} * $form->{"${_}_rate"}) }
	}
	
	$ml = ($form->{type} eq 'invoice') ? 1 : -1;
	$ml = 1 if $form->{till};
	$form->{creditremaining} -= ($amount * $ml);

	for (qw(sell sellprice listprice)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces1) }
	$form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"}, $decimalplaces2);

	for (qw(netweight grossweight)) { $form->{"${_}_$i"} = $form->{"weight_$i"} * $form->{"qty_$i"} }

	for (qw(qty discount netweight grossweight)) { $form->{"${_}_$i"} =  $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }

	for (qw(partnumber description unit)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }

      }

      $i++;
      $focus = "partnumber_$i";

      &display_form;

    } else {

      if ($form->{rebuildpartsgroup}) {
	$focus = "partnumber_$form->{rowcount}";
	$form->{rowcount}--;
	&display_form;
      } else {
	# ok, so this is a new part
	# ask if it is a part or service item

	if (($form->{"partsgroup_$i"} || $form->{"partsgroupcode_$i"}) && ($form->{"partsnumber_$i"} eq "") && ($form->{"description_$i"} eq "")) {
	  $form->{rowcount}--;
	  &display_form;
	} else {
	  
	  $form->{"id_$i"}          = 0;
	  $form->{"unit_$i"}        = $locale->text('ea');

	  &new_item;
	  
	}
      }
    }
  }
}


sub post {

  $form->isblank("transdate", $locale->text('Invoice Date missing!'));
  $form->isblank("customer", $locale->text('Customer missing!'));

  # if oldcustomer ne customer redo form
  if (&check_name(customer)) {
    &update;
    exit;
  }

  &validate_items;

  $transdate = $form->datetonum(\%myconfig, $form->{transdate});
  
  $form->error($locale->text('Cannot post invoice for a closed period!')) if ($transdate <= $form->{closedto});

  $form->isblank("exchangerate", $locale->text('Exchange rate missing!')) if ($form->{currency} ne $form->{defaultcurrency});

  $roundto = 0;

  if ($form->{roundchange}) {
    %roundchange = split /[=;]/, $form->unescape($form->{roundchange});
    $roundto = $roundchange{''};
  }

  $paid = 0;
  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      $paid += $form->parse_amount(\%myconfig, $form->{"paid_$i"});

      $datepaid = $form->datetonum(\%myconfig, $form->{"datepaid_$i"});

      $form->isblank("datepaid_$i", $locale->text('Payment date missing!'));
      
      $form->error($locale->text('Cannot post payment for a closed period!')) if ($datepaid <= $form->{closedto});

      if ($form->{currency} ne $form->{defaultcurrency}) {
	$form->isblank("exchangerate_$i", $locale->text('Exchange rate for payment missing!'));
      }

      if ($form->{selectpaymentmethod}) {
	$roundto = $roundchange{$form->{"paymentmethod_$i"}};
      }
    }
  }
  
  $AR_paid = $form->{"AR_paid_$form->{paidaccounts}"};
  $paymentmethod = $form->{"paymentmethod_$form->{paidaccounts}"};

  $form->{label} = $locale->text('Invoice');

  if (! $form->{repost}) {
    if ($form->{id}) {
      &repost;
      exit;
    }
  }


  # add discount to payments
  if ($form->{discount_paid}) {
    $form->{paidaccounts}++ if $form->{"paid_$form->{paidaccounts}"};
    $i = $form->{paidaccounts};
    
    for (qw(paid datepaid source memo exchangerate cleared vr_id paymentmethod)) { $form->{"${_}_$i"} = $form->{"discount_$_"} }
    $form->{discount_index} = $i;
    $form->{"AR_paid_$i"} = $form->{"AR_discount_paid"};
    $form->{"paymentmethod_$i"} = $form->{discount_paymentmethod};

    if ($form->{"paid_$i"}) {
      $paid += $form->parse_amount(\%myconfig, $form->{"paid_$i"});
      
      $datepaid = $form->datetonum(\%myconfig, $form->{"datepaid_$i"});
      $expired = $form->datetonum(\%myconfig, $form->add_date(\%myconfig, $form->{transdate}, $form->{discountterms}, 'days'));

      $form->isblank("datepaid_$i", $locale->text('Cash discount date missing!'));

      $form->error($locale->text('Cannot post cash discount for a closed period!')) if ($datepaid <= $form->{closedto});

      $form->error($locale->text('Cash discount date past due!')) if ($datepaid > $expired);

      if ($form->{currency} ne $form->{defaultcurrency}) {
	$form->isblank("exchangerate_$i", $locale->text('Exchange rate for cash discount missing!'));
      }
    }
  }

  if ($roundto > 0.01) {
    $total = $form->round_amount($form->{oldinvtotal} / $roundto, 0) * $roundto;
    $cashover = $form->round_amount($paid - $total - ($paid - $form->{oldinvtotal}), $form->{precision});

    if ($cashover) {
      if ($form->round_amount($paid, $form->{precision}) == $form->round_amount($total, $form->{precision})) {
	$i = ++$form->{paidaccounts};
	$form->{"paid_$i"} = $form->format_amount(\%myconfig, $cashover, $form->{precision});
	$form->{"datepaid_$i"} = $datepaid;
	$form->{"AR_paid_$i"} = $form->{cashovershort};
      }
    }
  }

  $i = ++$form->{paidaccounts};
  $form->{"AR_paid_$i"} = $AR_paid;
  $form->{"paymentmethod_$i"} = $paymentmethod;

  if (IS->post_invoice(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Invoice')." $form->{invnumber} ".$locale->text('posted!'));
  } else {
    $form->error($locale->text('Cannot post invoice!'));
  }

}


sub print_and_post {

  $form->error($locale->text('Select postscript or PDF!')) if $form->{format} !~ /(ps|pdf)/;
  $form->error($locale->text('Select a Printer!')) if $form->{media} eq 'screen';

  if (! $form->{repost}) {
    if ($form->{id}) {
      $form->{print_and_post} = 1;
      &repost;
      exit;
    }
  }

  $oldform = new Form;
  $form->{display_form} = "post";
  for (keys %$form) { $oldform->{$_} = $form->{$_} }
  $oldform->{rowcount}++;

  &print_form($oldform);

}


sub delete {

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->{action} = "yes";
  $form->hide_form;

  print qq|
<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>

<h4>|.$locale->text('Are you sure you want to delete Invoice Number').qq| $form->{invnumber}
</h4>

<p>
<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>
|;


}


sub yes {

  if (IS->delete_invoice(\%myconfig, \%$form, $spool)) {
    $form->redirect($locale->text('Invoice deleted!'));
  } else {
    $form->error($locale->text('Cannot delete invoice!'));
  }

}


sub generate_invoices {

  if ($form->{beenhere}) {
    &do_generate_invoices;
    exit;
  }

  $focus = "name";
  
  $form->{reportcode} = "generate_sales_invoices";
  
  AA->vc_links(\%myconfig, \%$form);
  
  for (qw(name city startdate)) { $form->{"l_$_"} = "checked" }

  @checked = ();
  %radio = ();
  @input = qw(name vcnumber city state zipcode country startdatefrom startdateto enddatefrom enddateto employee paymentmethod curr pricegroup business);
  
  $fldlabel{name} = $locale->text('Customer');
  $fldlabel{vcnumber} = $locale->text('Customer Number');
  $fldlabel{city} = $locale->text('City');
  $fldlabel{state} = $locale->text('State/Province');
  $fldlabel{zipcode} = $locale->text('Zip/Postal Code');
  $fldlabel{country} = $locale->text('Country');
  $fldlabel{startdate} = $locale->text('Startdate');
  $fldlabel{enddate} = $locale->text('Enddate');
  
  $i = 1;
  $includeinreport{name} = { ndx => $i++, sort => name, checkbox => 1, html => qq|<input name="l_name" class="checkbox" type="checkbox" value="Y" $form->{l_name}>|, label => $fldlabel{name} };
  $includeinreport{vcnumber} = { ndx => $i++, sort => vcnumber, checkbox => 1, html => qq|<input name="l_vcnumber" class="checkbox" type="checkbox" value="Y" $form->{l_vcnumber}>|, label => $fldlabel{vcnumber} };
  $includeinreport{city} = { ndx => $i++, sort => city, checkbox => 1, html => qq|<input name="l_city" class="checkbox" type="checkbox" value="Y" $form->{l_city}>|, label => $fldlabel{city} };
  $includeinreport{state} = { ndx => $i++, sort => state, checkbox => 1, html => qq|<input name="l_state" class="checkbox" type="checkbox" value="Y" $form->{l_state}>|, label => $fldlabel{state} };
  $includeinreport{zipcode} = { ndx => $i++, sort => zipcode, checkbox => 1, html => qq|<input name="l_zipcode" class="checkbox" type="checkbox" value="Y" $form->{l_zipcode}>|, label => $fldlabel{zipcode} };
  $includeinreport{country} = { ndx => $i++, sort => country, checkbox => 1, html => qq|<input name="l_country" class="checkbox" type="checkbox" value="Y" $form->{l_country}>|, label => $fldlabel{country} };
  $includeinreport{startdate} = { ndx => $i++, sort => startdate, checkbox => 1, html => qq|<input name="l_startdate" class="checkbox" type="checkbox" value="Y" $form->{l_startdate}>|, label => $fldlabel{startdate} };
  $includeinreport{enddate} = { ndx => $i++, sort => enddate, checkbox => 1, html => qq|<input name="l_enddate" class="checkbox" type="checkbox" value="Y" $form->{l_enddate}>|, label => $fldlabel{enddate} };
  
  if (@{ $form->{all_report} }) {
    $form->{selectreportform} = "\n";
    for (@{ $form->{all_report} }) { $form->{selectreportform} .= qq|$_->{reportdescription}--$_->{reportid}\n| }

    $reportform = qq|
      <tr>
        <th align=right>|.$locale->text('Report').qq|</th>
	<td>
	  <select name=report onChange="ChangeReport();">|.$form->select_option($form->{selectreportform}, undef, 1)
          .qq|</select>
        </td>
      </tr>
|;
  }
  
  if (@{ $form->{all_pricegroup} }) {

    $fldlabel{pricegroup} = $locale->text('Pricegroup');
    $includeinreport{pricegroup} = { ndx => $i++, sort => pricegroup, checkbox => 1, html => qq|<input name="l_pricegroup" class="checkbox" type="checkbox" value="Y" $form->{l_pricegroup}>|, label => $fldlabel{pricegroup} };
    
    $selectpricegroup = "\n";
    for (@{ $form->{all_pricegroup} }) { $selectpricegroup .= qq|$_->{pricegroup}--$_->{id}\n| }
    
    $pricegroup = qq|
        <tr>
	<th align=right>$fldlabel{pricegroup}</th>
	<td><select name=pricegroup>|
	.$form->select_option($selectpricegroup, undef, 1)
	.qq|</select></td>
|;
  }
  
  if (@{ $form->{all_business} }) {

    $fldlabel{business} = $locale->text('Type of Business');
    $includeinreport{business} = { ndx => $i++, sort => business, checkbox => 1, html => qq|<input name="l_business" class="checkbox" type="checkbox" value="Y" $form->{l_business}>|, label => $fldlabel{business} };
  
    $selectbusiness = "\n";
    for (@{ $form->{all_business} }) { $selectbusiness .= qq|$_->{description}--$_->{id}\n| }
    
    $business = qq|
        <tr>
	<th align=right>$fldlabel{business}</th>
	<td><select name=business>|
	.$form->select_option($selectbusiness, undef, 1)
	.qq|</select></td>
|;
  }

  if ($form->{selectpaymentmethod}) {
    
    $fldlabel{paymentmethod} = $locale->text('Payment Method');
    $includeinreport{paymentmethod} = { ndx => $i++, sort => paymentmethod, checkbox => 1, html => qq|<input name="l_paymentmethod" class="checkbox" type="checkbox" value="Y" $form->{l_paymentmethod}>|, label => $fldlabel{paymentmethod} };
    
    $paymentmethod = qq|
        <tr>
	<th align=right>$fldlabel{paymentmethod}</th>
	<td><select name=paymentmethod>|
	.$form->select_option($form->{selectpaymentmethod}, $form->{paymentmethod_1}, 1)
	.qq|</select></td>
|;
  }
  
  if ($form->{selectcurrency}) {
    
    $fldlabel{curr} = $locale->text('Currency');
    $includeinreport{curr} = { ndx => $i++, sort => curr, checkbox => 1, html => qq|<input name="l_curr" class="checkbox" type="checkbox" value="Y" $form->{l_curr}>|, label => $fldlabel{curr} };
    
    $selectcurrency = "\n$form->{selectcurrency}";
    $currency = qq|
        <tr>
	<th align=right>$fldlabel{curr}</th>
	<td><select name=curr>|
	.$form->select_option($selectcurrency, $form->{currency}, 1)
	.qq|</select>
	</td>
|;
  }

  $employee = "";
  if ($form->{selectemployee}) {

    $fldlabel{employee} = $locale->text('Salesperson');
    $includeinreport{employee} = { ndx => $i++, sort => employee, checkbox => 1, html => qq|<input name="l_employee" class="checkbox" type="checkbox" value="Y" $form->{l_employee}>|, label => $fldlabel{employee} };
    
    $selectemployee = "\n$form->{selectemployee}";
    $employee = qq|
	      <tr>
	        <th align=right nowrap>$fldlabel{employee}</th>
		<td><select name=employee>|
		.$form->select_option($selectemployee, $form->{employee}, 1)
		.qq|</select>
		</td>
	      </tr>
|;
  }
  
  @a = ();
  $form->{flds} = "";
  
  for (sort { $includeinreport{$a}->{ndx} <=> $includeinreport{$b}->{ndx} } keys %includeinreport) {
    $form->{flds} .= "$_=$includeinreport{$_}->{label},";
    push @checked, "l_$_";
    if ($includeinreport{$_}->{checkbox}) {
      push @a, "$includeinreport{$_}->{html} $includeinreport{$_}->{label}";
    }
  }
  chop $form->{flds};


  $form->header;
  
  for (qw(name vcnumber city state zipcode country employee)) { delete $form->{$_} }
  for (qw(AR AR_discount AR_paid currency customer department employee formname language partsgroup paymentmethod projectnumber warehouse reportform)) { delete $form->{"select$_"} }
  for (qw(business pricegroup)) { delete $form->{"all_$_"} }

  JS->change_report(\%$form, \@input, \@checked, \%radio);

  for (qw(report reportvars)) { delete $form->{"all_$_"} }
  for (@checked) { delete $form->{$_} }
  for (@input) { delete $form->{$_} }
  for (keys %radio) { delete $form->{$_} }

  print qq|
<body onLoad="document.forms[0].${focus}.focus()" />

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        $reportform
	<tr>
	  <th align=right nowrap>$fldlabel{name}</th>
	  <td><input name="name" size="32"></td>
	</tr>
	<tr>
	  <th align=right nowrap>$fldlabel{vcnumber}</th>
	  <td><input name="vcnumber" size="32"></td>
	</tr>
	<tr>
	  <th align=right nowrap>$fldlabel{city}</th>
	  <td><input name="city" size="32"></td>
	</tr>
	<tr>
	  <th align=right nowrap>$fldlabel{state}</th>
	  <td><input name="state" size="32"></td>
	</tr>
	<tr>
	  <th align=right nowrap>$fldlabel{zipcode}</th>
	  <td><input name="zipcode" size="10"></td>
	</tr>
	<tr>
	  <th align=right nowrap>$fldlabel{country}</th>
	  <td><input name="country" size="32"></td>
	</tr>
	<tr>
	  <th align=right nowrap>$fldlabel{startdate}</th>
	  <td>|.$locale->text('From').qq| <input name="startdatefrom" size="11" class="date" title="$myconfig{dateformat}"> |.$locale->text('To').qq| <input name="startdateto" size="11" class="date" title="$myconfig{dateformat}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Enddate').qq|</th>
	  <td>|.$locale->text('From').qq| <input name="enddatefrom" size="11" class="date" title="$myconfig{dateformat}"> |.$locale->text('To').qq| <input name="enddateto" size="11" class="date" title="$myconfig{dateformat}"></td>
	</tr>
	$employee
	$paymentmethod
	$currency
	$pricegroup
	$business
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
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
  <tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
|;

  $form->{sort} ||= "name";
  $form->{direction} ||= "ASC";
  $form->{action} = "list_names";
  $form->{nextsub} = "list_names";

  $form->hide_form;

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


sub list_names {

  $form->{vc} = "customer";

  AA->all_names(\%myconfig, \%$form);

  @columns = ();
  for (split /,/, $form->{flds}) {
    ($column, $label) = split /=/, $_;
    push @columns, $column;
    $column_data{$column} = $label;
  }
  
  @column_index = ();
  $i = 0;

  if ($form->{column_index}) {
    for (split /,/, $form->{column_index}) {
      s/=.*//;
      push @column_index, $_;
      delete $form->{"l_$_"}
    }
  } else {
    for (@columns) {
      if ($form->{"l_$_"} eq "Y") {
	push @column_index, $_;
	$form->{column_index} .= "$_=,";
      }
      delete $form->{"l_$_"};
    }

    chop $form->{column_index};

  }


  $href = "$form->{script}?action=list_names";
  for (qw(direction oldsort path login id)) { $href .= qq|&$_=$form->{$_}| }
  for (qw(id direction oldsort)) { delete $form->{$_} }

  @column_index = $form->sort_columns(@column_index);
  unshift @column_index, "ndx";

  for (@column_index) { $column_data{$_} = qq|\n<th nowrap><a class="listheading" href="$href&sort=$_">$column_data{$_}</a></th>| }
  
  $column_data{ndx} = qq|<th class=listheading width=1%><input name="allbox" type="checkbox" class="checkbox" value="1" checked onChange="CheckAll();"></th>|;


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
	<tr class=listheading>
|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
      </tr>
|;


  $i = 0;
  for $ref (@{ $form->{all_vc} }) {
    
    $i++;
    $j++; $j %= 2;
    
    print qq|
      <tr class=listrow$j>
|;

    for (@column_index) { $column_data{$_} = qq|<td>$ref->{$_}</td>| }

    $column_data{ndx} = qq|<td><input name="ndx_$i" type="checkbox" class="checkbox" value="$ref->{id}" checked></td>|;

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

  $form->{lastndx} = $i;

  map { delete $form->{"all_$_"} } qw(business pricegroup vc);
  
  %button = ('Generate Invoices' => { ndx => 1, key => 'G', value => $locale->text('Generate Invoices') },
             'Save Report' => { ndx => 8, key => 'S', value => $locale->text('Save Report') }
            );
  
  if (!$form->{admin}) {
    delete $button{'Save Report'} unless $form->{savereport};
  }
  
  $form->{beenhere} = 1;
  
  delete $form->{savereport};

  $form->hide_form;
  
  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

  print qq|
</form>
  
</body>
</html>
|;

}


sub do_generate_invoices {

  $myform = new Form;
  for (keys %$form) { $myform->{$_} = $form->{$_} }
  
  $form->info($locale->text('Generating Invoices')."\n");
  
  my $i = 0;
  $total = 0;
  
  for (1 .. $form->{lastndx}) {

    if ($form->{"ndx_$_"}) {
      $i++;
      $myform->{"$form->{vc}_id"} = $form->{"ndx_$_"};
      
      $ok = IS->generate_invoice(\%myconfig, \%$myform);
      
      $form->{precision} = $myform->{precision};
      $form->info("$i. $myform->{$form->{vc}} $myform->{city} $myform->{invnumber}, ");
      $form->info($form->format_amount(\%myconfig, $myform->{invamount}, $myform->{precision}));
      $form->info(" ... ");

      $total += $myform->{invamount};
      
      if ($ok) {
	$form->info($locale->text('ok'));
      } else {
	$form->info($locale->text('failed!'));
      }
      $form->info("\n");

      for (keys %$myform) { delete $myform->{$_} }
      for (keys %$form) { $myform->{$_} = $form->{$_} }
    }

  }

  $form->info("<p>".$locale->text('Total:'));
  $form->info($form->format_amount(\%myconfig, $total, $form->{precision}, "0"));
  
}


