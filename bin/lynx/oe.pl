#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Order entry module
# Quotation module
#
#======================================================================


use SL::OE;
use SL::IR;
use SL::IS;
use SL::PE;

require "$form->{path}/arap.pl";
require "$form->{path}/io.pl";


1;
# end of main


sub add {

  if ($form->{type} eq 'purchase_order') {
    $form->{title} = $locale->text('Add Purchase Order');
    $form->{vc} = 'vendor';
  }
  if ($form->{type} eq 'sales_order') {
    $form->{title} = $locale->text('Add Sales Order');
    $form->{vc} = 'customer';
  }
  if ($form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Add Request for Quotation');
    $form->{vc} = 'vendor';
  }
  if ($form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Add Quotation');
    $form->{vc} = 'customer';
  }

  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&vc=$form->{vc}&login=$form->{login}&path=$form->{path}" unless $form->{callback};

  $form->{rowcount} = 0;

  &order_links;
  &prepare_order;
  &display_form;

}


sub edit {
  
  if ($form->{type} =~ /(purchase_order|bin_list)/) {
    $form->{title} = $locale->text('Edit Purchase Order');
    $form->{vc} = 'vendor';
    $form->{type} = 'purchase_order';
  }
  if ($form->{type} =~ /((sales|work)_order|(packing|pick)_list)/) {
    $form->{title} = $locale->text('Edit Sales Order');
    $form->{vc} = 'customer';
    $form->{type} = 'sales_order';
  }
  if ($form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Edit Request for Quotation');
    $form->{vc} = 'vendor';
  }
  if ($form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Edit Quotation');
    $form->{vc} = 'customer';
  }

  $form->{shipto} = 1;
  &order_links;
  &prepare_order;
  &display_form;
  
}



sub order_links {

  # retrieve order/quotation
  OE->retrieve(\%myconfig, \%$form);

  $form->{selectprinter} = "";
  for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" }
  chop $form->{selectprinter};
  
  # get customer/vendor
  $form->all_vc(\%myconfig, $form->{vc}, ($form->{vc} eq 'customer') ? "AR" : "AP", undef, $form->{transdate}, 1);
  
  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};
  $form->{currency} = $form->{defaultcurrency} unless $form->{currency};
  
  for (@curr) { $form->{selectcurrency} .= "$_\n" }

  $form->{oldlanguage_code} = $form->{language_code};
  
  $l{language_code} = $form->{language_code};
  $l{all} = 1;
  $l{parentgroup} = 1;

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
 
  if (@{ $form->{"all_$form->{vc}"} }) {
    unless ($form->{"$form->{vc}_id"}) {
      $form->{"$form->{vc}_id"} = $form->{"all_$form->{vc}"}->[0]->{id};
    }
  }
  
  for (qw(terms taxincluded intnotes)) { $temp{$_} = $form->{$_} }

  # get customer / vendor
  AA->get_name(\%myconfig, \%$form);

  if ($form->{id}) {
    for (keys %temp) { $form->{$_} = $temp{$_} }
  }

  $form->{terms} = "" if ! $form->{terms};

  $form->{exchangerate} ||= 1;

  ($form->{$form->{vc}}) = split /--/, $form->{$form->{vc}};
  $form->{"old$form->{vc}"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
  $form->{"old$form->{vc}number"} = $form->{"$form->{vc}number"};

  # build selection list
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
  
  # reference documents
  $i = 0;
  for (@{ $form->{all_reference} }) {
    $i++;
    $form->{"referencedescription_$i"} = $_->{description};
    $form->{"referenceid_$i"} = $_->{id};
  }
  $form->{reference_rows} = $i;
  
  $form->{"select$form->{vc}"} = $form->escape($form->{"select$form->{vc}"},1);
  for (qw(currency partsgroup projectnumber department warehouse employee language printer)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }

}


sub prepare_order {

  $form->{formname} ||= $form->{type};
  $form->{sortby} ||= "runningnumber";
  $form->{format} ||= $myconfig{outputformat};
  $form->{copies} ||= 1;
  
  if ($myconfig{printer}) {
    $form->{format} ||= "ps";
  } 
  $form->{media} ||= $myconfig{printer};
  
  $form->{currency} =~ s/ //g;
  $form->{oldcurrency} = $form->{currency};

  $i = 1;

  if ($form->{id}) {
    
    for (qw(ordnumber quonumber shippingpoint shipvia waybill notes intnotes shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact)) { $form->{$_} = $form->quote($form->{$_}) }
    
    foreach $ref (@{ $form->{form_details} } ) {
      for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }

      $form->{"projectnumber_$i"} = qq|$ref->{projectnumber}--$ref->{project_id}| if $ref->{project_id};
      $form->{"partsgroup_$i"} = qq|$ref->{partsgroup}--$ref->{partsgroup_id}| if $ref->{partsgroup_id};

      $form->{"discount_$i"} = $form->format_amount(\%myconfig, $form->{"discount_$i"} * 100);

      for (qw(netweight grossweight volume)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }

      ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};
      
      for (map { "${_}_$i" } qw(sellprice listprice)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $decimalplaces) }

      ($dec) = ($form->{"lastcost_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};
      
      $form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"}, $decimalplaces);
      
      $form->{"qty_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"});
      $form->{"oldqty_$i"} = $form->{"qty_$i"};
      
      $form->{"ship_$i"} = $form->format_amount(\%myconfig, $form->{"ship_$i"});
      
      for (qw(partnumber sku description unit)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }
      $form->{rowcount} = $i;
      $i++;
    }
  }

  $form->{oldtransdate} = $form->{transdate};

  if ($form->{type} eq 'sales_quotation') {
    if (! $form->{readonly}) {
      $form->{readonly} = 1 if $myconfig{acs} =~ /Quotations--Quotation/;
    }
    
    $form->{selectformname} = qq|sales_quotation--|.$locale->text('Quotation');
  }
  
  if ($form->{type} eq 'request_quotation') {
    if (! $form->{readonly}) {
      $form->{readonly} = 1 if $myconfig{acs} =~ /Quotations--RFQ/;
    }
    
    $form->{selectformname} = qq|request_quotation--|.$locale->text('RFQ');
  }
  
  if ($form->{type} eq 'sales_order') {
    if (! $form->{readonly}) {
      $form->{readonly} = 1 if $myconfig{acs} =~ /Order Entry--Sales Order/;
    }
    
    $form->{selectformname} = qq|sales_order--|.$locale->text('Sales Order')
.qq|\nwork_order--|.$locale->text('Work Order')
.qq|\npick_list--|.$locale->text('Pick List')
.qq|\npacking_list--|.$locale->text('Packing List')
.qq|\nbarcode--|.$locale->text('Barcode');
  }
  
  if ($form->{type} eq 'purchase_order') {
    if (! $form->{readonly}) {
      $form->{readonly} = 1 if $myconfig{acs} =~ /Order Entry--Purchase Order/;
    }
    
    $form->{selectformname} = qq|purchase_order--|.$locale->text('Purchase Order')
.qq|\nbin_list--|.$locale->text('Bin List')
.qq|\nbarcode--|.$locale->text('Barcode');
  }

  if ($form->{type} eq 'ship_order') {
    $form->{selectformname} = qq|pick_list--|.$locale->text('Pick List')
.qq|\npacking_list--|.$locale->text('Packing List')
.qq|\nbarcode--|.$locale->text('Barcode');
  }
  
  if ($form->{type} eq 'receive_order') {
    $form->{selectformname} = qq|bin_list--|.$locale->text('Bin List')
.qq|\nbarcode--|.$locale->text('Barcode');
  }

  $focus = "partnumber_$i";
  
  $form->{selectformname} = $form->escape($form->{selectformname},1);
  
  $form->helpref($form->{type}, $myconfig{countrycode});

}


sub lookup_order {

  $form->isblank("ordnumber", $locale->text('Order Number missing!'));
  
  if ($id = OE->lookup_order(\%myconfig, \%$form)) {
    $type = ($form->{vc} eq 'customer') ? 'sales_order' : 'purchase_order';
    $form->{callback} = "oe.pl?action=edit&id=$id&type=$type&vc=$form->{vc}&path=$form->{path}&login=$form->{login}";
    $form->redirect;
  } else {
    $form->error($locale->text('Order not on file!'));
  }
  
}


sub form_header {

  $checkedopen = ($form->{closed}) ? "" : "checked";
  $checkedclosed = ($form->{closed}) ? "checked" : "";

  if ($form->{id}) {
    $openclosed = qq|
      <tr>
	<th nowrap align=right><input name=closed type=radio class=radio value=0 $checkedopen> |.$locale->text('Open').qq|</th>
	<th nowrap align=left><input name=closed type=radio class=radio value=1 $checkedclosed> |.$locale->text('Closed').qq|</th>
      </tr>
|;
  }

  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

  if ($form->{defaultcurrency}) {
    $exchangerate = qq|<tr>
                <th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td>
		  <table>
		    <tr>
		  
		<td><select name=currency onChange="javascript:document.forms[0].submit()">|
		.$form->select_option($form->{selectcurrency}, $form->{currency})
		.qq|</select><td>|;

    if ($form->{currency} ne $form->{defaultcurrency}) {
      $fdm = $form->dayofmonth($myconfig{dateformat}, $form->{transdate}, 'fdm');
      $ldm = $form->dayofmonth($myconfig{dateformat}, $form->{transdate});

      $exchangerate .= qq|
      <th align=right nowrap>|.$locale->text('Exchange Rate').qq| <font color=red>*</font></th>
      <td nowrap><input name=exchangerate class="inputright" size=10 value=$form->{exchangerate}>
          <a href=am.pl?action=list_exchangerates&transdatefrom=$fdm&transdateto=$ldm&currency=$form->{currency}&login=$form->{login}&path=$form->{path} target=_blank>?</a></td>|;
    }
    $exchangerate .= qq|</tr></table></td></tr>
|;
  }

  $terms = qq|
                    <tr>
		      <th align=right nowrap>|.$locale->text('Terms').qq| |.$locale->text('Net').qq|</th>
		      <td nowrap><input name=terms class="inputright" size="3" maxlength="3" value=$form->{terms}> <b>|.$locale->text('days').qq|</b></td>
                    </tr>
|;

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

  $reference_documents = &reference_documents;
  
  if ($form->{business}) {
    $business = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Business').qq|</th>
		<td nowrap>$form->{business}|;
    $business .= qq|&nbsp;&nbsp;&nbsp;
		<b>|.$locale->text('Trade Discount').qq|</b> |
		.$form->format_amount(\%myconfig, $form->{tradediscount} * 100).qq| %| if $form->{vc} eq 'customer';
    $business .= qq|</td>
	      </tr>
|;
  }


  if ($form->{type} !~ /_quotation$/) {
    $ordnumber = qq|
	      <tr>
		<th width=70% align=right nowrap>|.$locale->text('Order Number').qq|</th>
                <td><input name=ordnumber size=20 value="|.$form->quote($form->{ordnumber}).qq|"></td>|
		.$form->hide_form(qw(quonumber)).qq|
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Order Date').qq| <font color=red>*</font></th>
		<td><input name=transdate size=11 class=date title="$myconfig{dateformat}" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap=true>|.$locale->text('Required by').qq|</th>
		<td><input name=reqdate size=11 class=date title="$myconfig{dateformat}" value=$form->{reqdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('PO Number').qq|</th>
		<td><input name=ponumber size=20 value="|.$form->quote($form->{ponumber}).qq|"></td>
	      </tr>
|;
    
    $n = ($form->{creditremaining} < 0) ? "0" : "1";

    $creditremaining = qq|
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
  } else {
    $reqlabel = ($form->{type} eq 'sales_quotation') ? $locale->text('Valid until') : $locale->text('Required by');
    if ($form->{type} eq 'sales_quotation') {
      $ordnumber = qq|
	      <tr>
		<th width=70% align=right nowrap>|.$locale->text('Quotation Number').qq|</th>
		<td><input name=quonumber size=20 value="|.$form->quote($form->{quonumber}).qq|"></td>|
		.$form->hide_form(qw(ordnumber))
		.qq|
	      </tr>
|;
    } else {
      $ordnumber = qq|
	      <tr>
		<th width=70% align=right nowrap>|.$locale->text('RFQ Number').qq|</th>
		<td><input name=quonumber size=20 value="|.$form->quote($form->{quonumber}).qq|"></td>
		|
		.$form->hide_form(qw(ordnumber))
		.qq|
	      </tr>
|;

      $terms = "";
    }
     

    $ordnumber .= qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Quotation Date').qq|</th>
		<td><input name=transdate size=11 class=date title="$myconfig{dateformat}" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap=true>$reqlabel</th>
		<td><input name=reqdate size=11 class=date title="$myconfig{dateformat}" value=$form->{reqdate}></td>
	      </tr>
|;

  }

  if ($form->{vc} eq 'customer') {
    $vcname = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');

    if ($form->{pricegroup}) {
      $pricegroup = qq|
              <tr>
	        <th align=right>|.$locale->text('Pricegroup').qq|</th>
		<td>$form->{pricegroup}</td>
              </tr>
|;
    }
  } else {
    $vcname = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
  }

  $vcref = qq|<a href=ct.pl?action=edit&db=$form->{vc}&id=$form->{"$form->{vc}_id"}&login=$form->{login}&path=$form->{path} target=_blank>?</a>|;
  
  $vc = qq|<input type=hidden name=action value="update">
              <tr>
	        <th align=right nowrap>$vcname <font color=red>*</font></th>
|;

  if ($form->{"select$form->{vc}"}) {
    $vc .= qq|
                <td nowrap><select name=$form->{vc} onChange="javascript:document.forms[0].submit()">|.$form->select_option($form->{"select$form->{vc}"}, $form->{$form->{vc}}, 1).qq|</select>
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
                <td nowrap><input name=$form->{vc} value="|.$form->quote($form->{$form->{vc}}).qq|" size=35>
		$vcref
		</td>
	      </tr>
	      <tr>
	        <th align=right nowrap>$vcnumber</th>
		<td><input name="$form->{vc}number" value="$form->{"$form->{vc}number"}" size=35>
		</td>
	      </tr>
|;
  }

  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td><select name=department>|
		.$form->select_option($form->{selectdepartment}, $form->{department}, 1).qq|
		</select>
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


  $employee = $form->hide_form(qw(employee));

  if ($form->{type} eq 'sales_order') {
    if ($form->{selectemployee}) {
      $employee = qq|
 	      <tr>
	        <th align=right nowrap>|.$locale->text('Salesperson').qq|</th>
		<td><select name=employee>|
		.$form->select_option($form->{selectemployee}, $form->{employee}, 1)
		.qq|</select>
		</td>
	      </tr>
|;
    }
  } else {
    if ($form->{selectemployee}) {
      $employee = qq|
 	      <tr>
	        <th align=right nowrap>|.$locale->text('Employee').qq|</th>
		<td><select name=employee>|
		.$form->select_option($form->{selectemployee}, $form->{employee}, 1)
		.qq|</select>
		</td>
	      </tr>
|;
    }
  }

  %title = ( work_order => $locale->text('Work Order'),
	     pick_list => $locale->text('Pick List'),
	     packing_list => $locale->text('Packing List'),
	     bin_list => $locale->text('Bin List'),
	   );
  $title = " / $title{$form->{formname}}" if $form->{formname} !~ /(sales_order|purchase_order|quotation)/;

  
  $form->header;
  
  print qq|
<body onLoad="document.forms[0].${focus}.focus()" />

<form method=post action="$form->{script}">
|;

  $form->hide_form(qw(id type defaultcurrency formname printed emailed queued vc title discount creditlimit creditremaining tradediscount business oldtransdate recurring address1 address2 city state zipcode country pricegroup closedto precision reference_rows referenceurl));

  $form->hide_form("select$form->{vc}");
  $form->hide_form(map { "select$_" } qw(formname currency partsgroup projectnumber department warehouse employee language printer));
  $form->hide_form("$form->{vc}_id", "old$form->{vc}", "old$form->{vc}number");


  print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{helpref}$form->{title}$title</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width="100%">
        <tr valign=top>
	  <td>
	    <table width=100%>
	      $vc
	      <tr>
	        <th align=right nowrap>|.$locale->text('Address').qq|</th>
		<td>$form->{address1} $form->{address2} $form->{city} $form->{state} $form->{zipcode} $form->{country}</td>
	      </tr>
	      $pricegroup
	      $creditremaining
	      $business
	      $exchangerate
	      $warehouse
	      <tr>
		<th align=right>|.$locale->text('Shipping Point').qq|</th>
		<td><input name=shippingpoint size=35 value="|.$form->quote($form->{shippingpoint}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Ship via').qq|</th>
		<td><input name=shipvia size=35 value="|.$form->quote($form->{shipvia}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Waybill').qq|</th>
		<td><input name=waybill size=35 value="|.$form->quote($form->{waybill}).qq|"></td>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $openclosed
	      $department
	      $employee
	      $ordnumber
	      $terms
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
	$description
      </table>
    </td>
  </tr>
|;

  $form->hide_form(qw(shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail message email subject cc bcc taxaccounts helpref aa_id));

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
	      <td align=right>
	      <input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}></td>
	      <th align=left>|.$locale->text('Tax Included').qq|</th>
	    </tr>
|;
  }

  if (!$form->{taxincluded}) {
    
    for (split / /, $form->{taxaccounts}) {

      if ($form->{"${_}_base"}) {
	$form->{invtotal} += $form->{"${_}_total"} = $form->round_amount($form->round_amount($form->round_amount($form->{"${_}_base"}, $form->{precision}) * $form->{"${_}_rate"}, 10), $form->{precision});
	$form->{"${_}_total"} = $form->format_amount(\%myconfig, $form->{"${_}_total"}, $form->{precision});
	
	$tax .= qq|
	      <tr>
		<th align=right>$form->{"${_}_description"}</th>
		<td align=right>$form->{"${_}_total"}</td>
	      </tr>
|;
      }
    }

    $form->{invsubtotal} = $form->format_amount(\%myconfig, $form->{invsubtotal}, $form->{precision}, 0);
    
    $subtotal = qq|
	      <tr>
		<th align=right>|.$locale->text('Subtotal').qq|</th>
		<td align=right>$form->{invsubtotal}</td>
	      </tr>
|;

  }

  $form->{oldinvtotal} = $form->{invtotal};
  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, $form->{precision}, 0);


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
    <td><hr size=3 noshade></td>
  </tr>
  <tr>
    <td>
|;

  $form->{oldtotalpaid} = $totalpaid;
  $form->hide_form(map { "old$_" } qw(invtotal totalpaid));

  &print_options;

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

    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
               'Preview' => { ndx => 3, key => 'V', value => $locale->text('Preview') },
               'Print' => { ndx => 4, key => 'P', value => $locale->text('Print') },
	       'Save' => { ndx => 5, key => 'S', value => $locale->text('Save') },
	       'Ship to' => { ndx => 6, key => 'T', value => $locale->text('Ship to') },
	       'Ship all' => { ndx => 7, key => 'A', value => $locale->text('Ship all') },
	       'E-mail' => { ndx => 8, key => 'E', value => $locale->text('E-mail') },
	       'Print and Save' => { ndx => 9, key => 'R', value => $locale->text('Print and Save') },
	       'Save as new' => { ndx => 10, key => 'N', value => $locale->text('Save as new') },
	       'Print and Save as new' => { ndx => 11, key => 'W', value => $locale->text('Print and Save as new') },
	       'Sales Invoice' => { ndx => 12, key => 'I', value => $locale->text('Sales Invoice') },
	       'Sales Order' => { ndx => 13, key => 'O', value => $locale->text('Sales Order') },
	       'Quotation' => { ndx => 14, key => 'Q', value => $locale->text('Quotation') },
	       'Vendor Invoice' => { ndx => 15, key => 'I', value => $locale->text('Vendor Invoice') },
	       'Purchase Order' => { ndx => 16, key => 'O', value => $locale->text('Purchase Order') },
	       'RFQ' => { ndx => 17, key => 'Q', value => $locale->text('RFQ') },
	       'Schedule' => { ndx => 18, key => 'H', value => $locale->text('Schedule') },
	       'New Number' => { ndx => 19, key => 'M', value => $locale->text('New Number') },
	       'Delete' => { ndx => 20, key => 'D', value => $locale->text('Delete') },
	      );


    %f = ();
    for ("Update", "Ship to", "Print", "E-mail", "Save", "New Number") { $f{$_} = 1 }
    if ($latex) {
      $f{'Print and Save'} = 1;
      $f{'Preview'} = 1;
    }

    $f{'Ship all'} = 1 if $form->{type} =~ /(sales|purchase)_order/;
    
    if ($form->{id}) {
      
      $f{'Delete'} = 1;
      $f{'Save as new'} = 1;
      $f{'Print and Save as new'} = 1 if $latex;
      if ($form->{closed} && $transdate <= $form->{closedto}) {
	$f{'Save'} = 0;
	$f{'Delete'} = 0;
      }

      if ($form->{type} =~ /sales_/) {
	if ($myconfig{acs} !~ /(AR--AR|AR--Sales Invoice)/) {
	  $f{'Sales Invoice'} = 1;
	}
      } else {
	if ($myconfig{acs} !~ /(AP--AP|AP--Vendor Invoice)/) {
	  $f{'Vendor Invoice'} = 1;
	}
      }
	
      if ($myconfig{acs} !~ /Quotations--Quotations/) {
	if ($form->{type} eq 'sales_order') {
	  if ($myconfig{acs} !~ /Quotations--RFQ/) {
	    $f{'Quotation'} = 1;
	  }
	}
	
	if ($form->{type} eq 'purchase_order') {
	  if ($myconfig{acs} !~ /Quotations--RFQ/) {
	    $f{'RFQ'} = 1;
	  }
	}
      }
      
      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	if ($form->{type} eq 'sales_quotation') {
	  if ($myconfig{acs} !~ /Order Entry--Sales Order/) {
	    $f{'Sales Order'} = 1;
	  }
	}
	
	if ($myconfig{acs} !~ /Order Entry--Purchase Order/) {
	  if ($form->{type} eq 'request_quotation') {
	    $f{'Purchase Order'} = 1;
	  }
	}
      }

      if ($form->{aa_id}) {
	for ("Save", "Print and Save", "Sales Invoice", "Vendor Invoice", "Delete") { delete $f{$_} }
      }
    }

    if ($form->{type} =~ /_order/) {
      $f{'Schedule'} = 1;
    }

  }

  for (keys %button) { delete $button{$_} if ! $f{$_} }
  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

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


sub ship_all {
  
  for (1 .. $form->{rowcount}) {
    $form->{"ship_$_"} = $form->{"qty_$_"};
  }

  $form->{rowcount}--;

  &display_form;

}


sub update {

  if ($form->{type} eq 'generate_purchase_order') {
    
    for (1 .. $form->{rowcount}) {
      if ($form->{"ndx_$_"}) {
	$form->{"$form->{vc}_id_$_"} = $form->{"$form->{vc}_id"};
	$form->{"$form->{vc}_$_"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
      }
    }
    
    &po_orderitems;
    exit;
  }
  
  $form->{exchangerate} = $form->parse_amount(\%myconfig, $form->{exchangerate});

  if ($form->{vc} eq 'customer') {
    $ARAP = "AR";
  } else {
    $ARAP = "AP";
  }

  if ($newname = &check_name($form->{vc})) {
    &rebuild_vc($form->{vc}, $ARAP, $form->{transdate}, 1);
  }

  if ($form->{transdate} ne $form->{oldtransdate}) {
    $form->{oldtransdate} = $form->{transdate};
    &rebuild_vc($form->{vc}, $ARAP, $form->{transdate}, 1) if ! $newname;

    $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate});
    $form->{oldcurrency} = $form->{currency};

    if (@{ $form->{all_employee} }) {
      $form->{selectemployee} = "";
      for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }
      $form->{selectemployee} = $form->escape($form->{selectemployee},1);
    }
  }

  $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}) if $form->{currency} ne $form->{oldcurrency};
  $form->{oldcurrency} = $form->{currency};

  my $i = $form->{rowcount};
  $form->{exchangerate} ||= 1;

  if (($form->{"partnumber_$i"} eq "") && ($form->{"description_$i"} eq "") && ($form->{"partsgroup_$i"} eq "") && ($form->{"partsgroupcode_$i"} eq "")) {

    &check_form;
    
  } else {

    $retrieve_item = "";
    if ($form->{type} eq 'purchase_order' || $form->{type} eq 'request_quotation') {
      $retrieve_item = "IR::retrieve_item";
    }
    if ($form->{type} eq 'sales_order' || $form->{type} eq 'sales_quotation') {
      $retrieve_item = "IS::retrieve_item";
    }

    &{ "$retrieve_item" }("", \%myconfig, \%$form);
    
    $rows = scalar @{ $form->{item_list} };

    if ($form->{language_code} && $rows == 0) {
      $language_code = $form->{language_code};
      $form->{language_code} = "";
      if ($retrieve_item) {
	&{ "$retrieve_item" }("", \%myconfig, \%$form);
      }
      $form->{language_code} = $language_code;
      $rows = scalar @{ $form->{item_list} };
    }
    
    if ($rows) {
      
      if ($rows > 1) {
	
	&select_item;
	exit;
	
      } else {

        $form->{"qty_$i"} = ($form->{"qty_$i"} * 1) ? $form->{"qty_$i"} : 1;
	$form->{"reqdate_$i"} = $form->{reqdate} if $form->{type} ne 'sales_quotation';
	$sellprice = $form->parse_amount(\%myconfig, $form->{"sellprice_$i"});
	
	for (qw(partnumber description unit)) { $form->{item_list}[$i]{$_} = $form->quote($form->{item_list}[$i]{$_}) }
	for (keys %{ $form->{item_list}[0] }) { $form->{"${_}_$i"} = $form->{item_list}[0]{$_} }

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

	for (qw(listprice lastcost)) { $form->{"${_}_$i"} /= $form->{exchangerate} }

	$form->{"sell_$i"} = $form->{"sellprice_$i"} if $form->{vc} eq 'customer';

        $sellprice = $form->{"sellprice_$i"} * (1 - $form->{"discount_$i"} / 100);
	$amount = $sellprice * $form->{"qty_$i"};
	for (split / /, $form->{taxaccounts}) { $form->{"${_}_base"} = 0 }
	for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $amount }
	if (!$form->{taxincluded}) {
	  for (split / /, $form->{taxaccounts}) { $amount += ($form->{"${_}_base"} * $form->{"${_}_rate"}) }
	}
	
	$form->{creditremaining} -= $amount;

	for (qw(sell sellprice listprice)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces1) }
	$form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"}, $decimalplaces2);
	
	$form->{"oldqty_$i"} = $form->{"qty_$i"};

	for (qw(netweight grossweight)) { $form->{"${_}_$i"} = $form->{"weight_$i"} * $form->{"qty_$i"} }

	for (qw(qty discount netweight grossweight)) { $form->{"{_}_$i"} =  $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }

      }

      $i++;
      $focus = "partnumber_$i";
      
      &display_form;

    } else {
      # ok, so this is a new part
      # ask if it is a part or service item

      if (($form->{"partsgroup_$i"} || $form->{"partsgroupcode_$i"}) && ($form->{"partsnumber_$i"} eq "") && ($form->{"description_$i"} eq "")) {
	$form->{rowcount}--;
	&display_form;
      } else {
		
	$form->{"id_$i"}	= 0;
	$form->{"unit_$i"}	= $locale->text('ea');
	&new_item;

      }
    }
  }

}



sub search {

  $requiredby = $locale->text('Required by');

  if ($form->{type} eq 'purchase_order') {
    $form->{title} = $locale->text('Purchase Orders');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Employee');
  }
  
  if ($form->{type} eq 'receive_order') {
    $form->{title} = $locale->text('Receive Merchandise');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Employee');
  }
  
  if ($form->{type} eq 'consolidate_sales_order') {
    $form->{title} = $locale->text('Consolidate Sales Orders');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Salesperson');
  }

  if ($form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Request for Quotations');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('RFQ Number');
    $ordnumber = 'quonumber';
    $employee = $locale->text('Employee');
  }
  
  if ($form->{type} eq 'sales_order') {
    $form->{title} = $locale->text('Sales Orders');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Salesperson');
  }
  
  if ($form->{type} eq 'ship_order') {
    $form->{title} = $locale->text('Ship Merchandise');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Salesperson');
  }
  
  if ($form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Quotations');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Quotation Number');
    $ordnumber = 'quonumber';
    $employee = $locale->text('Employee');
    $requiredby = $locale->text('Valid until');
  }

  if ($form->{type} eq 'generate_purchase_order') {
    $form->{title} = $locale->text('Generate Purchase Orders from Sales Order');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Salesperson');
    $detail = qq|
                <tr>
		  <td><input name=detail type=radio class=radio value=0 checked> |.$locale->text('Summary').qq|</td>
		  <td><input name=detail type=radio class=radio value=1> |.$locale->text('Detail').qq|
		  </td>
		</tr>
|;
  }
  
  if ($form->{type} eq 'consolidate_purchase_order') {
    $form->{title} = $locale->text('Consolidate Purchase Orders');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Employee');
  }
 
  $l_employee = qq|<input name="l_employee" class=checkbox type=checkbox value=Y> $employee|;

  # setup vendor / customer selection
  $transdate = $form->current_date(\%myconfig);
  $form->all_vc(\%myconfig, $form->{vc}, ($form->{vc} eq 'customer') ? "AR" : "AP", undef, $transdate);
 
  $vcname = $locale->text('Customer');
  $vcnumber = $locale->text('Customer Number');
  $l_name = qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> $vcname|;
  $l_customernumber = qq|<input name="l_customernumber" class=checkbox type=checkbox value=Y> $vcnumber|;
  
  if ($form->{vc} eq 'vendor') {
    $vcname = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
    $l_customernumber = "";
    $l_name = qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> $vcname|;
    $l_vendornumber = qq|<input name="l_vendornumber" class=checkbox type=checkbox value=Y> $vcnumber|;
  }
  

  if (@{ $form->{"all_$form->{vc}"} }) {
    $vc = qq|
         <tr>
	   <th align=right nowrap>$vcname</th>
	   <td colspan=3><select name=$form->{vc}><option>\n|;
    
    for (@{ $form->{"all_$form->{vc}"} }) { $vc .= qq|<option value="|.$form->quote($_->{name}).qq|--$_->{id}">$_->{name}\n| }

    $vc .= qq|</select>
           </td>
	 </tr>
|;
  } else {
    $vc = qq|
              <tr>
	        <th align=right nowrap>$vcname</th>
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

  # warehouse
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


  $selectemployee = "";
  if (@{ $form->{all_employee} }) {
    $selectemployee = "<option>\n";
    for (@{ $form->{all_employee} }) { $selectemployee .= qq|<option value="|.$form->quote($_->{name}).qq|--$_->{id}">$_->{name}\n| }

    $selectemployee = qq|
      <tr>
	<th align=right>$employee</th>
	<td colspan=3><select name=employee>$selectemployee</select></td>
      </tr>
|;
  } else {
    $l_employee = "";
  }

  # departments  
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "<option>\n";

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|<option value="|.$form->quote($_->{description}).qq|--$_->{id}">$_->{description}\n| }
  }

  $department = qq|  
        <tr>  
	  <th align=right nowrap>|.$locale->text('Department').qq|</th>
	  <td colspan=3><select name=department>$form->{selectdepartment}</select></td>
	</tr>
| if $form->{selectdepartment}; 

  if ($form->{type} =~ /(consolidate.*|generate.*|ship|receive)_order/) {
     
    $openclosed = qq|
	        <input type=hidden name="open" value=1>
|;

  } else {
   
    $openclosed = qq|
	      <tr>
	        <td nowrap><input name="open" class=checkbox type=checkbox value=1 checked> |.$locale->text('Open').qq|</td>
	        <td nowrap><input name="closed" class=checkbox type=checkbox value=1 $form->{closed}> |.$locale->text('Closed').qq|</td>
	      </tr>
|;
  }

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

  if ($form->{type} =~ /_order/) {
    $ponumber = qq|
        <tr>
          <th align=right>|.$locale->text('PO Number').qq|</th>
          <td colspan=3><input name="ponumber" size=20></td>
        </tr>
|;


    $l_ponumber = qq|<input name="l_ponumber" class=checkbox type=checkbox value=Y> |.$locale->text('PO Number');
  }

  @a = ();
  push @a, qq|<input name="l_runningnumber" class=checkbox type=checkbox value=Y> |.$locale->text('No.');
  push @a, qq|<input name="l_id" class=checkbox type=checkbox value=Y> |.$locale->text('ID');
  push @a, qq|<input name="l_$ordnumber" class=checkbox type=checkbox value=Y checked> $ordlabel|;
  push @a, qq|<input name="l_description" class=checkbox type=checkbox value=Y checked> |.$locale->text('Description');
  push @a, qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked> |.$locale->text('Date');
  push @a, $l_ponumber if $l_ponumber;
  push @a, qq|<input name="l_reqdate" class=checkbox type=checkbox value=Y checked> $requiredby|;
  push @a, qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> $vcname|;
  push @a, qq|<input name="l_$form->{vc}number" class=checkbox type=checkbox value=Y checked> $vcnumber|;
  push @a, $l_employee if $l_employee;
  push @a, $l_warehouse if $l_warehouse;
  push @a, qq|<input name="l_shippingpoint" class=checkbox type=checkbox value=Y> |.$locale->text('Shipping Point');
  push @a, qq|<input name="l_shipvia" class=checkbox type=checkbox value=Y> |.$locale->text('Ship via');
  push @a, qq|<input name="l_waybill" class=checkbox type=checkbox value=Y> |.$locale->text('Waybill');
  push @a, qq|<input name="l_netamount" class=checkbox type=checkbox value=Y> |.$locale->text('Amount');
  push @a, qq|<input name="l_tax" class=checkbox type=checkbox value=Y> |.$locale->text('Tax');
  push @a, qq|<input name="l_amount" class=checkbox type=checkbox value=Y checked> |.$locale->text('Total');
  push @a, qq|<input name="l_curr" class=checkbox type=checkbox value=Y checked> |.$locale->text('Currency');
  push @a, qq|<input name="l_memo" class=checkbox type=checkbox value=Y> |.$locale->text('Line Item');
  push @a, qq|<input name="l_notes" class=checkbox type=checkbox value=Y> |.$locale->text('Notes');

  $form->helpref("search_$form->{type}", $myconfig{countrycode});

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
      <table>
        $vc
	$department
	$selectemployee
        <tr>
          <th align=right>$ordlabel</th>
          <td colspan=3><input name="$ordnumber" size=20></td>
        </tr>
	$ponumber
        <tr>
          <th align=right>|.$locale->text('Description').qq|</th>
          <td colspan=3><input name="description" size=40></td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('Notes').qq|</th>
          <td colspan=3><input name="notes" size=40></td>
        </tr>
	$warehouse
        <tr>
          <th align=right>|.$locale->text('Shipping Point').qq|</th>
          <td colspan=3><input name="shippingpoint" size=40></td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('Ship via').qq|</th>
          <td colspan=3><input name="shipvia" size=40></td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('Waybill').qq|</th>
          <td colspan=3><input name="waybill" size=40></td>
        </tr>

        <tr>
          <th align=right>|.$locale->text('From').qq|</th>
          <td><input name=transdatefrom size=11 class=date title="$myconfig{dateformat}"></td>
          <th align=right>|.$locale->text('To').qq|</th>
          <td><input name=transdateto size=11 class=date title="$myconfig{dateformat}"></td>
        </tr>
        <input type=hidden name=sort value=transdate>
	$selectfrom
        <tr>
          <th align=right>|.$locale->text('Include in Report').qq|</th>
          <td colspan=3>
	    <table>
	      $openclosed
	      $detail
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
	        <td><input name="l_subtotal" class=checkbox type=checkbox value=Y> |.$locale->text('Subtotal').qq|</td>
	      </tr>
	    </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr><td colspan=4><hr size=3 noshade></td></tr>
</table>

<br>
<input type=hidden name=nextsub value=transactions>
|;

  $form->hide_form(qw(path login vc type));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
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
  
  # split vendor / customer
  ($form->{$form->{vc}}, $form->{"$form->{vc}_id"}) = split(/--/, $form->{$form->{vc}});

  OE->transactions(\%myconfig, \%$form);

  $ordnumber = ($form->{type} =~ /_order/) ? 'ordnumber' : 'quonumber';
  $name = $form->escape($form->{$form->{vc}});
  $name .= qq|--$form->{"$form->{vc}_id"}| if $form->{"$form->{vc}_id"};
  
  $form->helpref("list_$form->{type}", $myconfig{countrycode});
  
  # construct href
  $href = qq|$form->{script}?action=transactions|;
  for (qw(oldsort direction path type vc login)) { $href .= qq|&$_=$form->{$_}| }

  # construct callback
  $name = $form->escape($form->{$form->{vc}},1);
  $name .= qq|--$form->{"$form->{vc}_id"}| if $form->{"$form->{vc}_id"};
  
  $form->sort_order();
  
  $callback = qq|$form->{script}?action=transactions|;
  for (qw(oldsort direction path type vc login)) { $callback .= qq|&$_=$form->{$_}| }

  if ($form->{$form->{vc}}) {
    $callback .= "&$form->{vc}=".$form->escape($form->{$form->{vc}},1).qq|--$form->{"$form->{vc}_id"}|;
    $href .= "&$form->{vc}=".$form->escape($form->{$form->{vc}}).qq|--$form->{"$form->{vc}_id"}|;
    $name = ($form->{vc} eq 'customer') ? $locale->text('Customer') : $locale->text('Vendor');
    $option = "$name : $form->{$form->{vc}}";
  }
  if ($form->{"$form->{vc}number"}) {
    $callback .= "&$form->{vc}number=".$form->escape($form->{"$form->{vc}number"},1);
    $href .= "&$form->{vc}number=".$form->escape($form->{"$form->{vc}number"},1);
    $name = ($form->{vc} eq 'customer') ? $locale->text('Customer Number') : $locale->text('Vendor Number');
    $option = qq|$name : $form->{"$form->{vc}number"}|;
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
    if ($form->{vc} eq 'customer') {
      $option .= $locale->text('Salesperson');
    } else {
      $option .= $locale->text('Employee');
    }
    $option .= " : $employee";
  }
  if ($form->{ordnumber}) {
    $callback .= "&ordnumber=".$form->escape($form->{ordnumber},1);
    $href .= "&ordnumber=".$form->escape($form->{ordnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Order Number')." : $form->{ordnumber}";
  }
  if ($form->{quonumber}) {
    $callback .= "&quonumber=".$form->escape($form->{quonumber},1);
    $href .= "&quonumber=".$form->escape($form->{quonumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Quotation Number')." : $form->{quonumber}";
  }
  if ($form->{ponumber}) {
    $callback .= "&ponumber=".$form->escape($form->{ponumber},1);
    $href .= "&ponumber=".$form->escape($form->{ponumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('PO Number')." : $form->{ponumber}";
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
  if ($form->{notes}) {
    $callback .= "&notes=".$form->escape($form->{notes},1);
    $href .= "&notes=".$form->escape($form->{notes});
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Notes')." : $form->{notes}";
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $href .= "&description=".$form->escape($form->{description});
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Description')." : $form->{description}";
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
 
  @columns = $form->sort_columns("transdate", "reqdate", "id", "$ordnumber", "ponumber", "name", "$form->{vc}number", "description", "memo", "notes", "netamount", "tax", "amount", "curr", "employee", "warehouse", "shippingpoint", "shipvia", "waybill", "open", "closed");
  unshift @columns, "runningnumber";

  $form->{l_open} = $form->{l_closed} = "Y" if ($form->{open} && $form->{closed}) ;
  $form->{l_memo} = "Y" if $form->{detail};

  for (@columns) {
    if ($form->{"l_$_"} eq "Y") {
      push @column_index, $_;

      if ($form->{l_curr} && $_ =~ /(amount|tax)/) {
	push @column_index, "fx_$_";
      }
      
      # add column to href and callback
      $callback .= "&l_$_=Y";
      $href .= "&l_$_=Y";
    }
  }
  
  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
    $href .= "&l_subtotal=Y";
  }
 
  $requiredby = $locale->text('Required by');

  $i = 1; 
  if ($form->{vc} eq 'vendor') {
    if ($form->{type} eq 'receive_order') {
      $form->{title} = $locale->text('Receive Merchandise');
    }
    if ($form->{type} eq 'purchase_order') {
      $form->{title} = $locale->text('Purchase Orders');
      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Purchase Order'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Purchase Order').qq|"> |;
	$button{'Order Entry--Purchase Order'}{order} = $i++;
      }
    }
    if ($form->{type} eq 'consolidate_purchase_order') {
      $form->{title} = $locale->text('Purchase Orders');
      $form->{type} = "purchase_order";
      unshift @column_index, "ndx";
      $ndx = 1;
      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Purchase Order'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Consolidate Orders').qq|"> |;
	$button{'Order Entry--Purchase Order'}{order} = $i++;
      }
    }

    if ($form->{type} eq 'request_quotation') {
      $form->{title} = $locale->text('Request for Quotations');
      $quotation = $locale->text('RFQ');

      if ($myconfig{acs} !~ /Quotations--Quotations/) {
	$button{'Quotations--RFQ'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('RFQ ').qq|"> |;
	$button{'Quotations--RFQ'}{order} = $i++;
      }
      
    }
    $name = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
    $employee = $locale->text('Employee');
  }
  if ($form->{vc} eq 'customer') {
    if ($form->{type} eq 'sales_order') {
      $form->{title} = $locale->text('Sales Orders');
      $employee = $locale->text('Salesperson');

      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Sales Order'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Sales Order').qq|"> |;
	$button{'Order Entry--Sales Order'}{order} = $i++;
      }

    }
    if ($form->{type} eq 'generate_purchase_order') {
      $form->{title} = $locale->text('Sales Orders');
      $form->{type} = "sales_order";
      $employee = $locale->text('Salesperson');
      unshift @column_index, "ndx";
      $ndx = 1;
      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Purchase Order'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Generate Purchase Orders').qq|"> |;
	$button{'Order Entry--Purchase Order'}{order} = $i++;
      }
      $callback .= "&detail=$form->{detail}";
      $href .= "&detail=$form->{detail}";
    }
    if ($form->{type} eq 'consolidate_sales_order') {
      $form->{title} = $locale->text('Sales Orders');
      $form->{type} = "sales_order";
      unshift @column_index, "ndx";
      $ndx = 1;
      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Sales Order'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Consolidate Orders').qq|"> |;
	$button{'Order Entry--Sales Order'}{order} = $i++;
      }
    }

    if ($form->{type} eq 'ship_order') {
      $form->{title} = $locale->text('Ship Merchandise');
      $employee = $locale->text('Salesperson');
    }
    if ($form->{type} eq 'sales_quotation') {
      $form->{title} = $locale->text('Quotations');
      $employee = $locale->text('Employee');
      $requiredby = $locale->text('Valid until');
      $quotation = $locale->text('Quotation');

      if ($myconfig{acs} !~ /Quotations--Quotations/) {
	$button{'Quotations--Quotation'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Quotation ').qq|"> |;
	$button{'Quotations--Quotation'}{order} = $i++;
      }
      
    }
    $name = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
  }

  for (split /;/, $myconfig{acs}) { delete $button{$_} }

  if ($ndx) {
    $column_header{ndx} = qq|
<script language="javascript">
<!--

function CheckAll() {

  var frm = document.forms[0]
  var el = frm.elements
  var re = /ndx_/;

  for (i = 0; i < el.length; i++) {
    if (el[i].type == 'checkbox' && re.test(el[i].name)) {
      el[i].checked = frm.allbox_select.checked
    }
  }
}
// -->
</script>

<th class=listheading width=1%><input name="allbox_select" type=checkbox class=checkbox value="1" checked onChange="CheckAll();"></th>|;
  }
  
  $column_header{runningnumber} = qq|<th class=listheading>&nbsp;</th>|;
  $column_header{id} = qq|<th><a class=listheading href=$href&sort=id>|.$locale->text('ID').qq|</a></th>|;
  $column_header{transdate} = qq|<th><a class=listheading href=$href&sort=transdate>|.$locale->text('Date').qq|</a></th>|;
  $column_header{reqdate} = qq|<th><a class=listheading href=$href&sort=reqdate>$requiredby</a></th>|;
  $column_header{ordnumber} = qq|<th><a class=listheading href=$href&sort=ordnumber>|.$locale->text('Order').qq|</a></th>|;
  $column_header{ponumber} = qq|<th><a class=listheading href=$href&sort=ponumber>|.$locale->text('PO Number').qq|</a></th>|;
  $column_header{quonumber} = qq|<th><a class=listheading href=$href&sort=quonumber>$quotation</a></th>|;
  $column_header{name} = qq|<th><a class=listheading href=$href&sort=name>$name</a></th>|;
  $column_header{"$form->{vc}number"} = qq|<th><a class=listheading href=$href&sort=$form->{vc}number>$vcnumber</a></th>|;
  $column_header{netamount} = qq|<th class=listheading>|.$locale->text('Amount').qq|</th>|;
  $column_header{tax} = qq|<th class=listheading>|.$locale->text('Tax').qq|</th>|;
  $column_header{amount} = qq|<th class=listheading>|.$locale->text('Total').qq|</th>|;
  $column_header{curr} = qq|<th><a class=listheading href=$href&sort=curr>|.$locale->text('Curr').qq|</a></th>|;
  $column_header{warehouse} = qq|<th><a class=listheading href=$href&sort=warehouse>|.$locale->text('Warehouse').qq|</a></th>|;
  $column_header{shippingpoint} = qq|<th><a class=listheading href=$href&sort=shippingpoint>|.$locale->text('Shipping Point').qq|</a></th>|;
  $column_header{shipvia} = qq|<th><a class=listheading href=$href&sort=shipvia>|.$locale->text('Ship via').qq|</a></th>|;
  $column_header{waybill} = qq|<th><a class=listheading href=$href&sort=waybill>|.$locale->text('Waybill').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_header{memo} = "<th class=listheading>" . $locale->text('Line Item') . "</th>";
  $column_header{notes} = qq|<th class=listheading>|.$locale->text('Notes').qq|</th>|;
  $column_header{open} = qq|<th class=listheading>|.$locale->text('O').qq|</th>|;
  $column_header{closed} = qq|<th class=listheading>|.$locale->text('C').qq|</th>|;

  $column_header{employee} = qq|<th><a class=listheading href=$href&sort=employee>$employee</a></th>|;

  for (qw(amount tax netamount)) { $column_header{"fx_$_"} = "<th>&nbsp;</th>" }
  
  $title = "$form->{title} / $form->{company}";
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

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
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
	</tr>
|;

  # add sort and escape callback
  $callback .= "&sort=$form->{sort}";
  $form->{callback} = $callback;
  $callback = $form->escape($callback);

  if (@{ $form->{OE} }) {
    $sameitem = $form->{OE}->[0]->{$form->{sort}};
  }

  $action = "edit";
  $action = "ship_receive" if ($form->{type} =~ /(ship|receive)_order/);

  $warehouse = $form->escape($form->{warehouse});

  $i = 0;
  foreach $ref (@{ $form->{OE} }) {

    $i++;

    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&subtotal;
	$sameitem = $ref->{$form->{sort}};
      }
    }
    
    if ($form->{l_curr}) {
      for (qw(netamount amount)) { $ref->{"fx_$_"} = $ref->{$_} }
      $ref->{fx_tax} = $ref->{fx_amount} - $ref->{fx_netamount};
      for (qw(netamount amount)) { $ref->{$_} *= $ref->{exchangerate} }

      for (qw(netamount amount)) { $column_data{"fx_$_"} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{"fx_$_"}, $form->{precision}, "&nbsp;")."</td>" }
      $column_data{fx_tax} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{fx_amount} - $ref->{fx_netamount}, $form->{precision}, "&nbsp;")."</td>";
      
      $totalfxnetamount += $ref->{fx_netamount}; 
      $totalfxamount += $ref->{fx_amount};

      $subtotalfxnetamount += $ref->{fx_netamount};
      $subtotalfxamount += $ref->{fx_amount};
    }
    
    for (qw(netamount amount)) { $column_data{$_} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}, "&nbsp;")."</td>" }
    $column_data{tax} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} - $ref->{netamount}, $form->{precision}, "&nbsp;")."</td>";

    $totalnetamount += $ref->{netamount};
    $totalamount += $ref->{amount};

    $subtotalnetamount += $ref->{netamount};
    $subtotalamount += $ref->{amount};

    for (qw(notes description memo)) { $ref->{$_} =~ s/\r?\n/<br>/g }
    for (qw(id description memo)) { $column_data{$_} = "<td>$ref->{$_}</td>" }
    $column_data{transdate} = qq|<td nowrap><input type=hidden name="transdate_$i" value="$ref->{transdate}">$ref->{transdate}&nbsp;</td>|;
    $column_data{reqdate} = "<td nowrap>$ref->{reqdate}&nbsp;</td>";

    $column_data{runningnumber} = qq|<td align=right>$i</td>|;
    $id = ($ref->{orderitemsid}) ? "$ref->{id}--$ref->{orderitemsid}" : $ref->{id};
    $column_data{ndx} = qq|<td><input name="ndx_$i" class=checkbox type=checkbox value="$id" checked></td>|;
    $column_data{$ordnumber} = "<td><a href=$form->{script}?path=$form->{path}&action=$action&type=$form->{type}&id=$ref->{id}&warehouse=$warehouse&vc=$form->{vc}&login=$form->{login}&callback=$callback>$ref->{$ordnumber}</a></td>";

    $name = $form->escape($ref->{name});
    $column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{"$form->{vc}_id"}&db=$form->{vc}&callback=$callback>$ref->{name}</a></td>|;
    $column_data{"$form->{vc}number"} = qq|<td>$ref->{"$form->{vc}number"}</td>|;

    for (qw(employee warehouse shipvia shippingpoint waybill curr ponumber notes)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

    if ($ref->{closed}) {
      $column_data{closed} = "<td align=center>*</td>";
      $column_data{open} = "<td>&nbsp;</td>";
    } else {
      $column_data{closed} = "<td>&nbsp;</td>";
      $column_data{open} = "<td align=center>*</td>";
    }

    if ($ref->{id} != $sameid) {
      $j++; $j %= 2;
    }
    
    print "
        <tr class=listrow$j>";
    
    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>
|;

    $sameid = $ref->{id};

  }
  
  if ($form->{l_subtotal} eq 'Y') {
    &subtotal;
  }
  
  # print totals
  print qq|
        <tr class=listtotal>|;
  
  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $column_data{netamount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalnetamount, $form->{precision}, "&nbsp;")."</th>";
  $column_data{tax} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount - $totalnetamount, $form->{precision}, "&nbsp;")."</th>";
  $column_data{amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount, $form->{precision}, "&nbsp;")."</th>";

  if ($form->{l_curr} && $form->{sort} eq 'curr' && $form->{l_subtotal}) {
    $column_data{fx_netamount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxnetamount, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_tax} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxamount - $totalfxnetamount, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalfxamount, $form->{precision}, "&nbsp;")."</th>";
  }

  for (@column_index) { print "\n$column_data{$_}" }
 
  print qq|
        </tr>
      </td>
    </table>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
|;

  $form->hide_form(qw(callback type vc path login department ordnumber ponumber detail sort));
  
  print qq|

<input type=hidden name=rowcount value=$i>
|;

  $form->hide_form("vc", "$form->{vc}_id");

  if ($form->{type} !~ /(ship|receive)_order/) {
    for (sort { $a->{order} <=> $b->{order} } %button) { print $_->{code} }
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
  
  $column_data{netamount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalnetamount, $form->{precision}, "&nbsp;")."</th>";
  $column_data{tax} = "<td class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount - $subtotalnetamount, $form->{precision}, "&nbsp;")."</th>";
  $column_data{amount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount, $form->{precision}, "&nbsp;")."</th>";

  if ($form->{l_curr} && $form->{sort} eq 'curr' && $form->{l_subtotal}) {
    $column_data{fx_netamount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxnetamount, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_tax} = "<td class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxamount - $subtotalfxnetamount, $form->{precision}, "&nbsp;")."</th>";
    $column_data{fx_amount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxamount, $form->{precision}, "&nbsp;")."</th>";
  }

  $subtotalnetamount = 0;
  $subtotalamount = 0;
  
  $subtotalfxnetamount = 0;
  $subtotalfxamount = 0;

  print "
        <tr class=listsubtotal>
";
  
  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;

}


sub save {

  if ($form->{type} =~ /_order$/) {
    $msg = $locale->text('Order Date missing!');
  } else {
    $msg = $locale->text('Quotation Date missing!');
  }
  
  $form->isblank("transdate", $msg);

  $msg = ucfirst $form->{vc};
  $form->isblank($form->{vc}, $locale->text($msg . " missing!"));

# $locale->text('Customer missing!');
# $locale->text('Vendor missing!');
  
  $form->isblank("exchangerate", $locale->text('Exchange rate missing!')) if ($form->{currency} ne $form->{defaultcurrency});
  
  &validate_items;

  # if the name changed get new values
  if (&check_name($form->{vc})) {
    &update;
    exit;
  }


  # this is for the internal notes section for the [email] Subject
  if ($form->{type} =~ /_order$/) {
    if ($form->{type} eq 'sales_order') {
      $form->{label} = $locale->text('Sales Order');

      $numberfld = "sonumber";
      $ordnumber = "ordnumber";
    } else {
      $form->{label} = $locale->text('Purchase Order');
      
      $numberfld = "ponumber";
      $ordnumber = "ordnumber";
    }

    $err = $locale->text('Cannot save order!');
    
  } else {
    if ($form->{type} eq 'sales_quotation') {
      $form->{label} = $locale->text('Quotation');
      
      $numberfld = "sqnumber";
      $ordnumber = "quonumber";
    } else {
      $form->{label} = $locale->text('Request for Quotation');

      $numberfld = "rfqnumber";
      $ordnumber = "quonumber";
    }
      
    $err = $locale->text('Cannot save quotation!');
 
  }

  if (! $form->{repost}) {
    if ($form->{id}) {
      &repost("Save");
      exit;
    }
  }
  
  if (OE->save(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Order saved!'));
  } else {
    $form->error($err);
  }

}


sub print_and_save {

  $form->error($locale->text('Select a Printer!')) if $form->{media} eq 'screen';

  $oldform = new Form;
  $form->{display_form} = "save";
  for (keys %$form) { $oldform->{$_} = $form->{$_} }
  $oldform->{rowcount}++;

  &print_form($oldform);

}


sub delete {

  $form->header;

  if ($form->{type} =~ /_order$/) {
    $msg = $locale->text('Are you sure you want to delete Order Number');
    $ordnumber = 'ordnumber';
  } else {
    $msg = $locale->text('Are you sure you want to delete Quotation Number');
    $ordnumber = 'quonumber';
  }
  
  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->{action} = "yes";
  $form->hide_form;

  print qq|
<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>

<h4>$msg $form->{$ordnumber}</h4>
<p>
<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>

</body>
</html>
|;


}



sub yes {

  if ($form->{type} =~ /_order$/) {
    $msg = $locale->text('Order deleted!');
    $err = $locale->text('Cannot delete order!');
  } else {
    $msg = $locale->text('Quotation deleted!');
    $err = $locale->text('Cannot delete quotation!');
  }
  
  if (OE->delete(\%myconfig, \%$form, $spool)) {
    $form->redirect($msg);
  } else {
    $form->error($err);
  }

}


sub vendor_invoice { &invoice };
sub sales_invoice { &invoice };

sub invoice {

  if ($form->{type} =~ /_order$/) {
    $form->isblank("ordnumber", $locale->text('Order Number missing!'));
    $form->isblank("transdate", $locale->text('Order Date missing!'));
  } else {
    $form->isblank("quonumber", $locale->text('Quotation Number missing!'));
    $form->isblank("transdate", $locale->text('Quotation Date missing!'));
    $form->{ordnumber} = "";
  }

  # if the name changed get new values
  if (&check_name($form->{vc})) {
    &update;
    exit;
  }


  # close orders/quotations
  $form->{closed} = 1;

  $totalship = 0;
  for $i (1 .. $form->{rowcount}) {
    $totalship += abs($form->parse_amount(\%myconfig, $form->{"ship_$i"}));
  }
  if ($form->round_amount($totalship, 1) == 0) {
    for $i (1 .. $form->{rowcount}) { $form->{"ship_$i"} = $form->{"qty_$i"} }
  }

  OE->save(\%myconfig, \%$form);
  
  $form->{order_id} = $form->{id} if $form->{type} =~ /_order$/;

  $form->{id} = '';
  $form->{closed} = 0;
  $form->{rowcount}--;
  $form->{shipto} = 1;
  
  if ($form->{type} =~ /_order$/) {
    &create_backorder;
  }

  $form->{id} = '';
  
  if ($form->{type} eq 'purchase_order' || $form->{type} eq 'request_quotation') {
    $form->{script} = 'ir.pl';
    $script = "ir";
  }
  if ($form->{type} eq 'sales_order' || $form->{type} eq 'sales_quotation') {
    $form->{script} = 'is.pl';
    $script = "is";
  }

  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->current_date(\%myconfig));
  }
  
  for (qw(id subject message printed emailed queued)) { delete $form->{$_} }
  $form->{$form->{vc}} =~ s/--.*//g;
  $form->{type} = "invoice";
  $form->{formname} = "invoice";
 
  # locale messages
  $locale = new Locale "$myconfig{countrycode}", "$script";

  require "$form->{path}/$form->{script}";

  # customized scripts
  if (-f "$form->{path}/custom_$form->{script}") {
    eval { require "$form->{path}/custom_$form->{script}"; };
  }

  # customized scripts for login
  if (-f "$form->{path}/$form->{login}_$form->{script}") {
    eval { require "$form->{path}/$form->{login}_$form->{script}"; };
  }

  for ("$form->{vc}", "currency") { $form->{"select$_"} = "" }
  for (qw(currency oldcurrency exchangerate employee department warehouse intnotes notes taxincluded)) { $temp{$_} = $form->{$_} }

  $form->{warehouse} =~ s/--.*//;

  $form->{transdate} = $form->current_date(\%myconfig);
  
  &invoice_links;

  $form->{creditremaining} -= ($form->{oldinvtotal} - $form->{ordtotal});
  
  &prepare_invoice;

  for (keys %temp) { $form->{$_} = $temp{$_} }

  for $i (1 .. $form->{rowcount}) {
    $form->{"deliverydate_$i"} = $form->{"reqdate_$i"};
    for (qw(qty sellprice discount)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }
  }

  for (qw(audittrail recurring)) { delete $form->{$_} }

  &display_form;

}



sub create_backorder {
  
  $form->{shipped} = 1;
 
  # figure out if we need to create a backorder
  # items aren't saved if qty != 0

  $dec1 = $dec2 = 0;
  $totalqty = 0;
  $totalship = 0;
  
  for $i (1 .. $form->{rowcount}) {
    ($dec) = ($form->{"qty_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $dec1 = ($dec > $dec1) ? $dec : $dec1;
    
    ($dec) = ($form->{"ship_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $dec2 = ($dec > $dec2) ? $dec : $dec2;
    
    $totalqty += $qty = $form->{"qty_$i"};
    $totalship += $ship = $form->{"ship_$i"};
    
    $form->{"qty_$i"} = $qty - $ship;
  }

  $totalqty = $form->round_amount($totalqty, $dec1);
  $totalship = $form->round_amount($totalship, $dec2);

  if ($totalship == 0) {
    for (1 .. $form->{rowcount}) { $form->{"ship_$_"} = $form->{"qty_$_"} }
    $form->{ordtotal} = 0;
    $form->{shipped} = 0;
    return;
  }

  if ($totalqty == $totalship) {
    for (1 .. $form->{rowcount}) { $form->{"qty_$_"} = $form->{"ship_$_"} }
    $form->{ordtotal} = 0;
    return;
  }

  @flds = qw(partnumber description lineitemdetail qty ship unit sellprice discount oldqty oldship orderitems_id id bin weight listprice lastcost taxaccounts pricematrix sku onhand bin assembly inventory_accno_id income_accno_id expense_accno_id deliverydate reqdate itemnotes serialnumber ordernumber customerponumber projectnumber package netweight grossweight volume partsgroup);

  for $i (1 .. $form->{rowcount}) {
    for (qw(qty sellprice discount)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    $form->{"oldship_$i"} = $form->{"ship_$i"};
    $form->{"ship_$i"} = 0;
  }

  # clear flags
  for (qw(id subject message cc bcc printed emailed queued audittrail)) { delete $form->{$_} }

  OE->save(\%myconfig, \%$form);
 
  # rebuild rows for invoice
  @f = ();
  $count = 0;

  for $i (1 .. $form->{rowcount}) {
    $form->{"qty_$i"} = $form->{"oldship_$i"};
    $form->{"oldqty_$i"} = $form->{"qty_$i"};
    
    $form->{"orderitems_id_$i"} = "";

    if ($form->{"qty_$i"}) {
      push @f, {};
      $j = $#f;
      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
 
  $form->redo_rows(\@flds, \@f, $count, $form->{rowcount});
  $form->{rowcount} = $count;

}



sub save_as_new {

  for (qw(closed id printed emailed queued)) { delete $form->{$_} }
  &save;

}


sub print_and_save_as_new {

  for (qw(closed id printed emailed queued)) { delete $form->{$_} }
  &print_and_save;

}


sub ship_receive {

  &order_links;

  &prepare_order;

  # warehouse
  if (@{ $form->{all_warehouse} }) {
    $form->{selectwarehouse} = "\n";
    if ($form->{warehouse}) {
      $form->{selectwarehouse} = $form->{warehouse};
    } else {
      for (@{ $form->{all_warehouse} }) { $form->{selectwarehouse} .= qq|$_->{description}--$_->{id}\n| }
    }
    $form->{selectwarehouse} = $form->escape($form->{selectwarehouse},1);
  }

  $form->{shippingdate} = $form->current_date(\%myconfig);
  $form->{"$form->{vc}"} =~ s/--.*//;
  $form->{"old$form->{vc}"} = qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;

  @flds = ();
  @a = ();
  $count = 0;
  foreach $key (keys %$form) {
    if ($key =~ /_1$/) {
      $key =~ s/_1//;
      push @flds, $key;
    }
  }
  
  for $i (1 .. $form->{rowcount}) {
    # undo formatting from prepare_order
    for (qw(qty ship)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    $n = ($form->{"qty_$i"} -= $form->{"ship_$i"});
    if (abs($n) > 0) {
      $form->{"ship_$i"} = "";
      $form->{"serialnumber_$i"} = "";

      push @f, {};
      $j = $#f;

      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
  
  $form->redo_rows(\@flds, \@f, $count, $form->{rowcount});
  $form->{rowcount} = $count;
  
  &display_ship_receive;
  
}


sub display_ship_receive {
  
  $form->{rowcount}++;

  if ($form->{vc} eq 'customer') {
    $form->{title} = $locale->text('Ship Merchandise');
    $shipped = $locale->text('Shipping Date');
    $vcname = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
  } else {
    $form->{title} = $locale->text('Receive Merchandise');
    $shipped = $locale->text('Date Received');
    $vcname = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
  }
  
  $warehouse = qq|
	      <tr>
		<th align=right>|.$locale->text('Warehouse').qq|</th>
		<td><select name=warehouse>|
		.$form->select_option($form->{selectwarehouse}, $form->{warehouse}, 1)
		.qq|</select>
		</td>
	      </tr>
| if $form->{selectwarehouse};

  $employee = qq|
 	      <tr>
	        <th align=right nowrap>|.$locale->text('Contact').qq|</th>
		<td><select name=employee>|
		.$form->select_option($form->{selectemployee}, $form->{employee}, 1)
		.qq|</select>
		</td>
	      </tr>
|;

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


  $form->helpref($form->{type}, $myconfig{countrycode});
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=display_form value=display_ship_receive>
|;

  $form->hide_form(qw(id type printed emailed queued vc weightunit description));
  $form->hide_form(map { "select$_" } qw(warehouse employee));
  $form->hide_form("old$form->{vc}");

  print qq|

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width="100%">
        <tr valign=top>
	  <td>
	    <table width=100%>
	      <tr>
		<th align=right>$vcname</th>
		<td colspan=3>$form->{$form->{vc}}</td>|
		.$form->hide_form("$form->{vc}", "$form->{vc}_id")
		.qq|
	      </tr>
	      $department
	      <tr>
		<th align=right>|.$locale->text('Shipping Point').qq|</th>
		<td colspan=3>
		<input name=shippingpoint size=35 value="|.$form->quote($form->{shippingpoint}).qq|">
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Ship via').qq|</th>
		<td colspan=3>
		<input name=shipvia size=35 value="|.$form->quote($form->{shipvia}).qq|">
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Waybill').qq|</th>
		<td colspan=3>
		<input name=waybill size=35 value="|.$form->quote($form->{waybill}).qq|">
	      </tr>
	      $warehouse
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $employee
	      <tr>
		<th align=right nowrap>|.$locale->text('Order Number').qq|</th>
		<td>$form->{ordnumber}</td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Order Date').qq|</th>
		<td>$form->{transdate}</td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('PO Number').qq|</th>
		<td>$form->{ponumber}</td>
	      </tr>
	      <tr>
		<th align=right nowrap>$shipped <font color=red>*</font></th>
		<td><input name=shippingdate size=11 class=date value=$form->{shippingdate} title="$myconfig{dateformat}"></td>
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
	$description
      </table>
    </td>
  </tr>
|;

  $form->hide_form(qw(ordnumber transdate ponumber));
  $form->hide_form(map { "shipto$_" } qw(name address1 address2 city state zipcode country contact phone fax email));
  $form->hide_form(qw(message email subject cc bcc));

  @column_index = qw(partnumber);
  
  if ($form->{type} eq "ship_order") {
    $column_data{ship} = qq|<th class=listheading>|.$locale->text('Ship').qq|</th>|;
  }
  if ($form->{type} eq "receive_order") {
      $column_data{ship} = qq|<th class=listheading>|.$locale->text('Recd').qq|</th>|;
      $column_data{sku} = qq|<th class=listheading>|.$locale->text('SKU').qq|</th>|;
      push @column_index, "sku";
  }
  push @column_index, qw(description qty ship unit bin serialnumber);

  my $colspan = $#column_index + 1;
 
  $column_data{partnumber} = qq|<th class=listheading nowrap>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th class=listheading nowrap>|.$locale->text('Description').qq|</th>|;
  $column_data{qty} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading nowrap>|.$locale->text('Unit').qq|</th>|;
  $column_data{bin} = qq|<th class=listheading nowrap>|.$locale->text('Bin').qq|</th>|;
  $column_data{serialnumber} = qq|<th class=listheading nowrap>|.$locale->text('Serial No.').qq|</th>|;
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;
  
  $packagenumber = $locale->text('Packaging');
  $netweight = $locale->text('N.W.');
  $grossweight = $locale->text('G.W.');
  $volume = $locale->text('Volume');
  
  $colspan = $#column_index + 1;

  for $i (1 .. $form->{rowcount} - 1) {
    
    # undo formatting
    $form->{"ship_$i"} = $form->parse_amount(\%myconfig, $form->{"ship_$i"});

    $description = $form->{"description_$i"};
    $description =~ s/\r?\n/<br>/g;
    
    $column_data{partnumber} = qq|<td>|.$form->quote($form->{"partnumber_$i"}).qq|</td>|;
    $column_data{sku} = qq|<td>|.$form->quote($form->{"sku_$i"}).qq|</td>|;
    $column_data{description} = qq|<td>|.$form->quote($description).qq|</td>|;
    $column_data{qty} = qq|<td align=right>|.$form->format_amount(\%myconfig, $form->{"qty_$i"}).qq|</td>|;
    $column_data{ship} = qq|<td><input name="ship_$i" class="inputright" size=8 value=|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|></td>|;
    $column_data{unit} = qq|<td>|.$form->quote($form->{"unit_$i"}).qq|</td>|;
    $column_data{bin} = qq|<td>|.$form->quote($form->{"bin_$i"}).qq|</td>|;
    
    $column_data{serialnumber} = qq|<td><input name="serialnumber_$i" size=15 value="|.$form->quote($form->{"serialnumber_$i"}).qq|"></td>|;
    
    print qq|
        <tr valign=top>|;

    for (@column_index) { print "\n$column_data{$_}" }
  
    print qq|
        </tr>
|;
    $form->hide_form(map { "${_}_$i"} qw(partnumber description itemnotes lineitemdetail sku orderitems_id id partsgroup unit bin qty));

    if ($form->{type} eq 'ship_order') {
      print qq|
		<tr>
		  <td colspan=$colspan>
		  <b>$packagenumber</b>
		  <input name="package_$i" size=20 value="|.$form->quote($form->{"package_$i"}).qq|">
		  <b>$netweight</b>
		  <input name="netweight_$i" class="inputright" size=8 value=|.$form->format_amount(\%myconfig, $form->{"netweight_$i"}).qq|>
		  <b>$grossweight</b>
		  <input name="grossweight_$i" class="inputright" size=8 value=|.$form->format_amount(\%myconfig, $form->{"grossweight_$i"}).qq|> ($form->{weightunit})
		  <b>$volume</b>
		  <input name="volume_$i" class="inputright" size=8 value=|.$form->format_amount(\%myconfig, $form->{"volume_$i"}).qq|>
		  </td>
		</tr>
		<tr>
		  <td colspan=$colspan>
		    <hr noshade>
		  </td>
		</tr>
|;
    }
      

  }
 
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td>
|;

  $form->{copies} = 1;

  if ($form->{type} eq "receive_order") {
    print qq|
  <tr>
    <td>
      <hr noshade>
    </td>
  </tr>
|;

  }
  
  &print_options;
  
  print qq|
    </td>
  </tr>
</table>
<br>
|;

  %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
             'Preview' => { ndx => 2, key => 'V', value => $locale->text('Preview') },
             'Print' => { ndx => 3, key => 'P', value => $locale->text('Print') },
	     'Ship to' => { ndx => 4, key => 'T', value => $locale->text('Ship to') },
	     'E-mail' => { ndx => 5, key => 'E', value => $locale->text('E-mail') },
	     'Done' => { ndx => 11, key => 'D', value => $locale->text('Done') },
	    );
  
  for ("Update", "Print", "Preview") { $form->print_button(\%button, $_) }
  
  if ($form->{type} eq 'ship_order') {
    for ('Ship to', 'E-mail') { $form->print_button(\%button, $_) }
  }
  
  $form->print_button(\%button, 'Done');
  
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


sub done {

  if ($form->{type} eq 'ship_order') {
    $form->isblank("shippingdate", $locale->text('Shipping Date missing!'));
  } else {
    $form->isblank("shippingdate", $locale->text('Date received missing!'));
  }
  
  $total = 0;
  for (1 .. $form->{rowcount} - 1) { $total += $form->{"ship_$_"} = $form->parse_amount(\%myconfig, $form->{"ship_$_"}) }
  
  $form->error($locale->text('Nothing entered!')) unless $total;

  if (OE->save_inventory(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Inventory saved!'));
  } else {
    $form->error($locale->text('Could not save!'));
  }

}


sub search_transfer {
  
  OE->get_warehouses(\%myconfig, \%$form);

  # warehouse
  if (@{ $form->{all_warehouse} }) {
    $form->{selectwarehouse} = "<option>\n";
    $form->{warehouse} = qq|$form->{warehouse}--$form->{warehouse_id}| if $form->{warehouse_id};

    for (@{ $form->{all_warehouse} }) { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| }
  } else {
    $form->error($locale->text('Nothing to transfer!'));
  }
  
  $form->get_partsgroup(\%myconfig, { searchitems => 'part'});
  if (@{ $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = "<option>\n";
    for (@{ $form->{all_partsgroup} }) { $form->{selectpartsgroup} .= qq|<option value="$_->{partsgroup}--$_->{id}">$_->{partsgroup}\n| }
  }
  
  $form->{title} = $locale->text('Transfer Inventory');
  $form->helpref("transfer_inventory", $myconfig{countrycode});
 
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
      <table>
        <tr>
          <th align=right nowrap>|.$locale->text('Transfer from').qq|</th>
          <td><select name=fromwarehouse>$form->{selectwarehouse}</select></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Transfer to').qq|</th>
          <td><select name=towarehouse>$form->{selectwarehouse}</select></td>
        </tr>
	<tr>
	  <th align="right" nowrap="true">|.$locale->text('Part Number').qq|</th>
	  <td><input name=partnumber size=20></td>
	</tr>
	<tr>
	  <th align="right" nowrap="true">|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Group').qq|</th>
	  <td><select name=partsgroup>$form->{selectpartsgroup}</select></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=hidden name=nextsub value=list_transfer>

<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->hide_form(qw(path login sessionid));

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


sub list_transfer {

  $form->{sort} = "partnumber" unless $form->{sort};

  OE->get_inventory(\%myconfig, \%$form);
  
  # construct href
  $href = "$form->{script}?action=list_transfer";
  for (qw(direction oldsort path login sessionid)) { $href .= "&$_=$form->{$_}" }
  for (qw(partnumber fromwarehouse towarehouse description partsgroup)) { $href .= "&$_=".$form->escape($form->{$_}) }

  $form->sort_order();
  
  # construct callback
  $callback = "$form->{script}?action=list_transfer";
  for (qw(direction oldsort path login sessionid)) { $callback .= "&$_=$form->{$_}" }
  for (qw(partnumber fromwarehouse towarehouse description partsgroup)) { $callback .= "&$_=".$form->escape($form->{$_},1) }

  @column_index = $form->sort_columns(qw(partnumber description partsgroup make model fromwarehouse qty towarehouse transfer));

  $column_header{partnumber} = qq|<th><a class=listheading href=$href&sort=partnumber>|.$locale->text('Part Number').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_header{partsgroup} = qq|<th><a class=listheading href=$href&sort=partsgroup>|.$locale->text('Group').qq|</a></th>|;
  $column_header{fromwarehouse} = qq|<th><a class=listheading href=$href&sort=warehouse>|.$locale->text('From').qq|</a></th>|;
  $column_header{towarehouse} = qq|<th class=listheading>|.$locale->text('To').qq|</th>|;
  $column_header{qty} = qq|<th class=listheading>|.$locale->text('Qty').qq|</a></th>|;
  $column_header{transfer} = qq|<th class=listheading>|.$locale->text('Transfer').qq|</a></th>|;

  
  ($warehouse, $warehouse_id) = split /--/, $form->{fromwarehouse};
  
  if ($form->{fromwarehouse}) {
    $option .= "\n<br>";
    $option .= $locale->text('From Warehouse')." : $warehouse";
  }
  ($warehouse, $warehouse_id) = split /--/, $form->{towarehouse};
  if ($form->{towarehouse}) {
    $option .= "\n<br>";
    $option .= $locale->text('To Warehouse')." : $warehouse";
  }
  if ($form->{partnumber}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Part Number')." : $form->{partnumber}";
  }
  if ($form->{description}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Description')." : $form->{description}";
  }
  if ($form->{partsgroup}) {
    ($partsgroup) = split /--/, $form->{partsgroup};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Group')." : $partsgroup";
  }

  $form->{title} = $locale->text('Transfer Inventory');

  $callback .= "&sort=$form->{sort}";
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=warehouse_id value=$warehouse_id>

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
	<tr class=listheading>|;

for (@column_index) { print "\n$column_header{$_}" }

print qq|
	</tr>
|;

  if (@{ $form->{all_inventory} }) {
    $sameitem = $form->{all_inventory}->[0]->{$form->{sort}};
  }

  $i = 0;
  foreach $ref (@{ $form->{all_inventory} }) {

    $i++;

    $column_data{partnumber} = qq|<td><input type=hidden name="id_$i" value=$ref->{id}>$ref->{partnumber}</td>|;
    $column_data{description} = "<td>$ref->{description}&nbsp;</td>";
    $column_data{partsgroup} = "<td>$ref->{partsgroup}&nbsp;</td>";
    $column_data{fromwarehouse} = qq|<td><input type=hidden name="warehouse_id_$i" value=$ref->{warehouse_id}>$ref->{warehouse}&nbsp;</td>|;
    $column_data{towarehouse} = qq|<td>$warehouse&nbsp;</td>|;
    $column_data{qty} = qq|<td><input type=hidden name="qty_$i" value=$ref->{qty}>|.$form->format_amount(\%myconfig, $ref->{qty}).qq|</td>|;
    $column_data{transfer} = qq|<td><input name="transfer_$i" size=4></td>|;

    $j++; $j %= 2;
    print "
        <tr class=listrow$j>";
    
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

<br>

<input name=callback type=hidden value="$callback">

<input type=hidden name=rowcount value=$i>
|;

  $form->{action} = "transfer";
  $form->hide_form(qw(path login sessionid action));

  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Transfer').qq|">|;

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


sub transfer {

  if (OE->transfer(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Inventory transferred!'));
  } else {
    $form->error($locale->text('Could not transfer Inventory!'));
  }

}


sub rfq_ { &add };
sub quotation_ { &add };


sub generate_purchase_orders {

  for (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$_"}) {
      $ok = 1;
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $ok;
  
  ($null, $argv) = split /\?/, $form->{callback};
  
  for (split /\&/, $argv) {
    ($key, $value) = split /=/, $_;
    $form->{$key} = $value;
  }

  $form->{vc} = "vendor";

  OE->get_soparts(\%myconfig, \%$form);

  # flatten array
  $i = 0;
  foreach $parts_id (sort { $form->{orderitems}{$a}{ndx} <=> $form->{orderitems}{$b}{ndx} } keys %{ $form->{orderitems} }) {

    $required = $form->{orderitems}{$parts_id}{required};
    next if $required <= 0;

    $i++;

    ($ph, $id, $orderitemsid) = split /--/, $parts_id;
    
    $form->{"id_$i"} = $parts_id;
    
    $form->{"required_$i"} = $form->format_amount(\%myconfig, $required);
    $form->{"sku_$i"} = $form->{orderitems}{$parts_id}{partnumber};

    $form->{"curr_$i"} = $form->{defaultcurrency};
    $form->{"description_$i"} = $form->{orderitems}{$parts_id}{description};

    $form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{orderitems}{$parts_id}{lastcost}, $form->{precision});

    $form->{"qty_$i"} = $form->format_amount(\%myconfig, $required);
    
    if (exists $form->{orderitems}{$parts_id}{"parts$form->{vc}"}) {
      $form->{"qty_$i"} = "";

      foreach $id (sort { $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$a}{lastcost} * $form->{$form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$a}{curr}} <=> $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$b}{lastcost} * $form->{$form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$b}{curr}} } keys %{ $form->{orderitems}{$parts_id}{"parts$form->{vc}"} }) {
	$i++;

	$form->{"qty_$i"} = $form->format_amount(\%myconfig, $required);
    
 	$form->{"description_$i"} = "";
	for (qw(partnumber curr)) { $form->{"${_}_$i"} = $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{$_} }

        $form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{lastcost}, $form->{precision});
        $form->{"leadtime_$i"} = $form->format_amount(\%myconfig, $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{leadtime});
	$form->{"fx_$i"} = $form->format_amount(\%myconfig, $form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{lastcost} * $form->{$form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{curr}}, $form->{precision});

	$form->{"id_$i"} = $parts_id;
	
	$form->{"$form->{vc}_$i"} = qq|$form->{orderitems}{$parts_id}{"parts$form->{vc}"}{$id}{name}--$id|;
	$form->{"$form->{vc}_id_$i"} = $id;

        $required = "";
      }
    }
    $form->{"blankrow_$i"} = 1;
  }

  $form->{rowcount} = $i;

  &po_orderitems;

}


sub po_orderitems {

  @column_index = qw(sku description partnumber leadtime fx lastcost curr required qty name);
  
  $column_header{sku} = qq|<th class=listheading>|.$locale->text('SKU').qq|</th>|;
  $column_header{partnumber} = qq|<th class=listheading>|.$locale->text('Part Number').qq|</th>|;
  $column_header{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_header{name} = qq|<th class=listheading>|.$locale->text('Vendor').qq|</th>|;
  $column_header{qty} = qq|<th class=listheading>|.$locale->text('Order').qq|</th>|;
  $column_header{required} = qq|<th class=listheading>|.$locale->text('Req').qq|</th>|;
  $column_header{lastcost} = qq|<th class=listheading>|.$locale->text('Cost').qq|</th>|;
  $column_header{fx} = qq|<th class=listheading>&nbsp;</th>|;
  $column_header{leadtime} = qq|<th class=listheading>|.$locale->text('Lead').qq|</th>|;
  $column_header{curr} = qq|<th class=listheading>|.$locale->text('Curr').qq|</th>|;


  $form->{title} = $locale->text('Generate Purchase Orders');
  
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
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
	</tr>
|;

  for $i (1 .. $form->{rowcount}) {

    for (qw(sku partnumber description curr)) { $column_data{$_} = qq|<td>$form->{"${_}_$i"}&nbsp;</td>| }

    for (qw(required leadtime lastcost fx)) { $column_data{$_} = qq|<td align=right>$form->{"${_}_$i"}</td>| }
    
    $column_data{qty} = qq|<td><input name="qty_$i" class="inputright" size=6 value=$form->{"qty_$i"}></td>|;
   
    if ($form->{"$form->{vc}_id_$i"}) {
      $name = $form->{"$form->{vc}_$i"};
      $name =~ s/--.*//;
      $column_data{name} = qq|<td>$name</td>|;
      $form->hide_form("$form->{vc}_id_$i", "$form->{vc}_$i");
    } else {
      $column_data{name} = qq|<td><input name="ndx_$i" class=checkbox type=checkbox value="1"></td>|;
    }

    $form->hide_form(map { "${_}_$i" } qw(id sku partnumber description curr required leadtime lastcost fx name blankrow));
    
    $blankrow = $form->{"blankrow_$i"};

BLANKROW:
    $j++; $j %= 2;
    print "
        <tr class=listrow$j>";
    
    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>
|;

    if ($blankrow) {
      for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
      $blankrow = 0;

      goto BLANKROW;
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

<br>
|;

  $form->hide_form(qw(callback department ponumber path login employee_id vc nextsub rowcount type detail));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Generate Orders').qq|">|;

  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Select Vendor').qq|">|;
 
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


sub generate_orders {

  if (OE->generate_orders(\%myconfig, \%$form)) {
    $form->redirect;
  } else {
    $form->error($locale->text('Order generation failed!'));
  }
  
}



sub consolidate_orders {

  $form->{orddescription} = $locale->text('Sales Orders') ." / ";
  for (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$_"}) {
      $ok = 1;
      $form->{orddescription} .= $form->{"transdate_$_"};
      last;
    }
  }
  for (reverse 1 .. $form->{rowcount}) {
    if ($form->{"ndx_$_"}) {
      $form->{orddescription} .= qq| - $form->{"transdate_$_"}|;
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $ok;
  
  ($null, $argv) = split /\?/, $form->{callback};
  
  for (split /\&/, $argv) {
    ($key, $value) = split /=/, $_;
    $form->{$key} = $value;
  }

  if (OE->consolidate_orders(\%myconfig, \%$form)) {
    $form->redirect;
  } else {
    $form->error($locale->text('Order generation failed!'));
  }

}


sub select_vendor {

  for (1 .. $form->{rowcount}) {
    last if ($ok = $form->{"ndx_$_"});
  }

  $form->error($locale->text('Nothing selected!')) unless $ok;
  
  $form->header;
  
  print qq|
<body onload="document.forms[0].vendor.focus()" />

<form method=post action=$form->{script}>

<b>|.$locale->text('Vendor').qq|</b> <input name=vendor size=40>

|;

  $form->{nextsub} = "vendor_selected";
  $form->{action} = "vendor_selected";
  
  $form->hide_form;
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">

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


sub vendor_selected {

  if (($rv = $form->get_name(\%myconfig, $form->{vc}, $form->{transdate})) > 1) {
    &select_name($form->{vc});
    exit;
  }

  if ($rv == 1) {
    for (1 .. $form->{rowcount}) {
      if ($form->{"ndx_$_"}) {
	$form->{"$form->{vc}_id_$_"} = $form->{name_list}[0]->{id};
	$form->{"$form->{vc}_$_"} = "$form->{name_list}[0]->{name}--$form->{name_list}[0]->{id}";
      }
    }
  } else {
    $msg = ucfirst $form->{vc} . " not on file!" unless $msg;
    $form->error($locale->text($msg));
  }

  &po_orderitems;
  
}


