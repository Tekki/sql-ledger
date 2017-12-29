#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Order entry module
# Quotation
#
#======================================================================

package OE;

use SL::PM;
use SL::CP;


sub transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
 
  my $query;
  my $var;
  my $ordnumber = 'ordnumber';
  my $quotation = '0';
  my $where;
  my $orderitems_description;
  my $orderitems_join;
  
  # remove locks
  for (qw(oe ar ap)) {
    $form->remove_locks($myconfig, $dbh, $_);
  }

  $form->{vc} =~ s/;//g;

  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  if ($form->{type} =~ /(ship|receive)_order/ || $form->{l_memo} eq 'Y') {
    $orderitems_description = ", oi.description AS memo";
    $orderitems_join = qq|JOIN orderitems oi ON (oi.trans_id = o.id)|;
  }
  
  if ($form->{detail}) {
    $orderitems_description = ", oi.description AS memo, oi.sellprice, oi.qty, oi.id AS orderitemsid, oi.ordernumber, oi.ponumber";
    $orderitems_join = qq|JOIN orderitems oi ON (oi.trans_id = o.id)| unless $orderitems_join;
  }

  unless ($form->{transdatefrom} || $form->{transdateto}) {
    ($form->{transdatefrom}, $form->{transdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }

  if ($form->{type} =~ /_quotation$/) {
    $quotation = '1';
    $ordnumber = 'quonumber';
  }
  
  my $number = $form->like(lc $form->{$ordnumber});
  my $name = $form->like(lc $form->{$form->{vc}});
  
  for (qw(department warehouse employee)) {
    if ($form->{$_}) {
      (undef, $var) = split /--/, $form->{$_};
      $where .= " AND o.${_}_id = $var";
    }
  }
  
  if ($form->{type} eq 'generate_sales_invoices') {
    $orderitems_join = qq|JOIN orderitems oi ON (oi.trans_id = o.id)|;
    if ($form->{shippeditems}) {
      $where .= " AND oi.ship > 0";
    }
  }

  my $query = qq|SELECT o.id, o.ordnumber, o.transdate, o.reqdate,
                 o.amount, ct.name, ct.$form->{vc}number, o.netamount,
                 o.$form->{vc}_id,
                 o.exchangerate,
                 o.closed, o.quonumber, o.shippingpoint, o.shipvia, o.waybill,
                 e.name AS employee, o.curr, o.ponumber,
                 o.notes, w.description AS warehouse, o.description,
                 o.backorder
                 $orderitems_description
                 FROM oe o
                 JOIN $form->{vc} ct ON (o.$form->{vc}_id = ct.id)
                 $orderitems_join
                 LEFT JOIN employee e ON (o.employee_id = e.id)
                 LEFT JOIN warehouse w ON (o.warehouse_id = w.id)
                 WHERE o.quotation = '$quotation'
                 $where|;

  # build query if type eq (ship|receive)_order
  if ($form->{type} =~ /(ship|receive)_order/) {
    
    $query .= qq|
	         AND o.quotation = '0'
           AND oi.qty > oi.ship
           AND o.id NOT IN (SELECT id FROM semaphore)|;
  }

  if ($form->{"$form->{vc}_id"}) {
    $query .= qq| AND o.$form->{vc}_id = $form->{"$form->{vc}_id"}|;
  } else {
    if ($form->{$form->{vc}} ne "") {
      $query .= " AND lower(ct.name) LIKE '$name'";
    }
    if ($form->{"$form->{vc}number"} ne "") {
      $name = $form->like(lc $form->{"$form->{vc}number"});
      $query .= " AND lower(ct.$form->{vc}number) LIKE '$name'";
    }
  }

  if ($form->{$ordnumber} ne "") {
    if ($form->{detail}) {
      $query .= " AND lower(oi.ordernumber) LIKE '$number'";
    } else {
      $query .= " AND lower(o.$ordnumber) LIKE '$number'";
    }
     
    if ($form->{type} !~ /(ship|receive|generate|consolidate)_/) {
      $form->{open} = 1;
      $form->{closed} = 1;
    }
  }
  if ($form->{ponumber} ne "") {
    $var = $form->like(lc $form->{ponumber});
    if ($form->{detail}) {
      $query .= " AND lower(oi.ponumber) LIKE '$var'";
    } else {
      $query .= " AND lower(o.ponumber) LIKE '$var'";
    }
  }

  if (!$form->{open} && !$form->{closed}) {
    $query .= " AND o.id = 0";
  } elsif (!($form->{open} && $form->{closed})) {
    $query .= ($form->{open}) ? " AND o.closed = '0'" : " AND o.closed = '1'";
  }

  if ($form->{shipvia} ne "") {
    $var = $form->like(lc $form->{shipvia});
    $query .= " AND lower(o.shipvia) LIKE '$var'";
  }
  if ($form->{waybill} ne "") {
    $var = $form->like(lc $form->{waybill});
    $query .= " AND lower(o.waybill) LIKE '$var'";
  }
  if ($form->{notes} ne "") {
    $var = $form->like(lc $form->{notes});
    $query .= " AND lower(o.notes) LIKE '$var'";
  }
  if ($form->{description} ne "") {
    $var = $form->like(lc $form->{description});
    $query .= " AND lower(o.description) LIKE '$var'";
  }
  if ($form->{memo} ne "") {
    $var = $form->like(lc $form->{memo});
    $query .= " AND o.id IN (SELECT DISTINCT trans_id
                             FROM orderitems
			     WHERE lower(description) LIKE '$var')";
  }
  if ($form->{transdatefrom}) {
    $query .= " AND o.transdate >= '$form->{transdatefrom}'";
  }
  if ($form->{transdateto}) {
    $query .= " AND o.transdate <= '$form->{transdateto}'";
  }

  my @sf = (transdate, $ordnumber, name);
  push @sf, "employee" if $form->{l_employee};
  my %ordinal = $form->ordinal_order($dbh, $query);

  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my %objid = ();
  my $i = -1;
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{exchangerate} ||= 1;
    if ($form->{open} && $form->{closed}) {
      unless ($form->{l_backorder}) {
        next if $ref->{backorder};
      }
    }
    if ($form->{detail}) {
      $i++;
      $ml = 1;
      $ref->{ordnumber} = $ref->{ordernumber} if $ref->{ordernumber};
      if ($ref->{netamount}) {
        $ml = $ref->{amount} / $ref->{netamount};
      }
      $ref->{netamount} = $ref->{sellprice} * $ref->{qty};
      $ref->{amount} = $ref->{netamount} * $ml;
      push @{ $form->{OE} }, $ref;
      $objid{vc}{$ref->{curr}}{$ref->{"$form->{vc}_id"}}++;
    } else {
      if ($ref->{id} != $objid{id}{$ref->{id}}) {
        $i++;
        push @{ $form->{OE} }, $ref;
        $objid{vc}{$ref->{curr}}{$ref->{"$form->{vc}_id"}}++;
      } else {
        $form->{OE}[$i]->{memo} .= "\n$ref->{memo}" if $ref->{memo};
      }
    }
    $objid{id}{$ref->{id}} = $ref->{id};
  }
  $sth->finish;

  $dbh->disconnect;

  my @d;
  
  if ($form->{type} =~ /^consolidate_/) {
    @d = ();
    foreach $ref (@{ $form->{OE} }) { push @d, $ref if $objid{vc}{$ref->{curr}}{$ref->{"$form->{vc}_id"}} > 1 }

    @{ $form->{OE} } = @d;
  }
  
}


sub lookup_order {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
 
  my $query;
  my $ordnumber = $dbh->quote($form->{ordnumber});
  
  if ($form->{vc} eq 'customer') {
    $query = qq|SELECT id
		FROM oe
		WHERE ordnumber = $ordnumber
		AND customer_id > 0|;
  } else {
    $query = qq|SELECT id
		FROM oe
		WHERE ordnumber = $ordnumber
		AND vendor_id > 0|;
  }
  my ($id) = $dbh->selectrow_array($query);

  $dbh->disconnect;

  $id;
  
}


sub save {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database, turn off autocommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $sth;
  my $ok;

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};
  
  (undef, $form->{employee_id}) = split /--/, $form->{employee};
  if (! $form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
    $form->{employee} = "$form->{employee}--$form->{employee_id}";
  }

  for (qw(department warehouse)) { 
    (undef, $form->{"${_}_id"}) = split(/--/, $form->{$_});
    $form->{"${_}_id"} *= 1;
  }
 
  my $sw = -1;
  my $arap = "ap";

  if ($form->{type} eq 'sales_order') {
    $sw = 1;
    $arap = "ar";
  }

  $query = qq|SELECT p.assembly, p.project_id,
              p.inventory_accno_id, p.income_accno_id, p.expense_accno_id
              FROM parts p
              WHERE p.id = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT id
              FROM vendor
              WHERE name = ?|;
  my $vth = $dbh->prepare($query) || $form->dberror($query);

  $form->{vc} =~ s/;//g;

  $query = qq|SELECT c.accno
              FROM partstax pt
              JOIN chart c ON (c.id = pt.chart_id)
              WHERE pt.parts_id = ?|;
  my $ptt = $dbh->prepare($query) || $form->dberror($query);

  if ($form->{id} *= 1) {
    $query = qq|SELECT id, aa_id FROM oe
                WHERE id = $form->{id}|;

    ($form->{id}, $form->{aa_id}) = $dbh->selectrow_array($query);
    
    if ($form->{id}) {
      if ($form->{type} =~ /_order$/) {
        &adj_onhand($dbh, $form, $sw) unless $form->{aa_id};
      }

      for (qw(dpt_trans orderitems shipto cargo acc_trans payment status inventory)) {
        $query = qq|DELETE FROM $_
                    WHERE trans_id = $form->{id}|;
        $dbh->do($query) || $form->dberror($query);
      }

      $query = qq|DELETE FROM $arap
                  WHERE id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);

    } else {
      $query = qq|INSERT INTO oe (id)
                  VALUES ($form->{id})|;
      $dbh->do($query) || $form->dberror($query);
    }
  }
 
  if (! $form->{id}) {
    
    my $uid = localtime;
    $uid .= $$;
    
    $query = qq|INSERT INTO oe (ordnumber, employee_id)
		VALUES ('$uid', $form->{employee_id})|;
    $dbh->do($query) || $form->dberror($query);
   
    $query = qq|SELECT id FROM oe
                WHERE ordnumber = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;
    
  }

  my $i;
  my $ml;
  my $amount;
  my $linetotal;
  my $discount;
  my $project_id;
  my $taxrate;
  my $fxsellprice;
  my %taxbase;
  my $taxbase;
  my @taxaccounts;
  my %taxaccounts;
  my $netamount = 0;
  my $lineitemdetail;

  my $uid = localtime;
  $uid .= $$;

  for $i (1 .. $form->{rowcount}) {

    for (qw(qty ship)) { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) }
     
    $form->{"discount_$i"} = $form->parse_amount($myconfig, $form->{"discount_$i"}) / 100;
    $form->{"sellprice_$i"} = $form->parse_amount($myconfig, $form->{"sellprice_$i"});

    if ($form->{"qty_$i"}) {

      $form->{"cost_$i"} = $form->parse_amount($myconfig, $form->{"cost_$i"});
      if ($form->{"costvendorid_$i"}) {
        delete $form->{"costvendorid_$i"} unless $form->{"costvendor_$i"};
      } else {
        if ($form->{"costvendor_$i"}) {
          $vth->execute($form->{"costvendor_$i"});
          ($form->{"costvendorid_$i"}) = $vth->fetchrow_array;
          $vth->finish;
        }
      }
      if ($form->{"costvendorid_$i"} *= 1) {
        delete $form->{"costvendor_$i"};
      }

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
      
      my ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};

      $fxsellprice = $form->round_amount($form->{"sellprice_$i"}, $decimalplaces);

      $discount = $form->round_amount($form->{"sellprice_$i"} * $form->{"discount_$i"}, $decimalplaces);
      $form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"} - $discount, $decimalplaces);

      $linetotal = $form->round_amount($form->{"sellprice_$i"} * $form->{"qty_$i"}, $form->{precision});
      
      @taxaccounts = split / /, $form->{"taxaccounts_$i"};
      $ml = 1;
      $tax = 0;
      
      for (0 .. 1) {
        $taxrate = 0;

        for (@taxaccounts) { $taxrate += $form->{"${_}_rate"} if ($form->{"${_}_rate"} * $ml) > 0 }
        
        $taxrate *= $ml;
        $taxamount = $linetotal * $taxrate / (1 + $taxrate);
        $taxbase = ($linetotal - $taxamount);
	
        for my $item (@taxaccounts) {
          if (($form->{"${item}_rate"} * $ml) > 0) {

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

      # if kit calculate taxes
      if ($form->{"kit_$i"}) {
        %p = split /[: ]/, $form->{"pricematrix_$i"};
        for (split / /, $form->{"kit_$i"}) {
          @p = split /:/, $_;
          for $n (3 .. $#p) {
            if ($p[2]) {
              if ($p{0}) {
                $d = $form->round_amount($p[2] * $form->{"discount_$i"}, $decimalplaces);

                $lt = $form->round_amount(($p[2] - $d) * $p[1] * $form->{"sellprice_$i"}/$p{0} * $form->{"qty_$i"}, $form->{precision});

                if ($form->{taxincluded}) {
                  $taxaccounts{$p[$n]} += $lt * $form->{"$p[$n]_rate"} / (1 + $form->{"$p[$n]_rate"}) if $form->{"$p[$n]_rate"} != -1;
                } else {
                  $taxaccounts{$p[$n]} += $lt * $form->{"$p[$n]_rate"};
                }
              }
            }
          }
        }
      }

      $netamount += $form->{"sellprice_$i"} * $form->{"qty_$i"};
      
      $project_id = 'NULL';
      if ($form->{"projectnumber_$i"} ne "") {
        (undef, $project_id) = split /--/, $form->{"projectnumber_$i"};
      }
      $project_id = $form->{"project_id_$i"} if $form->{"project_id_$i"};
      
      # add/save detail record in orderitems table
      $query = qq|INSERT INTO orderitems (description, trans_id, parts_id)
		  VALUES ('$uid', $form->{id}, $form->{"id_$i"})|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|SELECT id
		  FROM orderitems
		  WHERE description = '$uid'|;
      ($form->{"orderitems_id_$i"}) = $dbh->selectrow_array($query);

      &adj_inventory($dbh, $form, $i) unless $form->{aa_id};

      $lineitemdetail = ($form->{"lineitemdetail_$i"}) ? 1 : 0;
      
      $query = qq|UPDATE orderitems SET
		  description = |.$dbh->quote($form->{"description_$i"}).qq|,
		  qty = $form->{"qty_$i"},
		  sellprice = $fxsellprice,
		  discount = $form->{"discount_$i"},
		  unit = |.$dbh->quote($form->{"unit_$i"}).qq|,
		  reqdate = |.$form->dbquote($form->{"reqdate_$i"}, SQL_DATE).qq|,
		  project_id = $project_id,
		  ship = $form->{"ship_$i"},
		  serialnumber = |.$dbh->quote($form->{"serialnumber_$i"}).qq|,
		  ordernumber = |.$dbh->quote($form->{"ordernumber_$i"}).qq|,
		  ponumber = |.$dbh->quote($form->{"customerponumber_$i"}).qq|,
		  itemnotes = |.$dbh->quote($form->{"itemnotes_$i"}).qq|,
		  lineitemdetail = '$lineitemdetail',
      cost = $form->{"cost_$i"},
      vendor = |.$dbh->quote($form->{"costvendor_$i"}).qq|,
      vendor_id = $form->{"costvendorid_$i"}
		  WHERE id = $form->{"orderitems_id_$i"}
		  AND trans_id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);

      $form->{"sellprice_$i"} = $fxsellprice;

      # add package
      $ok = ($form->{"package_$i"} ne "") ? 1 : 0;
      for (qw(netweight grossweight volume)) {
        $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"});
        $ok = 1 if $form->{"${_}_$i"};
      }
      if ($ok) {
        $query = qq|INSERT INTO cargo (id, trans_id, package, netweight,
                    grossweight, volume) VALUES ( $form->{"orderitems_id_$i"},
		    $form->{id}, |
		    .$dbh->quote($form->{"package_$i"}).qq|,
		    $form->{"netweight_$i"}, $form->{"grossweight_$i"},
		    $form->{"volume_$i"})|;
        $dbh->do($query) || $form->dberror($query);
      }
      
      if ($form->{type} =~ /_order/) {
        if ($form->{"netweight_$i"} && $form->{"ship_$i"}) {
          $query = qq|UPDATE parts SET
                      weight = abs($form->{"netweight_$i"} / $form->{"ship_$i"} * 1.0)
                WHERE id = $form->{"id_$i"}|;
          $dbh->do($query) || $form->dberror($query);
        }
      }
    }
    $form->{"discount_$i"} *= 100;
  }


  # set values which could be empty
  for (qw(vendor_id customer_id taxincluded closed quotation)) { $form->{$_} *= 1 }

  # add up the tax
  my $tax = 0;
  for (keys %taxaccounts) { $tax += $form->round_amount($taxaccounts{$_}, $form->{precision}) }
  $netamount -= $tax if $form->{taxincluded};

  $amount = $form->round_amount($netamount + $tax, $form->{precision});
  $netamount = $form->round_amount($netamount, $form->{precision});

  $form->{exchangerate} = $form->parse_amount($myconfig, $form->{exchangerate}) || 1;
  
  my $quotation;
  my $ordnumber;
  my $numberfld;
  if ($form->{type} =~ /_order$/) {
    $quotation = "0";
    $ordnumber = "ordnumber";
    $numberfld = ($form->{vc} eq 'customer') ? "sonumber" : "ponumber";
  } else {
    $quotation = "1";
    $ordnumber = "quonumber";
    $numberfld = ($form->{vc} eq 'customer') ? "sqnumber" : "rfqnumber";
  }

  $form->{$ordnumber} = $form->update_defaults($myconfig, $numberfld, $dbh) unless $form->{$ordnumber}; 
  
  $form->{backorder} *= 1;
  $form->{terms} *= 1;

  # save OE record
  $query = qq|UPDATE oe set
              ordnumber = |.$dbh->quote($form->{ordnumber}).qq|,
              quonumber = |.$dbh->quote($form->{quonumber}).qq|,
              description = |.$dbh->quote($form->{description}).qq|,
              transdate = '$form->{transdate}',
              vendor_id = $form->{vendor_id},
              customer_id = $form->{customer_id},
              amount = $amount,
              netamount = $netamount,
              reqdate = |.$form->dbquote($form->{reqdate}, SQL_DATE).qq|,
              taxincluded = '$form->{taxincluded}',
              shippingpoint = |.$dbh->quote($form->{shippingpoint}).qq|,
              shipvia = |.$dbh->quote($form->{shipvia}).qq|,
              waybill = |.$dbh->quote($form->{waybill}).qq|,
              notes = |.$dbh->quote($form->{notes}).qq|,
              intnotes = |.$dbh->quote($form->{intnotes}).qq|,
              curr = '$form->{currency}',
              closed = '$form->{closed}',
              quotation = '$quotation',
              department_id = $form->{department_id},
              employee_id = $form->{employee_id},
              language_code = '$form->{language_code}',
              ponumber = |.$dbh->quote($form->{ponumber}).qq|,
              terms = $form->{terms},
              warehouse_id = $form->{warehouse_id},
              exchangerate = $form->{exchangerate},
              backorder = '$form->{backorder}'
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $form->{ordtotal} = $amount;

  # add shipto
  $form->{name} = $form->{$form->{vc}};
  $form->{name} =~ s/--$form->{"$form->{vc}_id"}//;
  $form->add_shipto($dbh, $form->{id});

  # save printed, emailed, queued
  $form->save_status($dbh); 

  # save references
  $form->save_reference($dbh, $form->{type});

  # update exchangerate
  $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, $form->{exchangerate});
  
  if ($form->{department_id}) {
    $query = qq|INSERT INTO dpt_trans (trans_id, department_id)
                VALUES ($form->{id}, $form->{department_id})|;
    $dbh->do($query) || $form->dberror($query);
  }
      
  if ($form->{type} =~ /_order$/) {
    # adjust onhand
    &adj_onhand($dbh, $form, $sw * -1) unless $form->{aa_id};
  }


  my %audittrail = ( tablename	=> 'oe',
                     reference	=> ($form->{type} =~ /_order$/) ? $form->{ordnumber} : $form->{quonumber},
                     formname	=> $form->{type},
                     action	=> 'saved',
                     id		=> $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);

  $form->save_recurring($dbh, $myconfig);
  
  $form->remove_locks($myconfig, $dbh, 'oe');


  if ($form->{type} =~ /_order$/) {
    use SL::AA;

    my $t = $form->{type};

    for $i (1 .. $form->{paidaccounts}) {
      if ($form->{"paid_$i"}) {
        $query = qq|INSERT INTO $arap (id) VALUES ($form->{id})|;
        $dbh->do($query) || $form->dberror($query);

        $arap = uc $arap;
        $query = qq|SELECT c.accno
                    FROM $form->{vc} vc
                    JOIN chart c ON (c.id = vc.prepayment_accno_id)
                    WHERE vc.id = $form->{"$form->{vc}_id"}|;
        ($form->{$arap}) = $dbh->selectrow_array($query);

        unless ($form->{$arap}) {
          my $asc = ($arap eq 'AR') ? "DESC" : "ASC";
          $query = qq|SELECT accno
                      FROM chart
                      WHERE link = '$arap'
                      ORDER BY accno $asc|;
          ($form->{$arap}) = $dbh->selectrow_array($query);
        }

        if ($form->{$arap}) {
          $form->{type} = "transaction";
          $form->{exchangerate} = $form->format_amount($myconfig, $form->{exchangerate});
          my $n = $form->{paidaccounts} - 1;
          $form->{"${arap}_paid_$form->{paidaccounts}"} = $form->{"${arap}_paid_$n"};
          $form->{"payment_$form->{paidaccounts}"} = $form->{"payment_$n"};
          delete $form->{rowcount};

          AA->post_transaction($myconfig, $form, $dbh);
        }

        last;
      }
    }
    $form->{type} = $t;
  }

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}



sub delete {
  my ($self, $myconfig, $form, $spool) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  $form->{id} *= 1;
  
  # delete spool files
  my $query = qq|SELECT spoolfile FROM status
                 WHERE trans_id = $form->{id}
		 AND spoolfile IS NOT NULL|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $spoolfile;
  my @spoolfiles = ();

  while (($spoolfile) = $sth->fetchrow_array) {
    push @spoolfiles, $spoolfile;
  }
  $sth->finish;

  $form->reset_shipped($dbh, $form->{id}, ($form->{type} eq 'purchase_order') ? -1 : 1);

  for (qw(dpt_trans inventory status orderitems shipto cargo acc_trans payment)) {
    $query = qq|DELETE FROM $_ WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  for (qw(recurring recurringemail recurringprint)) {
    $query = qq|DELETE FROM $_ WHERE id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }

  my $arap = ($form->{vc} eq 'customer') ? 'ar' : 'ap';
  $query = qq|DELETE FROM $arap WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # delete OE record
  $query = qq|DELETE FROM oe
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  my %audittrail = ( tablename	=> 'oe',
                     reference	=> ($form->{type} =~ /_order$/) ? $form->{ordnumber} : $form->{quonumber},
		     formname	=> $form->{type},
		     action	=> 'deleted',
		     id		=> $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);

  $form->delete_references($dbh);

  $form->remove_locks($myconfig, $dbh, 'oe');

  my $rc = $dbh->commit;
  $dbh->disconnect;

  if ($rc) {
    foreach $spoolfile (@spoolfiles) {
      if (-f "$spool/$myconfig->{dbname}/$spoolfile") {
	unlink "$spool/$myconfig->{dbname}/$spoolfile";
      }
    }
  }
  
  $rc;
  
}



sub retrieve {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $sth;
  my $ith;
  my $var;
  my $ref;

  my %defaults = $form->get_defaults($dbh, \@{[qw(weightunit closedto precision referenceurl lock_%)]});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  $form->get_peripherals($dbh);
  
  $form->{currencies} = $form->get_currencies($myconfig, $dbh);
  
  $form->{ARAP} = ($form->{vc} eq 'customer') ? 'AR' : 'AP';

  unless ($form->{readonly}) {
    for (qw(oe ar ap)) {
      $form->remove_locks($myconfig, $dbh, lc $_);
    }
  }

  # payment accounts
  $query = qq|SELECT c.accno, c.description, c.link,
              l.description AS translation
              FROM chart c
              LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
              WHERE c.link LIKE '%$form->{ARAP}_paid%'
              AND c.closed = '0'
              ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{"$form->{ARAP}_paid"} }, { accno => $ref->{accno},
                                   description => $ref->{description} };
  }
  $sth->finish;


  if ($form->{id} *= 1) {
    
    # retrieve order
    $query = qq|SELECT o.ordnumber, o.transdate, o.reqdate, o.terms,
                o.taxincluded, o.shippingpoint, o.shipvia, o.waybill,
		o.notes, o.intnotes,
		o.curr AS currency, e.name AS employee, o.employee_id,
		o.$form->{vc}_id, vc.name AS $form->{vc}, o.amount AS invtotal,
		o.closed, o.quonumber, o.department_id,
		d.description AS department, o.language_code, o.ponumber,
		o.warehouse_id, w.description AS warehouse, o.description,
		o.aa_id, o.backorder
		FROM oe o
	        JOIN $form->{vc} vc ON (o.$form->{vc}_id = vc.id)
	        LEFT JOIN employee e ON (o.employee_id = e.id)
	        LEFT JOIN department d ON (o.department_id = d.id)
	        LEFT JOIN warehouse w ON (o.warehouse_id = w.id)
		WHERE o.id = $form->{id}|;
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
    $ith = $dbh->prepare($query) || $form->dberror($query);

    $query = qq|SELECT * FROM shipto
                WHERE trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    # get printed, emailed and queued
    $query = qq|SELECT s.printed, s.emailed, s.spoolfile, s.formname
                FROM status s
		WHERE s.trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $form->{printed} .= "$ref->{formname} " if $ref->{printed};
      $form->{emailed} .= "$ref->{formname} " if $ref->{emailed};
      $form->{queued} .= "$ref->{formname} $ref->{spoolfile} " if $ref->{spoolfile};
    }
    $sth->finish;
    for (qw(printed emailed queued)) { $form->{$_} =~ s/ +$//g }

    # retrieve individual items
    $query = qq|SELECT o.id AS orderitems_id,
                p.partnumber, p.assembly, o.description, o.qty,
		o.sellprice, o.parts_id AS id, o.unit, o.discount, p.bin,
                o.reqdate, o.project_id, o.ship, o.serialnumber,
		o.itemnotes, o.lineitemdetail, o.ordernumber,
		o.ponumber AS customerponumber,
                o.cost, o.vendor_id AS costvendorid, o.vendor AS costvendor,
		pr.projectnumber,
		pg.partsgroup, p.partsgroup_id, p.partnumber AS sku,
		p.listprice, p.lastcost, p.sellprice AS sell, p.weight,
		p.onhand,
		p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		t.description AS partsgrouptranslation,
		c.package, c.netweight, c.grossweight, c.volume,
                v.name
		FROM orderitems o
		JOIN parts p ON (o.parts_id = p.id)
		LEFT JOIN project pr ON (o.project_id = pr.id)
		LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		LEFT JOIN translation t ON (t.trans_id = p.partsgroup_id AND t.language_code = '$form->{language_code}')
		LEFT JOIN cargo c ON (c.id = o.id AND c.trans_id = o.trans_id)
                LEFT JOIN vendor v ON (v.id = o.vendor_id)
		WHERE o.trans_id = $form->{id}
                ORDER BY o.id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    # foreign exchange rates
    $form->exchangerate_defaults($dbh, $myconfig, $form);

    # query for price matrix
    my $pmh = PM->price_matrix_query($dbh, $form);

    # taxes
    $query = qq|SELECT c.accno
		FROM chart c
		JOIN partstax pt ON (pt.chart_id = c.id)
		WHERE pt.parts_id = ?|;
    my $tth = $dbh->prepare($query) || $form->dberror($query);
   
    my $taxrate;
    my $ptref;
    my $sellprice;
    my $listprice;

    if ($form->{vc} eq 'customer') {
      $query = qq|SELECT p.id, sellprice, a.qty
                  FROM assembly a
                  JOIN parts p ON (p.id = a.parts_id)
                  WHERE a.aid = ?|;
    } else {
      $query = qq|SELECT p.id, lastcost AS sellprice, a.qty
                  FROM assembly a
                  JOIN parts p ON (p.id = a.parts_id)
                  WHERE a.aid = ?|;
    }
    my $ath = $dbh->prepare($query) || $form->dberror($query);

    my $aref;
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

      $ref->{costvendor} ||= $ref->{name};

      ($decimalplaces) = ($ref->{sellprice} =~ /\.(\d+)/);
      $decimalplaces = length $decimalplaces;
      $decimalplaces = ($decimalplaces > $form->{precision}) ? $decimalplaces : $form->{precision};

      $tth->execute($ref->{id});

      $ref->{taxaccounts} = "";
      $taxrate = 0;
      
      while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
        $ref->{taxaccounts} .= "$ptref->{accno} ";
        $taxrate += $form->{"$ptref->{accno}_rate"};
      }
      $tth->finish;
      chop $ref->{taxaccounts};

      # preserve prices
      $sellprice = $ref->{sellprice};

      # sell for barcodes
      if ($form->{vc} eq 'customer') {
	$ref->{sell} = $ref->{sellprice};
      }

      for (qw(listprice lastcost)) { $ref->{$_} = $form->round_amount($ref->{$_} / $form->{$form->{currency}}, $decimalplaces) }

      # partnumber and price matrix
      PM->price_matrix($pmh, $ref, $form->{transdate}, $decimalplaces, $form, $myconfig);

      my %p = split /[ :]/, $ref->{pricematrix};
      $p{0} = $ref->{sellprice};
      $ref->{pricematrix} = "";
      for (sort keys %p) {
        $ref->{pricematrix} .= "$_:$p{$_} ";
      }
      chop $ref->{pricematrix};

      $ref->{sellprice} = $sellprice;

      $ref->{partsgroup} = $ref->{partsgrouptranslation} if $ref->{partsgrouptranslation};

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

          $aref->{sellprice} = $form->round_amount($aref->{sellprice}, $form->{precision});

          $ref->{kit} .= "$aref->{id}:$aref->{qty}:$aref->{sellprice}$accno ";
        }
        chop $ref->{kit};
        $ath->finish;
      }

      if ($form->{warehouse_id}) {
        $ith->execute($ref->{id});
        ($ref->{onhand}) = $ith->fetchrow_array;
        $ith->finish;
      }
      
      push @{ $form->{form_details} }, $ref;
      
    }
    $sth->finish;

    # get payments
    $query = qq|SELECT c.accno, c.description, c.closed, ac.source, ac.amount,
                ac.memo, ac.transdate, ac.cleared, ac.id, y.exchangerate,
                l.description AS translation,
                pm.description AS paymentmethod, y.paymentmethod_id
                FROM acc_trans ac
                JOIN chart c ON (c.id = ac.chart_id)
                LEFT JOIN payment y ON (y.trans_id = ac.trans_id AND ac.id = y.id)
                LEFT JOIN paymentmethod pm ON (pm.id = y.paymentmethod_id)
                LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
                WHERE ac.trans_id = $form->{id}
                AND c.link LIKE '%$form->{ARAP}_paid%'
                AND ac.fx_transaction = '0'
                ORDER BY ac.transdate|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $resort;

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{description} = $ref->{translation} if $ref->{translation};
      $ref->{exchangerate} ||= 1;
      push @{ $form->{acc_trans}{"$form->{ARAP}_paid"} }, $ref;

      if ($ref->{closed}) {
        $resort = 1;
        push @{ $form->{"$form->{ARAP}_paid"} }, { accno => $ref->{accno},
                                       description => $ref->{description} };
      }

    }
    $sth->finish;

    if ($resort) {
      @{ $form->{"$form->{ARAP}_paid"} } = sort { $a->{accno} cmp $b->{accno} } @{ $form->{"$form->{ARAP}_paid"} };
    }

    # get recurring transaction
    $form->get_recurring($dbh);
    
    # get document references
    $form->all_references($dbh);

    $form->create_lock($myconfig, $dbh, $form->{id}, 'oe');
    $form->create_lock($myconfig, $dbh, $form->{id}, lc $form->{ARAP}, 1);

  } else {
    $form->{transdate} = $form->current_date($myconfig);

    # get last name used
    $form->lastname_used($myconfig, $dbh, $form->{vc}) unless $form->{"$form->{vc}_id"};
    
    delete $form->{notes};

  }

  # get paymentmethod
  $query = qq|SELECT *
              FROM paymentmethod
              ORDER BY rn|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  @{ $form->{"all_paymentmethod"} } = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{"all_paymentmethod"} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}


sub order_details {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query;
  my $sth;
  my $ref;
    
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

  my %translations;

  $query = qq|SELECT p.description, t.description
              FROM project p
              LEFT JOIN translation t ON (t.trans_id = p.id AND t.language_code = '$form->{language_code}')
              WHERE id = ?|;
  my $prh = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT inventory_accno_id, income_accno_id, expense_accno_id,
              assembly, tariff_hscode AS hscode, countryorigin,
              drawing, toolnumber, barcode
              FROM parts
              WHERE id = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);

  my $sortby;
  
  # sort items by project and partsgroup
  for $i (1 .. $form->{rowcount} - 1) {

    if ($form->{"id_$i"}) {
      # account numbers
      $pth->execute($form->{"id_$i"});
      $ref = $pth->fetchrow_hashref(NAME_lc);
      for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }
      $pth->finish;

      $projectnumber_id = 0;
      $projectnumber = "";
      $partsgroup = "";
      $form->{projectnumber} = "";

      if ($form->{groupprojectnumber} || $form->{grouppartsgroup}) {

        $inventory_accno_id = ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) ? "1" : "";

        if ($form->{groupprojectnumber}) {
          ($projectnumber, $projectnumber_id) = split /--/, $form->{"projectnumber_$i"};
        }
        if ($form->{grouppartsgroup}) {
          ($partsgroup) = split /--/, $form->{"partsgroup_$i"};
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
          $form->{projectnumber} .= $partsgroup;
        }

        $form->format_string((projectnumber));

      }

      $sortby = qq|$projectnumber$form->{partsgroup}|;
      if ($form->{sortby} ne 'runningnumber') {
        for (qw(partnumber description bin)) {
          $sortby .= $form->{"${_}_$i"} if $form->{sortby} eq $_;
        }
      }

      push @sortlist, [ $i, qq|$projectnumber$form->{partsgroup}$inventory_accno_id|, $form->{projectnumber}, $projectnumber_id, $partsgroup, $sortby ];
    }

    # last package number
    $form->{packages} = $form->{"package_$i"} if $form->{"package_$i"};
    
  }

  my @p = ();
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

  $form->{orddescription} = $form->{quodescription} = $form->{description};

  for (qw(description projectnumber)) { delete $form->{$_} }

  # sort the whole thing by project and group
  @sortlist = sort { $a->[5] cmp $b->[5] } @sortlist;
  

  # if there is a warehouse limit picking
  if ($form->{warehouse_id} && $form->{formname} =~ /(pick|packing)_list/) {
    # run query to check for inventory
    $query = qq|SELECT sum(qty) AS qty
                FROM inventory
		WHERE parts_id = ?
		AND warehouse_id = ?|;
    $sth = $dbh->prepare($query) || $form->dberror($query);

    for $i (1 .. $form->{rowcount} - 1) {
      $sth->execute($form->{"id_$i"}, $form->{warehouse_id}) || $form->dberror;

      ($qty) = $sth->fetchrow_array;
      $sth->finish;

      $form->{"qty_$i"} = 0 if $qty == 0;
      
      if ($form->parse_amount($myconfig, $form->{"ship_$i"}) > $qty) {
        $form->{"ship_$i"} = $form->format_amount($myconfig, $qty);
      }
    }
  }
    

  my $runningnumber = 1;
  my $sameitem = "";
  my $subtotal;
  my $k = scalar @sortlist;
  my $j = 0;

  @{ $form->{lineitems} } = ();
  @{ $form->{taxrates} } = ();

  for my $item (@sortlist) {
    $i = $item->[0];
    $j++;

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
          if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"} || $form->{"kit_$i"}) {
            push(@{ $form->{part} }, "");
            push(@{ $form->{service} }, NULL);
          } else {
            push(@{ $form->{part} }, NULL);
            push(@{ $form->{service} }, "");
          }

          push(@{ $form->{description} }, $item->[2]);
          for (qw(taxrates runningnumber number sku qty ship unit bin serialnumber ordernumber customerponumber requiredate projectnumber sell sellprice listprice netprice discount discountrate linetotal itemnotes lineitemdetail package netweight grossweight volume countryorigin hscode drawing toolnumber barcode)) { push(@{ $form->{$_} }, "") }
          push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });
        }
      }
    }

    $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"});
    $form->{"ship_$i"} = $form->parse_amount($myconfig, $form->{"ship_$i"});
    
    if ($form->{"qty_$i"}) {
      
      $form->{totalqty} += $form->{"qty_$i"};
      $form->{totalship} += $form->{"ship_$i"};
      $form->{totalnetweight} += $form->parse_amount($myconfig, $form->{"netweight_$i"});
      $form->{totalgrossweight} += $form->parse_amount($myconfig, $form->{"grossweight_$i"});

      # add number, description and qty to $form->{number}, ....
      push(@{ $form->{runningnumber} }, $runningnumber++);
      push(@{ $form->{number} }, $form->{"partnumber_$i"});
      push(@{ $form->{requiredate} }, $form->{"reqdate_$i"});

      for (qw(sku description unit bin serialnumber ordernumber customerponumber sell sellprice listprice itemnotes lineitemdetail package netweight grossweight volume countryorigin hscode drawing toolnumber barcode)) { push(@{ $form->{$_} }, $form->{"${_}_$i"}) }

      # if not grouped remove id
      ($projectnumber) = split /--/, $form->{"projectnumber_$i"};
      push(@{ $form->{projectnumber} }, $projectnumber);

      push(@{ $form->{qty} }, $form->format_amount($myconfig, $form->{"qty_$i"}));
      push(@{ $form->{ship} }, $form->format_amount($myconfig, $form->{"ship_$i"}));
      my $sellprice = $form->parse_amount($myconfig, $form->{"sellprice_$i"});
      my ($dec) = ($sellprice =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > $form->{precision}) ? $dec : $form->{precision};
      
      my $discount = $form->round_amount($sellprice * $form->parse_amount($myconfig, $form->{"discount_$i"}) / 100, $decimalplaces);

      # keep a netprice as well, (sellprice - discount)
      $form->{"netprice_$i"} = $sellprice - $discount;

      my $linetotal = $form->round_amount($form->{"qty_$i"} * $form->{"netprice_$i"}, $form->{precision});

      if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"} || $form->{"kit_$i"}) {
        push(@{ $form->{part} }, $form->{"sku_$i"});
        push(@{ $form->{service} }, NULL);
        $form->{totalparts} += $linetotal;
            } else {
        push(@{ $form->{service} }, $form->{"sku_$i"});
        push(@{ $form->{part} }, NULL);
        $form->{totalservices} += $linetotal;
      }

      push(@{ $form->{netprice} }, ($form->{"netprice_$i"}) ? $form->format_amount($myconfig, $form->{"netprice_$i"}, $decimalplaces) : " ");
      
      $discount = ($discount) ? $form->format_amount($myconfig, $discount * -1, $decimalplaces) : " ";

      push(@{ $form->{discount} }, $discount);
      push(@{ $form->{discountrate} }, $form->format_amount($myconfig, $form->{"discount_$i"}));
      
      $form->{ordtotal} += $linetotal;

      # this is for the subtotals for grouping
      $subtotal += $linetotal;

      $form->{"linetotal_$i"} = $form->format_amount($myconfig, $linetotal, $form->{precision}, 0);
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
	
      if ($form->{"assembly_$i"} || $form->{"kit_$i"}) {
        $form->{stagger} = -1;
        &assembly_details($myconfig, $form, $dbh, $form->{"id_$i"}, $form->{"qty_$i"}, $form->{"kit_$i"});
        if ($form->{"kit_$i"}) {
          %p = split /[: ]/, $form->{"pricematrix_$i"};
          for (split / /, $form->{"kit_$i"}) {
            @p = split /:/, $_;
            for $n (1 .. $#p) {
              if ($form->{taxaccounts} =~ /$p[$n]/) {
                if ($p[0]) {
                  if ($p{0}) {
                    $d = $form->round_amount($p{0} * $form->{"discount_$i"}/100, $decimalplaces);
                    $p = $form->round_amount($p{0} - $d, $decimalplaces);
                    $p = $form->round_amount($p * $form->{"qty_$i"}, $form->{precision});
                    $d = $form->round_amount($p[0] * $form->{"discount_$i"}/100, $decimalplaces);
                    if ($p) {

                      $lt = ($p[0] - $d) * $linetotal/$p * $form->{"qty_$i"};

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

            if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) {
              push(@{ $form->{part} }, "");
              push(@{ $form->{service} }, NULL);
            } else {
              push(@{ $form->{service} }, "");
              push(@{ $form->{part} }, NULL);
            }

            for (qw(taxrates runningnumber number sku qty ship unit bin serialnumber ordernumber customerponumber requiredate projectnumber sell sellprice listprice netprice discount discountrate itemnotes lineitemdetail package netweight grossweight volume countryorigin hscode drawing toolnumber barcode)) { push(@{ $form->{$_} }, "") }

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
            
            if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) {
              push(@{ $form->{part} }, "");
              push(@{ $form->{service} }, NULL);
            } else { 
              push(@{ $form->{service} }, "");
              push(@{ $form->{part} }, NULL);
            } 
           
            for (qw(taxrates runningnumber number sku qty ship unit bin serialnumber ordernumber customerponumber requiredate projectnumber sell sellprice listprice netprice discount discountrate itemnotes lineitemdetail package netweight grossweight volume countryorigin hscode drawing toolnumber barcode)) { push(@{ $form->{$_} }, "") }

            push(@{ $form->{description} }, $form->{groupsubtotaldescription});
            push(@{ $form->{linetotal} }, $form->format_amount($myconfig, $subtotal, $form->{precision}));
            push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });
          }
        }
      }
    }
  }


  $tax = 0;
  for (sort keys %taxaccounts) {
    $taxaccounts{$_} = $form->round_amount($taxaccounts{$_}, $form->{precision});
    $tax += $taxaccounts{$_};
    $form->{"${_}_taxbaseinclusive"} = $taxbase{$_} + $taxaccounts{$_};
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
    push(@{ $form->{linetax} }, $form->format_amount($myconfig, $ref->{tax}, $form->{precision}, ""));
  }
  
  $form->{totaltax} = $form->format_amount($myconfig, $tax, $form->{precision}, "");
  
  for (qw(totalparts totalservices)) { $form->{$_} = $form->format_amount($myconfig, $form->{$_}, $form->{precision}) }
  for (qw(totalqty totalship totalnetweight totalgrossweight)) { $form->{$_} = $form->format_amount($myconfig, $form->{$_}) }
  
  if ($form->{taxincluded}) {
    $form->{subtotal} = $form->{ordtotal} - $tax;
  } else {
    $form->{subtotal} = $form->{ordtotal};
    $form->{ordtotal} = $form->{ordtotal} + $tax;
  }

  for (sort keys %taxaccounts) {
    push(@{ $form->{taxdescription} }, $form->{"${_}_description"});
    push(@{ $form->{taxnumber} }, $form->{"${_}_taxnumber"});

    push(@{ $form->{taxbaseinclusive} }, $form->format_amount($myconfig, $form->{"${_}_taxbaseinclusive"}, $form->{precision}));
    push(@{ $form->{taxbase} }, $form->format_amount($myconfig, $taxbase{$_}, $form->{precision}));
    push(@{ $form->{tax} }, $form->format_amount($myconfig, $taxaccounts{$_}, $form->{precision}, 0));
    push(@{ $form->{taxrate} }, $form->format_amount($myconfig, $form->{"${_}_rate"} * 100, undef, 0));

    $form->{"${_}_taxbaseinclusive"} = $form->format_amount($myconfig, $form->{"${_}_taxbaseinclusive"}, $form->{precision});
    $form->{"${_}_taxbase"} = $form->format_amount($myconfig, $taxbase{$_}, $form->{precision});
    $form->{"${_}_tax"} = $form->format_amount($myconfig, $form->{"${_}_tax"}, $form->{precision}, 0);

    $form->{"${_}_taxrate"} = $form->format_amount($myconfig, $form->{"${_}_rate"} * 100, undef, 0);

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
  $form->{payment_method} = $form->{"paymentmethod_$form->{paidaccounts}"};
  $form->{payment_method} =~ s/--.*//;
  $form->{payment_accno} = $form->{"AR_paid_$form->{paidaccounts}"};
  $form->{payment_accno} =~ s/--.*//;

  $form->{total} = $form->format_amount($myconfig, $form->{ordtotal} - $form->{paid}, $form->{precision}, 0);
  $form->{paid} = $form->format_amount($myconfig, $form->{paid}, $form->{precision});
  $form->{subtotal} = $form->format_amount($myconfig, $form->{subtotal}, $form->{precision}, 0);

  my $whole;
  ($whole, $form->{decimal}) = split /\./, $form->{ordtotal};
  $form->{decimal} .= "00";
  $form->{decimal} = substr($form->{decimal}, 0, 2);
  $form->{text_decimal} = $c->num2text($form->{decimal} * 1);
  $form->{text_amount} = $c->num2text($whole);
  $form->{integer_amount} = $whole;
  
  # format amounts
  $form->{quototal} = $form->{ordtotal} = $form->format_amount($myconfig, $form->{ordtotal}, $form->{precision}, 0);

  $form->format_string(qw(text_amount text_decimal));

  $dbh->disconnect;

}


sub assembly_details {
  my ($myconfig, $form, $dbh, $id, $qty, $kit) = @_;

  my $sm = "";
  my $spacer;

  $form->{stagger}++;
  if ($form->{format} eq 'html') {
    $spacer = "&nbsp;" x (3 * ($form->{stagger} - 1)) if $form->{stagger} > 1;
  }
  if ($form->{format} =~ /(ps|pdf)/) {
    if ($form->{stagger} > 1) {
      $spacer = ($form->{stagger} - 1) * 3;
      $spacer = '\rule{'.$spacer.'mm}{0mm}';
    }
  }

  # get parts and push them onto the stack
  my $sortorder = "";
  
  if ($form->{grouppartsgroup}) {
    $sortorder = qq| ORDER BY pg.partsgroup, a.id|;
  } else {
    $sortorder = qq| ORDER BY a.id|;
  }
  
  my $where = ($form->{formname} eq 'work_order') ? "1 = 1" : "a.bom = '1'";
  
  my $query = qq|SELECT p.partnumber, p.description, p.unit, a.qty,
	         pg.partsgroup, p.partnumber AS sku, p.assembly, p.id, p.bin,
		 p.drawing, p.toolnumber, p.barcode, p.notes AS itemnotes
	         FROM assembly a
	         JOIN parts p ON (a.parts_id = p.id)
	         LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
	         WHERE $where
	         AND a.aid = '$id'
	         $sortorder|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my @sf;

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    
    @sf = qw(partnumber description partsgroup itemnotes drawing toolnumber barcode unit bin);

    for (@sf) { $form->{"a_$_"} = $ref->{$_} }
    $form->format_string(map { "a_$_" } @sf);
   
    if ($form->{grouppartsgroup} && $ref->{partsgroup} ne $sm) {
      for (qw(taxrates number sku unit qty runningnumber ship bin serialnumber ordernumber customerponumber requiredate projectnumber sellprice listprice netprice discount discountrate linetotal itemnotes lineitemdetail package netweight grossweight volume countryorigin hscode drawing toolnumber barcode)) { push(@{ $form->{$_} }, "") }
      $sm = ($form->{"a_partsgroup"}) ? $form->{"a_partsgroup"} : "";
      push(@{ $form->{description} }, "$spacer$sm");
      
      push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });
      
    }

    
    if ($form->{stagger}) {
     
      for (qw(drawing toolnumber barcode itemnotes)) { push(@{ $form->{$_} }, qq|$spacer$form->{"a_$_"}|) }
      push(@{ $form->{description} }, qq|$spacer$form->{"a_partnumber"}, $form->{"a_description"}|);
      for (qw(taxrates number sku runningnumber ship serialnumber ordernumber customerponumber requiredate projectnumber sellprice listprice netprice discount discountrate linetotal lineitemdetail package netweight grossweight volume countryorigin hscode)) { push(@{ $form->{$_} }, "") }
      
    } else {
      
      push(@{ $form->{number} }, $form->{"a_partnumber"});
      for (qw(description sku drawing toolnumber barcode itemnotes)) { push(@{ $form->{$_} }, $form->{"a_$_"}) }
      
      for (qw(taxrates runningnumber serialnumber ordernumber customerponumber requiredate projectnumber sellprice listprice netprice discount discountrate linetotal lineitemdetail package netweight grossweight volume countryorigin hscode)) { push(@{ $form->{$_} }, "") }
      
    }

    push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });
      
    push(@{ $form->{qty} }, $form->format_amount($myconfig, $ref->{qty} * $qty));
    if ($kit) {
      push(@{ $form->{ship} }, $form->format_amount($myconfig, $ref->{qty} * $qty));
    } else {
      push(@{ $form->{ship} }, "");
    }

    for (qw(unit bin)) { push(@{ $form->{$_} }, $form->{"a_$_"}) }

    if ($ref->{assembly} && $form->{formname} eq 'work_order') {
      &assembly_details($myconfig, $form, $dbh, $ref->{id}, $ref->{qty} * $qty, $kit);
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


sub get_warehouses {
  my ($self, $myconfig, $form, $dbh) = @_;

  my $disconnect;

  if (!$dbh) {
    $dbh = $form->dbconnect($myconfig);
    $disconnect = 1;
  }
  
  # setup warehouses
  my $query = qq|SELECT id, description
                 FROM warehouse
                 ORDER BY rn|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_warehouse} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect if $disconnect;

}


sub save_inventory {
  my ($self, $myconfig, $form) = @_;
  
  my $warehouse_id;
  (undef, $warehouse_id) = split /--/, $form->{warehouse};
  $warehouse_id *= 1;

  my $ml = ($form->{type} eq 'ship_order') ? -1 : 1;
  
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $sth;
  my $cth;
  my $pth;
  my $serialnumber;
  my $ship;
  my $cargobjid;
  my $employee_id;
  
  (undef, $employee_id) = split /--/, $form->{employee};
  (undef, $employee_id) = $form->get_employee($dbh) unless $employee_id;
 
  $query = qq|SELECT oi.serialnumber, oi.ship
              FROM orderitems oi
	      JOIN oe o ON (o.id = oi.trans_id)
              WHERE oi.trans_id = ?
	      AND oi.id = ?
	      FOR UPDATE|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT id
              FROM cargo
              WHERE id = ?|;
  $cth = $dbh->prepare($query) || $form->dberror($query);

  for $i (1 .. $form->{rowcount} -1) {

    $ship = (abs($form->{"ship_$i"}) > abs($form->{"qty_$i"})) ? $form->{"qty_$i"} : $form->{"ship_$i"};
    
    if ($ship) {

      $ship *= $ml;
      $query = qq|INSERT INTO inventory (parts_id, warehouse_id,
                  qty, trans_id, orderitems_id, shippingdate, employee_id)
                  VALUES ($form->{"id_$i"}, $warehouse_id,
		  $ship, $form->{"id"},
		  $form->{"orderitems_id_$i"}, '$form->{shippingdate}',
		  $employee_id)|;
      $dbh->do($query) || $form->dberror($query);
     
      # add serialnumber, ship to orderitems
      $sth->execute($form->{id}, $form->{"orderitems_id_$i"}) || $form->dberror;
      ($serialnumber, $ship, $cargobjid) = $sth->fetchrow_array;
      $sth->finish;

      $serialnumber .= " " if $serialnumber;
      $serialnumber .= qq|$form->{"serialnumber_$i"}|;
      $ship += $form->{"ship_$i"};

      $query = qq|UPDATE orderitems SET
                  serialnumber = '$serialnumber',
		  ship = $ship,
		  reqdate = '$form->{shippingdate}'
		  WHERE trans_id = $form->{id}
		  AND id = $form->{"orderitems_id_$i"}|;
      $dbh->do($query) || $form->dberror($query);

      for (qw(netweight grossweight volume)) {
	$form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"});
        $form->{"${_}_$i"} = $form->{"${_}_$i"} / $form->{"ship_$i"} if $form->{"ship_$i"};
        $form->{"${_}_$i"} *= $ship;
      }
      
      $cth->execute($form->{"orderitems_id_$i"}) || $form->dberror;
      ($cargobjid) = $cth->fetchrow_array;
      $cth->finish;

      if ($cargobjid) {
	$query = qq|UPDATE cargo SET
	            package = |.$dbh->quote($form->{"package_$i"}).qq|,
		    netweight = $form->{"netweight_$i"},
		    grossweight = $form->{"grossweight_$i"},
		    volume = $form->{"volume_$i"}
		    WHERE id = $form->{"orderitems_id_$i"}
		    AND trans_id = $form->{id}|;
      } else {
	$query = qq|INSERT INTO cargo (id, trans_id, package, netweight,
	            grossweight, volume) VALUES (
		    $form->{"orderitems_id_$i"}, $form->{id}, |
		    .$dbh->quote($form->{"package_$i"}).qq|,
		    $form->{"netweight_$i"}, $form->{"grossweight_$i"},
		    $form->{"volume_$i"})|;
      }
      $dbh->do($query) || $form->dberror($query);
      
      # update order with ship via
      $query = qq|UPDATE oe SET
                  shippingpoint = |.$dbh->quote($form->{shippingpoint}).qq|,
                  shipvia = |.$dbh->quote($form->{shipvia}).qq|,
                  waybill = |.$dbh->quote($form->{waybill}).qq|,
		  warehouse_id = $warehouse_id
		  WHERE id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);

      # update parts
      $query = qq|UPDATE parts SET
                  onhand = onhand + $form->{"ship_$i"} * $ml,
                  weight = $form->{"netweight_$i"} / $ship
                  WHERE id = $form->{"id_$i"}
                  AND (inventory_accno_id > 0 OR assembly = '1')|;
      $dbh->do($query) || $form->dberror($query);

    }
  }
  
  # remove locks
  for (qw(oe ar ap)) {
    $form->remove_locks($myconfig, $dbh, $_);
  }
 
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub adj_onhand {
  my ($dbh, $form, $ml) = @_;

  my $query = qq|SELECT oi.parts_id, oi.ship, p.inventory_accno_id,
                 p.income_accno_id, p.expense_accno_id, p.assembly
                 FROM orderitems oi
		 JOIN parts p ON (p.id = oi.parts_id)
                 WHERE oi.trans_id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $query = qq|SELECT sum(p.inventory_accno_id), p.assembly, '1'
	      FROM parts p
	      JOIN assembly a ON (a.parts_id = p.id)
	      WHERE a.aid = ?
	      GROUP BY p.assembly|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT p.id, p.inventory_accno_id, a.qty
              FROM assembly a
              JOIN parts p ON (p.id = a.parts_id)
              WHERE a.aid = ?|;
  my $kth = $dbh->prepare($query) || $form->dberror($query);
  my $kref;

  my $ref;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    if ($ref->{inventory_accno_id} || $ref->{assembly}) {

      # do not update if assembly consists of all services
      if ($ref->{assembly}) {
	$ath->execute($ref->{parts_id}) || $form->dberror($query);

        my ($inv, $assembly, $items) = $ath->fetchrow_array;
	$ath->finish;

        if ($items) {
          next unless ($inv || $assembly);
        }
	
      }

      # adjust onhand in parts table
      $form->update_balance($dbh,
			    "parts",
			    "onhand",
			    qq|id = $ref->{parts_id}|,
			    $ref->{ship} * $ml);
    }

    unless ($ref->{inventory_accno_id} + $ref->{income_accno_id} + $ref->{expense_accno_id}) {
      $kth->execute($ref->{parts_id});

      while ($kref = $kth->fetchrow_hashref(NAME_lc)) {
        if ($kref->{inventory_accno_id}) {
          $form->update_balance($dbh,
                                "parts",
                                "onhand",
                                qq|id = $kref->{id}|,
                                $kref->{qty} * $ref->{ship} * $ml);
        }
      }
      $kth->finish;
    }
  }
  
  $sth->finish;

}


sub adj_inventory {
  my ($dbh, $form, $i) = @_;

  my $ml = ($form->{type} =~ /sales_order/) ? -1 : 1;

  my $query = qq|INSERT INTO inventory (warehouse_id, parts_id, trans_id,
                 orderitems_id, qty, shippingdate, employee_id) VALUES (
                 $form->{warehouse_id}, ?, $form->{id},
                 $form->{"orderitems_id_$i"}, ?,
                 '$form->{transdate}', $form->{employee_id})|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT p.id, p.inventory_accno_id, a.qty
              FROM assembly a
              JOIN parts p ON (p.id = a.parts_id)
              WHERE a.aid = ?|;
  my $kth = $dbh->prepare($query) || $form->dberror($query);
  my $kref;

  my $ship = $form->{"ship_$i"} * $ml;

  if ($ship) {
    if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) {
      $sth->execute($form->{"id_$i"}, $ship);
      $sth->finish;
    }

    if ($form->{"kit_$i"}) {
      $kth->execute($form->{"id_$i"});
      while ($kref = $kth->fetchrow_hashref(NAME_lc)) {
        if ($kref->{inventory_accno_id}) {
          $sth->execute($kref->{id}, $ship * $kref->{qty});
          $sth->finish;
        }
      }
      $kth->finish;
    }
  }

}



sub get_soparts {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query;
  my $sth;
  my $ref;
  my $id;
  my $orderitemsid;
  
  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  # store required items from selected sales orders
  if ($form->{detail}) {
    $query = qq|SELECT p.id, oi.qty - oi.ship AS required,
		  p.assembly, oi.id AS orderitemsid
		  FROM orderitems oi
		  JOIN parts p ON (p.id = oi.parts_id)
		  WHERE oi.trans_id = ?
		  AND oi.id = ?|;
  } else {
    $query = qq|SELECT p.id, oi.qty - oi.ship AS required,
		p.assembly, oi.id AS orderitemsid
		FROM orderitems oi
		JOIN parts p ON (p.id = oi.parts_id)
		WHERE oi.trans_id = ?|;
  }
  $sth = $dbh->prepare($query) || $form->dberror($query);

  for (my $i = 1; $i <= $form->{rowcount}; $i++) {

    if ($form->{"ndx_$i"}) {

      ($id, $orderitemsid) = split /--/, $form->{"ndx_$i"};

      if ($form->{detail}) {
	$sth->execute($id, $orderitemsid);
      } else {
	$sth->execute($id);
      }
      
      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	&add_items_required("", $dbh, $form, $id, $ref->{id}, $ref->{required}, $ref->{assembly}, $ref->{orderitemsid}, $i);
      }
      $sth->finish;
    }

  }

  $form->{transdate} = $form->current_date($myconfig);
  
  # foreign exchange rates
  $form->exchangerate_defaults($dbh, $myconfig, $form);

  $dbh->disconnect;

}


sub add_items_required {
  my ($self, $dbh, $form, $id, $parts_id, $required, $assembly, $orderitemsid, $ndx) = @_;

  my $query;
  my $sth;
  my $ref;
  my $ph;

  if ($assembly) {
    $query = qq|SELECT p.id, a.qty, p.assembly
                FROM assembly a
		JOIN parts p ON (p.id = a.parts_id)
		WHERE a.aid = $parts_id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      &add_items_required("", $dbh, $form, $id, $ref->{id}, $required * $ref->{qty}, $ref->{assembly}, $orderitemsid, $ndx);
    }
    $sth->finish;
    
  } else {

    if ($form->{detail}) {
      $query = qq|SELECT p.partnumber, oi.description, p.lastcost
                  FROM orderitems oi
		  JOIN parts p ON (p.id = oi.parts_id)
		  WHERE oi.parts_id = $parts_id
		  AND oi.id = $orderitemsid
		  AND oi.trans_id = $id|;
    } else {
      $query = qq|SELECT partnumber, description, lastcost
		  FROM parts
		  WHERE id = $parts_id|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    $ref = $sth->fetchrow_hashref(NAME_lc);

    if ($form->{detail}) {
      $ph = "$parts_id--$id--$orderitemsid";
    } else {
      $ph = $parts_id;
    }
    $ref->{ndx} = ++$ndx;
      
    for (keys %$ref) { $form->{orderitems}{$ph}{$_} = $ref->{$_} }
    $sth->finish;

    $form->{orderitems}{$ph}{required} += $required;

    $query = qq|SELECT pv.partnumber, pv.leadtime, pv.lastcost, pv.curr,
		pv.vendor_id, v.name
		FROM partsvendor pv
		JOIN vendor v ON (v.id = pv.vendor_id)
		WHERE pv.parts_id = ?|;
    $sth = $dbh->prepare($query) || $form->dberror($query);

    # get cost and vendor
    $sth->execute($parts_id);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{ndx} = ++$ndx;
      for (keys %$ref) { $form->{orderitems}{$ph}{partsvendor}{$ref->{vendor_id}}{$_} = $ref->{$_} }
    }
    $sth->finish;
    
  }

}


sub generate_orders {
  my ($self, $myconfig, $form) = @_;

  my %v;
  my $query;
  my $sth;
  
  for (my $i = 1; $i <= $form->{rowcount}; $i++) {
    for (qw(qty lastcost)) { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) }
    
    if ($form->{"qty_$i"}) {
      ($vendor, $vendor_id) = split /--/, $form->{"vendor_$i"};
      
      if ($vendor_id) {
	$v{$vendor_id}{$form->{"id_$i"}}{qty} += $form->{"qty_$i"};
	$v{$vendor_id}{$form->{"id_$i"}}{ndx} = $i;
	for (qw(curr lastcost)) { $v{$vendor_id}{$form->{"id_$i"}}{$_} = $form->{"${_}_$i"} }
      }
    }
  }

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  # foreign exchange rates
  $form->exchangerate_defaults($dbh, $myconfig, $form);

  my $amount;
  my $netamount;
  my $curr = "";
  my %tax;
  my $taxincluded = 0;
  my $vendor_id;

  my $description;
  my $itemnotes;
  my $unit;
  my $ordernumber;

  my $sellprice;
  my $uid;
  
  my $rc;
  
  foreach $vendor_id (keys %v) {
    
    %tax = ();
    
    $query = qq|SELECT v.curr, v.taxincluded, t.rate, c.accno
                FROM vendor v
		LEFT JOIN vendortax vt ON (v.id = vt.vendor_id)
		LEFT JOIN tax t ON (t.chart_id = vt.chart_id)
		LEFT JOIN chart c ON (c.id = t.chart_id)
                WHERE v.id = $vendor_id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $curr = $ref->{curr};
      $taxincluded = $ref->{taxincluded};
      $tax{$ref->{accno}} = $ref->{rate};
    }
    $sth->finish;  

    $curr ||= $form->{defaultcurrency};
    $taxincluded *= 1;
    
    # get precision
    $form->{precision} = "";
    $query = qq|SELECT prec FROM curr
                WHERE curr = '$curr'|;
    ($form->{precision}) = $dbh->selectrow_array($query);
    
    if ($form->{precision} eq "") {
      my %defaults = $form->get_defaults($dbh, \@{[qw(precision)]});
      $form->{precision} = $defaults{precision};
    }

    $uid = localtime;
    $uid .= $$;
 
    $query = qq|INSERT INTO oe (ordnumber)
		VALUES ('$uid')|;
    $dbh->do($query) || $form->dberror($query);
   
    $query = qq|SELECT id FROM oe
                WHERE ordnumber = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    my ($id) = $sth->fetchrow_array;
    $sth->finish;
    
    # get default shipto
    $query = qq|SELECT * FROM shipto
                WHERE trans_id = $vendor_id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    $ref = $sth->fetchrow_hashref(NAME_lc);

    $query = qq|INSERT INTO shipto (trans_id, shiptoname, shiptoaddress1,
                shiptoaddress2, shiptocity, shiptostate, shiptozipcode,
		shiptocountry, shiptocontact, shiptophone, shiptofax,
		shiptoemail) VALUES ($id, '$ref->{shiptoname}',
		'$ref->{shiptoaddress1}', '$ref->{shiptoaddress2}',
		'$ref->{shiptocity}', '$ref->{shiptostate}',
		'$ref->{shiptozipcode}', '$ref->{shiptocountry}',
		'$ref->{shiptocontact}', '$ref->{shiptophone}',
		'$ref->{shiptofax}', '$ref->{shiptoemail}')|;
    $dbh->do($query) || $form->dberror($query);
    $sth->finish;


    $amount = 0;
    $netamount = 0;

    foreach my $parts_id (sort { $v{$vendor_id}{$a}{ndx} <=> $v{$vendor_id}{$b}{ndx} } keys %{ $v{$vendor_id} }) {

      if (($form->{$curr} * $form->{$v{$vendor_id}{$parts_id}{curr}}) > 0) {
	$sellprice = $v{$vendor_id}{$parts_id}{lastcost} / $form->{$curr} * $form->{$v{$vendor_id}{$parts_id}{curr}};
      } else {
	$sellprice = $v{$vendor_id}{$parts_id}{lastcost};
      }
      $sellprice = $form->round_amount($sellprice, $form->{precision});
      
      my $linetotal = $form->round_amount($sellprice * $v{$vendor_id}{$parts_id}{qty}, $form->{precision});
      
      my ($ph, $trans_id, $orderitemsid) = split /--/, $parts_id;
      
      $query = qq|SELECT c.accno FROM chart c
                  JOIN partstax pt ON (pt.chart_id = c.id)
		  WHERE pt.parts_id = $ph|;
      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);
      
      my $rate = 0;
      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	$rate += $tax{$ref->{accno}};
      }
      $sth->finish;

      if ($form->{detail}) {
	$query = qq|SELECT oi.description, oi.itemnotes AS notes, p.unit,
	            oi.ordernumber, oi.ponumber
	            FROM parts p
		    JOIN orderitems oi ON (oi.parts_id = p.id)
		    WHERE oi.parts_id = $ph
		    AND oi.trans_id = $trans_id
		    AND oi.id = $orderitemsid|;
      } else {
	$query = qq|SELECT p.description, p.notes, p.unit
	            FROM parts p
		    WHERE p.id = $ph|;
      }
      
      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);
      
      $ref = $sth->fetchrow_hashref(NAME_lc);
      
      $description = $dbh->quote($ref->{description});
      $itemnotes = $dbh->quote($ref->{notes});
      $unit = $dbh->quote($ref->{unit});
      $ordernumber = $dbh->quote($ref->{ordernumber});
      $ponumber = $dbh->quote($ref->{ponumber}) || $dbh->quote($form->{ponumber});
      
      $sth->finish;

      $netamount += $linetotal;
      if ($taxincluded) {
	$amount += $linetotal;
      } else {
	$amount += $form->round_amount($linetotal * (1 + $rate), $form->{precision});
      }
	
      $query = qq|INSERT INTO orderitems (trans_id, parts_id, description,
                  qty, ship, sellprice, unit, itemnotes, ordernumber,
		  ponumber) VALUES
		  ($id, $ph, $description,
		  $v{$vendor_id}{$parts_id}{qty}, 0, $sellprice, $unit,
		  $itemnotes, $ordernumber, $ponumber)|;
      $dbh->do($query) || $form->dberror($query);

    }

    my $ordnumber = $form->update_defaults($myconfig, 'ponumber');

    my $employee_id;
    my $department_id;
    
    (undef, $employee_id) = $form->get_employee($dbh);
    (undef, $department_id) = split /--/, $form->{department};
    $department_id *= 1;
    
    $query = qq|UPDATE oe SET
		ordnumber = |.$dbh->quote($ordnumber).qq|,
		transdate = current_date,
		vendor_id = $vendor_id,
		customer_id = 0,
		amount = $amount,
		netamount = $netamount,
		taxincluded = '$taxincluded',
		curr = '$curr',
		employee_id = $employee_id,
		department_id = '$department_id',
		ponumber = |.$dbh->quote($form->{ponumber}).qq|
		WHERE id = $id|;
    $dbh->do($query) || $form->dberror($query);
    
    $rc = $dbh->commit;
    
  }

  $dbh->disconnect;

  $rc;
  
}


sub consolidate_orders {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my $id;
  my $ref;
  my @ref;
  my $item;
  my %oe = ();
  
  my $query = qq|SELECT * FROM oe
                 WHERE id = ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|SELECT * FROM reference
              WHERE trans_id = ?|;
  my $rth = $dbh->prepare($query) || $form->dberror($query);
  
  $query = qq|INSERT INTO reference (
              trans_id, description, archive_id, login, formname) VALUES
	      (?,?,?,?,?)|;
  my $irth = $dbh->prepare($query) || $form->dberror($query);

  for (my $i = 1; $i <= $form->{rowcount}; $i++) {
    # retrieve order
    if ($form->{"ndx_$i"}) {
      $sth->execute($form->{"ndx_$i"});
      
      $ref = $sth->fetchrow_hashref(NAME_lc);
      $ref->{ndx} = $i;
      $oe{oe}{$ref->{curr}}{$ref->{id}} = $ref;

      $oe{vc}{$ref->{curr}}{$ref->{"$form->{vc}_id"}}++;
      $sth->finish;

      $rth->execute($form->{"ndx_$i"});
      while ($ref = $rth->fetchrow_hashref(NAME_lc)) {
	push @ref, $ref;
      }
      $rth->finish;
      
    }
  }

  $query = qq|SELECT * FROM orderitems
              WHERE trans_id = ?|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  foreach $curr (keys %{ $oe{oe} }) {
    
    foreach $id (sort { $oe{oe}{$curr}{$a}->{ndx} <=> $oe{oe}{$curr}{$b}->{ndx} } keys %{ $oe{oe}{$curr} }) {

      # retrieve order
      $vc_id = $oe{oe}{$curr}{$id}->{"$form->{vc}_id"};

      if ($oe{vc}{$oe{oe}{$curr}{$id}->{curr}}{$vc_id} > 1) {

        push @{ $oe{orders}{$curr}{$vc_id} }, $id;

	$sth->execute($id);
	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	  push @{ $oe{orderitems}{$curr}{$id} }, $ref;
	}
	$sth->finish;  

      }
    }
  }

  
  my $ordnumber;
  my $numberfld = ($form->{vc} eq 'customer') ? 'sonumber' : 'ponumber';

  my $department_id;
  (undef, $department_id) = split /--/, $form->{department};
  $department_id *= 1;

  my $warehouse_id;
  (undef, $warehouse_id) = split /--/, $form->{warehouse};
  $warehouse_id *= 1;

  my $uid = localtime;
  $uid .= $$;

  my @orderitems = ();
 
  for $curr (keys %{ $oe{orders} }) {
    
    for $vc_id (sort { $a <=> $b } keys %{ $oe{orders}{$curr} }) {
      # the orders
      @orderitems = ();
      $form->{customer_id} = $form->{vendor_id} = 0;
      $form->{"$form->{vc}_id"} = $vc_id;
      $amount = 0;
      $netamount = 0;

      for $id (@{ $oe{orders}{$curr}{$vc_id} }) {

        # header
	$ref = $oe{oe}{$curr}{$id};

	$amount += $ref->{amount};
	$netamount += $ref->{netamount};

	for $item (@{ $oe{orderitems}{$curr}{$id} }) {
	  $item->{ordernumber} ||= $ref->{ordnumber};
	  $item->{customerponumber} ||= $ref->{ponumber};
	  $item->{reqdate} ||= $ref->{reqdate};
	  $item->{reqdate} ||= $ref->{transdate};
	  push @orderitems, $item;
	}

	# close order
	$query = qq|UPDATE oe SET
	            closed = '1'
		    WHERE id = $id|;
        $dbh->do($query) || $form->dberror($query);

        # reset shipped
	$query = qq|UPDATE orderitems SET
	            ship = 0
		    WHERE trans_id = $id|;
        $dbh->do($query) || $form->dberror($query);

      }

      $ordnumber = $form->update_defaults($myconfig, $numberfld, $dbh);
    
      $query = qq|INSERT INTO oe (ordnumber)
		  VALUES ('$uid')|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|SELECT id
                  FROM oe
		  WHERE ordnumber = '$uid'|;
      ($form->{id}) = $dbh->selectrow_array($query);

      $ref->{employee_id} *= 1;

      $query = qq|UPDATE oe SET
		  ordnumber = |.$dbh->quote($ordnumber).qq|,
		  transdate = current_date,
		  vendor_id = $form->{vendor_id},
		  customer_id = $form->{customer_id},
		  amount = $amount,
		  netamount = $netamount,
		  reqdate = |.$form->dbquote($ref->{reqdate}, SQL_DATE).qq|,
		  taxincluded = '$ref->{taxincluded}',
		  shippingpoint = |.$dbh->quote($ref->{shippingpoint}).qq|,
		  notes = |.$dbh->quote($ref->{notes}).qq|,
		  curr = '$curr',
		  employee_id = $ref->{employee_id},
		  intnotes = |.$dbh->quote($ref->{intnotes}).qq|,
		  shipvia = |.$dbh->quote($ref->{shipvia}).qq|,
		  waybill = |.$dbh->quote($ref->{waybill}).qq|,
		  language_code = '$ref->{language_code}',
		  ponumber = |.$dbh->quote($form->{ponumber}).qq|,
		  department_id = $department_id,
                  warehouse_id = $warehouse_id,
		  description = |.$dbh->quote($form->{orddescription}).qq|
		  WHERE id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);
	  
      my $sortorder = $form->{sort};
      $sortorder = "customerponumber" if $form->{sort} eq 'ponumber';

      # add items
      for $item (sort { $a->{$sortorder} cmp $b->{$sortorder} } @orderitems) {
	for (qw(qty sellprice discount project_id ship)) { $item->{$_} *= 1 }

	$query = qq|INSERT INTO orderitems (
		    trans_id, parts_id, description,
		    qty, sellprice, discount,
		    unit, project_id, reqdate,
		    ship, serialnumber, itemnotes,
		    lineitemdetail, ordernumber, ponumber)
		    VALUES (
		    $form->{id}, $item->{parts_id}, |
		    .$dbh->quote($item->{description})
		    .qq|, $item->{qty}, $item->{sellprice}, $item->{discount}, |
		    .$dbh->quote($item->{unit})
		    .qq|, $item->{project_id}, |
		    .$form->dbquote($item->{reqdate}, SQL_DATE)
		    .qq|, $item->{ship}, |
		    .$dbh->quote($item->{serialnumber}).qq|, |
		    .$dbh->quote($item->{itemnotes}).qq|, '$item->{lineitemdetail}', |
		    .$dbh->quote($item->{ordernumber}).qq|, |
		    .$dbh->quote($item->{customerponumber}).qq|)|;

	$dbh->do($query) || $form->dberror($query);

      }

      # trans_id, description, archive_id, login, formname
      for $item (@ref) {
	$irth->execute($form->{id}, $item->{description}, $item->{archive_id}, $item->{login}, $item->{formname});
	$irth->finish;
      }

      # change inventory, cargo
      for $id (@{ $oe{orders}{$curr}{$vc_id} }) {
        for (qw(cargo inventory)) {
          $query = qq|UPDATE $_
                      SET trans_id = $form->{id}
                      WHERE trans_id = $id|;
          $dbh->do($query) || $form->dberror($query);
        }
      }
    }
  }

  $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}


1;

