#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# common routines used in is, ir, oe, ic
#
#======================================================================

# any custom scripts for this one
if (-f "$form->{path}/custom/io.pl") {
  eval { require "$form->{path}/custom/io.pl"; };
}
if (-f "$form->{path}/custom/$form->{login}/io.pl") {
  eval { require "$form->{path}/custom/$form->{login}/io.pl"; };
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

  @column_index = qw(runningnumber partnumber description lineitemdetail qty onhand);

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
  $column_data{description} = qq|<th class=listheading nowrap>|.$locale->text('Description').qq|</th>|;
  $column_data{qty} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading nowrap>|.$locale->text('Unit').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading nowrap>|.$locale->text('Price').qq|</th>|;
  $column_data{discount} = qq|<th class=listheading>%</th>|;
  $column_data{linetotal} = qq|<th class=listheading nowrap>|.$locale->text('Extended').qq|</th>|;
  $column_data{bin} = qq|<th class=listheading nowrap>|.$locale->text('Bin').qq|</th>|;
  $column_data{onhand} = qq|<th class=listheading nowrap>|.$locale->text('OH').qq|</th>|;

  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $column_data{lineitemdetail} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); JavaScript:document.main.submit()"></th>|;

  $form->hide_form(qw(weightunit));

  &check_all(qw(allbox lineitemdetail_));
  
  print qq|
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
  $costlabel = $locale->text('Cost');
  $costvendorlabel = $locale->text('Vendor');
  $marginlabel = $locale->text('Margin');
  $group = $locale->text('Group');
  $groupcode = $locale->text('Code');
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
  $exchangerate *= 1;

  $spc = substr($myconfig{numberformat},-3,1);
  for $i (1 .. $numrows) {
    if ($spc eq '.') {
      (undef, $dec) = split /\./, $form->{"sellprice_$i"};
    } else {
      (undef, $dec) = split /,/, $form->{"sellprice_$i"};
    }
    $dec = length $dec;
    $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

    # undo formatting
    for (qw(qty ship discount sellprice netweight grossweight volume cost)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    
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
      @f = split / /, $form->{"pricematrix_$i"};
      if (scalar @f > 1) {
	foreach $item (@f) {
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
    
    if (($rows = $form->numtextrows($form->{"description_$i"}, 46, 6)) < 2) {
      $rows = 1;
    }
    
    if ($i == $numrows) {
      $column_data{description} = qq|<td><input name="description_$i" size=46></td>|;
    } else {
      $form->{"description_$i"} = $form->quote($form->{"description_$i"});
      $column_data{description} = qq|<td><textarea name="description_$i" rows=$rows cols=46 wrap=soft>$form->{"description_$i"}</textarea></td>|;
    }

    $skunumber = qq|
                <br><b>$sku</b> $form->{"sku_$i"}| if ($form->{vc} eq 'vendor' && $form->{"sku_$i"});

    
    if ($form->{selectpartsgroup}) {
      if ($i < $numrows) {
	$partsgroup = qq|
	        <tr>
		  <td colspan=$colspan>
		  <b>$group</b>|.$form->hide_form("partsgroup_$i", "partsgroupcode_$i");
	($form->{"partsgroup_$i"}) = split /--/, $form->{"partsgroup_$i"};
	$partsgroup .= qq|$form->{"partsgroup_$i"} <b>$groupcode</b> $form->{"partsgroupcode_$i"}</td>
		</tr>|;
	$partsgroup = "" unless $form->{"partsgroup_$i"};
      }
    }
    
    $delivery = qq|
          <td colspan=2 nowrap>
	  <b>${$delvar}</b>
	  <input name="${delvar}_$i" size=11 class=date title="$myconfig{dateformat}" value="$form->{"${delvar}_$i"}">|.&js_calendar("main", "${delvar}_$i").qq|</td>
|;

    if ($i < $numrows) {
      $zero = "0";
      $itemhref = qq| <a href="ic.pl?login=$form->{login}&path=$form->{path}&action=edit&id=$form->{"id_$i"}" target=_blank>?</a>|;
      $itemhistory = qq| <a href="ic.pl?action=history&history=sales&login=$form->{login}&path=$form->{path}&pickvar=sellprice_$i&id=$form->{"id_$i"}" target=popup>?</a>|;

      %p = split /[: ]/, $form->{"pricematrix_$i"};
      for (split / /, $form->{"kit_$i"}) {
        @p = split /:/, $_;
        for $n (3 .. $#p) {
          if ($p[2]) {
            if ($p{0}) {
              $d = $form->round_amount($p[2] * $form->{"discount_$i"}/100, $decimalplaces);
              $form->{"$p[$n]_base"} += $form->round_amount(($p[2] - $d) * $p[1] * $form->{"sellprice_$i"}/$p{0} * $form->{"qty_$i"}, $form->{precision});
            }
          }
        }
      }
 
    } else {
      $itemhref = "";
      $itemhistory = "";
      $zero = "";
    }

    $column_data{runningnumber} = qq|<td><input name="runningnumber_$i" class="inputright" size="3" value="$i"></td>|;
    $column_data{partnumber} = qq|<td nowrap><input name="partnumber_$i" size="15" value="|.$form->quote($form->{"partnumber_$i"}).qq|" accesskey="$i" title="[$i]">$skunumber$itemhref</td>|;
    $column_data{qty} = qq|<td><input name="qty_$i" class="inputright" title="$form->{"onhand_$i"}" size="5" value="|.$form->format_amount(\%myconfig, $form->{"qty_$i"}).qq|"></td>|;
    $column_data{ship} = qq|<td><input name="ship_$i" class="inputright" size="5" value="|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|"></td>|;
    $column_data{unit} = qq|<td><input name="unit_$i" size="5" maxlength="5" value="|.$form->quote($form->{"unit_$i"}).qq|"></td>|;
    $column_data{sellprice} = qq|<td nowrap><input name="sellprice_$i" class="inputright" size="11" value="|.$form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces, $zero).qq|">$itemhistory</td>|;
    $column_data{discount} = qq|<td><input name="discount_$i" class="inputright" size="3" value="|.$form->format_amount(\%myconfig, $form->{"discount_$i"}).qq|"></td>|;
    $column_data{linetotal} = qq|<td align=right>|.$form->format_amount(\%myconfig, $linetotal, $form->{precision}, $zero).qq|</td>|;
    $column_data{bin} = qq|<td>$form->{"bin_$i"}</td>|;
    $column_data{onhand} = qq|<td align="right">$form->{"onhand_$i"}</td>|;

    $form->{"lineitemdetail_$i"} = ($form->{allbox}) ? 1 : $form->{"lineitemdetail_$i"};
    $form->{"lineitemdetail_$i"} = ($form->{"lineitemdetail_$i"}) ? "checked" : "";
    $column_data{lineitemdetail} = qq|<td><input name="lineitemdetail_$i" type="checkbox" class="checkbox" $form->{"lineitemdetail_$i"}></td>|;
    
    
    print qq|
        <tr valign=top>|;

    for (@column_index) {
      print "\n$column_data{$_}";
    }
  
    print qq|
        </tr>
|;

    $form->{"oldqty_$i"} = $form->{"qty_$i"};

    $form->hide_form(map { "${_}_$i" } qw(oldqty oldship orderitems_id id weight sell listprice lastcost taxaccounts pricematrix sku onhand bin assembly inventory_accno_id income_accno_id expense_accno_id kit));
  
    $project = qq|
                <b>$projectnumber</b>
		<select name="projectnumber_$i">|
		.$form->select_option($form->{selectprojectnumber}, $form->{"projectnumber_$i"}, 1)
		.qq|</select>
| if $form->{selectprojectnumber};

    if ($form->{type} !~ /_quotation/) {
      $orderxref = qq|
                <b>$orderxrefnumber</b>
		<input name="ordernumber_$i" value="$form->{"ordernumber_$i"}">&nbsp;<a href=oe.pl?action=lookup_order&ordnumber=|.$form->escape($form->{"ordernumber_$i"},1).qq|&vc=customer&type=sales_order&pickvar=ordernumber_$i&path=$form->{path}&login=$form->{login} target=popup>?</a>
                <b>$poxrefnumber</b>
		<input name="customerponumber_$i" value="$form->{"customerponumber_$i"}">&nbsp;<a href=oe.pl?action=lookup_order&ordnumber=|.$form->escape($form->{"customerponumber_$i"},1).qq|&vc=vendor&type=purchase_order&pickvar=customerponumber_$i&path=$form->{path}&login=$form->{login} target=popup>?</a>
|;
    }

    $costprice = "";

    if ($form->{vc} eq 'customer') {
      if ($form->{type} =~ /(invoice|_order|quotation)/ && $form->{type} !~ /credit/) {
        if ($linetotal) {
          $margin = $form->format_amount(\%myconfig, (($linetotal - ($form->{"cost_$i"} * $form->{"qty_$i"}))) / $linetotal * 100, 1);
        }

        $name = $form->escape($form->{"costvendor_$i"},1);
        $costprice = qq|
        <tr>
          <td colspan=$colspan>
          <input name="costvendorid_$i" type="hidden" value="$form->{"costvendorid_$i"}">
          <b>$costvendorlabel</b>
          <input name="costvendor_$i" value="$form->{"costvendor_$i"}">
          <a href="ct.pl?action=lookup_name&db=vendor&login=$form->{login}&path=$form->{path}&pickvar=costvendor_$i&pickid=costvendorid_$i&name=$name" target=popup> ?</a>
          <b>$costlabel</b>
          <input name="cost_$i" class=inputright size=10 value="|.$form->format_amount(\%myconfig, $form->{"cost_$i"}, $form->{precision}).qq|">&nbsp;<a href="ic.pl?action=history&history=purchases&login=$form->{login}&path=$form->{path}&pickvar=cost_$i&id=$form->{"id_$i"}" target=popup> ?</a>
|;
        $costprice .= qq|
                <b>$marginlabel</b>
                $margin
| if ($margin && $form->{"cost_$i"});
        $costprice .= qq|
          </td>
        </tr>
|;

        $form->{costsubtotal} += ($form->{"cost_$i"} * $form->{"qty_$i"});
      }
    }

    if (($rows = $form->numtextrows($form->{"itemnotes_$i"}, 46, 6)) < 2) {
      $rows = 1;
    }
    
    $form->{"itemnotes_$i"} = $form->quote($form->{"itemnotes_$i"});
    $itemnotes = qq|<td><textarea name="itemnotes_$i" rows=$rows cols=46 wrap=soft>$form->{"itemnotes_$i"}</textarea></td>|;

    $serial = qq|
                <td colspan=6><b>$serialnumber</b>
                <input name="serialnumber_$i" value="|.$form->quote($form->{"serialnumber_$i"}).qq|"></td>| if $form->{type} !~ /_quotation/;

    $package = qq|
                <tr>
		  <td colspan=$colspan>
		  <b>$packagenumber</b>
		  <input name="package_$i" size=20 value="|.$form->quote($form->{"package_$i"}).qq|">
		  <b>$netweight</b>
		  <input name="netweight_$i" class="inputright" size="8" value="|.$form->format_amount(\%myconfig, $form->{"netweight_$i"}).qq|">
		  <b>$grossweight</b>
		  <input name="grossweight_$i" class="inputright" size="8" value="|.$form->format_amount(\%myconfig, $form->{"grossweight_$i"}).qq|"> ($form->{weightunit})
		  <b>$volume</b>
		  <input name="volume_$i" class="inputright" size="8" value="|.$form->format_amount(\%myconfig, $form->{"volume_$i"}).qq|">
		  </td>
		</tr>
|;
    
    if ($i == $numrows) {
      $partsgroup = "";
      if ($form->{selectpartsgroup}) {
	$partsgroup = qq|
	        <tr>
		  <td colspan=$colspan>
		    <b>$group</b>
		    <select name="partsgroup_$i">|
		    .$form->select_option($form->{selectpartsgroup}, undef, 1)
		    .qq|</select>
		    <input name="partsgroupcode_$i" size=10>
		  </td>
		</tr>
|;
      }

      $serial = "";
      $costprice = "";
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
	  $itemnotes
	  $serial
	</tr>
        $costprice
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
	  $partsgroup
|;
      }
      
      $form->hide_form("${delvar}_$i");
      $form->hide_form(map { "${_}_$i" } qw(itemnotes serialnumber ordernumber customerponumber projectnumber cost costvendor costvendorid package netweight grossweight volume));
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
    @column_index = qw(ndx partnumber sku barcode description image partsgroup partsgroupcode onhand sellprice);
  } else {
    @column_index = qw(ndx partnumber barcode description image partsgroup partsgroupcode onhand sellprice);
  }

  $column_data{ndx} = qq|<th class=listheading width=1%><input name="allbox_select" type=checkbox class=checkbox value="1" onChange="CheckAll();"></th>|;
  $column_data{partnumber} = qq|<th class=listheading>|.$locale->text('Number').qq|</th>|;
  $column_data{sku} = qq|<th class=listheading>|.$locale->text('SKU').qq|</th>|;
  $column_data{barcode} = qq|<th class=listheading>|.$locale->text('Barcode').qq|</th>|;
  $column_data{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_data{partsgroup} = qq|<th class=listheading>|.$locale->text('Group').qq|</th>|;
  $column_data{partsgroupcode} = qq|<th class=listheading>|.$locale->text('Code').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading>|.$locale->text('Price').qq|</th>|;
  $column_data{onhand} = qq|<th class=listheading>|.$locale->text('Qty').qq|</th>|;
  $column_data{image} = qq|<th class=listheading>|.$locale->text('Image').qq|</th>|;
  
  $exchangerate = $form->{exchangerate} || 1;

  $helpref = $form->{helpref};
  $form->helpref("select_item", $myconfig{countrycode});
  
  # list items with radio button on a form
  $form->header;

  &check_all(qw(allbox_select ndx_));
  
  $title = $locale->text('Select items');

  print qq|
<body>

<form method=post action="$form->{script}">

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

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
        </tr>
|;

  my $i = 0;
  foreach $ref (@{ $form->{item_list} }) {
    $i++;

    for (qw(sku partnumber barcode description unit itemnotes partsgroup partsgroupcode)) { $ref->{$_} = $form->quote($ref->{$_}) }

    $column_data{ndx} = qq|<td><input name="ndx_$i" class=checkbox type=checkbox value=$i></td>|;
    
    for (qw(partnumber sku barcode description image partsgroup partsgroupcode)) { $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>| }

    $column_data{sellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice} / $exchangerate, $form->{precision}, "&nbsp;").qq|</td>|;
    $column_data{onhand} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{onhand}, undef, "&nbsp;").qq|</td>|;
    $column_data{image} = qq|<td align=center><img src="$ref->{image}" border="0" height="32"></td>| if $ref->{image};
    
    $j++; $j %= 2;
    print qq|
        <tr class=listrow$j>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

    for (qw(partnumber sku description partsgroup partsgroupcode partsgroup_id bin weight sell sellprice listprice lastcost onhand unit assembly taxaccounts inventory_accno_id income_accno_id expense_accno_id pricematrix id itemnotes kit)) {
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
  $form->{helpref} = $helpref;
  $form->{nextsub} = "item_selected";

  $form->hide_form;
  
  print qq|
<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}



sub item_selected {

  $i = $form->{rowcount} - 1;
  $i = $form->{assembly_rows} - 1 if ($form->{item} =~ /(assembly|kit)/);
  $qty = ($form->{"qty_$form->{rowcount}"}) ? $form->{"qty_$form->{rowcount}"} : 1;

  for $j (1 .. $form->{lastndx}) {
    
    if ($form->{"ndx_$j"}) {

      $i++;

      $form->{"qty_$i"} = $qty;
      $form->{"discount_$i"} ||= $form->{discount} * 100;
      $form->{"reqdate_$i"} = $form->{reqdate} if $form->{type} !~ /_quotation/;

      for (qw(id partnumber sku description sell sellprice listprice lastcost bin unit partsgroupcode weight assembly taxaccounts pricematrix onhand itemnotes inventory_accno_id income_accno_id expense_accno_id kit)) {
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
      $form->{exchangerate} *= 1;
      if (($form->{exchangerate})) {
	for (qw(sell sellprice listprice lastcost)) { $form->{"${_}_$i"} /= $form->{exchangerate} }
        # don't format sell, list and cost
	$form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"}, $decimalplaces1);
      }
      
      # this is for the assembly
      if ($form->{item} =~ /(assembly|kit)/) {
	$form->{"adj_$i"} = 1;
        $form->{"bom_$i"} = 1 if $form->{item} eq 'kit';
	
	for (qw(sellprice listprice lastcost weight)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }

	$form->{sellprice} += ($form->{"sellprice_$i"} * $form->{"qty_$i"});
        $form->{lastcost} += ($form->{"lastcost_$i"} * $form->{"qty_$i"});
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
      if ($form->{item} !~ /(assembly|kit)/) {
	for (qw(sell sellprice listprice)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces1) }
	$form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"}, $decimalplaces2);
      }
      $form->{"cost_$i"} = $form->{"lastcost_$i"};
      $form->{"discount_$i"} = $form->format_amount(\%myconfig, $form->{"discount_$i"});
    }
  }

  $form->{rowcount} = $i;
  $form->{assembly_rows} = $i if ($form->{item} =~ /(assembly|kit)/);
  
  $i++;
  $focus = "partnumber_$i";

  # delete all the new_ variables
  for $i (1 .. $form->{lastndx}) {
    for (qw(id partnumber sku description sell sellprice listprice lastcost bin unit weight assembly taxaccounts pricematrix onhand itemnotes inventory_accno_id income_accno_id expense_accno_id)) {
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
  $form->{oldcallback} = $form->escape($form->{callback},1);
  $form->{callback} = $form->escape("$form->{script}?action=display_form",1);

  # delete action
  delete $form->{action};

  # save all other form variables in a previousform variable
  if (!$form->{previousform}) {
    delete $form->{previousform};
    foreach $key (sort keys %$form) {
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

|;

  for (qw(partnumber description)) { $form->{$_} = $form->{"${_}_$i"} }
  $form->hide_form(qw(partnumber description previousform rowcount path login));

  $form->print_button(\%button);
  
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
  if ($form->{item} =~ /(assembly|kit)/) {
    # create makemodel rows
    &makemodel_row(++$form->{makemodel_rows});
    
    $numrows = 0;
    if ($form->{item} eq 'assembly') {
      $numrows = ++$form->{customer_rows};
      $subroutine = "customer_row";
    }
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

  my @f = ();
  my $count = 0;
  my $i;
  my $j;
  my @flds = qw(id runningnumber partnumber description partsgroup partsgroupcode qty ship unit sell sellprice discount oldqty oldship orderitems_id bin weight listprice lastcost taxaccounts pricematrix sku onhand assembly inventory_accno_id income_accno_id expense_accno_id itemnotes reqdate deliverydate serialnumber ordernumber customerponumber projectnumber package netweight grossweight lineitemdetail cost kit);

  # remove any makes or model rows
  if ($form->{item} eq 'part') {
    for (qw(listprice sellprice lastcost avgcost weight rop markup onhand)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
    
    &calc_markup;
    
    @flds = qw(make model);
    $count = 0;
    @f = ();
    for $i (1 .. $form->{makemodel_rows}) {
      if (($form->{"make_$i"} ne "") || ($form->{"model_$i"} ne "")) {
	push @f, {};
	$j = $#f;

	for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
      }
    }

    $form->redo_rows(\@flds, \@f, $count, $form->{makemodel_rows});
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
  
  if ($form->{item} =~ /(assembly|kit)/) {

    if (!$form->{project_id}) {
      $form->{sellprice} = 0;
      $form->{listprice} = 0;
      $form->{lastcost} = 0;
      $form->{weight} = 0;
    }
    
    for (qw(rop markup onhand)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
   
    @flds = qw(id qty unit bom adj partnumber description sellprice listprice lastcost weight assembly runningnumber);
    $count = 0;
    @f = ();
    
    for $i (1 .. ($form->{assembly_rows} - 1)) {
      if ($form->{"qty_$i"}) {
	push @f, {};
	my $j = $#f;

        $form->{"qty_$i"} = $form->parse_amount(\%myconfig, $form->{"qty_$i"});

	for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }

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
    
    $form->redo_rows(\@flds, \@f, $count, $form->{assembly_rows});
    $form->{assembly_rows} = $count;
    
    $count = 0;
    @flds = qw(make model);
    @f = ();
    
    for $i (1 .. ($form->{makemodel_rows})) {
      if (($form->{"make_$i"} ne "") || ($form->{"model_$i"} ne "")) {
	push @f, {};
	my $j = $#f;

	for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
      }
    }

    $form->redo_rows(\@flds, \@f, $count, $form->{makemodel_rows});
    $form->{makemodel_rows} = $count;

    &check_customer if $form->{item} eq 'assembly';

  }
  
  if ($form->{type}) {

    # this section applies to invoices and orders
    # remove any empty numbers
    
    $focus = "partnumber_1";
    
    $count = 0;
    @f = ();
    if ($form->{rowcount}) {
      for $i (1 .. $form->{rowcount} - 1) {
	if ($form->{"partnumber_$i"}) {
	  push @f, {};
	  my $j = $#f;

	  for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
	  $count++;
	}
      }
      
      $form->redo_rows(\@flds, \@f, $count, $form->{rowcount});
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

    for (qw(printed emailed)) {
      $form->{$_} =~ s/\s??$form->{formname}\s??//;
      if ($form->{"$form->{formname}_$_"}) {
	$form->{$_} .= " $form->{formname}";
      }
      $form->{$_} =~ s/^ //;
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
  $exchangerate *= 1;

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
      (undef, $dec) = split /\./, $form->{"sellprice_$i"};
    } else {
      (undef, $dec) = split /,/, $form->{"sellprice_$i"};
    }
    $dec = length $dec;
    $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

    if ($qty != $form->{"oldqty_$i"}) {
      # check pricematrix
      @f = split / /, $form->{"pricematrix_$i"};
      if (scalar @f > 1) {
	foreach $item (@f) {
	  ($q, $p) = split /:/, $item;
	  if (($p * 1) && ($qty >= ($q * 1))) {
	    $form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $p / $exchangerate, $decimalplaces);
	  }
	}
      }
    }

    if ($form->{vc} eq 'customer') {
      $form->{"sell_$i"} = $form->{"sellprice_$i"};
    }
      
    $sellprice = $form->round_amount($form->parse_amount(\%myconfig, $form->{"sellprice_$i"}) * (1 - $form->{"discount_$i"} / 100), $decimalplaces);
    $amount = $form->round_amount($sellprice * $qty, $form->{precision});
    for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $form->round_amount($amount, $form->{precision}) }
    $form->{oldinvtotal} += $form->round_amount($amount, $form->{precision});
  }

  if ($form->{taxincluded}) {
    $netamount = $form->{oldinvtotal};
    for (split / /, $form->{taxaccounts}) { $netamount -= ($form->{"${_}_base"} * $form->{"${_}_rate"}) }
    $form->{cd_available} = $form->round_amount($netamount * $form->{cashdiscount} / 100, $form->{precision});
  } else {
    $form->{cd_available} = $form->round_amount($form->{oldinvtotal} * $form->{cashdiscount} / 100, $form->{precision});
    for (split / /, $form->{taxaccounts}) { $form->{oldinvtotal} += $form->round_amount($form->{"${_}_base"} * $form->{"${_}_rate"}, $form->{precision}) }
  }
  
  $totalpaid = 0;
  for $i (1 .. $form->{paidaccounts}) {
    $totalpaid += $form->{"paid_$i"};
  }

  # return total
  return ($form->{oldinvtotal} - $totalpaid);

}


sub validate_items {

  # check if items are valid
  if ($form->{rowcount} == 1) {
    &update;
    exit;
  }

  for $i (1 .. $form->{rowcount} - 1) {
    $form->isblank("partnumber_$i", $locale->text('Number missing in Row') . " $i");
    if ($form->{"kit_$i"}) {
      $form->error($locale->text('Same kit in Row') . " $i") if $samekit{$form->{"id_$i"}};
      $samekit{$form->{"id_$i"}} = 1;
    }
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

  # remove payment
	for $i (1 .. $form->{paidaccounts}) {
		for (qw(olddatepaid cleared vr_id source memo paid exchangerate paymentmethod AP_paid)) { delete $form->{"${_}_$i"} }
	}


  &create_form;

}

 
sub sales_order {

  if ($form->{type} eq 'sales_quotation') {
    $form->{closed} = 1;
    OE->save(\%myconfig, \%$form);
    # format amounts
    for $i (1 .. $form->{rowcount}) {
      for (qw(qty discount sellprice cost netweight grossweight volume)) {
        $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"});
      }
    }
  }

  $form->{title} = $locale->text('Add Sales Order');
  $form->{vc} = 'customer';
  $form->{type} = 'sales_order';
  $form->{formname} = 'sales_order';

  # remove payment
	for $i (1 .. $form->{paidaccounts}) {
		for (qw(olddatepaid cleared vr_id source memo paid exchangerate paymentmethod AR_paid)) { delete $form->{"${_}_$i"} }
	}

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

  &create_form;

}


sub create_form {

  for (qw(id subject message cc bcc printed emailed queued audittrail recurring)) { delete $form->{$_} }
 
  $form->{script} = 'oe.pl';

  $form->{linkshipto} = 1;

  $form->{rowcount}-- if $form->{rowcount};
  $form->{rowcount} = 0 if ! $form->{"$form->{vc}_id"};

  do "$form->{path}/$form->{script}";

  for ("$form->{vc}", "currency") { $form->{"select$_"} = "" }
  
  for (qw(currency employee department intnotes notes language_code taxincluded)) { $temp{$_} = $form->{$_} }

  for $i (1 .. $form->{rowcount}) {
    for (qw(sellprice listprice lastcost qty ship netweight grossweight volume discount)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
  }

  &order_links;

  $form->{reqdate} = $form->add_date(\%myconfig, $form->{transdate}, $form->{terms}, 'days');
  
  for (keys %temp) { $form->{$_} = $temp{$_} if $temp{$_} }

  $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}) || 1;

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

  if ($form->{formname} =~ /(pick|packing|bin)_list/) {
    $form->{email} = $form->{shiptoemail} if $form->{shiptoemail};
  }

  $name = $form->{$form->{vc}};
  $name =~ s/--.*//g;
  $title = $locale->text('E-mail')." $name";
 
  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{oldinvtotal}, $form->{precision});

  ($form->{warehouse}, $form->{warehouse_id}) = split /--/, $form->{warehouse};
  
  AA->company_details(\%myconfig, \%$form);

  $form->{warehouse} = "$form->{warehouse}--$form->{warehouse_id}" if $form->{warehouse_id};

  $form->header;

  print qq|
<body>

<form method=post action="$form->{script}">

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{helpref}$title</a></th>
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
 	  <th align=right nowrap=true>|.$locale->text('Bcc').qq|</th>
	  <td><input name=bcc size=30 value="$form->{bcc}"></td>
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

  for (qw(media format)) { $form->{"old$_"} = $form->{$_} }
  $form->{media} = "email";
  $form->{format} = "pdf";

  &print_options;
  
  for (qw(email cc bcc subject message formname sendmode format language_code action nextsub)) { delete $form->{$_} }
  
  $form->{nextsub} = "send_email";
  
  $form->hide_form;

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub send_email {

  $oldform = new Form;
  
  for (keys %$form) { $oldform->{$_} = $form->{$_} }
  for (qw(media format)) { $oldform->{$_} = $form->{"old$_"} }
  for (1 .. $oldform->{paidaccounts}) { $oldform->{"paid_$_"} = $form->parse_amount(\%myconfig, $form->{"paid_$_"}) }

  &print_form($oldform);
  
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
 
    if ($form->{selectprinter} && $latex) {
      for (split /\n/, $form->unescape($form->{selectprinter})) { $media .= qq|
            <option value="$_">$_| }
    }
    $media .= qq|
            <option value="queue">|.$locale->text('Queue');
    $media .= qq|</select>|;

    # set option selected
    $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;
 
  }

  $selectformat = qq|<option value="html">|.$locale->text('html').qq|
<option value="xml">|.$locale->text('XML').qq|
<option value="txt">|.$locale->text('Text');

  if ($latex) {
    $selectformat .= qq|
<option value="ps">|.$locale->text('Postscript').qq|
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

  if ($latex && $form->{media} ne 'email') {
    print qq|
    <td nowrap>|.$locale->text('Copies').qq|
    <input name="copies" class="inputright" size="2" value="$form->{copies}"></td>
|;
  }

  if ($form->{media} ne 'email') {
    print qq|
           <td align=right width=90%>|;

    for (qw(printed emailed)) { $checked{$_} = "checked" if $form->{"$form->{formname}_$_"} }

    $onhold = "";
    if ($form->{formname} =~ /invoice/) {
      $checked{onhold} = "checked" if $form->{onhold};
      $onhold = qq|
                 <td align=right><input name="onhold" type="checkbox" class="checkbox" value="1" $checked{onhold}></td>
		 <th align=left nowrap>|.$locale->text('On Hold').qq|</th>
|;
    }

    print qq|
             <table>
	       <tr>
                 $onhold
		 <td align=right><input name="$form->{formname}_printed" type="checkbox" class="checkbox" value="1" $checked{printed}></td>
		 <th align=left nowrap>|.$locale->text('Printed').qq|</th>
		 <td align=right><input name="$form->{formname}_emailed" type="checkbox" class="checkbox" value="1" $checked{emailed}></td>
		 <th align=left nowrap>|.$locale->text('E-mailed').qq|</th>
	       </tr>
|;

    if ($form->{queued}) {
      if ($form->{queued} =~ /$form->{formname}/) {
	print qq|
	       <tr>
		 <td><input name="" type="checkbox" class="checkbox" checked></td>
		 <th align=left nowrap>|.$locale->text('Queued').qq|</th>
	       </tr>
|;
      }
    }
    if ($form->{recurring}) {
      print qq|
	       <tr>
		 <td><input name="" type="checkbox" class="checkbox" checked></td>
		 <th align=left nowrap>|.$locale->text('Scheduled').qq|</th>
	       </tr>
|;
    }
    print qq|
      </table>
|;
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
	    
	    <th>|.$locale->text('Sort by').qq| -></th>
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

    $oldform = new Form;
    for (keys %$form) { $oldform->{$_} = $form->{$_} }
    
  }
  
  &print_form($oldform);

}


sub print_form {
  my ($oldform) = @_;

  $inv = "inv";
  $due = "due";

  $numberfld = "sinumber";

  $display_form = ($form->{display_form}) ? $form->{display_form} : "display_form";

  if (! ($form->{copies} = abs($form->{copies}))) {
    $form->{copies} = 1;
  }

  for (qw(name email)) { $form->{"user$_"} = $myconfig{$_} }

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
  if ($form->{formname} eq 'barcode') {
    if ($form->{type} =~ /invoice/) {
      $numberfld = "vinumber" if $form->{vc} eq 'vendor';
    } elsif ($form->{type} =~ /order/) {
      $inv = "ord";
      $due = "req";
      $form->{label} = $locale->text('Barcode');
      $numberfld = "ponumber";
      $order = 1;
    }
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
  if ($form->{formname} eq 'warehouse_transfer') {
    &print_transfer;
    exit;
  }

  $form->{"${inv}date"} = $form->{transdate};

  $form->isblank("email", "$form->{$form->{vc}} : ".$locale->text('E-mail address missing!')) if ($form->{media} eq 'email');
  $form->isblank("${inv}date", $locale->text($form->{label} .' Date missing!'));

  # get next number
  if (! $form->{"${inv}number"}) {
    $form->{"${inv}number"} ||= '-';
    if ($form->{media} ne 'screen') {
      $form->{"${inv}number"} = $form->update_defaults(\%myconfig, $numberfld);
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

  @f = ();
  foreach $i (1 .. $form->{rowcount}) {
    push @f, map { "${_}_$i" } qw(partnumber description projectnumber partsgroup partsgroupcode serialnumber ordernumber customerponumber bin unit itemnotes package);
  }
  for (split / /, $form->{taxaccounts}) { push @f, "${_}_description" }

  $ARAP = ($form->{vc} eq 'customer') ? "AR" : "AP";
  push @f, $ARAP;
  
  # format payment dates
  for $i (1 .. $form->{paidaccounts} - 1) {
    if (exists $form->{longformat}) {
      $form->{"datepaid_$i"} = $locale->date(\%myconfig, $form->{"datepaid_$i"}, $form->{longformat});
    }
    
    push @f, "${ARAP}_paid_$i", "source_$i", "memo_$i";
  }
  $form->format_string(@f);

  for (qw(employee warehouse paymentmethod)) { ($form->{$_}, $form->{"${_}_id"}) = split /--/, $form->{$_} };
 
  # this is a label for the subtotals
  $form->{groupsubtotaldescription} = $locale->text('Subtotal') if not exists $form->{groupsubtotaldescription};

  $duedate = $form->{"${due}date"};

  # create the form variables
  if ($order) {
    $msg = ($form->{vc} eq 'customer') ? $locale->text('Shipped') : $locale->text('Received');
    $msg .= " ".$locale->text('Qty')." ".$locale->text('in row');
    for $i (1 .. $form->{rowcount}) {
      $ship = $form->parse_amount(\%myconfig, $form->{"ship_$i"});
      $qty = $form->parse_amount(\%myconfig, $form->{"qty_$i"});

      if ($qty < 0) {
        $form->error($msg." $i ".$locale->text('must be negative')) if $ship > 0;
        $qty *= -1;
        $ship *= -1;
      }
      if ($qty >= 0) {
        $form->error($msg." $i ".$locale->text('must be positive')) if $ship < 0;
      }
      if ($ship > $qty) {
        $form->error($msg." $i ".$locale->text('exceeds quantity'));
      }
    }

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

  @f = qw(email name address1 address2 city state zipcode country contact phone fax);

  $fillshipto = 1;
  # check for shipto
  foreach $item (@f) {
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
      for (@f) { $form->{"shipto$_"} = $form->{$_} }
      for (qw(phone fax)) { $form->{"shipto$_"} = $form->{"$form->{vc}$_"} }
    }
  }

  # remove email
  shift @f;
 
  # some of the stuff could have umlauts so we translate them
  push @f, qw(contact shippingpoint shipvia notes intnotes employee warehouse paymentmethod);
  push @f, map { "shipto$_" } qw(name address1 address2 city state zipcode country contact email phone fax);
  push @f, qw(firstname lastname salutation contacttitle occupation mobile);

  push @f, ("${inv}number", "${inv}date", "${due}date", "${inv}description");
  
  push @f, qw(company address tel fax businessnumber companyemail companywebsite username useremail);

  for (qw(notes intnotes)) { $form->{$_} =~ s/^\s+//g }

  # before we format replace <%var%>
  for ("${inv}description", "notes", "intnotes", "message") { $form->{$_} =~ s/<%(.*?)%>/$fld = lc $1; $form->{$fld}/ge }

  $form->format_string(@f);

  $form->{templates} = "$templates/$myconfig{dbname}";
  $form->{IN} = "$form->{formname}.$form->{format}";

  if ($form->{format} =~ /(ps|pdf)/) {
    $form->{IN} =~ s/$&$/tex/;
  }

  $form->{pre} = "<body bgcolor=#ffffff>\n<pre>" if $form->{format} eq 'txt';

  if ($form->{media} !~ /(screen|queue|email)/) {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;
    
    $form->{OUT} =~ s/<%(fax)%>/<%$form->{vc}$1%>/;
    $form->{OUT} =~ s/<%(.*?)%>/$form->{$1}/g;

    if ($form->{printed} !~ /$form->{formname}/) {
    
      $form->{printed} .= " $form->{formname}";
      $form->{printed} =~ s/^ //;

      $form->{"$form->{formname}_printed"} = 1;

      $form->update_status(\%myconfig);
    }

    %audittrail = ( tablename	=> ($order) ? 'oe' : lc $ARAP,
                    reference	=> $form->{"${inv}number"},
		    formname	=> $form->{formname},
		    action	=> 'printed',
		    id		=> $form->{id} );

    if ($oldform) {
      $oldform->{printed} = $form->{printed};
      $oldform->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
    }
    
  }

  if ($form->{media} eq 'email') {
    
    $form->{subject} = qq|$form->{label} $form->{"${inv}number"}| unless $form->{subject};

    $form->{plainpaper} = 1;
    $form->{OUT} = "$sendmail";

    if ($form->{emailed} !~ /$form->{formname}/) {
      $form->{emailed} .= " $form->{formname}";
      $form->{emailed} =~ s/^ //;

      $form->{"$form->{formname}_emailed"} = 1;
      
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
   
    if ($oldform) {
      $oldform->{intnotes} = qq|$oldform->{intnotes}\n\n| if $oldform->{intnotes};
      $oldform->{intnotes} .= qq|[email]\n|
      .$locale->text('Date').qq|: $now\n|
      .$locale->text('To').qq|: $form->{email}\n${cc}${bcc}|
      .$locale->text('Subject').qq|: $form->{subject}\n|;

      $oldform->{intnotes} .= qq|\n|.$locale->text('Message').qq|: |;
      $oldform->{intnotes} .= ($form->{message}) ? $form->{message} : $locale->text('sent');

      $oldform->{message} = $form->{message};
      $oldform->{emailed} = $form->{emailed};

      $oldform->save_intnotes(\%myconfig, ($order) ? 'oe' : lc $ARAP);
    
      $oldform->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
    }
    
  }


  if ($form->{media} eq 'queue') {
    
    %queued = split / /, $form->{queued};

    if ($filename = $queued{$form->{formname}}) {
      $form->{queued} =~ s/$form->{formname} $filename//;
      unlink "$spool/$myconfig{dbname}/$filename";
      $filename =~ s/\..*$//g;
    } else {
      $filename = time;
      $filename .= int rand 10000;
    }

    $filename .= ".$form->{format}";
    $form->{OUT} = ">$spool/$myconfig{dbname}/$filename";

    $form->{queued} .= " $form->{formname} $filename";
    $form->{queued} =~ s/^ //;

    # save status
    $form->update_status(\%myconfig);
    
    %audittrail = ( tablename   => ($order) ? 'oe' : lc $ARAP,
		    reference   => $form->{"${inv}number"},
		    formname    => $form->{formname},
		    action      => 'queued',
		    id          => $form->{id} );

    if ($oldform) {
      $oldform->{queued} = $form->{queued};
      $oldform->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
    }

  }

  $form->{fileid} = $form->{"${inv}number"};
  $form->{fileid} =~ s/(\s|\W)+//g;

  $form->format_string(qw(email cc bcc));

  $form->parse_template(\%myconfig, $userspath, $dvipdf, $xelatex) if $form->{copies};


  # if we got back here restore the previous form
  if ($oldform) {

    $oldform->{"${inv}number"} = $form->{"${inv}number"};
    $oldform->{dcn} = $form->{dcn};
    
    # restore and display form
    for (keys %$oldform) { $form->{$_} = $oldform->{$_} }
    delete $form->{pre};

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
  
  $helpref = $form->{helpref};

  $vcname = $locale->text('Name');
  
  if ($form->{vc} eq 'customer') {
    
    if ($form->{type} eq 'invoice') {
      $form->helpref("sales_invoice_ship_to", $myconfig{countrycode});
    } else {
      $form->helpref("$form->{type}_ship_to", $myconfig{countrycode});
    }
      
  } else {

    if ($form->{type} eq 'invoice') {
      $form->helpref("vendor_invoice_ship_to", $myconfig{countrycode});
    } else {
      $form->helpref("$form->{type}_ship_to", $myconfig{countrycode});
    }
    
  }

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
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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
  
  $form->{helpref} = $helpref;
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

