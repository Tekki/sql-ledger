#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
# 
#======================================================================
#
# printing routines for ar, ap
#

# any custom scripts for this one
if (-f "$form->{path}/custom/arapprn.pl") {
      eval { require "$form->{path}/custom/arapprn.pl"; };
}
if (-f "$form->{path}/custom/$form->{login}/arapprn.pl") {
      eval { require "$form->{path}/custom/$form->{login}/arapprn.pl"; };
}

1;
# end of main


sub print {

  if ($form->{media} !~ /screen/) {
    $oldform = new Form;
    for (keys %$form) { $oldform->{$_} = $form->{$_} }
  }
 
  if (! $form->{invnumber}) {
    $invfld = 'sinumber';
    $invfld = 'vinumber' if $form->{ARAP} eq 'AP';
    $form->{invnumber} ||= '-';
    if ($form->{media} ne 'screen') {
      $form->{invnumber} = $form->update_defaults(\%myconfig, $invfld);
    }
  }

  if ($form->{formname} =~ /(check|receipt)/) {
    if ($form->{media} ne 'screen') {
      for (qw(action header)) { delete $form->{$_} }
      $form->{invtotal} = $form->{oldinvtotal};
      
      foreach $key (keys %$form) {
	$form->{$key} =~ s/&/%26/g;
	$form->{previousform} .= qq|$key=$form->{$key}&|;
      }
      chop $form->{previousform};
      $form->{previousform} = $form->escape($form->{previousform}, 1);
    }

    if ($form->{paidaccounts} > 1) {
      if ($form->{"paid_$form->{paidaccounts}"}) {
	&update;
	exit;
      } elsif ($form->{paidaccounts} > 2) {
	&select_payment;
	exit;
      }
    } else {
      $form->error($locale->text('Nothing to print!'));
    }
    
  }

  &{ "print_$form->{formname}" }($oldform, 1);

}


sub print_check {
  my ($oldform, $i) = @_;
  
  $display_form = ($form->{display_form}) ? $form->{display_form} : "display_form";

  if ($form->{"paid_$i"}) {
    @a = ();
    
    $datepaid = $form->datetonum(\%myconfig, $form->{"datepaid_$i"});
    ($form->{yyyy}, $form->{mm}, $form->{dd}) = $datepaid =~ /(....)(..)(..)/;

    if (exists $form->{longformat}) {
      $form->{"datepaid_$i"} = $locale->date(\%myconfig, $form->{"datepaid_$i"}, $form->{longformat});
    }

    push @a, "source_$i", "memo_$i";
    $form->format_string(@a);
  }

  $form->{amount} = $form->{"paid_$i"};

  if (($form->{formname} eq 'check' && $form->{vc} eq 'customer') ||
    ($form->{formname} eq 'receipt' && $form->{vc} eq 'vendor')) {
    $form->{amount} =~ s/-//g;
  }
    
  for (qw(datepaid source memo)) { $form->{$_} = $form->{"${_}_$i"} }

  AA->company_details(\%myconfig, \%$form);
  @a = qw(name address1 address2 city state zipcode country);
  push @a, qw(firstname lastname salutation contacttitle occupation mobile);
 
  foreach $item (qw(invnumber ordnumber)) {
    $temp{$item} = $form->{$item};
    delete $form->{$item};
    push(@{ $form->{$item} }, $temp{$item});
  }
  push(@{ $form->{invdate} }, $form->{transdate});
  push(@{ $form->{due} }, $form->format_amount(\%myconfig, $form->{oldinvtotal}, $form->{precision}));
  push(@{ $form->{paid} }, $form->{"paid_$i"});

  use SL::CP;
  $c = CP->new(($form->{language_code}) ? $form->{language_code} : $myconfig{countrycode}); 
  $c->init;
  ($whole, $form->{decimal}) = split /\./, $form->parse_amount(\%myconfig, $form->{amount});

  $form->{decimal} = substr("$form->{decimal}00", 0, 2);
  $form->{text_decimal} = $c->num2text($form->{decimal} * 1);
  $form->{text_amount} = $c->num2text($whole);
  $form->{integer_amount} = $whole;

  if ($form->{cd_amount}) {
    ($whole, $form->{cd_decimal}) = split /\./, $form->{cd_invtotal};
    $form->{cd_decimal} = substr("$form->{cd_decimal}00", 0, 2);
    $form->{text_cd_decimal} = $c->num2text($form->{cd_decimal} * 1);
    $form->{text_cd_invtotal} = $c->num2text($whole);
    $form->{integer_cd_invtotal} = $whole;
  }
  
  push @a, (qw(text_amount text_decimal text_cd_invtotal text_cd_decimal));

  # dcn
  if ($form->{vc} eq 'customer') {
    for (qw(memberno rvc dcn)) { $form->{$_} = $form->{"bank$_"} }
    $form->{rvc} = $form->format_dcn($form->{rvc});
    $form->{dcn} = $form->format_dcn($form->{dcn});
  }

  for (qw(employee)) { ($form->{$_}, $form->{"${_}_id"}) = split /--/, $form->{$_} };
  
  push @a, qw(employee notes intnotes company address tel fax businessnumber companyemail companywebsite);
  
  $form->format_string(@a);

  $form->{templates} = "$templates/$myconfig{dbname}";
  $form->{IN} = "$form->{formname}.$form->{format}";

  if ($form->{format} =~ /(ps|pdf)/) {
    $form->{IN} =~ s/$&$/tex/;
  }

  if ($form->{media} !~ /(screen)/) {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;
    
    if ($form->{printed} !~ /$form->{formname}/) {

      $form->{printed} .= " $form->{formname}";
      $form->{printed} =~ s/^ //;

      $form->update_status(\%myconfig);
    }

    %audittrail = ( tablename   => lc $form->{ARAP},
                    reference   => $form->{invnumber},
		    formname    => $form->{formname},
		    action      => 'printed',
		    id          => $form->{id} );
    
    %status = ();
    for (qw(printed audittrail)) { $status{$_} = $form->{$_} }
    
    $status{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);

  }

  $form->{fileid} = $invnumber;
  $form->{fileid} =~ s/(\s|\W)+//g;

  $form->parse_template(\%myconfig, $userspath, $dvipdf, $xelatex);

  if ($form->{previousform}) {
  
    $previousform = $form->unescape($form->{previousform});

    for (keys %$form) { delete $form->{$_} }

    foreach $item (split /&/, $previousform) {
      ($key, $value) = split /=/, $item, 2;
      $value =~ s/%26/&/g;
      $form->{$key} = $value;
    }

    for (qw(exchangerate creditlimit creditremaining)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }

    for (1 .. $form->{rowcount}) { $form->{"amount_$_"} = $form->parse_amount(\%myconfig, $form->{"amount_$_"}) }
    for (split / /, $form->{taxaccounts}) { $form->{"tax_$_"} = $form->parse_amount(\%myconfig, $form->{"tax_$_"}) }

    for $i (1 .. $form->{paidaccounts}) {
      for (qw(paid exchangerate)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    }

    for (qw(printed audittrail)) { $form->{$_} = $status{$_} }

    &{ "$display_form" };
    
  }

}


sub print_receipt {
  my ($oldform, $i) = @_;
  
  &print_check($oldform, $i);

}

sub print_remittance_voucher {
  my ($oldform) = @_;

  &print_transaction($oldform);

}


sub print_transaction {
  my ($oldform) = @_;
 
  $display_form = ($form->{display_form}) ? $form->{display_form} : "display_form";
 
  AA->company_details(\%myconfig, \%$form);

  @a = qw(name address1 address2 city state zipcode country);

  $form->{invdescription} = $form->{description};
  $form->{description} = ();

  $form->{invtotal} = 0;
  foreach $i (1 .. $form->{rowcount} - 1) {
    ($form->{tempaccno}, $form->{tempaccount}) = split /--/, $form->{"$form->{ARAP}_amount_$i"};
    ($form->{tempprojectnumber}) = split /--/, $form->{"projectnumber_$i"};
    $form->{tempdescription} = $form->{"description_$i"};
    
    $form->format_string(qw(tempaccno tempaccount tempprojectnumber tempdescription));
    
    push(@{ $form->{accno} }, $form->{tempaccno});
    push(@{ $form->{account} }, $form->{tempaccount});
    push(@{ $form->{description} }, $form->{tempdescription});
    push(@{ $form->{projectnumber} }, $form->{tempprojectnumber});

    push(@{ $form->{amount} }, $form->{"amount_$i"});

    $form->{subtotal} += $form->parse_amount(\%myconfig, $form->{"amount_$i"});
    
  }

  $form->{cd_subtotal} = $form->{subtotal};
  $cashdiscount = $form->parse_amount($myconfig, $form->{cashdiscount})/100;
  $form->{cd_available} = $form->{subtotal} * $cashdiscount;
  $cdt = $form->parse_amount($myconfig, $form->{discount_paid});
  $cdt ||= $form->{cd_available};
  $form->{cd_subtotal} -= $cdt;
  $form->{cd_amount} = $cdt;

  $cashdiscount = 0;
  if ($form->{subtotal}) {
    $cashdiscount = $cdt / $form->{subtotal};
  }

  $cd_tax = 0;
  for (split / /, $form->{taxaccounts}) {
    
    if ($form->{"tax_$_"}) {
      
      $form->format_string("${_}_description");

      $tax += $amount = $form->parse_amount(\%myconfig, $form->{"tax_$_"});

      $form->{"${_}_tax"} = $form->{"tax_$_"};
      push(@{ $form->{tax} }, $form->{"tax_$_"});

      if ($form->{cdt}) {
	$cdt = ($form->{discount_paid}) ? $form->{"tax_$_"} : $amount * (1 - $cashdiscount);
	$cd_tax += $form->round_amount($cdt, $form->{precision});
	push(@{ $form->{cd_tax} }, $form->format_amount(\%myconfig, $cdt, $form->{precision}));
      } else {
	push(@{ $form->{cd_tax} }, $form->{"tax_$_"});
      }
      
      push(@{ $form->{taxdescription} }, $form->{"${_}_description"});

      $form->{"${_}_taxrate"} = $form->format_amount($myconfig, $form->{"${_}_rate"} * 100, undef, 0);

      push(@{ $form->{taxrate} }, $form->{"${_}_taxrate"});
      
      push(@{ $form->{taxnumber} }, $form->{"${_}_taxnumber"});
    }
  }


  push @a, $form->{ARAP};
  $form->format_string(@a);

  $form->{roundto} = 0;
  if ($form->{roundchange}) {
    %roundchange = split /[=;]/, $form->unescape($form->{roundchange});
    $form->{roundto} = $roundchange{''};
    if ($form->{selectpaymentmethod}) {
      $form->{roundto} = $roundchange{$form->{"paymentmethod_$form->{paidaccounts}"}};
    }
  }

  $form->{paid} = 0;

  for $i (1 .. $form->{paidaccounts}) {

    if ($form->{"paid_$i"}) {
      @a = ();
      $form->{paid} += $form->parse_amount(\%myconfig, $form->{"paid_$i"});
      
      if (exists $form->{longformat}) {
	$form->{"datepaid_$i"} = $locale->date(\%myconfig, $form->{"datepaid_$i"}, $form->{longformat});
      }

      push @a, "$form->{ARAP}_paid_$i", "source_$i", "memo_$i";
      $form->format_string(@a);
      
      ($accno, $account) = split /--/, $form->{"$form->{ARAP}_paid_$i"};
      
      push(@{ $form->{payment} }, $form->{"paid_$i"});
      push(@{ $form->{paymentdate} }, $form->{"datepaid_$i"});
      push(@{ $form->{paymentaccount} }, $account);
      push(@{ $form->{paymentsource} }, $form->{"source_$i"});
      push(@{ $form->{paymentmemo} }, $form->{"memo_$i"});

      ($description) = split /--/, $form->{"paymentmethod_$i"};
      push(@{ $form->{paymentmethod} }, $description);

      if ($form->{selectpaymentmethod}) {
	$form->{roundto} = $roundchange{$form->{"paymentmethod_$i"}};
      }
      
    }
  }

  if ($form->{formname} eq 'remittance_voucher') {
    $form->isblank("dcn", qq|$form->{"$form->{ARAP}_paid_$form->{paidaccounts}"} : |.$locale->text('DCN missing!'));
    $form->isblank("rvc", qq|$form->{"$form->{ARAP}_paid_$form->{paidaccounts}"} : |.$locale->text('RVC missing!'));
  }

  if ($form->{taxincluded}) {
    $tax = 0;
    $cd_tax = 0;
  }

  $form->{invtotal} = $form->{subtotal} + $tax;
  $form->{cd_invtotal} = $form->{cd_subtotal} + $cd_tax;

  use SL::CP;
  $c = CP->new(($form->{language_code}) ? $form->{language_code} : $myconfig{countrycode}); 
  $c->init;

  ($whole, $decimal) = split /\./, $form->{invtotal};
  $form->{decimal} = substr("${decimal}00", 0, 2);
  $form->{text_decimal} = $c->num2text($form->{decimal} * 1);
  $form->{text_amount} = $c->num2text($whole);
  $form->{integer_amount} = $whole;

  if ($form->{roundto} > 0.01) {
    $form->{total} = $form->round_amount($form->round_amount(($form->{invtotal} - $form->{paid}) / $form->{roundto}, 0) * $form->{roundto}, $form->{precision});
    $form->{roundingdifference} = $form->round_amount($form->{paid} + $form->{total} - $form->{invtotal}, $form->{precision});
  } else {
    $form->{total} = $form->{invtotal} - $form->{paid};
  }

  ($whole, $decimal) = split /\./, $form->{total};
  $form->{out_decimal} = substr("${decimal}00", 0, 2);
  $form->{text_out_decimal} = $c->num2text($form->{out_decimal} * 1); 
  $form->{text_out_amount} = $c->num2text($whole);
  $form->{integer_out_amount} = $whole;
  
  for (qw(cd_subtotal cd_amount cd_invtotal invtotal subtotal paid total)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $form->{precision}) }

  # dcn
  if ($form->{vc} eq 'customer') {
    $form->{rvc} = $form->format_dcn($form->{rvc});
    $form->{dcn} = $form->format_dcn($form->{dcn});
  }
  
  for (qw(employee)) { ($form->{$_}, $form->{"${_}_id"}) = split /--/, $form->{$_} };
  
  $form->fdld(\%myconfig, \%$locale);

  if (exists $form->{longformat}) {
    for (qw(duedate transdate)) { $form->{$_} = $locale->date(\%myconfig, $form->{$_}, $form->{longformat}) }
  }

  # before we format replace <%var%>
  for (qw(description notes intnotes)) { $form->{$_} =~ s/<%(.*?)%>/$fld = lc $1; $form->{$fld}/ge }
  
  @a = qw(employee invnumber transdate duedate notes intnotes dcn rvc);

  push @a, qw(company address tel fax businessnumber companyemail companywebsite text_amount text_decimal text_out_decimal text_out_amount);
  
  $form->format_string(@a);

  $form->{invdate} = $form->{transdate};

  $form->{templates} = "$templates/$myconfig{dbname}";
  $form->{IN} = "$form->{formname}.$form->{format}";
  $form->{IN} = lc $form->{ARAP} . "_$form->{formname}.$form->{format}" if $form->{formname} eq 'transaction';

  if ($form->{format} =~ /(ps|pdf)/) {
    $form->{IN} =~ s/$&$/tex/;
  }

  $form->{pre} = "<body bgcolor=#ffffff>\n<pre>" if $form->{format} eq 'txt';

  if ($form->{media} !~ /(screen)/) {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;
    
    if ($form->{printed} !~ /$form->{formname}/) {

      $form->{printed} .= " $form->{formname}";
      $form->{printed} =~ s/^ //;

      $form->{"$form->{formname}_printed"} = 1;

      $form->update_status(\%myconfig);
    }

    if (%$oldform) {
      $oldform->{printed} = $form->{printed};
      $oldform->{"$form->{formname}_printed"} = 1;
    }

    %audittrail = ( tablename   => lc $form->{ARAP},
                    reference   => $form->{invnumber},
		    formname    => $form->{formname},
		    action      => 'printed',
		    id          => $form->{id} );
    
    $oldform->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail) if %$oldform;

  }

  $form->{fileid} = $form->{invnumber};
  $form->{fileid} =~ s/(\s|\W)+//g;

  $form->parse_template(\%myconfig, $userspath, $dvipdf, $xelatex);

  if (%$oldform) {
    $oldform->{invnumber} = $form->{invnumber};
    $oldform->{invtotal} = $form->{invtotal};

    for (keys %$form) { delete $form->{$_} }
    for (keys %$oldform) { $form->{$_} = $oldform->{$_} }

    if (! $form->{printandpost}) {
      for (qw(exchangerate creditlimit creditremaining)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }

      for (1 .. $form->{rowcount}) { $form->{"amount_$_"} = $form->parse_amount(\%myconfig, $form->{"amount_$_"}) }
      for (split / /, $form->{taxaccounts}) { $form->{"tax_$_"} = $form->parse_amount(\%myconfig, $form->{"tax_$_"}) }

      for $i (1 .. $form->{paidaccounts}) {
	for (qw(paid exchangerate)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
      }
    }
    
    &{ "$display_form" };

  }

}


sub print_credit_note { &print_transaction };
sub print_debit_note { &print_transaction };


sub print_payslip {
  my ($oldform) = @_;

  HR->payslip_details(\%myconfig, \%$form);

  $display_form = ($form->{display_form}) ? $form->{display_form} : "display_form";
 
  @a = ();
  $form->{paid} = $form->parse_amount(\%myconfig, $form->{paid});
  
  if (exists $form->{longformat}) {
    $form->{dateto} = $locale->date(\%myconfig, $form->{dateto}, $form->{longformat});
    $form->{transdate} = $locale->date(\%myconfig, $form->{transdate}, $form->{longformat});
    $form->{datepaid} = $form->{transdate};
  }
  
  for (qw(employee paymentmethod department project)) { ($form->{$_}, $form->{"${_}_id"}) = split /--/, $form->{$_} };
 
  push @a, qw(ap payment employee paymentmethod department project gldescription source memo);
  $form->format_string(@a);
  

  use SL::CP;
  $c = CP->new(($form->{language_code}) ? $form->{language_code} : $myconfig{countrycode}); 
  $c->init;
  ($whole, $form->{decimal}) = split /\./, $form->{paid};

  $form->{decimal} .= "00";
  $form->{decimal} = substr($form->{decimal}, 0, 2);
  $form->{text_decimal} = $c->num2text($form->{decimal} * 1); 
  $form->{text_amount} = $c->num2text($whole);
  $form->{integer_amount} = $whole;
  
 
  # before we format replace <%var%>
  $form->{description} =~ s/<%(.*?)%>/$fld = lc $1; $form->{$fld}/ge;
  
  @a = qw(description);

  push @a, qw(company address tel fax businessnumber companyemail companywebsite text_amount text_decimal);
   
  for $i (1 .. $form->{wage_rows}) {
    if ($form->{"qty_$i"}) {
      push @a, "wage_$i";

      push @{ $form->{wage} }, $form->{"wage_$i"};
      push @{ $form->{pay} }, $form->{"pay_$i"};
      push @{ $form->{qty} }, $form->{"qty_$i"};
      push @{ $form->{amount} }, $form->{"amount_$i"};
    }
  }

  delete $form->{deduct};
  
  for $i (1 .. $form->{deduction_rows}) {
    if ($form->{"deduct_$i"}) {
      push @a, "deduction_$i";

      push @{ $form->{deduction} }, $form->{"deduction_$i"};
      $form->{"deduct_$i"} =~ s/-//;
      push @{ $form->{deduct} }, $form->{"deduct_$i"};
    }
  }

  $form->format_string(@a);

  $form->{templates} = "$templates/$myconfig{dbname}";
  $form->{IN} = "$form->{formname}.$form->{format}";

  if ($form->{format} =~ /(ps|pdf)/) {
    $form->{IN} =~ s/$&$/tex/;
  }

  $form->{pre} = "<body bgcolor=#ffffff>\n<pre>" if $form->{format} eq 'txt';

  if ($form->{media} !~ /(screen)/) {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;
  }

  $form->parse_template(\%myconfig, $userspath, $dvipdf, $xelatex);

  if (%$oldform) {
    for (keys %$form) { delete $form->{$_} }
    for (keys %$oldform) { $form->{$_} = $oldform->{$_} }

    &{ "$display_form" };
  }

}



sub select_payment {

  @column_index = qw(ndx datepaid source memo paid);
  push @column_index, "$form->{ARAP}_paid";

  $helpref = $form->{helpref};
  $form->helpref("select_payment", $myconfig{countrycode});
  
  # list payments with radio button on a form
  $form->header;

  $title = $locale->text('Select payment');

  $column_data{ndx} = qq|<th width=1%>&nbsp;</th>|;
  $column_data{datepaid} = qq|<th>|.$locale->text('Date').qq|</th>|;
  $column_data{source} = qq|<th>|.$locale->text('Source').qq|</th>|;
  $column_data{memo} = qq|<th>|.$locale->text('Memo').qq|</th>|;
  $column_data{paid} = qq|<th>|.$locale->text('Amount').qq|</th>|;
  $column_data{"$form->{ARAP}_paid"} = qq|<th>|.$locale->text('Account').qq|</th>|;

  print qq|
<body>

<form method=post action=$form->{script}>

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

  $checked = "checked";
  foreach $i (1 .. $form->{paidaccounts} - 1) {

    for (@column_index) { $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>| }

    $paid = $form->{"paid_$i"};
    $ok = 1;

    $column_data{ndx} = qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
    $column_data{paid} = qq|<td align=right>$paid</td>|;
    $column_data{datepaid} = qq|<td nowrap>$form->{"datepaid_$i"}</td>|;

    $checked = "";
    
    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>|;

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

  for (qw(action nextsub)) { delete $form->{$_} }
  $form->{helpref} = $helpref;
  
  $form->hide_form;
  
  print qq|

<br>
<input type=hidden name=nextsub value=payment_selected>
|;

  if ($ok) {
    print qq|
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;
  }

  print qq|
</form>

</body>
</html>
|;
  
}

sub payment_selected {

  &{ "print_$form->{formname}" }($form->{oldform}, $form->{ndx});

}


sub print_options {

  if ($form->{selectlanguage}) {
    $lang = qq|<select name=language_code>|.$form->select_option($form->{selectlanguage}, $form->{language_code}, undef, 1).qq|</select>|;
  }
  
  $type = qq|<select name=formname>|.$form->select_option($form->{selectformname}, $form->{formname}, undef, 1).qq|</select>|;

  $media = qq|<select name=media>
          <option value="screen">|.$locale->text('Screen');

  $selectformat = qq|<option value="html">|.$locale->text('html').qq|
<option value="xml">|.$locale->text('XML').qq|
<option value="txt">|.$locale->text('Text');
			
  if ($form->{selectprinter} && $latex) {
    for (split /\n/, $form->unescape($form->{selectprinter})) { $media .= qq| 
          <option value="$_">$_| }
  }

  if ($latex) {
    $selectformat .= qq|
<option value="ps">|.$locale->text('Postscript').qq|
<option value="pdf">|.$locale->text('PDF');
  }

  $format = qq|<select name=format>$selectformat</select>|;
  $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;

  $media .= qq|</select>|;
  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

  $checked{printed} = "checked" if $form->{"$form->{formname}_printed"};
  $checked{onhold} = "checked" if $form->{onhold};

  if (!$form->{nohold}) {
    $status = qq|
             <tr>
	       <td align=right><input name="onhold" type="checkbox" class="checkbox" value="1" $checked{onhold}></td>
	       <th align=left nowrap>|.$locale->text('On Hold').qq|</font></th>
	       <td align=right><input name="$form->{formname}_printed" type="checkbox" class="checkbox" value="1" $checked{printed}></td>
	       <th align=left nowrap>|.$locale->text('Printed').qq|</th>
	     </tr>
|;
  }

  if ($form->{recurring}) {
    $recurring = qq|
             <tr>
	       <td></td>
	       <th align=left nowrap>|.$locale->text('Scheduled').qq|</th>
	     </tr>
|;
  }

  print qq|
  <table width=100%>
    <tr>
      <td>$type</td>
      <td>$lang</td>
      <td>$format</td>
      <td>$media</td>
      <td align=right width=90%>
        <table>
      $status
      $recurring
	</table>
      </td>
    </tr>
  </table>
|;

}


sub print_and_post {

  $form->error($locale->text('Select a Printer!')) if $form->{media} eq 'screen';

  $form->{printandpost} = 1;
  $form->{display_form} = "post";

  if (! $form->{invnumber}) {
    $invfld = 'sinumber';
    $invfld = 'vinumber' if $form->{ARAP} eq 'AP';
    $form->{invnumber} = $form->update_defaults(\%myconfig, $invfld);
  }

  &print;

}


