#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2009
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# module for reposting/deleting invoices
#
#======================================================================

package SM;


sub repost_invoices {
  my ($self, $myconfig, $form, $userspath) = @_;

  $myconfig->{numberformat} = '1000.00';
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query;
  my $sth;
  
  my $newform = new Form;
  my %default;

  # set up default AR account
  $query = qq|SELECT accno
              FROM chart
	      WHERE link = 'AR'
	      ORDER BY accno|;
  ($default{AR}) = $dbh->selectrow_array($query);
  if (! $default{AR}) {
    $dbh->disconnect;
    return -1;
  }
  $query = qq|SELECT accno
              FROM chart
	      WHERE link = 'AP'
	      ORDER BY accno|;
  ($default{AP}) = $dbh->selectrow_array($query);
  if (! $default{AP}) {
    $dbh->disconnect;
    return -2;
  }

  my $tid = time;

  $query = qq|CREATE TABLE invoice$tid
              AS SELECT i.* FROM invoice i, ar a
	      WHERE i.trans_id = a.id
	      AND a.transdate >= date '$form->{transdate}'|;
  $dbh->do($query) || &dberror($form, $query, $userspath);

  $query = qq|INSERT INTO invoice$tid
              SELECT i.* FROM invoice i, ap a
	      WHERE i.trans_id = a.id
	      AND a.transdate >= date '$form->{transdate}'|;
  $dbh->do($query) || &dberror($form, $query, $userspath);

  $query = qq|CREATE TABLE ar$tid
              AS SELECT * FROM ar
	      WHERE invoice = '1'
	      AND transdate >= date '$form->{transdate}'|;
  $dbh->do($query) || &dberror($form, $query, $userspath);
  
  $query = qq|CREATE TABLE ap$tid
              AS SELECT * FROM ap
	      WHERE invoice = '1'
	      AND transdate >= date '$form->{transdate}'|;
  $dbh->do($query) || &dberror($form, $query, $userspath);

  $query = qq|CREATE TABLE shipto$tid
              AS SELECT s.* FROM shipto s, ar$tid a
	      WHERE a.id = s.trans_id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);
  
  $query = qq|INSERT INTO shipto$tid
              SELECT s.* FROM shipto s, ap$tid a
	      WHERE a.id = s.trans_id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);

  $query = qq|CREATE TABLE cargo$tid
              AS SELECT c.* FROM cargo c, ar$tid a
	      WHERE a.id = c.trans_id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);
  
  $query = qq|INSERT INTO cargo$tid
              SELECT c.* FROM cargo c, ap$tid a
	      WHERE a.id = c.trans_id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);

  $query = qq|CREATE TABLE acc_trans$tid
              AS SELECT * FROM acc_trans
	      WHERE trans_id = 0|;
  $dbh->do($query) || &dberror($form, $query, $userspath);

  $query = qq|CREATE TABLE recurring$tid
              AS SELECT r.* FROM recurring r, ar$tid a
	      WHERE a.id = r.id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);
  
  $query = qq|INSERT INTO recurring$tid
              SELECT r.* FROM recurring r, ap$tid a
	      WHERE a.id = r.id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);

  $query = qq|CREATE TABLE recurringemail$tid
              AS SELECT r.* FROM recurringemail r, ar$tid a
	      WHERE a.id = r.id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);
  
  $query = qq|INSERT INTO recurringemail$tid
              SELECT r.* FROM recurringemail r, ap$tid a
	      WHERE a.id = r.id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);

  $query = qq|CREATE TABLE recurringprint$tid
              AS SELECT r.* FROM recurringprint r, ar$tid a
	      WHERE a.id = r.id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);
  
  $query = qq|INSERT INTO recurringprint$tid
              SELECT r.* FROM recurringprint r, ap$tid a
	      WHERE a.id = r.id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);

  $query = qq|CREATE TABLE payment$tid
              AS SELECT p.* FROM payment p, ar$tid a
	      WHERE a.id = p.trans_id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);
  
  $query = qq|INSERT INTO payment$tid
              SELECT p.* FROM payment p, ap$tid a
	      WHERE a.id = p.trans_id|;
  $dbh->do($query) || &dberror($form, $query, $userspath);

  $query = qq|SELECT p.id, p.obsolete
              FROM invoice i
	      JOIN parts p ON (p.id = i.trans_id)
	      WHERE p.id = ?|;
  my $pth = $dbh->prepare($query);

  $dbh->{AutoCommit} = 0;
  
  my $id;
  my %arap = ( ar => { link => AR, isir => IS, vc => customer },
               ap => { link => AP, isir => IR, vc => vendor }
	     );
  my $i;
  my $item;
  my $ref;
  my %obsolete;
  
  # delete invoices
  foreach $item (qw(ar ap)) {
    $query = qq|SELECT id FROM $item$tid
		ORDER BY transdate, id|;
    $sth = $dbh->prepare($query);
    $sth->execute || &dberror($form, $query, $userspath);

    while (($form->{id}) = $sth->fetchrow_array) {
      push @{ $arap{$item}{id} }, $form->{id};
      # save account links
      $query = qq|INSERT INTO acc_trans$tid
		  SELECT * FROM acc_trans
		  WHERE trans_id = $form->{id}|;
      $dbh->do($query) || &dberror($form, $query, $userspath);

      $pth->execute($form->{id});
      while ($ref = $pth->fetchrow_hashref(NAME_lc)) {
	$obsolete{$ref->{id}} = 1 if $ref->{obsolete};
      }
      $pth->finish;

      # reverse the invoice, keep exchangerate on file
      &{ "$arap{$item}{isir}::reverse_invoice" }($dbh, $form);

      # remove ar/ap record
      $query = qq|DELETE FROM $item
		  WHERE id = $form->{id}|;
      $dbh->do($query) || &dberror($form, $query, $userspath);
		  
      $dbh->commit;

    }
    $sth->finish;
  }

  # get defaultcurrency
  $query = qq|SELECT curr
              FROM curr
	      WHERE rn = 1|;
  ($default{defaultcurrency}) = $dbh->selectrow_array($query);

  foreach $item (qw(ar ap)) {
    foreach $id (@{ $arap{$item}{id} }) {

      # initialize $newform
      for (keys %$newform) { delete $newform->{$_} }

      # get ar and payment accounts
      $query = qq|SELECT c.accno FROM chart c
		  JOIN acc_trans$tid a ON (a.chart_id = c.id)
		  WHERE c.link = '$arap{$item}{link}'
		  AND a.trans_id = $id|;
      $sth = $dbh->prepare($query);
      $sth->execute || &dberror($form, $query, $userspath);

      ($form->{$arap{$item}{link}}) = $sth->fetchrow_array;
      $sth->finish;

      for (keys %default) { $newform->{$_} ||= $default{$_} }
      
      # get payment accounts
      $query = qq|SELECT c.accno, a.amount, a.transdate, a.source, a.memo,
		  p.exchangerate, p.paymentmethod_id
		  FROM acc_trans$tid a
		  JOIN chart c ON (a.chart_id = c.id)
		  JOIN payment$tid p ON (p.trans_id = a.trans_id)
		  WHERE c.link like '%$arap{$item}{link}_paid%'
		  AND NOT a.fx_transaction
		  AND a.trans_id = $id|;
      $sth = $dbh->prepare($query);
      $sth->execute || &dberror($form, $query, $userspath);
      
      $i = 0;
      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	$i++;
	$newform->{"$arap{$item}{link}_paid_$i"} = $ref->{accno};
	$newform->{"paid_$i"} = $ref->{amount} * -1;
	$newform->{"datepaid_$i"} = $newform->{"olddatepaid_$i"} = $ref->{transdate};

	for (qw(source memo cleared vr_id exchangerate)) { $newform->{"${_}_$i"} = $ref->{$_} }
	$newform->{paymentmethod} = "--$ref->{paymentmethod_id}";
      }
      $sth->finish;
      $newform->{paidaccounts} = $i + 1;
      
      # get ar/ap entry
      $query = qq|SELECT a.invnumber, a.transdate, a.transdate AS invdate,
		  a.$arap{$item}{vc}_id, a.taxincluded, a.duedate, a.invoice,
		  a.shippingpoint, a.terms, a.notes, a.curr AS currency,
		  a.ordnumber, a.employee_id, a.quonumber, a.intnotes,
		  a.department_id, a.shipvia, a.till, a.language_code,
		  a.ponumber, a.approved, a.cashdiscount, a.discountterms,
		  a.waybill,
		  a.warehouse_id, a.description, a.onhold, a.exchangerate,
		  a.dcn, a.bank_id, a.paymentmethod_id,
		  ct.name AS $arap{$item}{vc}, ad.address1, ad.address2,
		  ad.city, ad.state, ad.zipcode, ad.country,
		  ct.contact, ct.phone, ct.fax, ct.email,
		  e.login
		  FROM $item$tid a
		  JOIN $arap{$item}{vc} ct ON (a.$arap{$item}{vc}_id = ct.id)
		  JOIN address ad ON (ad.trans_id = ct.id)
		  LEFT JOIN employee e ON (a.employee_id = e.id)
		  WHERE a.id = $id|;
      $sth = $dbh->prepare($query);
      $sth->execute || &dberror($form, $query, $userspath);

      $ref = $sth->fetchrow_hashref(NAME_lc);
      for (keys %$ref) { $newform->{$_} = $ref->{$_} }
      $sth->finish;

      # get name and tax accounts for customer/vendor
      $query = qq|SELECT c.accno, t.rate
		  FROM chart c
		  JOIN $arap{$item}{vc}tax ct ON (ct.chart_id = c.id)
		  JOIN tax t ON (t.chart_id = c.id)
		  WHERE ct.$arap{$item}{vc}_id = $newform->{"$arap{$item}{vc}_id"}|;
      $sth = $dbh->prepare($query);
      $sth->execute || &dberror($form, $query, $userspath);

      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	$newform->{taxaccounts} .= "$ref->{accno} ";
	$newform->{"$ref->{accno}_rate"} = $ref->{rate};
      }
      chop $newform->{taxaccounts};
      $sth->finish;
      
      # get shipto
      $query = qq|SELECT shiptoname, shiptoaddress1, shiptoaddress2,
		  shiptocity, shiptostate, shiptozipcode, shiptocountry,
		  shiptocontact, shiptophone, shiptofax, shiptoemail
		  FROM shipto$tid
		  WHERE trans_id = $id|;
      $sth = $dbh->prepare($query);
      $sth->execute || &dberror($form, $query, $userspath);
      
      $ref = $sth->fetchrow_hashref(NAME_lc);
      for (keys %$ref) { $newform->{$_} = $ref->{$_} }
      $sth->finish;
      
      # get individual items
      $query = qq|SELECT i.id, i.parts_id, i.description, i.qty,
		  i.fxsellprice AS sellprice, i.discount, i.unit,
		  i.project_id, i.deliverydate,
		  i.serialnumber, i.itemnotes, i.lineitemdetail,
		  i.ordernumber, i.ponumber
		  FROM invoice$tid i
		  WHERE NOT i.assemblyitem
		  AND i.trans_id = $id|;
      $sth = $dbh->prepare($query);
      $sth->execute || &dberror($form, $query, $userspath);
      
      $i = 0;
      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

	# get tax accounts for part
	$query = qq|SELECT c.accno
		    FROM chart c
		    JOIN partstax pt ON (c.id = pt.chart_id)
		    WHERE pt.parts_id = $ref->{id}|;
	$pth = $dbh->prepare($query);
	$pth->execute || &dberror($form, $query, $userspath);
	while (($accno) = $pth->fetchrow_array) {
	  $ref->{taxaccounts} .= "$accno ";
	}
	chop $ref->{taxaccounts};
	$pth->finish;

	$i++;
	$ref->{discount} *= 100;

	for (keys %$ref) { $newform->{"${_}_$i"} = $ref->{$_} }
	
	$newform->{"id_$i"} = $ref->{parts_id};
	
	# get cargo information
	$query = qq|SELECT * FROM cargo$tid
		    WHERE trans_id = $id
		    AND id = $ref->{id}|;
	($newform->{"package_$i"}, $newform->{"netweight_$i"}, $newform->{"grossweight_$i"}, $newform->{"volume_$i"}) = $dbh->selectrow_array($query);

      }
      $newform->{rowcount} = $i + 1;
      
      $sth->finish;

      # post a new invoice
      for (qw(employee department warehouse)) { $newform->{$_} = qq|--$newform->{"${_}_id"}| }
      $newform->{type} = "invoice";
      
      &{ "$arap{$item}{isir}::post_invoice" }("", $myconfig, $newform, $dbh);

      print " $newform->{invnumber}";
      
      # insert recurring from recurring$tid
      for (qw(recurring recurringemail recurringprint)) {
	$query = qq|INSERT INTO $_
		    SELECT *
		    FROM $_$tid
		    WHERE id = $id|;
	$dbh->do($query) || &dberror($form, $query, $userspath);

	$query = qq|UPDATE $_
		    SET id = $newform->{id}
		    WHERE id = $id|;
	$dbh->do($query) || &dberror($form, $query, $userspath);
	
      }

      $dbh->commit;

    }
  }

  $query = qq|SELECT onhand
              FROM parts
	      WHERE id = ?|;
  $pth = $dbh->prepare($query) || &dberror($form, $query, $userspath);

  $query = qq|UPDATE parts SET
              obsolete = 1
	      WHERE id = ?|;
  $sth = $dbh->prepare($query) || &dberror($form, $query, $userspath);

  my $onhand;
  foreach $item (keys %obsolete) {
    $pth->execute($item);
    ($onhand) = $pth->fetchrow_array;
    $pth->finish;

    if (!$onhand) {
      $sth->execute($item);
      $sth->finish;
    }
  }

  for (qw(invoice ar ap shipto cargo acc_trans recurring recurringemail recurringprint payment)) {
    $query = qq|DROP TABLE $_$tid|;
    $dbh->do($query) || &dberror($form, $query, $userspath);
  }

  $dbh->commit;
  $dbh->disconnect;

}


sub dberror {
  my ($form, $query, $userspath) = @_;

  unlink "$userspath/nologin.LCK";
  $form->dberror($query);

}

1;

