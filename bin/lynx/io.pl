######################################################################
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#######################################################################
#
# common routines used in is, ir, oe
#
#######################################################################

# any custom scripts for this one
if (-f "$form->{path}/custom_io.pl") {
  eval { require "$form->{path}/custom_io.pl"; };
}
if (-f "$form->{path}/$form->{login}_io.pl") {
  eval { require "$form->{path}/$form->{login}_io.pl"; };
}


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


sub display_row {
  my $numrows = shift;

  @column_index = qw(runningnumber partnumber itemdetail description lineitemdetail qty);

  if ($form->{type} eq "sales_order") {
    push @column_index, "ship";
    $column_data{ship} = qq|<th class=listheading align=center width="auto">|.$locale->text('Ship').qq|</th>|;
  }
  if ($form->{type} eq "purchase_order") {
    push @column_index, "ship";
    $column_data{ship} = qq|<th class=listheading align=center width="auto">|.$locale->text('Recd').qq|</th>|;
  }

  if ($form->{language_code} ne $form->{oldlanguage_code}) {
    # rebuild partsgroup
    $l{language_code} = $form->{language_code};
    $l{searchitems} = 'nolabor' if $form->{vc} eq 'customer';
    
    $form->get_partsgroup(\%myconfig, \%l);
    if (@ { $form->{all_partsgroup} }) {
      $form->{selectpartsgroup} = "\n";
      foreach $ref (@ { $form->{all_partsgroup} }) {
	if ($ref->{translation}) {
	  $form->{selectpartsgroup} .= qq|$ref->{translation}--$ref->{id}\n|;
	} else {
	  $form->{selectpartsgroup} .= qq|$ref->{partsgroup}--$ref->{id}\n|;
	}
      }
      $form->{selectpartsgroup} = $form->escape($form->{selectpartsgroup},1);
    }
    $form->{oldlanguage_code} = $form->{language_code};
  }
      

  push @column_index, qw(unit sellprice discount linetotal);

  my $colspan = $#column_index + 1;

  $form->{invsubtotal} = 0;
  for (split / /, $form->{taxaccounts}) { $form->{"${_}_base"} = 0 }
  
  $column_data{runningnumber} = qq|<th class=listheading nowrap>|.$locale->text('Item').qq|</th>|;
  $column_data{partnumber} = qq|<th class=listheading nowrap>|.$locale->text('Number').qq|</th>|;
  $column_data{itemdetail} = qq|<th class=listheading nowrap></th>|;
  $column_data{description} = qq|<th class=listheading nowrap>|.$locale->text('Description').qq|</th>|;
  $column_data{qty} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading nowrap>|.$locale->text('Unit').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading nowrap>|.$locale->text('Price').qq|</th>|;
  $column_data{discount} = qq|<th class=listheading>%</th>|;
  $column_data{linetotal} = qq|<th class=listheading nowrap>|.$locale->text('Extended').qq|</th>|;
  $column_data{bin} = qq|<th class=listheading nowrap>|.$locale->text('Bin').qq|</th>|;
  $column_data{onhand} = qq|<th class=listheading nowrap>|.$locale->text('OH').qq|</th>|;

  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $column_data{lineitemdetail} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll();"></th>|;

  $form->hide_form(qw(weightunit));

  print qq|
<script language="JavaScript">
<!--

function CheckAll(v) {

  var frm = document.forms[0]
  var el = frm.elements
  var re = /lineitemdetail_/;

  for (i = 0; i < el.length; i++) {
    if (el[i].type == 'checkbox' && re.test(el[i].name)) {
      el[i].checked = frm.allbox.checked
    }
  }
}
// -->
</script>

  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;


  $deliverydate = $locale->text('Delivery Date');
  $serialnumber = $locale->text('Serial No.');
  $projectnumber = $locale->text('Project');
  $orderxrefnumber = $locale->text('Order Number');
  $poxrefnumber = $locale->text('PO Number');
  $group = $locale->text('Group');
  $sku = $locale->text('SKU');
  $packagenumber = $locale->text('Packaging');
  $netweight = $locale->text('N.W.');
  $grossweight = $locale->text('G.W.');
  $volume = $locale->text('Volume');

  $delvar = 'deliverydate';
  
  if ($form->{type} =~ /_(order|quotation)$/) {
    $reqdate = $locale->text('Required by');
    $delvar = 'reqdate';
  }

  $exchangerate = $form->parse_amount(\%myconfig, $form->{exchangerate});
  $exchangerate ||= 1;

  $itemdetailok = ($myconfig{acs} =~ /Goods \& Services--Add /) ? 0 : 1;

  $spc = substr($myconfig{numberformat},-3,1);
  for $i (1 .. $numrows) {
    if ($spc eq '.') {
      ($null, $dec) = split /\./, $form->{"sellprice_$i"};
    } else {
      ($null, $dec) = split /,/, $form->{"sellprice_$i"};
    }
    $dec = length $dec;
    $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

    # undo formatting
    for (qw(qty ship discount sellprice netweight grossweight volume)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    if ($form->{type} =~ /_order/) {
      if ($form->{"ship_$i"} != $form->{"oldship_$i"} || $form->{"qty_$i"} != $form->{"oldqty_$i"}) {
	$form->{"netweight_$i"} = $form->{"weight_$i"} * $form->{"ship_$i"};
      }
    } else {
      if ($form->{"qty_$i"} != $form->{"oldqty_$i"}) {
	$form->{"netweight_$i"} = $form->{"weight_$i"} * $form->{"qty_$i"};
      }
    }

    if ($form->{"qty_$i"} != $form->{"oldqty_$i"}) {
      # check pricematrix
      @a = split / /, $form->{"pricematrix_$i"};
      if (scalar @a > 1) {
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

    $discount = $form->round_amount($form->{"sellprice_$i"} * $form->{"discount_$i"}/100, $decimalplaces);
    $linetotal = $form->round_amount($form->{"sellprice_$i"} - $discount, $decimalplaces);
    $linetotal = $form->round_amount($linetotal * $form->{"qty_$i"}, $form->{precision});

    if (($rows = $form->numtextrows($form->{"description_$i"}, 46, 6)) > 1) {
      $form->{"description_$i"} = $form->quote($form->{"description_$i"});
      $column_data{description} = qq|<td><textarea name="description_$i" rows=$rows cols=46 wrap=soft>$form->{"description_$i"}</textarea></td>|;
    } else {
      $form->{"description_$i"} = $form->quote($form->{"description_$i"});
      $column_data{description} = qq|<td><input name="description_$i" size=48 value="|.$form->quote($form->{"description_$i"}).qq|"></td>|;
    }

    $skunumber = qq|
                <br><b>$sku</b> $form->{"sku_$i"}| if ($form->{vc} eq 'vendor' && $form->{"sku_$i"});

    
    if ($form->{selectpartsgroup}) {
      if ($i < $numrows) {
	$partsgroup = qq|
	        <tr>
		  <td colspan=$colspan>
	          <b>$group</b>|.$form->hide_form("partsgroup_$i");
	($form->{"partsgroup_$i"}) = split /--/, $form->{"partsgroup_$i"};
	$partsgroup .= qq|$form->{"partsgroup_$i"}</td>
	        </tr>|;
	$partsgroup = "" unless $form->{"partsgroup_$i"};
      }
    }
    
    $delivery = qq|
          <td colspan=2 nowrap>
	  <b>${$delvar}</b>
	  <input name="${delvar}_$i" size=11 class=date title="$myconfig{dateformat}" value="$form->{"${delvar}_$i"}"></td>
|;

    $itemdetail = "<td></td>";
    $zero = "";
    
    if ($numrows != $i) {
      $zero = "0";
      if ($itemdetailok) {
	$itemdetail = qq|<td><a href="ic.pl?login=$form->{login}&path=$form->{path}&action=edit&id=$form->{"id_$i"}" target=_blank>?</a></td>|;
      }
    }
    
    $column_data{runningnumber} = qq|<td><input name="runningnumber_$i" size=3 value=$i></td>|;
    $column_data{partnumber} = qq|<td><input name="partnumber_$i" size=15 value="|.$form->quote($form->{"partnumber_$i"}).qq|" accesskey="$i" title="[Alt-$i]">$skunumber</td>|;
    $column_data{itemdetail} = $itemdetail;
    $column_data{qty} = qq|<td align=right><input name="qty_$i" title="$form->{"onhand_$i"}" size=8 value=|.$form->format_amount(\%myconfig, $form->{"qty_$i"}).qq|></td>|;
    $column_data{ship} = qq|<td align=right><input name="ship_$i" size=8 value=|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|></td>|;
    $column_data{unit} = qq|<td><input name="unit_$i" size=5 value="|.$form->quote($form->{"unit_$i"}).qq|"></td>|;
    $column_data{sellprice} = qq|<td align=right><input name="sellprice_$i" size=11 value=|.$form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces, $zero).qq|></td>|;
    $column_data{discount} = qq|<td align=right><input name="discount_$i" size=3 value=|.$form->format_amount(\%myconfig, $form->{"discount_$i"}).qq|></td>|;
    $column_data{linetotal} = qq|<td align=right>|.$form->format_amount(\%myconfig, $linetotal, $form->{precision}, $zero).qq|</td>|;
    $column_data{bin} = qq|<td>$form->{"bin_$i"}</td>|;
    $column_data{onhand} = qq|<td>$form->{"onhand_$i"}</td>|;

    $form->{"lineitemdetail_$i"} = ($form->{allbox}) ? 1 : $form->{"lineitemdetail_$i"};
    $form->{"lineitemdetail_$i"} = ($form->{"lineitemdetail_$i"}) ? "checked" : "";
    $column_data{lineitemdetail} = qq|<td><input name="lineitemdetail_$i" type=checkbox class=checkbox $form->{"lineitemdetail_$i"}></td>|;
    
    
    print qq|
        <tr valign=top>|;

    for (@column_index) {
      print "\n$column_data{$_}";
    }
  
    print qq|
        </tr>
<input type=hidden name="oldqty_$i" value="$form->{"qty_$i"}">
<input type=hidden name="oldship_$i" value="$form->{"ship_$i"}">
|;

    $form->hide_form(map { "${_}_$i" } qw(orderitems_id id weight listprice lastcost taxaccounts pricematrix sku onhand bin assembly inventory_accno_id income_accno_id expense_accno_id));
  
    $project = qq|
                <b>$projectnumber</b>
		<select name="projectnumber_$i">|
		.$form->select_option($form->{selectprojectnumber}, $form->{"projectnumber_$i"}, 1)
		.qq|</select>
| if $form->{selectprojectnumber};

    if ($form->{type} !~ /_quotation/) {
      $orderxref = qq|
                <b>$orderxrefnumber</b> <input name="ordernumber_$i" value="$form->{"ordernumber_$i"}"> <a href=oe.pl?action=lookup_order&ordnumber=|.$form->escape($form->{"ordernumber_$i"},1).qq|&vc=customer&path=$form->{path}&login=$form->{login} target=_blank>?</a>
		<b>$poxrefnumber</b> <input name="customerponumber_$i" value="$form->{"customerponumber_$i"}"> <a href=oe.pl?action=lookup_order&ordnumber=|.$form->escape($form->{"customerponumber_$i"},1).qq|&vc=vendor&path=$form->{path}&login=$form->{login} target=_blank>?</a>
|;
    }


    if (($rows = $form->numtextrows($form->{"itemnotes_$i"}, 46, 6)) > 1) {
      $form->{"itemnotes_$i"} = $form->quote($form->{"itemnotes_$i"});
      $itemnotes = qq|<td><textarea name="itemnotes_$i" rows=$rows cols=46 wrap=soft>$form->{"itemnotes_$i"}</textarea></td>|;
    } else {
      $form->{"itemnotes_$i"} = $form->quote($form->{"itemnotes_$i"});
      $itemnotes = qq|<td><input name="itemnotes_$i" size=48 value="|.$form->quote($form->{"itemnotes_$i"}).qq|"></td>|;
    }
	
    $serial = qq|
                <td colspan=6 nowrap><b>$serialnumber</b> <input name="serialnumber_$i" value="|.$form->quote($form->{"serialnumber_$i"}).qq|"></td>| if $form->{type} !~ /_quotation/;

    $package = qq|
		  <td colspan=$colspan>
		  <b>$packagenumber</b>
		  <input name="package_$i" size=20 value="|.$form->quote($form->{"package_$i"}).qq|">
		  <b>$netweight</b>
		  <input name="netweight_$i" size=8 value=|.$form->format_amount(\%myconfig, $form->{"netweight_$i"}).qq|>
		  <b>$grossweight</b>
		  <input name="grossweight_$i" size=8 value=|.$form->format_amount(\%myconfig, $form->{"grossweight_$i"}).qq|> ($form->{weightunit})
		  <b>$volume</b>
		  <input name="volume_$i" size=8 value=|.$form->format_amount(\%myconfig, $form->{"volume_$i"}).qq|>
		  </td>
|;
    
    if ($i == $numrows) {
      $partsgroup = "";
      if ($form->{selectpartsgroup}) {
	$partsgroup = qq|
	        <b>$group</b>
		<select name="partsgroup_$i">|
		.$form->select_option($form->{selectpartsgroup}, undef, 1)
		.qq|</select>
|;
      }

      $serial = "";
      $project = "";
      $orderxref = "";
      $delivery = "";
      $itemnotes = "";
      $package = "";
    }


    # print second and third row
    if ($form->{"lineitemdetail_$i"}) {
      print qq|
        <tr valign=top>
	  $delivery
	  <td></td>
	  $itemnotes
	  $serial
	</tr>
        <tr valign=top>
	  <td colspan=$colspan>
	  $project
	  $orderxref
	  </td>
	</tr>
	$partsgroup
	$package
|;
    } else {
      if ($i == $numrows) {
	print qq|
        <tr valign=top>
	  <td colspan=$colspan>
	  $partsgroup
	  </td>
	</tr>
|;
      }
      
      $form->hide_form(map { "${_}_$i" } ("$delvar", "itemnotes", "serialnumber", "ordernumber", "customerponumber", "projectnumber"));

      $form->hide_form(map { "${_}_$i" } qw(package netweight grossweight volume));
    }

    print qq|
	<tr>
	  <td colspan=$colspan><hr size=1 noshade></td>
	</tr>
|;

    $skunumber = "";

    for (split / /, $form->{"taxaccounts_$i"}) {
      $form->{"${_}_base"} += $linetotal;
    }
  
    $form->{invsubtotal} += $linetotal;
  }

  print qq|
      </table>
    </td>
  </tr>
|;

  $form->{oldcurrency} = $form->{currency};
  $form->hide_form(qw(audittrail oldcurrency));
  
  $form->hide_form(map { "select$_" } qw(partsgroup projectnumber));
  
}


sub select_item {

  if ($form->{vc} eq "vendor") {
    @column_index = qw(ndx partnumber sku description partsgroup onhand sellprice);
  } else {
    @column_index = qw(ndx partnumber description partsgroup onhand sellprice);
  }

  $column_data{ndx} = qq|<th class=listheading width=1%><input name="allbox_select" type=checkbox class=checkbox value="1" onChange="CheckAll();"></th>|;
  $column_data{partnumber} = qq|<th class=listheading>|.$locale->text('Number').qq|</th>|;
  $column_data{sku} = qq|<th class=listheading>|.$locale->text('SKU').qq|</th>|;
  $column_data{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_data{partsgroup} = qq|<th class=listheading>|.$locale->text('Group').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading>|.$locale->text('Price').qq|</th>|;
  $column_data{onhand} = qq|<th class=listheading>|.$locale->text('Qty').qq|</th>|;
  
  $exchangerate = ($form->{exchangerate}) ? $form->{exchangerate} : 1;

  # list items with radio button on a form
  $form->header;

  $title = $locale->text('Select items');

  print qq|
<script language="JavaScript">
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

    for (qw(sku partnumber description unit itemnotes partsgroup)) { $ref->{$_} = $form->quote($ref->{$_}) }

    $column_data{ndx} = qq|<td><input name="ndx_$i" class=checkbox type=checkbox value=$i></td>|;
    
    for (qw(partnumber sku description partsgroup)) { $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>| }
    
    $column_data{sellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice} / $exchangerate, $form->{precision}, "&nbsp;").qq|</td>|;
    $column_data{onhand} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{onhand}, undef, "&nbsp;").qq|</td>|;
    
    $j++; $j %= 2;
    print qq|
        <tr class=listrow$j>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

    for (qw(partnumber sku description partsgroup partsgroup_id bin weight sellprice listprice lastcost onhand unit assembly taxaccounts inventory_accno_id income_accno_id expense_accno_id pricematrix id itemnotes)) {
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

  # delete variables
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

  $i = $form->{rowcount} - 1;
  $i = $form->{assembly_rows} - 1 if ($form->{item} eq 'assembly');
  $qty = ($form->{"qty_$form->{rowcount}"}) ? $form->{"qty_$form->{rowcount}"} : 1;

  for $j (1 .. $form->{lastndx}) {
    
    if ($form->{"ndx_$j"}) {

      $i++;
  
      $form->{"qty_$i"} = $qty;
      $form->{"discount_$i"} ||= $form->{discount} * 100;
      $form->{"reqdate_$i"} = $form->{reqdate} if $form->{type} !~ /_quotation/;

      for (qw(id partnumber sku description sellprice listprice lastcost bin unit weight assembly taxaccounts pricematrix onhand itemnotes inventory_accno_id income_accno_id expense_accno_id)) {
	$form->{"${_}_$i"} = $form->{"new_${_}_$j"};
      }

      $form->{"netweight_$i"} = $form->{"weight_$i"};
      $form->{"grossweight_$i"} = $form->{"weight_$i"};

      $form->{"partsgroup_$i"} = qq|$form->{"new_partsgroup_$j"}--$form->{"new_partsgroup_id_$j"}|;

      ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      $decimalplaces1 = ($dec > $form->{precision}) ? $dec : $form->{precision};
      
      ($dec) = ($form->{"lastcost_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      $decimalplaces2 = ($dec > $form->{precision}) ? $dec : $form->{precision};

      # if there is an exchange rate adjust sellprice
      if (($form->{exchangerate} * 1)) {
	for (qw(sellprice listprice lastcost)) { $form->{"${_}_$i"} /= $form->{exchangerate} }
        # don't format list and cost
	$form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"}, $decimalplaces1);
      }

      # this is for the assembly
      if ($form->{item} eq 'assembly') {
	$form->{"adj_$i"} = 1;
	
	for (qw(sellprice listprice weight)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }

	$form->{sellprice} += ($form->{"sellprice_$i"} * $form->{"qty_$i"});
	$form->{weight} += ($form->{"weight_$i"} * $form->{"qty_$i"});
      }

      $linetotal = $form->{"sellprice_$i"} * (1 - $form->{"discount_$i"} / 100) * $form->{"qty_$i"};
      for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $linetotal }
      $amount = $linetotal;
      if (!$form->{taxincluded}) {
	for (split / /, $form->{"taxaccounts_$i"}) { $amount += $linetotal * $form->{"${_}_rate"} }
      }

      $ml = 1;
      if ($form->{type} =~ /invoice/) {
	$ml = -1 if $form->{type} =~ /(debit|credit)_invoice/;
      }

      $form->{creditremaining} -= ($amount * $ml);

      $form->{"runningnumber_$i"} = $i;
  
      # format amounts
      if ($form->{item} ne 'assembly') {
	for (qw(sellprice listprice)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces1) }
	$form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"}, $decimalplaces2);
      }
      $form->{"discount_$i"} = $form->format_amount(\%myconfig, $form->{"discount_$i"});

    }
  }

  $form->{rowcount} = $i;
  $form->{assembly_rows} = $i if ($form->{item} eq 'assembly');
  
  $focus = "description_$i";

  # delete all the new_ variables
  for $i (1 .. $form->{lastndx}) {
    for (qw(id partnumber sku description sellprice listprice lastcost bin unit weight assembly taxaccounts pricematrix onhand itemnotes inventory_accno_id income_accno_id expense_accno_id)) {
      delete $form->{"new_${_}_$i"};
    }
  }
  
  for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

  &display_form;

}


sub new_item {

  if ($form->{language_code} && $form->{"description_$form->{rowcount}"}) {
    $form->error($locale->text('Translation not on file!'));
  }
  
  # change callback
  $form->{old_callback} = $form->escape($form->{callback},1);
  $form->{callback} = $form->escape("$form->{script}?action=display_form",1);

  # delete action
  delete $form->{action};

  # save all other form variables in a previousform variable
  if (!$form->{previousform}) {
    foreach $key (keys %$form) {
      # escape ampersands
      $form->{$key} =~ s/&/%26/g;
      $form->{previousform} .= qq|$key=$form->{$key}&|;
    }
    chop $form->{previousform};
    $form->{previousform} = $form->escape($form->{previousform}, 1);
  }

  $i = $form->{rowcount};
  for (qw(partnumber description)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }
  
  %button = ('Add Part' => { ndx => 1, key => 'P', value => $locale->text('Add Part') },
             'Add Service' => { ndx => 2, key => 'P', value => $locale->text('Add Service') }
	    );

  delete $button{'Add Part'} if $myconfig{acs} =~ /Goods \& Services--Add Part/;
  delete $button{'Add Service'} if $myconfig{acs} =~ /Goods \& Services--Add Service/;
  
  $form->header;

  print qq|
<body>

<h2 class=error>|.$locale->text('Error!').qq|</h2>
<h4 class=error>|.$locale->text('Item not on file!').qq|</h4>

<form method=post action=ic.pl>

<input type=hidden name=partnumber value="$form->{"partnumber_$i"}">
<input type=hidden name=description value="$form->{"description_$i"}">
|;

  $form->hide_form(qw(previousform rowcount path login));

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
  
  print qq|
</form>

</body>
</html>
|;

}



sub display_form {

  # if we have a display_form
  if ($form->{display_form}) {
    &{ "$form->{display_form}" };
    exit;
  }

  &form_header;

  $numrows = ++$form->{rowcount};
  $subroutine = "display_row";

  if ($form->{item} eq 'part') {
    # create makemodel rows
    &makemodel_row(++$form->{makemodel_rows});

    &vendor_row(++$form->{vendor_rows});
    
    $numrows = ++$form->{customer_rows};
    $subroutine = "customer_row";
  }
  if ($form->{item} eq 'assembly') {
    # create makemodel rows
    &makemodel_row(++$form->{makemodel_rows});
    
    $numrows = ++$form->{customer_rows};
    $subroutine = "customer_row";
  }
  if ($form->{item} eq 'service') {
    &vendor_row(++$form->{vendor_rows});
    
    $numrows = ++$form->{customer_rows};
    $subroutine = "customer_row";
  }
  if ($form->{item} eq 'labor') {
    $numrows = 0;
  }

  # create rows
  &{ $subroutine }($numrows) if $numrows;

  &form_footer;

}



sub check_form {

  my @a = ();
  my $count = 0;
  my $i;
  my $j;
  my @flds = qw(id runningnumber partnumber description partsgroup qty ship unit sellprice discount oldqty oldship orderitems_id bin weight listprice lastcost taxaccounts pricematrix sku onhand assembly inventory_accno_id income_accno_id expense_accno_id itemnotes reqdate deliverydate serialnumber ordernumber customerponumber projectnumber package netweight grossweight lineitemdetail);

  # remove any makes or model rows
  if ($form->{item} eq 'part') {
    for (qw(listprice sellprice lastcost avgcost weight rop markup)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
    
    &calc_markup;
    
    @flds = qw(make model);
    $count = 0;
    @a = ();
    for $i (1 .. $form->{makemodel_rows}) {
      if (($form->{"make_$i"} ne "") || ($form->{"model_$i"} ne "")) {
	push @a, {};
	$j = $#a;

	for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
      }
    }

    $form->redo_rows(\@flds, \@a, $count, $form->{makemodel_rows});
    $form->{makemodel_rows} = $count;

    &check_vendor;
    &check_customer;
    
  }
  
  if ($form->{item} eq 'service') {
    
    for (qw(sellprice listprice lastcost avgcost markup)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
    
    &calc_markup;
    &check_vendor;
    &check_customer;
    
  }
  
  if ($form->{item} eq 'assembly') {

    if (!$form->{project_id}) {
      $form->{sellprice} = 0;
      $form->{listprice} = 0;
      $form->{lastcost} = 0;
      $form->{weight} = 0;
    }
    
    for (qw(rop stock markup)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
   
    @flds = qw(id qty unit bom adj partnumber description sellprice listprice lastcost weight assembly runningnumber);
    $count = 0;
    @a = ();
    
    for $i (1 .. ($form->{assembly_rows} - 1)) {
      if ($form->{"qty_$i"}) {
	push @a, {};
	my $j = $#a;

        $form->{"qty_$i"} = $form->parse_amount(\%myconfig, $form->{"qty_$i"});

	for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }

        if (! $form->{project_id}) {
	  for (qw(sellprice listprice weight lastcost)) { $form->{$_} += ($form->{"${_}_$i"} * $form->{"qty_$i"}) }
	}
	
	$count++;
      }
    }

    if ($form->{markup} && $form->{markup} != $form->{oldmarkup}) {
      $form->{sellprice} = 0;
      &calc_markup;
    }
 
    for (qw(sellprice lastcost listprice)) { $form->{$_} = $form->round_amount($form->{$_}, $form->{precision}) }
    
    $form->redo_rows(\@flds, \@a, $count, $form->{assembly_rows});
    $form->{assembly_rows} = $count;
    
    $count = 0;
    @flds = qw(make model);
    @a = ();
    
    for $i (1 .. ($form->{makemodel_rows})) {
      if (($form->{"make_$i"} ne "") || ($form->{"model_$i"} ne "")) {
	push @a, {};
	my $j = $#a;

	for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
      }
    }

    $form->redo_rows(\@flds, \@a, $count, $form->{makemodel_rows});
    $form->{makemodel_rows} = $count;

    &check_customer;
  
  }
  
  if ($form->{type}) {

    # this section applies to invoices and orders
    # remove any empty numbers
    
    $focus = "partnumber_1";
    
    $count = 0;
    @a = ();
    if ($form->{rowcount}) {
      for $i (1 .. $form->{rowcount} - 1) {
	if ($form->{"partnumber_$i"}) {
	  push @a, {};
	  my $j = $#a;

	  for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
	  $count++;
	}
      }
      
      $form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
      $form->{rowcount} = $count;

      if ($form->{type} =~ /invoice/) {
	if ($form->{type} =~ /(debit|credit)_invoice/) {
	  $form->{creditremaining} -= ($form->{oldinvtotal} - $form->{oldtotalpaid});
	  $form->{creditremaining} += &invoicetotal;
	} else {
	  $form->{creditremaining} += ($form->{oldinvtotal} - $form->{oldtotalpaid});
	  $amount = &invoicetotal;
	  $form->{creditremaining} -= $amount;
	}
      } else {
	$form->{creditremaining} += ($form->{oldinvtotal} - $form->{oldtotalpaid});
	$form->{creditremaining} -= &invoicetotal;
      }

      $count++;
      $focus = "partnumber_$count";
      
    }
  }

  &display_form;

}


sub calc_markup {

  if ($form->{markup}) {
    if ($form->{markup} != $form->{oldmarkup}) {
      if ($form->{lastcost}) {
	$form->{sellprice} = $form->{lastcost} * (1 + $form->{markup}/100);
	$form->{sellprice} = $form->round_amount($form->{sellprice}, $form->{precision});
      } else {
	$form->{lastcost} = $form->{sellprice} / (1 + $form->{markup}/100);
	$form->{lastcost} = $form->round_amount($form->{lastcost}, $form->{precision});
      }
    }
  } else {
    if ($form->{lastcost}) {
      $form->{markup} = $form->round_amount(((1 - $form->{sellprice} / $form->{lastcost}) * 100), 1);
    }
    $form->{markup} = "" if $form->{markup} == 0;
  }

}


sub invoicetotal {
  
  $exchangerate = $form->parse_amount(\%myconfig, $form->{exchangerate});
  $exchangerate ||= 1;

  # add all parts and deduct paid
  for (split / /, $form->{taxaccounts}) { $form->{"${_}_base"} = 0 }

  my $amount;
  my $sellprice;
  my $discount;
  my $qty;

  $form->{oldinvtotal} = 0;

  for $i (1 .. $form->{rowcount}) {
    
    $qty = $form->parse_amount(\%myconfig, $form->{"qty_$i"});
    
    $spc = substr($myconfig{numberformat},-3,1);
    if ($spc eq '.') {
      ($null, $dec) = split /\./, $form->{"sellprice_$i"};
    } else {
      ($null, $dec) = split /,/, $form->{"sellprice_$i"};
    }
    $dec = length $dec;
    $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

    if ($qty != $form->{"oldqty_$i"}) {
      # check pricematrix
      @a = split / /, $form->{"pricematrix_$i"};
      if (scalar @a > 1) {
	foreach $item (@a) {
	  ($q, $p) = split /:/, $item;
	  if (($p * 1) && ($qty >= ($q * 1))) {
	    $form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $p / $exchangerate, $decimalplaces);
	  }
	}
      }
    }

    $sellprice = $form->round_amount($form->parse_amount(\%myconfig, $form->{"sellprice_$i"}) * (1 - $form->{"discount_$i"} / 100), $decimalplaces);
    $amount = $sellprice * $qty;
    for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $amount }
    $form->{oldinvtotal} += $amount;
  }

  $form->{oldinvtotal} = $form->round_amount($form->{oldinvtotal}, $form->{precision});

  if ($form->{taxincluded}) {
    $netamount = $form->{oldinvtotal};
    for (split / /, $form->{taxaccounts}) { $netamount -= ($form->{"${_}_base"} * $form->{"${_}_rate"}) }
    $form->{cd_available} = $form->round_amount($netamount * $form->{cashdiscount} / 100, $form->{precision});
  } else {
    $form->{cd_available} = $form->round_amount($form->{oldinvtotal} * $form->{cashdiscount} / 100, $form->{precision});
    for (split / /, $form->{taxaccounts}) { $form->{oldinvtotal} += $form->round_amount($form->{"${_}_base"} * $form->{"${_}_rate"}, $form->{precision}) }
  }
  
  $form->{oldtotalpaid} = 0;
  for $i (1 .. $form->{paidaccounts}) {
    $form->{oldtotalpaid} += $form->{"paid_$i"};
  }
  
  # return total
  return ($form->{oldinvtotal} - $form->{oldtotalpaid});

}


sub validate_items {
  
  # check if items are valid
  if ($form->{rowcount} == 1) {
    &update;
    exit;
  }
    
  for $i (1 .. $form->{rowcount} - 1) {
    $form->isblank("partnumber_$i", $locale->text('Number missing in Row') . " $i");
  }

}



sub purchase_order {

  if ($form->{type} eq 'request_quotation') {
    $form->{closed} = 1;
    OE->save(\%myconfig, \%$form);
  }

  $form->{title} = $locale->text('Add Purchase Order');
  $form->{vc} = 'vendor';
  $form->{type} = 'purchase_order';
  $form->{formname} = 'purchase_order';
  $buysell = 'sell';

  &create_form;

}

 
sub sales_order {
  
  if ($form->{type} eq 'sales_quotation') {
    $form->{closed} = 1;
    OE->save(\%myconfig, \%$form);
  }

  $form->{title} = $locale->text('Add Sales Order');
  $form->{vc} = 'customer';
  $form->{type} = 'sales_order';
  $form->{formname} = 'sales_order';
  $buysell = 'buy';

  &create_form;

}


sub rfq {
  
  if ($form->{type} eq 'purchase_order') {
    $form->{closed} = 1;
    OE->save(\%myconfig, \%$form);
  }
 
  $form->{title} = $locale->text('Add Request for Quotation');
  $form->{vc} = 'vendor';
  $form->{type} = 'request_quotation';
  $form->{formname} = 'request_quotation';
  $buysell = 'sell';
 
  &create_form;
  
}


sub quotation {
  
  if ($form->{type} eq 'sales_order') {
    $form->{closed} = 1;
    OE->save(\%myconfig, \%$form);
  }
 
  $form->{title} = $locale->text('Add Quotation');
  $form->{vc} = 'customer';
  $form->{type} = 'sales_quotation';
  $form->{formname} = '';
  $buysell = 'buy';

  &create_form;

}


sub create_form {

  for (qw(id subject message cc bcc printed emailed queued audittrail recurring)) { delete $form->{$_} }
 
  $form->{script} = 'oe.pl';

  $form->{shipto} = 1;

  $form->{rowcount}-- if $form->{rowcount};
  $form->{rowcount} = 0 if ! $form->{"$form->{vc}_id"};

  do "$form->{path}/$form->{script}";

  for ("$form->{vc}", "currency") { $form->{"select$_"} = "" }
  
  for (qw(currency employee department intnotes notes language_code taxincluded)) { $temp{$_} = $form->{$_} }

  &order_links;

  $form->{reqdate} = $form->add_date(\%myconfig, $form->{transdate}, $form->{terms}, 'days');
  
  for (keys %temp) { $form->{$_} = $temp{$_} if $temp{$_} }

  $form->{exchangerate} = "";
  $form->{forex} = "";
  $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, $buysell)));


  for $i (1 .. $form->{rowcount}) {
    for (qw(netweight grossweight volume discount)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }

    ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

    for (qw(sellprice listprice)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces) }

    ($dec) = ($form->{"lastcost_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

    $form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"}, $decimalplaces);

    for (qw(qty ship)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}) }
    $form->{"oldqty_$i"} = $form->{"qty_$i"};
  }

  &prepare_order;

  &display_form;

}



sub e_mail {

  $bcc = qq|<input type=hidden name=bcc value="$form->{bcc}">|;
  if ($myconfig{role} =~ /(admin|manager)/) {
    $bcc = qq|
 	  <th align=right nowrap=true>|.$locale->text('Bcc').qq|</th>
	  <td><input name=bcc size=30 value="$form->{bcc}"></td>
|;
  }

  if ($form->{formname} =~ /(pick|packing|bin)_list/) {
    $form->{email} = $form->{shiptoemail} if $form->{shiptoemail};
  }

  $name = $form->{$form->{vc}};
  $name =~ s/--.*//g;
  $title = $locale->text('E-mail')." $name";
 
 
  ($form->{warehouse}, $form->{warehouse_id}) = split /--/, $form->{warehouse};
  
  AA->company_details(\%myconfig, \%$form);

  $form->{warehouse} = "$form->{warehouse}--$form->{warehouse_id}" if $form->{warehouse_id};

  $form->header;

  print qq|
<body>

<form method=post action="$form->{script}">

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$title</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th align=right nowrap>|.$locale->text('E-mail').qq| <font color=red>*</font></th>
	  <td><input name=email size=30 value="$form->{email}"></td>
	  <th align=right nowrap>|.$locale->text('Cc').qq|</th>
	  <td><input name=cc size=30 value="$form->{cc}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Subject').qq|</th>
	  <td><input name=subject size=30 value="|.$form->quote($form->{subject}).qq|"></td>
	  $bcc
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th align=left nowrap>|.$locale->text('Message').qq|</th>
	</tr>
	<tr>
	  <td><textarea name=message rows=15 cols=60 wrap=soft>$form->{message}</textarea></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
|;

  $form->{oldmedia} = $form->{media};
  $form->{media} = "email";
  $form->{format} = "pdf";
  
  &print_options;
  
  for (qw(email cc bcc subject message formname sendmode format language_code action nextsub)) { delete $form->{$_} }
  
  $form->hide_form;

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=send_email>

<br>
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub send_email {

  $old_form = new Form;
  
  for (keys %$form) { $old_form->{$_} = $form->{$_} }
  $old_form->{media} = $old_form->{oldmedia};

  $form->{from} = qq|$form->{username} <$form->{useremail}>|;

  &print_form($old_form);
  
}
  

 
sub print_options {

  $form->{sendmode} = "attachment";
  
  $form->{SM}{$form->{sendmode}} = "selected";
  
  if ($form->{selectlanguage}) {
    $lang = qq|<select name="language_code">|.$form->select_option($form->{selectlanguage}, $form->{language_code}, undef, 1).qq|</select>|;
    $form->hide_form(qw(oldlanguage_code selectlanguage));
  }

  $type = qq|<select name="formname">|.$form->select_option($form->{selectformname}, $form->{formname}, undef, 1).qq|</select>|;
  $form->hide_form(qw(selectformname));
  
  if ($form->{media} eq 'email') {
    $media = qq|<select name="sendmode">
	    <option value="attachment" $form->{SM}{attachment}>|.$locale->text('Attachment').qq|
	    <option value="inline" $form->{SM}{inline}>|.$locale->text('In-line').qq|</select>|;

  } else {
    $media = qq|<select name=media>
	    <option value="screen">|.$locale->text('Screen');
 
    if (%printer && $latex) {
      for (sort keys %printer) { $media .= qq|
            <option value="$_">$_| }
    }
    if ($latex) {
      $media .= qq|
            <option value="queue">|.$locale->text('Queue');
    }
    $media .= qq|</select>|;

    # set option selected
    $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;
 
  }

  $selectformat = qq|<option value="html">html|;
#	    <option value="txt">|.$locale->text('Text');

  if ($latex) {
    $selectformat .= qq|
<option value="postscript">|.$locale->text('Postscript').qq|
<option value="pdf">|.$locale->text('PDF');
  }

  $format = qq|<select name=format>$selectformat</select>|;
  $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;
  
  print qq|
<table>
  <tr>
    <td>$type</td>
    <td>$lang</td>
    <td>$format</td>
    <td>$media</td>
|;

  if (%printer && $latex && $form->{media} ne 'email') {
    print qq|
    <td nowrap>|.$locale->text('Copies').qq|
    <input name=copies size=2 value=$form->{copies}></td>
|;
  }


# $locale->text('Printed')
# $locale->text('E-mailed')
# $locale->text('Queued')
# $locale->text('Scheduled')

  %status = ( printed => 'Printed',
              emailed => 'E-mailed',
	      queued  => 'Queued',
	      recurring => 'Scheduled' );
  
  print qq|<td align=right width=90%>|;

  for (qw(printed emailed queued recurring)) {
    if ($form->{$_} =~ /$form->{formname}/) {
      print $locale->text($status{$_}).qq|<br>|;
    }
  }

  print qq|
    </td>
  </tr>
</table>
|;

  $form->{groupprojectnumber} = "checked" if $form->{groupprojectnumber};
  $form->{grouppartsgroup} = "checked" if $form->{grouppartsgroup};
  
  for (qw(runningnumber partnumber description bin)) { $sortby{$_} = "checked" if $form->{sortby} eq $_ }

  if ($form->{media} eq 'email') {
    $form->hide_form(qw(groupprojectnumber grouppartsgroup sortby));
  } else {
    print qq|
    <tr>
      <td>
	<table>
	  <tr>
	    <th>|.$locale->text('Group by').qq| -></th>
	    <td><input name=groupprojectnumber type=checkbox class=checkbox $form->{groupprojectnumber}></td>
	    <td>|.$locale->text('Project').qq|</td>
	    <td><input name=grouppartsgroup type=checkbox class=checkbox $form->{grouppartsgroup}></td>
	    <td>|.$locale->text('Group').qq|</td>

	    <td width=20></td>
	    
	    <th><b>|.$locale->text('Sort by').qq| -></th>
	    <td><input name=sortby type=radio class=radio value=runningnumber $sortby{runningnumber}></td>
	    <td>|.$locale->text('Item').qq|</td>
	    <td><input name=sortby type=radio class=radio value=partnumber $sortby{partnumber}></td>
	    <td>|.$locale->text('Number').qq|</td>
	    <td><input name=sortby type=radio class=radio value=description $sortby{description}></td>
	    <td>|.$locale->text('Description').qq|</td>
	    <td><input name=sortby type=radio class=radio value=bin $sortby{bin}></td>
	    <td>|.$locale->text('Bin').qq|</td>
	  </tr>
	</table>
      </td>
    </tr>
|;
  }

}



sub print {

  # if this goes to the printer pass through
  if ($form->{media} !~ /(screen|email)/) {
    $form->error($locale->text('Select txt, postscript or PDF!')) if ($form->{format} !~ /(txt|postscript|pdf)/);

    $old_form = new Form;
    for (keys %$form) { $old_form->{$_} = $form->{$_} }
    
  }
   
  &print_form($old_form);

}


sub print_form {
  my ($old_form) = @_;

  $inv = "inv";
  $due = "due";

  $numberfld = "sinumber";

  $display_form = ($form->{display_form}) ? $form->{display_form} : "display_form";

  if (! ($form->{copies} = abs($form->{copies}))) {
    $form->{copies} = 1;
  }

  if ($form->{formname} eq 'invoice') {
    $form->{label} = $locale->text('Invoice');
  }
  if ($form->{formname} eq 'vendor_invoice') {
    $form->{label} = $locale->text('Invoice');
    $numberfld = "vinumber";
  }
  if ($form->{formname} eq 'debit_invoice') {
    $form->{label} = $locale->text('Debit Invoice');
  }
  if ($form->{formname} eq 'credit_invoice') {
    $form->{label} = $locale->text('Credit Invoice');
  }

  if ($form->{formname} eq 'sales_order') {
    $inv = "ord";
    $due = "req";
    $form->{label} = $locale->text('Sales Order');
    $numberfld = "sonumber";
    $order = 1;
  }
  if ($form->{formname} eq 'work_order') {
    $inv = "ord";
    $due = "req";
    $form->{label} = $locale->text('Work Order');
    $numberfld = "sonumber";
    $order = 1;
  }
  if ($form->{formname} eq 'packing_list') {
    # we use the same packing list as from an invoice
    $form->{label} = $locale->text('Packing List');

    if ($form->{type} =~ /invoice/) {
      $numberfld = "vinumber" if $form->{vc} eq 'vendor';
    } else {
      $inv = "ord";
      $due = "req";
      $numberfld = "sonumber";
      $order = 1;
    }
  }
  if ($form->{formname} eq 'pick_list') {
    $form->{label} = $locale->text('Pick List');
    if ($form->{type} =~ /invoice/) {
      $numberfld = "vinumber" if $form->{vc} eq 'vendor';
    } else {
      $inv = "ord";
      $due = "req";
      $order = 1;
      $numberfld = "sonumber";
    }
  }
  if ($form->{formname} eq 'purchase_order') {
    $inv = "ord";
    $due = "req";
    $form->{label} = $locale->text('Purchase Order');
    $numberfld = "ponumber";
    $order = 1;
  }
  if ($form->{formname} eq 'bin_list') {
    $form->{label} = $locale->text('Bin List');
    if ($form->{type} =~ /invoice/) {
      $numberfld = "vinumber" if $form->{vc} eq 'vendor';
    } else {
      $inv = "ord";
      $due = "req";
      $numberfld = "ponumber";
      $order = 1;
    }
  }
  if ($form->{formname} eq 'sales_quotation') {
    $inv = "quo";
    $due = "req";
    $form->{label} = $locale->text('Quotation');
    $numberfld = "sqnumber";
    $order = 1;
  }
  if ($form->{formname} eq 'request_quotation') {
    $inv = "quo";
    $due = "req";
    $form->{label} = $locale->text('Quotation');
    $numberfld = "rfqnumber";
    $order = 1;
  }

  &validate_items;
 
  $form->{"${inv}date"} = $form->{transdate};

  $form->isblank("email", "$form->{$form->{vc}} : ".$locale->text('E-mail address missing!')) if ($form->{media} eq 'email');
  $form->isblank("${inv}date", $locale->text($form->{label} .' Date missing!'));

  # get next number
  if (! $form->{"${inv}number"}) {
    $form->{"${inv}number"} = $form->update_defaults(\%myconfig, $numberfld);
    if ($form->{media} eq 'screen') {
      &update;
      exit;
    }
  }


# $locale->text('Invoice Number missing!')
# $locale->text('Invoice Date missing!')
# $locale->text('Packing List Number missing!')
# $locale->text('Packing List Date missing!')
# $locale->text('Order Number missing!')
# $locale->text('Order Date missing!')
# $locale->text('Quotation Number missing!')
# $locale->text('Quotation Date missing!')

  AA->company_details(\%myconfig, \%$form);

  @a = ();
  foreach $i (1 .. $form->{rowcount}) {
    push @a, map { "${_}_$i" } qw(partnumber description projectnumber partsgroup serialnumber ordernumber customerponumber bin unit itemnotes package);
  }
  for (split / /, $form->{taxaccounts}) { push @a, "${_}_description" }

  $ARAP = ($form->{vc} eq 'customer') ? "AR" : "AP";
  push @a, $ARAP;
  
  # format payment dates
  for $i (1 .. $form->{paidaccounts} - 1) {
    if (exists $form->{longformat}) {
      $form->{"datepaid_$i"} = $locale->date(\%myconfig, $form->{"datepaid_$i"}, $form->{longformat});
    }
    
    push @a, "${ARAP}_paid_$i", "source_$i", "memo_$i";
  }
  $form->format_string(@a);

  for (qw(employee warehouse paymentmethod)) { ($form->{$_}, $form->{"${_}_id"}) = split /--/, $form->{$_} };
 
  # this is a label for the subtotals
  $form->{groupsubtotaldescription} = $locale->text('Subtotal') if not exists $form->{groupsubtotaldescription};
  delete $form->{groupsubtotaldescription} if $form->{deletegroupsubtotal};

  $duedate = $form->{"${due}date"};

  # create the form variables
  if ($order) {
    OE->order_details(\%myconfig, \%$form);
  } else {
    if ($form->{vc} eq 'customer') {
      IS->invoice_details(\%myconfig, \%$form);
    } else {
      IR->invoice_details(\%myconfig, \%$form);
    }
  }

  if ($form->{formname} eq 'remittance_voucher') {
    $form->isblank("dcn", qq|$form->{"${ARAP}_paid_$form->{paidaccounts}"} : |.$locale->text('DCN missing!'));
    $form->isblank("rvc", qq|$form->{"${ARAP}_paid_$form->{paidaccounts}"} : |.$locale->text('RVC missing!'));
  }

  $form->fdld(\%myconfig, \%$locale);
  
  if (exists $form->{longformat}) {
    for ("${inv}date", "${due}date", "shippingdate", "transdate") { $form->{$_} = $locale->date(\%myconfig, $form->{$_}, $form->{longformat}) }
  }

  @a = qw(email name address1 address2 city state zipcode country contact phone fax);

  $fillshipto = 1;
  # check for shipto
  foreach $item (@a) {
    if ($form->{"shipto$item"}) {
      $fillshipto = 0;
      last;
    }
  }

  if ($fillshipto) {
    $fillshipto = 0;
    $fillshipto = 1 if $form->{formname} =~ /(credit_invoice|purchase_order|request_quotation|bin_list)/;
    $fillshipto = 1 if ($form->{type} eq 'invoice' && $form->{vc} eq 'vendor');

    $form->{shiptophone} = $form->{tel};
    $form->{shiptofax} = $form->{fax};
    $form->{shiptocontact} = $form->{employee};
   
    if ($fillshipto) {
      if ($form->{warehouse}) {
	$form->{shiptoname} = $form->{company};
	for (qw(address1 address2 city state zipcode country)) {
	  $form->{"shipto$_"} = $form->{"warehouse$_"};
	}
      } else {
	# fill in company address
	$form->{shiptoname} = $form->{company};
	$form->{shiptoaddress1} = $form->{address};
      }
    } else {
      for (@a) { $form->{"shipto$_"} = $form->{$_} }
      for (qw(phone fax)) { $form->{"shipto$_"} = $form->{"$form->{vc}$_"} }
    }
  }

  # remove email
  shift @a;
 
  # some of the stuff could have umlauts so we translate them
  push @a, qw(contact shippingpoint shipvia notes intnotes employee warehouse paymentmethod);
  push @a, map { "shipto$_" } qw(name address1 address2 city state zipcode country contact email phone fax);
  push @a, qw(firstname lastname salutation contacttitle occupation mobile);

  push @a, ("${inv}number", "${inv}date", "${due}date", "${inv}description");
  
  for (qw(name email)) { $form->{"user$_"} = $myconfig{$_} }

  push @a, qw(companyemail companywebsite company address tel fax businessnumber username useremail dcn rvc);

  for (qw(notes intnotes)) { $form->{$_} =~ s/^\s+//g }

  # before we format replace <%var%>
  for ("${inv}description", "notes", "intnotes", "message") { $form->{$_} =~ s/<%(.*?)%>/$fld = lc $1; $form->{$fld}/ge }

  $form->format_string(@a);

  $form->{templates} = "$myconfig{templates}";
  $form->{IN} = "$form->{formname}.$form->{format}";

  if ($form->{format} =~ /(postscript|pdf)/) {
    $form->{IN} =~ s/$&$/tex/;
  }


  $form->{pre} = "<body bgcolor=#ffffff>\n<pre>" if $form->{format} eq 'txt';

  if ($form->{media} !~ /(screen|queue|email)/) {
    $form->{OUT} = "| $printer{$form->{media}}";
    
    $form->{OUT} =~ s/<%(fax)%>/<%$form->{vc}$1%>/;
    $form->{OUT} =~ s/<%(.*?)%>/$form->{$1}/g;

    if ($form->{printed} !~ /$form->{formname}/) {
    
      $form->{printed} .= " $form->{formname}";
      $form->{printed} =~ s/^ //;

      $form->update_status(\%myconfig);
    }

    %audittrail = ( tablename	=> ($order) ? 'oe' : lc $ARAP,
                    reference	=> $form->{"${inv}number"},
		    formname	=> $form->{formname},
		    action	=> 'printed',
		    id		=> $form->{id} );

    if ($old_form) {
      $old_form->{printed} = $form->{printed};
      $old_form->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
    }
    
  }

  if ($form->{media} eq 'email') {
    $mergerv = 1;
    
    $form->{subject} = qq|$form->{label} $form->{"${inv}number"}| unless $form->{subject};

    $form->{plainpaper} = 1;
    $form->{OUT} = "$sendmail";

    if ($form->{emailed} !~ /$form->{formname}/) {
      $form->{emailed} .= " $form->{formname}";
      $form->{emailed} =~ s/^ //;

      # save status
      $form->update_status(\%myconfig);
    }

    $now = scalar localtime;
    $cc = $locale->text('Cc').qq|: $form->{cc}\n| if $form->{cc};
    $bcc = $locale->text('Bcc').qq|: $form->{bcc}\n| if $form->{bcc};
    
    %audittrail = ( tablename	=> ($order) ? 'oe' : lc $ARAP,
                    reference	=> $form->{"${inv}number"},
		    formname	=> $form->{formname},
		    action	=> 'emailed',
		    id		=> $form->{id} );
   
    if ($old_form) {
      $old_form->{intnotes} = qq|$old_form->{intnotes}\n\n| if $old_form->{intnotes};
      $old_form->{intnotes} .= qq|[email]\n|
      .$locale->text('Date').qq|: $now\n|
      .$locale->text('To').qq|: $form->{email}\n${cc}${bcc}|
      .$locale->text('Subject').qq|: $form->{subject}\n|;

      $old_form->{intnotes} .= qq|\n|.$locale->text('Message').qq|: |;
      $old_form->{intnotes} .= ($form->{message}) ? $form->{message} : $locale->text('sent');

      $old_form->{message} = $form->{message};
      $old_form->{emailed} = $form->{emailed};

      $old_form->{format} = "postscript" if $myconfig{printer};
      $old_form->{media} = $myconfig{printer};

      $old_form->save_intnotes(\%myconfig, ($order) ? 'oe' : lc $ARAP);
    
      $old_form->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
    }
    
  }


  if ($form->{media} eq 'queue') {
    
    %queued = split / /, $form->{queued};

    if ($filename = $queued{$form->{formname}}) {
      $form->{queued} =~ s/$form->{formname} $filename//;
      unlink "$spool/$filename";
      $filename =~ s/\..*$//g;
    } else {
      $filename = time;
      $filename .= int rand 10000;
    }

    $filename .= ($form->{format} eq 'postscript') ? '.ps' : '.pdf';
    $form->{OUT} = ">$spool/$filename";

    $form->{queued} .= " $form->{formname} $filename";
    $form->{queued} =~ s/^ //;

    # save status
    $form->update_status(\%myconfig);
    
    %audittrail = ( tablename   => ($order) ? 'oe' : lc $ARAP,
		    reference   => $form->{"${inv}number"},
		    formname    => $form->{formname},
		    action      => 'queued',
		    id          => $form->{id} );

    if ($old_form) {
      $old_form->{queued} = $form->{queued};
      $old_form->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
    }

  }

  $form->{fileid} = $form->{"${inv}number"};
  $form->{fileid} =~ s/(\s|\W)+//g;

  $form->format_string(qw(email cc bcc));
  

  $form->parse_template(\%myconfig, $userspath) if $form->{copies};


  # if we got back here restore the previous form
  if ($old_form) {

    $old_form->{"${inv}number"} = $form->{"${inv}number"};
    $old_form->{dcn} = $form->{dcn};

    for (1 .. $old_form->{paidaccounts}) {
      delete $old_form->{"paid_$_"};
    }
    
    # restore and display form
    for (keys %$old_form) { $form->{$_} = $old_form->{$_} }
    delete $form->{pre};
    
    for (1 .. $form->{paidaccounts}) {
      $form->{"paid_$_"} = $form->parse_amount(\%myconfig, $form->{"paid_$_"});
    }
 
    $form->{rowcount}--;

    &{ "$display_form" };

  }

}


sub ship_to {

  $title = $form->{title};
  $form->{title} = $locale->text('Shipping Address');

  for (qw(exchangerate creditlimit creditremaining)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
  for (1 .. $form->{paidaccounts}) { $form->{"paid_$_"} = $form->parse_amount(\%myconfig, $form->{"paid_$_"}) }
  for (qw(dcn rvc)) { $temp{$_} = $form->{$_} }

  # get details for name
  AA->ship_to(\%myconfig, \%$form);

  for (keys %temp) { $form->{$_} = $temp{$_} }
  
  $vcname = $locale->text('Name');

  $form->{rowcount}--;

  %shipto = (
          address1 => { i => 2, label => $locale->text('Address') },
	  address2 => { i => 3, label => '' },
	      city => { i => 4, label => $locale->text('City') },
	     state => { i => 5, label => $locale->text('State/Province') },
	   zipcode => { i => 6, label => $locale->text('Zip/Postal Code') },
	   country => { i => 7, label => $locale->text('Country') },
	   contact => { i => 8, label => $locale->text('Contact') },
	     phone => { i => 9, label => $locale->text('Phone') },
	       fax => { i => 10, label => $locale->text('Fax') },
	     email => { i => 11, label => $locale->text('E-mail') } );
  
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
	  <th class=listheading colspan=3>$form->{name}</a></th>
	</tr>
	<tr>
	  <td></td>
	  <th align=right nowrap>$vcname</th>
	  <td><input name=shiptoname size=35 maxlength=64 value="|.$form->quote($form->{shiptoname}).qq|"></td>
	</tr>
	<tr>
	  <td></td>
	  <th align=right nowrap>$shipto{address1}{label}</th>
	  <td><input name=shiptoaddress1 size=35 maxlength=32 value="|.$form->quote($form->{shiptoaddress1}).qq|"></td>
	</tr>
	<tr>
	  <td></td>
	  <td></td>
	  <td><input name=shiptoaddress2 size=35 maxlength=32 value="|.$form->quote($form->{shiptoaddress2}).qq|"></td>
	</tr>
	<tr>
	  <td></td>
	  <th align=right nowrap>$shipto{city}{label}</th>
	  <td><input name=shiptocity size=35 maxlength=32 value="|.$form->quote($form->{shiptocity}).qq|"></td>
	</tr>
	<tr>
	  <td></td>
	  <th align=right nowrap>$shipto{state}{label}</th>
	  <td><input name=shiptostate size=35 maxlength=32 value="|.$form->quote($form->{shiptostate}).qq|"></td>
	</tr>
	<tr>
	  <td></td>
	  <th align=right nowrap>$shipto{zipcode}{label}</th>
	  <td><input name=shiptozipcode size=10 maxlength=10 value="|.$form->quote($form->{shiptozipcode}).qq|"></td>
	</tr>
	<tr>
	  <td></td>
	  <th align=right nowrap>$shipto{country}{label}</th>
	  <td><input name=shiptocountry size=35 maxlength=32 value="|.$form->quote($form->{shiptocountry}).qq|"></td>
	</tr>
	<tr>
	  <td></td>
	  <th align=right nowrap>$shipto{contact}{label}</th>
	  <td><input name=shiptocontact size=35 maxlength=64 value="|.$form->quote($form->{shiptocontact}).qq|"></td>
	</tr>
	<tr>
	  <td></td>
	  <th align=right nowrap>$shipto{phone}{label}</th>
	  <td><input name=shiptophone size=20 value="$form->{shiptophone}"></td>
	</tr>
	<tr>
	  <td></td>
	  <th align=right nowrap>$shipto{fax}{label}</th>
	  <td><input name=shiptofax size=20 value="$form->{shiptofax}"></td>
	</tr>
	<tr>
	  <td></td>
	  <th align=right nowrap>$shipto{email}{label}</th>
	  <td><input name=shiptoemail size=35 value="$form->{shiptoemail}"></td>
	</tr>
|;

  $i = 1;
  for $ref (@{ $form->{all_shipto} }) {

    print qq|
        <tr>
	  <td></td>
	  <td><hr noshade></td>
	  <td><hr noshade></td>
        </tr>

	<tr>
	  <td><input name="ndx_$i" type=checkbox class=checkbox>
	  <th align=right nowrap>$vcname</th>
	  <td>$ref->{shiptoname}</td>
        </tr>
|;

    for (sort { $shipto{$a}{i} <=> $shipto{$b}{i} } keys %shipto) {
      print qq|
	<tr>
	  <td></td>
	  <th align=right nowrap>$shipto{$_}{label}</th>
	  <td>$ref->{"shipto$_"}</td>
        </tr>
|;
    }

    for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }
    $form->hide_form(map { "${_}_$i" } keys %$ref);

    $i++;
  }
  $form->{shipto_rows} = $i - 1;

  print qq|
      </table>
    </td>
  </tr>
</table>
|;

  # delete shipto
  for (qw(action all_shipto)) { delete $form->{$_} }
  for (qw(name address1 address2 city state zipcode country contact phone fax email)) {
    delete $form->{"shipto$_"};
    $form->{flds} .= "$_ ";
  }
  chop $form->{flds};
  
  $form->{title} = $title;

  $form->{nextsub} = "shipto_selected";
  
  
  $form->hide_form;

  print qq|

<hr size=3 noshade>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub shipto_selected {

  $display_form = $form->{display_form} || "display_form";

  for $i (1 .. $form->{shipto_rows}) {
    if ($form->{"ndx_$i"}) {
      for (split / /, $form->{flds}) { $form->{"shipto$_"} = $form->{"shipto${_}_$i"} }
      last;
    }
  }

  &{ "$display_form" };

}

