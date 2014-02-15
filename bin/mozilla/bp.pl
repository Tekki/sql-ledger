#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Batch printing
#
#======================================================================


use SL::BP;

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


sub search {

# $locale->text('Invoices')
# $locale->text('Remittance Vouchers')
# $locale->text('Packing Lists')
# $locale->text('Pick Lists')
# $locale->text('Sales Orders')
# $locale->text('Work Orders')
# $locale->text('Purchase Orders')
# $locale->text('Bin Lists')
# $locale->text('Quotations')
# $locale->text('RFQs')
# $locale->text('Time Cards')

# $locale->text('Customer')
# $locale->text('Customer Number')
# $locale->text('Vendor')
# $locale->text('Vendor Number')
# $locale->text('Employee')
# $locale->text('Employee Number')

  %label = ( invoice => { title => 'Invoices', name => ['Customer','Vendor'] },
             remittance_voucher => { title => 'Remittance Vouchers', name => ['Customer'] },
             packing_list => { title => 'Packing Lists', name => ['Customer', 'Vendor'] },
             pick_list => { title => 'Pick Lists', name => ['Customer','Vendor'] },
             sales_order => { title => 'Sales Orders', name => ['Customer'] },
             work_order => { title => 'Work Orders', name => ['Customer'] },
             purchase_order => { title => 'Purchase Orders', name => ['Vendor'] },
             bin_list => { title => 'Bin Lists', name => ['Customer', 'Vendor'] },
             sales_quotation => { title => 'Quotations', name => ['Customer'] },
             request_quotation => { title => 'RFQs', name => ['Vendor'] },
             timecard => { title => 'Time Cards', name => ['Employee'] },
	   );

  $label{invoice}{invnumber} = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
	  <td colspan=3><input name=invnumber size=20></td>
	</tr>
|;
  $label{invoice}{ordnumber} = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Order Number').qq|</th>
	  <td colspan=3><input name=ordnumber size=20></td>
	</tr>
|;
  $label{sales_quotation}{quonumber} = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Quotation Number').qq|</th>
	  <td colspan=3><input name=quonumber size=20></td>
	</tr>
|;

  $label{remittance_voucher}{invnumber} = $label{invoice}{invnumber};
  $label{packing_list}{invnumber} = $label{invoice}{invnumber};
  $label{packing_list}{ordnumber} = $label{invoice}{ordnumber};
  $label{pick_list}{invnumber} = $label{invoice}{invnumber};
  $label{pick_list}{ordnumber} = $label{invoice}{ordnumber};
  $label{sales_order}{ordnumber} = $label{invoice}{ordnumber};
  $label{work_order}{ordnumber} = $label{invoice}{ordnumber};
  $label{purchase_order}{ordnumber} = $label{invoice}{ordnumber};
  $label{bin_list}{invnumber} = $label{invoice}{invnumber};
  $label{bin_list}{ordnumber} = $label{invoice}{ordnumber};
  $label{request_quotation}{quonumber} = $label{sales_quotation}{quonumber};
  
  $label{print}{title} = "Print";
  $label{queue}{title} = "Queued";
  $label{email}{title} = "E-Mail";

  $checked{$form->{batch}} = "checked";

# $locale->text('Print')
# $locale->text('Queued')
# $locale->text('E-Mail')

  $form->{title} = $locale->text($label{$form->{batch}}{title})." ".$locale->text($label{$form->{type}}{title});

  if ($form->{batch} ne 'queue') {
    $onhold = qq|
		<input name=onhold class=checkbox type=checkbox value=Y> |.$locale->text('On Hold');

    @f = qw(invoice packing_list pick_list bin_list);

    if (! grep /$form->{type}/, @f) {
      $onhold = "";
    }

    $openclosed = qq| 
              <tr>
	        <td></td>
	        <td colspan=3 nowrap><input name=open class=checkbox type=checkbox value=Y checked> |.$locale->text('Open').qq|
		<input name=closed class=checkbox type=checkbox value=Y> |.$locale->text('Closed').qq|
		$onhold
		<input name="printed" class=checkbox type=checkbox value=Y> |.$locale->text('Printed').qq|
		<input name="notprinted" class=checkbox type=checkbox value=Y $checked{print}> |.$locale->text('Not Printed').qq|
		<input name="emailed" class=checkbox type=checkbox value=Y> |.$locale->text('E-mailed').qq|
		<input name="notemailed" class=checkbox type=checkbox value=Y $checked{email}> |.$locale->text('Not E-mailed').qq|
		</td>
              </tr>
|;
  }


  # setup customer/vendor/employee selection
  if (! BP->get_vc(\%myconfig, \%$form)) {
    if ($form->{batch} eq 'queue') {
      $form->error($locale->text('Nothing in the Queue!'));
    }
  }
  
  if ($form->{vc}) {
    @{ $label{$form->{type}}{name} } = (ucfirst $form->{vc});
  }

  $k = 0;
  foreach $vc (@{ $label{$form->{type}}{name} }) {
    $vcn = lc $vc;
    if ($form->{$vcn}) {
      $k++;
      if (@{ $form->{"all_$vcn"} }) {
	
	$form->{"select$vcn"} = qq|
	<tr>
	  <th align=right>|.$locale->text($vc).qq|</th>
	  <td colspan=3><select name=$vcn><option>\n|;
	  
	for (@{ $form->{"all_$vcn"} }) { $form->{"select$vcn"} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }
	
	$form->{"select$vcn"} .= qq|<option value="1--0">|.$locale->text('None') if $k > 1;
	
	$form->{"select$vcn"} .= qq|</select></tr>
        <input type=hidden name="print$vcn" value=Y>|;

      } else {
	$form->{"select$vcn"} = qq|
	  <tr>
	    <th align=right>|.$locale->text($vc).qq|</th>
	    <td colspan=3><input name=$vcn size=35>|;

	if ($#{$label{$form->{type}}{name}} > 0) {
	  $form->{"select$vcn"} .= qq|
	    <input name=print$vcn type=checkbox class=checkbox value=Y checked>|;
	} else {
	  $form->{"select$vcn"} .= qq| 
	    <input name=print$vcn type=hidden value="Y">|;

	}

        $vcnumber = "$vc Number";
        $form->{"select$vcn"} .= qq|
            </td>
	  </tr>
	  <tr>
	    <th align=right>|.$locale->text($vcnumber).qq|</th>
	    <td colspan=3><input name="${vcn}number" size=35></td>
	  </tr>|;
	    
      }
    }
  }

  if (@{ $form->{all_project} }) {
    if ($form->{type} eq 'timecard') {
      $projectlabel = $locale->text('Project Number');
    }
      
    if ($form->{type} eq 'storescard') {
      $projectlabel = $locale->text('Job Number');
    }
    
    $selectprojectnumber = "\n";
    for (@{ $form->{all_project} }) { $selectprojectnumber .= qq|$_->{projectnumber}--$_->{id}\n| }
    
    $projectnumber = qq|
          <tr>
	    <th align=right>$projectlabel</th>
	    <td colspan=3><select name=projectnumber>|.$form->select_option($selectprojectnumber, $form->{projectnumber}, 1)
	    .qq|</select></td>
	    </tr>
|;
  }

  if ($form->{type} eq 'remittance_voucher' || $form->{type} eq 'invoice') {
    if (@{ $form->{all_paymentmethod} }) {
      $paymentmethod = qq|
          <tr>
	    <th align=right>|.$locale->text('Payment Method').qq|</th>
	    <td colspan=3><select name=paymentmethod><option>\n|;

	    for (@{ $form->{all_paymentmethod} }) { $paymentmethod .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| }
	    $paymentmethod .= qq|</select></tr>|;
    }
  }
 
  # accounting years
  if (@{ $form->{all_years} }) {
    # accounting years
    $selectaccountingyear = "\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|$_\n| }
    $selectaccountingmonth = "\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|$_--|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
        <tr>
	<th align=right>|.$locale->text('Period').qq|</th>
	<td colspan=3 nowrap>
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

  $form->{sort} = "transdate";
  $form->{nextsub} = "list_spool";
  
  $form->helpref("bp_$form->{type}", $myconfig{countrycode});

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(batch sort nextsub type title));

  print qq|
<table width=100%>
  <tr><th class=listtop>$form->{helpref}$form->{title}</a></th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        $form->{selectcustomer}
	$form->{selectvendor}
	$form->{selectemployee}
	$account
	$label{$form->{type}}{invnumber}
	$label{$form->{type}}{ordnumber}
	$label{$form->{type}}{quonumber}
	$projectnumber
	<tr>
	  <th align=right nowrap>|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40></td>
	</tr>
	$paymentmethod
	<tr>
	  <th align=right nowrap>|.$locale->text('From').qq|</th>
	  <td><input name=transdatefrom size=11 class=date title="$myconfig{dateformat}">
	  <b>|.$locale->text('To').qq|</b>
	  <input name=transdateto size=11 class=date title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
	$openclosed
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
|;
  
  $form->hide_form(qw(path login));
  
  print qq|

</form>

</body>
</html>
|;

}



sub remove {
  
  $selected = 0;
  
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$i"}) {
      $selected = 1;
      last;
    }
  }

  $form->error('Nothing selected!') unless $selected;
 
  $form->{title} = $locale->text('Confirm!');
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  for (qw(action header)) { delete $form->{$_} }
  
  $form->hide_form;
  
  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|.$locale->text('Are you sure you want to remove the marked entries from the queue?').qq|</h4>

<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>

</body>
</html>
|;

}



sub yes {

  $form->info($locale->text('Removing marked entries from queue ...'));
  $form->{callback} .= "&header=1" if $form->{callback};

  if (BP->delete_spool(\%myconfig, \%$form, $spool)) {
    $form->redirect($locale->text('Removed spoolfiles!'));
  } else {
    $form->error($locale->text('Cannot remove files!'));
  }

}



sub print {

  $myform = new Form;
  
  for (keys %$form) {
    $myform->{$_} = $form->{$_};
    delete $form->{$_};
  }

  %msg = ( print => 'Printing',
           email => 'E-mailing',
	   );

# $locale->text('Printing')
# $locale->text('E-mailing')

  $ok = 0;
  $myconfig{vclimit} = 0;
  $r = 1;
  $total = 0;

  for my $i (1 .. $myform->{rowcount}) {
    
    if ($myform->{"ndx_$i"}) {

      $ok = 1;
      
      for (keys %$form) { delete $form->{$_} }
      
      for (qw(id vc)) { $form->{$_} = $myform->{"${_}_$i"} }
      $form->{script} = qq|$myform->{"module_$i"}.pl|;
      for (qw(login path media sendmode subject message format type header copies)) { $form->{$_} = $myform->{$_} }

      do "$form->{path}/$form->{script}";
      
      $form->{shipto} = 1;

      if ($myform->{"module_$i"} eq 'oe') {
	&order_links;
	&prepare_order;
	$form->{formname} = $myform->{type};
	$inv = 'ord'
      } elsif ($myform->{"module_$i"} eq 'jc') {
	&{"prepare_$myform->{type}"};
	$form->{formname} = $myform->{type};
      } else {
	&invoice_links;
	&prepare_invoice;
	if ($myform->{type} ne 'invoice') {
	  $form->{formname} = $myform->{type};
	}
	delete $form->{paid};
	
	$arap = ($form->{vc} eq 'customer') ? "AR" : "AP";
	$form->{payment_accno} = $form->unescape($form->{payment_accno});
	
	# default
        @f = split /\n/, $form->unescape($form->{"select${arap}_paid"});
	$form->{payment_accno} ||= $f[0];

	for (2 .. $form->{paidaccounts}) {
	  $form->{"paid_$_"} = $form->format_amount(\%myconfig, $form->{"paid_$_"}, $form->{precision});
	  $form->{payment_accno} = $form->{"${arap}_paid_$_"};
	}

	$form->{"${arap}_paid_$form->{paidaccounts}"} = $form->{payment_accno};
	$inv = 'inv'
      }

      $form->{rowcount}++;

      # unquote variables
      if ($form->{media} eq 'email' || $form->{media} eq 'queue') {
	for (keys %$form) { $form->{$_} = $form->unquote($form->{$_}) }
      }

      $myform->{description} = $form->{description};

      &print_form;

      $myform->info("${r}. ".$locale->text($msg{$myform->{batch}}).qq| ... $myform->{"reference_$i"}|);
      $myform->info(qq|, $myform->{description}|) if $myform->{description};

      if ($myform->{"module_$i"} ne 'jc') {
	if ($form->{formname} =~ /_invoice/) {
	  $total -= $form->parse_amount(\%myconfig, $form->{"${inv}total"});
	} else {
	  $total += $form->parse_amount(\%myconfig, $form->{"${inv}total"});
	}
	$myform->info(qq|, $form->{"${inv}total"}, $form->{"$form->{vc}number"}, $form->{"$form->{vc}"} $form->{city}|);
      }
      $myform->info(" ... ".$locale->text('ok')."\n");

      $r++;
      
    }
  }
  
  $myform->info($locale->text('Total').": ".$form->format_amount(\%myconfig, $total, $myform->{precision})) if $total;
  
  for (keys %$form) { delete $form->{$_} }
  for (keys %$myform) { $form->{$_} = $myform->{$_} }

  if ($ok) {
    $form->{callback} = "";
    $form->redirect;
  } else {
    $form->error($locale->text('Nothing selected!'));
  }
  
}


sub e_mail { &print }


sub list_spool {

  BP->get_spoolfiles(\%myconfig, \%$form);

  @f = qw(direction oldsort path login type printcustomer printvendor batch allbox);
  $href = "$form->{script}?action=list_spool";
  for (@f) { $href .= "&$_=$form->{$_}" }
  $href .= "&title=".$form->escape($form->{title});

 
  $form->sort_order();
  
  $callback = "$form->{script}?action=list_spool";
  for (@f) { $callback .= "&$_=$form->{$_}" }
  $callback .= "&title=".$form->escape($form->{title},1);

  %vc = ( customer => { name => 'Customer', number => 'Customer Number' },
            vendor => { name => 'Vendor', number => 'Vendor Number' },
          employee => { name => 'Employee', number => 'Employee Number' }
	     );
  
  for (qw(customer vendor employee)) {
    if ($form->{$_}) {
      $var = qq|$form->{$_}--$form->{"${_}_id"}|;
      $callback .= "&$_=".$form->escape($var,1);
      $href .= "&$_=".$form->escape($var);
      $option .= "\n<br>" if ($option);
      $option .= $locale->text($vc{$_}{name})." : $form->{$_}";
    }
    if ($form->{"${_}number"}) {
      $callback .= qq|&${_}number=|.$form->escape($form->{$form->{"${_}number"}},1);
      $href .= qq|&${_}number=|.$form->escape($form->{$form->{"${_}number"}});
      $option .= "\n<br>" if ($option);
      $option .= $locale->text($vc{$_}{number}).qq| : $form->{"${_}number"}|;
    }

  }
  if ($form->{invnumber}) {
    $callback .= "&invnumber=".$form->escape($form->{invnumber},1);
    $href .= "&invnumber=".$form->escape($form->{invnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Invoice Number')." : $form->{invnumber}";
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
  if ($form->{projectnumber}) {
    $callback .= "&projectnumber=".$form->escape($form->{projectnumber},1);
    $href .= "&projectnumber=".$form->escape($form->{projectnumber});
    $option .= "\n<br>" if ($option);
    ($projectnumber) = split /--/, $form->{projectnumber};
    $option .= $locale->text('Project Number')." : $projectnumber";
  }

  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $href .= "&description=".$form->escape($form->{description});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Description')." : $form->{description}";
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
  if ($form->{printed}) {
    $callback .= "&printed=$form->{printed}";
    $href .= "&printed=$form->{printed}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Printed');
  }
  if ($form->{emailed}) {
    $callback .= "&emailed=$form->{emailed}";
    $href .= "&emailed=$form->{emailed}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('E-mailed');
  }
  if ($form->{notprinted}) {
    $callback .= "&notprinted=$form->{notprinted}";
    $href .= "&notprinted=$form->{notprinted}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Not Printed');
  }
  if ($form->{notemailed}) {
    $callback .= "&notemailed=$form->{notemailed}";
    $href .= "&notemailed=$form->{notemailed}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Not E-mailed');
  }


  @columns = qw(transdate);
  if ($form->{type} =~ /(packing|pick|bin)_list|invoice|remittance_voucher/) {
    push @columns, "invnumber";
  }
  if ($form->{type} =~ /_(order|list)$/) {
    push @columns, "ordnumber";
  }
  if ($form->{type} =~ /_quotation$/) {
    push @columns, "quonumber";
  }
  if ($form->{type} eq 'timecard') {
    push @columns, "id";
  }
  
  push @columns, qw(description name vcnumber);
  push @columns, "email" if $form->{batch} eq 'email';
  push @columns, qw(city amount);
  push @columns, "spoolfile" if $form->{batch} eq 'queue';
  
  @column_index = $form->sort_columns(@columns);
  unshift @column_index, qw(runningnumber ndx);

  $column_header{runningnumber} = "<th><a class=listheading>&nbsp;</th>";
  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $action = ($form->{deselect}) ? "deselect_all" : "select_all";
  $column_header{ndx} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); Javascript:document.forms[0].submit()"><input type=hidden name=action value="$action"></th>|;
  $column_header{transdate} = "<th><a class=listheading href=$href&sort=transdate>".$locale->text('Date')."</a></th>";
  $column_header{invnumber} = "<th><a class=listheading href=$href&sort=invnumber>".$locale->text('Invoice')."</a></th>";
  $column_header{ordnumber} = "<th><a class=listheading href=$href&sort=ordnumber>".$locale->text('Order')."</a></th>";
  $column_header{quonumber} = "<th><a class=listheading href=$href&sort=quonumber>".$locale->text('Quotation')."</a></th>";
  $column_header{name} = "<th><a class=listheading href=$href&sort=name>".$locale->text('Name')."</a></th>";

  $column_header{vcnumber} = "<th><a class=listheading href=$href&sort=vcnumber>".$locale->text('Number')."</a></th>";

  $column_header{email} = "<th class=listheading>".$locale->text('E-mail')."</th>";
  $column_header{city} = "<th class=listheading>".$locale->text('City')."</th>";
  $column_header{id} = "<th><a class=listheading href=$href&sort=id>".$locale->text('ID')."</a></th>";
  $column_header{description} = "<th><a class=listheading href=$href&sort=description>".$locale->text('Description')."</a></th>";
  $column_header{spoolfile} = "<th class=listheading>".$locale->text('Spoolfile')."</th>";
  $column_header{amount} = "<th class=listheading>".$locale->text('Amount')."</th>";

  $form->helpref("list_spool", $myconfig{countrycode});
  
  $form->header;
  
  print qq|
<script language="javascript">
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
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
	</tr>
|;


  # add sort and escape callback, this one we use for the add sub
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);

  $i = 0;
  $totalamount = 0;
  
  foreach $ref (@{ $form->{SPOOL} }) {

    $i++;
    
    if ($form->{"ndx_$i"}) {
      $form->{"ndx_$i"} = "checked";
    }
    
    $totalamount += $ref->{amount};

    # this is for audittrail
    $form->{module} = $ref->{module};
    
    if ($ref->{invoice}) {
      $ref->{module} = ($ref->{module} eq 'ar') ? "is" : "ir";
    }
    $module = "$ref->{module}.pl";
    
    $column_data{amount} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}).qq|</td>|;

    $column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox $form->{"ndx_$i"} $form->{"ndx_$i"}></td>|;

    if ($form->{batch} eq 'queue') {
      if ($spoolfile eq $ref->{spoolfile}) {
	$column_data{ndx} = qq|<td></td>|;
      }
    }
    
    $column_data{runningnumber} = qq|<td>$i</td>|;

    for (qw(description email city id invnumber ordnumber quonumber vcnumber)) { $column_data{$_} = qq|<td>$ref->{$_}</td>| }
    $column_data{transdate} = qq|<td nowrap>$ref->{transdate}</td>|;

    $column_data{name} = qq|<td><a href=ct.pl?action=edit&id=$ref->{vc_id}&db=$ref->{db}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{name}</a></td>|;
    
    if ($ref->{module} eq 'oe') {
      $column_data{invnumber} = qq|<td>&nbsp</td>|;
      $column_data{ordnumber} = qq|<td><a href=$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&type=$form->{type}&callback=$callback>$ref->{ordnumber}</a></td>
      <input type=hidden name="reference_$i" value="|.$form->quote($ref->{ordnumber}).qq|">|;
      
      $column_data{quonumber} = qq|<td><a href=$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&type=$form->{type}&callback=$callback>$ref->{quonumber}</a></td>
    <input type=hidden name="reference_$i" value="|.$form->quote($ref->{quonumber}).qq|">|;
 
    } elsif ($ref->{module} eq 'jc') {
      $column_data{id} = qq|<td><a href=$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&type=$form->{type}&callback=$callback>$ref->{id}</a></td>
    <input type=hidden name="reference_$i" value="$ref->{id}">|;

      $column_data{name} = qq|<td><a href=hr.pl?action=edit&id=$ref->{employee_id}&db=employee&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{name}</a></td>|;
    } else {
      $column_data{invnumber} = qq|<td><a href=$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&type=$form->{type}&callback=$callback>$ref->{invnumber}</a></td>
    <input type=hidden name="reference_$i" value="|.$form->quote($ref->{invnumber}).qq|">|;
    }
    
   
    $column_data{spoolfile} = qq|<td><a href=$spool/$myconfig{dbname}/$ref->{spoolfile}>$ref->{spoolfile}</a></td>
|;

    $spoolfile = $ref->{spoolfile};
    
    $j++; $j %= 2;
    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>

<input type=hidden name="id_$i" value="$ref->{id}">
<input type=hidden name="spoolfile_$i" value="$ref->{spoolfile}">
<input type=hidden name="vc_$i" value="$ref->{vc}">
<input type=hidden name="module_$i" value="$ref->{module}">
|;
  }

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount, $form->{precision}, "&nbsp;")."</th>";
  
  print qq|<tr class=listtotal>|;
  
  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
<input type=hidden name=rowcount value=$i>

      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
|;

  $form->hide_form(qw(callback title type sort path login printcustomer printvendor customer customernumber vendor vendornumber employee employeenumber batch invnumber ordnumber quonumber description transdatefrom transdateto open closed onhold printed emailed notprinted notemailed precision));

  $form->{copies} ||= 1;

  $selectformat = "";
  $media = qq|<select name=media>|;
  
  if ($form->{batch} eq 'email') {
    $form->{format} ||= "pdf";
    $selectformat .= qq|<option value="html">|.$locale->text('html').qq|
<option value="xml">|.$locale->text('XML').qq|
<option value="txt">|.$locale->text('Text');
  } else {
    $form->{format} ||= $myconfig{outputformat};
    $form->{media} ||= $myconfig{printer};
    $form->{format} ||= "ps";
    exit if (! $latex && $form->{batch} eq 'print');
  }
  
  if ($latex) {
    $selectformat .= qq|
	  <option value="ps">|.$locale->text('Postscript').qq|
          <option value="pdf">|.$locale->text('PDF');
  }
   
  if (@{ $form->{all_printer} } && $form->{batch} ne 'email') {
    
    for (@{ $form->{all_printer} }) {
      $media .= qq|<option value="$_->{printer}">$_->{printer}|;
    }

    $copies = qq|
      <td nowrap>|.$locale->text('Copies').qq|
      <input name=copies size=2 value=$form->{copies}></td>
|;

  }

  if ($form->{batch} eq 'email') {
    $sendmode = qq|<select name="sendmode">
            <option value="attachment">|.$locale->text('Attachment').qq|
	    <option value="inline">|.$locale->text('In-line').qq|</select>|;
  }
	    
  if ($form->{batch} ne 'email') {
    $media .= qq|
          <option value="queue">|.$locale->text('Queue') if $form->{batch} eq 'print';
  }
 
  $media .= qq|</select>|;

  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;
  $media = qq|<td width=1%>$media</td>|;
  
  $format = qq|<select name=format>$selectformat</select>|;
  $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;
  $format = qq|<td width=1%>$format</td>|;
 
  if ($form->{batch} eq 'email') {
    $sendmode =~ s/(<option value="\Q$form->{sendmode}\E")/$1 selected/;
    $sendmode = qq|<td>$sendmode</td>|;

    $message = qq|<tr>
                    <td colspan=2 nowrap><b>|.$locale->text('Subject').qq|</b>&nbsp;<input name=subject size=30></td>
		  </tr>
		  <tr>
                    <td colspan=2><b>|.$locale->text('Message').qq|<br><textarea name=message rows=15 cols=60 wrap=soft>$form->{message}</textarea></td>
      </tr>|;
      
    $media = qq|<input type="hidden" name="media" value="email">
|;
  }
  if ($form->{batch} eq 'queue') {
    $format = "";
    $copies = "";
    $media = "" if ! @{ $form->{all_printer} };
  }


  print qq|
<table>
  $message
  <tr>
  $format
  $sendmode
  $media
  $copies
  </tr>
</table>
<p>
|;
  
  %button = ('Select all' => { ndx => 2, key => 'A', value => $locale->text('Select all') },
               'Deselect all' => { ndx => 3, key => 'A', value => $locale->text('Deselect all') },
               'Print' => { ndx => 5, key => 'P', value => $locale->text('Print') },
               'E-mail' => { ndx => 6, key => 'E', value => $locale->text('E-mail') },
               'Combine' => { ndx => 7, key => 'C', value => $locale->text('Combine') },
	       'Remove' => { ndx => 8, key => 'R', value => $locale->text('Remove') },
	      );


  if ($form->{deselect}) {
    delete $button{'Select all'};
  } else {
    delete $button{'Deselect all'};
  }
  
  if ($form->{batch} eq 'print') {
    delete $button{'E-mail'};
  }
  if ($form->{batch} ne 'queue') {
    delete $button{'Remove'};
  }
  if ($form->{batch} eq 'email') {
    delete $button{'Print'};
  }
  if ($form->{batch} eq 'queue') {
    delete $button{'E-mail'};
    delete $button{'Print'} if ! @{ $form->{all_printer} };
  }

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


sub select_all {

  for (1 .. $form->{rowcount}) { $form->{"ndx_$_"} = 1 }
  $form->{allbox} = 1;
  $form->{deselect} = 1;
  &list_spool;
  
}


sub deselect_all {
  
  for (1 .. $form->{rowcount}) { $form->{"ndx_$_"} = "" }
  $form->{allbox} = "";
  &list_spool;
  
}


sub combine {

  use Cwd;
  $dir = cwd();
  $files = "";

  for (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$_"}) {
      if ($form->{"spoolfile_$_"} =~ /\.pdf$/) {
	$files .= qq|$form->{"spoolfile_$_"} |;
      }
    }
  }

  $form->{format} = "pdf";
  
  if ($files) {
    chdir("$spool/$myconfig{dbname}");
    if ($filename = BP->spoolfile(\%myconfig, \%$form)) {
      @args = ("cat $files > $filename");
      system(@args) == 0 or $form->error("@args : $?");
    }
  } else {
    $form->error($locale->text('Nothing selected!'));
  }

  chdir("$dir");

  $form->redirect;
  
}


sub continue { &{ $form->{nextsub} } };

