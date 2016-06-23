#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Check and receipt printing payment module backend routines
# Number to text conversion routines are in
# locale/{countrycode}/Num2text
#
#======================================================================

package CP;


sub new {
  my ($type, $countrycode) = @_;

  my $self = {};

  if ($countrycode) {
    if (-f "locale/$countrycode/Num2text") {
      require "locale/$countrycode/Num2text";
    } else {
      use SL::Num2text;
    }
  } else {
    use SL::Num2text;
  }

  bless $self, $type;

}


sub paymentaccounts {
  my ($self, $myconfig, $form, $dbh) = @_;

  my $disconnect = ($dbh) ? 0 : 1;
  
  # connect to database
  $dbh = $form->dbconnect($myconfig) unless $dbh;
  
  my $query = qq|SELECT c.accno, c.description, c.link,
                 l.description AS translation
                 FROM chart c
		             LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
                 WHERE c.link LIKE '%$form->{ARAP}%'
                 AND c.closed = '0'
                 ORDER BY c.accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $form->{PR}{$form->{ARAP}} = ();
  $form->{PR}{"$form->{ARAP}_paid"} = ();
  $form->{PR}{"$form->{ARAP}_discount"} = ();
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    foreach my $item (split /:/, $ref->{link}) {
      if ($item eq $form->{ARAP}) {
        push @{ $form->{PR}{$form->{ARAP}} }, $ref;
      }
      if ($item eq "$form->{ARAP}_paid") {
        push @{ $form->{PR}{"$form->{ARAP}_paid"} }, $ref;
      }
      if ($item eq "$form->{ARAP}_discount") {
        push @{ $form->{PR}{"$form->{ARAP}_discount"} }, $ref;
      }
    }
  }
  $sth->finish;
  
  # get currencies and closedto
  $form->{datepaid} = $form->current_date($myconfig);

  ($form->{employee}) = $form->get_employee($dbh);
  
  my %defaults = $form->get_defaults($dbh, \@{['closedto', "$form->{type}\_%"]});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  $form->{currencies} = $form->get_currencies($myconfig, $dbh);

  if ($form->{payment} eq 'payments') {
    # get language codes
    $form->all_languages($myconfig, $dbh);
    
    $form->all_departments($myconfig, $dbh, $form->{vc});
  }

  if ($form->{vc} eq 'vendor') {
    # get business types
    $query = qq|SELECT *
                FROM business
                ORDER BY rn|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{all_business} }, $ref;
    }
    $sth->finish;
  }

  $query = qq|SELECT *
              FROM paymentmethod
              ORDER BY rn|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_paymentmethod} }, $ref;
  }
  $sth->finish;

  $form->get_peripherals($dbh);

  $dbh->disconnect if $disconnect;

}


sub get_openvc {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my $where = qq|a.amount != a.paid
                 AND a.approved = '1'
                 AND a.onhold = '0'
                 AND NOT a.id IN (SELECT id
		             FROM semaphore)|;

  $form->{vc} =~ s/;//g;
  my $arap = ($form->{vc} eq 'customer') ? 'ar' : 'ap';

  my $sth;
  my $ref;
  my $i = 0;
  my $var;

  if ($form->{duedatefrom}) {
    $where .= qq|
	      AND a.duedate >= '$form->{duedatefrom}'|;
  }
  if ($form->{duedateto}) {
    $where .= qq|
	      AND a.duedate <= '$form->{duedateto}'|;
  }

  my $id;
  my $description;
  
  if (! $form->{all_vc}) {
    ($id, $description) = split /--/, $form->{$form->{ARAP}};
    if ($id) {
      $where .= qq|
      	AND c.accno = '$id'|;
    }
    if ($form->{vc} eq 'vendor') {
      ($description, $id) = split /--/, $form->{business};
      if ($id) {
        $where .= qq|
        AND vc.business_id = $id|;
      }
    }
  }
  
  ($description, $id) = split /--/, $form->{paymentmethod};
 
  if ($id) {
    $where .= qq|
	    AND a.paymentmethod_id = $id|;
  }

  if (! $form->{"select$form->{vc}"}) {
    if ($form->{$form->{vc}}) {
      $var = $form->like(lc $form->{$form->{vc}});
      $where .= qq| AND lower(vc.name) LIKE '$var'|;
    }
    if ($form->{"$form->{vc}number"}) {
      $var = $form->like(lc $form->{"$form->{vc}number"});
      $where .= qq| AND lower(vc.$form->{vc}number) LIKE '$var'|;
    }
  }

  my %defaults = $form->get_defaults($dbh, \@{['namesbynumber']});
  my $sortorder = "name";
  if ($defaults{namesbynumber}) {
    $sortorder = "$form->{vc}number";
  }

  # build selection list
  $query = qq|SELECT vc.*,
              ad.address1, ad.address2, ad.city, ad.state, ad.zipcode,
              ad.country, a.amount, a.paid,
              a.exchangerate,
              l.description AS translation,
              ch.accno AS $form->{ARAP},
              ch.description AS $form->{ARAP}_description,
              pa.accno AS $form->{ARAP}_paid,
              pa.description AS $form->{ARAP}_paid_description,
              pm.description AS paymentmethod
              FROM $form->{vc} vc
              JOIN $arap a ON (a.$form->{vc}_id = vc.id)
              JOIN acc_trans ac ON (a.id = ac.trans_id)
              JOIN chart c ON (c.id = ac.chart_id)
              JOIN address ad ON (ad.trans_id = vc.id)
              LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
              LEFT JOIN chart ch ON (ch.id = vc.arap_accno_id)
              LEFT JOIN chart pa ON (pa.id = vc.payment_accno_id)
              LEFT JOIN paymentmethod pm ON (pm.id = vc.paymentmethod_id)
              WHERE $where
              ORDER BY vc.$sortorder|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my %due;
  my @transactions = ();

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    
    $ref->{exchangerate} ||= 1;
    $ref->{description} = $ref->{translation} if $ref->{translation};

    if ($form->{vc} eq 'vendor') {
      $ref->{fxdue} = $form->round_amount(($ref->{amount} - $ref->{paid}) / $ref->{exchangerate}, $form->{precision});
      $due{$ref->{id}} += $ref->{fxdue};
    }
    push @transactions, $ref;
  }
  $sth->finish;

  my %vc;
  
  foreach $ref (@transactions) {

    next if $vc{$ref->{id}};
    if ($form->{vc} eq 'vendor') {
      if ($ref->{threshold} > 0) {
        next if $due{$ref->{id}} < $ref->{threshold};
      }
    }

    $i++;
    $vc{$ref->{id}} = 1;
    push @{ $form->{name_list} }, $ref;
 
  }

  $form->all_departments($myconfig, $dbh, $form->{vc});
  
  $form->all_languages($myconfig, $dbh);
  
  $dbh->disconnect;

  $i;

}


sub retrieve {
  my ($self, $myconfig, $form) = @_;
  
  my $id;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{id} *= 1;

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $ml = 1;
  
  if ($form->{vc} eq 'customer') {
    $ml = -1;
  }
 
  my $query = qq|SELECT a.id, a.invnumber, a.transdate, a.duedate,
                 ac.transdate AS datepaid, a.amount,
		 SUM(ac.amount) * $ml AS paid, ac.source, ac.memo,
		 a.$form->{vc}_id,
		 a.curr, a.discountterms, a.cashdiscount, a.netamount,
		 date '$form->{transdate}' <= a.transdate + a.discountterms AS calcdiscount,
		 ac.approved,
		 a.exchangerate,
		    (SELECT acc.amount * $ml
		     FROM acc_trans acc
		     JOIN chart c ON (c.id = acc.chart_id)
		     WHERE acc.trans_id = ac.trans_id
		     AND acc.fx_transaction = '0'
		     AND acc.vr_id = $form->{id}
		     AND c.link LIKE '%$form->{ARAP}_discount%') AS discount
	         FROM $form->{arap} a
		 JOIN acc_trans ac ON (ac.trans_id = a.id)
		 JOIN chart ch ON (ch.id = ac.chart_id)
		 WHERE ac.vr_id = $form->{id}
		 AND ac.fx_transaction = '0'
		 AND ch.link LIKE '%$form->{ARAP}_paid%'
                 GROUP BY a.id, a.invnumber, a.transdate, a.duedate,
		 a.amount, a.paid, a.discountterms, a.cashdiscount, a.netamount,
		 a.$form->{vc}_id, a.curr, ac.transdate, calcdiscount,
		 ac.approved, a.exchangerate, ac.trans_id, ac.source, ac.memo|;

  my @sf = qw(transdate invnumber);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $query = qq|SELECT c.accno, c.description,
              l.description AS translation
              FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE ac.trans_id = ?
	      AND ac.fx_transaction = '0'
	      AND (c.link LIKE '$form->{ARAP}%'
	           OR c.link LIKE '%:$form->{ARAP}')|;
  my $ath = $dbh->prepare($query);
 
  $query = qq|SELECT c.accno, c.description,
              l.description AS translation
              FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE ac.trans_id = ?
	      AND ac.transdate = ?
	      AND ac.fx_transaction = '0'
	      AND c.link LIKE '%$form->{ARAP}_paid%'|;
  my $pth = $dbh->prepare($query);
  
  $query = qq|SELECT c.accno, c.description,
              l.description AS translation
              FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE ac.trans_id = ?
	      AND ac.fx_transaction = '0'
	      AND c.link LIKE '%$form->{ARAP}_discount%'|;
  my $dth = $dbh->prepare($query);

  my $accno;
  my $description;
  my $translation;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{edit} .= "$ref->{id} ";
    
    push @{ $form->{transactions} }, $ref;
    
    $form->{"$form->{vc}_id"} = $ref->{"$form->{vc}_id"};
    $form->{source} ||= $ref->{source};
    $form->{memo} ||= $ref->{memo};
    $form->{approved} ||= $ref->{approved};
    $ref->{calcdiscount} = 0 unless $ref->{discountterms};

    # AR/AP account
    if (!$form->{arap_accno}) {
      $ath->execute($ref->{id});
      ($accno, $description, $translation) = $ath->fetchrow_array;
      $ath->finish;
      $description = $translation if $translation;
      $form->{arap_accno} = "${accno}--$description";
    }
    # payment
    if (!$form->{payment_accno}) {
      $pth->execute($ref->{id}, $ref->{datepaid});
      ($accno, $description, $translation) = $pth->fetchrow_array;
      $pth->finish;
      $description = $translation if $translation;
      $form->{"$form->{ARAP}_paid"} = "${accno}--$description";
      $form->{payment_accno} = $form->{"$form->{ARAP}_paid"};
    }
    # discount
    if (!$form->{discount_accno}) {
      if ($ref->{discount}) {
	$dth->execute($ref->{id});
	($accno, $description, $translation) = $dth->fetchrow_array;
	$dth->finish;
	$description = $translation if $translation;
	$form->{"$form->{ARAP}_discount"} = "${accno}--$description";
	$form->{discount_accno} = $form->{"$form->{ARAP}_discount"};
      }
    }

  }
  chop $form->{edit};
  $sth->finish;

  $query = qq|SELECT br.description, vr.vouchernumber
              FROM vr
	      JOIN br ON (br.id = vr.br_id)
	      WHERE vr.id = $form->{id}|;
  ($form->{batchdescription}, $form->{vouchernumber}) = $dbh->selectrow_array($query);
    
  $form->{voucherid} = $form->{id};
  $form->{id} *= 1;
  AA->get_name($myconfig, $form, $dbh);

  $form->{"old$form->{vc}"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;

  &paymentaccounts("", $myconfig, $form, $dbh);
  
  $form->all_departments($myconfig, $dbh, $form->{vc});
  
  $form->all_languages($myconfig, $dbh);

  $dbh->disconnect;

}


sub get_openinvoices {
  my ($self, $myconfig, $form) = @_;
  
  my $id;
 
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
 
  $form->{vc} =~ s/;//g;

  # remove locks
  $form->remove_locks($myconfig, $dbh, $form->{arap});
  
  my $where = qq|WHERE a.$form->{vc}_id = $form->{"$form->{vc}_id"}
	         AND a.amount != a.paid
		 AND a.approved = '1'
		 AND a.onhold = '0'
		 AND NOT a.id IN (SELECT id
		                  FROM semaphore)|;

  my %defaults = $form->get_defaults($dbh, \@{[qw(namesbynumber cdt precision)]});

  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my @sf = qw(transdate invnumber);

  if ($form->{payment} eq 'payments') {
    $where = qq|WHERE a.amount != a.paid
                AND a.approved = '1'
		AND a.onhold = '0'
		AND NOT a.id IN (SELECT id
		                 FROM semaphore)|;
    @sf = qw(name transdate);
    if ($defaults{namesbynumber}) {
      @sf = ("$form->{vc}number", "transdate");
    }
  }
  
  $where .= qq|
              AND a.curr = '$form->{currency}'| if $form->{currency};
  $where .= qq|
	      AND a.duedate >= '$form->{duedatefrom}'| if $form->{duedatefrom};
  $where .= qq|
	      AND a.duedate <= '$form->{duedateto}'| if $form->{duedateto};

  (undef, $id) = split /--/, $form->{department};
  $where .= qq|
                 AND a.department_id = $id| if $id;

  (undef, $id) = split /--/, $form->{paymentmethod};
  $where .= qq|
                 AND a.paymentmethod_id = $id| if $id;
	 
  ($id) = split /--/, $form->{$form->{ARAP}};
  $where .= qq|
		 AND ch.accno = '$id'| if $id;

  if ($form->{vc} eq 'vendor') {
    (undef, $id) = split /--/, $form->{business};
    $where .= qq|
		   AND vc.business_id = $id| if $id;
		   
  }
  
  my $datepaid = ($form->{datepaid}) ? "date '$form->{datepaid}'" : 'current_date';
  my $query = qq|SELECT DISTINCT a.id, a.invnumber, a.transdate, a.duedate,
                 a.description AS invdescription,
		 a.amount, a.paid, a.curr, vc.$form->{vc}number, vc.name,
		 vc.language_code, vc.threshold, vc.curr AS currency,
		 vc.payment_accno_id,
		 a.$form->{vc}_id,
		 a.discountterms, a.cashdiscount, a.netamount,
		 $datepaid <= a.transdate + a.discountterms AS calcdiscount,
		 a.exchangerate, ex.exchangerate AS vcexch,
		 a.taxincluded
		 FROM acc_trans ac
		 JOIN $form->{arap} a ON (a.id = ac.trans_id)
		 JOIN $form->{vc} vc ON (vc.id = a.$form->{vc}_id)
		 JOIN chart ch ON (ch.id = ac.chart_id)
		 LEFT JOIN exchangerate ex ON (ex.curr = vc.curr AND ex.transdate = a.transdate)
		 $where|;

  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  # discount
  $query = qq|SELECT sum(ac.amount)
              FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      WHERE c.link LIKE '%$form->{ARAP}_discount%'
	      AND ac.approved = '1'
	      AND ac.trans_id = ?|;
  my $tth = $dbh->prepare($query) || $form->dberror($query);
	      
  my %total;
  my @transactions = ();

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    $ref->{calcdiscount} = 0 if ! $ref->{cashdiscount};
    if ($ref->{calcdiscount}) {
      $tth->execute($ref->{id});
      if ($tth->fetchrow_array) {
	$ref->{calcdiscount} = 0;
      }
      $tth->finish;
    }

    $ref->{exchangerate} ||= 1;
    $ref->{vcexch} ||= 1;

    # for threshold calculation
    $ref->{fxdue} = $form->round_amount(($ref->{amount} - $ref->{paid}) / $ref->{vcexch}, $form->{precision});
    
    $total{$ref->{"$form->{vc}_id"}} += $ref->{fxdue};
    push @transactions, $ref;
  }
  
  $sth->finish;

  foreach $ref (@transactions) {
    if ($form->{vc} eq 'vendor') {
      if ($ref->{threshold} > 0) {
	$total{$ref->{"$form->{vc}_id"}} = $form->round_amount($total{$ref->{"$form->{vc}_id"}}, $form->{precision});
        next if $total{$ref->{"$form->{vc}_id"}} < $ref->{threshold};
      }
    }
    $form->create_lock($myconfig, $dbh, $ref->{id}, $form->{arap});
    push @{ $form->{PR} }, $ref;
  }
    
  $dbh->disconnect;
  
}



sub post_payment {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn AutoCommit off
  $dbh = $form->dbconnect_noauto($myconfig);

  my ($paymentaccno) = split /--/, $form->{"$form->{ARAP}_paid"};
  my ($discountaccno) = split /--/, $form->{"$form->{ARAP}_discount"};
  
  # if currency ne defaultcurrency update exchangerate
  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{exchangerate} = $form->parse_amount($myconfig, $form->{exchangerate});

    $form->update_exchangerate($dbh, $form->{currency}, $form->{datepaid}, $form->{exchangerate});
  } else {
    $form->{exchangerate} = 1;
  }

  $form->update_defaults($myconfig, qq|$form->{type}_$paymentaccno|, $dbh, $form->{source});

  my $query;
  my $sth;

  # tax accounts
  $query = qq|SELECT DISTINCT c.accno, t.rate, t.validto
              FROM chart c
	      JOIN acc_trans ac ON (ac.chart_id = c.id)
	      JOIN tax t ON (t.chart_id = c.id)
	      WHERE c.link LIKE '%$form->{ARAP}_tax%'
	      AND ac.trans_id = ?
	      AND (t.validto >= ? OR t.validto IS NULL)
	      ORDER BY t.validto DESC|;
  my $tth = $dbh->prepare($query) || $form->dberror($query);
  
  my %defaults = $form->get_defaults($dbh, \@{['fx%_accno_id', 'cdt']});

  my $ml = ($form->{ARAP} eq 'AR') ? 1 : -1;

  $form->{arap} = lc $form->{ARAP};
  
  my $where = qq|
		c.link = '$form->{ARAP}'
		|;
 
  # AR/AP default account
  $query = qq|SELECT c.id
              FROM chart c
              WHERE $where|;
  my ($arapdefault) = $dbh->selectrow_array($query);
 
  # AR/AP account
  $query = qq|SELECT DISTINCT c.id
              FROM chart c
	      JOIN acc_trans a ON (a.chart_id = c.id)
	      WHERE $where
	      AND a.trans_id = ?|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);

  my $paymentamount = $form->parse_amount($myconfig, $form->{amount});

  # query to retrieve paid amount
  $query = qq|SELECT amount, netamount, paid, transdate, taxincluded,
              exchangerate
              FROM $form->{arap}
              WHERE id = ?
 	      FOR UPDATE|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);

  my %trans;
  my $ref;
  my $amount;
  my $vth;
  my $dth;
  my $ith;
  my $dith;

  my %cdt;
  my $diff;
  my $accno;
  my $rate;

  # delete payments
  $form->{voucherid} *= 1;
  if ($form->{edit} && $form->{voucherid}) {
    $query = qq|SELECT SUM(ac.amount) * $ml * -1
                FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		WHERE ac.trans_id = ?
		AND ac.vr_id = $form->{voucherid}
		AND c.link LIKE '%$form->{ARAP}_paid%'
		AND NOT (ac.chart_id = $defaults{fxgain_accno_id}
		      OR ac.chart_id = $defaults{fxloss_accno_id})|;
    $sth = $dbh->prepare($query) || $form->dberror($query);

    # discount
    $query = qq|SELECT sum(ac.amount) * $ml * -1
                FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		WHERE ac.trans_id = ?
		AND ac.vr_id = $form->{voucherid}
		AND c.link LIKE '%$form->{ARAP}_discount%'|;
    $dth = $dbh->prepare($query) || $form->dberror($query);

    foreach $id (split / /, $form->{edit}) {
      
      $query = qq|SELECT id
		  FROM acc_trans
		  WHERE trans_id = $id
		  AND vr_id = $form->{voucherid}|;
      $ith = $dbh->prepare($query) || $form->dberror($query);
      $ith->execute;
      
      while (($paymentid) = $ith->fetchrow_array) {
	$query = qq|DELETE FROM payment
		    WHERE id = $paymentid
		    AND trans_id = $id|;
	$dith = $dbh->prepare($query) || $form->dberror($query);
	$dbh->do($query) || $form->dberror($query);
      }
      $ith->finish;
     
      # payments
      $sth->execute($id);
      $ref = $sth->fetchrow_hashref(NAME_lc);
      for (keys %$ref) { $trans{$id}{$_} = $ref->{$_} }
      $sth->finish;
      
      # discount
      $dth->execute($id);
      ($trans{$id}{discount}) = $dth->fetchrow_array;
      $dth->finish;
    
      # update arap
      $form->update_balance($dbh,
                            $form->{arap},
			    'paid',
			    qq|id = $id|,
			    ($trans{$id}{amount} + $trans{$id}{discount}) * -1);

      # update batch
      $form->update_balance($dbh,
  			    'br',
			    'amount',
			    qq|id = $form->{batchid}|,
			    ($trans{$id}{amount} + $trans{$id}{discount}) * -1);

    }
    
    $query = qq|DELETE FROM acc_trans
                WHERE vr_id = $form->{voucherid}|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|DELETE FROM vr
                WHERE id = $form->{voucherid}|;
    $dbh->do($query) || $form->dberror($query);

  }
    
  my %audittrail;
  my $action = 'posted';
  my $approved = ($form->{pending}) ? '0' : '1';
  
  if (!$approved) {
    $action = 'saved';
  }
  
  my $voucherid = 'NULL';
  
  if ($form->{batch}) {
    $voucherid = $form->{voucherid};
    if (! $form->{voucherid}) {
      $query = qq|SELECT nextval('id')|;
      ($voucherid) = $dbh->selectrow_array($query);
    }
    $form->{vouchernumber} = $form->update_defaults($myconfig, 'vouchernumber', $dbh) unless $form->{vouchernumber};
  }
  
  $query = qq|INSERT INTO vr (br_id, trans_id, id, vouchernumber)
              VALUES ($form->{batchid}, ?, $voucherid, |
	      .$dbh->quote($form->{vouchernumber}).qq|)|;
  $vth = $dbh->prepare($query) || $form->dberror($query);
 
  my $assignvoucherid;
  my $arap;
  my (undef, $paymentmethod_id) = split /--/, $form->{paymentmethod};
  $paymentmethod_id *= 1;
  
  # go through line by line
  for my $i (1 .. $form->{rowcount}) {

    $assignvoucherid = 1;
    $cdt = 0;
    
    for (qw(paid discount)) { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) }
    
    if ($form->{"checked_$i"}) {

      # paymentid
      $query = qq|SELECT MAX(id)
		  FROM payment
		  WHERE trans_id = $form->{"id_$i"}|;
      ($paymentid) = $dbh->selectrow_array($query);
      $paymentid++;

      # original paid
      # lock for update
      $pth->execute($form->{"id_$i"}) || $form->dberror;
      $ref = $pth->fetchrow_hashref(NAME_lc);
      for (keys %$ref) { $trans{$form->{"id_$i"}}{$_} = $ref->{$_} }

      $paymentamount -= $form->{"paid_$i"};
      
      $ath->execute($form->{"id_$i"}) || $form->dberror;
      ($arap) = $ath->fetchrow_array || $arapdefault;
      $ath->finish;
      
      $amount = $form->round_amount($form->{"paid_$i"} * $trans{$form->{"id_$i"}}{exchangerate}, $form->{precision});

      # add AR/AP
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
                  amount, approved, vr_id)
                  VALUES ($form->{"id_$i"}, $arap, '$form->{datepaid}',
		  $amount * $ml, '$approved',
		  $voucherid)|;
      $dbh->do($query) || $form->dberror($query);

      # add payment
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
                  amount, source, memo, approved, vr_id, id)
                  VALUES ($form->{"id_$i"},
		         (SELECT id FROM chart
		          WHERE accno = '$paymentaccno'),
		  '$form->{datepaid}', $form->{"paid_$i"} * $ml * -1, |
		  .$dbh->quote($form->{source}).qq|, |
		  .$dbh->quote($form->{memo}).qq|, '$approved',
		  $voucherid, $paymentid)|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|INSERT INTO payment (id, trans_id, exchangerate,
                  paymentmethod_id)
                  VALUES ($paymentid, $form->{"id_$i"}, $form->{exchangerate},
		  $paymentmethod_id)|;
      $dbh->do($query) || $form->dberror($query);

      # add exchangerate difference if currency ne defaultcurrency
      $amount = $form->round_amount($form->{"paid_$i"} * ($form->{exchangerate} - 1) * $ml * -1, $form->{precision});

      if ($amount) {
        # exchangerate difference
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
		    amount, fx_transaction, source, approved, vr_id)
		    VALUES ($form->{"id_$i"},
		           (SELECT id FROM chart
			    WHERE accno = '$paymentaccno'),
		  '$form->{datepaid}', $amount, '1', |
		  .$dbh->quote($form->{source}).qq|, '$approved',
		  $voucherid)|;
	$dbh->do($query) || $form->dberror($query);
      }

      # gain/loss
      $amount = $form->round_amount(($form->round_amount($form->{"paid_$i"} * $trans{$form->{"id_$i"}}{exchangerate}, $form->{precision}) - $form->round_amount($form->{"paid_$i"} * $form->{exchangerate}, $form->{precision})) * $ml * -1, $form->{precision});
      if ($amount) {
	my $accno_id = ($amount > 0) ? $defaults{fxgain_accno_id} : $defaults{fxloss_accno_id};
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
		    amount, fx_transaction, approved, vr_id)
		    VALUES ($form->{"id_$i"}, $accno_id,
		    '$form->{datepaid}', $amount, '1', '$approved',
		    $voucherid)|;
	$dbh->do($query) || $form->dberror($query);
      }

      
      # deduct tax for cash discount
      if ($form->{"discount_$i"}) {

	%cdt = ();
	$diff = 0;
	
	if ($defaults{cdt} && !$trans{$form->{"id_$i"}}{taxincluded}) {

	  $tth->execute($form->{"id_$i"}, $trans{$form->{"id_$i"}}{transdate}) || $form->dberror;
	  
	  my $totalrate = 0;
	  while (($accno, $rate) = $tth->fetchrow_array) {
	    $totalrate += $rate;
	    $cdt{$accno} = $rate;
	  }
	  $tth->finish;

	  $cdt = $form->round_amount($form->{"discount_$i"} * $totalrate, $form->{precision});

	  for (keys %cdt) {
	    $accno = $_;
	    if ($totalrate) {
	      $amount = $cdt * $cdt{$_} / $totalrate;
	      $cdt{$_} = $form->round_amount($amount, $form->{precision});
	      $diff += ($amount - $cdt{$_});
	    }
	  }
	  $diff = $form->round_amount($diff, $form->{precision});
	  if ($diff != 0) {
	    $cdt{$accno} -= $diff;
	  }
	
	  $cdt = $form->round_amount($cdt * $trans{$form->{"id_$i"}}{exchangerate}, $form->{precision});
	  
	}

	$cdt{$discountaccno} = $form->{"discount_$i"};

	for (keys %cdt) {
          # add AR/AP
	  $amount = $form->round_amount($cdt{$_} * $trans{$form->{"id_$i"}}{exchangerate}, $form->{precision});
	  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
		      amount, approved, vr_id, id)
		      VALUES ($form->{"id_$i"}, $arap, '$form->{datepaid}',
		      $amount * $ml, '$approved',
		      $voucherid, $form->{"id_$i"})|;
	  $dbh->do($query) || $form->dberror($query);

          # add discount
	  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
		      amount, source, memo, approved, vr_id, id)
		      VALUES ($form->{"id_$i"},
			     (SELECT id FROM chart
			      WHERE accno = '$_'),
		      '$form->{datepaid}', $cdt{$_} * $ml * -1, |
		      .$dbh->quote($form->{source}).qq|, |
		      .$dbh->quote($form->{memo}).qq|, '$approved',
		      $voucherid, $form->{"id_$i"})|;
	  $dbh->do($query) || $form->dberror($query);

	  # add exchangerate difference if currency ne defaultcurrency
	  $amount = $form->round_amount($cdt{$_} * ($form->{exchangerate} - 1) * $ml * -1, $form->{precision});

	  if ($amount) {
	    # exchangerate difference
	    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
			amount, fx_transaction, source, approved, vr_id, id)
			VALUES ($form->{"id_$i"},
			       (SELECT id FROM chart
				WHERE accno = '$_'),
		      '$form->{datepaid}', $amount, '1', |
		      .$dbh->quote($form->{source}).qq|, '$approved',
		      $voucherid, $form->{"id_$i"})|;
	    $dbh->do($query) || $form->dberror($query);

	    # gain/loss
	    $amount = $form->round_amount(($form->round_amount($cdt{$_} * $trans{$form->{"id_$i"}}{exchangerate}, $form->{precision}) - $form->round_amount($cdt{$_} * $form->{exchangerate}, $form->{precision})) * $ml * -1, $form->{precision});
	    
	    if ($amount) {
	      my $accno_id = ($amount > 0) ? $defaults{fxgain_accno_id} : $defaults{fxloss_accno_id};
	      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
			  amount, fx_transaction, approved, vr_id, id)
			  VALUES ($form->{"id_$i"}, $accno_id,
			  '$form->{datepaid}', $amount, '1', '$approved',
			  $voucherid, $form->{"id_$i"})|;
	      $dbh->do($query) || $form->dberror($query);
	    }
	  }
	}
      }


      $form->{"paid_$i"} = $form->round_amount($form->{"paid_$i"} * $trans{$form->{"id_$i"}}{exchangerate}, $form->{precision});
      $form->{"discount_$i"} = $form->round_amount($form->{"discount_$i"} * $trans{$form->{"id_$i"}}{exchangerate}, $form->{precision});

      # unlock arap
      $pth->finish;

      $amount = $form->round_amount($trans{$form->{"id_$i"}}{paid} + $form->{"paid_$i"} + $form->{"discount_$i"}, $form->{precision});

      # if discount taxable adjust ar/ap amount
      if ($defaults{cdt} && !$trans{$form->{"id_$i"}}{taxincluded}) {
	$trans{$form->{"id_$i"}}{amount} -= $cdt;
      }

      # update AR/AP transaction
      $query = qq|UPDATE $form->{arap} set
                  amount = $trans{$form->{"id_$i"}}{amount},
		  paid = $amount,
		  datepaid = '$form->{datepaid}',
		  bank_id = (SELECT id FROM chart WHERE accno = '$paymentaccno'),
		  paymentmethod_id = $paymentmethod_id
		  WHERE id = $form->{"id_$i"}|;
      $dbh->do($query) || $form->dberror($query);
      
      %audittrail = ( tablename  => $form->{arap},
                      reference  => $form->{source},
		      formname   => $form->{formname},
		      action     => $action,
		      id         => $form->{"id_$i"} );
 
      $form->audittrail($dbh, "", \%audittrail);


      if ($form->{batch}) {
	  # add voucher
	  $vth->execute($form->{"id_$i"});
	  $vth->finish;

	  # update batch
	  $form->update_balance($dbh,
				'br',
				'amount',
				qq|id = $form->{batchid}|,
				$amount);
      }
    }
  }

  # record a AR/AP with a payment
  if ($form->round_amount($paymentamount, $form->{precision})) {
    $form->{invnumber} = "";
    if ($assignvoucherid) {
      for (qw(id number)) { delete $form->{"voucher$_"} }
    }
    OP::overpayment("", $myconfig, $form, $dbh, $paymentamount, $ml);
  }

  $form->remove_locks($myconfig, $dbh, $form->{arap}) if $form->{payment} eq 'payment';

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}



sub invoice_ids {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $datepaid = ($form->{datepaid}) ? "date '$form->{datepaid}'" : 'current_date';

  $form->{vc} =~ s/;//g;
  $form->{arap} = ($form->{vc} eq 'customer') ? 'ar' : 'ap';

  my $query = qq|SELECT DISTINCT a.id, a.invnumber, a.transdate, a.duedate,
                 a.description AS invdescription,
		 a.amount, a.paid, vc.$form->{vc}number, vc.name,
		 a.$form->{vc}_id, a.cashdiscount, a.netamount,
                 $datepaid <= a.transdate + a.discountterms AS calcdiscount,
		 a.exchangerate,
		    (SELECT acc.amount
		     FROM acc_trans acc
		     JOIN chart c ON (c.id = acc.chart_id)
		     WHERE acc.trans_id = ac.trans_id
		     AND acc.fx_transaction = '0'
		     AND c.link LIKE '%$form->{ARAP}_discount%') AS discount
		 FROM acc_trans ac
		 JOIN $form->{arap} a ON (a.id = ac.trans_id)
		 JOIN $form->{vc} vc ON (vc.id = a.$form->{vc}_id)
		 WHERE a.id = ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  my $ref;

  for (1 .. $form->{rowcount}) {
    for $id (split / /, $form->{"id_$_"}) {
      $sth->execute($id) || $form->dberror;
      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
	push @{ $form->{PR} }, $ref;
      }
      $sth->finish;
    }
  }

  $dbh->disconnect;
  
}


sub payment_register {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};

  my $query = qq|SELECT c.id, c.accno, c.description,
                 l.description AS translation
                 FROM chart c
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		 WHERE c.charttype = 'A'
                 AND c.link LIKE '%$form->{ARAP}_paid%'
                 AND c.closed = '0'
		 ORDER BY c.accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my @accno;
  my $ref;
  my $arap;
  my $ml = 1;

  if ($form->{ARAP} eq 'AP') {
    $arap = 'ap';
  } else {
    $arap = 'ar';
    $ml = -1;
  }

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @accno, $ref;
  }
  $sth->finish;

  $query = qq|SELECT acc.amount * $ml AS amount, acc.transdate AS datepaid,
              acc.source, acc.trans_id,
              vc.name, vc.id AS $form->{vc}_id
              FROM acc_trans acc
              JOIN $arap a ON (a.id = acc.trans_id)
              JOIN $form->{vc} vc ON (vc.id = a.$form->{vc}_id)|;

  my $where = "WHERE acc.fx_transaction = '0'
               AND acc.chart_id = ?";

  unless ($form->{datepaidfrom} || $form->{datepaidto}) {
    ($form->{datepaidfrom}, $form->{datepaidto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
  if ($form->{datepaidfrom}) {
    $where .= " AND acc.transdate >= '$form->{datepaidfrom}'";
  }
  if ($form->{datepaidto}) {
    $where .= " AND acc.transdate <= '$form->{datepaidto}'";
  }
  if ($form->{"$form->{vc}_id"}) {
    $where .= qq| AND vc.id = $form->{"$form->{vc}_id"}|;
  }
  $query .= qq| $where ORDER BY acc.source|;

  $sth = $dbh->prepare($query);

  # check if void
  $query = qq|SELECT SUM(acc.amount) * $ml AS amount, vc.id
              FROM acc_trans acc
              JOIN $arap a ON (a.id = acc.trans_id)
              JOIN $form->{vc} vc ON (vc.id = a.$form->{vc}_id)
              WHERE acc.fx_transaction = '0'
              AND acc.source = ?
              AND acc.chart_id = ?
              GROUP BY vc.id|;
  my $ach = $dbh->prepare($query);

  # printed
  my $formname = ($form->{ARAP} eq 'AP') ? 'check' : 'payment';
  $query = qq|SELECT printed
              FROM status
              WHERE formname LIKE '$formname'
              AND printed
              AND trans_id = ?|;
  my $pth = $dbh->prepare($query);

  my $accno;
  ($accno) = split /--/, $form->{accno};
  if ($accno) {
    @accno = grep { $_->{accno} eq $accno } @accno;
  }

  my $samesource;
  my %source;
  my %inv;
  my (undef, $option) = split /--/, $form->{option};

  for (@accno) {
    $sth->execute($_->{id});

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      if ($form->{checknumberfrom}) {
        next if $ref->{source} < $form->{checknumberfrom};
      }
      if ($form->{checknumberto}) {
        next if $ref->{source} > $form->{checknumberto};
      }

      if ($option eq 'all') { 
        if ($ref->{amount}) {
          $ach->execute($ref->{source}, $_->{id});
          ($amount) = $ach->fetchrow_array;
          $ach->finish;
          if ($form->round_amount($amount,10) == 0) {
            $ref->{amount} = 0;
            next if $inv{$ref->{trans_id}};
            $inv{$ref->{trans_id}} = 1;
            $ref->{void} = 1;
          }
        }
      } elsif ($option eq 'void') {
        $ach->execute($ref->{source}, $_->{id});
        ($amount) = $ach->fetchrow_array;
        $ach->finish;
        next if ($ref->{amount} > 0);
        $ref->{amount} = 0;
        next if $form->round_amount($amount,10);
      } elsif ($option eq 'exclude') {
        $ach->execute($ref->{source}, $_->{id});
        ($amount) = $ach->fetchrow_array;
        $ach->finish;
        next if ($form->round_amount($amount,10) == 0);
      } elsif ($option eq 'printed') {
        $pth->execute($ref->{trans_id});
        ($ok) = $pth->fetchrow_array;
        $pth->finish;
        next unless $ok;

        $ach->execute($ref->{source}, $_->{id});
        ($amount) = $ach->fetchrow_array;
        $ach->finish;
        next if ($form->round_amount($amount,10) == 0);

      } elsif ($option eq 'notprinted') {
        $pth->execute($ref->{trans_id});
        ($ok) = $pth->fetchrow_array;
        $pth->finish;
        next if $ok;

        $ach->execute($ref->{source}, $_->{id});
        ($amount) = $ach->fetchrow_array;
        $ach->finish;
        next if ($form->round_amount($amount,10) == 0);

      }

      $ref->{datetonum} = $form->datetonum($myconfig, $ref->{datepaid});

      $form->{"$_->{accno}"} = "$_->{accno}--$_->{description}";

      if ($ref->{source} && $ref->{source} eq $samesource) {
        $i = @{ $source{$_->{accno}} };
        $source{$_->{accno}}[$i-1]->{amount} += $ref->{amount};
        $source{$_->{accno}}[$i-1]->{trans_id} .= "\n$ref->{trans_id}";
      } else {
        push @{ $source{$_->{accno}} }, $ref;
      }

      $samesource = $ref->{source};
    }
    $sth->finish;
  }

  for (keys %source) {
    for $ref (sort { sortsource($a, $b, $form) } @{ $source{$_} }) {
      push @{ $form->{CHK}{$_} }, $ref;
    }
  }

  $dbh->disconnect;

}


sub sortsource {
  my ($a, $b, $form) = @_;

  if ($form->{sort} eq 'datepaid') {
    if ($form->{direction} eq 'DESC') {
      return $b->{datetonum} <=> $a->{datetonum};
    }
    return $a->{datetonum} <=> $b->{datetonum};
  }

  if ($form->{sort} eq 'source') {
    if ($form->{direction} eq 'DESC') {
      return $b->{source} <=> $a->{source};
    }
    return $a->{source} <=> $b->{source};
  }

  if ($form->{direction} eq 'DESC') {
    return $b->{$form->{sort}} cmp $a->{$form->{sort}};
  }
  return $a->{$form->{sort}} cmp $b->{$form->{sort}};

}


sub void_payments {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query = qq|SELECT SUM(acc.amount), MAX(acc.id), acc.project_id,
                 acc.chart_id
                 FROM acc_trans acc
                 JOIN chart c ON (c.id = acc.chart_id)
                 WHERE fx_transaction = '0'
                 AND c.accno = ?
                 AND acc.trans_id = ?
                 AND acc.source = ?
                 GROUP BY acc.project_id, acc.chart_id|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|INSERT INTO acc_trans
              (trans_id, chart_id, amount, source, project_id, id)
              VALUES (?, ?, ?, ?, ?, ?)|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);

  my $arap = lc $form->{ARAP};

  for (1 .. $form->{rowcount}) {
    if ($form->{"id_$_"}) {
      for my $trans_id (split /\n/, $form->{"id_$_"}) {
        $sth->execute($form->{"accno_$_"}, $trans_id, $form->{"source_$_"});
        my ($amount, $id, $project_id, $chart_id) = $sth->fetchrow_array;
        $sth->finish;

        $amount *= -1;
        $id++;
        $ath->execute($trans_id, $chart_id, $amount, $form->{"source_$_"}, $project_id, $id);
        $ath->finish;

        $form->update_balance($dbh,
                              $arap,
                              "paid",
                              qq|id = $trans_id|,
                              $amount);
      }
    }
  }

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub create_selects {
  my ($self, $myconfig, $form) = @_;

  my ($query, $sth);

  my $dbh = $form->dbconnect($myconfig);

  $form->get_peripherals($dbh);

  $form->all_languages($myconfig, $dbh);

  $query = qq|SELECT id FROM chart WHERE accno = '$form->{"accno_1"}'|;
  ($chart_id) = $dbh->selectrow_array($query);

  my %defaults = $form->get_defaults($dbh, \@{["chknumber_${chart_id}"]});
  $form->{source} = $defaults{"chknumber_${chart_id}"} + 1;

  $dbh->disconnect;

}


sub reissue_payment {
  my ($self, $myconfig, $form, $i) = @_;

  my $dbh = $form->dbconnect_noauto($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};

  my $query;
  my $sth;
  my $tth;
  my $ath;
  my $zth;
  my $ref;
  my $trans_id;

  my $rc = 0;
  my $arap = lc $form->{ARAP};

  # retrieve name, address
  $query = qq|SELECT vc.*, ad.*, current_date AS datepaid
              FROM $form->{vc} vc
              JOIN address ad ON (ad.trans_id = vc.id)
              WHERE vc.id = $form->{"$form->{vc}_id"}|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  $ref = $sth->fetchrow_hashref(NAME_lc);
  for (qw(name address1 address2 city state zipcode country datepaid)) { $form->{$_} = $ref->{$_} }
  $sth->finish;

  # invoices
  $query = qq|SELECT a.*, a.transdate AS invdate
              FROM $arap a
              WHERE a.id = ?|;
  $sth = $dbh->prepare($query);

  $query = qq|SELECT id
              FROM chart
              WHERE accno = '$form->{"accno_$i"}'|;
  my ($chart_id) = $dbh->selectrow_array($query);

  # update acc_trans for each trans_id
  $query = qq|UPDATE acc_trans SET
              source = '$form->{source}',
              transdate = '$form->{datepaid}'
              WHERE source = '$form->{"source_$i"}'
              AND fx_transaction = '0'
              AND trans_id = ?
              AND chart_id = $chart_id|;
  $tth = $dbh->prepare($query);

  $query = qq|UPDATE $arap
              SET datepaid = '$form->{datepaid}'
              WHERE id = ?|;
  $ath = $dbh->prepare($query);

  # amount of check for each invoice
  $query = qq|SELECT SUM(amount)
              FROM acc_trans
              WHERE fx_transaction = '0'
              AND trans_id = ?
              AND source = '$form->{"source_$i"}'
              AND chart_id = $chart_id|;
  $zth = $dbh->prepare($query);

  $form->{amount} = 0;
  for (qw(invnumber invdescription invdate due paid)) { @{ $form->{$_} } = () }

  for $trans_id (split /\n/, $form->{"id_$i"}) {

    $zth->execute($trans_id);
    $paid = 0;
    while ($amount = $zth->fetchrow_array) {
      $form->{amount} += $amount;
      $paid += $amount;
    }
    $zth->finish;

    $sth->execute($trans_id);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{due} = $form->format_amount($myconfig, $ref->{amount}, $form->{precision});
      $ref->{paid} = $form->format_amount($myconfig, $paid, $form->{precision});
      for (qw(invnumber invdescription invdate due paid)) { push @{ $form->{$_} }, $ref->{$_} }
    }
    $sth->finish;

    # update source, datepaid
    $tth->execute($trans_id);
    $tth->finish;

    # update datepaid
    $ath->execute($trans_id);
    $ath->finish;
  }

  $form->{"source_$i"} = $form->{source};

  my $chkno = ($form->{ARAP} eq 'AP') ? qq|chknumber_$form->{"accno_$i"}| : qq|receipt_$form->{"accno_$i"}|;
  # record last check number
  $form->update_defaults($myconfig, $chkno, $dbh, $form->{source});

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}



1;

