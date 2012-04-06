#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Overpayment function
# used in AR, AP, IS, IR, OE, CP
#
#======================================================================

package OP;

sub overpayment {
  my ($self, $myconfig, $form, $dbh, $amount, $ml) = @_;
 
  my $fxamount = $form->round_amount($amount * $form->{exchangerate}, $form->{precision});
  my ($paymentaccno) = split /--/, $form->{"$form->{ARAP}_paid"};

  my ($null, $department_id) = split /--/, $form->{department};
  $department_id *= 1;

  my $action = 'posted';
  
  my $approved = ($form->{pending}) ? '0' : '1';
  my $batchid ||= $form->{batchid};

  if (!$approved) {
    $action = 'saved';
  }
  
  my $uid = localtime;
  $uid .= $$;

  # add AR/AP header transaction with a payment
  $query = qq|INSERT INTO $form->{arap} (invnumber, employee_id, approved)
	      VALUES ('$uid', (SELECT id FROM employee
			     WHERE login = '$form->{login}'), '$approved')|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|SELECT id FROM $form->{arap}
	    WHERE invnumber = '$uid'|;
  ($uid) = $dbh->selectrow_array($query);
  
  my $voucherid = 'NULL';

  if ($form->{batch}) {
    $form->{vouchernumber} = $form->update_defaults($myconfig, 'vouchernumber', $dbh) unless $form->{vouchernumber};

    if (!($voucherid = $form->{voucherid})) {
      $query = qq|SELECT nextval('id')|;
      ($voucherid) = $dbh->selectrow_array($query);
    }
  }

  my $invnumber = $form->{invnumber};
  $invnumber = $form->update_defaults($myconfig, ($form->{arap} eq 'ar') ? "sinumber" : "vinumber", $dbh) unless $invnumber;

  $query = qq|UPDATE $form->{arap} set
	      invnumber = |.$dbh->quote($invnumber).qq|,
	      $form->{vc}_id = $form->{"$form->{vc}_id"},
	      transdate = '$form->{datepaid}',
	      datepaid = '$form->{datepaid}',
	      duedate = '$form->{datepaid}',
	      netamount = 0,
	      amount = 0,
	      paid = $fxamount,
	      curr = '$form->{currency}',
	      department_id = $department_id,
	      bank_id = (SELECT id FROM chart WHERE accno = '$paymentaccno')
	      WHERE id = $uid|;
  $dbh->do($query) || $form->dberror($query);

  # add AR/AP
  my ($accno) = split /--/, $form->{$form->{ARAP}};
  
  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate, amount,
              approved, vr_id)
	      VALUES ($uid, (SELECT id FROM chart
			     WHERE accno = '$accno'),
	      '$form->{datepaid}', $fxamount * $ml, '$approved', $voucherid)|;
  $dbh->do($query) || $form->dberror($query);

  # add payment
  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
	      amount, source, memo, approved, vr_id)
	      VALUES ($uid, (SELECT id FROM chart
			     WHERE accno = '$paymentaccno'),
		'$form->{datepaid}', $amount * $ml * -1, |
		.$dbh->quote($form->{source}).qq|, |
		.$dbh->quote($form->{memo}).qq|, '$approved', $voucherid)|;
  $dbh->do($query) || $form->dberror($query);

  # add exchangerate difference
  if ($fxamount != $amount) {
    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
		amount, cleared, fx_transaction, source, approved, vr_id)
		VALUES ($uid, (SELECT id FROM chart
			       WHERE accno = '$paymentaccno'),
	        '$form->{datepaid}', ($fxamount - $amount) * $ml * -1,
	        '$form->{datepaid}', '1', |
		.$dbh->quote($form->{source}).qq|, '$approved', $voucherid)|;
    $dbh->do($query) || $form->dberror($query);
  }

  # add voucher
  if ($form->{batch}) {
    $query = qq|INSERT INTO vr (br_id, trans_id, id, vouchernumber)
                VALUES ($batchid, $uid, $voucherid, |
		.$dbh->quote($form->{vouchernumber}).qq|)|;
    $dbh->do($query) || $form->dberror($query);

    # update batch
    $form->update_balance($dbh,
                          'br',
			  'amount',
			  qq|id = $batchid|,
			  $fxamount);

  }
  
  my %audittrail = ( tablename  => $form->{arap},
                     reference  => $invnumber,
		     formname   => ($form->{arap} eq 'ar') ? 'deposit' : 'pre-payment',
		     action     => $action,
		     id         => $uid );
 
  $form->audittrail($dbh, "", \%audittrail);
  
}


1;

