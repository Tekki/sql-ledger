#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Inventory Control backend
#
#======================================================================

package IC;


sub get_part {
  my ($self, $myconfig, $form) = @_;

  # connect to db
  my $dbh = $form->dbconnect($myconfig);
  my $i;

  $form->{id} *= 1;
  
  my $query = qq|SELECT p.*,
                 c1.accno AS inventory_accno, c1.description AS inventory_description,
		 c2.accno AS income_accno, c2.description AS income_description,
		 c3.accno AS expense_accno, c3.description AS expense_description,
		 pg.partsgroup, pg.code AS partsgroupcode,
		 l1.description AS inventory_translation,
		 l2.description AS income_translation,
		 l3.description AS expense_translation
	         FROM parts p
		 LEFT JOIN chart c1 ON (p.inventory_accno_id = c1.id)
		 LEFT JOIN translation l1 ON (l1.trans_id = c1.id AND l1.language_code = '$myconfig->{countrycode}')
		 LEFT JOIN chart c2 ON (p.income_accno_id = c2.id)
		 LEFT JOIN translation l2 ON (l2.trans_id = c2.id AND l2.language_code = '$myconfig->{countrycode}')
		 LEFT JOIN chart c3 ON (p.expense_accno_id = c3.id)
		 LEFT JOIN translation l3 ON (l3.trans_id = c3.id AND l3.language_code = '$myconfig->{countrycode}')
		 LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
                 WHERE p.id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  my $ref = $sth->fetchrow_hashref(NAME_lc);

  # copy to $form variables
  $ref->{inventory_description} = $ref->{inventory_translation} if $ref->{inventory_translation};
  $ref->{income_description} = $ref->{income_translation} if $ref->{income_translation};
  $ref->{expense_description} = $ref->{expense_translation} if $ref->{expense_translation};

  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;
  
  # part, service item or labor
  $form->{item} = ($form->{inventory_accno_id}) ? 'part' : 'service';
  $form->{item} = 'labor' if ! $form->{income_accno_id};
  $form->{item} = 'assembly' if $form->{assembly};
  $form->{item} = 'kit' unless $form->{inventory_accno_id} + $form->{income_accno_id} + $form->{expense_accno_id};
    
  if ($form->{assembly} || $form->{item} eq 'kit') {

    # retrieve assembly items
    $query = qq|SELECT p.id, p.partnumber, p.description,
                p.sellprice, p.weight, a.qty, a.bom, a.adj, p.unit,
		p.lastcost, p.listprice, p.onhand,
		pg.partsgroup, p.assembly, p.partsgroup_id
                FROM parts p
		JOIN assembly a ON (a.parts_id = p.id)
		LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		WHERE a.aid = $form->{id}
		ORDER BY a.id|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    $form->{assembly_rows} = 0;
    while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
      $form->{assembly_rows}++;
      foreach my $key ( keys %{ $ref } ) {
	$form->{"${key}_$form->{assembly_rows}"} = $ref->{$key};
      }
    }
    $sth->finish;

  }

  # setup accno hash for <option checked> {amount} is used in create_links
  for (qw(inventory income expense)) { $form->{amount}{"IC_$_"} = { accno => $form->{"${_}_accno"}, description => $form->{"${_}_description"} } }


  if ($form->{item} =~ /(part|assembly|kit)/) {
    # get makes
    if ($form->{makemodel} ne "") {
      $query = qq|SELECT make, model
                  FROM makemodel
                  WHERE parts_id = $form->{id}|;

      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);
      
      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	push @{ $form->{makemodels} }, $ref;
      }
      $sth->finish;
    }

    # get inventory
    $query = qq|SELECT w.description AS warehouse, SUM(i.qty) AS onhand
                FROM inventory i
                JOIN warehouse w ON (i.warehouse_id = w.id)
                WHERE i.parts_id = $form->{id}
                GROUP BY w.description
                ORDER BY warehouse|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{inventory} }, $ref if $ref->{onhand};
    }
    $sth->finish;

  }

  # now get accno for taxes
  $query = qq|SELECT c.accno
              FROM chart c, partstax pt
	      WHERE pt.chart_id = c.id
	      AND pt.parts_id = $form->{id}|;
  
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (($key) = $sth->fetchrow_array) {
    $form->{amount}{$key} = $key;
  }

  $sth->finish;

  # is it an orphan
  $form->{orphaned} = &orphaned("", $dbh, $form);
 
  $form->{orphaned} = 0 if $form->{project_id};

  if ($form->{item} =~ /(part|service)/) {
    # get vendors
    $query = qq|SELECT v.id, v.name, pv.partnumber,
                pv.lastcost, pv.leadtime, pv.curr AS vendorcurr
		FROM partsvendor pv
		JOIN vendor v ON (v.id = pv.vendor_id)
		WHERE pv.parts_id = $form->{id}
		ORDER BY 2|;
    
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{vendormatrix} }, $ref;
    }
    $sth->finish;
  }
 
  # get matrix
  if ($form->{item} ne 'labor') {
    $query = qq|SELECT pc.pricebreak, pc.sellprice AS customerprice,
		pc.curr AS customercurr,
		pc.validfrom, pc.validto,
		c.name, c.id AS cid, g.pricegroup, g.id AS gid
		FROM partscustomer pc
		LEFT JOIN customer c ON (c.id = pc.customer_id)
		LEFT JOIN pricegroup g ON (g.id = pc.pricegroup_id)
		WHERE pc.parts_id = $form->{id}
		ORDER BY c.name, g.pricegroup, pc.pricebreak|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{customermatrix} }, $ref;
    }
    $sth->finish;
  }

  $dbh->disconnect;
  
}


sub orphaned {
  my ($self, $dbh, $form) = @_;
  
  my $query = qq|SELECT parts_id
              FROM invoice
	      WHERE parts_id = $form->{id}
	    UNION
	      SELECT parts_id
	      FROM orderitems
	      WHERE parts_id = $form->{id}
	    UNION
	      SELECT parts_id
	      FROM assembly
	      WHERE parts_id = $form->{id}
	    UNION
	      SELECT parts_id
	      FROM jcitems
	      WHERE parts_id = $form->{id}|;
  my ($orphaned) = $dbh->selectrow_array($query);

  !$orphaned;

}


sub save {
  my ($self, $myconfig, $form, $dbh) = @_;

  my $disconnect;
  
  # connect to database, turn off AutoCommit
  if (! $dbh) {
    $disconnect = 1;
    $dbh = $form->dbconnect_noauto($myconfig);
  }

  # undo amount formatting
  for (qw(rop weight listprice sellprice lastcost onhand)) { $form->{$_} = $form->parse_amount($myconfig, $form->{$_}) }
  
  $form->{assembly} = ($form->{item} eq 'assembly') ? 1 : 0;
  for (qw(id alternate obsolete)) { $form->{$_} *= 1 }

  if ($form->{id} && $form->{changeup}) {
    
    if (!$form->{orphaned}) {
      
      if ($form->{assembly}) {
	
        my $stock = new Form;
        $stock->{rowcount} = 1;
        $stock->{qty_1} = $form->{oldonhand} * -1;
        $stock->{id_1} = $form->{id};

        IC->stock_assemblies($myconfig, \%$stock, $dbh);
        
        $query = qq|UPDATE parts SET obsolete = '1'
              WHERE id = $form->{id}|;
        $dbh->do($query) || $form->dberror($query);

      } else {
	
        $query = qq|UPDATE parts SET obsolete = '1', onhand = 0
                    WHERE id = $form->{id}|;
        $dbh->do($query) || $form->dberror($query);
      }
      $form->{id} = 0;
      $form->{oldonhand} = 0;
    }
    
  }
  
  ($form->{inventory_accno}) = split(/--/, $form->{IC_inventory});
  ($form->{expense_accno}) = split(/--/, $form->{IC_expense});
  ($form->{income_accno}) = split(/--/, $form->{IC_income});

  $form->{makemodel} = (($form->{make_1}) || ($form->{model_1})) ? 1 : 0;
  
  my $query;
  my $sth;
  my $i;
  my $vendor_id;
  my $customer_id;
  
  if ($form->{id}) {

    # get old price
    $query = qq|SELECT id, listprice, sellprice, lastcost, weight, project_id
                FROM parts
		WHERE id = $form->{id}|;
    my ($id, $listprice, $sellprice, $lastcost, $weight, $project_id) = $dbh->selectrow_array($query);

    if ($id) {
      
      if ($form->{item} eq 'assembly' &! $project_id) {
        # if item is part of an assembly adjust all assemblies
        $query = qq|SELECT aid, qty, adj
                    FROM assembly
                    WHERE parts_id = $form->{id}|;
        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);
        while (my ($id, $qty, $adj) = $sth->fetchrow_array) {
          &update_assembly($dbh, $form, $id, $qty, $adj, $listprice * 1, $sellprice * 1, $lastcost * 1, $weight * 1);
        }
        $sth->finish;
      }

      if ($form->{item} =~ /(part|service)/) {
        # delete partsvendor records
        $query = qq|DELETE FROM partsvendor
                    WHERE parts_id = $form->{id}|;
        $dbh->do($query) || $form->dberror($query);
      }
       
      if ($form->{item} !~ /(service|labor)/) {
        # delete makemodel records
        $query = qq|DELETE FROM makemodel
                    WHERE parts_id = $form->{id}|;
        $dbh->do($query) || $form->dberror($query);
      }

      if ($form->{item} eq 'kit') {
        # delete assembly records
        $query = qq|DELETE FROM assembly
                    WHERE aid = $form->{id}|;
        $dbh->do($query) || $form->dberror($query);
      }

      if ($form->{item} eq 'assembly') {

        if ($form->{orphaned}) {
          # delete assembly records
          $query = qq|DELETE FROM assembly
                      WHERE aid = $form->{id}|;
          $dbh->do($query) || $form->dberror($query);
        } else {

          for $i (1 .. $form->{assembly_rows} - 1) {
            # update BOM, A only
            for (qw(bom adj)) { $form->{"${_}_$i"} *= 1 }

            $query = qq|UPDATE assembly SET
                        bom = '$form->{"bom_$i"}',
                        adj = '$form->{"adj_$i"}'
                        WHERE aid = $form->{id}
                        AND parts_id = $form->{"id_$i"}|;
                        $dbh->do($query) || $form->dberror($query);
          }
        }
      }

      # delete tax records
      $query = qq|DELETE FROM partstax
		  WHERE parts_id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);
      
      # delete matrix
      $query = qq|DELETE FROM partscustomer
		  WHERE parts_id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);
      
    } else {
      $query = qq|INSERT INTO parts (id)
                  VALUES ($form->{id})|;
      $dbh->do($query) || $form->dberror($query);
    }

  } else {
  
    my $uid = localtime;
    $uid .= $$;

    $query = qq|INSERT INTO parts (partnumber)
                VALUES ('$uid')|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT id FROM parts
                WHERE partnumber = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;

    $form->{orphaned} = 1;
    
  }

  my $partsgroup_id;
  (undef, $partsgroup_id) = split /--/, $form->{partsgroup};
  $partsgroup_id *= 1;

  $form->{partnumber} = $form->update_defaults($myconfig, "partnumber", $dbh) if ! $form->{partnumber};
  $form->{partnumber} =~ s/(^\s+|\s+$)//g;

  $query = qq|UPDATE parts SET
              partnumber = |.$dbh->quote($form->{partnumber}).qq|,
              description = |.$dbh->quote($form->{description}).qq|,
              makemodel = '$form->{makemodel}',
              alternate = '$form->{alternate}',
              assembly = '$form->{assembly}',
              listprice = $form->{listprice},
              sellprice = $form->{sellprice},
              lastcost = $form->{lastcost},
              weight = $form->{weight},
              priceupdate = |.$form->dbquote($form->{priceupdate}, SQL_DATE).qq|,
              unit = |.$dbh->quote($form->{unit}).qq|,
              notes = |.$dbh->quote($form->{notes}).qq|,
              rop = $form->{rop},
              bin = |.$dbh->quote($form->{bin}).qq|,
              inventory_accno_id = (SELECT id FROM chart
                                    WHERE accno = '$form->{inventory_accno}'),
              income_accno_id = (SELECT id FROM chart
              WHERE accno = '$form->{income_accno}'),
              expense_accno_id = (SELECT id FROM chart
                                  WHERE accno = '$form->{expense_accno}'),
                                  obsolete = '$form->{obsolete}',
              image = '$form->{image}',
              drawing = '$form->{drawing}',
              microfiche = '$form->{microfiche}',
              partsgroup_id = $partsgroup_id,
              toolnumber = '$form->{toolnumber}',
              countryorigin = '$form->{countryorigin}',
              tariff_hscode = '$form->{tariff_hscode}',
              barcode = '$form->{barcode}'
              WHERE id = $form->{id}|;
        $dbh->do($query) || $form->dberror($query);

        # insert makemodel records
        if ($form->{item} =~ /(part|assembly|kit)/) {
          for $i (1 .. $form->{makemodel_rows}) {
            if (($form->{"make_$i"} ne "") || ($form->{"model_$i"} ne "")) {
              $query = qq|INSERT INTO makemodel (parts_id, make, model)
                          VALUES ($form->{id},|
                          .$dbh->quote($form->{"make_$i"}).qq|, |
                          .$dbh->quote($form->{"model_$i"}).qq|)|;
        $dbh->do($query) || $form->dberror($query);
      }
    }
  }


  # insert taxes
  for (split / /, $form->{taxaccounts}) {
    if ($form->{"IC_tax_$_"}) {
      $query = qq|INSERT INTO partstax (parts_id, chart_id)
                  VALUES ($form->{id}, 
		              (SELECT id
			            FROM chart
			            WHERE accno = '$_'))|;
      $dbh->do($query) || $form->dberror($query);
    }
  }
  
  @lt = localtime;
  $lt[5] += 1900;
  $lt[4]++;
  $lt[4] = substr("0$lt[4]", -2);
  $lt[3] = substr("0$lt[3]", -2);
  my $shippingdate = "$lt[5]$lt[4]$lt[3]";
  
  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
 
  # add assembly records
  if ($form->{item} eq 'assembly' && !$project_id) {
    
    if ($form->{orphaned}) {
      for $i (1 .. $form->{assembly_rows}) {
        $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"});
	
        if ($form->{"qty_$i"}) {
          for (qw(bom adj)) { $form->{"${_}_$i"} *= 1 }
          $query = qq|INSERT INTO assembly (aid, parts_id, qty, bom, adj)
                VALUES ($form->{id}, $form->{"id_$i"},
                $form->{"qty_$i"}, '$form->{"bom_$i"}',
                '$form->{"adj_$i"}')|;
          $dbh->do($query) || $form->dberror($query);
        }
      }
    }
   
    # adjust onhand for the assembly parts
    &adjust_inventory($dbh, $form, $form->{id}, $form->{onhand} - $form->{oldonhand});

  }

  # add kit records
  if ($form->{item} eq 'kit') {
    
    for $i (1 .. $form->{assembly_rows}) {
      $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"});
      
      if ($form->{"qty_$i"}) {
        for (qw(bom adj)) { $form->{"${_}_$i"} *= 1 }
        $query = qq|INSERT INTO assembly (aid, parts_id, qty, bom, adj)
                    VALUES ($form->{id}, $form->{"id_$i"},
                    $form->{"qty_$i"}, '$form->{"bom_$i"}',
                    '$form->{"adj_$i"}')|;
        $dbh->do($query) || $form->dberror($query);
      }
    }
  }


  # add vendors
  if ($form->{item} !~ /(assembly|kit)/) {
    
    for $i (1 .. $form->{vendor_rows}) {
      if (($form->{"vendor_$i"} ne "") && $form->{"lastcost_$i"}) {

        (undef, $vendor_id) = split /--/, $form->{"vendor_$i"};
	
        for (qw(lastcost leadtime)) { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"})}
        
        $query = qq|INSERT INTO partsvendor (vendor_id, parts_id, partnumber,
                    lastcost, leadtime, curr)
                    VALUES ($vendor_id, $form->{id},|
                    .$dbh->quote($form->{"partnumber_$i"}).qq|,
                    $form->{"lastcost_$i"},
                    $form->{"leadtime_$i"}, '$form->{"vendorcurr_$i"}')|;
        $dbh->do($query) || $form->dberror($query);
      }
    }
  }
  
  
  # add pricematrix
  for $i (1 .. $form->{customer_rows}) {

    for (qw(pricebreak customerprice)) { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"})}

    if ($form->{"customerprice_$i"}) {

      (undef, $customer_id) = split /--/, $form->{"customer_$i"};
      $customer_id *= 1;
      
      (undef, $pricegroup_id) = split /--/, $form->{"pricegroup_$i"};
      $pricegroup_id *= 1;
      
      $query = qq|INSERT INTO partscustomer (parts_id, customer_id,
                  pricegroup_id, pricebreak, sellprice, curr,
                  validfrom, validto)
                  VALUES ($form->{id}, $customer_id,
                  $pricegroup_id, $form->{"pricebreak_$i"},
                  $form->{"customerprice_$i"}, '$form->{"customercurr_$i"}',|
                  .$form->dbquote($form->{"validfrom_$i"}, SQL_DATE).qq|, |
                  .$form->dbquote($form->{"validto_$i"}, SQL_DATE).qq|)|;
      $dbh->do($query) || $form->dberror($query);
    }
  }

  if ($form->{item} =~ /(part|labor)/) {
    $form->update_balance($dbh,
			  "parts",
			  "onhand",
			  qq|id = $form->{id}|,
			  $form->{onhand} - $form->{oldonhand});
  }
  
  my %audittrail = ( tablename	=> 'ic',
                     reference => $form->{partnumber},
		     formname => $form->{item},
                     action     => 'saved',
		     id => $form->{id}
		     );

  $form->audittrail($dbh, "", \%audittrail);
  
  $form->save_reference($dbh, $form->{item});
  
  # commit
  my $rc = $dbh->commit;

  $dbh->disconnect if $disconnect;

  $rc;
  
}


sub update_assembly {
  my ($dbh, $form, $id, $qty, $adj, $listprice, $sellprice, $lastcost, $weight) = @_;

  my $formlistprice = $form->{listprice};
  my $formsellprice = $form->{sellprice};
  
  if (!$adj) {
    $formlistprice = $listprice;
    $formsellprice = $sellprice;
  }
  
  my $query = qq|SELECT aid, qty, adj
                 FROM assembly
	         WHERE parts_id = $id|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $form->{$id} = 1;
  
  while (my ($pid, $aqty, $aadj) = $sth->fetchrow_array) {
    &update_assembly($dbh, $form, $pid, $aqty * $qty, $aadj, $listprice, $sellprice, $lastcost, $weight) if !$form->{$pid};
  }
  $sth->finish;

  $query = qq|UPDATE parts
              SET listprice = listprice + $qty * ($formlistprice - $listprice),
	          sellprice = sellprice + $qty * ($formsellprice - $sellprice),
		  lastcost = lastcost + $qty * ($form->{lastcost} - $lastcost),
                  weight = weight + $qty * ($form->{weight} - $weight)
	      WHERE id = $id|;
  $dbh->do($query) || $form->dberror($query);

  delete $form->{$id};
  
}


sub retrieve_items {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $var;
  my $where = '1 = 1';
  
  if ($form->{partnumber} ne "") {
    $var = $form->like(lc $form->{partnumber});
    $where .= " AND lower(p.partnumber) LIKE '$var'";
  }
  
  if ($form->{description} ne "") {
    $var = $form->like(lc $form->{description});
    $where .= " AND lower(p.description) LIKE '$var'";
  }
  $where .= qq| AND p.obsolete = '0'
                AND (p.inventory_accno_id > 0 OR p.assembly = '1')|;

  if ($form->{partsgroup} ne "") {
    (undef, $var) = split /--/, $form->{partsgroup};
    $where .= qq| AND p.partsgroup_id = $var|;
  }

  my $query = qq|SELECT p.id, p.partnumber, p.description,
                 p.bin, p.onhand, p.rop, p.assembly
                 FROM parts p
 		 WHERE $where|;

  my @sf = qw(partnumber description bin);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  my $ref;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_items} }, $ref;
  }
  $sth->finish;
  
  if ($form->{warehouse} ne "") {
    my ($warehouse, $warehouse_id) = split /--/, $form->{warehouse};
    $warehouse_id *= 1;
    $query = qq|SELECT SUM(qty) AS onhand, '$warehouse' AS warehouse,
		'$warehouse_id' AS warehouse_id
		FROM inventory
		WHERE warehouse_id = $warehouse_id
		AND parts_id = ?|;
  } else {
    $query = qq|SELECT SUM(i.qty) AS onhand, w.description AS warehouse,
		w.id AS warehouse_id
		FROM inventory i
		JOIN warehouse w ON (w.id = i.warehouse_id)
		WHERE i.parts_id = ?
		GROUP BY w.description, w.id|;
  }

  $sth = $dbh->prepare($query) || $form->dberror($query);

  my @tp;
  
  for (@{ $form->{all_items} }) {

    @tp = ();
    
    $sth->execute($_->{id}) || $form->dberror($query);
    
    if ($form->{warehouse} ne "") {
      
      $ref = $sth->fetchrow_hashref(NAME_lc);
      if ($ref->{onhand} != 0) {
	$_->{onhand} = $ref->{onhand};
	push @tp, $_;
      }

    } else {

      push @tp, $_;
      
      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	if ($ref->{onhand} != 0) {
          $_->{onhand} -= $ref->{onhand};

	  $ref->{id} = $_->{id};
	  push @tp, $ref;
	}
      }
    }
    
    push @li, @tp;
    
    $sth->finish;
  }

  @{ $form->{all_items} } = @li;

  $dbh->disconnect;
  
}


sub adjust_onhand {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|UPDATE parts SET
                 onhand = ?
		 WHERE id = ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  my $onhand;
  my %pt;
  my %upd;
  
  my $current_date = $form->current_date($myconfig);
  
  my ($name, $employee_id) = $form->get_employee($dbh);
  $employee_id *= 1;
  
  $query = qq|INSERT INTO inventory (warehouse_id, parts_id, qty, employee_id, shippingdate)
              VALUES (?,?,?,'$employee_id','$current_date')|;
  my $ith = $dbh->prepare($query);
 
  for my $i (1 .. $form->{rowcount}) {

    $form->{"onhand_$i"} = $form->parse_amount($myconfig, $form->{"onhand_$i"});
    if ($form->{"oldonhand_$i"} != $form->{"onhand_$i"}) {
      $upd{$form->{"id_$i"}} = 1;
      if ($form->{"warehouseid_$i"}) {
	$ith->execute($form->{"warehouseid_$i"}, $form->{"id_$i"}, $form->{"onhand_$i"} - $form->{"oldonhand_$i"});
	$ith->finish;
      }
    }

  }

  for $i (1 .. $form->{rowcount}) {
    if ($upd{$form->{"id_$i"}}) {
      $pt{$form->{"id_$i"}} += $form->{"onhand_$i"};
    }
  }
    
  for (keys %pt) {
    $sth->execute($pt{$_}, $_);
    $sth->finish;
  }
  
  $dbh->disconnect;

}


sub retrieve_assemblies {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $var;
  my $inventoryjoin;
  my $where = '1 = 1';
  
  if ($form->{partnumber} ne "") {
    $var = $form->like(lc $form->{partnumber});
    $where .= " AND lower(p.partnumber) LIKE '$var'";
  }
  if ($form->{description} ne "") {
    $var = $form->like(lc $form->{description});
    $where .= " AND lower(p.description) LIKE '$var'";
  }

  $where .= qq| AND p.obsolete = '0'
                AND p.project_id IS NULL|;

  # retrieve assemblies
  my $query = qq|SELECT p.id, p.partnumber, p.description,
                 p.bin, p.onhand, p.rop
                 FROM parts p
 		 WHERE $where
		 AND p.assembly = '1'|;

  my @sf = qw(partnumber description bin);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  # only services
  $query = qq|SELECT sum(p.inventory_accno_id), p.assembly
              FROM parts p
	      JOIN assembly a ON (a.parts_id = p.id)
	      WHERE a.aid = ?
	      GROUP BY p.assembly|;
  my $svh = $dbh->prepare($query) || $form->dberror($query);

  my $warehouse_id;
  (undef, $warehouse_id) = split /--/, $form->{warehouse};
  my $inh;

  if ($form->{checkinventory}) {
    if ($form->{warehouse}) {
      $query = qq|SELECT p.id, SUM(i.qty) AS onhand, a.qty
                  FROM parts p
                  JOIN assembly a ON (a.parts_id = p.id)
                  JOIN inventory i ON (i.parts_id = p.id AND warehouse_id = $warehouse_id)
                  WHERE (p.inventory_accno_id > 0 OR p.assembly)
                  AND p.income_accno_id > 0
                  AND a.aid = ?
                  GROUP BY p.id, a.qty|;
    } else {
      $query = qq|SELECT p.id, p.onhand - SUM(i.qty) AS onhand, a.qty
                  FROM parts p
                  JOIN assembly a ON (a.parts_id = p.id)
                  LEFT JOIN inventory i ON (i.parts_id = p.id)
                  WHERE (p.inventory_accno_id > 0 OR p.assembly)
                  AND p.income_accno_id > 0
                  AND a.aid = ?
                  GROUP BY p.id, p.onhand, a.qty|;
    }
    $inh = $dbh->prepare($query) || $form->dberror($query);
  }

  my %available = ();
  my %required;
  my $ref;
  my $aref;
  my $stock;
  my $howmany;
  my $qty;
  my $ok;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $stock = 0;
    $svh->execute($ref->{id});
    while (($ref->{inventory}, $ref->{assembly}) = $svh->fetchrow_array) {
      last if $ref->{inventory} || $ref->{assembly};
    }
    $svh->finish;
    
    if ($ref->{inventory} || $ref->{assembly}) {
      $ok = 1;

      if ($form->{checkinventory}) {
        # warehouse onhand
	$inh->execute($ref->{id});
	$ok = 0;
	%required = ();
	
	while ($aref = $inh->fetchrow_hashref(NAME_lc)) {
	  $available{$aref->{id}} = (exists $available{$aref->{id}}) ? $available{$aref->{id}} : $aref->{onhand};
	  $required{$aref->{id}} = $aref->{qty};
	  
	  if ($available{$aref->{id}} >= $aref->{qty}) {
	    
	    $howmany = ($aref->{qty}) ? int $available{$aref->{id}}/$aref->{qty} : 1;
	    if ($stock) {
	      $stock = ($stock > $howmany) ? $howmany : $stock;
	    } else {
	      $stock = $howmany;
	    }
	    $ok = 1;

	    $available{$aref->{id}} -= $aref->{qty} * $stock;

	  } else {
	    $ok = 0;
	    for (keys %required) { $available{$_} += $required{$_} * $stock }
	    $stock = 0;
	    last;
	  }
	}
	$inh->finish;
	$ref->{stock} = $stock;
	
      }
      push @{ $form->{assembly_items} }, $ref if $ok;
    }
  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub stock_assemblies {
  my ($self, $myconfig, $form, $dbh) = @_;

  my $disconnect;
  my %audittrail;
  
  # connect to database
  if (!$dbh) {
    $dbh = $form->dbconnect_noauto($myconfig);
    $disconnect = 1;
  }

  my $query = qq|SELECT partnumber
                 FROM parts
                 WHERE id = ?|;
  my $pth = $dbh->prepare($query);

  (undef, $form->{warehouse_id}) = split /--/, $form->{warehouse};
  (undef, $form->{employee_id}) = $form->get_employee($dbh);
  
  for my $i (1 .. $form->{rowcount}) {

    $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"});

    if ($form->{"qty_$i"}) {
      &adjust_inventory($dbh, $form, $form->{"id_$i"} * 1, $form->{"qty_$i"});

      $pth->execute($form->{"id_$i"});
      ($partnumber) = $pth->fetchrow_array;
      $pth->finish;

      %audittrail = ( tablename  => 'ic',
                      reference  => $partnumber,
                      formname   => 'assembly',
                      action     => 'stock',
                      id         => $form->{"id_$i"} );

      $form->audittrail($dbh, "", \%audittrail);
    }
  }

  my $rc;

  if ($disconnect) {
    $rc = $dbh->commit;
    $dbh->disconnect;
  }

  $rc;

}


sub adjust_inventory {
  my ($dbh, $form, $id, $qty) = @_;

  return unless $qty;
  
  my $query = qq|SELECT p.id, p.inventory_accno_id, p.assembly, a.qty
		 FROM parts p
		 JOIN assembly a ON (a.parts_id = p.id)
		 WHERE a.aid = $id|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $current_date = $form->current_date($myconfig) || $form->{shippingdate};
  
  $query = qq|INSERT INTO inventory (warehouse_id, parts_id, qty, employee_id, shippingdate)
              VALUES (?,?,?,'$form->{employee_id}','$current_date')|;
  my $ith = $dbh->prepare($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    # is it a service item then loop
    if (! $ref->{inventory_accno_id}) {
      next if ! $ref->{assembly};              # assembly
    }
    
    # adjust parts onhand
    $form->update_balance($dbh,
			  "parts",
			  "onhand",
			  qq|id = $ref->{id}|,
			  $qty * $ref->{qty} * -1);

    if ($form->{warehouse_id}) {
      $ith->execute($form->{warehouse_id}, $ref->{id}, $qty * $ref->{qty} * -1);
      $ith->finish;
    }
    
  }

  $sth->finish;

  # update assembly
  $form->update_balance($dbh,
			"parts",
			"onhand",
			qq|id = $id|,
			$qty);

  if ($form->{warehouse_id}) {
    $ith->execute($form->{warehouse_id}, $id, $qty);
    $ith->finish;
  }

}


sub delete {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  
  $form->{id} *= 1;
  
  $query = qq|DELETE FROM parts
 	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|DELETE FROM partstax
	      WHERE parts_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);


  if ($form->{item} ne 'assembly') {
    $query = qq|DELETE FROM partsvendor
		WHERE parts_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }

  # check if it is a part, assembly or service
  if ($form->{item} ne 'service') {
    $query = qq|DELETE FROM makemodel
		WHERE parts_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }

  if ($form->{item} eq 'assembly') {
    # adjust onhand for the assembly parts
    &adjust_inventory($dbh, $form, $form->{id}, $form->{oldonhand} * -1);

    $query = qq|DELETE FROM assembly
		WHERE aid = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  if ($form->{item} eq 'alternate') {
    $query = qq|DELETE FROM alternate
		WHERE id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }

  $query = qq|DELETE FROM inventory
	      WHERE parts_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM partscustomer
	      WHERE parts_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM translation
	      WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $form->delete_references($dbh);
  
  my %audittrail = ( tablename  => 'ic',
                     reference  => $form->{partnumber},
		     formname   => $form->{item},
		     action     => 'deleted',
		     id         => $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);
 
  # commit
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}


sub assembly_item {
  my ($self, $myconfig, $form) = @_;

  my $i = $form->{assembly_rows};
  my $var;
  my $where = "p.obsolete = '0'";

  if ($form->{"partnumber_$i"} ne "") {
    $var = $form->like(lc $form->{"partnumber_$i"});
    $where .= " AND lower(p.partnumber) LIKE '$var'";
  }
  if ($form->{"description_$i"} ne "") {
    $var = $form->like(lc $form->{"description_$i"});
    $where .= " AND lower(p.description) LIKE '$var'";
  }
  if ($form->{"partsgroup_$i"} ne "") {
    (undef, $var) = split /--/, $form->{"partsgroup_$i"};
    $where .= qq| AND p.partsgroup_id = $var|;
  }

  if ($form->{id}) {
    $where .= " AND p.id != $form->{id}";
  }

  if ($form->{"description_$i"} ne "") {
    $where .= " ORDER BY p.description";
  } else {
    $where .= " ORDER BY p.partnumber";
  }

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT p.id, p.partnumber, p.description, p.sellprice,
                 p.weight, p.onhand, p.unit, p.lastcost,
                 p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		 pg.partsgroup, p.partsgroup_id, p.assembly
		 FROM parts p
		 LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		 WHERE $where|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    next unless $ref->{inventory_accno_id} + $ref->{income_accno_id} + $ref->{expense_accno_id};
    next if $ref->{assembly} && $form->{item} eq 'kit';
    push @{ $form->{item_list} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;
  
}


sub all_parts {
  my ($self, $myconfig, $form) = @_;

  my $where = '1 = 1';
  my $var;
  my $warehouse;
  my $ref;
  
  for (qw(partnumber drawing microfiche toolnumber barcode)) {
    if ($form->{$_} ne "") {
      $var = $form->like(lc $form->{$_});
      $where .= " AND lower(p.$_) LIKE '$var'";
    }
  }
  # special case for description
  if ($form->{description} ne "") {
    unless ($form->{bought} || $form->{sold} || $form->{onorder} || $form->{ordered} || $form->{rfq} || $form->{quoted}) {
      $var = $form->like(lc $form->{description});
      $where .= " AND lower(p.description) LIKE '$var'";
    }
  }
  
  # assembly components
  my $assemblyflds;
  if ($form->{searchitems} eq 'component') {
    $assemblyflds = qq|, p1.partnumber AS assemblypartnumber, p1.description AS assemblydescription, a.aid AS assembly_id|;
  }

  # special case for serialnumber
  if ($form->{l_serialnumber}) {
    if ($form->{serialnumber} ne "") {
      $var = $form->like(lc $form->{serialnumber});
      $where .= " AND lower(i.serialnumber) LIKE '$var'";
    }
  }

  if (($form->{warehouse} ne "") || $form->{l_warehouse}) {
    $form->{l_warehouse} = 1;
  }
  
  if ($form->{searchitems} eq 'part') {
    $where .= " AND p.inventory_accno_id > 0
                AND p.income_accno_id > 0";
  }
  if ($form->{searchitems} eq 'assembly') {
    $form->{bought} = "";
    $where .= " AND p.assembly = '1'";
  }
  if ($form->{searchitems} eq 'kit') {
    $form->{bought} = "";
    $where .= " AND p.inventory_accno_id IS NULL
                AND p.income_accno_id IS NULL
                AND p.expense_accno_id IS NULL";
  }
  if ($form->{searchitems} eq 'service') {
    $where .= " AND p.assembly = '0'
                AND p.inventory_accno_id IS NULL
                AND p.income_accno_id > 0";
  }
  if ($form->{searchitems} eq 'labor') {
    $where .= " AND p.inventory_accno_id > 0
                AND p.income_accno_id IS NULL";
  }

  # items which were never bought, sold or on an order
  if ($form->{itemstatus} eq 'orphaned') {
    $where .= qq| AND p.onhand = 0
                  AND p.id NOT IN (SELECT p.id FROM parts p
		                   JOIN invoice i ON (p.id = i.parts_id))
		  AND p.id NOT IN (SELECT p.id FROM parts p
		                   JOIN assembly a ON (p.id = a.parts_id))
                  AND p.id NOT IN (SELECT p.id FROM parts p
		                   JOIN orderitems o ON (p.id = o.parts_id))
		  AND p.id NOT IN (SELECT p.id FROM parts p
		                   JOIN jcitems j ON (p.id = j.parts_id))|;
  }
  
  if ($form->{itemstatus} eq 'active') {
    $where .= " AND p.obsolete = '0'";
  }
  if ($form->{itemstatus} eq 'obsolete') {
    $where .= " AND p.obsolete = '1'";
  }
  if ($form->{itemstatus} eq 'onhand') {
    $where .= " AND p.onhand > 0";
  }
  if ($form->{itemstatus} eq 'short') {
    $where .= " AND p.onhand < p.rop";
  }

  my $costflds;
  my $invoicejoin;

  if ($form->{l_cost}) {
    $invoicejoin = " JOIN invoice i ON (i.parts_id = p.id)";
    $costflds = qq|, i.sellprice AS cost|;
    $where .= " AND (i.qty - i.allocated) < 0";
  }
  
  my $makemodelflds = qq|, '', ''|;;
  my $makemodeljoin;
  
  if (($form->{make} ne "") || $form->{l_make} || ($form->{model} ne "") || $form->{l_model}) {
    $makemodelflds = qq|, m.make, m.model|;
    $makemodeljoin = qq|LEFT JOIN makemodel m ON (m.parts_id = p.id)|;
    
    if ($form->{make} ne "") {
      $var = $form->like(lc $form->{make});
      $where .= " AND lower(m.make) LIKE '$var'";
    }
    if ($form->{model} ne "") {
      $var = $form->like(lc $form->{model});
      $where .= " AND lower(m.model) LIKE '$var'";
    }
  }
  if ($form->{partsgroup} ne "") {
    (undef, $var) = split /--/, $form->{partsgroup};
    $where .= qq| AND p.partsgroup_id = $var|;
  }

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company', 'companyemail', 'companywebsite', 'address', 'tel', 'fax', 'businessnumber']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my @sf = qw(partnumber description);

  my $query;
  
  my $curr = substr($form->get_currencies($myconfig, $dbh),0,3);
  
  my $flds = qq|p.id, p.partnumber, p.description, p.onhand, p.unit,
                p.bin, p.sellprice, p.listprice, p.lastcost, p.rop,
		p.avgcost,
		p.weight, p.priceupdate, p.image, p.drawing, p.microfiche,
		p.assembly, pg.partsgroup, pg.code AS partsgroupcode,
		'$curr' AS curr,
		c1.accno AS inventory, c2.accno AS income, c3.accno AS expense,
		p.notes, p.toolnumber, p.countryorigin, p.tariff_hscode,
		p.barcode
		$makemodelflds $assemblyflds $costflds
		|;

  if ($form->{l_cost}) {
    $flds =~ s/p.onhand/(i.qty + i.allocated) * -1 AS onhand/;
  }

  $query = qq|SELECT $flds
	      FROM parts p
	      LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
	      LEFT JOIN chart c1 ON (c1.id = p.inventory_accno_id)
	      LEFT JOIN chart c2 ON (c2.id = p.income_accno_id)
	      LEFT JOIN chart c3 ON (c3.id = p.expense_accno_id)
	      $makemodeljoin
	      $invoicejoin
  	      WHERE $where|;

  # redo query for components report
  if ($form->{searchitems} eq 'component') {
    
    $flds =~ s/p.onhand/a.qty AS onhand/;
    
    if ($form->{itemstatus} eq 'active') {
      $where .= qq| AND p1.obsolete = '0'|;
    }

    $query = qq|SELECT $flds
		FROM assembly a
		JOIN parts p ON (a.parts_id = p.id)
		JOIN parts p1 ON (a.aid = p1.id)
		LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		LEFT JOIN chart c1 ON (c1.id = p.inventory_accno_id)
		LEFT JOIN chart c2 ON (c2.id = p.income_accno_id)
		LEFT JOIN chart c3 ON (c3.id = p.expense_accno_id)
		$makemodeljoin
  	        WHERE $where|;
  }

  # rebuild query for bought and sold items
  if ($form->{bought} || $form->{sold} || $form->{onorder} || $form->{ordered} || $form->{rfq} || $form->{quoted}) {

    $form->sort_order();
    @sf = qw(partnumber description curr employee name);
    push @sf, "transdate";
    push @sf, qw(serialnumber id);
    push @sf, "invnumber" if ($form->{bought} || $form->{sold});
    push @sf, "ordnumber" if ($form->{onorder} || $form->{ordered});
    push @sf, "quonumber" if ($form->{rfq} || $form->{quoted});

    my $union = "";
    $query = "";
  
    if ($form->{bought} || $form->{sold}) {
      
      my $invwhere = "$where";
      my $transdate = ($form->{method} eq 'accrual') ? "transdate" : "datepaid";
      
      $invwhere .= " AND i.assemblyitem = '0'";
      $invwhere .= " AND a.$transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
      $invwhere .= " AND a.$transdate <= '$form->{transdateto}'" if $form->{transdateto};

      if ($form->{description} ne "") {
	$var = $form->like(lc $form->{description});
	$invwhere .= " AND lower(i.description) LIKE '$var'";
      }

      if ($form->{open} || $form->{closed}) {
	if ($form->{open} && $form->{closed}) {
	  if ($form->{method} eq 'cash') {
	    $invwhere .= " AND a.amount = a.paid";
	  }
	} else {
	  if ($form->{open}) {
	    if ($form->{method} eq 'cash') {
	      $invwhere .= " AND a.id = 0";
	    } else {
	      $invwhere .= " AND NOT a.amount = a.paid";
	    }
	  } else {
	    $invwhere .= " AND a.amount = a.paid";
	  }
	}
      } else {
	$invwhere .= " AND a.id = 0";
      }

      my $flds = qq|p.id, p.partnumber, i.description, i.serialnumber,
                    i.qty AS onhand, i.unit, p.bin, i.sellprice,
		    p.listprice, p.lastcost, p.rop, p.weight,
		    p.avgcost,
		    p.priceupdate, p.image, p.drawing, p.microfiche,
		    p.assembly,
		    pg.partsgroup, pg.code AS partsgroupcode,
		    a.invnumber, a.ordnumber, a.quonumber,
                    a.transdate,
		    i.trans_id, ct.name, e.name AS employee,
		    a.curr, a.till, p.notes, p.toolnumber,
		    p.countryorigin, p.tariff_hscode, p.barcode
		    $makemodelflds $costflds|;

      my $rflds;
      
      if ($form->{bought}) {
	
	$rflds = $flds;

	if ($form->{l_cost}) {
	  $rflds =~ s/i.sellprice/p.sellprice/;
	  $rflds =~ s/i.qty AS onhand/(i.qty + i.allocated) * -1 AS onhand/;
	} else {
	  $rflds =~ s/i.qty AS onhand/i.qty * -1 AS onhand/;
	}

	$query = qq|
	            SELECT $rflds, 'ir' AS module, '' AS type,
		    (SELECT exchangerate FROM exchangerate ex
		     WHERE ex.curr = a.curr
		     AND ex.transdate = a.$transdate) AS exchangerate,
		     i.discount, ct.id AS vc_id, 'vendor' as vc
		    FROM invoice i
		    JOIN parts p ON (p.id = i.parts_id)
		    JOIN ap a ON (a.id = i.trans_id)
		    JOIN vendor ct ON (a.vendor_id = ct.id)
		    LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		    LEFT JOIN employee e ON (a.employee_id = e.id)
		    $makemodeljoin
		    WHERE $invwhere|;
	$union = "
	          UNION ALL";
      }

      if ($form->{sold}) {
	
	$query .= qq|$union
                     SELECT $flds, 'is' AS module, '' AS type,
		    (SELECT exchangerate FROM exchangerate ex
		     WHERE ex.curr = a.curr
		     AND ex.transdate = a.$transdate) AS exchangerate,
		     i.discount, ct.id AS vc_id, 'customer' as vc
		     FROM invoice i
		     JOIN parts p ON (p.id = i.parts_id)
		     JOIN ar a ON (a.id = i.trans_id)
		     JOIN customer ct ON (a.customer_id = ct.id)
		     LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		     LEFT JOIN employee e ON (a.employee_id = e.id)
		     $makemodeljoin
		     WHERE $invwhere|;
	$union = "
	          UNION ALL";
      }
    }

    if (! $form->{l_cost}) {
      if ($form->{onorder} || $form->{ordered}) {
	my $ordwhere = "$where
		       AND a.quotation = '0'";
	$ordwhere .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
	$ordwhere .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};

	if ($form->{description} ne "") {
	  $var = $form->like(lc $form->{description});
	  $ordwhere .= " AND lower(i.description) LIKE '$var'";
	}
	
	if ($form->{open} || $form->{closed}) {
	  unless ($form->{open} && $form->{closed}) {
	    $ordwhere .= " AND a.closed = '0'" if $form->{open};
	    $ordwhere .= " AND a.closed = '1'" if $form->{closed};
	  }
	} else {
	  $ordwhere .= " AND a.id = 0";
	}

	$flds = qq|p.id, p.partnumber, i.description, i.serialnumber,
		   i.qty AS onhand, i.unit, p.bin, i.sellprice,
		   p.listprice, p.lastcost, p.rop, p.weight,
		   p.avgcost,
		   p.priceupdate, p.image, p.drawing, p.microfiche,
		   p.assembly,
		   pg.partsgroup, pg.code AS partsgroupcode,
		   '' AS invnumber, a.ordnumber, a.quonumber,
                   a.transdate,
		   i.trans_id, ct.name, e.name AS employee,
		   a.curr, '0' AS till, p.notes, p.toolnumber,
		   p.countryorigin, p.tariff_hscode, p.barcode
		   $makemodelflds|;

	if ($form->{ordered}) {
	  $query .= qq|$union
		       SELECT $flds, 'oe' AS module, 'sales_order' AS type,
		      (SELECT exchangerate FROM exchangerate ex
		       WHERE ex.curr = a.curr
		       AND ex.transdate = a.transdate) AS exchangerate,
		       i.discount, ct.id AS vc_id, 'customer' as vc
		       FROM orderitems i
		       JOIN parts p ON (i.parts_id = p.id)
		       JOIN oe a ON (i.trans_id = a.id)
		       JOIN customer ct ON (a.customer_id = ct.id)
		       LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		       LEFT JOIN employee e ON (a.employee_id = e.id)
		       $makemodeljoin
		       WHERE $ordwhere
		       AND a.customer_id > 0|;
	  $union = "
		    UNION ALL";
	}
	
	if ($form->{onorder}) {
	  $flds = qq|p.id, p.partnumber, i.description, i.serialnumber,
		     i.qty AS onhand, i.unit, p.bin, i.sellprice,
		     p.listprice, p.lastcost, p.rop, p.weight,
		     p.avgcost,
		     p.priceupdate, p.image, p.drawing, p.microfiche,
		     p.assembly,
		     pg.partsgroup, pg.code AS partsgroupcode,
		     '' AS invnumber, a.ordnumber, a.quonumber,
                     a.transdate,
		     i.trans_id, ct.name, e.name AS employee,
		     a.curr, '0' AS till, p.notes, p.toolnumber,
		     p.countryorigin, p.tariff_hscode, p.barcode
		     $makemodelflds|;
		     
	  $query .= qq|$union
		      SELECT $flds, 'oe' AS module, 'purchase_order' AS type,
		      (SELECT exchangerate FROM exchangerate ex
		       WHERE ex.curr = a.curr
		       AND ex.transdate = a.transdate) AS exchangerate,
		       i.discount, ct.id AS vc_id, 'vendor' as vc
		      FROM orderitems i
		      JOIN parts p ON (i.parts_id = p.id)
		      JOIN oe a ON (i.trans_id = a.id)
		      JOIN vendor ct ON (a.vendor_id = ct.id)
		      LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		      LEFT JOIN employee e ON (a.employee_id = e.id)
		      $makemodeljoin
		      WHERE $ordwhere
		      AND a.vendor_id > 0|;
	  $union = "
		    UNION ALL";
	}
      
      }
	
      if ($form->{rfq} || $form->{quoted}) {
	my $quowhere = "$where
		       AND a.quotation = '1'";
	$quowhere .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
	$quowhere .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};

	if ($form->{description} ne "") {
	  $var = $form->like(lc $form->{description});
	  $quowhere .= " AND lower(i.description) LIKE '$var'";
	}
	
	if ($form->{open} || $form->{closed}) {
	  unless ($form->{open} && $form->{closed}) {
	    $ordwhere .= " AND a.closed = '0'" if $form->{open};
	    $ordwhere .= " AND a.closed = '1'" if $form->{closed};
	  }
	} else {
	  $ordwhere .= " AND a.id = 0";
	}

	$flds = qq|p.id, p.partnumber, i.description, i.serialnumber,
		   i.qty AS onhand, i.unit, p.bin, i.sellprice,
		   p.listprice, p.lastcost, p.rop, p.weight,
		   p.avgcost,
		   p.priceupdate, p.image, p.drawing, p.microfiche,
		   p.assembly,
		   pg.partsgroup, pg.code AS partsgroupcode,
		   '' AS invnumber, a.ordnumber, a.quonumber,
                   a.transdate,
		   i.trans_id, ct.name, e.name AS employee,
		   a.curr, '0' AS till, p.notes, p.toolnumber,
		   p.countryorigin, p.tariff_hscode, p.barcode
		   $makemodelflds|;

	if ($form->{quoted}) {
	  $query .= qq|$union
		       SELECT $flds, 'oe' AS module, 'sales_quotation' AS type,
		      (SELECT exchangerate FROM exchangerate ex
		       WHERE ex.curr = a.curr
		       AND ex.transdate = a.transdate) AS exchangerate,
		       i.discount, ct.id AS vc_id, 'customer' as vc
		       FROM orderitems i
		       JOIN parts p ON (i.parts_id = p.id)
		       JOIN oe a ON (i.trans_id = a.id)
		       JOIN customer ct ON (a.customer_id = ct.id)
		       LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		       LEFT JOIN employee e ON (a.employee_id = e.id)
		       $makemodeljoin
		       WHERE $quowhere
		       AND a.customer_id > 0|;
	  $union = "
		    UNION ALL";
	}
	
	if ($form->{rfq}) {
	  $flds = qq|p.id, p.partnumber, i.description, i.serialnumber,
		     i.qty AS onhand, i.unit, p.bin, i.sellprice,
		     p.listprice, p.lastcost, p.rop, p.weight,
		     p.avgcost,
		     p.priceupdate, p.image, p.drawing, p.microfiche,
		     p.assembly,
		     pg.partsgroup, pg.code AS partsgroupcode,
		     '' AS invnumber, a.ordnumber, a.quonumber,
                     a.transdate,
		     i.trans_id, ct.name, e.name AS employee,
		     a.curr, '0' AS till, p.notes, p.toolnumber,
		     p.countryorigin, p.tariff_hscode, p.barcode
		     $makemodelflds|;

	  $query .= qq|$union
		      SELECT $flds, 'oe' AS module, 'request_quotation' AS type,
		      (SELECT exchangerate FROM exchangerate ex
		       WHERE ex.curr = a.curr
		       AND ex.transdate = a.transdate) AS exchangerate,
		       i.discount, ct.id AS vc_id, 'vendor' as vc
		      FROM orderitems i
		      JOIN parts p ON (i.parts_id = p.id)
		      JOIN oe a ON (i.trans_id = a.id)
		      JOIN vendor ct ON (a.vendor_id = ct.id)
		      LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		      LEFT JOIN employee e ON (a.employee_id = e.id)
		      $makemodeljoin
		      WHERE $quowhere
		      AND a.vendor_id > 0|;
	  $union = "
		    UNION ALL";
	}

      }
    }
  }

  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $query = qq|SELECT c.accno
              FROM chart c
	      JOIN partstax pt ON (pt.chart_id = c.id)
	      WHERE pt.parts_id = ?
	      ORDER BY c.accno|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $pth->execute($ref->{id});
    while (($accno) = $pth->fetchrow_array) {
      $ref->{tax} .= "$accno ";
    }
    $pth->finish;

    push @{ $form->{parts} }, $ref;
  }
  $sth->finish;

  my @li = ();
  
  # include individual items for assembly and kit
  if (($form->{searchitems} =~ /(assembly|kit)/) && $form->{individual}) {

    if ($form->{sold} || $form->{ordered} || $form->{quoted}) {
      $flds = qq|p.id, p.partnumber, p.description, p.onhand AS perassembly, p.unit,
                 p.bin, p.sellprice, p.listprice, p.lastcost, p.rop,
		 p.avgcost,
 		 p.weight, p.priceupdate, p.image, p.drawing, p.microfiche,
		 p.assembly, pg.partsgroup, pg.code AS partsgroupcode,
		 p.notes, p.toolnumber, p.barcode
		 $makemodelflds $assemblyflds
		 |;
    } else {
      # replace p.onhand with a.qty AS onhand
      $flds =~ s/p.onhand/a.qty AS perassembly/;
      $flds .= ",p.onhand" if $form->{searchitems} =~ /kit/;
    }
	
    for (@{ $form->{parts} }) {
      push @li, $_;

      $_->{perassembly} = 1;
      $flds =~ s/p\.onhand*AS perassembly/p\.onhand, a\.qty AS perassembly/;
      push @li, &include_assembly($dbh, $myconfig, $form, $_->{id}, $flds, $makemodeljoin, undef, 1);
      push @li, {id => $_->{id}, assemblyitem => 1};  # this is just for
                                                      # adding a blank line
    }

    # copy assemblies to $form->{parts}
    @{ $form->{parts} } = @li;
    
  }
    
  @li = ();
  
  if (($form->{warehouse} ne "") || $form->{l_warehouse}) {
    
    if ($form->{warehouse} ne "") {
      ($warehouse, $var) = split /--/, $form->{warehouse};
      $var *= 1;
      $query = qq|SELECT SUM(qty) AS onhand, '$warehouse' AS warehouse
                  FROM inventory
		  WHERE warehouse_id = $var
                  AND parts_id = ?|;
    } else {
      $query = qq|SELECT SUM(i.qty) AS onhand, w.description AS warehouse
                  FROM inventory i
		  JOIN warehouse w ON (w.id = i.warehouse_id)
                  WHERE i.parts_id = ?
		  GROUP BY w.description
                  ORDER BY warehouse|;
    }

    $sth = $dbh->prepare($query) || $form->dberror($query);

    my @tp;
    my %id;

    for (@{ $form->{parts} }) {

      @tp = ();

      $sth->execute($_->{id}) || $form->dberror($query);

      if ($form->{warehouse} ne "") {
	$ref = $sth->fetchrow_hashref(NAME_lc);
        if ($_->{assemblyitem}) {
          if ($form->{searchitems} =~ /kit/) {
            $_->{onhand} = $ref->{onhand};
          }
          push @tp, $_ if $ok;
        } else {
          $ok = 0;
          if ($_->{onhand} = $ref->{onhand}) {
            $ok = 1;
            push @tp, $_;
          }
        }

      } else {

	push @tp, $_;

        if ($_->{assemblyitem}) {
          while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
            if ($form->{searchitems} =~ /kit/) {
              $ref->{id} = $_->{id};
              push @tp, $ref;
            }
          }
        } else {
          while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
            $ref->{id} = $_->{id};
            push @tp, $ref;
          }
        }
      }
      
      push @li, @tp;
      
      $sth->finish;
    }

    @{ $form->{parts} } = @li;

  }
  
  $form->get_peripherals($dbh);

  $form->all_languages($myconfig, $dbh);

  $dbh->disconnect;

}


sub include_assembly {
  my ($dbh, $myconfig, $form, $id, $flds, $makemodeljoin, $qty, $all) = @_;
  
  $form->{stagger}++;
  if ($form->{stagger} > $form->{pncol}) {
    $form->{pncol} = $form->{stagger};
  }
 
  $form->{$id} = 1;
  $qty *= 1;

  my @sf = qw(partnumber description bin);
  if ($form->{sort} eq 'partnumber') {
    $sortorder = "a.id";
  } else {
    @sf = grep !/$form->{sort}/, @sf;
    $sortorder = "p.$form->{sort} $form->{direction}, ". join ',p.', @sf;
  }
  
  @sf = ();
  my $query = qq|SELECT $flds
		 FROM parts p
		 JOIN assembly a ON (a.parts_id = p.id)
		 LEFT JOIN partsgroup pg ON (pg.id = p.id)
 		 LEFT JOIN chart c1 ON (c1.id = p.inventory_accno_id)
		 LEFT JOIN chart c2 ON (c2.id = p.income_accno_id)
		 LEFT JOIN chart c3 ON (c3.id = p.expense_accno_id)
		 $makemodeljoin
		 WHERE a.aid = $id
		 ORDER BY $sortorder|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{assemblyitem} = 1;
    $ref->{stagger} = $form->{stagger};
    $ref->{qty} *= $qty;

    push @sf, $ref;
    next unless $all;

    if ($ref->{assembly} &! $form->{$ref->{id}}) {
      push @sf, &include_assembly($dbh, $myconfig, $form, $ref->{id}, $flds, $makemodeljoin, $ref->{qty}, $all);
      if ($form->{stagger} > $form->{pncol}) {
	$form->{pncol} = $form->{stagger};
      }
    }
  }
  $sth->finish;

  $form->{$id} = 0;
  $form->{stagger}--;

  @sf;

}


sub get_assembly_bom_transfer {
  my ($self, $myconfig, $form) = @_;

  my $var;
 
  my $where = qq|p.assembly = '1'
                 AND p.obsolete = '0'
                 AND p.project_id IS NULL|;
 
  for (qw(partnumber description)) {
    if ($form->{$_} ne "") {
      $var = $form->like(lc $form->{$_});
      $where .= " AND lower(p.$_) LIKE '$var'";
    }
  }

  if ($form->{partsgroup} ne "") {
    (undef, $var) = split /--/, $form->{partsgroup};
    $where .= qq| AND p.partsgroup_id = $var|;
  }

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company', 'companyemail', 'companywebsite', 'address', 'tel', 'fax', 'businessnumber']});
  
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my %ordinal = ( 'partnumber' => 2 );
  my @sf = qw(partnumber);
  my $sortorder = $form->sort_order(\@sf, \%ordinal);

  my $query = qq|SELECT p.id, p.partnumber, p.description, p.unit,
                 p.assembly, p.onhand, pg.partsgroup, pg.code AS partsgroupcode
                 FROM parts p
                 LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
                 WHERE $where
                 ORDER BY $sortorder|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{parts} }, $ref;
  }
  $sth->finish;

  $form->{qty} = $form->parse_amount($myconfig, $form->{qty});

  my @li = ();
  my $flds = qq|p.id, p.partnumber, p.description, p.unit,
                p.assembly, p.onhand, a.qty|;

  for (@{ $form->{parts} }) {
    push @li, $_;
    push @li, &include_assembly($dbh, $myconfig, $form, $_->{id}, $flds, undef, $form->{qty}, undef);
  }

  $query = qq|SELECT SUM(i.qty)
              FROM inventory i
              WHERE i.warehouse_id = ?
              AND i.parts_id = ?|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  # total all warehouses
  $query = qq|SELECT SUM(i.qty)
              FROM inventory i
              WHERE i.warehouse_id > 0
              AND i.parts_id = ?|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);

  my ($fromwarehouse, $fromwarehouse_id) = split /--/, $form->{fromwarehouse};
  my ($towarehouse, $towarehouse_id) = split /--/, $form->{towarehouse};

  @{ $form->{all_inventory} } = ();

  for (@li) {

    if ($fromwarehouse_id) {
      $sth->execute($fromwarehouse_id, $_->{id});

      ($_->{fromonhand}) = $sth->fetchrow_array;
      $_->{fromwarehouse} = $fromwarehouse;
      $_->{fromwarehouse_id} = $fromwarehouse_id;

      $sth->finish;
    } else {
      $ath->execute($_->{id});
      ($var) = $ath->fetchrow_array;
      $ath->finish;
      $_->{fromonhand} = $_->{onhand} - $var;
    }

    if ($towarehouse_id) {
      $sth->execute($towarehouse_id, $_->{id});

      ($_->{toonhand}) = $sth->fetchrow_array;
      $_->{towarehouse} = $towarehouse;
      $_->{towarehouse_id} = $towarehouse_id;
    } else {
      $ath->execute($_->{id});
      ($var) = $ath->fetchrow_array;
      $ath->finish;
      $_->{toonhand} = $_->{onhand} - $var;
    }

    $_->{transfer} = $_->{qty};
    
    push @{ $form->{all_inventory} }, $_;
    
    $sth->finish;
  }

  $dbh->disconnect;

}


sub supply_demand {
  my ($self, $myconfig, $form) = @_;

  my $var;
  my $ref;
  
  my $where = qq|p.obsolete = '0'|;
  my $dwhere;

  for (qw(partnumber description)) {
    if ($form->{$_} ne "") {
      $var = $form->like(lc $form->{$_});
      $where .= qq| AND lower(p.$_) LIKE '$var'|;
    }
  }
  
  if ($form->{partsgroup} ne "") {
    (undef, $var) = split /--/, $form->{partsgroup};
    $where .= qq| AND p.partsgroup_id = $var|;
  }

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my ($transdatefrom, $transdateto);
  if ($form->{year}) {
    ($transdatefrom, $transdateto) = $form->from_to($form->{year}, '01', 12);
    
    $dwhere = qq| AND a.transdate >= '$transdatefrom'
 		  AND a.transdate <= '$transdateto'|;
  }
    
  $query = qq|SELECT p.id, p.partnumber, p.description,
              sum(i.qty) AS qty, p.onhand, p.rop,
	      extract(MONTH FROM a.transdate) AS month,
	      '0' AS so, '0' AS po
	      FROM invoice i
	      JOIN parts p ON (p.id = i.parts_id)
	      JOIN ar a ON (a.id = i.trans_id)
	      WHERE $where
	      $dwhere
	      AND p.inventory_accno_id > 0
	      GROUP BY p.id, p.partnumber, p.description, p.onhand, p.rop,
	      extract(MONTH FROM a.transdate)|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my %parts;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    if (exists $parts{$ref->{id}}) {
      $parts{$ref->{id}}->{$ref->{month}} = $ref->{qty};
      $parts{$ref->{id}}->{qty} += $ref->{qty};
    } else {
      $ref->{$ref->{month}} = $ref->{qty};
      $parts{$ref->{id}} = $ref;
    }
  }
  $sth->finish;

  my %ofld = ( customer => so,
               vendor => po );
  
  for (qw(customer vendor)) {
    $query = qq|SELECT p.id, p.partnumber, p.description,
		sum(i.qty) - sum(i.ship) AS $ofld{$_}, p.onhand, p.rop,
		0 AS month
		FROM orderitems i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN oe a ON (a.id = i.trans_id)
		WHERE $where
		AND p.inventory_accno_id > 0
		AND a.closed = '0'
		AND a.quotation = '0'
		AND a.${_}_id > 0
		GROUP BY p.id, p.partnumber, p.description, p.onhand, p.rop,
		month|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      if (exists $parts{$ref->{id}}) {
	$parts{$ref->{id}}->{$ofld{$_}} += $ref->{$ofld{$_}};
      } else {
	$parts{$ref->{id}} = $ref;
      }
    }
    $sth->finish;
  }

  # add assemblies from open sales orders
  $query = qq|SELECT p.id, SUM(i.qty) - SUM(i.ship) AS qty, p.onhand, p.rop
              FROM orderitems i
	      JOIN parts p ON (p.id = i.parts_id)
	      JOIN oe a ON (a.id = i.trans_id)
	      WHERE p.obsolete = '0'
	      AND p.assembly = '1'
	      AND a.closed = '0'
	      GROUP BY p.id, p.onhand, p.rop|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{qty} -= $ref->{onhand};
    &assembly_demand($dbh, $form, \%parts, $ref->{id}, $ref->{qty}, $where) if $ref->{qty};
  }
  $sth->finish;

  $dbh->disconnect;

  for (sort { $parts{$a}->{$form->{sort}} cmp $parts{$b}->{$form->{sort}} } keys %parts) {
    push @{ $form->{parts} }, $parts{$_};
  }
  
}


sub assembly_demand {
  my ($dbh, $form, $parts, $id, $qty, $where) = @_;

  # assemblies
  my $query = qq|SELECT p.id, p.partnumber, p.description,
                 a.qty * $qty AS so, p.onhand, p.assembly,
	         p.partsgroup_id
	         FROM assembly a
	         JOIN parts p ON (p.id = a.parts_id)
 	         WHERE $where
		 AND a.aid = $id
	         AND p.inventory_accno_id > 0
		 
		 UNION
	  
	         SELECT p.id, p.partnumber, p.description,
                 a.qty * $qty AS so, p.onhand, p.assembly,
	         p.partsgroup_id
	         FROM assembly a
	         JOIN parts p ON (p.id = a.parts_id)
 	         WHERE $where
                 AND a.aid = $id
		 AND p.assembly = '1'|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    if ($ref->{assembly}) {
      &assembly_requirements($dbh, $form, $parts, $ref->{id}, $ref->{so}, $where);
      next;
    }

    if (exists $parts->{$ref->{id}}) {
      $parts->{$ref->{id}}{so} += $ref->{so};
    } else {
      $parts->{$ref->{id}} = $ref;
    }
  }
  $sth->finish;
    
}


sub requirements {
  my ($self, $myconfig, $form) = @_;

  my $var;
  my $ref;
  my $id;
  my $qty;
  
  my $where = qq|p.obsolete = '0'|;

  for (qw(partnumber description)) {
    if ($form->{$_} ne "") {
      $var = $form->like(lc $form->{$_});
      $where .= qq| AND lower(p.$_) LIKE '$var'|;
    }
  }
  
  if ($form->{partsgroup} ne "") {
    (undef, $var) = split /--/, $form->{partsgroup};
    $where .= qq| AND p.partsgroup_id = $var|;
  }

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $query = qq|SELECT p.*
	      FROM parts p
	      WHERE $where
	      AND p.inventory_accno_id > 0
	      UNION
	      SELECT p.*
	      FROM parts p
	      WHERE $where
	      AND p.assembly = '1'
	      |;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my %parts;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $parts{$ref->{id}} = $ref;
  }
  $sth->finish;

  # add assemblies
  $query = qq|SELECT p.*
	      FROM parts p
	      WHERE $where
	      AND p.assembly = '1'
	      |;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $qty = $ref->{rop} - $ref->{onhand};
    &assembly_requirements($dbh, $form, \%parts, $ref->{id}, $qty) if $qty > 0;
  }
  $sth->finish;


  # if part belongs to an assembly
  $query = qq|SELECT a.aid, a.qty, p.onhand, p.rop, p.id, p.assembly
	      FROM parts p
	      JOIN assembly a ON (a.parts_id = p.id)
	      WHERE $where
	      |;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $query = qq|SELECT p.*
	      FROM parts p
	      WHERE p.id = ?
	      |;
  my $pth = $dbh->prepare($query) || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    $qty = $ref->{rop} - $ref->{onhand};
    $qty = 0 if $qty < 0;

    if ($qty) {
      
      $qty *= $ref->{qty};

      if (exists $parts{$ref->{id}}) {
	if ($ref->{assembly}) {
	  &assembly_requirements($dbh, $form, \%parts, $ref->{id}, $qty);
	} else {
	  $parts{$ref->{id}}{amb} = $qty;
	}
      } else {
	
	$pth->execute($ref->{id});
	$pref = $pth->fetchrow_hashref(NAME_lc);

	$pref->{amb} = $qty;

	if ($pref->{assembly}) {
	  &assembly_requirements($dbh, $form, \%parts, $ref->{id}, $qty);
	} else {
	  if (exists $parts{$ref->{id}}) {
	    $parts{$ref->{id}}{amb} += $qty;
	  } else {
	    $parts{$ref->{id}} = $pref;
	  }
	}
	$pth->finish;
      }
    }
  }
  $sth->finish;


  # check for parts on open orders 
  my %ofld = ( customer => so,
               vendor => po );
  
  for (qw(customer vendor)) {
    $query = qq|SELECT sum(qty) - sum(ship) AS $ofld{$_}, p.assembly, p.onhand,
                p.rop
		FROM orderitems i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN oe a ON (a.id = i.trans_id)
		WHERE i.parts_id = ?
		AND a.closed = '0'
		AND a.quotation = '0'
		AND a.${_}_id > 0
		GROUP BY p.assembly, p.onhand, p.rop
		|;
    $sth = $dbh->prepare($query) || $form->dberror($query);

    for $id (keys %parts) {
      $sth->execute($id);
      $ref = $sth->fetchrow_hashref(NAME_lc);
      $qty = $ref->{$ofld{$_}} - $ref->{onhand};
      $qty = 0 if $qty < 0;
      if ($qty) {
	if ($ref->{assembly}) {
	  &assembly_requirements($dbh, $form, \%parts, $id, $qty);
	} else {
	  $parts{$id}{$ofld{$_}} += $qty;
	}
      }
      $sth->finish;
    }
  }

  $dbh->disconnect;

  for (sort { $parts{$a}->{$form->{sort}} cmp $parts{$b}->{$form->{sort}} } keys %parts) {
    push @{ $form->{parts} }, $parts{$_};
  }
  
}


sub assembly_requirements {
  my ($dbh, $form, $parts, $id, $qty) = @_;

  # assemblies
  my $query = qq|SELECT p.id, p.partnumber, p.description,
                 a.qty * $qty AS amb, p.onhand, p.assembly,
	         p.partsgroup_id, p.rop
	         FROM assembly a
	         JOIN parts p ON (p.id = a.parts_id)
 	         WHERE p.obsolete = '0'
		 AND a.aid = $id
	         AND p.inventory_accno_id > 0
		 
		 UNION
	  
	         SELECT p.id, p.partnumber, p.description,
                 a.qty * $qty AS amb, p.onhand, p.assembly,
	         p.partsgroup_id, p.rop
	         FROM assembly a
	         JOIN parts p ON (p.id = a.parts_id)
 	         WHERE p.obsolete = '0'
                 AND a.aid = $id
		 AND p.assembly = '1'|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    if ($ref->{assembly}) {
      if (exists $parts->{$ref->{id}}) {
	$parts->{$ref->{id}}{amb} += $ref->{amb};
      } else {
	$parts->{$ref->{id}} = $ref;
      }

      &assembly_requirements($dbh, $form, $parts, $ref->{id}, $ref->{amb});
      next;
    }

    if (exists $parts->{$ref->{id}}) {
      $parts->{$ref->{id}}{amb} += $ref->{amb};
    } else {
      $parts->{$ref->{id}} = $ref;
    }
  }
  $sth->finish;
    
}


sub create_links {
  my ($self, $module, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $ref;

  my $query = qq|SELECT c.accno, c.description, c.link,
                 l.description AS translation
                 FROM chart c
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		 WHERE c.link LIKE '%$module%'
		 ORDER BY c.accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    foreach my $key (split /:/, $ref->{link}) {
      if ($key =~ /$module/) {
	$ref->{description} = $ref->{translation} if $ref->{translation};

	push @{ $form->{"${module}_links"}{$key} }, { accno => $ref->{accno},
				      description => $ref->{description} };
      }
    }
  }
  $sth->finish;

  if ($form->{item} ne 'assembly') {
    $query = qq|SELECT count(*) FROM vendor|;
    my ($count) = $dbh->selectrow_array($query);

    if ($count < $myconfig->{vclimit}) {
      $query = qq|SELECT id, name
		  FROM vendor
		  ORDER BY name|;
      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);

      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	push @{ $form->{all_vendor} }, $ref;
      }
      $sth->finish;
    }
  }

  # pricegroups, customers
  $query = qq|SELECT count(*) FROM customer|;
  ($count) = $dbh->selectrow_array($query);

  if ($count < $myconfig->{vclimit}) {
    $query = qq|SELECT id, name
		FROM customer
		ORDER BY name|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{all_customer} }, $ref;
    }
    $sth->finish;
  }

  $query = qq|SELECT id, pricegroup
              FROM pricegroup
	      ORDER BY pricegroup|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_pricegroup} }, $ref;
  }
  $sth->finish;


  if ($form->{id} *= 1) {
    my %defaults = $form->get_defaults($dbh, \@{[qw(weightunit precision referenceurl)]});
    for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
    $form->all_references($dbh);

  } else {
    $form->{priceupdate} = $form->current_date($myconfig);
    
    my %defaults = $form->get_defaults($dbh, \@{['weightunit', '%_accno_id', 'precision', 'referenceurl']});
    for (qw(weightunit precision referenceurl)) { $form->{$_} = $defaults{$_} }

    for (qw(inventory income expense)) {
      $query = qq|SELECT c.accno, c.description,
                  l.description AS translation
                  FROM chart c
		  LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		  WHERE c.id = '$defaults{"${_}_accno_id"}'|;
      ($form->{"${_}_accno"}, $form->{"${_}_description"}, $form->{"${_}_translation"}) = $dbh->selectrow_array($query);
      $form->{"${_}_description"} = $form->{"${_}_translation"} if $form->{"${_}_translation"};
      $form->{amount}{"IC_$_"} = { accno => $form->{"${_}_accno"}, description => $form->{"${_}_description"} };
      
    }
    
  }

  $form->{currencies} = $form->get_currencies($myconfig, $dbh);
  
  $form->get_partsgroup($myconfig, {all => 1}, $dbh);
 
  $dbh->disconnect;

}


sub get_warehouses {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT id, description
                 FROM warehouse
                 ORDER BY rn|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  if ($form->{searchitems} !~ /(service|labor)/) {
    while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{all_warehouse} }, $ref;
    }
  }
  $sth->finish;

  $form->get_partsgroup($myconfig, { searchitems => $form->{searchitems}, subgroup => 1 }, $dbh);

  $form->all_years($myconfig, $dbh);

  $dbh->disconnect;

}


sub get_inventory {
  my ($self, $myconfig, $form) = @_;

  my $query;
  my $var;

  my $dbh = $form->dbconnect($myconfig);
  
  my %defaults = $form->get_defaults($dbh, \@{[qw(company address tel fax companyemail companywebsite)]});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $where = qq|
                 AND p.obsolete = '0'
                 AND ((p.inventory_accno_id > 0 AND p.income_accno_id > 0)
                 OR p.assembly = '1')|;
  
  if ($form->{partnumber} ne "") {
    $var = $form->like(lc $form->{partnumber});
    $where .= "
                AND lower(p.partnumber) LIKE '$var'";
  }
  if ($form->{description} ne "") {
    $var = $form->like(lc $form->{description});
    $where .= "
                AND lower(p.description) LIKE '$var'";
  }
  if ($form->{partsgroup} ne "") {
    (undef, $var) = split /--/, $form->{partsgroup};
    $where .= "
                AND pg.id = $var";
  }

  my $wwhere = $where;
  if ($form->{warehouse} ne "") {
    (undef, $var) = split /--/, $form->{warehouse};
    $wwhere .= " AND i.warehouse_id = $var";

    $query = qq|
            SELECT p.id, p.partnumber, p.description, p.bin,
            pg.partsgroup, '' AS warehouse, 0 AS warehouse_id,
            p.unit, p.onhand,
            (SELECT SUM(qty) FROM inventory i WHERE i.parts_id = p.id AND i.warehouse_id > 0) AS qty
            FROM parts p
            LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
            WHERE p.onhand > 0
            $where
        UNION
            SELECT p.id, p.partnumber, p.description, p.bin,
            pg.partsgroup, w.description AS warehouse, i.warehouse_id,
            p.unit, sum(i.qty) * 2 AS onhand,
            sum(i.qty) AS qty
            FROM inventory i
            JOIN parts p ON (p.id = i.parts_id)
            LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
            JOIN warehouse w ON (w.id = i.warehouse_id)
            $wwhere
            GROUP BY p.id, p.partnumber, p.description, p.bin, p.unit, pg.partsgroup, w.description, i.warehouse_id|;
  } else {
    $query = qq|
            SELECT p.id, p.partnumber, p.description, p.bin,
            pg.partsgroup, '' AS warehouse, 0 AS warehouse_id,
            p.unit, p.onhand,
            (SELECT SUM(qty) FROM inventory i WHERE i.parts_id = p.id AND i.warehouse_id > 0) AS qty
            FROM parts p
            LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
            WHERE p.onhand > 0
            $where
        UNION
            SELECT p.id, p.partnumber, p.description, p.bin,
            pg.partsgroup, w.description AS warehouse, i.warehouse_id,
            p.unit, sum(i.qty) * 2 AS onhand,
            sum(i.qty) AS qty
            FROM inventory i
            JOIN parts p ON (p.id = i.parts_id)
            LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
            LEFT JOIN warehouse w ON (w.id = i.warehouse_id)
            WHERE 1 = 1
            $where
            GROUP BY p.id, p.partnumber, p.description, p.bin, p.unit, pg.partsgroup, w.description, i.warehouse_id|;

  }

  my @sf = qw(partnumber warehouse);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{qty} = $ref->{onhand} - $ref->{qty};
    push @{ $form->{all_inventory} }, $ref if $ref->{qty};
  }
  $sth->finish;

  &get_warehouses("", $myconfig, $form, $dbh);

  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);

  $dbh->disconnect;

}


sub transfer {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  
  my @a = localtime;
  $a[5] += 1900;
  $a[4]++;
  $a[4] = substr("0$a[4]", -2);
  $a[3] = substr("0$a[3]", -2);
  $shippingdate = ($form->{shippingdate}) ? $form->{shippingdate} : "$a[5]$a[4]$a[3]";

  my %total = ();

  my $query = qq|INSERT INTO inventory
                 (warehouse_id, parts_id, qty, shippingdate, employee_id)
		 VALUES (?, ?, ?, '$shippingdate', $form->{employee_id})|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT partnumber, assembly, onhand
              FROM parts
              WHERE id = ?|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT SUM(qty)
              FROM inventory
              WHERE warehouse_id = ?
              AND parts_id = ?|;
  my $ith = $dbh->prepare($query) || $form->dberror($query);

  my %audittrail;
  my $qty;
  my $partnumber;
  my $assembly;
  my $onhand;
  
  for $i (1 .. $form->{rowcount}) {
    $qty = $form->parse_amount($myconfig, $form->{"transfer_$i"});

    if ($qty) {
      # check if it is an assembly
      $ath->execute($form->{"id_$i"});
      ($partnumber, $assembly, $onhand) = $ath->fetchrow_array;
      $ath->finish;

      %audittrail = ( tablename	=> 'ic',
                      reference => $partnumber,
		      formname => $assembly ? 'assembly' : 'part',
                      action     => 'transfer',
		      id => $form->{"id_$i"}
		      );

      $form->audittrail($dbh, "", \%audittrail);

      if ($assembly) {
        if ($form->{"warehouse_id_$i"}) {
          $ith->execute($form->{"warehouse_id_$i"}, $form->{"id_$i"});
          ($onhand) = $ith->fetchrow_array;
          $ith->finish;
          $form->{warehouse_id} = $form->{"warehouse_id_$i"};
        } else {
          delete $form->{warehouse_id};
        }

        if ($qty > $onhand) {
          #stock assembly
          &adjust_inventory($dbh, $form, $form->{"id_$i"} * 1, $qty - $onhand);
        }
      }

      # to warehouse
      if ($form->{"towarehouse_$i"}) {
	(undef, $towarehouse_id) = split /--/, $form->{"towarehouse_$i"}; 
	$sth->execute($towarehouse_id, $form->{"id_$i"}, $qty) || $form->dberror;
	$sth->finish;
      }
      
      # from warehouse
      if ($form->{"warehouse_id_$i"}) {
	$sth->execute($form->{"warehouse_id_$i"}, $form->{"id_$i"}, $qty * -1) || $form->dberror;
	$sth->finish;
      }
    }
  }

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub transfer_report {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);
  
  my $var;
  my %inventory;
  my $where = "1 = 1";
  my $warehouse_id;
  
  if ($form->{partnumber} ne "") {
    $var = $form->like(lc $form->{partnumber});
    $where .= "
                AND lower(p.partnumber) LIKE '$var'";
  }
  if ($form->{description} ne "") {
    $var = $form->like(lc $form->{description});
    $where .= "
                AND lower(p.description) LIKE '$var'";
  }
  if ($form->{partsgroup} ne "") {
    (undef, $var) = split /--/, $form->{partsgroup};
    $where .= "
                AND pg.id = $var";
  }
  if ($form->{warehouse} ne "") {
    (undef, $warehouse_id) = split /--/, $form->{warehouse};
    $where .= "
                AND i.warehouse_id = $warehouse_id";
  }
  
  unless ($form->{transdatefrom} || $form->{transdateto}) {
    ($form->{transdatefrom}, $form->{transdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }

  $where .= " AND i.shippingdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
  $where .= " AND i.shippingdate <= '$form->{transdateto}'" if $form->{transdateto};

  my $query = qq|SELECT p.id, p.partnumber, p.description,
              pg.partsgroup, w.description AS warehouse, i.shippingdate,
	      e.name AS employee, i.employee_id, i.qty, i.id AS iid, p.unit
	      FROM inventory i
	      JOIN parts p ON (p.id = i.parts_id)
	      LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
	      JOIN warehouse w ON (w.id = i.warehouse_id)
	      LEFT JOIN employee e ON (e.id = i.employee_id)
	      WHERE $where|;

  my @sf = (shippingdate, partnumber, iid);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $query = qq|SELECT i.id, w.description
              FROM inventory i
              JOIN warehouse w ON (w.id = i.warehouse_id)
              WHERE parts_id = ?
              AND shippingdate = ?
              AND employee_id = ?
              AND qty = ?
              ORDER BY i.id|;
  my $wth = $dbh->prepare($query) || $form->dberror($query);

  my $ref;
  my $wref;
  my $found;

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    $found = 0;
    next if $inventory{$ref->{iid}};

    $qty = $ref->{qty};

    if ($ref->{qty} > 0) {
      $ref->{towarehouse} = $ref->{warehouse};
    } else {
      $ref->{qty} *= -1;
      $ref->{fromwarehouse} = $ref->{warehouse};
    }
 
    $inventory{$ref->{iid}} = 1;

    $wth->execute($ref->{id}, $ref->{shippingdate}, $ref->{employee_id}, $qty * -1);

    while ($wref = $wth->fetchrow_hashref(NAME_lc)) {
      $found = 1;
      next if $inventory{$wref->{id}};
      $inventory{$wref->{id}} = 1;
      if ($qty > 0) {
        $ref->{towarehouse} = $ref->{warehouse};
        $ref->{fromwarehouse} = $wref->{description};
      } else {
        $ref->{qty} = $qty * -1;
        $ref->{towarehouse} = $wref->{description};
        $ref->{fromwarehouse} = $ref->{warehouse};
      }

      push @{ $form->{inventory_transfer} }, $ref unless $ref->{warehouse} eq $wref->{description};
      last;
    }

    $wth->finish;

    push @{ $form->{inventory_transfer} }, $ref unless $found;

  }
  $sth->finish;

  $dbh->disconnect;

}


sub so_requirements {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $var;
  my $where = "o.closed = '0' AND o.quotation = '0'";
  
  $form->{vc} =~ s/;//g;

  if ($form->{searchitems} eq 'part') {
    $where .= " AND p.inventory_accno_id > 0 AND p.income_accno_id > 0";
  }
  if ($form->{searchitems} eq 'assembly') {
    $where .= " AND p.assembly = '1'";
  }
  if ($form->{searchitems} eq 'service') {
    $where .= " AND p.assembly = '0' AND p.inventory_accno_id IS NULL";
  }
  if ($form->{searchitems} eq 'labor') {
    $where .= " AND p.inventory_accno_id > 0 AND p.income_accno_id IS NULL";
  }

  if ($form->{partnumber}) {
    $var = $form->like(lc $form->{partnumber});
    $where .= " AND lower(p.partnumber) LIKE '$var'";
  }
  if ($form->{description}) {
    $var = $form->like(lc $form->{description});
    $where .= " AND lower(p.description) LIKE '$var'";
  }
  if ($form->{$form->{vc}}) {
    $var = $form->like(lc $form->{$form->{vc}});
    $where .= " AND lower(c.name) LIKE '$var'";
  }
  if ($form->{"$form->{vc}number"}) {
    $var = $form->like(lc $form->{"$form->{vc}number"});
    $where .= " AND lower(c.$form->{vc}number) LIKE '$var'";
  }

  unless ($form->{reqdatefrom} || $form->{reqdateto}) {
    ($form->{reqdatefrom}, $form->{reqdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
  $where .= " AND o.reqdate >= '$form->{reqdatefrom}'" if $form->{reqdatefrom};
  $where .= " AND o.reqdate <= '$form->{reqdateto}'" if $form->{reqdateto};
  
  my $query = qq|SELECT p.partnumber, p.id as parts_id,
                 c.id AS $form->{vc}_id, c.name, c.$form->{vc}number,
		 o.id, o.ordnumber, o.reqdate,
		 oi.qty, oi.description
                 FROM oe o
		 JOIN orderitems oi ON (oi.trans_id = o.id)
		 JOIN parts p ON (p.id = oi.parts_id)
		 JOIN $form->{vc} c ON (o.$form->{vc}_id = c.id)
		 WHERE $where|;

  my @sf = qw(partnumber ordnumber reqdate);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);
 
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_parts} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}


sub history {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (%defaults) { $form->{$_} = $defaults{$_} }
  
  my $id = $form->{id} * 1;
  
  my $query;

  if ($form->{history} eq 'sales') {
    $query = qq|SELECT 'ar' AS module, p.partnumber, i.description,
		i.sellprice, c.name, a.invnumber AS trn,
		a.id, 'invoice' AS type, a.transdate
		FROM invoice i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN ar a ON (a.id = i.trans_id)
		JOIN customer c ON (c.id = a.customer_id)
		WHERE i.parts_id = $id
	      UNION ALL
		SELECT 'so' AS module, p.partnumber, i.description,
		i.sellprice * o.exchangerate AS sellprice,
		c.name, o.ordnumber AS trn, o.id, 'sales_order' AS type,
		o.transdate
		FROM orderitems i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN oe o ON (o.id = i.trans_id)
		JOIN customer c ON (c.id = o.customer_id)
		WHERE o.quotation = '0'
		AND i.parts_id = $id
	      UNION ALL
		SELECT 'sq' AS module, p.partnumber, i.description,
		i.sellprice * o.exchangerate AS sellprice,
		c.name, o.quonumber AS trn, o.id, 'sales_quotation' AS type,
		o.transdate
		FROM orderitems i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN oe o ON (o.id = i.trans_id)
		JOIN customer c ON (c.id = o.customer_id)
		WHERE o.quotation = '1'
		AND i.parts_id = $id
		ORDER BY 1, transdate
		|;

  } elsif ($form->{history} eq 'purchases') {
    $query = qq|SELECT 'ap' AS module, p.partnumber, i.description,
		i.sellprice, v.name, a.invnumber AS trn,
		a.id, 'invoice' AS type, a.transdate
		FROM invoice i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN ap a ON (a.id = i.trans_id)
		JOIN vendor v ON (v.id = a.vendor_id)
		WHERE i.parts_id = $id
	      UNION ALL
		SELECT 'po' AS module, p.partnumber, i.description,
		i.sellprice * o.exchangerate AS sellprice,
		v.name, o.ordnumber AS trn, o.id, 'purchase_order' AS type,
		o.transdate
		FROM orderitems i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN oe o ON (o.id = i.trans_id)
		JOIN vendor v ON (v.id = o.vendor_id)
		WHERE o.quotation = '0'
		AND i.parts_id = $id
	      UNION ALL
		SELECT 'rfq' AS module, p.partnumber, i.description,
		i.sellprice * o.exchangerate AS isellprice,
		v.name, o.quonumber AS trn, o.id, 'request_quotation' AS type,
		o.transdate
		FROM orderitems i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN oe o ON (o.id = i.trans_id)
		JOIN vendor v ON (v.id = o.vendor_id)
		WHERE o.quotation = '1'
		AND i.parts_id = $id
		ORDER BY 1, transdate
		|;
  } else {
    $query = qq|SELECT 'ar' AS module, p.partnumber, i.description,
		i.sellprice, c.name, a.invnumber AS trn,
		a.id, 'invoice' AS type, a.transdate
		FROM invoice i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN ar a ON (a.id = i.trans_id)
		JOIN customer c ON (c.id = a.customer_id)
		WHERE i.parts_id = $id
	      UNION ALL
		SELECT 'ap' AS module, p.partnumber, i.description,
		i.sellprice, v.name, a.invnumber AS trn,
		a.id, 'invoice' AS type, a.transdate
		FROM invoice i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN ap a ON (a.id = i.trans_id)
		JOIN vendor v ON (v.id = a.vendor_id)
		WHERE i.parts_id = $id
	      UNION ALL
		SELECT 'so' AS module, p.partnumber, i.description,
		i.sellprice * o.exchangerate AS sellprice,
		c.name, o.ordnumber AS trn, o.id, 'sales_order' AS type,
		o.transdate
		FROM orderitems i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN oe o ON (o.id = i.trans_id)
		JOIN customer c ON (c.id = o.customer_id)
		WHERE o.quotation = '0'
		AND i.parts_id = $id
	      UNION ALL
		SELECT 'po' AS module, p.partnumber, i.description,
		i.sellprice * o.exchangerate AS sellprice,
		v.name, o.ordnumber AS trn, o.id, 'purchase_order' AS type,
		o.transdate
		FROM orderitems i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN oe o ON (o.id = i.trans_id)
		JOIN vendor v ON (v.id = o.vendor_id)
		WHERE o.quotation = '0'
		AND i.parts_id = $id
	      UNION ALL
		SELECT 'sq' AS module, p.partnumber, i.description,
		i.sellprice * o.exchangerate AS sellprice,
		c.name, o.quonumber AS trn, o.id, 'sales_quotation' AS type,
		o.transdate
		FROM orderitems i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN oe o ON (o.id = i.trans_id)
		JOIN customer c ON (c.id = o.customer_id)
		WHERE o.quotation = '1'
		AND i.parts_id = $id
	      UNION ALL
		SELECT 'rfq' AS module, p.partnumber, i.description,
		i.sellprice * o.exchangerate AS isellprice,
		v.name, o.quonumber AS trn, o.id, 'request_quotation' AS type,
		o.transdate
		FROM orderitems i
		JOIN parts p ON (p.id = i.parts_id)
		JOIN oe o ON (o.id = i.trans_id)
		JOIN vendor v ON (v.id = o.vendor_id)
		WHERE o.quotation = '1'
		AND i.parts_id = $id
		ORDER BY 1, transdate
		|;
  }

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_parts} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}


1;

