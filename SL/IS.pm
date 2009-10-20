#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Inventory invoicing module
#
#======================================================================

package IS;


sub invoice_details {
  my ($self, $myconfig, $form) = @_;

  $form->{duedate} ||= $form->{transdate};

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $sth;

  $form->{total} = 0;

  $form->{terms} = $form->datediff($myconfig, $form->{transdate}, $form->{duedate});
 
  # this is for the template
  $form->{invdate} = $form->{transdate};
  $form->{invdescription} = $form->{description};
  
  my $tax;
  my $item;
  my $i;
  my @sortlist = ();
  my $projectnumber;
  my $projectdescription;
  my $projectnumber_id;
  my $translation;
  my $partsgroup;
  my @taxaccounts;
  my %taxaccounts;
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
              assembly, tariff_hscode AS hscode, countryorigin, barcode
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
      
      $inventory_accno_id = ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) ? "1" : "";
      
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
      
      $form->format_string(projectnumber);

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

  use SL::CP;
  my $c;
  if ($form->{language_code} ne "") {
    $c = new CP $form->{language_code};
  } else {
    $c = new CP $myconfig->{countrycode};
  }
  $c->init;

  $form->{text_packages} = $c->num2text($form->{packages} * 1);
  $form->format_string(qw(text_packages));
  $form->format_amount($myconfig, $form->{packages});
  
  $form->{projectnumber} = ();
  $form->{description} = ();
 
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

  foreach $item (@sortlist) {

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
	  
	  if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) {
	    push(@{ $form->{part} }, "");
	    push(@{ $form->{service} }, NULL);
	  } else {
	    push(@{ $form->{part} }, NULL);
	    push(@{ $form->{service} }, "");
	  }
    
	  push(@{ $form->{description} }, $item->[2]);
	  for (qw(taxrates runningnumber number sku serialnumber ordernumber customerponumber bin qty ship unit deliverydate projectnumber sellprice listprice netprice discount discountrate linetotal itemnotes package netweight grossweight volume countryorigin hscode barcode)) { push(@{ $form->{$_} }, "") }
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

      # if not grouped strip id
      ($projectnumber) = split /--/, $form->{"projectnumber_$i"};
      push(@{ $form->{projectnumber} }, $projectnumber);
      
      for (qw(sku serialnumber ordernumber customerponumber bin description unit deliverydate sellprice listprice package netweight grossweight volume countryorigin hscode barcode itemnotes)) { push(@{ $form->{$_} }, $form->{"${_}_$i"}) }
	
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

      if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) {
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

	foreach $item (@taxaccounts) {
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

      $tax = $form->round_amount($tax, $form->{precision});
      push(@{ $form->{lineitems} }, { amount => $linetotal, tax => $tax });
      push(@{ $form->{taxrates} }, join ' ', sort { $a <=> $b } @taxrates);
      
      if ($form->{"assembly_$i"}) {
	$form->{stagger} = -1;
	&assembly_details($myconfig, $form, $dbh, $form->{"id_$i"}, $form->{"qty_$i"});
      }

    }

    # add subtotal
    if ($form->{groupprojectnumber} || $form->{grouppartsgroup}) {
      if ($subtotal) {
	if ($j < $k) {
	  # look at next item
	  if ($sortlist[$j]->[1] ne $sameitem) {

	    if ($form->{"inventory_accno_id_$j"} || $form->{"assembly_$i"}) {
	      push(@{ $form->{part} }, "");
	      push(@{ $form->{service} }, NULL);
	    } else {
	      push(@{ $form->{service} }, "");
	      push(@{ $form->{part} }, NULL);
	    }

	    for (qw(taxrates runningnumber number sku serialnumber ordernumber customerponumber bin qty ship unit deliverydate projectnumber sellprice listprice netprice discount discountrate itemnotes package netweight grossweight volume countryorigin hscode barcode)) { push(@{ $form->{$_} }, "") }
	    
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

	    if ($form->{"inventory_accno_id_$j"} || $form->{"assembly_$i"}) {
	      push(@{ $form->{part} }, "");
	      push(@{ $form->{service} }, NULL);
	    } else {
	      push(@{ $form->{service} }, "");
	      push(@{ $form->{part} }, NULL);
	    }

	    for (qw(taxrates runningnumber number sku serialnumber ordernumber customerponumber bin qty ship unit deliverydate projectnumber sellprice listprice netprice discount discountrate itemnotes package netweight grossweight volume countryorigin hscode barcode)) { push(@{ $form->{$_} }, "") }

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
    if ($taxaccounts{$_} = $form->round_amount($taxaccounts{$_}, $form->{precision})) {
      $tax += $taxaccounts{$_};

      $form->{"${_}_taxbaseinclusive"} = $taxbase{$_} + $taxaccounts{$_};
      
      push(@{ $form->{taxdescription} }, $form->{"${_}_description"});

      $taxrate += $form->{"${_}_rate"};
      
      push(@{ $form->{taxrate} }, $form->format_amount($myconfig, $form->{"${_}_rate"} * 100));
      push(@{ $form->{taxnumber} }, $form->{"${_}_taxnumber"});
    }
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
  for (@{ $form->{lineitems} }) {
    push(@{ $form->{linetax} }, $form->format_amount($myconfig, $_->{tax}, $form->{precision}, ""));
  }
  
  
  if ($form->{taxincluded}) {
    $form->{invtotal} = $form->{total};
    $form->{subtotal} = $form->{total} - $tax;
  } else {
    $form->{subtotal} = $form->{total};
    $form->{invtotal} = $form->{total} + $tax;
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
    
    if ($taxaccounts{$_}) {

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
      push(@{ $form->{tax} }, $form->format_amount($myconfig, $taxaccounts{$_}, $form->{precision}));

      $form->{"${_}_taxbaseinclusive"} = $form->format_amount($myconfig, $form->{"${_}_taxbaseinclusive"}, $form->{precision});
      $form->{"${_}_taxbase"} = $form->format_amount($myconfig, $taxbase{$_}, $form->{precision});
      $form->{"${_}_tax"} = $form->format_amount($myconfig, $form->{"${_}_tax"}, $form->{precision});
      
      $form->{"${_}_taxrate"} = $form->format_amount($myconfig, $form->{"${_}_rate"} * 100);
      
    }
  }

  my ($paymentaccno) = split /--/, $form->{"AR_paid_$form->{paidaccounts}"};
  
  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      push(@{ $form->{payment} }, $form->{"paid_$i"});
      my ($accno, $description) = split /--/, $form->{"AR_paid_$i"};
      push(@{ $form->{paymentaccount} }, $description); 
      push(@{ $form->{paymentdate} }, $form->{"datepaid_$i"});
      push(@{ $form->{paymentsource} }, $form->{"source_$i"});
      push(@{ $form->{paymentmemo} }, $form->{"memo_$i"});

      ($description) = split /--/, $form->{"paymentmethod_$i"};
      push(@{ $form->{paymentmethod} }, $description);

      $form->{paid} += $form->parse_amount($myconfig, $form->{"paid_$i"});
    }
  }

  if ($form->{cdt} && $form->{discount_paid}) {
    $form->{invtotal} = $form->{cd_subtotal} + $cd_tax;
    $tax = $cd_tax;
  }

  $form->{cd_invtotal} = $form->{cd_subtotal} + $cd_tax;

  $form->{total} = $form->{invtotal} - $form->{paid};
  
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

  # dcn
  $query = qq|SELECT bk.iban, bk.bic, bk.membernumber, bk.dcn, bk.rvc
	      FROM bank bk
	      JOIN chart c ON (c.id = bk.id)
	      WHERE c.accno = '$paymentaccno'|;
  ($form->{iban}, $form->{bic}, $form->{membernumber}, $form->{dcn}, $form->{rvc}) = $dbh->selectrow_array($query);

  for my $dcn (qw(dcn rvc)) { $form->{$dcn} = $form->format_dcn($form->{$dcn}) }

  # save dcn
  if ($form->{id}) {
    $query = qq|UPDATE ar SET
		dcn = '$form->{dcn}',
		bank_id = (SELECT id FROM chart WHERE accno = '$paymentaccno')
		WHERE id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }

  $dbh->disconnect;
  
}


sub delete_invoice {
  my ($self, $myconfig, $form, $spool, $dbh) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;
  
  # connect to database, turn off autocommit
  if (! $dbh) {
    $dbh = $form->dbconnect_noauto($myconfig);
  }

  &reverse_invoice($dbh, $form);
  
  my %audittrail = ( tablename  => 'ar',
                     reference  => $form->{invnumber},
		     formname   => $form->{type},
		     action     => 'deleted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);
     
  # delete AR/AP record
  my $query = qq|DELETE FROM ar
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

  $query = qq|UPDATE oe SET aa_id = NULL
              WHERE aa_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $form->remove_locks($myconfig, $dbh, 'ar');

  my $rc = $dbh->commit;

  if ($rc) {
    foreach $spoolfile (@spoolfiles) {
      unlink "$spool/$spoolfile" if $spoolfile;
    }
  }
  
  $dbh->disconnect if $disconnect;
  
  $rc;
  
}


sub assembly_details {
  my ($myconfig, $form, $dbh, $id, $qty) = @_;
  
  my $sm = "";
  my $spacer;
  
  $form->{stagger}++;
  if ($form->{format} eq 'html') {
    $spacer = "&nbsp;" x (3 * ($form->{stagger} - 1)) if $form->{stagger} > 1;
  }
  if ($form->{format} =~ /(postscript|pdf)/) {
    if ($form->{stagger} > 1) {
      $spacer = ($form->{stagger} - 1) * 3;
      $spacer = '\rule{'.$spacer.'mm}{0mm}';
    }
  }
  
  # get parts and push them onto the stack
  my $sortorder = "";

  if ($form->{grouppartsgroup}) {
    $sortorder = qq|ORDER BY pg.partsgroup, a.id|;
  } else {
    $sortorder = qq|ORDER BY a.id|;
  }
  
  my $query = qq|SELECT p.partnumber, p.description, p.unit, a.qty,
	         pg.partsgroup, p.partnumber AS sku
	         FROM assembly a
	         JOIN parts p ON (a.parts_id = p.id)
	         LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
	         WHERE a.bom = '1'
	         AND a.aid = '$id'
	         $sortorder|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    for (qw(partnumber description partsgroup)) {
      $form->{"a_$_"} = $ref->{$_};
      $form->format_string("a_$_");
    }

    if ($form->{grouppartsgroup} && $ref->{partsgroup} ne $sm) {
      for (qw(taxrates runningnumber number sku serialnumber ordernumber customerponumber unit qty ship bin deliverydate projectnumber sellprice listprice netprice discount discountrate linetotal itemnotes package netweight grossweight volume countryorigin hscode barcode)) { push(@{ $form->{$_} }, "") }
      $sm = ($form->{"a_partsgroup"}) ? $form->{"a_partsgroup"} : "--";
      push(@{ $form->{description} }, "$spacer$sm");
      push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });
    }
    
    if ($form->{stagger}) {
      
      push(@{ $form->{description} }, $form->format_amount($myconfig, $ref->{qty} * $form->{"qty_$i"}) . qq| -- $form->{"a_partnumber"}, $form->{"a_description"}|);
      for (qw(taxrates runningnumber number sku serialnumber ordernumber customerponumber unit qty ship bin deliverydate projectnumber sellprice listprice netprice discount discountrate linetotal itemnotes package netweight grossweight volume countryorigin hscode barcode)) { push(@{ $form->{$_} }, "") }
      
    } else {
      
      push(@{ $form->{description} }, qq|$form->{"a_description"}|);
      push(@{ $form->{number} }, $form->{"a_partnumber"});
      push(@{ $form->{sku} }, $form->{"a_partnumber"});

      for (qw(taxrates runningnumber ship serialnumber ordernumber customerponumber reqdate projectnumber sellprice listprice netprice discount discountrate linetotal itemnotes package netweight grossweight volume countryorigin hscode barcode)) { push(@{ $form->{$_} }, "") }
      
    }

    push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });

    push(@{ $form->{qty} }, $form->format_amount($myconfig, $ref->{qty} * $qty));
    
    for (qw(unit bin)) {
      $form->{"a_$_"} = $ref->{$_};
      $form->format_string("a_$_");
      push(@{ $form->{$_} }, $form->{"a_$_"});
    }

  }
  $sth->finish;

  $form->{stagger}--;
  
}


sub project_description {
  my ($self, $dbh, $id) = @_;

  my $query = qq|SELECT description
                 FROM project
		 WHERE id = $id|;
  ($_) = $dbh->selectrow_array($query);

  $_;

}


sub post_invoice {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;
  
  # connect to database, turn off autocommit
  if (! $dbh) {
    $dbh = $form->dbconnect_noauto($myconfig);
  }

  my $query;
  my $sth;
  my $null;
  my $project_id;
  my $keepcleared;
  my $ok;
  
  %$form->{acc_trans} = ();

  ($null, $form->{employee_id}) = split /--/, $form->{employee};
  unless ($form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  }
  
  for (qw(department warehouse)) {
    ($null, $form->{"${_}_id"}) = split(/--/, $form->{$_});
    $form->{"${_}_id"} *= 1;
  }

  my %defaults = $form->get_defaults($dbh, \@{['fx%_accno_id', 'cdt', 'precision']});
  $form->{precision} = $defaults{precision};

  $query = qq|SELECT p.assembly, p.inventory_accno_id,
              p.income_accno_id, p.expense_accno_id, p.project_id
	      FROM parts p
	      WHERE p.id = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT c.accno
              FROM partstax pt
              JOIN chart c ON (c.id = pt.chart_id)
	      WHERE pt.parts_id = ?|;
  my $ptt = $dbh->prepare($query) || $form->dberror($query);
 
  if ($form->{id}) {
    $keepcleared = 1;
    $query = qq|SELECT id FROM ar
                WHERE id = $form->{id}|;

    if ($dbh->selectrow_array($query)) {
      &reverse_invoice($dbh, $form);
    } else {
      $query = qq|INSERT INTO ar (id)
                  VALUES ($form->{id})|;
      $dbh->do($query) || $form->dberror($query);
    }
    
  }
  
  my $uid = localtime;
  $uid .= $$;
 
  if (! $form->{id}) {
   
    $query = qq|INSERT INTO ar (invnumber, employee_id)
                VALUES ('$uid', $form->{employee_id})|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT id FROM ar
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

  $form->{exchangerate} = $form->parse_amount($myconfig, $form->{exchangerate});
  $form->{exchangerate} ||= 1;

  my $i;
  my $item;
  my $allocated = 0;
  my $taxrate;
  my $tax;
  my $fxtax;
  my @taxaccounts;
  my $amount;
  my $fxamount;
  my $roundamount;
  my $grossamount;
  my $invamount = 0;
  my $invnetamount = 0;
  my $diff = 0;
  my $fxdiff = 0;
  my $ml;
  my $id;
  my $ndx;
  my $sw = ($form->{type} eq 'invoice') ? 1 : -1;
  $sw = 1 if $form->{till};
  my $lineitemdetail;

  $form->{taxincluded} *= 1;

  foreach $i (1 .. $form->{rowcount}) {
    $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"}) * $sw;
    
    if ($form->{"qty_$i"}) {
      
      $pth->execute($form->{"id_$i"});
      $ref = $pth->fetchrow_hashref(NAME_lc);
      for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }
      $pth->finish;
      
      if (! $form->{"taxaccounts_$i"}) {
	$ptt->execute($form->{"id_$i"});
	while ($ref = $ptt->fetchrow_hashref(NAME_lc)) {
	  $form->{"taxaccounts_$i"} .= "$ref->{accno} ";
	}
	$ptt->finish;
	chop $form->{"taxaccounts_$i"};
      }

      # project
      $project_id = 'NULL';
      if ($form->{"projectnumber_$i"}) {
	($null, $project_id) = split /--/, $form->{"projectnumber_$i"};
      }
      $project_id = $form->{"project_id_$i"} if $form->{"project_id_$i"};

      # keep entered selling price
      my $fxsellprice = $form->parse_amount($myconfig, $form->{"sellprice_$i"});

      my ($dec) = ($fxsellprice =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};
      
      # undo discount formatting
      $form->{"discount_$i"} = $form->parse_amount($myconfig, $form->{"discount_$i"})/100;
     
      # deduct discount
      $form->{"sellprice_$i"} = $fxsellprice - $form->round_amount($fxsellprice * $form->{"discount_$i"}, $decimalplaces);
      
      # linetotal
      my $fxlinetotal = $form->round_amount($form->{"sellprice_$i"} * $form->{"qty_$i"}, $form->{precision});

      $amount = $fxlinetotal * $form->{exchangerate};
      my $linetotal = $form->round_amount($amount, $form->{precision});
      $fxdiff += $form->round_amount($amount - $linetotal, 10);
      
      @taxaccounts = split / /, $form->{"taxaccounts_$i"};
      $ml = 1;
      $tax = 0;
      $fxtax = 0;
      
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
      
      # add linetotal to income
      $amount = $form->round_amount($linetotal, $form->{precision});

      push @{ $form->{acc_trans}{lineitems} }, {
        chart_id => $form->{"income_accno_id_$i"},
	amount => $amount,
	grossamount => $grossamount,
	fxamount => $fxlinetotal,
	project_id => $project_id };
	
      $ndx = $#{$form->{acc_trans}{lineitems}};

      $form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"} * $form->{exchangerate}, $decimalplaces);
  
      if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) {
	
        if ($form->{"assembly_$i"}) {
          # do not update if assembly consists of all services
	  $query = qq|SELECT sum(p.inventory_accno_id), p.assembly
	              FROM parts p
		      JOIN assembly a ON (a.parts_id = p.id)
		      WHERE a.aid = $form->{"id_$i"}
		      GROUP BY p.assembly|;
          $sth = $dbh->prepare($query);
	  $sth->execute || $form->dberror($query);
	  my ($inv, $assembly) = $sth->fetchrow_array;
	  $sth->finish;
		      
          if ($inv || $assembly) {
	    $form->update_balance($dbh,
				  "parts",
				  "onhand",
				  qq|id = $form->{"id_$i"}|,
				  $form->{"qty_$i"} * -1) unless $form->{shipped};
	  }

	  &process_assembly($dbh, $form, $form->{"id_$i"}, $form->{"qty_$i"}, $project_id, $i);
	
	} else {

	  # regular part
	  $form->update_balance($dbh,
	                        "parts",
				"onhand",
				qq|id = $form->{"id_$i"}|,
				$form->{"qty_$i"} * -1) unless $form->{shipped};

          if ($form->{"qty_$i"} > 0) {
	    
	    $allocated = &cogs($dbh, $form, $form->{"id_$i"}, $form->{"qty_$i"}, $project_id);
	    
	  } else {
	   
	    # returns
	    $allocated = &cogs_returns($dbh, $form, $form->{"id_$i"}, $form->{"qty_$i"}, $project_id, $i);
	    
	    # change account to inventory
	    $form->{acc_trans}{lineitems}[$ndx]->{chart_id} = $form->{"inventory_accno_id_$i"};

	  }
	}
      }

      # save detail record in invoice table
      $query = qq|INSERT INTO invoice (description, trans_id, parts_id)
                  VALUES ('$uid', $form->{id}, $form->{"id_$i"})|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|SELECT id
                  FROM invoice
                  WHERE description = '$uid'|;
      ($id) = $dbh->selectrow_array($query);
      
      $lineitemdetail = ($form->{"lineitemdetail_$i"}) ? 1 : 0;
      
      $query = qq|UPDATE invoice SET
		  description = |.$dbh->quote($form->{"description_$i"}).qq|,
		  qty = $form->{"qty_$i"},
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

      # add id
      $form->{acc_trans}{lineitems}[$ndx]->{id} = $id;

      # add inventory
      $ok = ($form->{"package_$i"} ne "") ? 1 : 0;
      for (qw(netweight grossweight volume)) {
	$form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"});
	$ok = 1 if $form->{"${_}_$i"};
      }
      if ($ok) {
	$query = qq|INSERT INTO cargo (id, trans_id, package, netweight,
	            grossweight, volume) VALUES ( $id, $form->{id}, |
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
  for (@{ $form->{acc_trans}{lineitems} }) {
    $amount += $_->{amount};
    $grossamount += $_->{grossamount};
    $fxamount += $_->{fxamount};
  }
  $invnetamount = $amount;

  $amount = 0;
  for (split / /, $form->{taxaccounts}) { $amount += $form->{acc_trans}{$form->{id}}{$_}{amount} = $form->round_amount($form->{acc_trans}{$form->{id}}{$_}{amount}, $form->{precision}) }
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

  if ($form->round_amount($form->{paid} - $fxamount + $fxtax, $form->{precision}) == 0) {
    $form->{paid} = $invamount;
  } else {
    $form->{paid} = $form->round_amount($form->{paid} * $form->{exchangerate}, $form->{precision});
  }

  foreach $ref (sort { $b->{amount} <=> $a->{amount} } @ { $form->{acc_trans}{lineitems} }) {
    $amount = $ref->{amount} + $diff + $fxdiff;
    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		transdate, project_id, id)
		VALUES ($form->{id}, $ref->{chart_id}, $amount,
	      '$form->{transdate}', $ref->{project_id}, $ref->{id})|;
    $dbh->do($query) || $form->dberror($query);
    $diff = 0;
    $fxdiff = 0;
  }
  
  $form->{receivables} = $invamount * -1;

  delete $form->{acc_trans}{lineitems};
  
  # update exchangerate
  $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, $form->{exchangerate}, 0);

  my $accno;
  my ($araccno) = split /--/, $form->{AR};

  # record receivable
  if ($form->{receivables}) {

    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
                transdate)
                VALUES ($form->{id},
		       (SELECT id FROM chart
		        WHERE accno = '$araccno'),
                $form->{receivables}, '$form->{transdate}')|;
    $dbh->do($query) || $form->dberror($query);
  }
 

  $i = $form->{discount_index};

  if ($form->{"paid_$i"} && $defaults{cdt}) {
    
    my $roundamount;
    $tax = 0;
    $fxtax = 0;
    
    $form->{"exchangerate_$i"} = $form->parse_amount($myconfig, $form->{"exchangerate_$i"});
    $form->{"exchangerate_$i"} ||= 1;

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
	amount => $roundamount,
	transdate => $form->{"datepaid_$i"},
	id => $form->{id} };

    }

    $diff = $form->round_amount($diff, $form->{precision});
    if ($diff != 0) {
      my $n = $#{$form->{acc_trans}{taxes}};
      $form->{acc_trans}{taxes}[$n]{amount} -= $diff;
    }

    push @{ $form->{acc_trans}{taxes} }, {
      accno => $araccno,
      amount => $tax * -1,
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
    foreach $accno (keys %{$form->{acc_trans}{$trans_id}}) {
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

  
  # if there is no amount but a payment record receivable
  if ($invamount == 0) {
    $form->{receivables} = 1;
  }
  
  my $cleared = 'NULL';
  my $voucherid;
  my $approved;
  my $paymentid = 1;
  my $paymentaccno;
  my $paymentmethod_id;

  # record payments and offsetting AR
  for $i (1 .. $form->{paidaccounts}) {
    
    if ($form->{"paid_$i"}) {
      ($accno) = split /--/, $form->{"AR_paid_$i"};
      
      ($null, $paymentmethod_id) = split /--/, $form->{"paymentmethod_$i"};
      $paymentmethod_id *= 1;

      $paymentaccno = $accno;
      $form->{"datepaid_$i"} = $form->{transdate} unless ($form->{"datepaid_$i"});
      $form->{datepaid} = $form->{"datepaid_$i"};
      
      $form->{"exchangerate_$i"} = $form->parse_amount($myconfig, $form->{"exchangerate_$i"});
      $form->{"exchangerate_$i"} ||= 1;
 
      # record AR
      $amount = $form->round_amount($form->{"paid_$i"} * $form->{exchangerate}, $form->{precision});

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
				  $amount);
	  }
	}
      }

      
      if ($form->{receivables}) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate, approved, vr_id)
		    VALUES ($form->{id}, (SELECT id FROM chart
					WHERE accno = '$araccno'),
		    $amount, '$form->{"datepaid_$i"}',
		    '$approved', $voucherid)|;
	$dbh->do($query) || $form->dberror($query);
      }

      # record payment
      $amount = $form->{"paid_$i"} * -1;

      if ($keepcleared) {
	$cleared = $form->dbquote($form->{"cleared_$i"}, SQL_DATE);
      }
      
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
                  source, memo, cleared, approved, vr_id, id)
                  VALUES ($form->{id}, (SELECT id FROM chart
		                      WHERE accno = '$accno'),
		  $amount, '$form->{"datepaid_$i"}', |
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
      $amount = $form->round_amount(($form->round_amount($form->{"paid_$i"} * $form->{"exchangerate_$i"} - $form->{"paid_$i"}, $form->{precision})) * -1, $form->{precision});

      if ($amount) { 
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate, source, fx_transaction, cleared, approved, vr_id)
		    VALUES ($form->{id}, (SELECT id FROM chart
					WHERE accno = '$accno'),
		    $amount, '$form->{"datepaid_$i"}', |
		    .$dbh->quote($form->{"source_$i"}).qq|, '1', $cleared,
		    '$approved', $voucherid)|;
	$dbh->do($query) || $form->dberror($query);
      }
     
      # gain/loss
      $amount = $form->round_amount(($form->round_amount($form->{"paid_$i"} * $form->{exchangerate}, $form->{precision}) - $form->round_amount($form->{"paid_$i"} * $form->{"exchangerate_$i"}, $form->{precision})) * -1, $form->{precision});

      if ($amount) {
	my $accno_id = ($amount > 0) ? $defaults{fxgain_accno_id} : $defaults{fxloss_accno_id};
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate, fx_transaction, cleared, approved, vr_id)
	            VALUES ($form->{id}, $accno_id,
		    $amount, '$form->{"datepaid_$i"}', '1', $cleared,
		    '$approved', $voucherid)|;
	$dbh->do($query) || $form->dberror($query);
      }
    }
  }

  ($paymentaccno) = split /--/, $form->{"AR_paid_$form->{paidaccounts}"};

  ($null, $paymentmethod_id) = split /--/, $form->{"paymentmethod_$form->{paidaccounts}"};
  $paymentmethod_id *= 1;

  # if this is from a till
  my $till = ($form->{till}) ? qq|'$form->{till}'| : "NULL";

  $form->{invnumber} = $form->update_defaults($myconfig, "sinumber", $dbh) unless $form->{invnumber};

  for (qw(terms discountterms onhold)) { $form->{$_} *= 1 }
  $form->{cashdiscount} = $form->parse_amount($myconfig, $form->{cashdiscount}) / 100;

  if ($form->{cdt} && $form->{"paid_$form->{discount_index}"}) {
    $invamount -= $cd_tax if !$form->{taxincluded};
  }

  
  # for dcn
  ($form->{integer_amount}, $form->{decimal}) = split /\./, $form->{oldinvtotal};
  $form->{decimal} = substr("$form->{decimal}00", 0, 2);

  $query = qq|SELECT bk.membernumber, bk.dcn
	      FROM bank bk
	      JOIN chart c ON (c.id = bk.id)
	      WHERE c.accno = '$paymentaccno'|;
  ($form->{membernumber}, $form->{dcn}) = $dbh->selectrow_array($query);

  $form->{dcn} = $form->format_dcn($form->{dcn});

  # save AR record
  $query = qq|UPDATE ar set
              invnumber = |.$dbh->quote($form->{invnumber}).qq|,
              description = |.$dbh->quote($form->{description}).qq|,
	      ordnumber = |.$dbh->quote($form->{ordnumber}).qq|,
	      quonumber = |.$dbh->quote($form->{quonumber}).qq|,
              transdate = '$form->{transdate}',
              customer_id = $form->{customer_id},
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
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      intnotes = |.$dbh->quote($form->{intnotes}).qq|,
	      taxincluded = '$form->{taxincluded}',
	      curr = '$form->{currency}',
	      department_id = $form->{department_id},
	      employee_id = $form->{employee_id},
	      till = $till,
	      language_code = '$form->{language_code}',
	      ponumber = |.$dbh->quote($form->{ponumber}).qq|,
	      cashdiscount = $form->{cashdiscount},
	      discountterms = $form->{discountterms},
	      onhold = '$form->{onhold}',
	      warehouse_id = $form->{warehouse_id},
	      exchangerate = $form->{exchangerate},
	      dcn = '$form->{dcn}',
	      bank_id = (SELECT id FROM chart WHERE accno = '$paymentaccno'),
	      paymentmethod_id = $paymentmethod_id
              WHERE id = $form->{id}
             |;
  $dbh->do($query) || $form->dberror($query);

  # add shipto
  $form->{name} = $form->{customer};
  $form->{name} =~ s/--$form->{customer_id}//;
  $form->add_shipto($dbh, $form->{id});

  # save printed, emailed and queued
  $form->save_status($dbh);

  # add link for order
  if ($form->{order_id}) {
    $query = qq|UPDATE oe SET aa_id = $form->{id}
                WHERE id = $form->{order_id}|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  my %audittrail = ( tablename  => 'ar',
                     reference  => $form->{invnumber},
		     formname   => $form->{type},
		     action     => 'posted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);

  $form->save_recurring($dbh, $myconfig);

  $form->remove_locks($myconfig, $dbh, 'ar');
  
  my $rc = $dbh->commit;

  $dbh->disconnect if $disconnect;

  $rc;
  
}


sub process_assembly {
  my ($dbh, $form, $id, $totalqty, $project_id, $i) = @_;

  my $query = qq|SELECT a.parts_id, a.qty, p.assembly,
                 p.partnumber, p.description, p.unit,
                 p.inventory_accno_id, p.income_accno_id,
		 p.expense_accno_id
                 FROM assembly a
		 JOIN parts p ON (a.parts_id = p.id)
		 WHERE a.aid = $id|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $allocated;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    $allocated = 0;
    
    $ref->{inventory_accno_id} *= 1;
    $ref->{expense_accno_id} *= 1;

    # multiply by number of assemblies
    $ref->{qty} *= $totalqty;
    
    if ($ref->{assembly}) {
      &process_assembly($dbh, $form, $ref->{parts_id}, $ref->{qty}, $project_id, $i);
      next;
    } else {
      if ($ref->{inventory_accno_id}) {
	if ($ref->{qty} > 0) {
	  $allocated = &cogs($dbh, $form, $ref->{parts_id}, $ref->{qty}, $project_id);
	} else {
	  $allocated = &cogs_returns($dbh, $form, $ref->{parts_id}, $ref->{qty}, $project_id, $i);
	}
      }
    }

    # save detail record for individual assembly item in invoice table
    $query = qq|INSERT INTO invoice (trans_id, description, parts_id, qty,
                sellprice, fxsellprice, allocated, assemblyitem, unit)
		VALUES
		($form->{id}, |
		.$dbh->quote($ref->{description}).qq|,
		$ref->{parts_id}, $ref->{qty}, 0, 0, $allocated, 't', |
		.$dbh->quote($ref->{unit}).qq|)|;
    $dbh->do($query) || $form->dberror($query);
 
  }

  $sth->finish;

}


sub cogs {
  my ($dbh, $form, $id, $totalqty, $project_id) = @_;

  my $query;
  my $sth;

  $query = qq|SELECT i.id, i.trans_id, i.qty, i.allocated, i.sellprice,
	      p.inventory_accno_id, p.expense_accno_id
	      FROM invoice i
	      JOIN parts p ON (p.id = i.parts_id)
	      WHERE i.parts_id = $id
	      AND (i.qty + i.allocated) < 0
	      ORDER BY i.trans_id|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $linetotal;
  my $allocated = 0;
  my $qty;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    if (($qty = (($ref->{qty} * -1) - $ref->{allocated})) > $totalqty) {
      $qty = $totalqty;
    }
    
    $form->update_balance($dbh,
			  "invoice",
			  "allocated",
			  qq|id = $ref->{id}|,
			  $qty);

    # total expenses and inventory
    # sellprice is the cost of the item
    $linetotal = $form->round_amount($ref->{sellprice} * $qty, $form->{precision});

    # add expense
    push @{ $form->{acc_trans}{lineitems} }, {
      chart_id => $ref->{expense_accno_id},
      amount => $linetotal * -1,
      project_id => $project_id,
      id => $ref->{id} };

    # deduct inventory
    push @{ $form->{acc_trans}{lineitems} }, {
      chart_id => $ref->{inventory_accno_id},
      amount => $linetotal,
      project_id => $project_id,
      id => $ref->{id} };

    # add allocated
    $allocated += -$qty;
    
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

  # check if we can apply cogs against sold items
  $query = qq|SELECT i.id, i.trans_id, i.qty, i.allocated,
	      p.inventory_accno_id, p.expense_accno_id
	      FROM invoice i
	      JOIN parts p ON (p.id = i.parts_id)
	      WHERE i.parts_id = $id
	      AND (i.qty + i.allocated) > 0
	      ORDER BY i.trans_id|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    $qty = $ref->{qty} + $ref->{allocated};
    if ($qty > $totalqty) {
      $qty = $totalqty;
    }
    
    $linetotal = $form->round_amount($form->{"sellprice_$i"} * $qty, $form->{precision});
    
    $form->update_balance($dbh,
			  "invoice",
			  "allocated",
			  qq|id = $ref->{id}|,
			  $qty * -1);

    # debit COGS
    $query = qq|INSERT INTO acc_trans (trans_id, chart_id,
                amount, transdate, project_id)
                VALUES ($ref->{trans_id}, $ref->{expense_accno_id},
		$linetotal * -1, '$form->{transdate}', $project_id)|;
    $dbh->do($query) || $form->dberror($query);

    # credit inventory
    $query = qq|INSERT INTO acc_trans (trans_id, chart_id,
                amount, transdate, project_id)
                VALUES ($ref->{trans_id}, $ref->{inventory_accno_id},
		$linetotal, '$form->{transdate}', $project_id)|;
    $dbh->do($query) || $form->dberror($query);

    $allocated += $qty;
    
    last if (($totalqty -= $qty) <= 0);

  }
  $sth->finish;

  $allocated;
  
}


sub reverse_invoice {
  my ($dbh, $form) = @_;
  
  my $query = qq|SELECT id
                 FROM ar
		 WHERE id = $form->{id}|;
  my ($id) = $dbh->selectrow_array($query);
  
  return unless $id;

  my $qty;
  my $amount;
  
  # reverse inventory items
  $query = qq|SELECT i.id, i.parts_id, i.qty, i.allocated, i.assemblyitem,
              i.sellprice, i.project_id,
              p.assembly, p.inventory_accno_id, p.expense_accno_id, p.obsolete
              FROM invoice i
	      JOIN parts p ON (i.parts_id = p.id)
	      WHERE i.trans_id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $pth;
  my $pref;
  my $totalqty;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    
    if ($ref->{obsolete}) {
      $query = qq|UPDATE parts SET obsolete = '0'
                  WHERE id = $ref->{parts_id}|;
      $dbh->do($query) || $form->dberror($query);
    }

    if ($ref->{inventory_accno_id} || $ref->{assembly}) {

      # if the invoice item is not an assemblyitem adjust parts onhand
      if (!$ref->{assemblyitem}) {
        # adjust onhand in parts table
	$form->update_balance($dbh,
	                      "parts",
			      "onhand",
			      qq|id = $ref->{parts_id}|,
			      $ref->{qty});
      }

      # loop if it is an assembly
      next if $ref->{assembly} || $ref->{allocated} == 0;

      if ($ref->{allocated} < 0) {
	
	# de-allocate purchases
	$query = qq|SELECT i.id, i.trans_id, i.allocated
		    FROM invoice i
		    WHERE i.parts_id = $ref->{parts_id}
		    AND i.allocated > 0
		    ORDER BY i.trans_id DESC|;

	$pth = $dbh->prepare($query);
	$pth->execute || $form->dberror($query);

	$totalqty = $ref->{allocated} * -1;

	while ($pref = $pth->fetchrow_hashref(NAME_lc)) {

	  $qty = $totalqty;
	  
	  if ($qty > $pref->{allocated}) {
	    $qty = $pref->{allocated};
	  }
	  
	  # update invoice
	  $form->update_balance($dbh,
				"invoice",
				"allocated",
				qq|id = $pref->{id}|,
				$qty * -1);

	  last if (($totalqty -= $qty) <= 0);
	}
	$pth->finish;

      } else {
	
	# de-allocate sales
	$query = qq|SELECT i.id, i.trans_id, i.qty, i.allocated
		    FROM invoice i
		    WHERE i.parts_id = $ref->{parts_id}
		    AND i.allocated < 0
		    ORDER BY i.trans_id DESC|;

	$pth = $dbh->prepare($query);
	$pth->execute || $form->dberror($query);

        $totalqty = $ref->{qty} * -1;
	
	while ($pref = $pth->fetchrow_hashref(NAME_lc)) {

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

          $ref->{project_id} ||= 'NULL';
	  # credit cogs
	  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	              transdate, project_id)
	              VALUES ($pref->{trans_id}, $ref->{expense_accno_id},
		      $amount, '$form->{transdate}', $ref->{project_id})|;
          $dbh->do($query) || $form->dberror($query);

          # debit inventory
	  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	              transdate, project_id)
	              VALUES ($pref->{trans_id}, $ref->{inventory_accno_id},
		      $amount * -1, '$form->{transdate}', $ref->{project_id})|;
          $dbh->do($query) || $form->dberror($query);

	  last if (($totalqty -= $qty) <= 0);
	}
	$pth->finish;
      }
    }
    
    # delete cargo entry
    $query = qq|DELETE FROM cargo
                WHERE trans_id = $form->{id}
		AND id = $ref->{id}|;
    $dbh->do($query) || $form->dberror($query);

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
	      AND c.link LIKE '%AR_paid%'
	      AND NOT (ac.chart_id = $defaults{fxgain_accno_id}
	            OR ac.chart_id = $defaults{fxloss_accno_id})
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
			  $amount);
  }
  $sth->finish;
  
  
  for (qw(acc_trans dpt_trans invoice inventory shipto vr payment)) {
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
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  
  $form->{currencies} = $form->get_currencies($dbh, $myconfig);
 
  if ($form->{id}) {
    
    # retrieve invoice
    $query = qq|SELECT a.invnumber, a.ordnumber, a.quonumber,
                a.transdate, a.amount, a.netamount, a.paid,
                a.shippingpoint, a.shipvia, a.waybill,
		a.cashdiscount, a.discountterms, a.terms,
		a.notes, a.intnotes,
		a.duedate, a.taxincluded, a.curr AS currency,
		a.employee_id, e.name AS employee, a.till, a.customer_id,
		a.language_code, a.ponumber,
		a.warehouse_id, w.description AS warehouse,
		a.exchangerate,
		c.accno AS bank_accno, c.description AS bank_accno_description,
		t.description AS bank_accno_translation,
		pm.description AS paymentmethod, a.paymentmethod_id
		FROM ar a
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

    if ($form->{bank_accno}) {
      $form->{payment_accno} = ($form->{bank_accno_translation}) ? "$form->{bank_accno}--$form->{bank_accno_translation}" : "$form->{bank_accno}--$form->{bank_accno_description}";
    }

    if ($form->{paymentmethod_id}) {
      $form->{payment_method} = "$form->{paymentmethod}--$form->{paymentmethod_id}";
    }
    
    $form->{type} = ($form->{amount} < 0) ? 'credit_invoice' : 'invoice';
    $form->{type} = 'pos_invoice' if $form->{till};
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
    $query = qq|SELECT i.description, i.qty, i.fxsellprice, i.sellprice,
		i.discount, i.parts_id AS id, i.unit, i.deliverydate,
		i.project_id, pr.projectnumber, i.serialnumber, i.ordernumber,
		i.ponumber AS customerponumber, i.itemnotes, i.lineitemdetail,
		p.partnumber, p.assembly, p.bin,
		pg.partsgroup, p.partsgroup_id, p.partnumber AS sku,
		p.listprice, p.lastcost, p.weight, p.onhand,
		p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		t.description AS partsgrouptranslation,
		c.package, c.netweight, c.grossweight, c.volume
		FROM invoice i
	        JOIN parts p ON (i.parts_id = p.id)
	        LEFT JOIN project pr ON (i.project_id = pr.id)
	        LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		LEFT JOIN translation t ON (t.trans_id = p.partsgroup_id AND t.language_code = '$form->{language_code}')
		LEFT JOIN cargo c ON (c.id = i.id AND c.trans_id = i.trans_id)
		WHERE i.trans_id = $form->{id}
		AND NOT i.assemblyitem = '1'
		ORDER BY i.id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    # foreign currency
    &exchangerate_defaults($dbh, $myconfig, $form);

    # query for price matrix
    my $pmh = &price_matrix_query($dbh, $form);
    
    # taxes
    $query = qq|SELECT c.accno
		FROM chart c
		JOIN partstax pt ON (pt.chart_id = c.id)
		WHERE pt.parts_id = ?|;
    my $tth = $dbh->prepare($query) || $form->dberror($query);
   
    my $taxrate;
    my $ptref;
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

      my ($dec) = ($ref->{fxsellprice} =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

      $tth->execute($ref->{id});

      $ref->{taxaccounts} = "";
      $taxrate = 0;
      
      while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
	$ref->{taxaccounts} .= "$ptref->{accno} ";
	$taxrate += $form->{"$ptref->{accno}_rate"};
      }
      $tth->finish;
      chop $ref->{taxaccounts};

      # price matrix
      $ref->{sellprice} = ($ref->{fxsellprice} * $form->{$form->{currency}});
      &price_matrix($pmh, $ref, $form->{transdate}, $decimalplaces, $form, $myconfig);
      $ref->{sellprice} = $ref->{fxsellprice};

      $ref->{partsgroup} = $ref->{partsgrouptranslation} if $ref->{partsgrouptranslation};
      
      push @{ $form->{invoice_details} }, $ref;
    }
    $sth->finish;

  } else {
    $form->{transdate} = $form->current_date($myconfig);
  }

  my $rc = $dbh->commit;
  $dbh->disconnect;
  
  $rc;

}


sub retrieve_item {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $i = $form->{rowcount};
  my $null;
  my $var;

  my $where = "WHERE p.obsolete = '0' AND NOT p.income_accno_id IS NULL";

  if ($form->{"partnumber_$i"} ne "") {
    $var = $form->like(lc $form->{"partnumber_$i"});
    $where .= " AND lower(p.partnumber) LIKE '$var'";
  }
  if ($form->{"description_$i"} ne "") {
    $var = $form->like(lc $form->{"description_$i"});
    if ($form->{language_code} ne "") {
      $where .= " AND lower(t1.description) LIKE '$var'";
    } else {
      $where .= " AND lower(p.description) LIKE '$var'";
    }
  }

  if ($form->{"partsgroup_$i"} ne "") {
    ($null, $var) = split /--/, $form->{"partsgroup_$i"};
    $var *= 1;
    if ($var == 0) {
      # search by partsgroup, this is for the POS
      $where .= qq| AND pg.partsgroup = '$form->{"partsgroup_$i"}'|;
    } else {
      $where .= qq| AND p.partsgroup_id = $var|;
    }
  }

  if ($form->{"description_$i"} ne "") {
    $where .= " ORDER BY 3";
  } else {
    $where .= " ORDER BY 2";
  }
  
  my $query = qq|SELECT p.id, p.partnumber, p.description, p.sellprice,
                 p.listprice, p.lastcost,
		 p.unit, p.assembly, p.bin, p.onhand, p.notes AS itemnotes,
		 p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		 pg.partsgroup, p.partsgroup_id, p.partnumber AS sku,
		 p.weight,
		 t1.description AS translation,
		 t2.description AS grouptranslation
                 FROM parts p
		 LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
		 LEFT JOIN translation t1 ON (t1.trans_id = p.id AND t1.language_code = '$form->{language_code}')
		 LEFT JOIN translation t2 ON (t2.trans_id = p.partsgroup_id AND t2.language_code = '$form->{language_code}')
	         $where|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref;
  my $ptref;

  # setup exchange rates
  &exchangerate_defaults($dbh, $myconfig, $form);
  
  # taxes
  $query = qq|SELECT c.accno
	      FROM chart c
	      JOIN partstax pt ON (c.id = pt.chart_id)
	      WHERE pt.parts_id = ?|;
  my $tth = $dbh->prepare($query) || $form->dberror($query);


  # price matrix
  my $pmh = &price_matrix_query($dbh, $form);

  my $transdate = $form->datetonum($myconfig, $form->{transdate});
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    my ($dec) = ($ref->{sellprice} =~ /\.(\d+)/);
    $dec = length $dec;
    my $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

    # get taxes for part
    $tth->execute($ref->{id});

    $ref->{taxaccounts} = "";
    while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
      $ref->{taxaccounts} .= "$ptref->{accno} ";
    }
    $tth->finish;
    chop $ref->{taxaccounts};

    # get matrix
    &price_matrix($pmh, $ref, $transdate, $decimalplaces, $form, $myconfig);

    $ref->{description} = $ref->{translation} if $ref->{translation};
    $ref->{partsgroup} = $ref->{grouptranslation} if $ref->{grouptranslation};
    
    push @{ $form->{item_list} }, $ref;

  }
  
  $sth->finish;
  $dbh->disconnect;
  
}


sub price_matrix_query {
  my ($dbh, $form) = @_;
  
  my $query = qq|SELECT p.id AS parts_id, 0 AS customer_id, 0 AS pricegroup_id,
              0 AS pricebreak, p.sellprice, NULL AS validfrom, NULL AS validto,
	      '$form->{defaultcurrency}' AS curr, '' AS pricegroup
              FROM parts p
	      WHERE p.id = ?

	      UNION
  
              SELECT p.*, g.pricegroup
              FROM partscustomer p
	      LEFT JOIN pricegroup g ON (g.id = p.pricegroup_id)
	      WHERE p.parts_id = ?
	      AND p.customer_id = $form->{customer_id}
	      
	      UNION

	      SELECT p.*, g.pricegroup 
	      FROM partscustomer p 
	      LEFT JOIN pricegroup g ON (g.id = p.pricegroup_id)
	      JOIN customer c ON (c.pricegroup_id = g.id)
	      WHERE p.parts_id = ?
	      AND c.id = $form->{customer_id}
	      
	      UNION

	      SELECT p.*, '' AS pricegroup
	      FROM partscustomer p
	      WHERE p.customer_id = 0
	      AND p.pricegroup_id = 0
	      AND p.parts_id = ?

	      ORDER BY customer_id DESC, pricegroup_id DESC, pricebreak
	      
	      |;
  $dbh->prepare($query) || $form->dberror($query);

}


sub price_matrix {
  my ($pmh, $ref, $transdate, $decimalplaces, $form, $myconfig) = @_;

  $pmh->execute($ref->{id}, $ref->{id}, $ref->{id}, $ref->{id});
 
  $ref->{pricematrix} = "";
  
  my $customerprice;
  my $pricegroupprice;
  my $sellprice;
  my $baseprice;
  my $mref;
  my %p = ();
  my $i = 0;
  
  while ($mref = $pmh->fetchrow_hashref(NAME_lc)) {

    # check date
    if ($mref->{validfrom}) {
      next if $transdate < $form->datetonum($myconfig, $mref->{validfrom});
    }
    if ($mref->{validto}) {
      next if $transdate > $form->datetonum($myconfig, $mref->{validto});
    }

    # convert price
    $sellprice = $form->round_amount($mref->{sellprice} * $form->{$mref->{curr}}, $decimalplaces);

    $mref->{pricebreak} *= 1;

    if ($mref->{customer_id}) {
      $p{$mref->{pricebreak}} = $sellprice;
      $customerprice = 1;
    }

    if ($mref->{pricegroup_id}) {
      if (!$customerprice) {
	$p{$mref->{pricebreak}} = $sellprice;
	$pricegroupprice = 1;
      }
    }

    if (!$customerprice && !$pricegroupprice) {
      $p{$mref->{pricebreak}} = $sellprice;
    }
    
    if (($mref->{pricebreak} + $mref->{customer_id} + $mref->{pricegroup_id}) == 0) {
      $baseprice = $sellprice;
    }

    $i++;
 
  }
  $pmh->finish;

  if (! exists $p{0}) {
    $p{0} = $baseprice;
  }
  
  if ($i > 1) {
    $ref->{sellprice} = $p{0};
    for (sort { $a <=> $b } keys %p) { $ref->{pricematrix} .= "${_}:$p{$_} " }
  } else {
    $ref->{sellprice} = $form->round_amount($p{0} * (1 - $form->{tradediscount}), $decimalplaces);
    $ref->{pricematrix} = "0:$ref->{sellprice} " if $ref->{sellprice};
  }
  chop $ref->{pricematrix};

}


sub exchangerate_defaults {
  my ($dbh, $myconfig, $form) = @_;

  my $var;
  
  my $query;
  
  # get default currencies
  $form->{currencies} = $form->get_currencies($dbh, $myconfig);
  $form->{defaultcurrency} = substr($form->{currencies},0,3);
  
  $query = qq|SELECT buy
              FROM exchangerate
	      WHERE curr = ?
	      AND transdate = ?|;
  my $eth1 = $dbh->prepare($query) || $form->dberror($query);

  $query = qq~SELECT max(transdate || ' ' || buy || ' ' || curr)
              FROM exchangerate
	      WHERE curr = ?~;
  my $eth2 = $dbh->prepare($query) || $form->dberror($query);

  # get exchange rates for transdate or max
  foreach $var (split /:/, substr($form->{currencies},4)) {
    $eth1->execute($var, $form->{transdate});
    ($form->{$var}) = $eth1->fetchrow_array;
    if (! $form->{$var} ) {
      $eth2->execute($var);
      
      ($form->{$var}) = $eth2->fetchrow_array;
      ($null, $form->{$var}) = split / /, $form->{$var};
      $form->{$var} = 1 unless $form->{$var};
      $eth2->finish;
    }
    $eth1->finish;
  }

  $form->{$form->{currency}} = $form->{exchangerate} if $form->{exchangerate};
  $form->{$form->{currency}} ||= 1;
  $form->{$form->{defaultcurrency}} = 1;

}


1;

