#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# AR/AP backend routines
# common routines
#
#======================================================================

package AA;


sub post_transaction {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;
  
  # connect to database
  $dbh = $form->dbconnect_noauto($myconfig) unless $dbh;

  my $query;
  my $sth;

  my $null;
  ($null, $form->{department_id}) = split(/--/, $form->{department});
  $form->{department_id} *= 1;
  
  my %defaults = $form->get_defaults($dbh, \@{['fx%accno_id', 'cdt', 'precision']});
  $form->{precision} = $defaults{precision};

  my $ml = 1;
  my $arapml = ($form->{type} =~ /_note/) ? -1 : 1;
  my $table = 'ar';
  my $ARAP = 'AR';
  my $invnumber = "sinumber";
  my $keepcleared = ($form->{id}) ? 1 : 0;
  
  my $approved = ($form->{pending}) ? '0' : '1';
  my $action = ($approved) ? 'posted' : 'saved';

  if ($form->{vc} eq 'vendor') {
    $table = 'ap';
    $ARAP = 'AP';
    $ml = -1;
    $invnumber = "vinumber";
  }

  $form->{exchangerate} = $form->parse_amount($myconfig, $form->{exchangerate});
  $form->{exchangerate} ||= 1;

  my @taxaccounts = split / /, $form->{taxaccounts};
  my $tax = 0;
  my $fxtax = 0;
  my $amount;
  my $fxamount;
  my $diff;
  
  my %tax = ();
  my $accno;

  # add taxes
  foreach $accno (@taxaccounts) {
    $fxtax += $tax{fxamount}{$accno} = $form->parse_amount($myconfig, $form->{"tax_$accno"});
    $tax += $tax{fxamount}{$accno};
    
    push @{ $form->{acc_trans}{taxes} }, {
      accno => $accno,
      amount => $tax{fxamount}{$accno},
      transdate => $form->{transdate},
      fx_transaction => 0 };
      
    $amount = $tax{fxamount}{$accno} * $form->{exchangerate};
    $tax{amount}{$accno} = $form->round_amount($amount - $diff, $form->{precision});
    $diff = $tax{amount}{$accno} - ($amount - $diff);
    $amount = $tax{amount}{$accno} - $tax{fxamount}{$accno};
    $tax += $amount;

    if ($form->{currency} ne $form->{defaultcurrency}) {
      push @{ $form->{acc_trans}{taxes} }, {
	accno => $accno,
	amount => $amount,
	transdate => $form->{transdate},
	fx_transaction => 1 };
    }

  }

  my %amount = ();
  my $fxinvamount = 0;
  for (1 .. $form->{rowcount}) {
    $fxinvamount += $amount{fxamount}{$_} = $form->parse_amount($myconfig, $form->{"amount_$_"});
  }

  for (qw(taxincluded onhold)) { $form->{$_} *= 1 }
  
  my $i;
  my $project_id;
  my $cleared = 'NULL';
  
  $diff = 0;
  $fxdiff = 0;
  $invnetamount = 0;
  $fxinvnetamount = 0;
  
  # deduct tax from amounts if tax included
  for $i (1 .. $form->{rowcount}) {

    if ($amount{fxamount}{$i}) {
      
      if ($form->{taxincluded}) {
	$amount = ($fxinvamount) ? $fxtax * $amount{fxamount}{$i} / $fxinvamount : 0;
	$taxamount = $form->round_amount($amount - $fxdiff, $form->{precision});
	$amount{fxamount}{$i} -= $taxamount;
	$fxdiff = $form->round_amount($taxamount - ($amount - $fxdiff), 10);
      }
	
      # multiply by exchangerate
      $amount = $amount{fxamount}{$i} * $form->{exchangerate};
      $amount{amount}{$i} = $form->round_amount($amount - $diff, $form->{precision});
      $diff = $amount{amount}{$i} - ($amount - $diff);
      
      ($null, $project_id) = split /--/, $form->{"projectnumber_$i"};
      $project_id ||= 'NULL';
      ($accno) = split /--/, $form->{"${ARAP}_amount_$i"};

      if ($keepcleared) {
	$cleared = $form->dbquote($form->{"cleared_$i"}, SQL_DATE);
      }

      push @{ $form->{acc_trans}{lineitems} }, {
	accno => $accno,
	amount => $amount{fxamount}{$i},
	project_id => $project_id,
	description => $form->{"description_$i"},
	cleared => $cleared,
	fx_transaction => 0,
	id => $i };

      if ($form->{currency} ne $form->{defaultcurrency}) {
	$amount = $amount{amount}{$i} - $amount{fxamount}{$i};
	push @{ $form->{acc_trans}{lineitems} }, {
	  accno => $accno,
	  amount => $amount,
	  project_id => $project_id,
	  description => $form->{"description_$i"},
	  cleared => $cleared,
	  fx_transaction => 1,
	  id => $i };
      }

      $invnetamount += $amount{amount}{$i};
      $fxinvnetamount += $amount{fxamount}{$i};
      
    }
  }


  my $invamount = $invnetamount + $tax;
  
  my $paymentaccno;
  my $paymentmethod_id;

  my $paid = 0;

  $diff = 0;
  # add payments
  for $i (1 .. $form->{paidaccounts}) {
    $fxamount = $form->parse_amount($myconfig, $form->{"paid_$i"});
    
    if ($fxamount) {
      $paid += $fxamount;

      $paidamount = $fxamount * $form->{exchangerate};
      
      $amount = $form->round_amount($paidamount - $diff, $form->{precision});
      $diff = $amount - ($paidamount - $diff);
      
      $form->{datepaid} = $form->{"datepaid_$i"};
      
      $paid{fxamount}{$i} = $fxamount;
      $paid{amount}{$i} = $amount;
    }
  }
  
  $fxinvamount += $fxtax unless $form->{taxincluded};
  $fxinvamount = $form->round_amount($fxinvamount, $form->{precision});
  $invamount = $form->round_amount($invamount, $form->{precision});
  $paid = $form->round_amount($paid, $form->{precision});
  
  $paid = ($fxinvamount == $paid) ? $invamount : $form->round_amount($paid * $form->{exchangerate}, $form->{precision});
  
  ($null, $form->{employee_id}) = split /--/, $form->{employee};
  unless ($form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh); 
  }
  
  my $vth;
  
  # check if id really exists
  if ($form->{id}) {
    $query = qq|SELECT id
                FROM $table
 	        WHERE id = $form->{id}|;
    ($form->{id}) = $dbh->selectrow_array($query);

    &reverse_vouchers($dbh, $form);

    if ($form->{id}) {
      # delete detail records
      for (qw(acc_trans dpt_trans payment reference)) {
	$query = qq|DELETE FROM $_ WHERE trans_id = $form->{id}|;
	$dbh->do($query) || $form->dberror($query);
      }
    }
  }
  
  if (! $form->{id}) {
  
    my $uid = localtime;
    $uid .= $$;

    $query = qq|INSERT INTO $table (invnumber, approved)
                VALUES ('$uid', '$approved')|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM $table
                WHERE invnumber = '$uid'|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }

  if ($form->{department_id}) {
    $query = qq|INSERT INTO dpt_trans (trans_id, department_id)
                VALUES ($form->{id}, $form->{department_id})|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  # record last payment date in ar/ap table
  $form->{datepaid} ||= $form->{transdate};
  my $datepaid = ($paid) ? qq|'$form->{datepaid}'| : 'NULL';

  $form->{invnumber} = $form->update_defaults($myconfig, $invnumber) unless $form->{invnumber};
  $form->{duedate} ||= $form->{transdate};

  for (qw(terms discountterms)) { $form->{$_} *= 1 }

  $form->{cashdiscount} = $form->parse_amount($myconfig, $form->{cashdiscount}) / 100;


  $form->{amount} = $invamount;          # need for vr batch
  
  ($paymentaccno) = split /--/, $form->{"${ARAP}_paid_$form->{paidaccounts}"};
  ($null, $paymentmethod_id) = split /--/, $form->{"paymentmethod_$form->{paidaccounts}"};
  $paymentmethod_id *= 1;

  if ($form->{vc} eq 'customer') {
    # dcn
    ($form->{integer_amount}, $form->{decimal}) = split /\./, $fxinvamount;
    $form->{decimal} = substr("$form->{decimal}00", 0, 2);

    $query = qq|SELECT bk.membernumber, bk.dcn, bk.rvc
		FROM bank bk
		JOIN chart c ON (c.id = bk.id)
		WHERE c.accno = '$paymentaccno'|;
    ($form->{membernumber}, $form->{dcn}, $form->{rvc}) = $dbh->selectrow_array($query);
    
    for my $dcn (qw(dcn rvc)) { $form->{$dcn} = $form->format_dcn($form->{$dcn}) }
  }

  $query = qq|UPDATE $table SET
	      invnumber = |.$dbh->quote($form->{invnumber}).qq|,
	      description = |.$dbh->quote($form->{description}).qq|,
	      ordnumber = |.$dbh->quote($form->{ordnumber}).qq|,
	      transdate = '$form->{transdate}',
	      $form->{vc}_id = $form->{"$form->{vc}_id"},
	      taxincluded = '$form->{taxincluded}',
	      amount = $invamount * $arapml,
	      duedate = '$form->{duedate}',
	      paid = $paid * $arapml,
	      datepaid = $datepaid,
	      netamount = $invnetamount * $arapml,
	      terms = $form->{terms},
	      curr = '$form->{currency}',
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      department_id = $form->{department_id},
	      employee_id = $form->{employee_id},
	      ponumber = |.$dbh->quote($form->{ponumber}).qq|,
	      cashdiscount = $form->{cashdiscount},
	      discountterms = $form->{discountterms},
	      onhold = '$form->{onhold}',
	      exchangerate = $form->{exchangerate},
	      dcn = |.$dbh->quote($form->{dcn}).qq|,
	      bank_id = (SELECT id FROM chart WHERE accno = '$paymentaccno'),
	      paymentmethod_id = $paymentmethod_id
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # add voucher
  if ($form->{batchid}) {
    $form->{voucher}{transaction}{vouchernumber} = $form->update_defaults($myconfig, 'vouchernumber', $dbh) unless $form->{voucher}{transaction}{vouchernumber};

    $query = qq|INSERT INTO vr (br_id, trans_id, id, vouchernumber)
                VALUES ($form->{batchid}, $form->{id}, $form->{id}, |
		.$dbh->quote($form->{voucher}{transaction}{vouchernumber}).qq|)|;
    $dbh->do($query) || $form->dberror($query);

    # update batch
    $form->update_balance($dbh,
                          'br',
			  'amount',
			  qq|id = $form->{batchid}|,
			  $invamount * $arapml);
  }

  # update exchangerate
  $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, $form->{exchangerate});

  my $ref;
  
  # add individual transactions
  foreach $ref (@{ $form->{acc_trans}{lineitems} }) {

    # insert detail records in acc_trans
    $ref->{amount} = $form->round_amount($ref->{amount}, $form->{precision});
    if ($ref->{amount}) {
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
		  project_id, memo, fx_transaction, cleared, approved, id)
		  VALUES ($form->{id}, (SELECT id FROM chart
					WHERE accno = '$ref->{accno}'),
		  $ref->{amount} * $ml * $arapml, '$form->{transdate}',
		  $ref->{project_id}, |.$dbh->quote($ref->{description}).qq|,
		  '$ref->{fx_transaction}', $ref->{cleared}, '$approved',
		  $ref->{id})|;
      $dbh->do($query) || $form->dberror($query);
    }
  }

  # save taxes
  foreach $ref (@{ $form->{acc_trans}{taxes} }) {
    $ref->{amount} = $form->round_amount($ref->{amount}, $form->{precision});
    if ($ref->{amount}) {
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		  transdate, fx_transaction, approved)
		  VALUES ($form->{id},
			 (SELECT id FROM chart
			  WHERE accno = '$ref->{accno}'),
		  $ref->{amount} * $ml * $arapml, '$ref->{transdate}',
		  '$ref->{fx_transaction}', '$approved')|;
      $dbh->do($query) || $form->dberror($query);
    }
  }


  my $arap;
  
  # record ar/ap
  if (($arap = $invamount)) {
    ($accno) = split /--/, $form->{$ARAP};
    
    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
                approved)
		VALUES ($form->{id},
		       (SELECT id FROM chart
			WHERE accno = '$accno'),
		$invamount * -1 * $ml * $arapml, '$form->{transdate}', '$approved')|;
    $dbh->do($query) || $form->dberror($query);
  }

  # if there is no amount force ar/ap
  if ($fxinvamount == 0) {
    $arap = 1;
  }

  my $voucherid;
  my $apprpaid = $approved;
  my $paymentid = 1;

 
  # add paid transactions
  for $i (1 .. $form->{paidaccounts}) {
    
    $approved = $apprpaid;
    
    if ($paid{fxamount}{$i}) {
      
      ($accno) = split(/--/, $form->{"${ARAP}_paid_$i"});
      $form->{"datepaid_$i"} = $form->{transdate} unless ($form->{"datepaid_$i"});
      $form->{"exchangerate_$i"} = $form->parse_amount($myconfig, $form->{"exchangerate_$i"});
      $form->{"exchangerate_$i"} ||= 1;
     
      # if there is no amount
      if ($fxinvamount == 0) {
	$form->{exchangerate} = $form->{"exchangerate_$i"};
      }

      
      $voucherid = 'NULL';
      
      # add voucher for payment
      if ($form->{voucher}{payment}{$voucherid}{br_id}) {
	if ($form->{"vr_id_$i"}) {

	  $voucherid = $form->{"vr_id_$i"};
	  $approved = $form->{voucher}{payment}{$voucherid}{approved} * 1;
	  
	  $query = qq|INSERT INTO vr (br_id, trans_id, id, vouchernumber)
		      VALUES ($form->{voucher}{payment}{$voucherid}{br_id},
		      $form->{id}, $voucherid, |.
		      $dbh->quote($form->{voucher}{payment}{$voucherid}{vouchernumber}).qq|)|;
	  $dbh->do($query) || $form->dberror($query);

	  # update batch
	  $form->update_balance($dbh,
				'br',
				'amount',
				qq|id = $form->{voucher}{payment}{$voucherid}{br_id}|,
				$paid{amount}{$i} * $arapml);
	}
      }


      # ar/ap amount
      if ($arap) {
        ($accno) = split /--/, $form->{$ARAP};

	# add ar/ap
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate, approved, vr_id)
		    VALUES ($form->{id},
		           (SELECT id FROM chart
			    WHERE accno = '$accno'),
		    $paid{amount}{$i} * $ml * $arapml, '$form->{"datepaid_$i"}',
		    '$approved', $voucherid)|;
	$dbh->do($query) || $form->dberror($query);

      }
      $arap = $paid{amount}{$i};
      
      
      # add payment
      ($accno) = split /--/, $form->{"${ARAP}_paid_$i"};
      
      ($null, $paymentmethod_id) = split /--/, $form->{"paymentmethod_$i"};
      $paymentmethod_id *= 1;
     
      if ($keepcleared) {
	$cleared = $form->dbquote($form->{"cleared_$i"}, SQL_DATE);
      }
      
      $amount = $paid{fxamount}{$i};
      
      if ($amount) {
	# add payment
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate, source, memo, cleared, approved, vr_id, id)
		    VALUES ($form->{id},
			   (SELECT id FROM chart
			    WHERE accno = '$accno'),
		    $amount * -1 * $ml * $arapml, '$form->{"datepaid_$i"}', |
		    .$dbh->quote($form->{"source_$i"}).qq|, |
		    .$dbh->quote($form->{"memo_$i"}).qq|,
		    $cleared, '$approved', $voucherid, $paymentid)|;
	$dbh->do($query) || $form->dberror($query);

	$query = qq|INSERT INTO payment (id, trans_id, exchangerate,
	            paymentmethod_id)
		    VALUES ($paymentid, $form->{id}, $form->{"exchangerate_$i"},
		    $paymentmethod_id)|;
	$dbh->do($query) || $form->dberror($query);

	$paymentid++;


	if ($form->{currency} ne $form->{defaultcurrency}) {
	  
	  # exchangerate gain/loss
	  $amount = $form->round_amount(($form->round_amount($paid{fxamount}{$i} * $form->{exchangerate}, $form->{precision}) - $form->round_amount($paid{fxamount}{$i} * $form->{"exchangerate_$i"}, $form->{precision})) * -1, $form->{precision});
	  
	  if ($amount) {
	    my $accno_id = (($amount * $ml * $arapml) > 0) ? $defaults{fxgain_accno_id} : $defaults{fxloss_accno_id};
	    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
			transdate, fx_transaction, cleared, approved, vr_id)
			VALUES ($form->{id}, $accno_id,
			$amount * $ml * $arapml, '$form->{"datepaid_$i"}', '1',
			$cleared, '$approved', $voucherid)|;
	    $dbh->do($query) || $form->dberror($query);
	  }

	  # exchangerate difference
	  $amount = $form->round_amount($paid{amount}{$i} - $paid{fxamount}{$i} + $amount, $form->{precision});
	  if ($amount) {
	    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
			transdate, fx_transaction, cleared, source, approved, vr_id)
			VALUES ($form->{id},
			       (SELECT id FROM chart
				WHERE accno = '$accno'),
			$amount * -1 * $ml * $arapml, '$form->{"datepaid_$i"}', '1',
			$cleared, |
			.$dbh->quote($form->{"source_$i"}).qq|, '$approved',
			$voucherid)|;
	    $dbh->do($query) || $form->dberror($query);
	  }

	}
      }
    }
  }

  # save taxes for discount
  if (@cdt) {
    $i = $form->{discount_index};
    $voucherid = 'NULL';
    $approved = $apprpaid;
    
    if ($form->{voucher}{payment}{$voucherid}{br_id}) {
      if ($form->{"vr_id_$i"}) {
	$voucherid = $form->{"vr_id_$i"};
	$approved = $form->{voucher}{payment}{$voucherid}{approved} * 1;
      }
    }
	
    foreach $ref (@cdt) {
      $ref->{amount} = $form->round_amount($ref->{amount}, $form->{precision});
      if ($ref->{amount}) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate, fx_transaction, approved, vr_id, id)
		    VALUES ($form->{id},
			   (SELECT id FROM chart
			    WHERE accno = '$ref->{accno}'),
		    $ref->{amount} * $ml * $arapml, '$ref->{transdate}',
		    '$ref->{fx_transaction}', '$approved', $voucherid,
		    $paymentid)|;
	$dbh->do($query) || $form->dberror($query);
      }
    }
  }

  # save printed and queued
  $form->save_status($dbh);

  # save reference documents
  $form->save_reference($dbh);
  
  my %audittrail = ( tablename  => $table,
                     reference  => $form->{invnumber},
		     formname   => 'transaction',
		     action     => $action,
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);

  $form->save_recurring($dbh, $myconfig);

  $form->remove_locks($myconfig, $dbh, $table);
  
  my $rc;
  
  if ($disconnect) {
    $rc = $dbh->commit;
    $dbh->disconnect;
  }

  $rc;
  
}


sub reverse_vouchers {
  my ($dbh, $form) = @_;

  my $amount;
  my $table = 'ap';
  my $ARAP = 'AP';
  my $ml = 1;
  
  if ($form->{vc} eq 'customer') {
    $table = 'ar';
    $ARAP = 'AR';
    $ml = -1;
  }
  
  my $query = qq|SELECT vr.*, a.amount
                 FROM $table a
		 JOIN vr ON (vr.trans_id = a.id)
 	         WHERE vr.id = $form->{id}|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute || $form->dberror($query);
  my $ref = $sth->fetchrow_hashref(NAME_lc);
  $form->{voucher}{transaction} = $ref;
  $sth->finish;

  if ($form->{batchid}) {
    $form->update_balance($dbh,
			  'br',
			  'amount',
			  qq|id = $form->{batchid}|,
			  $form->{voucher}{transaction}{amount} * -1);
    
    # get batchid's and vouchers for payments
    $query = qq|SELECT * FROM vr
		WHERE trans_id = $form->{id}
		AND NOT br_id = $form->{batchid}|;
    $sth = $dbh->prepare($query) || $form->dberror($query);

    $query = qq|SELECT SUM(ac.amount), ac.approved
		FROM acc_trans ac
		JOIN vr ON (vr.id = ac.vr_id)
		JOIN chart c ON (c.id = ac.chart_id)
		WHERE ac.trans_id = $form->{id}
		AND vr.id = ?
		AND (c.link LIKE '%${ARAP}_paid%'
		     OR c.link LIKE '%${ARAP}_discount%')
		GROUP BY ac.approved|;
    my $ath = $dbh->prepare($query) || $form->dberror($query);
		
    $sth->execute || $form->dberror($query);
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      
      $form->{voucher}{payment}{$ref->{id}} = $ref;

      # get amount
      $ath->execute($ref->{id});
      ($amount) = $ath->fetchrow_array;
      $ath->finish;

      $amount = $form->round_amount($amount, $form->{precision});
      # update batch
      $form->update_balance($dbh,
			    'br',
			    'amount',
			    qq|id = $ref->{br_id}|,
			    $amount * $ml * -1);
    }
    $sth->finish;
  }

  $query = qq|DELETE FROM vr
	      WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

}



sub delete_transaction {
  my ($self, $myconfig, $form, $dbh) = @_;

  my $disconnect = ($dbh) ? 0 : 1;
  
  # connect to database, turn AutoCommit off
  $dbh = $form->dbconnect_noauto($myconfig) unless $dbh;
  
  my $table = ($form->{vc} eq 'customer') ? 'ar' : 'ap';
  
  my %audittrail = ( tablename  => $table,
                     reference  => $form->{invnumber},
		     formname   => 'transaction',
		     action     => 'deleted',
		     id         => $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);
  
  &reverse_vouchers($dbh, $form);
  
  $query = qq|DELETE FROM $table WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|SELECT glid FROM pay_trans
              WHERE trans_id = $form->{id}|;
  ($form->{glid}) = $dbh->selectrow_array($query);

  my $id;
  for $id (qw(id glid)) {
    for (qw(acc_trans dpt_trans payment status pay_trans reference)) {
      if ($form->{$id}) {
	$query = qq|DELETE FROM $_ WHERE trans_id = $form->{$id}|;
	$dbh->do($query) || $form->dberror($query);
      }
    }
    for (qw(recurring recurringemail recurringprint)) {
      if ($form->{$id}) {
	$query = qq|DELETE FROM $_ WHERE id = $form->{$id}|;
	$dbh->do($query) || $form->dberror($query);
      }
    }
  }
  
  $form->remove_locks($myconfig, $dbh, $table);
 
  # commit
  my $rc;
  
  if ($disconnect) {
    $rc = $dbh->commit;
    $dbh->disconnect;
  }

  $rc;

}



sub transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $null;
  my $var;
  my $paid = "a.paid";
  my $ml = 1;
  my $ARAP = 'AR';
  my $table = 'ar';
  my $acc_trans_join;
  my $acc_trans_flds;
  
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  if ($form->{vc} eq 'vendor') {
    $ml = -1;
    $ARAP = 'AP';
    $table = 'ap';
  }
  
  ($form->{transdatefrom}, $form->{transdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
 
  if ($form->{outstanding}) {
    $paid = qq|SELECT SUM(ac.amount) * -1 * $ml
               FROM acc_trans ac
	       JOIN chart c ON (c.id = ac.chart_id)
	       WHERE ac.trans_id = a.id
	       AND ac.approved = '1'
	       AND (c.link LIKE '%${ARAP}_paid%'
	            OR c.link LIKE '%${ARAP}_discount%'
		    OR c.link = '')|;
    $paid .= qq|
               AND ac.transdate <= '$form->{transdateto}'| if $form->{transdateto};
    $form->{summary} = 1;
    $form->{l_memo} = "";
  }

  my $taxfld = qq|SELECT sum(ac.amount)
		  FROM acc_trans ac
		  JOIN chart c ON (c.id = ac.chart_id)
		  WHERE ac.trans_id = a.id
		  AND ac.approved = '1'
		  AND c.link LIKE '%_tax%'|;
  $taxfld .= qq|
               AND ac.transdate <= '$form->{transdateto}'| if $form->{transdateto};
  
  if (!$form->{summary} || $form->{l_memo}) {
    $acc_trans_flds = qq|, c.accno, ac.source,
			 pr.projectnumber, ac.memo,
			 ac.amount AS linetotal,
			 i.description AS linedescription, ac.fx_transaction|;

    $acc_trans_join = qq|
	    JOIN acc_trans ac ON (a.id = ac.trans_id)
	    JOIN chart c ON (c.id = ac.chart_id)
	    LEFT JOIN project pr ON (pr.id = ac.project_id)
	    LEFT JOIN invoice i ON (i.id = ac.id|;
    $acc_trans_join .= qq| AND i.trans_id = a.id| if $form->{summary};
    $acc_trans_join .= qq|)|;
  }
    
  my $query = qq|SELECT a.id, a.invnumber, a.ordnumber, a.transdate,
                 a.duedate, ($taxfld) * $ml AS tax,
		 a.amount, ($paid) AS paid,
		 a.invoice, a.datepaid, a.terms, a.notes,
		 a.shipvia, a.waybill, a.shippingpoint,
		 e.name AS employee, vc.name, vc.$form->{vc}number,
		 a.$form->{vc}_id, a.till, a.curr,
		 a.exchangerate, d.description AS department,
		 a.ponumber, a.warehouse_id, w.description AS warehouse,
		 a.description, a.dcn, pm.description AS paymentmethod,
		 a.datepaid - a.duedate AS paymentdiff,
		 ad.address1, ad.address2, ad.city, ad.zipcode, ad.country
		 $acc_trans_flds
	         FROM $table a
	      JOIN $form->{vc} vc ON (a.$form->{vc}_id = vc.id)
	      JOIN address ad ON (ad.trans_id = vc.id)
	      LEFT JOIN employee e ON (a.employee_id = e.id)
	      LEFT JOIN department d ON (a.department_id = d.id)
	      LEFT JOIN warehouse w ON (a.warehouse_id = w.id)
	      LEFT JOIN paymentmethod pm ON (pm.id = a.paymentmethod_id)
	      $acc_trans_join
	      |;

  my $where = "a.approved = '1'";

  if ($form->{"$form->{vc}_id"}) {
    $where .= qq| AND a.$form->{vc}_id = $form->{"$form->{vc}_id"}|;
  } else {
    if ($form->{$form->{vc}}) {
      $var = $form->like(lc $form->{$form->{vc}});
      $where .= " AND lower(vc.name) LIKE '$var'";
    }
    if ($form->{"$form->{vc}number"}) {
      $var = $form->like(lc $form->{"$form->{vc}number"});
      $where .= " AND lower(vc.$form->{vc}number) LIKE '$var'";
    }
  }
  for (qw(warehouse department employee)) {
    if ($form->{$_}) {
      ($null, $var) = split /--/, $form->{$_};
      $where .= " AND a.${_}_id = $var";
    }
  }

  for (qw(invnumber ordnumber)) {
    if ($form->{$_}) {
      $var = $form->like(lc $form->{$_});
      $where .= " AND lower(a.$_) LIKE '$var'";
    }
  }
  for (qw(ponumber shipvia shippingpoint waybill notes description)) {
    if ($form->{$_}) {
      $var = $form->like(lc $form->{$_});
      $where .= " AND lower(a.$_) LIKE '$var'";
    }
  }
  if ($form->{memo}) {
    if ($acc_trans_flds) {
      $var = $form->like(lc $form->{memo});
      $where .= " AND lower(ac.memo) LIKE '$var'
		  OR lower(i.description) LIKE '$var'";
    } else {
      $where .= " AND a.id = 0";
    }
  }
  if ($form->{source}) {
    if ($acc_trans_flds) {
      $var = $form->like(lc $form->{source});
      $where .= " AND lower(ac.source) LIKE '$var'";
    } else {
      $where .= " AND a.id = 0";
    }
  }

  $where .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
  $where .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};

  if ($form->{paidlate} || $form->{paidearly}) {
    $form->{open} = 0;
    $form->{closed} = 1;
    if ($form->{paidlate}) {
      $where .= " AND a.datepaid > a.duedate" unless $form->{paidearly};
    }
    if ($form->{paidearly}) {
      $where .= " AND a.datepaid <= a.duedate" unless $form->{paidlate};
    }
  }

  if ($form->{onhold}) {
    $where .= " AND a.onhold = '1'";
  }

  if ($form->{open} || $form->{closed}) {
    if ($form->{open}) {
      $where .= " AND a.amount != a.paid" unless $form->{closed};
    }
    if ($form->{closed}) {
      $where .= " AND a.amount = a.paid" unless $form->{open};
    }
  }

  if ($form->{till} ne "") {
    $where .= " AND a.invoice = '1'
                AND a.till IS NOT NULL";
  }

  if ($form->{$ARAP}) {
    my ($accno) = split /--/, $form->{$ARAP};
    $where .= qq|
                AND a.id IN (SELECT ac.trans_id
		             FROM acc_trans ac
			     JOIN chart c ON (c.id = ac.chart_id)
			     WHERE a.id = ac.trans_id
			     AND c.accno = '$accno')
		|;
  }
  
  if ($form->{memo}) {
    $var = $form->like(lc $form->{memo});
    $where .= qq| AND (a.id IN (SELECT DISTINCT trans_id
                                FROM acc_trans
				WHERE lower(memo) LIKE '$var')
		       OR a.id IN (SELECT DISTINCT trans_id
		                FROM invoice
				WHERE lower(description) LIKE '$var'))|;
  }

  $query .= " WHERE $where";

  my @sf = (transdate, invnumber, name);
  push @sf, "employee" if $form->{l_employee};
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $i = -1;
  my $sameid;
 
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{exchangerate} ||= 1;
    if ($ref->{linetotal} <= 0) {
      $ref->{debit} = $ref->{linetotal} * -1;
      $ref->{credit} = 0;
    } else {
      $ref->{debit} = 0;
      $ref->{credit} = $ref->{linetotal};
    }

    if ($ref->{invoice}) {
      $ref->{memo} ||= $ref->{linedescription};
    }

    $ref->{netamount} = $ref->{amount} - $ref->{tax};

    if ($form->{outstanding}) {
      next if $form->round_amount($ref->{amount}, $form->{precision}) == $form->round_amount($ref->{paid}, $form->{precision});
    }

    for (qw(address1 address2 city zipcode country)) { $ref->{address} .= "$ref->{$_} " }
    
    if ($form->{summary}) {
      if ($sameid != $ref->{id}) {
	$i++;
	push @{ $form->{transactions} }, $ref;
      } else {
        if ($ref->{memo} && ! $ref->{fx_transaction}) {
	  if ($form->{transactions}[$i]->{memo}) {
	    $form->{transactions}[$i]->{memo} .= "\n";
	  }
	  $form->{transactions}[$i]->{memo} .= $ref->{memo};
	}
      }
    } else {
      push @{ $form->{transactions} }, $ref;
    }
    $sameid = $ref->{id};
  }
  
  $sth->finish;
  $dbh->disconnect;

}


# this is also used in IS, IR to retrieve the name
sub get_name {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;
  
  # connect to database
  $dbh = $form->dbconnect($myconfig) unless $dbh;
  
  my $dateformat = $myconfig->{dateformat};
  if ($myconfig->{dateformat} !~ /^y/) {
    my @transdate = split /\W/, $form->{transdate};
    $dateformat .= "yy" if (length $transdate[2] > 2);
  }
  
  if ($form->{transdate} !~ /\W/) {
    $dateformat = 'yyyymmdd';
  }
  
  my $duedate;
  
  if ($myconfig->{dbdriver} eq 'DB2') {
    $duedate = ($form->{transdate}) ? "date('$form->{transdate}') + c.terms DAYS" : "current_date + c.terms DAYS";
  } elsif ($myconfig->{dbdriver} eq 'mssql') {
    if ($form->{transdate}) {
      my $transdate = $form->datetonum($myconfig, $form->{transdate});
      $duedate = "date_add('$transdate', interval c.terms DAY)";
    } else {
      $duedate = "date_add(current_date, interval c.terms DAY)";
    }
  } else {
    $duedate = ($form->{transdate}) ? "to_date('$form->{transdate}', '$dateformat') + c.terms" : "current_date + c.terms";
  }

  $form->{"$form->{vc}_id"} *= 1;

  my $arap = "ar";
  if ($form->{vc} eq 'vendor') {
    $arap = "ap";
  }
  $form->{ARAP} = uc $arap;
  
  # get customer/vendor
  # also get shipto if we did not convert an order or invoice
  my $shipto = ", s.*" if ! $form->{shipto};
  my $shiptojoin = qq|LEFT JOIN shipto s ON (s.trans_id = c.id)|;

  my $query = qq|SELECT c.name AS $form->{vc}, c.$form->{vc}number,
                 c.discount, c.creditlimit, c.terms,
                 c.email, c.cc, c.bcc, c.taxincluded,
		 ad.address1, ad.address2, ad.city, ad.state,
		 ad.zipcode, ad.country, c.curr AS currency, c.language_code,
	         $duedate AS duedate, c.notes AS intnotes,
		 b.discount AS tradediscount, b.description AS business,
		 e.name AS employee, e.id AS employee_id,
		 c1.accno AS arap_accno, c1.description AS arap_accno_description, t1.description AS arap_accno_translation,
		 c2.accno AS payment_accno, c2.description AS payment_accno_description, t2.description AS payment_accno_translation,
		 c3.accno AS discount_accno, c3.description AS discount_accno_description, t3.description AS discount_accno_translation,
		 c.cashdiscount, c.threshold, c.discountterms,
		 c.remittancevoucher,
		 pm.description AS payment_method, c.paymentmethod_id,
		 pr.pricegroup
		 $shipto
                 FROM $form->{vc} c
		 JOIN address ad ON (ad.trans_id = c.id)
		 LEFT JOIN business b ON (b.id = c.business_id)
		 LEFT JOIN employee e ON (e.id = c.employee_id)
		 LEFT JOIN chart c1 ON (c1.id = c.arap_accno_id)
		 LEFT JOIN chart c2 ON (c2.id = c.payment_accno_id)
		 LEFT JOIN chart c3 ON (c3.id = c.discount_accno_id)
		 LEFT JOIN translation t1 ON (t1.trans_id = c1.id AND t1.language_code = '$myconfig->{countrycode}')
		 LEFT JOIN translation t2 ON (t2.trans_id = c2.id AND t2.language_code = '$myconfig->{countrycode}')
		 LEFT JOIN translation t3 ON (t3.trans_id = c3.id AND t3.language_code = '$myconfig->{countrycode}')
		 LEFT JOIN paymentmethod pm ON (pm.id = c.paymentmethod_id)
		 LEFT JOIN pricegroup pr ON (pr.id = c.pricegroup_id)
		 $shiptojoin
	         WHERE c.id = $form->{"$form->{vc}_id"}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $ref = $sth->fetchrow_hashref(NAME_lc);
  
  $ref->{arap_accno} .= qq|--|;
  $ref->{arap_accno} .= ($ref->{arap_accno_translation}) ? $ref->{arap_accno_translation} : $ref->{arap_accno_description};
  $ref->{payment_accno} .= qq|--|;
  $ref->{payment_accno} .= ($ref->{payment_accno_translation}) ? $ref->{payment_accno_translation} : $ref->{payment_accno_description};
  $ref->{discount_accno} .= qq|--|;
  $ref->{discount_accno} .= ($ref->{discount_accno_translation}) ? $ref->{discount_accno_translation} : $ref->{discount_accno_description};
  $ref->{payment_method} .= qq|--$ref->{paymentmethod_id}|;
  
  $form->{$form->{ARAP}} = $ref->{arap_accno} if $ref->{arap_accno} ne '--';

  for (qw(trans_id arap_accno)) { delete $ref->{$_} }

  if ($form->{id}) {
    for (qw(currency employee employee_id)) { delete $ref->{$_} }
  }
 
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;
  
  # if no currency use defaultcurrency
  $form->{currency} = ($form->{currency}) ? $form->{currency} : $form->{defaultcurrency};
  if ($form->{transdate} && ($form->{currency} ne $form->{defaultcurrency})) {
    $form->{exchangerate} ||= $form->get_exchangerate($myconfig, $dbh, $form->{currency}, $form->{transdate});
  }
  
  # if no employee, default to login
  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh) unless $form->{employee_id};
  
  # credit remaining calculation; this should go into a field
  # to speed up db access
  $form->{creditremaining} = $form->{creditlimit};


  $query = qq|SELECT SUM(a.amount - a.paid)
	      FROM $arap a
	      WHERE a.amount != a.paid
	      AND $form->{vc}_id = $form->{"$form->{vc}_id"}|;
  my ($amount) = $dbh->selectrow_array($query);
  $form->{creditremaining} -= $amount;

  if ($form->{"$form->{vc}_id"}) {
    $query = qq|SELECT SUM(a.amount)
		FROM oe a
		WHERE a.quotation = '0'
		AND a.closed = '0'
		AND a.$form->{vc}_id = $form->{"$form->{vc}_id"}|;
    ($amount) = $dbh->selectrow_array($query);
    $form->{creditremaining} -= $amount;
  }

  # get taxes
  $query = qq|SELECT c.accno
              FROM chart c
	      JOIN $form->{vc}tax ct ON (ct.chart_id = c.id)
	      WHERE ct.$form->{vc}_id = $form->{"$form->{vc}_id"}|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my %tax;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $tax{$ref->{accno}} = 1;
  }
  $sth->finish;

  my $where;
  if ($form->{transdate}) {
    $where = qq|AND (t.validto >= '$form->{transdate}' OR t.validto IS NULL)|;
  } else {
    $where = qq|AND t.validto IS NULL|; 
  }
	      
  # get tax rates and description
  $query = qq|SELECT c.accno, c.description, t.rate, t.taxnumber,
              l.description AS translation
	      FROM chart c
	      JOIN tax t ON (c.id = t.chart_id)
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.link LIKE '%$form->{ARAP}_tax%'
	      $where
	      ORDER BY c.accno, t.validto|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $form->{taxaccounts} = "";
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    if ($tax{$ref->{accno}}) {
      $ref->{description} = $ref->{translation} if $ref->{translation};
      for (qw(rate description taxnumber)) { $form->{"$ref->{accno}_$_"} = $ref->{$_} }
      $form->{taxaccounts} .= "$ref->{accno} ";
      $tax{$ref->{accno}} = 0;
    }
  }
  $sth->finish;
  chop $form->{taxaccounts};

  # setup last accounts used for this customer/vendor
  if (!$form->{id}) {
    for (qw(department_id department)) { delete $form->{$_} }
    
    if ($form->{type} =~ /_(order|quotation)/) {
      $query = qq|SELECT MAX(o.id),
                  o.department_id, d.description AS department,
		  o.warehouse_id, d.description AS warehouse
		  FROM oe o
		  LEFT JOIN department d ON (d.id = o.department_id)
		  LEFT JOIN warehouse w ON (w.id = o.warehouse_id)
		  WHERE o.$form->{vc}_id = $form->{"$form->{vc}_id"}
		  GROUP BY o.department_id, department,
		  o.warehouse_id, warehouse
|;
    } elsif ($form->{type} =~ /invoice/) {
      $query = qq|SELECT c.accno, c.description,
		  a.department_id, d.description AS department,
		  a.warehouse_id, d.description AS warehouse,
		  l.description AS translation
		  FROM chart c
		  JOIN acc_trans ac ON (ac.chart_id = c.id)
		  JOIN $arap a ON (a.id = ac.trans_id)
		  LEFT JOIN department d ON (d.id = a.department_id)
		  LEFT JOIN warehouse w ON (w.id = a.warehouse_id)
		  LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		  WHERE a.$form->{vc}_id = $form->{"$form->{vc}_id"}
		  AND a.id IN (SELECT max(id) FROM $arap
			       WHERE $form->{vc}_id = $form->{"$form->{vc}_id"})|;
    } else {
      $query = qq|SELECT c.accno, c.description, c.link, c.category,
		  ac.project_id, p.projectnumber, a.department_id,
		  d.description AS department,
		  l.description AS translation
		  FROM chart c
		  JOIN acc_trans ac ON (ac.chart_id = c.id)
		  JOIN $arap a ON (a.id = ac.trans_id)
		  LEFT JOIN project p ON (ac.project_id = p.id)
		  LEFT JOIN department d ON (d.id = a.department_id)
		  LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		  WHERE a.$form->{vc}_id = $form->{"$form->{vc}_id"}
		  AND a.id IN (SELECT max(id) FROM $arap
			       WHERE $form->{vc}_id = $form->{"$form->{vc}_id"})|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $i = 0;
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $form->{department} = $ref->{department};
      $form->{department_id} = $ref->{department_id};

      $form->{warehouse} = $ref->{warehouse};
      $form->{warehouse_id} = $ref->{warehouse_id};
      
      $ref->{description} = $ref->{translation} if $ref->{translation};
      if ($ref->{link} =~ /_amount/) {
	$i++;
	next if $form->{"amount_$i"};
	$form->{"$form->{ARAP}_amount_$i"} = "$ref->{accno}--$ref->{description}" if $ref->{accno};
	$form->{"projectnumber_$i"} = "$ref->{projectnumber}--$ref->{project_id}" if $ref->{project_id};
      }
    }
    $sth->finish;
    $form->{rowcount} = $i if ($i && !$form->{type});
  }

  $dbh->disconnect if $disconnect;
  
}


############# add addressid, contactid for multiple addresses and contacts
sub company_details {
  my ($self, $myconfig, $form, $dbh) = @_;

  my $disconnect = ($dbh) ? 0 : 1;
  
  # connect to database
  $dbh = $form->dbconnect($myconfig) unless $dbh;
  
  # get rest for the customer/vendor
  my $query = qq|SELECT ct.$form->{vc}number, ct.name, ad.address1, ad.address2,
                 ad.city, ad.state, ad.zipcode, ad.country,
	         ct.contact, ct.phone as $form->{vc}phone,
		 ct.fax as $form->{vc}fax,
		 ct.taxnumber AS $form->{vc}taxnumber, ct.sic_code AS sic,
		 bk.iban AS $form->{vc}iban, bk.bic AS $form->{vc}bic,
		 bk.membernumber AS $form->{vc}bankmembernumber,
		 bk.clearingnumber AS $form->{vc}bankclearingnumber,
		 ct.startdate, ct.enddate,
		 ct.threshold, pm.description AS payment_method
	         FROM $form->{vc} ct
		 JOIN address ad ON (ad.trans_id = ct.id)
		 LEFT JOIN paymentmethod pm ON (pm.id = ct.paymentmethod_id)
		 LEFT JOIN bank bk ON (bk.id = ct.id)
	         WHERE ct.id = $form->{"$form->{vc}_id"}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;

  $query = qq|SELECT * FROM contact
              WHERE trans_id = $form->{"$form->{vc}_id"}|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  $ref = $sth->fetchrow_hashref(NAME_lc);
  for (qw(firstname lastname salutation contacttitle occupation typeofcontact gender)) { $form->{$_} = $ref->{$_} }
  $form->{contact} = "$form->{firstname} $form->{lastname}";
  for (qw(phone fax mobile)) { $form->{"$form->{vc}$_"} ||= $ref->{$_} }
  $sth->finish;
  
  my ($null, $id) = split /--/, $form->{employee};
  $id *= 1;
  $query = qq|SELECT workphone, workfax, workmobile
              FROM employee
              WHERE id = $id|;
  ($form->{workphone}, $form->{workfax}, $form->{workmobile}) = $dbh->selectrow_array($query);

  my @df = qw(weightunit cdt company companyemail companywebsite address tel fax businessnumber);
  my %defaults = $form->get_defaults($dbh, \@df);
  for (@df) { $form->{$_} = $defaults{$_} }

  @df = qw(printer_%);
  %defaults = $form->get_defaults($dbh, \@df);

  my $label;
  my $command;
  for (keys %defaults) {
    if ($_ =~ /printer_/) {
      ($label, $command) = split /=/, $defaults{$_};
      $form->{"${label}_printer"} = $command;
    }
  }

  if ($form->{warehouse_id} *= 1) {
    $query = qq|SELECT address1, address2, city, state, zipcode, country
		FROM address
		WHERE trans_id = $form->{warehouse_id}|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute;
    $ref = $sth->fetchrow_hashref(NAME_lc);

    for (keys %$ref) { $form->{"warehouse$_"} = $ref->{$_} }
    $sth->finish;
  }
   
  # banking details
  if ($form->{vc} eq 'customer') {
    my ($paymentaccno) = split /--/, $form->{"AR_paid_$form->{paidaccounts}"};
    $query = qq|SELECT bk.*, ad.*
		FROM chart c
		JOIN bank bk ON (c.id = bk.id)
		JOIN address ad ON (c.id = ad.trans_id)
		WHERE c.accno = '$paymentaccno'|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute;
    $ref = $sth->fetchrow_hashref(NAME_lc);

    for (keys %$ref) { $form->{"bank$_"} = $ref->{$_} }
    $sth->finish;
      
    for (qw(iban bic membernumber clearingnumber rvc dcn)) { $form->{$_} = $form->{"bank$_"} };
  }

  $dbh->disconnect if $disconnect;

}


sub ship_to {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  AA->company_details($myconfig, $form, $dbh);
  
  my $table = ($form->{vc} eq 'customer') ? 'ar' : 'ap';
  
  my $query = qq|SELECT
                 s.shiptoname, s.shiptoaddress1, s.shiptoaddress2,
                 s.shiptocity, s.shiptostate, s.shiptozipcode,
		 s.shiptocountry, s.shiptocontact, s.shiptophone,
		 s.shiptofax, s.shiptoemail
                 FROM shipto s
		 WHERE trans_id = $form->{"$form->{vc}_id"}
		 UNION
                 SELECT
                 s.shiptoname, s.shiptoaddress1, s.shiptoaddress2,
                 s.shiptocity, s.shiptostate, s.shiptozipcode,
		 s.shiptocountry, s.shiptocontact, s.shiptophone,
		 s.shiptofax, s.shiptoemail
	         FROM shipto s
		 JOIN oe o ON (o.id = s.trans_id)
		 WHERE o.$form->{vc}_id = $form->{"$form->{vc}_id"}
		 UNION
		 SELECT
                 s.shiptoname, s.shiptoaddress1, s.shiptoaddress2,
                 s.shiptocity, s.shiptostate, s.shiptozipcode,
		 s.shiptocountry, s.shiptocontact, s.shiptophone,
		 s.shiptofax, s.shiptoemail
		 FROM shipto s
		 JOIN $table a ON (a.id = s.trans_id)
	         WHERE a.$form->{vc}_id = $form->{"$form->{vc}_id"}|;

  if ($form->{id}) {
    $query .= qq|
		 EXCEPT
		 SELECT
	         s.shiptoname, s.shiptoaddress1, s.shiptoaddress2,
                 s.shiptocity, s.shiptostate, s.shiptozipcode,
		 s.shiptocountry, s.shiptocontact, s.shiptophone,
		 s.shiptofax, s.shiptoemail
		 FROM shipto s
		 WHERE s.trans_id = '$form->{id}'|;
  }
	 
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_shipto} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}



sub all_names {
  my ($dbh, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->retrieve_report($myconfig, $dbh);

  if (! $form->{id}) {
    for (qw(sort direction initreport)) { delete $form->{$_} }
    $form->save_form($myconfig, $dbh);
  }

  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  my $query;
  my $var;
  my $null;
  
  my $where = "1 = 1";

  my @sf = ("$form->{vc}number");
  push @sf, qw(name);

  for (@sf) {
    if ($form->{$_} ne "") {
      $var = $form->like(lc $form->{$_});
      $where .= " AND lower(vc.$_) LIKE '$var'";
    }
  }

  for (qw(startdate enddate)) {
    if ($form->{"${_}from"}) {
      $where .= qq| AND vc.$_ >= '$form->{"${_}from"}'|;
    }
    if ($form->{"${_}to"}) {
      $where .= qq| AND vc.$_ <= '$form->{"${_}to"}'|;
    }
  }

  for (qw(language_code)) {
    if ($form->{$_} ne "") {
      $where .= " AND vc.$_ = '$_'";
    }
  }

  if ($form->{currency}) {
    $where .= " AND vc.curr = '$form->{currency}'";
  }

  for (qw(city state zipcode country)) {
    if ($form->{$_} ne "") {
      $var = $form->like(lc $form->{$_});
      $where .= " AND lower(ad.$_) LIKE '$var'";
    }
  }

  for (qw(employee paymentmethod pricegroup business)) {
    if ($form->{$_}) {
      ($null, $var) = split /--/, $form->{$_};
      $where .= " AND vc.${_}_id = $var";
    }
  }

  $query = qq|SELECT vc.id, vc.name, vc.$form->{vc}number, vc.startdate,
              vc.enddate,
              ad.city, ad.state, ad.zipcode, ad.country,
	      e.name AS employee,
	      b.description AS business,
	      pg.pricegroup,
	      pm.description AS paymentmethod,
	      vc.curr
              FROM $form->{vc} vc
	      JOIN address ad ON (ad.trans_id = vc.id)
	      LEFT JOIN employee e ON (e.id = vc.employee_id)
	      LEFT JOIN paymentmethod pm ON (pm.id = vc.paymentmethod_id)
	      LEFT JOIN business b ON (b.id = vc.business_id)
	      LEFT JOIN pricegroup pg ON (pg.id = vc.pricegroup_id)
	      WHERE $where|;

  my @sf = (name);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_vc} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}


sub vc_links {
  my ($dbh, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $sth;
  my $ref;

  $form->reports($myconfig, $dbh, $form->{login});
  
  for (qw(pricegroup business)) {
    $query = qq|SELECT *
		FROM $_|;
    $sth = $dbh->prepare($query);
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{"all_$_"} }, $ref;
    }
    $sth->finish;
  }
  
  $dbh->disconnect;

}


sub consolidate {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
 
  my $invoice = ($form->{type} eq 'invoice') ? 1 : 0;
  my $arap = lc $form->{ARAP};
  my $vc = ($form->{ARAP} eq 'AR') ? 'customer' : 'vendor';
  
  my $query = qq|SELECT a.*, c.prec
		 FROM $arap a
		 LEFT JOIN curr c ON (c.curr = a.curr)
		 WHERE amount != paid
		 AND invoice = '$invoice'
		 AND approved = '1'
		 AND onhold = '0'|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $query = qq|SELECT c.name, a.city
              FROM $vc c
	      JOIN address a ON (a.trans_id = c.id)
	      WHERE c.id = ?|;
  my $cth = $dbh->prepare($query);

  $query = qq|SELECT c.accno
              FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      WHERE ac.trans_id = ?
	      AND c.link = '$form->{ARAP}'|;
  my $ath = $dbh->prepare($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $cth->execute($ref->{"${vc}_id"});
    ($ref->{name}, $ref->{city}) = $cth->fetchrow_array;
    $cth->finish;
    
    $ath->execute($ref->{id});
    ($arap) = $ath->fetchrow_array;
    $ath->finish;

    $form->{$ref->{curr}}++;
    
    push @{ $form->{all_transactions}{$ref->{curr}}{$arap}{$ref->{name}} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}



1;

