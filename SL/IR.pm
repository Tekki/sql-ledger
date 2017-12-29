#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Inventory received module
#
#======================================================================

package IR;

use SL::IS;
use SL::PM;
use SL::CP;


sub invoice_details {
  my ($self, $myconfig, $form) = @_;

  $form->{duedate} ||= $form->{transdate};

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $sth;
  my $query;
  my $ref;

  $form->{total} = 0;

  $form->{terms} = $form->datediff($myconfig, $form->{duedate}, $form->{transdate});

  # this is for the template
  $form->{invdate} = $form->{transdate};
  $form->{invdescription} = $form->{description};

  for (qw(description projectnumber)) { delete $form->{$_} }
  
  my $tax;
  my $i;
  my @sortlist = ();
  my $projectnumber;
  my $projectdescription;
  my $projectnumber_id;
  my $translation;
  my $partsgroup;
  my @taxaccounts;
  my %taxaccounts;
  my $tax;
  my $taxrate;
  my $taxamount;
  my $taxbase;
  my %taxbase;
 
  my %translations;
  
  $query = qq|SELECT p.description, t.description
              FROM project p
	      LEFT JOIN translation t ON (t.trans_id = p.id AND t.language_code = '$form->{language_code}')
	      WHERE id = ?|;
  my $prh = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT inventory_accno_id, income_accno_id, expense_accno_id,
              tariff_hscode AS hscode, countryorigin, barcode
	      FROM parts
              WHERE id = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);

  my $sortby;
  
  # sort items by project and partsgroup
  for $i (1 .. $form->{rowcount} - 1) {

    # account numbers
    $pth->execute($form->{"id_$i"});
    $ref = $pth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }
    $pth->finish;

    $projectnumber_id = 0;
    $projectnumber = "";
    $form->{partsgroup} = "";
    $form->{projectnumber} = "";
    
    if ($form->{groupprojectnumber} || $form->{grouppartsgroup}) {
      
      $inventory_accno_id = ($form->{"inventory_accno_id_$i"}) ? "1" : "";
      
      if ($form->{groupprojectnumber}) {
	($projectnumber, $projectnumber_id) = split /--/, $form->{"projectnumber_$i"};
      }
      if ($form->{grouppartsgroup}) {
	($form->{partsgroup}) = split /--/, $form->{"partsgroup_$i"};
      }
      
      if ($projectnumber_id && $form->{groupprojectnumber}) {
	if ($translation{$projectnumber_id}) {
	  $form->{projectnumber} = $translation{$projectnumber_id};
	} else {
	  # get project description
	  $prh->execute($projectnumber_id);
	  ($projectdescription, $translation) = $prh->fetchrow_array;
	  $prh->finish;
	  
	  $form->{projectnumber} = ($translation) ? "$projectnumber, $translation" : "$projectnumber, $projectdescription";

	  $translation{$projectnumber_id} = $form->{projectnumber};
	}
      }

      if ($form->{grouppartsgroup} && $form->{partsgroup}) {
	$form->{projectnumber} .= " / " if $projectnumber_id;
	$form->{projectnumber} .= $form->{partsgroup};
      }
      
      $form->format_string((projectnumber));

    }
    
    $sortby = qq|$projectnumber$form->{partsgroup}|;
    if ($form->{sortby} ne 'runningnumber') {
      for (qw(partnumber description bin)) {
	$sortby .= $form->{"${_}_$i"} if $form->{sortby} eq $_;
      }
    }

    push @sortlist, [ $i, qq|$projectnumber$form->{partsgroup}$inventory_accno_id|, $form->{projectnumber}, $projectnumber_id, $form->{partsgroup}, $sortby ];

    # last package number 
    $form->{packages} = $form->{"package_$i"} if $form->{"package_$i"};
       
  }

  my @p;
  if ($form->{packages}) {
    @p = reverse split //, $form->{packages};
  }
  my $p = "";
  while (@p) {
    my $n = shift @p;
    if ($n =~ /\d/) {
      $p .= "$n";
    } else { 
      last;
    }
  }
  if ($p) {
    $form->{packages} = reverse split //, $p;
  }
  
  my $c;
  if ($form->{language_code} ne "") {
    $c = new CP $form->{language_code};
  } else {
    $c = new CP $myconfig->{countrycode};
  }
  $c->init;
  
  $form->{text_packages} = $c->num2text($form->{packages} * 1);
  $form->format_string((text_packages));
  $form->format_amount($myconfig, $form->{packages});

  @{ $form->{projectnumber} } = ();
  @{ $form->{description} } = ();

  # sort the whole thing by project and group
  @sortlist = sort { $a->[5] cmp $b->[5] } @sortlist;

  my $runningnumber = 1;
  my $sameitem = "";
  my $subtotal;
  my $k = scalar @sortlist;
  my $j = 0;
  my $ok;

  @{ $form->{lineitems} } = ();
  @{ $form->{taxrates} } = ();

  for my $item (@sortlist) {

    $i = $item->[0];
    $j++;

    # heading
    if ($form->{groupprojectnumber} || $form->{grouppartsgroup}) {
      if ($item->[1] ne $sameitem) {
	$sameitem = $item->[1];
	
	$ok = 0;

	if ($form->{groupprojectnumber}) {
	  $ok = $form->{"projectnumber_$i"};
	}
	if ($form->{grouppartsgroup}) {
	  $ok = $form->{"partsgroup_$i"} unless $ok;
	}

	if ($ok) {
	  
	  if ($form->{"inventory_accno_id_$i"} || $form->{"kit_$i"}) {
	    push(@{ $form->{part} }, "");
	    push(@{ $form->{service} }, NULL);
	  } else {
	    push(@{ $form->{part} }, NULL);
	    push(@{ $form->{service} }, "");
	  }
    
	  push(@{ $form->{description} }, $item->[2]);
	  for (qw(taxrates runningnumber number sku serialnumber ordernumber customerponumber bin qty ship unit deliverydate projectnumber sell sellprice listprice netprice discount discountrate linetotal itemnotes lineitemdetail package netweight grossweight volume countryorigin hscode barcode)) { push(@{ $form->{$_} }, "") }
	  push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });
	}
      }
    }
      
    $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"});
    
    if ($form->{"qty_$i"}) {

      $form->{totalqty} += $form->{"qty_$i"};
      $form->{totalship} += $form->{"qty_$i"};
      $form->{totalnetweight} += $form->parse_amount($myconfig, $form->{"netweight_$i"});
      $form->{totalgrossweight} += $form->parse_amount($myconfig, $form->{"grossweight_$i"});

      # add number, description and qty to $form->{number}, ....
      push(@{ $form->{runningnumber} }, $runningnumber++);
      push(@{ $form->{number} }, $form->{"partnumber_$i"});

      # if not grouped remove id
      ($projectnumber) = split /--/, $form->{"projectnumber_$i"};
      push(@{ $form->{projectnumber} }, $projectnumber);
      
      for (qw(sku serialnumber ordernumber customerponumber bin description unit deliverydate sell sellprice listprice itemnotes lineitemdetail package netweight grossweight volume countryorigin hscode barcode)) { push(@{ $form->{$_} }, $form->{"${_}_$i"}) }

      push(@{ $form->{qty} }, $form->format_amount($myconfig, $form->{"qty_$i"}));
      push(@{ $form->{ship} }, $form->format_amount($myconfig, $form->{"qty_$i"}));
      my $sellprice = $form->parse_amount($myconfig, $form->{"sellprice_$i"});
      my ($dec) = ($sellprice =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};
      
      my $discount = $form->round_amount($sellprice * $form->parse_amount($myconfig, $form->{"discount_$i"})/100, $decimalplaces);
      
      # keep a netprice as well, (sellprice - discount)
      $form->{"netprice_$i"} = $sellprice - $discount;
      
      my $linetotal = $form->round_amount($form->{"qty_$i"} * $form->{"netprice_$i"}, $form->{precision});

      if ($form->{"inventory_accno_id_$i"} || $form->{"kit_$i"}) {
	push(@{ $form->{part} }, $form->{"partnumber_$i"});
	push(@{ $form->{service} }, NULL);
	$form->{totalparts} += $linetotal;
      } else {
	push(@{ $form->{service} }, $form->{"partnumber_$i"});
	push(@{ $form->{part} }, NULL);
	$form->{totalservices} += $linetotal;
      }

      push(@{ $form->{netprice} }, ($form->{"netprice_$i"}) ? $form->format_amount($myconfig, $form->{"netprice_$i"}, $decimalplaces) : " ");
      
      $discount = ($discount) ? $form->format_amount($myconfig, $discount * -1, $decimalplaces) : " ";
      $linetotal = ($linetotal) ? $linetotal : " ";
      
      push(@{ $form->{discount} }, $discount);
      push(@{ $form->{discountrate} }, $form->format_amount($myconfig, $form->{"discount_$i"}));

      $form->{total} += $linetotal;

      # this is for the subtotals for grouping
      $subtotal += $linetotal;

      $form->{"linetotal_$i"} = $form->format_amount($myconfig, $linetotal, $form->{precision}, "0");
      push(@{ $form->{linetotal} }, $form->{"linetotal_$i"});
      
      @taxaccounts = split / /, $form->{"taxaccounts_$i"};
      
      my $ml = 1;
      my @taxrates = ();
      
      $tax = 0;
      
      for (0 .. 1) {
	$taxrate = 0;
	
	for (@taxaccounts) { $taxrate += $form->{"${_}_rate"} if ($form->{"${_}_rate"} * $ml) > 0 }
	
	$taxrate *= $ml;
	$taxamount = $linetotal * $taxrate / (1 + $taxrate);
	$taxbase = ($linetotal - $taxamount);

	for my $item (@taxaccounts) {
	  if (($form->{"${item}_rate"} * $ml) > 0) {
	    
	    push @taxrates, $form->{"${item}_rate"} * 100;
	    
	    if ($form->{taxincluded}) {
	      $taxaccounts{$item} += $linetotal * $form->{"${item}_rate"} / (1 + $taxrate);
	      $taxbase{$item} += $taxbase;
	    } else {
	      $taxbase{$item} += $linetotal;
	      $taxaccounts{$item} += $linetotal * $form->{"${item}_rate"};
	    }
	  }
	}

	if ($form->{taxincluded}) {
	  $tax += $linetotal * ($taxrate / (1 + ($taxrate * $ml)));
	} else {
	  $tax += $linetotal * $taxrate;
	}
	
	$ml *= -1;
      }

      # process 0 taxes
      for (@taxaccounts) {
        if ($form->{"${_}_rate"} eq "0") {
          push @taxrates, 0;
          $taxaccounts{$_} = 0;
          $taxbase{$_} += $linetotal;
        }
      }

      $tax = $form->round_amount($tax, $form->{precision});
      push(@{ $form->{lineitems} }, { amount => $linetotal, tax => $tax });
      push(@{ $form->{taxrates} }, join ' ', sort { $a <=> $b } @taxrates);
      
      if ($form->{"kit_$i"}) {
	$form->{stagger} = -1;
	&IS::assembly_details($myconfig, $form, $dbh, $form->{"id_$i"}, $form->{"qty_$i"}, $form->{"kit_$i"});
        if ($form->{"kit_$i"}) {
          %p = split /[: ]/, $form->{"pricematrix_$i"};
          for (split / /, $form->{"kit_$i"}) {
            @p = split /:/, $_;
            for $n (2 .. $#p) {
              if ($form->{taxaccounts} =~ /$p[$n]/) {
                if ($p[1]) {
                  if ($p{0}) {
                    $d = $form->round_amount($p{0} * $form->{"discount_$i"}/100, $decimalplaces);
                    $p = $form->round_amount($p{0} - $d, $decimalplaces);
                    $p = $form->round_amount($p * $form->{"qty_$i"}, $form->{precision});
                    $d = $form->round_amount($p[1] * $form->{"discount_$i"}/100, $decimalplaces);
                    if ($p) {

                      $lt = ($p[1] - $d) * $linetotal/$p * $form->{"qty_$i"};

                      if ($form->{taxincluded}) {
                        $taxaccounts{$p[$n]} += $lt * $form->{"$p[$n]_rate"} / (1 + $form->{"$p[$n]_rate"});
                        $taxbase{$p[$n]} += $lt - $lt * $form->{"$p[$n]_rate"} / (1 + $form->{"$p[$n]_rate"});
                      } else {
                        $taxaccounts{$p[$n]} += $lt * $form->{"$p[$n]_rate"};
                        $taxbase{$p[$n]} += $lt;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

    }

    # add subtotal
    if ($form->{groupprojectnumber} || $form->{grouppartsgroup}) {
      if ($subtotal) {
	if ($j < $k) {
	  # look at next item
	  if ($sortlist[$j]->[1] ne $sameitem) {

	    if ($form->{"inventory_accno_id_$j"} || $form->{"kit_$i"}) {
	      push(@{ $form->{part} }, "");
	      push(@{ $form->{service} }, NULL);
	    } else {
	      push(@{ $form->{service} }, "");
	      push(@{ $form->{part} }, NULL);
	    }

	    for (qw(taxrates runningnumber number sku serialnumber ordernumber customerponumber bin qty ship unit deliverydate projectnumber sell sellprice listprice netprice discount discountrate itemnotes lineitemdetail package netweight grossweight volume countryorigin hscode barcode)) { push(@{ $form->{$_} }, "") }
	    
	    push(@{ $form->{description} }, $form->{groupsubtotaldescription});
	    
	    push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });

	    if ($form->{groupsubtotaldescription} ne "") {
	      push(@{ $form->{linetotal} }, $form->format_amount($myconfig, $subtotal, $form->{precision}));
	    } else {
	      push(@{ $form->{linetotal} }, "");
	    }
	    $subtotal = 0;
	  }
	  
	} else {

	  # got last item
	  if ($form->{groupsubtotaldescription} ne "") {

	    if ($form->{"inventory_accno_id_$j"} || $form->{"kit_$i"}) {
	      push(@{ $form->{part} }, "");
	      push(@{ $form->{service} }, NULL);
	    } else {
	      push(@{ $form->{service} }, "");
	      push(@{ $form->{part} }, NULL);
	    }

	    for (qw(taxrates runningnumber number sku serialnumber ordernumber customerponumber bin qty ship unit deliverydate projectnumber sell sellprice listprice netprice discount discountrate itemnotes lineitemdetail package netweight grossweight volume countryorigin hscode barcode)) { push(@{ $form->{$_} }, "") }

	    push(@{ $form->{description} }, $form->{groupsubtotaldescription});
	    push(@{ $form->{linetotal} }, $form->format_amount($myconfig, $subtotal, $form->{precision}));
	    push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });
	  }
	}
      }
    }
  }

   
  $tax = 0;
  $taxrate = 0;
  
  for (sort keys %taxaccounts) {
    $taxaccounts{$_} = $form->round_amount($taxaccounts{$_}, $form->{precision});
    $tax += $taxaccounts{$_};
    
    $form->{"${_}_taxbaseinclusive"} = $taxbase{$_} + $taxaccounts{$_};
    
    push(@{ $form->{taxdescription} }, $form->{"${_}_description"});

    $taxrate += $form->{"${_}_rate"};
    
    push(@{ $form->{taxrate} }, $form->format_amount($myconfig, $form->{"${_}_rate"} * 100, undef, 0));
    push(@{ $form->{taxnumber} }, $form->{"${_}_taxnumber"});
  }

  # adjust taxes for lineitems
  my $total = 0;
  for $ref (@{ $form->{lineitems} }) {
    $total += $ref->{tax};
  }
  if ($form->round_amount($total, $form->{precision}) != $form->round_amount($tax, $form->{precision})) {
    # get largest amount
    for $ref (reverse sort { $a->{tax} <=> $b->{tax} } @{ $form->{lineitems} }) {
      $ref->{tax} -= ($total - $tax);
      last;
    }
  }
  $i = 1;
  for $ref (@{ $form->{lineitems} }) {
    push(@{ $form->{linetax} }, $form->format_amount($myconfig, $ref->{tax}, $form->{precision}, 0));
  }

  
  if ($form->{taxincluded}) {
    $form->{invtotal} = $form->{total};
    $form->{subtotal} = $form->{total} - $tax;
  } else {
    $form->{invtotal} = $form->{total} + $tax;
    $form->{subtotal} = $form->{total};
  }

  for (qw(subtotal invtotal)) { $form->{"cd_$_"} = $form->{$_} }
  my $cdt = $form->parse_amount($myconfig, $form->{discount_paid});
  $cdt ||= $form->{cd_available};
  $form->{cd_subtotal} -= $cdt;
  $form->{cd_amount} = $cdt;

  my $cashdiscount = 0;
  if ($form->{subtotal}) {
    $cashdiscount = $cdt / $form->{subtotal};
  }
  
  my $cd_tax = 0;

  for (sort keys %taxaccounts) {
    
    $amount = 0;

    if ($form->{cdt} && !$form->{taxincluded}) {
      $amount = $taxbase{$_} * $cashdiscount;
    }

    if ($form->{cd_amount}) {
      $form->{"cd_${_}_taxbase"} = $taxbase{$_} - $amount;

      push(@{ $form->{cd_taxbase} }, $form->format_amount($myconfig, $form->{"cd_${_}_taxbase"}, $form->{precision}));

      $cd_tax += $form->{"cd_${_}_tax"} = $form->round_amount(($taxbase{$_} - $amount) * $form->{"${_}_rate"}, $form->{precision});

      push(@{ $form->{cd_tax} }, $form->format_amount($myconfig, $form->{"cd_${_}_tax"}, $form->{precision}));

      $form->{"cd_${_}_taxbase"} = $form->format_amount($myconfig, $form->{"cd_${_}_taxbase"}, $form->{precision});
      $form->{"cd_${_}_taxbaseinclusive"} = $form->format_amount($myconfig, $form->{"${_}_taxbaseinclusive"} - $amount, $form->{precision});
    }

    if ($form->{cdt} && $form->{discount_paid}) {
      $form->{"${_}_taxbaseinclusive"} -= $amount;
      $taxbase{$_} -= $amount;
      $taxaccounts{$_} -= ($taxaccounts{$_} - $form->{"cd_${_}_tax"});
    }
    
    # need formatting here
    push(@{ $form->{taxbaseinclusive} }, $form->format_amount($myconfig, $form->{"${_}_taxbaseinclusive"}, $form->{precision}));
    push(@{ $form->{taxbase} }, $form->format_amount($myconfig, $taxbase{$_}, $form->{precision}));
    push(@{ $form->{tax} }, $form->format_amount($myconfig, $taxaccounts{$_}, $form->{precision}, 0));
    
    $form->{"${_}_taxbaseinclusive"} = $form->format_amount($myconfig, $form->{"${_}_taxbaseinclusive"}, $form->{precision});
    $form->{"${_}_taxbase"} = $form->format_amount($myconfig, $taxbase{$_}, $form->{precision});
    $form->{"${_}_tax"} = $form->format_amount($myconfig, $form->{"${_}_tax"}, $form->{precision}, 0);

    $form->{"${_}_taxrate"} = $form->format_amount($myconfig, $form->{"${_}_rate"} * 100, 0);

  }

  $form->{roundto} = 0;
  my %roundchange;
  if ($form->{roundchange}) {
    %roundchange = split /[=;]/, $form->unescape($form->{roundchange});
    $form->{roundto} = $roundchange{''};
    if ($form->{selectpaymentmethod}) {
      $form->{roundto} = $roundchange{$form->{"paymentmethod_$form->{paidaccounts}"}};
    }
  }

  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      push(@{ $form->{payment} }, $form->{"paid_$i"});
      my ($accno, $description) = split /--/, $form->{"AP_paid_$i"};
      push(@{ $form->{paymentaccount} }, $description); 
      push(@{ $form->{paymentdate} }, $form->{"datepaid_$i"});
      push(@{ $form->{paymentsource} }, $form->{"source_$i"});
      push(@{ $form->{paymentmemo} }, $form->{"memo_$i"});

      ($description) = split /--/, $form->{"paymentmethod_$i"};
      push(@{ $form->{paymentmethod} }, $description);

      if ($form->{selectpaymentmethod}) {
	$form->{roundto} = $roundchange{$form->{"paymentmethod_$i"}};
      }

      $form->{paid} += $form->parse_amount($myconfig, $form->{"paid_$i"});
    }
  }
  
  if ($form->{cdt} && $form->{discount_paid}) {
    $form->{invtotal} = $form->{cd_subtotal} + $cd_tax;
    $tax = $cd_tax;
  }
  
  $form->{cd_invtotal} = $form->{cd_subtotal} + $cd_tax;

  if (!$form->{cd_amount}) {
    $form->{cd_available} = 0;
    $form->{cd_subtotal} = 0;
    $form->{cd_invtotal} = 0;
  }
  

  $form->{totaltax} = $form->format_amount($myconfig, $tax, $form->{precision}, "");

  my $whole;
  my $decimal;
  
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
  
  if ($form->{cd_amount}) {
    ($whole, $decimal) = split /\./, $form->{cd_invtotal};
    $form->{cd_decimal} = substr("${decimal}00", 0, 2);
    $form->{text_cd_decimal} = $c->num2text($form->{cd_decimal} * 1);
    $form->{text_cd_invtotal} = $c->num2text($whole);
    $form->{integer_cd_invtotal} = $whole;
  }
 
  $form->format_string(qw(text_amount text_decimal text_cd_invtotal text_cd_decimal text_out_amount text_out_decimal));

  for (qw(cd_amount paid)) { $form->{$_} = $form->format_amount($myconfig, $form->{$_}, $form->{precision}) }
  for (qw(cd_subtotal cd_invtotal invtotal subtotal total totalparts totalservices)) { $form->{$_} = $form->format_amount($myconfig, $form->{$_}, $form->{precision}, "0") }
  for (qw(totalqty totalship totalnetweight totalgrossweight)) { $form->{$_} = $form->format_amount($myconfig, $form->{$_}) }


  $dbh->disconnect;
  
}


sub delete_invoice {
  my ($self, $myconfig, $form, $spool, $dbh) = @_;

  my $disconnect;

  # connect to database, turn off autocommit
  if (! $dbh) {
    $dbh = $form->dbconnect_noauto($myconfig);
    $disconnect = 1;
  }
  
  $form->{id} *= 1;
  
  &reverse_invoice($dbh, $form);
  
  my %audittrail = ( tablename  => 'ap',
                     reference  => $form->{invnumber},
		     formname   => $form->{type},
		     action     => 'deleted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);
     
  # delete AR/AP record
  my $query = qq|DELETE FROM ap
                 WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # delete spool files
  $query = qq|SELECT spoolfile FROM status
              WHERE trans_id = $form->{id}
	      AND spoolfile IS NOT NULL|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $spoolfile;
  my @spoolfiles = ();
  
  while (($spoolfile) = $sth->fetchrow_array) {
    push @spoolfiles, $spoolfile;
  }
  $sth->finish;  

  # delete status entries
  $query = qq|DELETE FROM status
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # reset ship/received
  $query = qq|SELECT id FROM oe
              WHERE aa_id = $form->{id}|;
  
  if (my ($id) = $dbh->selectrow_array($query)) {
    $form->reset_shipped($dbh, $id, 1);

    $query = qq|UPDATE oe SET aa_id = NULL,
                closed = '0'
                WHERE aa_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }

  $form->delete_references($dbh);

  $form->remove_locks($myconfig, $dbh, 'ap');
  
  my $rc = $dbh->commit;

  if ($rc) {
    foreach $spoolfile (@spoolfiles) {
      if (-f "$spool/$myconfig->{dbname}/$spoolfile") {
	unlink "$spool/$myconfig->{dbname}/$spoolfile";
      }
    }
  }
  
  $dbh->disconnect if $disconnect;
  
  $rc;
  
}



sub post_invoice {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my $disconnect;
  
  # connect to database, turn off autocommit
  if (! $dbh) {
    $dbh = $form->dbconnect_noauto($myconfig);
    $disconnect = 1;
  }

  my $query;
  my $sth;
  my $ref;
  my $project_id;
  my $allocated;
  my $taxrate;
  my $taxamount;
  my $diff = 0;
  my $fxdiff = 0;
  my $fxtax;
  my $item;
  my $id;
  my $keepcleared;
  my $ok;
  
  (undef, $form->{employee_id}) = split /--/, $form->{employee};
  unless ($form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  }

  for (qw(department warehouse)) {
    (undef, $form->{"${_}_id"}) = split(/--/, $form->{$_});
    $form->{"${_}_id"} *= 1;
  }

  my %defaults = $form->get_defaults($dbh, \@{['fx%_accno_id', 'cdt', 'precision']});
  $form->{precision} = $defaults{precision};
  
  $query = qq|SELECT inventory_accno_id, income_accno_id, expense_accno_id
	      FROM parts
	      WHERE id = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);
  
  my %updparts = ();
  
  if ($form->{id} *= 1) {
    $keepcleared = 1;
    $query = qq|SELECT id FROM ap
		WHERE id = $form->{id}|;
    
    if ($dbh->selectrow_array($query)) {
      $query = qq|SELECT p.id, p.inventory_accno_id
                  FROM invoice i
		  JOIN parts p ON (p.id = i.parts_id)
                  WHERE i.trans_id = $form->{id}
                  AND i.assemblyitem = '0'|;
      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);
      while ($ref = $sth->fetchrow_hashref) {
	if ($ref->{inventory_accno_id}) {
	  $updparts{$ref->{id}} = 1;
	}
      }
      $sth->finish;

      &reverse_invoice($dbh, $form);
      
    } else { 
      $query = qq|INSERT INTO ap (id) 
                  VALUES ($form->{id})|;
      $dbh->do($query) || $form->dberror($query);
    } 
  }

  my $uid = localtime;
  $uid .= $$;

  if (! $form->{id}) {

    $query = qq|INSERT INTO ap (invnumber, employee_id)
                VALUES ('$uid', (SELECT id FROM employee
		                 WHERE login = '$form->{login}'))|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM ap
                WHERE invnumber = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;

  }

  if ($form->{department_id}) {
    $query = qq|INSERT INTO dpt_trans (trans_id, department_id)
                VALUES ($form->{id}, $form->{department_id})|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  my $ith;
  my $rth;
  if ($form->{warehouse_id}) {
    $query = qq|INSERT INTO inventory (warehouse_id, parts_id, trans_id,
                qty, shippingdate, employee_id)
                VALUES ($form->{warehouse_id}, ?, $form->{id},
		?, '$form->{transdate}', $form->{employee_id})|;
    $ith = $dbh->prepare($query) || $form->dberror($query);

    $query = qq|SELECT p.id, a.qty, p.assembly,
                p.inventory_accno_id, p.income_accno_id, p.expense_accno_id
                FROM assembly a
                JOIN parts p ON (a.parts_id = p.id)
                WHERE a.aid = ?|;
    $rth = $dbh->prepare($query) || $form->dberror($query);
  }

  my $amount;
  my $grossamount;
  my $allocated;
  my $invamount = 0;
  my $invnetamount = 0;
  my $lineitemdetail;

  my %p;
  my @p;
  my $d;
  my $lt;
  my $n;

  $form->{exchangerate} = $form->parse_amount($myconfig, $form->{exchangerate}) || 1;

  my $qty;
  my $sw = ($form->{type} eq 'invoice') ? 1 : -1;

  $form->{taxincluded} *= 1;
  
  for $i (1 .. $form->{rowcount}) {

    $allocated = 0;
    
    $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"}) * $sw;
    
    if ($form->{"qty_$i"}) {
      
      $pth->execute($form->{"id_$i"});
      $ref = $pth->fetchrow_hashref(NAME_lc);
      for (keys %$ref) {
	$form->{"${_}_$i"} = $ref->{$_};
      }
      $pth->finish;
      
      if ($form->{warehouse_id}) {
        if (! $form->{shipped}) {
          if ($form->{"inventory_accno_id_$i"}) {
	    $ith->execute($form->{"id_$i"}, $form->{"qty_$i"});
	    $ith->finish;
	  }
          if ($form->{"kit_$i"}) {
            $rth->execute($form->{"id_$i"});
            while ($ref = $rth->fetchrow_hashref(NAME_lc)) {
              if ($ref->{inventory_accno_id}) {
                $ith->execute($ref->{id}, $ref->{qty} * $form->{"qty_$i"});
                $ith->finish;
              }
            }
            $rth->finish;
          }
	}
      }

      # project
      $project_id = 'NULL';
      if ($form->{"projectnumber_$i"} ne "") {
	(undef, $project_id) = split /--/, $form->{"projectnumber_$i"};
      }
 
      # undo discount formatting
      $form->{"discount_$i"} = $form->parse_amount($myconfig, $form->{"discount_$i"});
      
      # keep entered selling price
      my $fxsellprice = $form->parse_amount($myconfig, $form->{"sellprice_$i"});

      my ($dec) = ($fxsellprice =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};
      
      my $discount = $form->round_amount($fxsellprice * $form->{"discount_$i"}/100, $decimalplaces);
      $form->{"discount_$i"} /= 100;

      # deduct discount
      $form->{"sellprice_$i"} = $fxsellprice - $discount;

      # linetotal
      my $fxlinetotal = $form->round_amount($form->{"sellprice_$i"} * $form->{"qty_$i"}, $form->{precision});

      $amount = $fxlinetotal * $form->{exchangerate};
      my $linetotal = $form->round_amount($amount, $form->{precision});
      $fxdiff += $form->round_amount($amount - $linetotal, 10);

      @taxaccounts = split / /, $form->{"taxaccounts_$i"};

      $ml = 1;
      $tax = 0;
      
      for (0 .. 1) {
	$taxrate = 0;
	
        # add tax rates
	for (@taxaccounts) { $taxrate += $form->{"${_}_rate"} if ($form->{"${_}_rate"} * $ml) > 0 }

	if ($form->{taxincluded}) {
	  $tax += $amount = $linetotal * ($taxrate / (1 + ($taxrate * $ml)));
	  $form->{"sellprice_$i"} -= $amount / $form->{"qty_$i"};
	  $fxtax += $fxamount = $fxlinetotal * ($taxrate / (1 + ($taxrate * $ml)));
	} else {
	  $tax += $amount = $linetotal * $taxrate;
	  $fxtax += $fxamount = $fxlinetotal * $taxrate;
	}

        for (@taxaccounts) {
	  if (($form->{"${_}_rate"} * $ml) > 0) {
	    if ($taxrate != 0) {
	      $form->{acc_trans}{$form->{id}}{$_}{amount} += $amount * $form->{"${_}_rate"} / $taxrate;
	      $form->{acc_trans}{$form->{id}}{$_}{fxamount} += $fxamount * $form->{"${_}_rate"} / $taxrate;
	    }
	  }
	}
	
	$ml = -1;
      }

      $grossamount = $form->round_amount($linetotal, $form->{precision});

      if ($form->{taxincluded}) {
	$amount = $form->round_amount($tax, $form->{precision});
	$linetotal -= $form->round_amount($tax - $diff, $form->{precision});
	$diff = ($amount - $tax);
      }
      
      
      $amount = $form->round_amount($linetotal, $form->{precision});

      # adjust and round sellprice
      $form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"} * $form->{exchangerate}, $decimalplaces);
	
      # save detail record in invoice table
      $query = qq|INSERT INTO invoice (description, trans_id, parts_id)
                  VALUES ('$uid', $form->{id}, $form->{"id_$i"})|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|SELECT id FROM invoice
                  WHERE description = '$uid'|;
      ($id) = $dbh->selectrow_array($query);

      $lineitemdetail = ($form->{"lineitemdetail_$i"}) ? 1 : 0;
      
      $query = qq|UPDATE invoice SET
		  description = |.$dbh->quote($form->{"description_$i"}).qq|,
		  qty = $form->{"qty_$i"} * -1,
		  sellprice = $form->{"sellprice_$i"},
		  fxsellprice = $fxsellprice,
		  discount = $form->{"discount_$i"},
		  allocated = $allocated,
		  unit = |.$dbh->quote($form->{"unit_$i"}).qq|,
		  deliverydate = |.$form->dbquote($form->{"deliverydate_$i"}, SQL_DATE).qq|,
		  project_id = $project_id,
		  serialnumber = |.$dbh->quote($form->{"serialnumber_$i"}).qq|,
		  ordernumber = |.$dbh->quote($form->{"ordernumber_$i"}).qq|,
		  ponumber = |.$dbh->quote($form->{"customerponumber_$i"}).qq|,
		  itemnotes = |.$dbh->quote($form->{"itemnotes_$i"}).qq|,
		  lineitemdetail = '$lineitemdetail'
		  WHERE id = $id|;
      $dbh->do($query) || $form->dberror($query);
      

      if ($form->{"inventory_accno_id_$i"}) {
        
        # add purchase to inventory
        push @{ $form->{acc_trans}{lineitems} }, {
          chart_id => $form->{"inventory_accno_id_$i"},
          amount => $amount,
          grossamount => $grossamount,
          fxamount => $fxlinetotal,
          project_id => $project_id,
          id => $id };
        
     
        $updparts{$form->{"id_$i"}} = 1;

        # update parts table
        $form->update_balance($dbh,
                              "parts",
                              "onhand",
                              qq|id = $form->{"id_$i"}|,
                              $form->{"qty_$i"}) unless $form->{shipped};
                              
        # check if we sold the item
        if ($form->{"qty_$i"} > 0) {

          $allocated = &cogs($dbh, $form, $form->{"id_$i"}, $form->{"qty_$i"}, $project_id, $i);

        } else {
         
          $allocated = &cogs_returns($dbh, $form, $form->{"id_$i"}, $form->{"qty_$i"}, $project_id, $i);

        }

        $query = qq|UPDATE invoice SET
                    allocated = $allocated
                    WHERE id = $id|;
        $dbh->do($query) || $form->dberror($query);

      } elsif ($form->{"kit_$i"}) {

        &process_kit($dbh, $form, $project_id, $i, $decimalplaces);

      } else {
	
	# add purchase to expense
	push @{ $form->{acc_trans}{lineitems} }, {
	  chart_id => $form->{"expense_accno_id_$i"},
	  amount => $amount,
	  fxamount => $fxlinetotal,
	  grossamount => $grossamount,
	  project_id => $project_id,
	  id => $id };
	
      }

      # add inventory
      $ok = ($form->{"package_$i"} ne "") ? 1 : 0;
      for (qw(netweight grossweight volume)) {
	$form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"});
	$ok = 1 if $form->{"${_}_$i"};
      }
      if ($ok) {
	$query = qq|INSERT INTO cargo (id, trans_id, package, netweight,
	            grossweight, volume) VALUES ($id, $form->{id}, |
		    .$dbh->quote($form->{"package_$i"}).qq|,
		    $form->{"netweight_$i"} * 1, $form->{"grossweight_$i"} * 1,
		    $form->{"volume_$i"} * 1)|;
        $dbh->do($query) || $form->dberror($query);
      }
     
      $query = qq|UPDATE parts SET
		  bin = |.$dbh->quote($form->{"bin_$i"});
      if ($form->{"netweight_$i"} * 1) {
	my $weight = abs($form->{"netweight_$i"} / $form->{"qty_$i"});
	$query .= qq|, weight = $weight|;
      }
      $query .= qq|
		  WHERE id = $form->{"id_$i"}|;
      $dbh->do($query) || $form->dberror($query);

    }
  }

  $form->{paid} = 0;
  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      $form->{"paid_$i"} = $form->parse_amount($myconfig, $form->{"paid_$i"}) * $sw;
      $form->{paid} += $form->{"paid_$i"};
      $form->{datepaid} = $form->{"datepaid_$i"};
    }
  }

  # add lineitems + tax
  $amount = 0;
  $grossamount = 0;
  $fxamount = 0;
  for $ref (@{ $form->{acc_trans}{lineitems} }) {
    $amount += $ref->{amount};
    $grossamount += $ref->{grossamount};
    $fxamount += $ref->{fxamount};
  }
  $invnetamount = $amount;

  $amount = 0;
  for (split / /, $form->{taxaccounts}) {
    $form->{acc_trans}{$form->{id}}{$_}{amount} = $form->round_amount($form->{acc_trans}{$form->{id}}{$_}{amount}, 10);
    
    $amount += $form->{acc_trans}{$form->{id}}{$_}{amount} = $form->round_amount($form->{acc_trans}{$form->{id}}{$_}{amount}, $form->{precision});
    $form->{acc_trans}{$form->{id}}{$_}{amount} *= -1;
  }
  $invamount = $invnetamount + $amount;

  $diff = 0;
  if ($form->{taxincluded}) {
    $diff = $form->round_amount($grossamount - $invamount, $form->{precision});
    $invamount += $diff;
  }
  $fxdiff = 0 if $form->{rowcount} == 2;
  $fxdiff = $form->round_amount($fxdiff, $form->{precision});
  $invnetamount += $fxdiff;
  $invamount += $fxdiff;

  $fxtax = $form->round_amount($fxtax, $form->{precision});

  if ($form->round_amount($form->{paid} - ($fxamount + $fxtax), $form->{precision}) == 0) {
    $form->{paid} = $invamount;
  } else {
    $form->{paid} = $form->round_amount($form->{paid} * $form->{exchangerate}, $form->{precision});
  }
 
  foreach $ref (sort { $b->{amount} <=> $a->{amount} } @ { $form->{acc_trans}{lineitems} }) {
    if ($amount = $ref->{amount} + $diff + $fxdiff) {
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
                  transdate, project_id, id)
                  VALUES ($form->{id}, $ref->{chart_id}, $amount * -1,
                  '$form->{transdate}', $ref->{project_id}, $ref->{id})|;
      $dbh->do($query) || $form->dberror($query);
    }
    $diff = 0;
    $fxdiff = 0;
  }

  $form->{payables} = $invamount;
  
  delete $form->{acc_trans}{lineitems};
  
  # update exchangerate
  $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, $form->{exchangerate});
  
  my $accno;
  my ($apaccno) = split /--/, $form->{AP};
  
  # record payable
  if ($form->{payables}) {
    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
                transdate)
                VALUES ($form->{id},
		       (SELECT id FROM chart
		       WHERE accno = '$apaccno'),
                $form->{payables}, '$form->{transdate}')|;
    $dbh->do($query) || $form->dberror($query);
  }

  $i = $form->{discount_index};
  
  if ($form->{"paid_$i"} && $defaults{cdt}) {

    my $roundamount;
    $tax = 0;
    $fxtax = 0;
    
    $form->{"exchangerate_$i"} = $form->parse_amount($myconfig, $form->{"exchangerate_$i"}) || 1;

    # update exchangerate
    $form->update_exchangerate($dbh, $form->{currency}, $form->{"datepaid_$i"}, $form->{"exchangerate_$i"});
   
    # calculate tax difference
    my $discount = 0;
    if ($fxamount) {
      $discount = $form->{"paid_$i"} / $fxamount;
    }
    
    $diff = 0;
    $fxdiff = 0;

    for (split / /, $form->{taxaccounts}) {
      $fxtax = $form->round_amount($form->{acc_trans}{$form->{id}}{$_}{fxamount} * $discount, $form->{precision});

      $amount = $fxtax * $form->{"exchangerate_$i"};

      $tax += $roundamount = $form->round_amount($amount, $form->{precision});
      $diff += $amount - $roundamount;

      push @{ $form->{acc_trans}{taxes} }, {
	accno => $_,
	amount => $roundamount * -1,
	transdate => $form->{"datepaid_$i"},
	id => $form->{id} };

    }

    $diff = $form->round_amount($diff, $form->{precision});
    if ($diff != 0) {
      my $n = $#{$form->{acc_trans}{taxes}};
      $form->{acc_trans}{taxes}[$n]{amount} -= $diff;
    }

    push @{ $form->{acc_trans}{taxes} }, {
      accno => $apaccno,
      amount => $tax,
      transdate => $form->{"datepaid_$i"},
      id => 'NULL' };

    $cd_tax = $tax;
    
    foreach $ref (@{ $form->{acc_trans}{taxes} }) {
      $ref->{amount} = $form->round_amount($ref->{amount}, $form->{precision});
      if ($ref->{amount}) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate, id)
	            VALUES ($form->{id},
		           (SELECT id FROM chart
			    WHERE accno = '$ref->{accno}'),
                    $ref->{amount} * -1, '$ref->{transdate}',
		    $ref->{id})|;
        $dbh->do($query) || $form->dberror($query);
      }
    }

    delete $form->{acc_trans}{taxes};
    
  }
   

  foreach my $trans_id (keys %{$form->{acc_trans}}) {
    foreach $accno (keys %{ $form->{acc_trans}{$trans_id} }) {
      $amount = $form->round_amount($form->{acc_trans}{$trans_id}{$accno}{amount}, $form->{precision});
      if ($amount) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate)
	            VALUES ($trans_id, (SELECT id FROM chart
		                        WHERE accno = '$accno'),
                    $amount, '$form->{transdate}')|;
        $dbh->do($query) || $form->dberror($query);
      }
    }
  }

  # if there is no amount but a payment record payable
  if ($invamount == 0) {
    $form->{payables} = 1;
  }

  my $cleared = 'NULL';
  my $voucherid;
  my $approved;
  my $paymentid = 1;
  my $paymentaccno;
  my $paymentmethod_id;
  
  # record payments and offsetting AP
  for $i (1 .. $form->{paidaccounts}) {

    if ($form->{"paid_$i"}) {
      ($accno) = split /--/, $form->{"AP_paid_$i"};

      (undef, $paymentmethod_id) = split /--/, $form->{"paymentmethod_$i"};
      $paymentmethod_id *= 1;
      
      $paymentaccno = $accno;
      $form->{"datepaid_$i"} = $form->{transdate} unless ($form->{"datepaid_$i"});
      $form->{datepaid} = $form->{"datepaid_$i"};

      $form->{"exchangerate_$i"} = $form->parse_amount($myconfig, $form->{"exchangerate_$i"}) || 1;

      # update exchangerate
      $form->update_exchangerate($dbh, $form->{currency}, $form->{"datepaid_$i"}, $form->{"exchangerate_$i"});

      # record AP
      $amount = ($form->round_amount($form->{"paid_$i"} * $form->{exchangerate}, $form->{precision})) * -1;

      $voucherid = 'NULL';
      $approved = 1;

      # add voucher for payment
      if ($form->{voucher}{payment}{$voucherid}{br_id}) {
	if ($form->{"vr_id_$i"}) {

	  $voucherid = $form->{"vr_id_$i"};
	  $approved = $form->{voucher}{payment}{$voucherid}{approved} * 1;

	  if ($i != $form->{discount_index}) {
	    $query = qq|INSERT INTO vr (br_id, trans_id, id, vouchernumber)
			VALUES ($form->{voucher}{payment}{$voucherid}{br_id},
			$form->{id}, $voucherid, |.
			$dbh->quote($form->{voucher}{payment}{$voucherid}{vouchernumber}).qq|)|;
	    $dbh->do($query) || $form->dberror($query);

	    $form->update_balance($dbh,
				  'br',
				  'amount',
				  qq|id = $form->{voucher}{payment}{$voucherid}{br_id}|,
				  $amount * -1);
	  }
	}
      }
      

      if ($form->{payables}) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate, approved, vr_id)
		    VALUES ($form->{id}, (SELECT id FROM chart
					WHERE accno = '$apaccno'),
		    $amount, '$form->{"datepaid_$i"}',
		    '$approved', $voucherid)|;
	$dbh->do($query) || $form->dberror($query);
      }

      if ($keepcleared) {
	$cleared = $form->dbquote($form->{"cleared_$i"}, SQL_DATE);
      }

      # record payment
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
                  source, memo, cleared, approved, vr_id, id)
                  VALUES ($form->{id}, (SELECT id FROM chart
		                      WHERE accno = '$paymentaccno'),
                  $form->{"paid_$i"}, '$form->{"datepaid_$i"}', |
		  .$dbh->quote($form->{"source_$i"}).qq|, |
		  .$dbh->quote($form->{"memo_$i"}).qq|, $cleared,
		  '$approved', $voucherid, $paymentid)|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|INSERT INTO payment (id, trans_id, exchangerate,
                  paymentmethod_id)
                  VALUES ($paymentid, $form->{id}, $form->{"exchangerate_$i"},
		  $paymentmethod_id)|;
      $dbh->do($query) || $form->dberror($query);

      $paymentid++;

      # exchangerate difference
      $amount = $form->round_amount($form->{"paid_$i"} * $form->{"exchangerate_$i"} - $form->{"paid_$i"}, $form->{precision});
      
      if ($amount) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate, source, fx_transaction, cleared, approved, vr_id)
	            VALUES ($form->{id}, (SELECT id FROM chart
		                        WHERE accno = '$paymentaccno'),
		    $amount, '$form->{"datepaid_$i"}', |
		    .$dbh->quote($form->{"source_$i"}).qq|, '1', $cleared,
		    '$approved', $voucherid)|;
        $dbh->do($query) || $form->dberror($query);
      }
 
      # gain/loss
      $amount = $form->round_amount($form->round_amount($form->{"paid_$i"} * $form->{exchangerate}, $form->{precision}) - $form->round_amount($form->{"paid_$i"} * $form->{"exchangerate_$i"}, $form->{precision}), $form->{precision});
      
      if ($amount) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate, fx_transaction, cleared, approved, vr_id)
	            VALUES ($form->{id}, $defaults{fxgainloss_accno_id},
		    $amount, '$form->{"datepaid_$i"}', '1', $cleared,
		    '$approved', $voucherid)|;
        $dbh->do($query) || $form->dberror($query);
      }
    }
  }
  
  ($paymentaccno) = split /--/, $form->{"AP_paid_$form->{paidaccounts}"};
  
  (undef, $paymentmethod_id) = split /--/, $form->{"paymentmethod_$form->{paidaccounts}"};
  $paymentmethod_id *= 1;
  
  $form->{invnumber} = $form->update_defaults($myconfig, "vinumber", $dbh) unless $form->{invnumber};
  $form->{duedate} ||= $form->{transdate};

  for (qw(terms discountterms onhold)) { $form->{$_} *= 1 }
  $form->{cashdiscount} = $form->parse_amount($myconfig, $form->{cashdiscount}) / 100;

  if ($form->{cdt} && $form->{"paid_$form->{discount_index}"}) {
    $invamount -= $cd_tax if !$form->{taxincluded};
  }
  
  # save AP record
  $query = qq|UPDATE ap set
              invnumber = |.$dbh->quote($form->{invnumber}).qq|,
              description = |.$dbh->quote($form->{description}).qq|,
	      ordnumber = |.$dbh->quote($form->{ordnumber}).qq|,
	      quonumber = |.$dbh->quote($form->{quonumber}).qq|,
              transdate = '$form->{transdate}',
              vendor_id = $form->{vendor_id},
              amount = $invamount,
              netamount = $invnetamount,
              paid = $form->{paid},
	      datepaid = |.$form->dbquote($form->{datepaid}, SQL_DATE).qq|,
	      duedate = |.$form->dbquote($form->{duedate}, SQL_DATE).qq|,
	      invoice = '1',
	      shippingpoint = |.$dbh->quote($form->{shippingpoint}).qq|,
	      shipvia = |.$dbh->quote($form->{shipvia}).qq|,
	      waybill = |.$dbh->quote($form->{waybill}).qq|,
	      terms = $form->{terms},
	      taxincluded = '$form->{taxincluded}',
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      intnotes = |.$dbh->quote($form->{intnotes}).qq|,
	      curr = '$form->{currency}',
	      department_id = $form->{department_id},
	      employee_id = $form->{employee_id},
	      language_code = '$form->{language_code}',
	      ponumber = |.$dbh->quote($form->{ponumber}).qq|,
	      cashdiscount = $form->{cashdiscount},
	      discountterms = $form->{discountterms},
	      onhold = '$form->{onhold}',
	      warehouse_id = $form->{warehouse_id},
	      exchangerate = $form->{exchangerate},
	      dcn = |.$dbh->quote($form->{dcn}).qq|,
	      bank_id = (SELECT id FROM chart WHERE accno = '$paymentaccno'),
	      paymentmethod_id = $paymentmethod_id
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # add shipto
  $form->{name} = $form->{vendor};
  $form->{name} =~ s/--$form->{vendor_id}//;
  $form->add_shipto($dbh, $form->{id});

  # save printed, emailed and queued
  $form->save_status($dbh);
  
  # save reference documents
  $form->save_reference($dbh, "ap_$form->{type}");

  # add link for order
  if ($form->{order_id}) {
    $query = qq|UPDATE oe SET aa_id = $form->{id}
		WHERE id = $form->{order_id}|;
    $dbh->do($query) || $form->dberror($query);
  }
				
  my %audittrail = ( tablename  => 'ap',
                     reference  => $form->{invnumber},
		     formname   => $form->{type},
		     action     => 'posted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);

  $form->save_recurring($dbh, $myconfig);

  $form->remove_locks($myconfig, $dbh, 'ap');

  my $rc = $dbh->commit;

  $query = qq|UPDATE parts SET
	      avgcost = ?,
	      lastcost = ?
	      WHERE id = ?|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT sellprice
              FROM invoice i
	      JOIN ap a ON (a.id = i.trans_id)
	      WHERE i.parts_id = ?
	      ORDER BY a.transdate DESC, a.id DESC
	      LIMIT 1|;
  my $lth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT SUM(i.sellprice * i.qty), SUM(i.qty)
              FROM invoice i
	      JOIN ap a ON (a.id = i.trans_id)
	      WHERE i.parts_id = ?|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);
  
  for my $item (keys %updparts) {
    $ath->execute($item) || $form->dberror;
    my ($cost, $qty) = $ath->fetchrow_array;
    $ath->finish;
    $avgcost = 0;
    if ($qty) {
      $avgcost = $form->round_amount($cost / $qty, $form->{precision});
    }
    
    $lth->execute($item) || $form->dberror;
    my ($lastcost) = $lth->fetchrow_array;
    $lastcost *= 1;
    $lth->finish;

    $sth->execute($avgcost, $lastcost, $item) || $form->dberror;
    $sth->finish;
    
    $dbh->commit;
  }
  
  $dbh->disconnect if $disconnect;
  
  $rc;
  
}


sub process_kit {
  my ($dbh, $form, $project_id, $i, $decimalplaces) = @_;

  my %p;
  my @p;
  my $sellprice;
  my %sellprice;
  my $amount;
  my $grossamount;
  my $tax;
  my $taxrate;
  my %taxbase;
  my $id;
  my $uid = localtime;
  $uid .= $$;
  my $accno;
  my %kit;
  my $ref;
  my $j = 0;
  my $diff;

  my $query = qq|SELECT a.parts_id, a.qty, p.assembly,
                 p.partnumber, p.description, p.unit,
                 p.inventory_accno_id, p.income_accno_id,
		 p.expense_accno_id
                 FROM assembly a
		 JOIN parts p ON (a.parts_id = p.id)
		 WHERE a.aid = $form->{"id_$i"}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  for my $item (split / /, $form->{"kit_$i"}) {
    @p = split /:/, $item;
    $sellprice{$p[0]} = $p[2];
  }

  $query = qq|SELECT c.accno
              FROM chart c
              JOIN partstax t ON (t.chart_id = c.id)
              WHERE t.parts_id = ?|;
  my $tth = $dbh->prepare($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    $j++;
    $kit{$j}{allocated} = 0;
    
    for (qw(parts_id description unit qty inventory_accno_id expense_accno_id)) { $kit{$j}{$_} = $ref->{$_} }

    if ($ref->{inventory_accno_id}) {
      if ($form->{"qty_$i"} > 0) {
        $kit{$j}{allocated} = &cogs($dbh, $form, $ref->{parts_id}, $ref->{qty} * $form->{"qty_$i"}, $project_id);
      } elsif ($form->{"qty_$i"} < 0) {
        $kit{$j}{allocated} = &cogs_returns($dbh, $form, $ref->{parts_id}, $ref->{qty} * $form->{"qty_$i"}, $project_id, $i);
      }
    }

    if ($ref->{inventory_accno_id}) {
      # update onhand
      $form->update_balance($dbh,
                            "parts",
                            "onhand",
                            qq|id = $ref->{parts_id}|,
                            $ref->{qty} * $form->{"qty_$i"}) unless $form->{shipped};
    }

    $kit{$j}{sellprice} = $sellprice{$ref->{parts_id}};

    %p = split /[: ]/, $form->{"pricematrix_$i"};
    if ($p{0}) {
      $kit{$j}{sellprice} = $form->round_amount($sellprice{$ref->{parts_id}} * $form->{"sellprice_$i"}/$p{0}, $decimalplaces);
    }

    $kit{$j}{linetotal} = $form->round_amount($kit{$j}{sellprice} * $kit{$j}{qty} * $form->{"qty_$i"}, $form->{precision});

    # get tax accounts
    $tth->execute($ref->{parts_id});
    while (($accno) = $tth->fetchrow_array) {
      $kit{$j}{$accno} = 1;
    }
    $tth->finish;

  }

  $sth->finish;

  # check total against sellprice
  $amount = 0;
  $j = 0;
  for (keys %kit) {
    $j++;
    $amount += $kit{$_}{sellprice} * $kit{$_}{qty};
  }
  if ($diff = $form->round_amount($form->{"sellprice_$i"} - $amount, $form->{precision})) {
    $sellprice = 0;
    $j = 1;
    for (keys %kit) {
      if ($kit{$_}{sellprice} > $sellprice) {
        $sellprice = $kit{$_}{sellprice};
        $j = $_;
      }
    }
    $kit{$j}{sellprice} += $diff;
  }

  my @t = split / /, $form->{taxaccounts};
  $diff = 0;

  for (keys %kit) {

    $tax = 0;
    $taxrate = 0;

    for $accno (@t) {
      if ($kit{$_}{$accno}) {
        if ($form->{"${accno}_rate"}) {
          if ($form->{taxincluded}) {
            $taxrate += $form->{"${accno}_rate"};
          } else {
            $tax += $kit{$_}{sellprice} * $form->{"${accno}_rate"};
          }
          $taxbase{$accno} += $kit{$_}{linetotal};
        }
      }
    }

    if ($form->{taxincluded}) {
      $tax = $kit{$_}{sellprice} * $taxrate / (1 + $taxrate);

      $grossamount = $form->round_amount($kit{$_}{sellprice} * $kit{$_}{qty} * $form->{"qty_$i"}, $form->{precision});
      $amount = $grossamount - $form->round_amount($tax * $kit{$_}{qty} * $form->{"qty_$i"}, $form->{precision});
    } else {

      $amount = $form->round_amount($kit{$_}{sellprice} * $kit{$_}{qty} * $form->{"qty_$i"}, $form->{precision});
      $grossamount = $amount + $form->round_amount($tax * $kit{$_}{qty} * $form->{"qty_$i"}, $form->{precision});
    }

    $tax = $form->round_amount($tax, $form->{precision});
    $sellprice = $kit{$_}{sellprice};
    if ($form->{taxincluded}) {
      $sellprice = $form->round_amount($kit{$_}{sellprice} - $tax, $form->{precision});
    }

    # save detail record in invoice table
    $query = qq|INSERT INTO invoice (description, trans_id, parts_id)
                VALUES ('$uid', $form->{id}, $kit{$_}{parts_id})|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT id
                FROM invoice
                WHERE description = '$uid'|;
    ($id) = $dbh->selectrow_array($query);
 
    # save detail record for individual kit item in invoice table
    $query = qq|UPDATE invoice SET
                description = |.$dbh->quote($kit{$_}{description}).qq|,
                qty = $kit{$_}{qty} * $form->{"qty_$i"} * -1,
                sellprice = $sellprice,
                fxsellprice = 0,
                allocated = $kit{$_}{allocated},
                assemblyitem = '1',
                kititem = '1',
                discount = $form->{"discount_$i"},
                unit = |.$dbh->quote($kit{$_}{unit}).qq|
                WHERE id = $id|;
    $dbh->do($query) || $form->dberror($query);

    # add inventory/expense
    if ($amount) {
      if ($kit{$_}{inventory_accno_id}) {
        push @{ $form->{acc_trans}{lineitems} }, {
          chart_id => $kit{$_}{inventory_accno_id},
          amount => $amount,
          grossamount => $grossamount,
          fxamount => $amount,
          project_id => $project_id,
          id => $id };
      } else {
        push @{ $form->{acc_trans}{lineitems} }, {
          chart_id => $kit{$_}{expense_accno_id},
          amount => $amount,
          grossamount => $grossamount,
          fxamount => $amount,
          project_id => $project_id,
          id => $id };
      }
    }

  }

  for $accno (@t) {
    if ($form->{"${accno}_rate"}) {
      if ($form->{taxincluded}) {
        $amount = $taxbase{$accno} * $form->{"${accno}_rate"} / (1 + $form->{"${accno}_rate"});
      } else {
        $amount = $taxbase{$accno} * $form->{"${accno}_rate"};
      }
      $amount = $form->round_amount($amount, $form->{precision});
      $form->{acc_trans}{$form->{id}}{$accno}{amount} += $amount;
      $form->{acc_trans}{$form->{id}}{$accno}{fxamount} += $amount;
    }
  }

}


sub cogs {
  my ($dbh, $form, $id, $totalqty, $project_id, $i) = @_;

  my $query;
  my $sth;

  $query = qq|SELECT i.id, i.qty, i.allocated, i.trans_id, i.project_id,
              p.inventory_accno_id, p.expense_accno_id
              FROM invoice i
              JOIN parts p ON (p.id = i.parts_id)
              WHERE i.parts_id = $id
              AND (i.qty + i.allocated) > 0
              ORDER BY i.trans_id|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $linetotal;
  my $allocated = 0;
  my $qty;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    $qty = $ref->{qty} + $ref->{allocated};

    if (($qty - $totalqty) > 0) {
      $qty = $totalqty;
    }

    $linetotal = $form->round_amount($form->{"sellprice_$i"} * $qty, $form->{precision});
    $ref->{project_id} ||= 'NULL';

    # add entry for inventory, this one is for the sold item
    if ($linetotal) {
      # credit inventory
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, 
                  transdate, project_id, id)
                  VALUES ($ref->{trans_id}, $ref->{inventory_accno_id},
                  $linetotal, '$form->{transdate}', $ref->{project_id},
                  $id)|;
      $dbh->do($query) || $form->dberror($query);

      # add cogs
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, 
                  transdate, project_id, id)
                  VALUES ($ref->{trans_id}, $ref->{expense_accno_id},
                  $linetotal * -1, '$form->{transdate}',
                  $ref->{project_id}, $id)|;
      $dbh->do($query) || $form->dberror($query);
    }

    # update allocated for sold item
    $form->update_balance($dbh,
                          "invoice",
                          "allocated",
                          qq|id = $ref->{id}|,
                          $qty * -1);
    
    $allocated += $qty;

    last if (($totalqty -= $qty) <= 0);
  }

  $sth->finish;

  $allocated;
 
}


sub cogs_returns {
  my ($dbh, $form, $id, $totalqty, $project_id, $i) = @_;

  my $query;
  my $sth;

  my $linetotal;
  my $qty;
  my $ref;

  $totalqty *= -1;
  my $allocated = 0;

  # returned item, check if we can allocate purchases
  $query = qq|SELECT i.id, i.qty, i.allocated, i.trans_id
              FROM invoice i
              WHERE i.parts_id = $id
              AND (i.qty + i.allocated) < 0
              ORDER BY i.trans_id|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    $qty = ($ref->{qty} + $ref->{allocated}) * -1;

    if (($qty - $totalqty) > 0) {
      $qty = $totalqty;
    }

    # update allocated for sold item
    $form->update_balance($dbh,
                          "invoice",
                          "allocated",
                          qq|id = $ref->{id}|,
                          $qty);
    
    $allocated += $qty;

    last if (($totalqty -= $qty) <= 0);
  }
  $sth->finish;

  $allocated *= -1;
    
}


sub reverse_invoice {
  my ($dbh, $form) = @_;
  
  my $query = qq|SELECT id FROM ap
		 WHERE id = $form->{id}|;
  my ($id) = $dbh->selectrow_array($query);

  return unless $id;
  
  # reverse inventory items
  $query = qq|SELECT i.parts_id, i.qty, i.allocated, i.sellprice, i.project_id,
              i.kititem, p.inventory_accno_id, p.expense_accno_id, p.obsolete
              FROM invoice i
	      JOIN parts p ON (p.id = i.parts_id)
	      WHERE i.parts_id = p.id
              AND i.trans_id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $query = qq|UPDATE parts SET obsolete = '0'
              WHERE id = ?|;
  my $oth = $dbh->prepare($query);

  my $amount;
  my $netamount = 0;

  my $ref;
  my $pref;
  my $qty;
  my $totalqty;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $netamount += $form->round_amount($ref->{sellprice} * $ref->{qty} * -1, $form->{precision});

    if ($ref->{obsolete}) {
      $oth->execute($ref->{parts_id});
      $oth->finish;
    }

    if ($ref->{inventory_accno_id}) {
      # update onhand
      $form->update_balance($dbh,
                            "parts",
			    "onhand",
			    qq|id = $ref->{parts_id}|,
			    $ref->{qty});
    }
      
    next if $ref->{allocated} == 0;

    # we sold that many items
    if ($ref->{allocated} > 0) {

      # get references for sold items
      $query = qq|SELECT i.id, i.trans_id, i.allocated
                  FROM invoice i
                  WHERE i.parts_id = $ref->{parts_id}
                  AND i.allocated < 0
                  ORDER BY i.trans_id DESC|;
      my $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);

      $totalqty = $ref->{allocated};
      
      while ($pref = $sth->fetchrow_hashref(NAME_lc)) {
        
        $qty = $totalqty;
       
        if ($qty > ($pref->{allocated} * -1)) {
          $qty = $pref->{allocated} * -1;
        }

        $amount = $form->round_amount($ref->{sellprice} * $qty, $form->{precision});

        #adjust allocated
        $form->update_balance($dbh,
                              "invoice",
                              "allocated",
                              qq|id = $pref->{id}|,
                              $qty);

        # add reversal for sale
        $ref->{project_id} ||= 'NULL';
        $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, 
                    transdate, project_id)
                    VALUES ($pref->{trans_id}, $ref->{expense_accno_id},
                    $amount, '$form->{transdate}', $ref->{project_id})|;
        $dbh->do($query) || $form->dberror($query);
        
        $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, 
                    transdate, project_id)
                    VALUES ($pref->{trans_id}, $ref->{inventory_accno_id},
                    $amount * -1, '$form->{transdate}', $ref->{project_id})|;
        $dbh->do($query) || $form->dberror($query);

        last if (($totalqty -= $qty) <= 0);
        
      }
      $sth->finish;
      
    } else {
      
      # get references for bought items
      $query = qq|SELECT i.id, i.trans_id, i.allocated
                  FROM invoice i
                  WHERE i.parts_id = $ref->{parts_id}
                  AND i.allocated > 0
                  ORDER BY i.trans_id DESC|;
      my $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);

      $totalqty = $ref->{allocated} * -1;
      
      while ($pref = $sth->fetchrow_hashref(NAME_lc)) {
        
        $qty = $totalqty;
       
        if ($qty > $pref->{allocated}) {
          $qty = $pref->{allocated};
        }

        #adjust allocated
        $form->update_balance($dbh,
                              "invoice",
                              "allocated",
                              qq|id = $pref->{id}|,
                              $qty * -1);

        last if (($totalqty -= $qty) <= 0);
        
      }
      $sth->finish;

    }
  }
  $sth->finish;


  # get voucher id for payments
  $query = qq|SELECT DISTINCT * FROM vr
              WHERE trans_id = $form->{id}|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  my %defaults = $form->get_defaults($dbh, \@{['fx%_accno_id']});
  
  $query = qq|SELECT SUM(ac.amount), ac.approved
              FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      WHERE ac.trans_id = $form->{id}
	      AND ac.vr_id = ?
	      AND c.link LIKE '%AP_paid%'
	      AND NOT ac.chart_id = $defaults{fxgainloss_accno_id}
              GROUP BY ac.approved|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);

  $sth->execute || $form->dberror($query);

  my $approved;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    $form->{voucher}{payment}{$ref->{id}} = $ref;

    $ath->execute($ref->{id});
    ($amount, $approved) = $ath->fetchrow_array;
    $ath->finish;

    $form->{voucher}{payment}{$ref->{id}}{approved} = $approved;

    $amount = $form->round_amount($amount, $form->{precision});

    $form->update_balance($dbh,
                          'br',
			  'amount',
			  qq|id = $ref->{br_id}|,
			  $amount * -1);
  }
  $sth->finish;
  
  
  for (qw(acc_trans dpt_trans invoice inventory shipto cargo vr payment)) {
    $query = qq|DELETE FROM $_ WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  for (qw(recurring recurringemail recurringprint)) {
    $query = qq|DELETE FROM $_ WHERE id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }

} 


sub retrieve_invoice {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  
  my %defaults = $form->get_defaults($dbh, \@{['%accno_id']});

  $form->{currencies} = $form->get_currencies($myconfig, $dbh);
  
  # get default accounts and last invoice number
  for (qw(inventory_accno income_accno expense_accno fxgainloss_accno)) {
    $query = qq|SELECT accno FROM chart
		WHERE id = $defaults{"${_}_id"}|;
    ($form->{$_}) = $dbh->selectrow_array($query);
  }
  

  if ($form->{id} *= 1) {
    
    # retrieve invoice
    $query = qq|SELECT a.invnumber, a.ordnumber, a.quonumber,
                a.transdate, a.amount, a.netamount, a.paid,
		a.shippingpoint, a.shipvia, a.waybill,
		a.cashdiscount, a.discountterms, a.terms,
		a.notes, a.intnotes,
		a.duedate, a.taxincluded, a.curr AS currency,
		a.employee_id, e.name AS employee, a.vendor_id,
		a.language_code, a.ponumber,
		a.warehouse_id, w.description AS warehouse,
		a.exchangerate,
		c.accno AS bank_accno, c.description AS bank_accno_description,
		t.description AS bank_accno_translation,
		pm.description AS paymentmethod, a.paymentmethod_id
		FROM ap a
		LEFT JOIN employee e ON (e.id = a.employee_id)
		LEFT JOIN warehouse w ON (a.warehouse_id = w.id)
		LEFT JOIN chart c ON (c.id = a.bank_id)
		LEFT JOIN translation t ON (t.trans_id = c.id AND t.language_code = '$myconfig->{countrycode}')
		LEFT JOIN paymentmethod pm ON (pm.id = a.paymentmethod_id)
		WHERE a.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $sth->finish;
    
    $form->{warehouse_id} *= 1;
    $query = qq|SELECT SUM(qty)
                FROM inventory
                WHERE parts_id = ?
                AND warehouse_id = $form->{warehouse_id}|;
    my $wth = $dbh->prepare($query) || $form->dberror($query);

    $form->{payment_accno} = "";
    if ($form->{bank_accno}) {
      $form->{payment_accno} = ($form->{bank_accno_translation}) ? "$form->{bank_accno}--$form->{bank_accno_translation}" : "$form->{bank_accno}--$form->{bank_accno_description}";
    }
    
    $form->{payment_method} = "";
    if ($form->{paymentmethod_id}) {
      $form->{payment_method} = "$form->{paymentmethod}--$form->{paymentmethod_id}";
    }
    
    $form->{type} = ($form->{amount} < 0) ? 'debit_invoice' : 'invoice';
    $form->{formname} = $form->{type};

    # get shipto
    $query = qq|SELECT * FROM shipto
                WHERE trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $sth->finish;
    
    # retrieve individual items
    $query = qq|SELECT
		p.partnumber, i.description, i.qty, i.fxsellprice, i.sellprice,
		i.parts_id AS id, i.unit, p.bin, i.deliverydate,
		pr.projectnumber,
                i.project_id, i.serialnumber, i.ordernumber,
		i.ponumber AS customerponumber,
		i.discount, i.itemnotes, i.lineitemdetail,
		p.partnumber AS sku, pg.partsgroup, p.partsgroup_id,
		i.fxsellprice AS sell, p.weight, p.onhand,
		p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		t.description AS partsgrouptranslation,
		c.package, c.netweight, c.grossweight, c.volume
		FROM invoice i
		JOIN parts p ON (i.parts_id = p.id)
		LEFT JOIN project pr ON (i.project_id = pr.id)
		LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
		LEFT JOIN translation t ON (t.trans_id = p.partsgroup_id AND t.language_code = '$form->{language_code}')
		LEFT JOIN cargo c ON (c.id = i.id AND c.trans_id = i.trans_id)
		WHERE i.trans_id = $form->{id}
                AND NOT i.assemblyitem = '1'
		ORDER BY i.id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    # exchangerate defaults
    $form->exchangerate_defaults($dbh, $myconfig, $form);

    # price matrix and vendor partnumber
    my $pmh = PM->price_matrix_query($dbh, $form);

    # tax rates for part
    $query = qq|SELECT c.accno
		FROM chart c
		JOIN partstax pt ON (pt.chart_id = c.id)
		WHERE pt.parts_id = ?|;
    my $tth = $dbh->prepare($query);

    my $taxrate;
    my $ptref;

    $query = qq|SELECT p.id, i.sellprice, a.qty,
                i.discount
                FROM assembly a
                JOIN parts p ON (p.id = a.parts_id)
                JOIN invoice i ON (i.parts_id = p.id)
                WHERE i.trans_id = $form->{id}
                AND a.aid = ?|;
    my $ath = $dbh->prepare($query) || $form->dberror($query);

    my $aref;

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

      my ($dec) = ($ref->{fxsellprice} =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

      $tth->execute($ref->{id});
      $ref->{taxaccounts} = "";
      my $taxrate = 0;
      
      while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
        $ref->{taxaccounts} .= "$ptref->{accno} ";
        $taxrate += $form->{"$ptref->{accno}_rate"};
      }
      
      $tth->finish;
      chop $ref->{taxaccounts};

      if ($form->{warehouse_id}) {
        $wth->execute($ref->{id});
        $ref->{onhand} = $wth->fetchrow_array;
        $wth->finish;
      }

      $ref->{sellprice} = $form->round_amount($ref->{fxsellprice} * $form->{$form->{currency}}, $decimalplaces);

      # price matrix
      PM->price_matrix($pmh, $ref, undef, $decimalplaces, $form);

      $ref->{sellprice} = $ref->{fxsellprice};
      $ref->{qty} *= -1;

      my %p = split /[ :]/, $ref->{pricematrix};
      $p{0} = $ref->{sellprice};
      $ref->{pricematrix} = "";
      for (sort keys %p) {
        $ref->{pricematrix} .= "$_:$p{$_} ";
      }
      chop $ref->{pricematrix};

      $ref->{partsgroup} = $ref->{partsgrouptranslation} if $ref->{partsgrouptranslation};

      # retrieve kit prices and tax accounts
      unless ($ref->{inventory_accno_id} + $ref->{income_accno_id} + $ref->{expense_accno_id}) {

        my $accno;
        my $taxrate;

        $ath->execute($ref->{id});
        while ($aref = $ath->fetchrow_hashref(NAME_lc)) {
          $tth->execute($aref->{id});
          $accno = "";
          $taxrate = 0;
          while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
            $accno .= ":$ptref->{accno}";
            if ($form->{taxincluded}) {
              if ($form->{"$ptref->{accno}_rate"}) {
                $taxrate += $form->{"$ptref->{accno}_rate"};
              }
            }
          }
          $tth->finish;

          $aref->{sellprice} *= (1 + $taxrate);

          if ($aref->{discount} != 1) {
            $aref->{sellprice} = $form->round_amount($aref->{sellprice}/(1 - $aref->{discount}), $form->{precision});
          }

          $aref->{sellprice} = $form->round_amount($aref->{sellprice}/$form->{$form->{currency}}, $form->{precision});

          $ref->{kit} .= "$aref->{id}:$aref->{qty}:$aref->{sellprice}$accno ";
        }
        chop $ref->{kit};
        $ath->finish;
      }

      push @{ $form->{invoice_details} }, $ref;
    }
    $sth->finish;
    
  } else {
    $form->{transdate} = $form->current_date($myconfig);
  }
  
  
  $dbh->disconnect;
  
}


sub retrieve_item {
  my ($self, $myconfig, $form) = @_;

  my $i = $form->{rowcount};
  my $id;
  my $var;
  
  # don't include assemblies or obsolete parts
  my $where = qq|WHERE p.assembly = '0' AND p.obsolete = '0'|;
  my $vwhere = qq|$where
                  AND pv.vendor_id = $form->{vendor_id}|;
  
  if ($form->{"partnumber_$i"} ne "") {
    $var = $form->like(lc $form->{"partnumber_$i"});
    $where .= " AND (lower(p.partnumber) LIKE '$var'
                OR p.barcode LIKE '$var')";
    $vwhere .= " AND (lower(pv.partnumber) LIKE '$var'
                 OR p.barcode LIKE '$var')";
  }
  
  if ($form->{"description_$i"} ne "") {
    $var = $form->like(lc $form->{"description_$i"});
    if ($form->{language_code} ne "") {
      $where .= " AND lower(t1.description) LIKE '$var'";
      $vwhere .= " AND lower(t1.description) LIKE '$var'";
    } else {
      $where .= " AND lower(p.description) LIKE '$var'";
      $vwhere .= " AND lower(p.description) LIKE '$var'";
    }
  }

  if ($form->{"partsgroup_$i"} ne "") {
    ($var, $id) = split /--/, $form->{"partsgroup_$i"};
    $id *= 1;
    $where .= qq| AND (lower(pg.partsgroup) LIKE '${var}:%' OR p.partsgroup_id = $id)|;
    $vwhere .= qq| AND (lower(pg.partsgroup) LIKE '${var}:%' OR p.partsgroup_id = $id)|;
  }
  
  if ($form->{"partsgroupcode_$i"} ne "") {
    $var = $form->like(lc $form->{"partsgroupcode_$i"});
    $where .= qq| AND lower(pg.code) LIKE '$var'|;
    $vwhere .= qq| AND lower(pg.code) LIKE '$var'|;
  }

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT p.id, p.partnumber, p.description,
		 pg.partsgroup, pg.code AS partsgroupcode, p.partsgroup_id,
		 p.lastcost, p.listprice,
		 p.lastcost AS sellprice, p.sellprice AS sell,
		 p.unit, p.bin, p.onhand,
		 p.notes AS itemnotes, p.image,
		 p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		 p.partnumber AS sku, p.weight,
		 t1.description AS translation,
		 t2.description AS grouptranslation,
                 p.barcode
                 FROM parts p
		 LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
		 LEFT JOIN translation t1 ON (t1.trans_id = p.id AND t1.language_code = '$form->{language_code}')
		 LEFT JOIN translation t2 ON (t2.trans_id = p.partsgroup_id AND t2.language_code = '$form->{language_code}')
	         $where

		 UNION
		 
		 SELECT p.id, p.partnumber, p.description,
		 pg.partsgroup, pg.code AS partsgroupcode, p.partsgroup_id,
		 p.lastcost, p.listprice,
                 p.lastcost AS sellprice, p.sellprice AS sell,
		 p.unit, p.bin, p.onhand,
		 p.notes AS itemnotes, p.image,
		 p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		 p.partnumber AS sku, p.weight,
		 t1.description AS translation,
		 t2.description AS grouptranslation,
                 p.barcode
                 FROM parts p
		 LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
		 LEFT JOIN translation t1 ON (t1.trans_id = p.id AND t1.language_code = '$form->{language_code}')
		 LEFT JOIN translation t2 ON (t2.trans_id = p.partsgroup_id AND t2.language_code = '$form->{language_code}')
		 JOIN partsvendor pv ON (p.id = pv.parts_id)
	         $vwhere
		 |;

  if ($form->{"description_$i"} ne "") {
    $query .= " ORDER BY 3";
  } else {
    $query .= " ORDER BY 2";
  }


  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  my $wth;
  if ($form->{warehouse}) {
    my $warehouse_id;
    (undef, $warehouse_id) = split /--/, $form->{warehouse};
    $query = qq|SELECT SUM(qty)
                FROM inventory
                WHERE parts_id = ?
                AND warehouse_id = $warehouse_id|;
    $wth = $dbh->prepare($query) || $form->dberror($query);
  }

  # foreign currency
  $form->exchangerate_defaults($dbh, $myconfig, $form);

  # taxes
  $query = qq|SELECT c.accno
	      FROM chart c
	      JOIN partstax pt ON (pt.chart_id = c.id)
	      WHERE pt.parts_id = ?|;
  my $tth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT p.id, p.lastcost AS sellprice, a.qty
              FROM assembly a
              JOIN parts p ON (p.id = a.parts_id)
              WHERE a.aid = ?|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);

  my $aref;

  my $n;
  my $dec;
  my $decimalplaces;

  # price matrix
  my $pmh = PM->price_matrix_query($dbh, $form);

  my $ref;
  my $ptref;

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    if ($n = $ref->{inventory_accno_id} + $ref->{income_accno_id} + $ref->{expense_accno_id}) {
#      next unless $ref->{income_accno_id};
    }

    if (!$n) {
      $ath->execute($ref->{id});
      while ($aref = $ath->fetchrow_hashref(NAME_lc)) {
        $ref->{kit} .= "$aref->{id}:$aref->{qty}:$aref->{sellprice}";
        $tth->execute($aref->{id});
        while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
          $ref->{kit} .= ":$ptref->{accno}";
        }
        $tth->finish;
        $ref->{kit} .= " ";
      }
      chop $ref->{kit};
      $ath->finish;
    }

    if ($form->{warehouse}) {
      $wth->execute($ref->{id});
      ($ref->{onhand}) = $wth->fetchrow_array;
      $wth->finish;
    }

    ($dec) = ($ref->{sellprice} =~ /\.(\d+)/);
    $dec = length $dec;
    $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

    # get taxes for part
    $tth->execute($ref->{id});

    $ref->{taxaccounts} = "";
    while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
      $ref->{taxaccounts} .= "$ptref->{accno} ";
    }
    $tth->finish;
    chop $ref->{taxaccounts};

    # get vendor price and partnumber
    PM->price_matrix($pmh, $ref, undef, $decimalplaces, $form);

    $ref->{description} = $ref->{translation} if $ref->{translation};
    $ref->{partsgroup} = $ref->{grouptranslation} if $ref->{grouptranslation};
    
    push @{ $form->{item_list} }, $ref;
    
  }
  
  $sth->finish;
  $dbh->disconnect;
  
}


sub item_links {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT c.accno, c.description, c.link,
                 l.description AS translation
	         FROM chart c
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	         WHERE c.link LIKE '%IC%'
		 ORDER BY c.accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    foreach my $key (split(/:/, $ref->{link})) {
      if ($key =~ /IC/) {
	$ref->{description} = $ref->{translation} if $ref->{translation};

        push @{ $form->{IC_links}{$key} }, { accno => $ref->{accno},
                                       description => $ref->{description} };
      }
    }
  }

  $sth->finish;
}

1;

