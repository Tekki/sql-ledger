#=====================================================================
# SQL-Ledger ERP
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Inventory Control module
#
#======================================================================


use SL::IC;

require "$form->{path}/io.pl";
require "$form->{path}/rd.pl";

1;
# end of main



sub add {

  %label = ( part	=> 'Part',
             service	=> 'Service',
	     assembly	=> 'Assembly',
	     labor	=> 'Labor/Overhead', );

# $locale->text('Add Part')
# $locale->text('Add Service')
# $locale->text('Add Assembly')
# $locale->text('Add Labor/Overhead')

  $label = "Add $label{$form->{item}}";
  $form->{title} = $locale->text($label);

  $form->{callback} = "$form->{script}?action=add&item=$form->{item}&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  $form->{orphaned} = 1;

  if ($form->{previousform}) {
    $form->{callback} = "";
  }

  &link_part;
  
  &display_form;

}


sub edit {
  
 %label = ( part	=> 'Part',
            service	=> 'Service',
            assembly	=> 'Assembly',
	    labor	=> 'Labor/Overhead', );

# $locale->text('Edit Part')
# $locale->text('Edit Service')
# $locale->text('Edit Assembly')
# $locale->text('Edit Labor/Overhead')
# $locale->text('Part Changeup')
# $locale->text('Service Changeup')
# $locale->text('Assembly Changeup')
# $locale->text('Labor/Overhead Changeup')

  IC->get_part(\%myconfig, \%$form);

  $label = "Edit $label{$form->{item}}";
  $label = "$label{$form->{item}} Changeup" if $form->{changeup};

  $form->{title} = $locale->text($label);

  $form->{previousform} = $form->escape($form->{previousform}, 1) if $form->{previousform};

  &link_part;

  &display_form;

}



sub link_part {

  $partsgroupcode = $form->{partsgroupcode};
  
  IC->create_links("IC", \%myconfig, \%$form);

  $form->{partsgroupcode} = $partsgroupcode;
  $form->{oldpartsgroupcode} = $partsgroupcode;

  # currencies
  $form->{selectcurrency} = "";
  for (split /:/, $form->{currencies}) { $form->{selectcurrency} .= "$_\n" }
  

  # readonly
  if ($form->{changeup}) {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Goods \& Services--Changeup/;
    $form->helpref("changeup_$form->{item}", $myconfig{countrycode});
  } else {
    $form->helpref($form->{item}, $myconfig{countrycode});
  }

  if ($form->{item} eq 'part') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Goods \& Services--Add Part/;
    $form->error($locale->text('Cannot create Part').";".$locale->text('Inventory account does not exist!')) if ! @{ $form->{IC_links}{IC} };
    $form->error($locale->text('Cannot create Part').";".$locale->text('Income account does not exist!')) if ! @{ $form->{IC_links}{IC_sale} };
    $form->error($locale->text('Cannot create Part').";".$locale->text('COGS account does not exist!')) if ! @{ $form->{IC_links}{IC_cogs} };
  }
  
  if ($form->{item} eq 'service') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Goods \& Services--Add Service/;
    $form->error($locale->text('Cannot create Service').";".$locale->text('Income account does not exist!')) if ! @{ $form->{IC_links}{IC_income} };
    $form->error($locale->text('Cannot create Service').";".$locale->text('Expense account does not exist!')) if ! @{ $form->{IC_links}{IC_expense} };
  }
  
  if ($form->{item} eq 'assembly') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Goods \& Services--Add Assembly/;
    $form->error($locale->text('Cannot create Assembly').";".$locale->text('Income account does not exist!')) if ! @{ $form->{IC_links}{IC_income} };
  }
  if ($form->{item} eq 'labor') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Goods \& Services--Add Labor\/Overhead/;
    $form->error($locale->text('Cannot create Labor').";".$locale->text('Inventory account does not exist!')) if ! @{ $form->{IC_links}{IC} };
    $form->error($locale->text('Cannot create Labor').";".$locale->text('COGS account does not exist!')) if ! @{ $form->{IC_links}{IC_cogs} };
  }

  
  # parts, assemblies , labor and overhead have the same links
  $taxpart = ($form->{item} eq 'service') ? "service" : "part";
 
  # build the popup menus
  $form->{taxaccounts} = "";
  foreach $key (keys %{ $form->{IC_links} }) {
    
    $form->{"select$key"} = "";
    foreach $ref (@{ $form->{IC_links}{$key} }) {
      # if this is a tax field
      if ($key =~ /IC_tax/) {
	if ($key =~ /$taxpart/) {
	  
	  $form->{taxaccounts} .= "$ref->{accno} ";
	  $form->{"IC_tax_$ref->{accno}_description"} = "$ref->{accno}--$ref->{description}";

	  if ($form->{id}) {
	    if ($form->{amount}{$ref->{accno}}) {
	      $form->{"IC_tax_$ref->{accno}"} = "checked";
	    }
	  } else {
	    $form->{"IC_tax_$ref->{accno}"} = "checked";
	  }
	  
	}
      } else {

	$form->{"select$key"} .= "$ref->{accno}--$ref->{description}\n";
	
      }
    }
  }
  chop $form->{taxaccounts};

  $form->{selectIC_inventory} = $form->{selectIC};
  if ($form->{item} !~ /service/) {
    $form->{selectIC_income} = $form->{selectIC_sale};
    $form->{selectIC_expense} = $form->{selectIC_cogs};
    $form->{IC_income} = $form->{IC_sale};
    $form->{IC_expense} = $form->{IC_cogs};
  }

  # set option
  for (qw(IC_inventory IC_income IC_expense)) { $form->{$_} = "$form->{amount}{$_}{accno}--$form->{amount}{$_}{description}" if $form->{amount}{$_}{accno} }

  delete $form->{IC_links};
  delete $form->{amount};

  if ($form->{partsgroup}) {
    $form->{partsgroup} = "$form->{partsgroup}--$form->{partsgroup_id}";
  }
  $form->{oldpartsgroup} = $form->{partsgroup};

  if (@{ $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = qq|\n|;

    for (@{ $form->{all_partsgroup} }) { $form->{selectpartsgroup} .= qq|$_->{partsgroup}--$_->{id}\n| }
    delete $form->{all_partsgroup};
  }


  if ($form->{item} eq 'assembly') {

    for (1 .. $form->{assembly_rows}) {
      if ($form->{"partsgroup_id_$_"}) {
	$form->{"partsgroup_$_"} = qq|$form->{"partsgroup_$_"}--$form->{"partsgroup_id_$_"}|;
      }
    }
    
  }
  
  # setup make and models
  $i = 1;
  foreach $ref (@{ $form->{makemodels} }) {
    for (qw(make model)) { $form->{"${_}_$i"} = $ref->{$_} }
    $i++;
  }
  $form->{makemodel_rows} = $i - 1;
  delete $form->{makemodels};

  
  # setup vendors
  if (@{ $form->{all_vendor} }) {
    $form->{selectvendor} = "\n";
    for (@{ $form->{all_vendor} }) { $form->{selectvendor} .= qq|$_->{name}--$_->{id}\n| }
    delete $form->{all_vendor};
  }

  # vendor matrix
  $i = 1;
  foreach $ref (@{ $form->{vendormatrix} }) {
    $form->{"vendor_$i"} = qq|$ref->{name}--$ref->{id}|;

    for (qw(partnumber lastcost leadtime vendorcurr)) { $form->{"${_}_$i"} = $ref->{$_} }
    $i++;
  }
  $form->{vendor_rows} = $i - 1;
  delete $form->{vendormatrix};
  
  # setup customers and groups
  if (@{ $form->{all_customer} }) {
    $form->{selectcustomer} = "\n";
    for (@{ $form->{all_customer} }) { $form->{selectcustomer} .= qq|$_->{name}--$_->{id}\n| }
    delete $form->{all_customer};
  }

  if (@{ $form->{all_pricegroup} }) {
    $form->{selectpricegroup} = "\n";
    for (@{ $form->{all_pricegroup} }) { $form->{selectpricegroup} .= qq|$_->{pricegroup}--$_->{id}\n| }
    delete $form->{all_pricegroup};
  }

  $i = 1;
  # customer matrix
  foreach $ref (@{ $form->{customermatrix} }) {

    $form->{"customer_$i"} = "$ref->{name}--$ref->{cid}" if $ref->{cid};
    $form->{"pricegroup_$i"} = "$ref->{pricegroup}--$ref->{gid}" if $ref->{gid};

    for (qw(validfrom validto pricebreak customerprice customercurr)) { $form->{"${_}_$i"} = $ref->{$_} }

    $i++;
    
  }
  $form->{customer_rows} = $i - 1;
  delete $form->{customermatrix};

  for (qw(currency partsgroup assemblypartsgroup vendor customer pricegroup IC_inventory IC_income IC_expense)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }

}



sub form_header {

  if ($form->{lastcost} > 0) {
    $markup = $form->round_amount((($form->{sellprice}/$form->{lastcost} - 1) * 100), 1);
    $form->{markup} = $form->format_amount(\%myconfig, $markup, 1);
  }
  
  ($dec) = ($form->{sellprice} =~ /\.(\d+)/);
  $dec = length $dec;
  $form->{decimalplacessell} = ($dec > $form->{precision}) ? $dec : $form->{precision};
  
  for (qw(listprice sellprice)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $form->{decimalplacessell}) }
  
  ($dec) = ($form->{lastcost} =~ /\.(\d+)/);
  $dec = length $dec;
  $form->{decimalplacescost} = ($dec > $form->{precision}) ? $dec : $form->{precision};
 
  for (qw(lastcost avgcost)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $form->{decimalplacescost}) }

  for (qw(weight rop stock)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}) }
  
  for (qw(partnumber description unit notes)) { $form->{$_} = $form->quote($form->{$_}) }

  for (qw(description notes)) {
    if (($rows = $form->numtextrows($form->{$_}, 40)) < 2) {
      $rows = 1;
    }
    
    $fld{$_} = qq|<textarea name=$_ rows=$rows cols=40 wrap=soft>$form->{$_}</textarea>|;
  }

  for (split / /, $form->{taxaccounts}) { $form->{"IC_tax_$_"} = ($form->{"IC_tax_$_"}) ? "checked" : "" }

  # set option
  for (qw(IC_inventory IC_income IC_expense)) {
    if ($form->{$_}) {
      if ($form->{changeup}) {
	$select{$_} = $form->select_option($form->{"select$_"}, $form->{$_});
      } else {
	if ($form->{orphaned}) {
	  $select{$_} = $form->select_option($form->{"select$_"}, $form->{$_});
	} else {
	  $select{$_} = qq|<option selected>$form->{$_}|;
	}
      }
    }
  }

  if ($form->{selectpartsgroup}) {
    $selectpartsgroup = qq|<select name=partsgroup onChange="javascript:document.forms[0].submit()">|.$form->select_option($form->{selectpartsgroup}, $form->{partsgroup}, 1).qq|</select>
    <br><input name=partsgroupcode size=10 value="$form->{partsgroupcode}">|;
    $group = $locale->text('Group');
  }

  # tax fields
  foreach $item (split / /, $form->{taxaccounts}) {
    $tax .= qq|
      <input class=checkbox type=checkbox name="IC_tax_$item" value=1 $form->{"IC_tax_$item"}>&nbsp;<b>$form->{"IC_tax_${item}_description"}</b>
      <br>|.$form->hide_form("IC_tax_${item}_description");
  }

  $reference_documents = &reference_documents;

  $sellprice = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Sell Price').qq|</th>
		<td><input name=sellprice class="inputright" size=11 value=$form->{sellprice}></td>
	      </tr>
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('List Price').qq|</th>
		<td><input name=listprice class="inputright" size=11 value=$form->{listprice}></td>
	      </tr>
|;

  $avgcost = qq|
 	      <tr>
                <th align="right" nowrap="true">|.$locale->text('Average Cost').qq|</th>
                <td><input type=hidden name=avgcost value=$form->{avgcost}>$form->{avgcost}</td>
              </tr>
|;

  $lastcost = qq|
 	      <tr>
                <th align="right" nowrap="true">|.$locale->text('Last Cost').qq|</th>
                <td><input name=lastcost class="inputright" size=11 value=$form->{lastcost}></td>
              </tr>
	      <tr>
	        <th align="right" nowrap="true">|.$locale->text('Markup').qq| %</th>
		<td><input name=markup class="inputright" size=5 value=$form->{markup}></td>
		<input type=hidden name=oldmarkup value=$markup>
	      </tr>
|;


  if ($form->{item} =~ /(part|assembly)/) {
    $n = ($form->{onhand} > 0) ? "1" : "0";
    $onhand = qq|
	      <tr>
		<th align="right" nowrap>|.$locale->text('On Hand').qq|</th>
		<th align=left nowrap class="plus$n">&nbsp;|.$form->format_amount(\%myconfig, $form->{onhand}).qq|</th>
	      </tr>
|;

    $rop = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('ROP').qq|</th>
		<td><input name=rop class="inputright" size=8 value=$form->{rop}></td>
	      </tr>
|;
    
    $bin = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Bin').qq|</th>
		<td><input name=bin size=10 value="|.$form->quote($form->{bin}).qq|"></td>
	      </tr>
|;
    
    $imagelinks = qq|
  <tr>
    <td>
      <table width=100%>
        <tr>
	  <th align=right nowrap>|.$locale->text('Image').qq|</th>
	  <td><input name=image size=40 value="$form->{image}"></td>
	  
	  <th align=right nowrap>|.$locale->text('Country of Origin').qq|</th>
	  <td><input name=countryorigin size=20 value="$form->{countryorigin}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Drawing').qq|</th>
	  <td><input name=drawing size=40 value="$form->{drawing}"></td>

	  <th align=right nowrap>|.$locale->text('HS Code').qq|</th>
	  <td><input name=tariff_hscode size=20 value="$form->{tariff_hscode}"></td>
        </tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Microfiche').qq|</th>
	  <td><input name=microfiche size=20 value="$form->{microfiche}"></td>
	  <th align=right nowrap>|.$locale->text('Barcode').qq|</th>
	  <td><input name=barcode size=30 value="$form->{barcode}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Tool Number').qq|</th>
	  <td><input name=toolnumber size=20 value="$form->{toolnumber}"></td>
	</tr>
      </table>
    </td>
  </tr>
|;
  }


  if ($form->{item} eq "part") {

    $linkaccounts = qq|
	      <tr>
		<th align=right>|.$locale->text('Inventory').qq|</th>
		<td><select name=IC_inventory>$select{IC_inventory}</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Income').qq|</th>
		<td><select name=IC_income>$select{IC_income}</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('COGS').qq|</th>
		<td><select name=IC_expense>$select{IC_expense}</select></td>
	      </tr>
|;
  
    if ($tax) {
      $linkaccounts .= qq|
	      <tr>
		<th align=right>|.$locale->text('Tax').qq|</th>
		<td>$tax</td>
	      </tr>
|;
    }
  
    $weight = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Weight').qq|</th>
		<td>
		  <table>
		    <tr>
		      <td>
			<input name=weight class="inputright" size=11 value=$form->{weight}>
		      </td>
		      <th>
			&nbsp;
			$form->{weightunit}|
			.$form->hide_form(qw(weightunit))
			.qq|
		      </th>
		    </tr>
		  </table>
		</td>
	      </tr>
|;
    
  }


  if ($form->{item} eq "assembly") {

    $avgcost = "";
    
    if ($form->{project_id}) {
      $weight = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Weight').qq|</th>
		<td>
		  <table>
		    <tr>
		      <td>
			<input name=weight class="inputright" size=11 value=$form->{weight}>
		      </td>
		      <th>
			&nbsp;
			$form->{weightunit}|
			.$form->hide_form(qw(weightunit))
			.qq|
		      </th>
		    </tr>
		  </table>
		</td>
	      </tr>
|;
    } else {
   
      $weight = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Weight').qq|</th>
		<td>
		  <table>
		    <tr>
		      <td>
			&nbsp;$form->{weight}
			<input type=hidden name=weight value=$form->{weight}>
		      </td>
		      <th>
			&nbsp;
			$form->{weightunit}|
			.$form->hide_form(qw(weightunit))
			.qq|
		      </th>
		    </tr>
		  </table>
		</td>
	      </tr>
|;
    }
    

    if ($form->{project_id}) {
      $lastcost = "";
      $avgcost = "";
      $onhand = "";
      $rop = "";

    } else {
      $stock = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Stock').qq|</th>
		<td><input name=stock class="inputright" size=8 value=$form->{stock}></td>
	      </tr>
|;

      $lastcost = qq|
              <tr>
	        <th align="right" nowrap="true">|.$locale->text('Last Cost').qq|</th> 
		<td><input type=hidden name=lastcost value=$form->{lastcost}>$form->{lastcost}</td>
	      </tr>
	      <tr>
	        <th align="right" nowrap="true">|.$locale->text('Markup').qq| %</th>
		<td><input name=markup class="inputright" size=5 value=$form->{markup}></td>
		<input type=hidden name=oldmarkup value=$markup>
	      </tr>
|;

    }

    $linkaccounts = qq|
	      <tr>
		<th align=right>|.$locale->text('Income').qq|</th>
		<td><select name=IC_income>$select{IC_income}</select></td>
	      </tr>
|;
  
    if ($tax) {
      $linkaccounts .= qq|
	      <tr>
		<th align=right>|.$locale->text('Tax').qq|</th>
		<td>$tax</td>
	      </tr>
|;
    }
  
  }

 
  if ($form->{item} eq "service") {
    $avgcost = "";
    $linkaccounts = qq|
	      <tr>
		<th align=right>|.$locale->text('Income').qq|</th>
		<td><select name=IC_income>$select{IC_income}</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Expense').qq|</th>
		<td><select name=IC_expense>$select{IC_expense}</select></td>
	      </tr>
|;
  
    if ($tax) {
      $linkaccounts .= qq|
	      <tr>
		<th align=right>|.$locale->text('Tax').qq|</th>
		<td>$tax</td>
	      </tr>
|;
    }

  }

  if ($form->{item} eq 'labor') {
    $avgcost = "";
    
    $n = ($form->{onhand} > 0) ? "1" : "0";
    $onhand = qq|
	      <tr>
		<th align="right" nowrap>|.$locale->text('On Hand').qq|</th>
		<th align=left nowrap class="plus$n">&nbsp;|.$form->format_amount(\%myconfig, $form->{onhand}).qq|</th>
	      </tr>
|;
   
    $linkaccounts = qq|
	      <tr>
		<th align=right>|.$locale->text('Labor/Overhead').qq|</th>
		<td><select name=IC_inventory>$select{IC_inventory}</select></td>
	      </tr>

	      <tr>
		<th align=right>|.$locale->text('COGS').qq|</th>
		<td><select name=IC_expense>$select{IC_expense}</select></td>
	      </tr>
|;
  
  }

  if ($form->{id}) {
    $checked = ($form->{obsolete}) ? "checked" : "";
    $obsolete = qq|
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Obsolete').qq|</th>
		<td><input name=obsolete type=checkbox class=checkbox value=1 $checked></td>
	      </tr>
|;
    $obsolete = "<input type=hidden name=obsolete value=$form->{obsolete}>" if $form->{project_id};
  }

  $s = length $form->{partnumber};
  $s = ($s > 20) ? $s : 20;
  $fld{partnumber} = qq|<input name=partnumber value="|.$form->quote($form->{partnumber}).qq|" size=$s>|;


  $form->header;

  print qq|
<body>

<form method=post action="$form->{script}">
|;

  $form->hide_form(qw(id item title makemodel alternate onhand orphaned taxaccounts rowcount project_id precision changeup oldpartsgroup oldpartsgroupcode helpref));
  
  print qq|
<input type=hidden name=action value="update">

<table width="100%">
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width="100%">
        <tr valign=top>
          <th align=left>|.$locale->text('Number').qq|</th>
          <th align=left>|.$locale->text('Description').qq|</th>
	  <th align=left>$group</th>
	</tr>
	<tr valign=top>
	  <td>$fld{partnumber}</td>
          <td>$fld{description}</td>
	  <td>$selectpartsgroup</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width="100%" height="100%">
        <tr valign=top>
          <td width=70%>
            <table width="100%" height="100%">
              <tr class="listheading">
                <th class="listheading" align="center" colspan=2>|.$locale->text('Link Accounts').qq|</th>
              </tr>
              $linkaccounts
	      <tr>
	        <td colspan=2>
		  $reference_documents
		</td>
	      </tr>
              <tr>
                <th align="left">|.$locale->text('Notes').qq|</th>
              </tr>
              <tr>
                <td colspan=2>
                  $fld{notes}
                </td>
              </tr>
            </table>
          </td>
	  <td width="30%">
	    <table width="100%">
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Updated').qq|</th>
		<td><input name=priceupdate size=11 class=date title="$myconfig{dateformat}" value=$form->{priceupdate}></td>    
	      </tr>
	      $sellprice
	      $lastcost
	      $avgcost
	      <tr>
		<th align="right" nowrap="true">|.$locale->text('Unit').qq|</th>
		<td><input name=unit size=5 value="|.$form->quote($form->{unit}).qq|"></td>
	      </tr>
	      $weight
	      $onhand
	      $stock
	      $rop
	      $bin
	      $obsolete
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  $imagelinks
|;

  $form->hide_form(map { "select$_" } qw(currency partsgroup assemblypartsgroup vendor customer pricegroup IC_inventory IC_income IC_expense));
  
}


sub form_footer {
  
  if (! $form->{project_id}) {
    if ($form->{item} eq 'assembly') {
      &assembly_row(++$form->{assembly_rows});
    }
  }

  print qq|
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->hide_form(qw(customer_rows));

  if ($form->{item} =~ /(part|assembly)/) {
    $form->hide_form(qw(makemodel_rows));
  }
  
  if ($form->{item} =~ /(part|service)/) {
    $form->hide_form(qw(vendor_rows));
  }

  if (! $form->{readonly}) {
    
    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
               'Save' => { ndx => 3, key => 'S', value => $locale->text('Save') },
	       'New Number' => { ndx => 15, key => 'M', value => $locale->text('New Number') },
	      );
    
    if ($form->{id}) {

      if (! $form->{changeup}) {
	$button{'Save as new'} = { ndx => 7, key => 'N', value => $locale->text('Save as new') };
      }

      if ($form->{orphaned}) {
	$button{'Delete'} = { ndx => 16, key => 'D', value => $locale->text('Delete') };
      }
    }
    
    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
    
  }

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  $form->hide_form(qw(login path callback previousform));
  
  print qq|
</form>

</body>
</html>
|;

}


sub search {

  IC->get_warehouses(\%myconfig, \%$form);

  if (@{ $form->{all_partsgroup} }) {
    $partsgroup = qq|<option>\n|;

    for (@{ $form->{all_partsgroup} }) { $partsgroup .= qq|<option value="|.$form->quote($_->{partsgroup}).qq|--$_->{id}">$_->{partsgroup}\n| }

    $partsgroup = qq| 
        <th align=right nowrap>|.$locale->text('Group').qq|</th>
	<td><select name=partsgroup>$partsgroup</select></td>
|;

    $l{partsgroup} = qq|<input name=l_partsgroup class=checkbox type=checkbox value=Y> |.$locale->text('Group');
    $l{partsgroupcode} = qq|<input name=l_partsgroupcode class=checkbox type=checkbox value=Y> |.$locale->text('Group Code');
  }

  $method{accrual} = "checked" if $form->{method} eq 'accrual';
  $method{cash} = "checked" if $form->{method} eq 'cash';

  $l{listprice} = qq|<input name=l_listprice class=checkbox type=checkbox value=Y> |.$locale->text('List Price');
  $l{sellprice} = qq|<input name=l_sellprice class=checkbox type=checkbox value=Y checked> |.$locale->text('Sell Price');
  $l{linetotal} = qq|<input name=l_linetotal class=checkbox type=checkbox value=Y> |.$locale->text('Extended');
  $l{lastcost} = qq|<input name=l_lastcost class=checkbox type=checkbox value=Y checked> |.$locale->text('Last Cost');
  $l{avgcost} = qq|<input name=l_avgcost class=checkbox type=checkbox value=Y checked> |.$locale->text('Average Cost');
  $l{markup} = qq|<input name=l_markup class=checkbox type=checkbox value=Y> |.$locale->text('Markup');
  $l{account} = qq|<input name=l_account class=checkbox type=checkbox value=Y> |.$locale->text('Accounts');

 
  $bought = qq|
          <td>
	    <table>
	      <tr>
		<td><input name=bought class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('Vendor Invoices').qq|</td>
	      </tr>
	      <tr>
		<td><input name=onorder class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('Purchase Orders').qq|</td>
	      </tr>
	      <tr>
		<td><input name=rfq class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('RFQ').qq|</td>
	      </tr>
	    </table>
	  </td>
|;

  $sold = qq|
	  <td>
	    <table>
	      <tr>
		<td><input name=sold class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('Sales Invoices').qq|</td>
	      </tr>
	      <tr>
		<td><input name=ordered class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('Sales Orders').qq|</td>
	      </tr>
	      <tr>
		<td><input name=quoted class=checkbox type=checkbox value=1></td>
		<td nowrap>|.$locale->text('Quotations').qq|</td>
	      </tr>
	    </table>
	  </td>
|;

  $fromto = qq|
	  <td>
	    <table>
	      <tr>
		<td nowrap><b>|.$locale->text('From').qq|</b>
		<input name=transdatefrom size=11 class=date title="$myconfig{dateformat}">
		<b>|.$locale->text('To').qq|</b>
		<input name=transdateto size=11 class=date title="$myconfig{dateformat}"></td>
	      </tr>
	      <tr>
		<td nowrap><input name=method class=radio type=radio value=accrual $method{accrual}>|.$locale->text('Accrual').qq|
		<input name=method class=radio type=radio value=cash $method{cash}>|.$locale->text('Cash').qq|</td>
	      </tr>
	      <tr>
		<td nowrap>
		<input name=open class=checkbox type=checkbox value=1 checked> |.$locale->text('Open').qq|
		<input name=closed class=checkbox type=checkbox> |.$locale->text('Closed').qq|
		<input name=summary type=radio class=radio value=1> |.$locale->text('Summary').qq|
		<input name=summary type=radio class=radio value=0 checked> |.$locale->text('Detail').qq|
		</td>
	      </tr>
	    </table>
	  </td>
|;

  $l{name} = qq|<input name=l_name class=checkbox type=checkbox value=Y> |.$locale->text('Name');
  $l{curr} = qq|<input name=l_curr class=checkbox type=checkbox value=Y> |.$locale->text('Currency');
  $l{employee} = qq|<input name=l_employee class=checkbox type=checkbox value=Y> |.$locale->text('Employee');
  $l{serialnumber} = qq|<input name=l_serialnumber class=checkbox type=checkbox value=Y> |.$locale->text('Serial Number');

  $serialnumber = qq|
          <th align=right nowrap>|.$locale->text('Serial Number').qq|</th>
          <td><input name=serialnumber size=20></td>
|;

  $orphaned = qq|
            <input name=itemstatus class=radio type=radio value=orphaned>&nbsp;|.$locale->text('Orphaned');

  if ($form->{searchitems} =~ /(all|part|assembly)/) {
    
    $onhand = qq|
            <input name=itemstatus class=radio type=radio value=onhand>&nbsp;|.$locale->text('On Hand').qq|
            <input name=itemstatus class=radio type=radio value=short>&nbsp;|.$locale->text('Short').qq|
|;

    $makemodel = qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Make').qq|</th>
          <td><input name=make size=20></td>
          <th align=right nowrap>|.$locale->text('Model').qq|</th>
          <td><input name=model size=20></td>
        </tr>
|;

    $l{make} = qq|<input name=l_make class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Make');
    $l{model} = qq|<input name=l_model class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Model');

    $l{bin} = qq|<input name=l_bin class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Bin');

    $l{rop} = qq|<input name=l_rop class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('ROP');

    $l{weight} = qq|<input name=l_weight class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Weight');

    $l{countryorigin} = qq|<input name=l_countryorigin class=checkbox type=checkbox value=Y> |.$locale->text('Country of Origin');
    $l{tariff_hscode} = qq|<input name=l_tariff_hscode class=checkbox type=checkbox value=Y> |.$locale->text('HS Code');

    if (@{ $form->{all_warehouse} }) {
      $selectwarehouse = "<option>\n";

      for (@{ $form->{all_warehouse} }) { $selectwarehouse .= qq|<option value="|.$form->quote($_->{description}).qq|--$_->{id}">$_->{description}\n| }
      
      $warehouse = qq|
          <th align=right nowrap>|.$locale->text('Warehouse').qq|</th>
          <td><select name=warehouse>$selectwarehouse</select></td>
|;

      $l{warehouse} = qq|<input name=l_warehouse class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Warehouse');

    }

    $drawing = qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Drawing').qq|</th>
          <td><input name=drawing size=20></td>
	  <th align=right nowrap>|.$locale->text('Tool Number').qq|</th>
	  <td><input name=toolnumber size=20></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Microfiche').qq|</th>
          <td><input name=microfiche size=20></td>
          <th align=right nowrap>|.$locale->text('Barcode').qq|</th>
          <td><input name=barcode size=30></td>
        </tr>
|;

    $l{toolnumber} = qq|<input name=l_toolnumber class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Tool Number');
    
    $l{barcode} = qq|<input name=l_barcode class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Barcode');
    
    $l{image} = qq|<input name=l_image class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Image');
    
    $l{drawing} = qq|<input name=l_drawing class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Drawing');
    $l{microfiche} = qq|<input name=l_microfiche class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Microfiche');

    $l{cost} = qq|<input name=l_cost class=checkbox type=checkbox value=Y> |.$locale->text('Cost');
  }

  if ($form->{searchitems} eq 'assembly') {

    $bought = "";
 
    $toplevel = qq|
        <tr>
	  <td></td>
          <td colspan=3>
	  <input name=null class=radio type=radio checked>&nbsp;|.$locale->text('Top Level').qq|
	  <input name=individual class=checkbox type=checkbox value=1>&nbsp;|.$locale->text('Individual Items').qq|
          </td>
        </tr>
|;
    $bom = qq|<input name=itemstatus type=radio value=bom>&nbsp;|.$locale->text('BOM');
    
    if ($form->{changeup}) {

      $sold = "";
      $fromto = "";
      delete $l{name};
   
    }

  }
  
  if ($form->{searchitems} eq 'component') {

    $bought = "";
    $sold = "";
    $fromto = "";

    for (qw(name curr employee serialnumber warehouse account)) { delete $l{$_} }
    $warehouse = "";
    $serialnumber = "";
    $orphaned = "";
    
  }
  
  if ($form->{searchitems} eq 'labor') {

    $sold = "";
    $warehouse = "";
    $serialnumber = "";

    for (qw(avgcost cost)) { delete $l{$_} }
    
  }
  
  @f = ();
  push @f, qq|<input name=l_runningnumber class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('No.');
  push @f, qq|<input name=l_partnumber class=checkbox type=checkbox value=Y checked>&nbsp;|.$locale->text('Number');
  push @f, qq|<input name=l_description class=checkbox type=checkbox value=Y checked>&nbsp;|.$locale->text('Description');
  push @f, qq|<input name=l_qty class=checkbox type=checkbox value=Y checked>&nbsp;|.$locale->text('Qty');
  push @f, qq|<input name=l_unit class=checkbox type=checkbox value=Y checked>&nbsp;|.$locale->text('Unit');
  push @f, qq|<input name=l_priceupdate class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Updated');

  for (qw(partsgroup partsgroupcode cost sellprice listprice lastcost avgcost linetotal markup bin rop weight)) {
    push @f, $l{$_} if $l{$_};
  }
  
  push @f, qq|<input name=l_notes class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Notes');

  for (qw(image drawing toolnumber microfiche make model warehouse account name curr employee serialnumber countryorigin tariff_hscode barcode)) {
    push @f, $l{$_} if $l{$_};
  }
  

  %title = ( all	=> 'Items',
             part	=> 'Parts',
	     labor	=> 'Labor/Overhead',
	     service	=> 'Services',
	     assembly	=> 'Assemblies',
	     component	=> 'Components'
	   );

# $locale->text('Items')
# $locale->text('Parts')
# $locale->text('Labor/Overhead')
# $locale->text('Services')
# $locale->text('Assemblies')
# $locale->text('Components')
# $locale->text('Barcodes')
# $locale->text('Changeup Parts')
# $locale->text('Changeup Labor/Overhead')
# $locale->text('Changeup Services')
# $locale->text('Changeup Assemblies')
  
  if ($form->{changeup}) {
    $form->helpref("changeup_items", $myconfig{countrycode});
    $form->{title} = $locale->text('Changeup' . ' ' .$title{$form->{searchitems}});
  } else {
    $form->helpref("search_items", $myconfig{countrycode});
    $form->{title} = $locale->text($title{$form->{searchitems}});
  }
   
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(changeup searchitems title));

  print qq|

<table width="100%">
  <tr><th class=listtop>$form->{helpref}$form->{title}</a></th></tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        <tr>
          <th align=right nowrap>|.$locale->text('Number').qq|</th>
          <td><input name=partnumber size=20></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Description').qq|</th>
          <td colspan=3><input name=description size=40></td>
        </tr>
	<tr>
	  $warehouse
	</tr>
	<tr>
	  $partsgroup
	  $serialnumber
	</tr>
	$makemodel
	$drawing
	$toplevel
        <tr>
          <td></td>
          <td colspan=3>
            <input name=itemstatus class=radio type=radio value=active checked>&nbsp;|.$locale->text('Active').qq|
	    $onhand
            <input name=itemstatus class=radio type=radio value=obsolete>&nbsp;|.$locale->text('Obsolete').qq|
	    $orphaned
	    $bom
	  </td>
	</tr>
        <tr>
	  <td></td>
          <td colspan=3>
	    <hr size=1 noshade>
	  </td>
	</tr>
	<tr>
	  <td></td>
	  $bought
	  $sold
	  $fromto
        </tr>
	<tr>
	  <td></td>
          <td colspan=3>
	    <hr size=1 noshade>
	  </td>
	</tr>
	<tr>
          <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
          <td colspan=3>
            <table>
              <tr>
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
              </tr>
	      <tr>
                <td><input name=l_subtotal class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|</td>
	      </tr>
            </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr><td colspan=4><hr size=3 noshade></td></tr>
</table>

<input type=hidden name=nextsub value=generate_report>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
|;

  $form->hide_form(qw(path login));
  
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



sub generate_report {
  
  # setup $form->{sort}
  unless ($form->{sort}) {
    if ($form->{description} && !($form->{partnumber})) {
      $form->{sort} = "description";
    } else {
      $form->{sort} = "partnumber";
    }
  }
  
  if ($form->{itemstatus} eq 'bom') {
    $form->{l_perassembly} = "Y" if $form->{l_qty} eq "Y";
    $form->{individual} = 1;
    $form->{title} = $locale->text('BOM');
  }

  $callback = "$form->{script}?action=generate_report";
  for (qw(path login searchitems changeup itemstatus individual bom l_linetotal method)) { $callback .= qq|&$_=$form->{$_}| }
  for (qw(warehouse partsgroup title)) { $callback .= qq|&$_=|.$form->escape($form->{$_},1) }

  # if we have a serialnumber limit search
  if ($form->{serialnumber} || $form->{l_serialnumber}) {
    $form->{l_serialnumber} = "Y";
    unless ($form->{bought} || $form->{sold} || $form->{onorder} || $form->{ordered}) {
      if ($form->{searchitems} eq 'assembly') {
	$form->{sold} = $form->{ordered} = 1;
      } else {
	$form->{bought} = $form->{sold} = $form->{onorder} = $form->{ordered} = 1;
      }
    }
  }

 
  if ($form->{itemstatus} eq 'active') {
    $form->{option} .= $locale->text('Active')." : ";
  }
  if ($form->{itemstatus} eq 'obsolete') {
    $form->{option} .= $locale->text('Obsolete')." : ";
  }
  if ($form->{itemstatus} eq 'orphaned') {
    $form->{onhand} = $form->{short} = 0;
    $form->{bought} = $form->{sold} = 0;
    $form->{onorder} = $form->{ordered} = 0;
    $form->{rfq} = $form->{quoted} = 0;

    $form->{l_qty} = 0;
    $form->{warehouse} = "";
    $form->{l_warehouse} = 0;

    $form->{transdatefrom} = $form->{transdateto} = "";
    
    $form->{option} .= $locale->text('Orphaned')." : ";
  }
  if ($form->{itemstatus} eq 'onhand') {
    $form->{option} .= $locale->text('On Hand')." : ";
    $form->{l_onhand} = "Y";
  }
  if ($form->{itemstatus} eq 'short') {
    $form->{option} .= $locale->text('Short')." : ";
    $form->{l_onhand} = "Y";
    $form->{l_rop} = "Y" unless $form->{searchitems} eq 'labor';
    
    $form->{warehouse} = "";
    $form->{l_warehouse} = 0;
  }
  
  if ($form->{l_account}) {
    for (qw(l_name l_curr l_employee)) { delete $form->{$_} }
  } else {
    $ok = 0;
    foreach $l (qw(l_name l_curr l_employee)) {
      if ($form->{$l}) {
	foreach $v (qw(onorder ordered rfq quoted bought sold)) {
	  if ($form->{$v}) {
	    $ok = 1;
	    last;
	  }
	}
	if (!$ok) {
	  for (qw(onorder ordered rfq quoted bought sold)) { $form->{$_} = 1 }
	}
	last;
      }
    }
  }
  
  if ($form->{l_cost}) {
    for (qw(onorder ordered rfq quoted sold)) { $form->{$_} = "" }
    $form->{option} .= $locale->text('Inventory Value')." : ";
    for (qw(bought open closed)) { $form->{$_} = 1 }
    $form->{method} = "accrual";
  }
  
  if ($form->{onorder}) {
    $form->{l_ordnumber} = "Y";
    $callback .= "&onorder=$form->{onorder}";
    $form->{option} .= $locale->text('Purchase Order')." : ";
  }
  if ($form->{ordered}) {
    $form->{l_ordnumber} = "Y";
    $callback .= "&ordered=$form->{ordered}";
    $form->{option} .= $locale->text('Sales Order')." : ";
  }
  if ($form->{rfq}) {
    $form->{l_quonumber} = "Y";
    $callback .= "&rfq=$form->{rfq}";
    $form->{option} .= $locale->text('RFQ')." : ";
  }
  if ($form->{quoted}) {
    $form->{l_quonumber} = "Y";
    $callback .= "&quoted=$form->{quoted}";
    $form->{option} .= $locale->text('Quotation')." : ";
  }
  if ($form->{bought}) {
    $form->{l_invnumber} = "Y";
    $callback .= "&bought=$form->{bought}";
    $form->{option} .= $locale->text('Vendor Invoice')." : ";
  }
  if ($form->{sold}) {
    $form->{l_invnumber} = "Y";
    $callback .= "&sold=$form->{sold}";
    $form->{option} .= $locale->text('Sales Invoice')." : ";
  }
  if ($form->{sold} || $form->{bought}) {
    $label = ucfirst $form->{method};
    $form->{option} .= $locale->text($label) ." : ";
  }

  if ($form->{bought} || $form->{sold} || $form->{onorder} || $form->{ordered} || $form->{rfq} || $form->{quoted}) {
    
    # warehouse stuff is meaningless
    $form->{warehouse} = "";
    $form->{l_warehouse} = 0;
   
    $form->{l_account} = "";

    if ($form->{open}) {
      $callback .= "&open=$form->{open}";
      $form->{option} .= $locale->text('Open');
    }
    if ($form->{closed}) {
      $callback .= "&closed=$form->{closed}";
      if ($form->{open}) {
	$form->{option} .= " : ".$locale->text('Closed');
      } else {
	$form->{option} .= $locale->text('Closed');
      }
    }
    if ($form->{summary}) {
      $callback .= "&summary=$form->{summary}";
      $form->{option} .= " : ".$locale->text('Summary');
      $form->{l_ordnumber} = "";
      $form->{l_quonumber} = "";
      $form->{l_invnumber} = "";
    } else {
      $form->{option} .= " : ".$locale->text('Detail');
    }
 
    if ($form->{transdatefrom}) {
      $callback .= "&transdatefrom=$form->{transdatefrom}";
      $form->{option} .= "\n<br>".$locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{transdatefrom}, 1);
    }
    if ($form->{transdateto}) {
      $callback .= "&transdateto=$form->{transdateto}";
      $form->{option} .= "\n<br>".$locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{transdateto}, 1);
    }
  }
  
  if ($form->{warehouse}) {
    ($warehouse) = split /--/, $form->{warehouse};
    $form->{option} .= "<br>".$locale->text('Warehouse')." : $warehouse";
    $form->{l_warehouse} = 0;
  }
 
  $form->{option} .= "<br>";
  
  if ($form->{partnumber}) {
    $callback .= "&partnumber=".$form->escape($form->{partnumber},1);
    $form->{option} .= $locale->text('Number').qq| : $form->{partnumber}<br>|;
  }
  if ($form->{partsgroup}) {
    ($partsgroup) = split /--/, $form->{partsgroup};
    $form->{option} .= $locale->text('Group').qq| : $partsgroup<br>|;
  }
  if ($form->{serialnumber}) {
    $callback .= "&serialnumber=".$form->escape($form->{serialnumber},1);
    $form->{option} .= $locale->text('Serial Number').qq| : $form->{serialnumber}<br>|;
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $description = $form->{description};
    $description =~ s/\r?\n/<br>/g;
    $form->{option} .= $locale->text('Description').qq| : $form->{description}<br>|;
  }
  if ($form->{make}) {
    $callback .= "&make=".$form->escape($form->{make},1);
    $form->{option} .= $locale->text('Make').qq| : $form->{make}<br>|;
  }
  if ($form->{model}) {
    $callback .= "&model=".$form->escape($form->{model},1);
    $form->{option} .= $locale->text('Model').qq| : $form->{model}<br>|;
  }
  if ($form->{drawing}) {
    $callback .= "&drawing=".$form->escape($form->{drawing},1);
    $form->{option} .= $locale->text('Drawing').qq| : $form->{drawing}<br>|;
  }
  if ($form->{toolnumber}) {
    $callback .= "&toolnumber=".$form->escape($form->{toolnumber},1);
    $form->{option} .= $locale->text('Tool Number').qq| : $form->{toolnumber}<br>|;
  }
  if ($form->{microfiche}) {
    $callback .= "&microfiche=".$form->escape($form->{microfiche},1);
    $form->{option} .= $locale->text('Microfiche').qq| : $form->{microfiche}<br>|;
  }
  if ($form->{barcode}) {
    $callback .= "&barcode=".$form->escape($form->{barcode},1);
    $form->{option} .= $locale->text('Barcode').qq| : $form->{barcode}<br>|;
  }

  if ($form->{l_markup}) {
    $form->{l_sellprice} = "Y";
    $form->{l_lastcostmarkup} = "Y" if $form->{l_lastcost};
    $form->{l_avgcostmarkup} = "Y" if $form->{l_avgcost};
  }

  @columns = $form->sort_columns(qw(partnumber description notes assemblypartnumber partsgroup partsgroupcode make model bin onhand perassembly rop unit cost linetotalcost sellprice linetotalsellprice listprice linetotallistprice lastcost linetotallastcost lastcostmarkup avgcost linetotalavgcost avgcostmarkup curr priceupdate weight image drawing toolnumber barcode microfiche invnumber ordnumber quonumber name employee serialnumber warehouse countryorigin tariff_hscode));
  unshift @columns, "runningnumber";

  if ($form->{l_linetotal}) {
    $form->{l_onhand} = "Y";
    for (qw(sellprice lastcost avgcost listprice cost)) { $form->{"l_linetotal$_"} = "Y" if $form->{"l_$_"} }
  }

  if ($form->{searchitems} eq 'service') {
    # remove bin, weight and rop from list
    for (qw(bin weight rop)) { $form->{"l_$_"} = "" }

    $form->{l_onhand} = "";
    # qty is irrelevant unless bought or sold
    if ($form->{bought} || $form->{sold} || $form->{onorder} ||
        $form->{ordered} || $form->{rfq} || $form->{quoted}) {
      $form->{l_onhand} = "Y";
    } else {
      for (qw(sellprice lastcost avgcost listprice cost)) { $form->{"l_linetotal$_"} = "" }
    }
  } else {
    $form->{l_onhand} = "Y" if $form->{l_qty};
  }
 
  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      # add column to callback
      $callback .= "&l_$item=Y";
    }
  }

  if ($form->{l_account} eq 'Y') {
    if ($form->{searchitems} eq 'all' || $form->{searchitems} eq 'part') {
      push @column_index, (qw(inventory income expense tax));
    } elsif ($form->{searchitems} eq 'service') {
      push @column_index, (qw(income expense tax));
    } elsif ($form->{searchitems} eq 'assembly') {
      push @column_index, (qw(income tax));
    } else {
      push @column_index, (qw(inventory expense));
    }

    $callback .= "&l_account=Y";
  }
  
  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
  }

  IC->all_parts(\%myconfig, \%$form);

  $callback .= "&direction=$form->{direction}&oldsort=$form->{oldsort}";
  
  $href = $callback;
  
  if (@{ $form->{all_printer} }) {
    for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" } 
    chomp $form->{selectprinter};
  }

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }
 
  $form->sort_order();
  
  $callback =~ s/(direction=).*?\&/$1$form->{direction}\&/;

  if ($form->{searchitems} eq 'assembly') {
    if ($form->{l_partnumber}) {
      # replace partnumber with partnumber_
      $ndx = 0;
      foreach $item (@column_index) {
	$ndx++;
	last if $item eq 'partnumber';
      }

      splice @column_index, $ndx, 0, map { "partnumber_$_" } (1 .. $form->{pncol});
      $colspan = $form->{pncol} + 1;
    }
  }

  if ($form->{searchitems} eq 'component') {
    if ($form->{l_partnumber}) {
      # splice it in after the partnumber
      $ndx = 0;
      foreach $item (@column_index) {
	$ndx++;
	last if $item eq 'partnumber';
      }
      
      @f = splice @column_index, 0, $ndx;
      unshift @column_index, "assemblypartnumber";
      unshift @column_index, @f;
    }
  }
  
  $column_data{runningnumber} = qq|<th a class=listheading>&nbsp;</th>|;
  $hdr{partnumber} = { label => $locale->text('Number'), align => l };
  $column_data{partnumber} = qq|<th nowrap colspan=$colspan><a class=listheading href=$href&sort=partnumber>$hdr{partnumber}{label}</a></th>|;
  $hdr{description} = { label => $locale->text('Description'), align => p };
  $column_data{description} = qq|<th nowrap><a class=listheading href=$href&sort=description>$hdr{description}{label}</a></th>|;
  $hdr{notes} = { label => $locale->text('Notes'), align => p };
  $column_data{notes} = qq|<th nowrap class=listheading>$hdr{notes}{label}</th>|;
  $hdr{partsgroup} = { label => $locale->text('Group'), align => l };
  $column_data{partsgroup} = qq|<th nowrap><a class=listheading href=$href&sort=partsgroup>$hdr{partsgroup}{label}</a></th>|;
  $hdr{partsgroupcode} = { label => $locale->text('Group Code'), align => l };
  $column_data{partsgroupcode} = qq|<th nowrap><a class=listheading href=$href&sort=partsgroupcode>$hdr{partsgroupcode}{label}</a></th>|;

  $hdr{bin} = { label => $locale->text('Bin'), align => l };
  $column_data{bin} = qq|<th><a class=listheading href=$href&sort=bin>$hdr{bin}{label}</a></th>|;
  $hdr{priceupdate} = { label => $locale->text('Updated'), align => l };
  $column_data{priceupdate} = qq|<th nowrap><a class=listheading href=$href&sort=priceupdate>$hdr{priceupdate}{label}</a></th>|;
  $hdr{onhand} = { label => $locale->text('Qty'), align => r, type => n };
  $column_data{onhand} = qq|<th class=listheading nowrap>$hdr{onhand}{label}</th>|;
  $column_data{perassembly} = qq|<th>&nbsp;</th>|;
  $hdr{unit} = { label => $locale->text('Unit'), align => l };
  $column_data{unit} = qq|<th class=listheading nowrap>$hdr{unit}{label}</th>|;
  $hdr{cost} = { label => $locale->text('Cost'), align => r, type => n, precision => $form->{precision} };
  $column_data{cost} = qq|<th class=listheading nowrap>$hdr{cost}{label}</th>|;
  $hdr{listprice} = { label => $locale->text('List Price'), align => r, type => n, precision => $form->{precision} };
  $column_data{listprice} = qq|<th class=listheading nowrap>$hdr{listprice}{label}</th>|;
  $hdr{lastcost} = { label => $locale->text('Last Cost'), align => r, type => n, precision => $form->{precision} };
  $column_data{lastcost} = qq|<th class=listheading nowrap>$hdr{lastcost}{label}</th>|;
  $hdr{avgcost} = { label => $locale->text('Avg Cost'), align => r, type => n, precision => $form->{precision} };
  $column_data{avgcost} = qq|<th class=listheading nowrap>$hdr{avgcost}{label}</th>|;
  $hdr{rop} = { label => $locale->text('ROP'), align => r, type => n };
  $column_data{rop} = qq|<th class=listheading nowrap>$hdr{rop}{label}</th>|;
  $hdr{weight} = { label => $locale->text('Weight'), align => r, type => n };
  $column_data{weight} = qq|<th class=listheading nowrap>$hdr{weight}{label}</th>|;
  $hdr{avgcostmarkup} = { label => '%', align => r, type => n };
  $column_data{avgcostmarkup} = qq|<th class=listheading nowrap>%</th>|;
  $hdr{lastcostmarkup} = { label => '%', align => r, type => n };
  $column_data{lastcostmarkup} = qq|<th class=listheading nowrap>%</th>|;

  $hdr{make} = { label => $locale->text('Make'), align => l };
  $column_data{make} = qq|<th nowrap><a class=listheading href=$href&sort=make>$hdr{make}{label}</a></th>|;
  $hdr{model} = { label => $locale->text('Model'), align => l };
  $column_data{model} = qq|<th nowrap><a class=listheading href=$href&sort=model>$hdr{model}{label}</a></th>|;
  
  $hdr{invnumber} = { label => $locale->text('Invoice Number'), align => l };
  $column_data{invnumber} = qq|<th nowrap><a class=listheading href=$href&sort=invnumber>$hdr{invnumber}{label}</a></th>|;
  $hdr{ordnumber} = { label => $locale->text('Order Number'), align => l };
  $column_data{ordnumber} = qq|<th nowrap><a class=listheading href=$href&sort=ordnumber>$hdr{ordnumber}{label}</a></th>|;
  $hdr{quonumber} = { label => $locale->text('Quotation'), align => l };
  $column_data{quonumber} = qq|<th nowrap><a class=listheading href=$href&sort=quonumber>$hdr{quonumber}{label}</a></th>|;
  
  $hdr{name} = { label => $locale->text('Name'), align => l };
  $column_data{name} = qq|<th nowrap><a class=listheading href=$href&sort=name>$hdr{name}{label}</a></th>|;
  
  $hdr{employee} = { label => $locale->text('Employee'), align => l };
  $column_data{employee} = qq|<th nowrap><a class=listheading href=$href&sort=employee>$hdr{employee}{label}</a></th>|;
  
  $hdr{sellprice} = { label => $locale->text('Sell Price'), align => r, type => n, precision => $form->{precision} };
  $column_data{sellprice} = qq|<th class=listheading nowrap>$hdr{sellprice}{label}</th>|;
  
  $extended = $locale->text('Extended');
  for (qw(sellprice lastcost avgcost listprice cost)) {
    $hdr{"linetotal$_"} = { label => $extended, align => r, type => n, precision => $form->{precision} };
    $column_data{"linetotal$_"} = qq|<th class=listheading nowrap>$hdr{"linetotal$_"}{label}</th>|;
  }
  
  $hdr{curr} = { label => $locale->text('Curr'), align => l };
  $column_data{curr} = qq|<th nowrap><a class=listheading href=$href&sort=curr>$hdr{curr}{label}</a></th>|;
  
  $hdr{image} = { label => $locale->text('Image'), align => l };
  $column_data{image} = qq|<th class=listheading nowrap>$hdr{image}{label}</th>|;
  $hdr{drawing} = { label => $locale->text('Drawing'), align => l };
  $column_data{drawing} = qq|<th nowrap><a class=listheading href=$href&sort=drawing>$hdr{drawing}{label}</a></th>|;
  $hdr{toolnumber} = { label => $locale->text('Tool Number'), align => l };
  $column_data{toolnumber} = qq|<th nowrap><a class=listheading href=$href&sort=toolnumber>$hdr{toolnumber}{label}</a></th>|;

  $hdr{microfiche} = { label => $locale->text('Microfiche'), align => l };
  $column_data{microfiche} = qq|<th nowrap><a class=listheading href=$href&sort=microfiche>$hdr{microfiche}{label}</a></th>|;
  
  $hdr{countryorigin} = { label => $locale->text('CO'), align => l };
  $column_data{countryorigin} = qq|<th nowrap><a class=listheading href=$href&sort=countryorigin>$hdr{countryorigin}{label}</a></th>|;
  $hdr{tariff_hscode} = { label => $locale->text('HS Code'), align => l };
  $column_data{tariff_hscode} = qq|<th nowrap><a class=listheading href=$href&sort=tariff_hscode>$hdr{tariff_hscode}{label}</a></th>|;
  
  $hdr{barcode} = { label => $locale->text('Barcode'), align => l };
  $column_data{barcode} = qq|<th nowrap><a class=listheading href=$href&sort=barcode>$hdr{barcode}{label}</a></th>|;

  $hdr{serialnumber} = { label => $locale->text('Serial Number'), align => l };
  $column_data{serialnumber} = qq|<th nowrap><a class=listheading href=$href&sort=serialnumber>$hdr{serialnumber}{label}</a></th>|;
  
  $hdr{assemblypartnumber} = { label => $locale->text('Assembly'), align => l };
  $column_data{assemblypartnumber} = qq|<th nowrap><a class=listheading href=$href&sort=assemblypartnumber>$hdr{assemblypartnumber}{label}</a></th>|;
  
  $hdr{warehouse} = { label => $locale->text('Warehouse'), align => l };
  $column_data{warehouse} = qq|<th nowrap class=listheading>$hdr{warehouse}{label}</th>|;

  $hdr{inventory} = { label => $locale->text('Inventory'), align => l };
  $column_data{inventory} = qq|<th nowrap class=listheading>$hdr{inventory}{label}</th>|;
  $hdr{income} = { label => $locale->text('Income'), align => l };
  $column_data{income} = qq|<th nowrap class=listheading>$hdr{income}{label}</th>|;
  $hdr{expense} = { label => $locale->text('Expense'), align => l };
  $column_data{expense} = qq|<th nowrap class=listheading>$hdr{expense}{label}</th>|;
  $hdr{tax} = { label => $locale->text('Tax'), align => l };
  $column_data{tax} = qq|<th nowrap class=listheading>$hdr{tax}{label}</th>|;
  
  $form->header;

  $i = 1;
  if ($form->{changeup}) {
    $form->helpref("list_changeup", $myconfig{countrycode});
  } else {
    $form->helpref("list_items", $myconfig{countrycode});
    if ($form->{searchitems} eq 'part') {
      $button{'Goods & Services--Add Part'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Part').qq|"> |;
      $button{'Goods & Services--Add Part'}{order} = $i++;
    }
    if ($form->{searchitems} eq 'service') {
      $button{'Goods & Services--Add Service'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Service').qq|"> |;
      $button{'Goods & Services--Add Service'}{order} = $i++;
    }
    if ($form->{searchitems} eq 'assembly') {  
      $button{'Goods & Services--Add Assembly'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Assembly').qq|"> |;
      $button{'Goods & Services--Add Assembly'}{order} = $i++;
    }
    if ($form->{searchitems} eq 'labor') {  
      $button{'Goods & Services--Add Labor/Overhead'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Labor/Overhead').qq|"> |;
      $button{'Goods & Services--Add Labor/Overhead'}{order} = $i++;
    }
    
    $button{'Goods & Services--Preview'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Preview').qq|"> |;
    $button{'Goods & Services--Preview'}{order} = $i++;

    $button{'Goods & Services--Print'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Print ').qq|"> |;
    $button{'Goods & Services--Print'}{order} = $i++;
  }

  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }
  
  $title = "$form->{title} / $form->{company}";

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$title</a></th>
  </tr>
  <tr height="5"></tr>

  <tr><td>$form->{option}</td></tr>

  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  $form->{column_index} = "";
  for (@column_index) {
    print "\n$column_data{$_}";
    $form->{column_index} .= "$_--label=$hdr{$_}{label}:align=$hdr{$_}{align}:type=$hdr{$_}{type}:precision=$hdr{$_}{precision};";
  }
  chop $form->{column_index};
  
  print qq|
        </tr>
  |;


  # add order to callback
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);


  $k = $#{ $form->{parts} };
  @groupby = ($form->{sort});
  
  if ($form->{summary}) {
    @groupby = ();
    for (qw(partnumber description notes partsgroup partsgroupcode make model bin curr priceupdate image drawing toolnumber barcode microfiche invnumber ordnumber quonumber name employee serialnumber warehouse countryorigin tariff_hscode)) { $f{$_} = 1 };

    for (@column_index) {
      if ($f{$_}) {
	push @groupby, $_;
      }
    }
    push @groupby, "id";
  }

  if ($k > 0) {
    $samegroup = "";
    for (@groupby) { $samegroup .= $form->{parts}->[0]->{$_} }
  }

  $i = 0;
  $n = 0;

  foreach $ref (@{ $form->{parts} }) {

    $ref->{exchangerate} ||= 1;
    $ref->{discount} *= 1;

    if ($form->{summary}) {

      $summary{$ref->{id}}{total} += $ref->{sellprice} * $ref->{onhand};
      $summary{$ref->{id}}{onhand} += $ref->{onhand};
      $summary{$ref->{id}}{cost} += $ref->{cost} * $ref->{onhand};

      if ($n < $k) {
	$nextgroup = "";
	for (@groupby) { $nextgroup .= $form->{parts}->[$n+1]->{$_} }
	$n++;
	
	$form->{parts}->[$n]->{exchangerate} ||= 1;

        if ($samegroup eq $nextgroup) {
	  for (qw(exchangerate discount)) { $form->{parts}->[$n]->{$_} = ($ref->{$_} + $form->{parts}->[$n]->{$_}) / 2 }
	  next;
	}
	$samegroup = $nextgroup;
      }

      $ref->{onhand} = $summary{$ref->{id}}{onhand};
      if ($ref->{onhand}) {
	$ref->{sellprice} = $summary{$ref->{id}}{total} / $ref->{onhand};
	$ref->{cost} = $summary{$ref->{id}}{cost} / $ref->{onhand};
      }

      $summary{$ref->{id}}{total} = 0;
      $summary{$ref->{id}}{onhand} = 0;
      $summary{$ref->{id}}{cost} = 0;

    }
    
    if ($form->{l_subtotal} eq 'Y' && !$ref->{assemblyitem}) {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&parts_subtotal;
	$sameitem = $ref->{$form->{sort}};
      }
    }
    
    $i++;

    if ($form->{l_curr}) {
      if ($ref->{module} eq 'oe') {
	$ref->{sellprice} = $ref->{sellprice} * (1 - $ref->{discount});
      } else {
	for (qw(sellprice listprice lastcost avgcost cost)) { $ref->{$_} /= $ref->{exchangerate} }
      }
    } else {
      if ($ref->{module} eq 'oe') {
	$ref->{sellprice} = $ref->{sellprice} * (1 - $ref->{discount});
	for (qw(sellprice listprice lastcost avgcost cost)) { $ref->{$_} *= $ref->{exchangerate} }
      }
    }

    if (!$form->{summary}) {
      for (qw(sellprice listprice lastcost avgcost cost)) { $ref->{$_} = $form->round_amount($ref->{$_}, $form->{precision}) }
    }

    if ($form->{l_markup}) {
      $ref->{lastcostmarkup} = (($ref->{sellprice} / $ref->{lastcost}) - 1) * 100 if $ref->{lastcost} != 0;
      $ref->{avgcostmarkup} = (($ref->{sellprice} / $ref->{avgcost}) - 1) * 100 if $ref->{avgcost} != 0;
    }
    
    # use this for assemblies
    $onhand = $ref->{onhand};

    for (qw(description notes)) { $ref->{$_} =~ s/\r?\n/<br>/g }
    
    for (1 .. $form->{pncol}) { $column_data{"partnumber_$_"} = "<td>&nbsp;</td>" }

    $column_data{runningnumber} = "<td align=right>$i</td>";
    $column_data{partnumber} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&changeup=$form->{changeup}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{partnumber}&nbsp;</a></td>";

    if ($ref->{assemblypartnumber}) {
      if ($sameid eq $ref->{id}) {
	$i--;
	for (qw(runningnumber partnumber)) { $column_data{$_} = "<td>&nbsp;</td>" }
      }
    }
    
    $column_data{assemblypartnumber} = "<td><a href=$form->{script}?action=edit&id=$ref->{assembly_id}&changeup=$form->{changeup}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{assemblypartnumber}&nbsp;</a></td>";

    if ($ref->{assemblyitem}) {
      $onhand = 0 if $form->{sold};
      $ref->{income} = "";
      
      for (qw(runningnumber partnumber)) { $column_data{$_} = "<td>&nbsp;</td>" }
      $i--;
      
      $column_data{"partnumber_$ref->{stagger}"} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{partnumber}&nbsp;</a></td>";

    }
    
    for (qw(description notes partsgroup partsgroupcode employee curr)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

    $column_data{onhand} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{onhand}, undef, "&nbsp;")."</td>";
    $column_data{perassembly} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{perassembly}, undef, "&nbsp;")."</td>";

    if ($form->{summary} && $form->{l_linetotal}) {
      $column_data{sellprice} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{sellprice}, $form->{precision}, "&nbsp;") . "</td>";
    } else {
      $column_data{sellprice} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{sellprice}, $form->{precision}, "&nbsp;") . "</td>";
    }
    for (qw(listprice lastcost avgcost cost)) { $column_data{$_} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}, "&nbsp;") . "</td>" }
    
    for (qw(lastcost avgcost)) { $column_data{"${_}markup"} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{"${_}markup"}, 1, "&nbsp;")."</td>" }
    
    if ($form->{l_linetotal}) {
      for (qw(sellprice lastcost avgcost listprice cost)) { $column_data{"linetotal$_"} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{onhand} * $ref->{$_}, $form->{precision}, "&nbsp;")."</td>" }
    }

    if ($ref->{assemblyitem} && $ref->{stagger} > 1) {
      for (qw(sellprice lastcost avgcost listprice cost)) { $column_data{"linetotal$_"} = "<td>&nbsp;</td>" }
    }
    
    if (!$ref->{assemblyitem}) {
      $totalcost += $onhand * $ref->{cost};
      $totalsellprice += $onhand * $ref->{sellprice};
      $totallastcost += $onhand * $ref->{lastcost};
      $totalavgcost += $onhand * $ref->{avgcost};
      $totallistprice += $onhand * $ref->{listprice};
      
      $subtotalonhand += $onhand;
      $subtotalcost += $onhand * $ref->{cost};
      $subtotalsellprice += $onhand * $ref->{sellprice};
      $subtotallastcost += $onhand * $ref->{lastcost};
      $subtotalavgcost += $onhand * $ref->{avgcost};
      $subtotallistprice += $onhand * $ref->{listprice};
    }

    for (qw(rop weight)) { $column_data{$_} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_}, undef, "&nbsp;")."</td>" }
    for (qw(unit bin)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
    $column_data{priceupdate} = "<td nowrap>$ref->{priceupdate}&nbsp;</td>";
    
    $ref->{module} = 'ps' if $ref->{till};
    $column_data{invnumber} = ($ref->{module} ne 'oe') ? "<td><a href=$ref->{module}.pl?action=edit&type=invoice&id=$ref->{trans_id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{invnumber}&nbsp;</a></td>" : "<td>$ref->{invnumber}&nbsp;</td>";
    $column_data{ordnumber} = ($ref->{module} eq 'oe') ? "<td><a href=$ref->{module}.pl?action=edit&type=$ref->{type}&id=$ref->{trans_id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{ordnumber}&nbsp;</a></td>" : "<td>$ref->{ordnumber}&nbsp;</td>";
    $column_data{quonumber} = ($ref->{module} eq 'oe' && !$ref->{ordnumber}) ? "<td><a href=$ref->{module}.pl?action=edit&type=$ref->{type}&id=$ref->{trans_id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{quonumber}&nbsp;</a></td>" : "<td>$ref->{quonumber}&nbsp;</td>";

    $column_data{name} = "<td>$ref->{name}&nbsp;</td>";

    if ($ref->{vc_id}) {
      $column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{vc_id}&db=$ref->{vc}&callback=$callback>$ref->{name}</a></td>|;
    }
   
    $column_data{image} = ($ref->{image}) ? "<td><a href=$ref->{image}><img src=$ref->{image} height=32 border=0></a></td>" : "<td>&nbsp;</td>";
    $column_data{drawing} = ($ref->{drawing}) ? "<td><a href=$ref->{drawing}>$ref->{drawing}</a></td>" : "<td>&nbsp;</td>";
    $column_data{microfiche} = ($ref->{microfiche}) ? "<td><a href=$ref->{microfiche}>$ref->{microfiche}</a></td>" : "<td>&nbsp;</td>";
    
    for (qw(make model serialnumber warehouse inventory income expense tax toolnumber countryorigin tariff_hscode barcode)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
    
    $j++; $j %= 2;
    print "<tr class=listrow$j>";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
    </tr>
|;

    $sameid = $ref->{id};

  }
  
  
  if ($form->{l_subtotal} eq 'Y') {
    &parts_subtotal;
  }

  if ($form->{"l_linetotal"}) {
    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
    $column_data{linetotalcost} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalcost, $form->{precision}, "&nbsp;")."</th>";
    $column_data{linetotalsellprice} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalsellprice, $form->{precision}, "&nbsp;")."</th>";
    $column_data{linetotallastcost} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totallastcost, $form->{precision}, "&nbsp;")."</th>";
    $column_data{linetotalavgcost} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalavgcost, $form->{precision}, "&nbsp;")."</th>";
    $column_data{linetotallistprice} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totallistprice, $form->{precision}, "&nbsp;")."</th>";
    
    print "<tr class=listtotal>";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|</tr>
    |;
  }

  print qq|
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>
|;
 
  print qq|
<br>

<form method=post action=$form->{script}>

<input type=hidden name=item value=$form->{searchitems}>
|;

  $form->hide_form(qw(column_index callback path login option));

  &ic_print_options;

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


sub preview {

  $form->{format} = "pdf";
  $form->{media} = "screen";

  &print_;

}

  
sub ic_print_options {
  
  if (! $latex) {
    for (map { "Goods & Services--$_" } qw(Print Preview)) {
      delete $button{$_};
    }
    return;
  }

  $form->{PD}{$form->{type}} = "selected";
  
  if ($myconfig{printer}) {
    $form->{format} ||= "ps";
  } else {
    $form->{format} ||= "pdf";
  }
  $form->{media} ||= $myconfig{printer};

  if ($form->{selectlanguage}) {
    $lang = qq|<select name=language_code>|.$form->select_option($form->{selectlanguage}, $form->{language_code}, undef, 1).qq|</select>|;
  }
  
  $media = qq|<select name=media>
	  <option value=screen>|.$locale->text('Screen');

  if ($form->{selectprinter} && $latex) {
    $media .= $form->select_option($form->{selectprinter}, $form->{media});
  }
  
  $media .= qq|</select>|;
  
  $format = qq|<select name=format>|;

  $type = qq|<select name=formname>
	    <option value="partsreport" $form->{PD}{partsreport}>|.$locale->text('Parts Report').qq|
	    <option value="barcode" $form->{PD}{barcode}>|.$locale->text('Barcode')
	    .qq|</select>|;

  if ($latex) {
    $format .= qq|
            <option value="ps">|.$locale->text('Postscript').qq|
	    <option value="pdf">|.$locale->text('PDF');
  }

  $format .= qq|</select>|;
  $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;


  print qq|
<table>
  <tr>
    <td>$type</td>
    <td>$lang</td>
    <td>$format</td>
    <td>$media</td>
|;

  print qq|
  </tr>
</table>
<br>
|;

}


sub print_ {

  $form->error($locale->text('Nothing to print')) unless $form->{callback};
  
  ($script, $argv) = split /\?/, $form->{callback};
  
  for (split /&/, $argv) {
    ($key, $value) = split /=/, $_, 2;
    $form->{$key} = $form->unescape($value);
  }

  IC->all_parts(\%myconfig, \%$form);
 
  @columns = ();
  for (split /;/, $form->{column_index}) {
    ($column, $vars) = split /--/, $_;
    push @columns, $column;
    push @colndx, $column;
    $form->{$column} = ();
    %{ $hdr{$column} } = split /[:=]/, $vars;
  }

  for (qw(sku number ship sell)) {
    push @columns, $_;
    $form->{$_} = ();
  }
  $hdr{sku} = { label => $hdr{partnumber}{label}, $hdr{partnumber}{align}, type => c };
  $hdr{number} = $hdr{sku};
  $hdr{ship} = { label => $hdr{onhand}{label}, $hdr{onhand}{align}, type => n };

  foreach $ref (@{ $form->{parts} }) {
    $ref->{sku} = $ref->{partnumber};
    $ref->{number} = $ref->{sku};
    $ref->{sell} = $ref->{sellprice};
    
    if ($form->{formname} eq 'barcode') {
      $ref->{onhand} = 1 if $ref->{onhand} <= 0;
    }
    $ref->{ship} = $ref->{onhand};

    for (qw(sell sellprice listprice lastcost avgcost)) { $ref->{$_} = $form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}) }
    for (qw(qty rop ship onhand weight)) { $ref->{$_} = $form->format_amount(\%myconfig, $ref->{$_}) }

    # build arrays
    for (@columns) {
      push @{ $form->{$_} }, $ref->{$_};
    }
  }
  delete $form->{parts};

  if ($form->{media} !~ /screen/) {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;
  }

  if ($form->{formname} eq 'barcode') {
    $form->{templates} = "$templates/$myconfig{dbname}";
    $form->{IN} = "$form->{formname}.$form->{format}";
    
    if ($form->{format} =~ /(ps|pdf)/) {
      $form->{IN} =~ s/$&$/tex/;
    }

    for $temp (qw(description notes)) {
      for (@{ $form->{$temp} }) {
        $form->{"temp_$temp"} = $_;
        $form->format_string("temp_$temp");
        $_ = $form->{"temp_$temp"};
      }
    }

    $form->parse_template(\%myconfig, $userspath);

  } else {
    
    $form->gentex(\%myconfig, $templates, $userspath, \@colndx, \%hdr);

  }

  if ($form->{callback}) {
    $form->redirect unless $form->{media} eq 'screen';
  } else {
    $form->error($locale->text('Report processed!'));
  }

}


sub parts_subtotal {

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  $subtotalonhand = 0 if ($form->{searchitems} eq 'assembly' && $form->{individual});

  $column_data{onhand} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalonhand, undef, "&nbsp;")."</th>";

  $column_data{linetotalsellprice} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalsellprice, $form->{precision}, "&nbsp;")."</th>";
  $column_data{linetotallistprice} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotallistprice, $form->{precision}, "&nbsp;")."</th>";
  $column_data{linetotallastcost} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotallastcost, $form->{precision}, "&nbsp;")."</th>";
  $column_data{linetotalavgcost} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalavgcost, $form->{precision}, "&nbsp;")."</th>";
  
  $subtotalonhand = 0;
  $subtotalsellprice = 0;
  $subtotallistprice = 0;
  $subtotallastcost = 0;
  $subtotalavgcost = 0;

  print "<tr class=listsubtotal>";

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
  </tr>
|;

}


sub requirements {

  $form->get_partsgroup(\%myconfig, { searchitems => 'parts'});
  $form->all_years(\%myconfig);

  if (@{ $form->{all_partsgroup} }) {
    $partsgroup = qq|<option>\n|;

    for (@{ $form->{all_partsgroup} }) { $partsgroup .= qq|<option value="|.$form->quote($_->{partsgroup}).qq|--$_->{id}">$_->{partsgroup}\n| }

    $partsgroup = qq| 
        <th align=right nowrap>|.$locale->text('Group').qq|</th>
	<td><select name=partsgroup>$partsgroup</select></td>
|;

    $l{partsgroup} = qq|<input name=l_partsgroup class=checkbox type=checkbox value=Y> |.$locale->text('Group');
  }

  if (@{ $form->{all_years} }) {
    $selectaccountingyear = "\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|$_\n| }
    
    $selectfrom = qq|
        <tr>
 	  <th align=right>|.$locale->text('Year').qq|</th>
	  <td colspan=3>
	    <table>
	      <tr>
	        <td>
		<select name=year>|.$form->select_option($selectaccountingyear).qq|</select>
		</td>
		<td>
		  <table>
		    <tr>
|;

    for (sort keys %{ $form->{all_month} }) {
      $i = ($_ * 1) - 1;
      if (($i % 3) == 0) {
	$selectfrom .= qq|
		    </tr>
		    <tr>
|;
      }

      $i = $_ * 1;
	
      $selectfrom .= qq|
		      <td nowrap><input name="l_month_$i" class checkbox type=checkbox value=Y>&nbsp;|.$locale->text($form->{all_month}{$_}).qq|</td>\n|;
    }
		
    $selectfrom .= qq|
		    </tr>
		  </table>
		</td>
	      </tr>
	    </table>
	  </td>
        </tr>
|;
  } else {
    $form->error($locale->text('No History!'));
  }

  $form->{title} = $locale->text('Parts Requirements');
  $form->helpref("parts_requirements", $myconfig{countrycode});

  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

|;

  print qq|

<table width="100%">

  <tr><th class=listtop>$form->{helpref}$form->{title}</a></th></tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        <tr>
          <th align=right nowrap>|.$locale->text('Number').qq|</th>
          <td><input name=partnumber size=20></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Description').qq|</th>
          <td colspan=3><input name=description size=40></td>
        </tr>
	<tr>
	  $partsgroup
	</tr>
	$selectfrom
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=requirements_report>
<input type=hidden name=sort value=partnumber>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->hide_form(qw(path login));
  
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



sub requirements_report {

  $callback = "$form->{script}?action=requirements_report";
  for (qw(path login year)) { $callback .= qq|&$_=$form->{$_}| }
  for (qw(partsgroup)) { $callback .= qq|&$_=|.$form->escape($form->{$_},1) }
  
  if ($form->{partnumber}) {
    $callback .= "&partnumber=".$form->escape($form->{partnumber},1);
    $option .= $locale->text('Number').qq| : $form->{partnumber}<br>|;
  }
  if ($form->{partsgroup}) {
    ($partsgroup) = split /--/, $form->{partsgroup};
    $option .= $locale->text('Group').qq| : $partsgroup<br>|;
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $description = $form->{description};
    $description =~ s/\r?\n/<br>/g;
    $option .= $locale->text('Description').qq| : $form->{description}<br>|;
  }
  
 
  @column_index = $form->sort_columns(qw(partnumber description));
  unshift @column_index, "runningnumber";
  
  for (1 .. 12) {
    if ($form->{"l_month_$_"}) {
      $callback .= qq|&l_month_$_=$form->{"l_month_$_"}|;
      push @column_index, $_;
      $month{$_} = 1;
    }
  }
  
  push @column_index, "year" unless %month;
  push @column_index, qw(onhand so po order);

  IC->requirements(\%myconfig, \%$form);

  $form->sort_order();
  
  $callback .= "&direction=$form->{direction}&oldsort=$form->{oldsort}";
  
  $href = $callback;
  
  $callback =~ s/(direction=).*?\&/$1$form->{direction}\&/;
    
  if (%month) {
    $option .= $locale->text('Year').qq| : $form->{year}<br>|;
  }
    
  
  $column_data{runningnumber} = qq|<th a class=listheading>&nbsp;</th>|;
  $column_data{partnumber} = qq|<th nowrap colspan=$colspan><a class=listheading href=$href&sort=partnumber>|.$locale->text('Number').qq|</a></th>|;
  $column_data{description} = qq|<th nowrap><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_data{onhand} = qq|<th class=listheading nowrap>|.$locale->text('On Hand').qq|</th>|;
  $column_data{so} = qq|<th class=listheading nowrap>|.$locale->text('SO').qq|</th>|;
  $column_data{po} = qq|<th class=listheading nowrap>|.$locale->text('PO').qq|</th>|;
  $column_data{order} = qq|<th class=listheading nowrap>|.$locale->text('Order').qq|</th>|;
  $column_data{year} = qq|<th class=listheading nowrap>$form->{year}</th>|;

  for (sort { $a <=> $b } keys %month) { $column_data{$_} = qq|<th class=listheading nowrap>|.$locale->text($locale->{SHORT_MONTH}[$_-1]).qq|</th>| }
  
  $form->{title} = $locale->text('Parts Requirements');
  
  $form->helpref("requirements_report", $myconfig{countrycode});
  
  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>

  <tr><td>$option</td></tr>

  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
        </tr>
  |;


  # add order to callback
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);

  if (@{ $form->{parts} }) {
    $sameid = $form->{parts}->[0]->{id};
  }

  for (keys %month) { $column_data{$_} = "<td>&nbsp;</td>" }
  
  $i = 0;
  $qty = 0;
  foreach $ref (@{ $form->{parts} }) {

    if ($ref->{id} != $sameid) {
      
      $i++;
      $column_data{runningnumber} = "<td align=right>$i</td>";
      
      $order = 0 if $order < 0;
      $column_data{order} = "<td align=right>".$form->format_amount(\%myconfig, $order, undef, "-")."</td>";
      $j++; $j %= 2;
      print "<tr class=listrow$j>";

      for (@column_index) {
	print "\n$column_data{$_}";
	$column_data{$_} = "<td>&nbsp;</td>";
      }

      print qq|
    </tr>
|;
      $qty = 0;
    }

    
    $ref->{description} =~ s/\r?\n/<br>/g;
    
    $column_data{partnumber} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{partnumber}&nbsp;</a></td>";

    $column_data{description} = "<td>$ref->{description}&nbsp;</td>";

    $column_data{onhand} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{onhand}, undef, "&nbsp;")."</td>";
    $column_data{so} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{so}, undef, "&nbsp;")."</td>";
    $column_data{po} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{po}, undef, "&nbsp;")."</td>";

    if (%month) {
      for (keys %month) {
	$column_data{$_} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_}, undef, "&nbsp;")."</td>";
	$qty += $ref->{$_};
      }
    } else {
      $qty = $ref->{qty};
    }
    
    $column_data{year} = "<td align=right>".$form->format_amount(\%myconfig, $qty, undef, "&nbsp;")."</td>";

    $order = $qty + $ref->{so} - $ref->{po} - $ref->{onhand};

    $sameid = $ref->{id};

  }
  
  if (@{ $form->{parts} }) {
    $i++;
    $column_data{runningnumber} = "<td align=right>$i</td>";

    $order = 0 if $order < 0;
    $column_data{order} = "<td align=right>".$form->format_amount(\%myconfig, $order, undef, "-")."</td>";
    $j++; $j %= 2;
    print "<tr class=listrow$j>";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
    </tr>
|;
  }
 
  print qq|
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>

|;
 
  print qq|

<br>

<form method=post action=$form->{script}>

|;

  $form->hide_form(qw(callback path login));

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


sub so_requirements {
  
  $form->{vc} = "customer";
  
  if (! IC->get_vc(\%myconfig, \%$form)) {
    $form->error($locale->text('No open Sales Orders!'));
  }
  
  $form->all_years(\%myconfig);

  $vcname = $locale->text('Customer');
  $vcnumber = $locale->text('Customer Number');
  
  # setup customers
  if (@{ $form->{"all_$form->{vc}"} }) {
    $form->{"select$form->{vc}"} = "\n";
    for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|$_->{name}--$_->{id}\n| }
    delete $form->{"all_$form->{vc}"};
  }

  $vc = qq|
              <tr>
	        <th align=right nowrap>$vcname</th>
|;

  if ($form->{"select$form->{vc}"}) {
    $vc .= qq|
                <td><select name="$form->{vc}">|.$form->select_option($form->{"select$form->{vc}"}, $form->{$form->{vc}}, 1).qq|</select>
		</td>
              </tr>
|;
  } else {
    $vc .= qq|
               <td><input name="$form->{vc}" value="$form->{$form->{vc}}" size=35>
	       </td>
	     </tr>
	     <tr>
	       <th align=right nowrap>$vcnumber</th>
	       <td><input name="$form->{vc}number" value="$form->{"$form->{vc}number"}" size=35></td>
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
	<td>
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

  $form->{title} = $locale->text('Sales Order Requirements');
  
  $form->helpref("so_requirements", $myconfig{countrycode});
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

|;

  print qq|

<table width="100%">

  <tr><th class=listtop>$form->{helpref}$form->{title}</a></th></tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        <tr>
          <th align=right nowrap>|.$locale->text('Number').qq|</th>
          <td><input name=partnumber size=20></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Description').qq|</th>
          <td><input name=description size=40></td>
        </tr>
	<tr>
	  $vc
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=reqdatefrom size=11 class=date title="$myconfig{dateformat}"> <b>|.$locale->text('To').qq|</b> <input name=reqdateto size=11 class=date title="$myconfig{dateformat}"></td>
	</tr>
	  $selectfrom
	<tr>
	  <td></td>
	  <td>
	  <input name=searchitems class=radio type=radio value=all checked>
	  <b>|.$locale->text('All').qq|</b>
	  <input name=searchitems class=radio type=radio value=part>
	  <b>|.$locale->text('Parts').qq|</b>
	  <input name=searchitems class=radio type=radio value=assembly>
	  <b>|.$locale->text('Assemblies').qq|</b>
	  <input name=searchitems class=radio type=radio value=service>
	  <b>|.$locale->text('Services').qq|</b>
	  </td>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=so_requirements_report>
<input type=hidden name=sort value=partnumber>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->hide_form(qw(vc path login));
  
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


sub so_requirements_report {

  if ($form->{$form->{vc}}) {
    ($form->{$form->{vc}}, $form->{"$form->{vc}_id"}) = split(/--/, $form->{$form->{vc}});
  }

  $form->{title} = $locale->text('Sales Order Requirements');
  
  IC->so_requirements(\%myconfig, \%$form);

  $href = "$form->{script}?action=so_requirements_report";
  for (qw(searchitems vc direction oldsort path login)) { $href .= qq|&$_=$form->{$_}| }

  $form->sort_order();

  $callback = "$form->{script}?action=so_requirements_report";
  for (qw(searchitems vc direction oldsort path login)) { $callback .= qq|&$_=$form->{$_}| }

  
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

  if ($form->{partnumber}) {
    $callback .= "&partnumber=".$form->escape($form->{partnumber},1);
    $href .= "&partnumber=".$form->escape($form->{partnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Number')." : $form->{partnumber}";
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $href .= "&description=".$form->escape($form->{description});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Description')." : $form->{description}";
  }

  if ($form->{reqdatefrom}) {
    $callback .= "&reqdatefrom=$form->{reqdatefrom}";
    $href .= "&reqdatefrom=$form->{reqdatefrom}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{reqdatefrom}, 1);
  }
  if ($form->{reqdateto}) {
    $callback .= "&reqdateto=$form->{reqdateto}";
    $href .= "&reqdateto=$form->{reqdateto}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{reqdateto}, 1);
  }

  @column_index = $form->sort_columns(qw(reqdate id ordnumber name customernumber partnumber description qty));

  $name = $locale->text('Customer');
  $namenumber = $locale->text('Customer Number');
  $namefld = "customernumber";
  
  $column_data{reqdate} = "<th><a class=listheading href=$href&sort=reqdate>".$locale->text('Required by')."</a></th>";
  $column_data{ordnumber} = "<th><a class=listheading href=$href&sort=ordnumber>".$locale->text('Order')."</a></th>";
  $column_data{name} = "<th><a class=listheading href=$href&sort=name>$name</a></th>";
  $column_data{$namefld} = "<th><a class=listheading href=$href&sort=$namefld>$namenumber</a></th>";
  $column_data{partnumber} = "<th><a class=listheading href=$href&sort=partnumber>" . $locale->text('Part Number') . "</a></th>";
  $column_data{description} = "<th><a class=listheading href=$href&sort=description>" . $locale->text('Description') . "</a></th>";
  $column_data{qty} = "<th class=listheading>" . $locale->text('Qty') . "</th>";
  
  $title = "$form->{title} / $form->{company}";
  
  $form->helpref("so_requirements_report", $myconfig{countrycode});
  
  $form->header;

  print qq|
<body>

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
  
  if (@{ $form->{all_parts} }) {
    $sameitem = $form->{all_parts}->[0]->{$form->{sort}};
  }
  
  #
  $i = 0;
  foreach $ref (@{ $form->{all_parts} }) {

    $i++;
    
    $column_data{qty} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{qty}, undef, "&nbsp;")."</td>";
    
    $column_data{ordnumber} = "<td><a href=oe.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&type=sales_order&callback=$callback>$ref->{ordnumber}&nbsp;</a></td>";
    
    $ref->{description} =~ s/\r?\n/<br>/g;
    $column_data{reqdate} = "<td nowrap>$ref->{reqdate}</td>";
    $column_data{description} = "<td>$ref->{description}</td>";
    
    $column_data{partnumber} = qq|<td><a href=ic.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{parts_id}&callback=$callback>$ref->{partnumber}</a></td>|;
    
    $column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{"$form->{vc}_id"}&db=$form->{vc}&callback=$callback>$ref->{name}</a></td>|;
   
    $column_data{$namefld} = qq|<td>$ref->{$namefld}&nbsp;</td>|;
    
    $j++; $j %= 2;

    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "\n$column_data{$_}" }

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

</body>
</html>
|;


}


sub makemodel_row {
  my ($numrows) = @_;

  for (qw(make model)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }

  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th class="listheading">|.$locale->text('Make').qq|</th>
	  <th class="listheading">|.$locale->text('Model').qq|</th>
	</tr>
|;

  for $i (1 .. $numrows) {
    print qq|
	<tr>
	  <td><input name="make_$i" size=30 value="|.$form->quote($form->{"make_$i"}).qq|"></td>
	  <td><input name="model_$i" size=30 value="|.$form->quote($form->{"model_$i"}).qq|"></td>
	</tr>
|;
  }

  print qq|
      </table>
    </td>
  </tr>
|;

}


sub vendor_row {
  my ($numrows) = @_;
  
  $currency = qq|
	  <th class="listheading">|.$locale->text('Curr').qq|</th>| if $form->{selectcurrency};

  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th class="listheading">|.$locale->text('Vendor').qq|</th>
	  <th class="listheading">|.$locale->text('Number').qq|</th>
	  <th class="listheading">|.$locale->text('Cost').qq|</th>
	  $currency
	  <th class="listheading">|.$locale->text('Leadtime').qq|</th>
	</tr>
|;

  for $i (1 .. $numrows) {
    
    if ($form->{selectcurrency}) {
      $currency = qq|
	  <td><select name="vendorcurr_$i">|
	  .$form->select_option($form->{selectcurrency}, $form->{"vendorcurr_$i"})
	  .qq|</select></td>|;
    }
   
    if ($i == $numrows) {
     
      $vendor = qq|
          <td><input name="vendor_$i" size=35 value="|.$form->quote($form->{"vendor_$i"}).qq|"></td>
|;
 
      if ($form->{selectvendor}) {
	$vendor = qq|
	  <td width=99%><select name="vendor_$i">|.$form->select_option($form->{selectvendor}, undef, 1).qq|</select></td>
|;
      }
   
    } else {
      
      $form->hide_form("vendor_$i");
      
      ($vendor) = split /--/, $form->{"vendor_$i"};
      $vendor = qq|
          <td>$vendor</td>
|;
    }
    
    $s = length $form->{"partnumber_$i"};
    $s = ($s > 20) ? $s : 20;
    $fld{partnumber} = qq|<input name="partnumber_$i" value="|.$form->quote($form->{"partnumber_$i"}).qq|" size=$s>|;

    
    print qq|
	<tr>
	  $vendor
	  <td>$fld{partnumber}</td>
	  <td><input name="lastcost_$i" class="inputright" size=11 value=|.$form->format_amount(\%myconfig, $form->{"lastcost_$i"}, $form->{decimalplacescost}).qq|></td>
	  $currency
	  <td nowrap><input name="leadtime_$i" class="inputright" size=5 value=|.$form->format_amount(\%myconfig, $form->{"leadtime_$i"}).qq|> <b>|.$locale->text('days').qq|</b></td>
	</tr>
|;
      
  }

  print qq|
      </table>
    </td>
  </tr>
|;

}


sub customer_row {
  my ($numrows) = @_;

  if ($form->{selectpricegroup}) {
    $pricegroup = qq|
          <th class="listheading">|.$locale->text('Pricegroup').qq|
          </th>
|;
  }

  $currency = qq|<th class="listheading">|.$locale->text('Curr').qq|</th>| if $form->{selectcurrency};
	  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th class="listheading">|.$locale->text('Customer').qq|</th>
	  $pricegroup
	  <th class="listheading">|.$locale->text('Break').qq|</th>
	  <th class="listheading">|.$locale->text('Sell Price').qq|</th>
	  $currency
	  <th class="listheading">|.$locale->text('From').qq|</th>
	  <th class="listheading">|.$locale->text('To').qq|</th>
	</tr>
|;

  for $i (1 .. $numrows) {

    if ($form->{selectcurrency}) {
      $currency = qq|
	  <td><select name="customercurr_$i">|
	  .$form->select_option($form->{selectcurrency}, $form->{"customercurr_$i"})
	  .qq|</select></td>|;
    }
    
    if ($i == $numrows) {
      $customer = qq|
          <td><input name="customer_$i" size=35 value="|.$form->quote($form->{"customer_$i"}).qq|"></td>
	  |;
  
      if ($form->{selectcustomer}) {
	$customer = qq|
	  <td><select name="customer_$i">|.$form->select_option($form->{selectcustomer}, undef, 1).qq|</select></td>
|;
      }

      if ($form->{selectpricegroup}) {
	$pricegroup = qq|
	  <td><select name="pricegroup_$i">|.$form->select_option($form->{selectpricegroup}, undef, 1).qq|</select></td>
|;
      }

    } else {
      ($customer) = split /--/, $form->{"customer_$i"};
      $customer = qq|
          <td>$customer</td>|.$form->hide_form("customer_$i");

      if ($form->{selectpricegroup}) {
	($pricegroup) = split /--/, $form->{"pricegroup_$i"};
	$pricegroup = qq|
	  <td>$pricegroup</td>|.$form->hide_form("pricegroup_$i");
      }
    }
    
    
    print qq|
	<tr>
	  $customer
	  $pricegroup

	  <td><input name="pricebreak_$i" class="inputright" size=5 value=|.$form->format_amount(\%myconfig, $form->{"pricebreak_$i"}).qq|></td>
	  <td><input name="customerprice_$i" class="inputright" size=11 value=|.$form->format_amount(\%myconfig, $form->{"customerprice_$i"}, $form->{decimalplacessell}).qq|></td>
	  $currency
	  <td><input name="validfrom_$i" size=11 class=date title="$myconfig{dateformat}" value="$form->{"validfrom_$i"}"></td>
	  <td><input name="validto_$i" size=11 class=date title="$myconfig{dateformat}" value="$form->{"validto_$i"}"></td>
	</tr>
|;
  }

  print qq|
      </table>
    </td>
  </tr>
|;

}



sub assembly_row {
  my ($numrows) = @_;

  @column_index = qw(runningnumber qty unit bom adj partnumber description sellprice listprice lastcost);

  $form->{sellprice} = 0;
  $form->{listprice} = 0;
  $form->{lastcost} = 0;
  $form->{weight} = 0;

  $column_data{runningnumber} = qq|<th nowrap width=5%>|.$locale->text('Item').qq|</th>|;
  $column_data{qty} = qq|<th align=left nowrap width=10%>|.$locale->text('Qty').qq|</th>|;
  $column_data{unit} = qq|<th align=left nowrap width=5%>|.$locale->text('Unit').qq|</th>|;
  $column_data{partnumber} = qq|<th align=left nowrap width=20%>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th nowrap width=50%>|.$locale->text('Description').qq|</th>|;
  $column_data{sellprice} = qq|<th align=right nowrap>|.$locale->text('Sell').qq|</th>|;
  $column_data{listprice} = qq|<th align=right nowrap>|.$locale->text('List').qq|</th>|;
  $column_data{lastcost} = qq|<th align=right nowrap>|.$locale->text('Cost').qq|</th>|;
  $column_data{bom} = qq|<th>|.$locale->text('BOM').qq|</th>|;
  $column_data{adj} = qq|<th>|.$locale->text('A').qq|</th>|;
  
  print qq|
  <tr>
    <td>
      <table width="100%">
      <tr class=listheading>
	<th class=listheading>|.$locale->text('Individual Items').qq|</th>
      </tr>
      <tr>
	<td>
	  <table width="100%">
	    <tr>
|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
        </tr>
|;

  for $i (1 .. $numrows) {
    for (qw(partnumber description)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }

    $linetotalsellprice = $form->round_amount($form->{"sellprice_$i"} * $form->{"qty_$i"}, $form->{decimalplacessell});
    $form->{sellprice} += $linetotalsellprice;
    
    $linetotallistprice = $form->round_amount($form->{"listprice_$i"} * $form->{"qty_$i"}, $form->{decimalplacessell});
    $form->{listprice} += $linetotallistprice;

    $linetotallastcost = $form->round_amount($form->{"lastcost_$i"} * $form->{"qty_$i"}, $form->{decimalplacescost});
    $form->{lastcost} += $linetotallastcost;

    if ($i == $numrows) {
      $linetotalsellprice = $linetotallistprice = $linetotallastcost = "";
 
      for (qw(runningnumber unit bom adj)) { $column_data{$_} = qq|<td></td>| }

      $column_data{qty} = qq|<td><input name="qty_$i" class="inputright" size=6 value="$form->{"qty_$i"}" accesskey="$i" title="[$i]"></td>|;
      $column_data{partnumber} = qq|<td><input name="partnumber_$i" size=15></td>|;
      $column_data{description} = qq|<td><input name="description_$i" size=30></td>|;

    } else {

      $form->{"qty_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"});

      $linetotalsellprice = $form->format_amount(\%myconfig, $linetotalsellprice, $form->{decimalplacessell}, 0);
      $linetotallistprice = $form->format_amount(\%myconfig, $linetotallistprice, $form->{decimalplacessell}, 0);
      $linetotallastcost = $form->format_amount(\%myconfig, $linetotallastcost, $form->{decimalplacescost}, 0);

      $column_data{partnumber} = qq|<td><a href="$form->{script}?login=$form->{login}&path=$form->{path}&action=edit&id=$form->{"id_$i"}" target=_blank>$form->{"partnumber_$i"}</a></td>|;

      $column_data{runningnumber} = qq|<td><input name="runningnumber_$i" class="inputright" size=3 value="$i"></td>|;
      $column_data{qty} = qq|<td><input name="qty_$i" class="inputright" size=6 value="$form->{"qty_$i"}" accesskey="$i" title="[$i]"></td>|;

      for (qw(bom adj)) { $form->{"${_}_$i"} = ($form->{"${_}_$i"}) ? "checked" : "" }
      $column_data{bom} = qq|<td align=center><input name="bom_$i" type=checkbox class=checkbox value=1 $form->{"bom_$i"}></td>|;
      $column_data{adj} = qq|<td align=center><input name="adj_$i" type=checkbox class=checkbox value=1 $form->{"adj_$i"}></td>|;

      $column_data{unit} = qq|<td>$form->{"unit_$i"}</td>|;
      $column_data{description} = qq|<td>$form->{"description_$i"}</td>|;

      $form->hide_form(map { "${_}_$i" } qw(partnumber description unit));
    }
    
    $column_data{sellprice} = qq|<td align=right>$linetotalsellprice</td>|;
    $column_data{listprice} = qq|<td align=right>$linetotallistprice</td>|;
    $column_data{lastcost} = qq|<td align=right>$linetotallastcost</td>|;
    
    print qq|
        <tr>|;

    for (@column_index) { print "\n$column_data{$_}" }
    
    print qq|
        </tr>
|;
    $form->hide_form(map { "${_}_$i" } qw(id sellprice listprice lastcost weight assembly));
    
  }

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{sellprice} = "<th align=right>".$form->format_amount(\%myconfig, $form->{sellprice}, $form->{decimalplacessell})."</th>";
  $column_data{listprice} = "<th align=right>".$form->format_amount(\%myconfig, $form->{listprice}, $form->{decimalplacessell})."</th>";
  $column_data{lastcost} = "<th align=right>".$form->format_amount(\%myconfig, $form->{lastcost}, $form->{decimalplacescost})."</th>";
  
  print qq|
        <tr>|;

  for (@column_index) { print "\n$column_data{$_}" }
    
  print qq|
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
|;

  $form->hide_form(qw(assembly_rows));
 
}


sub update {

  if (($form->{partsgroup} ne $form->{oldpartsgroup}) || ($form->{partsgroupcode} ne $form->{oldpartsgroupcode})) {
    if ($form->{partsgroupcode} ne $form->{oldpartsgroupcode}) {
      $form->{partsgroup} = "";
      $form->{oldpartsgroup} = "";
      $form->{oldpartsgroupcode} = "";
    }
    if ($form->{partsgroup} ne $form->{oldpartsgroup}) {
      $form->{partsgroupcode} = "";
      $form->{oldpartsgroupcode} = "";
    }

    $form->get_partsgroup(\%myconfig, { all => 1 });
    if (@{ $form->{all_partsgroup} }) {
      $form->{selectpartsgroup} = qq|\n|;

      for (@{ $form->{all_partsgroup} }) { $form->{selectpartsgroup} .= qq|$_->{partsgroup}--$_->{id}\n| }
      delete $form->{all_partsgroup};
    }
    $form->{selectpartsgroup} = $form->escape($form->{selectpartsgroup},1);
    $form->{oldpartsgroup} = $form->{partsgroup};
  }


  if ($form->{item} eq "assembly") {

    $i = $form->{assembly_rows};
   
    # if last row is empty check the form otherwise retrieve item
    if (($form->{"partnumber_$i"} eq "") && ($form->{"description_$i"} eq "")) {
      
      &check_form;
      
    } else {

      IC->assembly_item(\%myconfig, \%$form);

      $rows = scalar @{ $form->{item_list} };
      
      if ($rows) {
	$form->{"adj_$i"} = 1;
	
	if ($rows > 1) {
	  $form->{makemodel_rows}--;
	  $form->{customer_rows}--;
	  &select_item;
	  exit;
	} else {
	  $form->{"qty_$i"} = 1;
	  $form->{"adj_$i"} = 1;
	  for (qw(partnumber description unit)) { $form->{item_list}[$i]{$_} = $form->quote($form->{item_list}[$i]{$_}) }
	  for (keys %{ $form->{item_list}[0] }) { $form->{"${_}_$i"} = $form->{item_list}[0]{$_} }

	  $form->{"runningnumber_$i"} = $form->{assembly_rows};
	  $form->{assembly_rows}++;

	  &check_form;

	}

      } else {

        $form->{rowcount} = $i;
	$form->{assembly_rows}++;
	
	&new_item;

      }
    }

  } else {
  
    &check_form;

  }

}


sub check_vendor {
  
  @flds = qw(vendor partnumber lastcost leadtime vendorcurr);
  @f = (); 
  $count = 0; 

  for (qw(lastcost leadtime)) { $form->{"${_}_$form->{vendor_rows}"} = $form->parse_amount(\%myconfig, $form->{"${_}_$form->{vendor_rows}"}) }
  
  for $i (1 .. $form->{vendor_rows} - 1) {
    
    for (qw(lastcost leadtime)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    if ($form->{"lastcost_$i"} || $form->{"partnumber_$i"}) {

      push @f, {};
      $j = $#f; 
      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;

    } 
  }
  
  $i = $form->{vendor_rows};
  
  if (!$form->{selectvendor}) {

    if ($form->{"vendor_$i"} && !$form->{"vendor_id_$i"}) {
      ($form->{vendor}) = split /--/, $form->{"vendor_$i"};
      if (($j = $form->get_name(\%myconfig, vendor)) > 1) {
	&select_name(vendor, $i);
	exit;
      }

      if ($j == 1) {
	# we got one name
	$form->{"vendor_$i"} = qq|$form->{name_list}[0]->{name}--$form->{name_list}[0]->{id}|;
      } else {
	# name is not on file
	$form->error(qq|$form->{"vendor_$i"} : |.$locale->text('Vendor not on file!'));
      }
    }
  }

  if ($form->{"vendor_$i"}) {
    push @f, {};
    $j = $#f; 
    for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
    $count++;
  }

  $form->redo_rows(\@flds, \@f, $count, $form->{vendor_rows});
  $form->{vendor_rows} = $count;

}


sub check_customer {
  
  @flds = qw(customer validfrom validto pricebreak customerprice pricegroup customercurr);
  @f = (); 
  $count = 0;

  for (qw(customerprice pricebreak)) { $form->{"${_}_$form->{customer_rows}"} = $form->parse_amount(\%myconfig, $form->{"${_}_$form->{customer_rows}"}) }

  for $i (1 .. $form->{customer_rows} - 1) {

    for (qw(customerprice pricebreak)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    if ($form->{"customerprice_$i"}) {
      if ($form->{"pricebreak_$i"} || $form->{"customer_$i"} || $form->{"pricegroup_$i"}) {
	
	push @f, {};
	$j = $#f; 
	for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
	
      }
    }
  }

  $i = $form->{customer_rows};

  if (!$form->{selectcustomer}) {

    if ($form->{"customer_$i"} && !$form->{"customer_id_$i"}) {
      ($form->{customer}) = split /--/, $form->{"customer_$i"};

      if (($j = $form->get_name(\%myconfig, customer)) > 1) {
	&select_name(customer, $i);
	exit;
      }

      if ($j == 1) {
	# we got one name
	$form->{"customer_$i"} = qq|$form->{name_list}[0]->{name}--$form->{name_list}[0]->{id}|;
      } else {
	# name is not on file
	$form->error(qq|$form->{customer} : |.$locale->text('Customer not on file!'));
      }
    }
  }

  if ($form->{"customer_$i"} || $form->{"pricegroup_$i"} || ($form->{"customerprice_$i"} || $form->{"pricebreak_$i"})) {
    push @f, {};
    $j = $#f; 
    for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
    $count++;
  }

  $form->redo_rows(\@flds, \@f, $count, $form->{customer_rows});
  $form->{customer_rows} = $count;

}



sub select_name {
  my ($table, $vr) = @_;
  
  @column_index = (ndx, name, "${table}number", address);

# $locale->text('Customer Number')
# $locale->text('Vendor Number')

  $label = ucfirst $table;
  $labelnumber = $locale->text("$label Number");
  
  $column_data{ndx} = qq|<th class=listheading width=1%>&nbsp;</th>|;
  $column_data{name} = qq|<th class=listheading>|.$locale->text($label).qq|</th>|;
  $column_data{"${table}number"} = qq|<th class=listheading>|.$locale->text($labelnumber).qq|</th>|;
  $column_data{address} = qq|<th class=listheading colspan=5>|.$locale->text('Address').qq|</th>|;
  
  $helpref = $form->{helpref};
  $form->helpref("select_name", $myconfig{countrycode});
  
  # list items with radio button on a form
  $form->header;

  $title = $locale->text('Select from one of the names below');

  print qq|
<body>

<form method=post action="$form->{script}">

<input type=hidden name=vr value=$vr>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$title</a></th>
  </tr>
  <tr space=5></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
	</tr>
|;

  @column_index = (ndx, name, "${table}number", address, city, state, zipcode, country);
  
  my $i = 0;
  foreach $ref (@{ $form->{name_list} }) {
    $checked = ($i++) ? "" : "checked";

    $ref->{name} = $form->quote($ref->{name});
    
   $column_data{ndx} = qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
   $column_data{name} = qq|<td><input name="new_name_$i" type=hidden value="|.$form->quote($ref->{name}).qq|">$ref->{name}</td>|;
   $column_data{"${table}number"} = qq|<td>$ref->{"${table}number"}</td>|;
   $column_data{address} = qq|<td>$ref->{address1} $ref->{address2}|;
   for (qw(city state zipcode country)) { $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>| }
    
    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>

<input name="new_id_$i" type=hidden value=$ref->{id}>

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

<input name=lastndx type=hidden value=$i>

|;

  # delete variables
  for (qw(action nextsub name_list)) { delete $form->{$_} }
  $form->{helpref} = $helpref;

  $form->hide_form;
  
  print qq|
<input type=hidden name=nextsub value=name_selected>
<input type=hidden name=vc value=$table>
<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}



sub name_selected {

  # replace the variable with the one checked

  # index for new item
  $i = $form->{ndx};
  
  $form->{"$form->{vc}_$form->{vr}"} = qq|$form->{"new_name_$i"}--$form->{"new_id_$i"}|;
  $form->{"$form->{vc}_id_$form->{vr}"} = $form->{"new_id_$i"};

  # delete all the new_ variables
  for $i (1 .. $form->{lastndx}) {
    for (qw(id name)) { delete $form->{"new_${_}_$i"} }
  }
  
  for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

  &update;

}


sub save {

# $locale->text('Inventory quantity must be zero before you can set this part obsolete!')
# $locale->text('Inventory quantity must be zero before you can set this assembly obsolete!')

  $msg = "Inventory quantity must be zero before you can set this $form->{item} obsolete!";

  if ($form->{obsolete}) {
    if (! $form->{changeup}) {
      $form->error($locale->text($msg)) if $form->{onhand};
    }
  }

  $olditem = $form->{id};

  # save part
  $rc = IC->save(\%myconfig, \%$form);

  $parts_id = $form->{id};

  # load previous variables
  if ($form->{previousform} && !$form->{callback}) {
    # save the new form variables before splitting previousform
    for (keys %$form) { $newform{$_} = $form->{$_} }

    $previousform = $form->unescape($form->{previousform});

    # don't trample on previous variables
    for (keys %newform) { delete $form->{$_} }

    # now take it apart and restore original values
    foreach $item (split /&/, $previousform) {
      ($key, $value) = split /=/, $item, 2;
      $value =~ s/%26/&/g;
      $form->{$key} = $value;
    }

    if ($form->{item} eq 'assembly') {

      # undo number formatting
      for (qw(weight listprice sellprice lastcost rop)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }

      $form->{assembly_rows}-- if $olditem;
      $i = $newform{rowcount};
      $form->{"qty_$i"} = 1 unless ($form->{"qty_$i"});

      $form->{listprice} -= $form->{"listprice_$i"} * $form->{"qty_$i"};
      $form->{sellprice} -= $form->{"sellprice_$i"} * $form->{"qty_$i"};
      $form->{lastcost} -= $form->{"lastcost_$i"} * $form->{"qty_$i"};
      $form->{weight} -= $form->{"weight_$i"} * $form->{"qty_$i"};

      # change/add values for assembly item
      for (qw(partnumber description bin unit weight listprice sellprice lastcost)) { $form->{"${_}_$i"} = $newform{$_} }

      foreach $item (qw(listprice sellprice lastcost)) {
	$form->{$item} += $form->{"${item}_$i"} * $form->{"qty_$i"};
	$form->{$item} = $form->round_amount($form->{$item}, $form->{precision});
      }
	
      $form->{weight} += $form->{"weight_$i"} * $form->{"qty_$i"};

      $form->{"adj_$i"} = 1 if !$olditem;

      $form->{customer_rows}--;
      
    } else {
      # set values for last invoice/order item
      $i = $form->{rowcount};
      $form->{"qty_$i"} = 1 unless ($form->{"qty_$i"});

      for (qw(partnumber description bin unit listprice sellprice partsgroup)) { $form->{"${_}_$i"} = $newform{$_} }
      $form->{"itemnotes_$i"} = $newform{notes};
      for (qw(inventory income expense)) {
	$form->{"${_}_accno_id_$i"} = $newform{"IC_$_"};
	$form->{"${_}_accno_id_$i"} =~ s/--.*//;
      }

      if ($form->{vendor_id}) {
	$form->{"sellprice_$i"} = $newform{lastcost};

	for ($j = 1; $j <= $newform{vendor_rows}; $j++) {
	  # if vendor matches and there is a number
	  if ($newform{"vendor_$j"} && $newform{"vendor_$j"} eq $form->{oldvendor}) {
	    if ($newform{"partnumber_$j"}) {
	      $form->{"partnumber_$i"} = $newform{"partnumber_$j"};
	      $form->{"sku_$i"} = $form->{"partnumber_$i"};
	    }
	    $form->{"sellprice_$i"} = $newform{"lastcost_$j"};
	  }
	}
      }

      if ($form->{exchangerate} != 0) {
	$form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"} / $form->{exchangerate}, $form->{precision});
      }
      
      for (split / /, $newform{taxaccounts}) { $form->{"taxaccounts_$i"} .= "$_ " if ($newform{"IC_tax_$_"}) }
      chop $form->{"taxaccounts_$i"};

      # credit remaining calculation
      $amount = $form->{"sellprice_$i"} * (1 - $form->{"discount_$i"} / 100) * $form->{"qty_$i"};
      for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $amount }
      if (!$form->{taxincluded}) {
	for (split / /, $form->{"taxaccounts_$i"}) { $amount += ($form->{"${_}_base"} * $form->{"${_}_rate"}) }
      }

      $ml = 1;
      if ($form->{type} =~ /invoice/) {
	$ml = -1 if $form->{type} =~ /(debit|credit)_invoice/;
      }
      $form->{creditremaining} -= ($amount * $ml);
      
    }
    
    $form->{"id_$i"} = $parts_id;
    delete $form->{action};

    # restore original callback
    $callback = $form->unescape($form->{callback});
    $form->{callback} = $form->unescape($form->{oldcallback});
    delete $form->{oldcallback};

    $form->{makemodel_rows}--;

    # put callback together
    foreach $key (keys %$form) {
      # do single escape for Apache 2.0
      $value = $form->escape($form->{$key}, 1);
      $callback .= qq|&$key=$value|;
    }
    $form->{callback} = $callback;
  }

  # redirect
  $form->redirect;

}


sub save_as_new {

  $form->{id} = 0;
  &save;

}


sub delete {

  # redirect
  if (IC->delete(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Item deleted!'));
  } else {
    $form->error($locale->text('Cannot delete item!'));
  }

}



sub stock_assembly {

  $form->{title} = $locale->text('Stock Assembly');
  
  $form->helpref("stock_assembly", $myconfig{countrycode});

  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width="100%">
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        <tr>
          <th align="right" nowrap="true">|.$locale->text('Number').qq|</th>
          <td><input name=partnumber size=20></td>
          <td>&nbsp;</td>
        </tr>
        <tr>
          <th align="right" nowrap="true">|.$locale->text('Description').qq|</th>
          <td><input name=description size=40></td>
        </tr>
        <tr>
          <td></td>
	  <td><input name=checkinventory class=checkbox type=checkbox value=1>&nbsp;|.$locale->text('Check Inventory').qq|</td>
        </tr>
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>

<input type=hidden name=sort value=partnumber>
|;

  $form->hide_form(qw(path login));

  print qq|
<input type=hidden name=nextsub value=list_assemblies>

<br>
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




sub list_assemblies {

  IC->retrieve_assemblies(\%myconfig, \%$form);

  $callback = "$form->{script}?action=list_assemblies&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&checkinventory=$form->{checkinventory}";
  
  $form->sort_order();
  $href = "$form->{script}?action=list_assemblies&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&checkinventory=$form->{checkinventory}";
  
  if ($form->{partnumber}) {
    $callback .= "&partnumber=".$form->escape($form->{partnumber},1);
    $href .= "&partnumber=".$form->escape($form->{partnumber});
    $form->{sort} = "partnumber" unless $form->{sort};
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $href .= "&description=".$form->escape($form->{description});
    $form->{sort} = "description" unless $form->{sort};
  }
 
  $column_data{partnumber} = qq|<th><a class=listheading href=$href&sort=partnumber>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</th>|;
  $column_data{bin} = qq|<th><a class=listheading href=$href&sort=bin>|.$locale->text('Bin').qq|</th>|;
  $column_data{onhand} = qq|<th class=listheading>|.$locale->text('Qty').qq|</th>|;
  $column_data{rop} = qq|<th class=listheading>|.$locale->text('ROP').qq|</th>|;
  $column_data{stock} = qq|<th class=listheading>|.$locale->text('Add').qq|</th>|;

  @column_index = $form->sort_columns(qw(partnumber description bin onhand rop stock));
  
  $form->{title} = $locale->text('Stock Assembly');

  $form->helpref("list_assemblies", $myconfig{countrycode});
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr size=5></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
	</tr>
|;

  # add sort and escape callback
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);


  $i = 1;
  foreach $ref (@{ $form->{assembly_items} }) {

    for (qw(partnumber description)) { $ref->{$_} = $form->quote($ref->{$_}) }
   
    $column_data{partnumber} = "<td width=20%><a href=$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{partnumber}&nbsp;</a></td>";
    
    $column_data{description} = qq|<td width=50%>$ref->{description}&nbsp;</td>|;
    $column_data{bin} = qq|<td>$ref->{bin}&nbsp;</td>|;
    $column_data{onhand} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{onhand}, undef, "&nbsp;").qq|</td>|;
    $column_data{rop} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{rop}, undef, "&nbsp;").qq|</td>|;
    $column_data{stock} = qq|<td width=10%><input name="qty_$i" class="inputright" size=8 value=|.$form->format_amount(\%myconfig, $ref->{stock}).qq|></td>
    <input type=hidden name="stock_$i" value=$ref->{stock}>|;

    $j++; $j %= 2;
    print qq|<tr class=listrow$j><input name="id_$i" type=hidden value=$ref->{id}>\n|;
    
    for (@column_index) { print "\n$column_data{$_}" }
    
    print qq|
	</tr>
|;

    $i++;

  }
  
  $i--;
  print qq|
      </td>
    </table>
  <tr>
    <td><hr size=3 noshade>
  </tr>
</table>
|;

  $form->hide_form(qw(checkinventory path login callback));

  print qq|
<input type=hidden name=rowcount value="$i">
<input type=hidden name=nextsub value=restock_assemblies>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">

</form>

</body>
</html>
|;
 
}


sub restock_assemblies {


  if ($form->{checkinventory}) {
    for (1 .. $form->{rowcount}) { $form->error($locale->text('Quantity exceeds available units to stock!')) if $form->parse_amount($myconfig, $form->{"qty_$_"}) > $form->{"stock_$_"} }
  }

  if (IC->restock_assemblies(\%myconfig, \%$form)) {
    if ($form->{callback} =~ /(direction=)(.*?)\&/) {
      $direction = ($2 eq 'ASC') ? 'DESC' : 'ASC';
    }
    $form->{callback} =~ s/direction=(.*?)\&/direction=$direction\&/;
    $form->redirect($locale->text('Assemblies restocked!'));
  } else {
    $form->error($locale->text('Cannot stock assemblies!'));
  }
  
}


sub new_number {

  $form->{partnumber} = $form->update_defaults(\%myconfig, "partnumber");

  &update;

}


sub continue { &{ $form->{nextsub} } };

sub add_part {
  $form->{item} = 'part';
  &add;
}

sub add_service {
  $form->{item} = 'service';
  &add;
}

sub add_assembly {
  $form->{item} = 'assembly';
  &add;
}

sub add_labor_overhead {
  $form->{item} = 'labor';
  &add;
}


