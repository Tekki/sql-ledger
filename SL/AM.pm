#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Administration module
#    Chart of Accounts
#    template routines
#    preferences
#
#======================================================================

package AM;


sub get_account {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{id} *= 1;
  
  my $query = qq|SELECT accno, description, charttype, gifi_accno,
                 category, link, contra, closed
                 FROM chart
	         WHERE id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;

  # get default accounts
  my %defaults = $form->get_defaults($dbh, \@{['%accno_id']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  # check if we have any transactions
  $query = qq|SELECT trans_id FROM acc_trans
              WHERE chart_id = $form->{id}|;
  ($form->{orphaned}) = $dbh->selectrow_array($query);
  $form->{orphaned} = !$form->{orphaned};

  $dbh->disconnect;

}


sub save_account {
  my ($self, $myconfig, $form, $dbh) = @_;

  my $disconnect;
  
  # connect to database, turn off AutoCommit
  if (! $dbh) {
    $disconnect = 1;
    $dbh = $form->dbconnect_noauto($myconfig);
  }

  $form->{link} = "";
  foreach my $item ($form->{AR},
		    $form->{AR_amount},
                    $form->{AR_tax},
                    $form->{AR_paid},
		    $form->{AR_discount},
                    $form->{AP},
		    $form->{AP_amount},
		    $form->{AP_tax},
		    $form->{AP_paid},
		    $form->{AP_discount},
		    $form->{IC},
		    $form->{IC_income},
		    $form->{IC_sale},
		    $form->{IC_expense},
		    $form->{IC_cogs},
		    $form->{IC_taxpart},
		    $form->{IC_taxservice},
		    ) {
     $form->{link} .= "${item}:" if ($item);
  }
  chop $form->{link};

  # strip blanks from accno
  for (qw(accno gifi_accno)) { $form->{$_} =~ s/( |')//g }
  
  foreach my $item (qw(accno gifi_accno description)) {
    $form->{$item} =~ s/-(-+)/-/g;
    $form->{$item} =~ s/ ( )+/ /g;
    $form->{$item} =~ s/^\s+//;
    $form->{$item} =~ s/\s+$//;
  }
  
  my $query;
  my $sth;
  
  $form->{contra} *= 1;
  $form->{closed} *= 1;
  
  # if we have an id then replace the old record
  if ($form->{id} *= 1) {
    $query = qq|UPDATE chart SET
                accno = '$form->{accno}',
		description = |.$dbh->quote($form->{description}).qq|,
		charttype = '$form->{charttype}',
		gifi_accno = '$form->{gifi_accno}',
		category = '$form->{category}',
		link = '$form->{link}',
		contra = '$form->{contra}',
                closed = '$form->{closed}'
		WHERE id = $form->{id}|;
  } else {
    $query = qq|INSERT INTO chart 
                (accno, description, charttype, gifi_accno, category, link,
		contra, closed)
                VALUES ('$form->{accno}',|
		.$dbh->quote($form->{description}).qq|,
		'$form->{charttype}', |
		.$dbh->quote($form->{gifi_accno}).qq|,
		'$form->{category}', '$form->{link}', '$form->{contra}',
                '$form->{closed}')|;
  }
  $dbh->do($query) || $form->dberror($query);


  $chart_id = $form->{id};

  if (! $form->{id}) {
    # get id from chart
    $query = qq|SELECT id
		FROM chart
		WHERE accno = '$form->{accno}'|;
    ($chart_id) = $dbh->selectrow_array($query);
  }

  if ($form->{IC_taxpart} || $form->{IC_taxservice} || $form->{AR_tax} || $form->{AP_tax}) {
   
    # add account if it doesn't exist in tax
    $query = qq|SELECT chart_id
                FROM tax
		WHERE chart_id = $chart_id|;
    my ($tax_id) = $dbh->selectrow_array($query);
    
    # add tax if it doesn't exist
    unless ($tax_id) {
      $query = qq|INSERT INTO tax (chart_id, rate)
                  VALUES ($chart_id, 0)|;
      $dbh->do($query) || $form->dberror($query);
    }
  } else {
    # remove tax
    if ($form->{id}) {
      $query = qq|DELETE FROM tax
		  WHERE chart_id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);
    }
  }

  # update taxpart and taxservice
  if ($form->{oldIC_taxpart} ne $form->{IC_taxpart}) {
    $query = qq|DELETE FROM partstax
                WHERE parts_id IN (SELECT id FROM parts
                                   WHERE inventory_accno_id > 0)
                AND chart_id = $chart_id|;
    $dbh->do($query) || $form->dberror($query);

    if ($form->{IC_taxpart}) {
      $query = qq|INSERT INTO partstax
                  SELECT id, $chart_id FROM parts
                  WHERE inventory_accno_id > 0|;
      $dbh->do($query) || $form->dberror($query);
    }
  }

  if ($form->{oldIC_taxservice} ne $form->{IC_taxservice}) {
    $query = qq|DELETE FROM partstax
                WHERE parts_id IN (SELECT id FROM parts
                                   WHERE inventory_accno_id IS NULL)
                AND chart_id = $chart_id|;
    $dbh->do($query) || $form->dberror($query);

    if ($form->{IC_taxservice}) {
      $query = qq|INSERT INTO partstax
                  SELECT id, $chart_id FROM parts
                  WHERE inventory_accno_id IS NULL|;
      $dbh->do($query) || $form->dberror($query);
    }
  }

  my %audittrail = ( tablename  => 'chart',
                     reference  => $form->{accno},
		     formname   => '',
		     action     => 'saved',
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);

  # commit
  my $rc = $dbh->commit;
  $dbh->disconnect if $disconnect;

  $rc;
  
}



sub delete_account {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my $query;
  
  $form->{id} *= 1;
  
  # set inventory_accno_id, income_accno_id, expense_accno_id to defaults
  my %defaults = $form->get_defaults($dbh, \@{['%_accno_id']});
  
  for (qw(inventory_accno_id income_accno_id expense_accno_id)) {
    $query = qq|SELECT count(*)
                FROM parts
		WHERE $_ = $defaults{$_}|;
    if ($dbh->selectrow_array($query)) {
      if ($defaults{$_}) {
	$query = qq|UPDATE parts
		    SET $_ = $defaults{$_}
		    WHERE $_ = $form->{id}|;
	$dbh->do($query) || $form->dberror($query);
      } else {
	$dbh->disconnect;
	return;
      }
    }
  }
  
  # delete chart of account record
  $query = qq|DELETE FROM chart
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM bank
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM address
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM translation
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  foreach my $table (qw(partstax customertax vendortax tax)) {
    $query = qq|DELETE FROM $table
		WHERE chart_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  my %audittrail = ( tablename  => 'chart',
                     reference  => $form->{accno},
		     formname   => '',
		     action     => 'deleted',
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);

  # commit and redirect
  my $rc = $dbh->commit;
  $dbh->disconnect;
  
  $rc;

}


sub gifi_accounts {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT accno, description
                 FROM gifi
		 ORDER BY accno|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}



sub get_gifi {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT accno, description
                 FROM gifi
	         WHERE accno = |.$dbh->quote($form->{accno});

  ($form->{accno}, $form->{description}) = $dbh->selectrow_array($query);

  # check for transactions
  $query = qq|SELECT * FROM acc_trans a
              JOIN chart c ON (a.chart_id = c.id)
	      JOIN gifi g ON (c.gifi_accno = g.accno)
	      WHERE g.accno = |.$dbh->quote($form->{accno});
  ($form->{orphaned}) = $dbh->selectrow_array($query);
  $form->{orphaned} = !$form->{orphaned};

  $dbh->disconnect;

}


sub save_gifi {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{accno} =~ s/( |')//g;
  
  foreach my $item (qw(accno description)) {
    $form->{$item} =~ s/-(-+)/-/g;
    $form->{$item} =~ s/ ( )+/ /g;
  }

  # id is the old account number!
  if ($form->{id} *= 1) {
    $query = qq|UPDATE gifi SET
                accno = '$form->{accno}',
		description = |.$dbh->quote($form->{description}).qq|
		WHERE accno = '$form->{id}'|;
  } else {
    $query = qq|INSERT INTO gifi 
                (accno, description)
                VALUES (|
		.$dbh->quote($form->{accno}).qq|,|
		.$dbh->quote($form->{description}).qq|)|;
  }
  $dbh->do($query) || $form->dberror; 
  
  my %audittrail = ( tablename  => 'gifi',
                     reference  => $form->{accno},
		     formname   => '',
		     action     => 'saved',
		     id         => 1 );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  $dbh->disconnect;

}


sub delete_gifi {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;
  
  # id is the old account number!
  $query = qq|DELETE FROM gifi
	      WHERE accno = '$form->{id}'|;
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'gifi',
                     reference  => $form->{id},
		     formname   => '',
		     action     => 'deleted',
		     id         => 1 );
  
  $form->audittrail($dbh, "", \%audittrail);
  
  $dbh->disconnect;

}


sub warehouses {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT w.id, w.description,
                 a.address1, a.address2, a.city, a.state, a.zipcode, a.country
                 FROM warehouse w
		 JOIN address a ON (a.trans_id = w.id)
		 ORDER BY w.rn|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}



sub get_warehouse {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;
  
  my $query = qq|SELECT w.description, a.address1, a.address2, a.city,
                 a.state, a.zipcode, a.country
                 FROM warehouse w
		 JOIN address a ON (a.trans_id = w.id)
	         WHERE w.id = $form->{id}|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  
  my $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;

  # see if it is in use
  $query = qq|SELECT * FROM inventory
              WHERE warehouse_id = $form->{id}|;
  ($form->{orphaned}) = $dbh->selectrow_array($query);
  $form->{orphaned} = !$form->{orphaned};

  $dbh->disconnect;

}


sub save_warehouse {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{description} =~ s/-(-)+/-/g;
  $form->{description} =~ s/ ( )+/ /g;

  if ($form->{id} *= 1) {
    $query = qq|SELECT id
                FROM warehouse
		WHERE id = $form->{id}|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }

  if (!$form->{id}) {
    $uid = localtime;
    $uid .= $$;

    $query = qq|SELECT MAX(rn) FROM warehouse|;
    my ($rn) = $dbh->selectrow_array($query);
    $rn++;
    
    $query = qq|INSERT INTO warehouse (description, rn)
                VALUES ('$uid', $rn)|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id
                FROM warehouse
		WHERE description = '$uid'|;
    ($form->{id}) = $dbh->selectrow_array($query);

    $query = qq|INSERT INTO address (trans_id)
                VALUES ($form->{id})|;
    $dbh->do($query) || $form->dberror($query);
    
  }
   
  $query = qq|UPDATE warehouse SET
	      description = |.$dbh->quote($form->{description}).qq|
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|UPDATE address SET
              address1 = |.$dbh->quote($form->{address1}).qq|,
              address2 = |.$dbh->quote($form->{address2}).qq|,
              city = |.$dbh->quote($form->{city}).qq|,
              state = |.$dbh->quote($form->{state}).qq|,
              zipcode = |.$dbh->quote($form->{zipcode}).qq|,
              country = |.$dbh->quote($form->{country}).qq|
	      WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'warehouse',
                     reference  => $form->{description},
		     formname   => '',
		     action     => 'saved',
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub delete_warehouse {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{id} *= 1;
  
  &reorder_rn("", $dbh, "warehouse", $form->{id});

  my $query = qq|DELETE FROM warehouse
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|DELETE FROM address
	      WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  my %audittrail = ( tablename  => 'warehouse',
                     reference  => $form->{description},
		     formname   => '',
		     action     => 'deleted',
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);
  
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}



sub departments {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT id, description, role
                 FROM department
		 ORDER BY rn|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}



sub get_department {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;
  
  my $query = qq|SELECT description, role
                 FROM department
	         WHERE id = $form->{id}|;
  ($form->{description}, $form->{role}) = $dbh->selectrow_array($query);
  
  # see if it is in use
  $query = qq|SELECT * FROM dpt_trans
              WHERE department_id = $form->{id}|;
  ($form->{orphaned}) = $dbh->selectrow_array($query);
  $form->{orphaned} = !$form->{orphaned};

  $dbh->disconnect;

}


sub save_department {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{description} =~ s/-(-)+/-/g;
  $form->{description} =~ s/ ( )+/ /g;

  if ($form->{id} *= 1) {
    $query = qq|UPDATE department SET
		description = |.$dbh->quote($form->{description}).qq|,
		role = '$form->{role}'
		WHERE id = $form->{id}|;
  } else {
    $query = qq|SELECT MAX(rn) FROM department|;
    my ($rn) = $dbh->selectrow_array($query);
    $rn++;
 
    $query = qq|INSERT INTO department 
                (description, role, rn)
                VALUES (|
		.$dbh->quote($form->{description}).qq|, '$form->{role}', $rn)|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'department',
                     reference  => $form->{description},
		     formname   => '',
		     action     => 'saved',
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);
  
  $dbh->disconnect;

}


sub delete_department {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;
  
  &reorder_rn("", $dbh, "department", $form->{id});

  $query = qq|DELETE FROM department
	      WHERE id = $form->{id}|;
  $dbh->do($query);
  
  my %audittrail = ( tablename  => 'department',
                     reference  => $form->{description},
		     formname   => '',
		     action     => 'deleted',
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);
  
  $dbh->disconnect;

}


sub business {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT id, description, discount
                 FROM business
		 ORDER BY rn|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}



sub get_business {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;

  my $query = qq|SELECT description, discount
                 FROM business
	         WHERE id = $form->{id}|;
  ($form->{description}, $form->{discount}) = $dbh->selectrow_array($query);

  $dbh->disconnect;

}


sub save_business {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{description} =~ s/-(-)+/-/g;
  $form->{description} =~ s/ ( )+/ /g;
  $form->{discount} /= 100;
  
  if ($form->{id} *= 1) {
    $query = qq|UPDATE business SET
		description = |.$dbh->quote($form->{description}).qq|,
		discount = $form->{discount}
		WHERE id = $form->{id}|;
  } else {
    $query = qq|SELECT MAX(rn) FROM business|;
    my ($rn) = $dbh->selectrow_array($query);
    $rn++;
 
    $query = qq|INSERT INTO business 
                (description, discount, rn)
		VALUES (|
		.$dbh->quote($form->{description}).qq|, $form->{discount}, $rn)|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'business',
                     reference  => $form->{description},
		     formname   => '',
		     action     => 'saved',
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);
  
  $dbh->disconnect;

}


sub delete_business {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;

  &reorder_rn("", $dbh, "business", $form->{id});

  $query = qq|DELETE FROM business
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'business',
                     reference  => $form->{description},
		     formname   => '',
		     action     => 'deleted',
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);
  
  $dbh->disconnect;

}


sub paymentmethod {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  $form->{sort} ||= "rn";
 
  my @sf = qw(description rn);
  my %ordinal = ( description	=> 2,
                  rn		=> 4 );
  my $sortorder = $form->sort_order(\@sf, \%ordinal);

  my $query = qq|SELECT *
                 FROM paymentmethod
		 ORDER BY $sortorder|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}



sub get_paymentmethod {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};
  
  my $query = qq|SELECT description, fee, roundchange
                 FROM paymentmethod
	         WHERE id = $form->{id}|;
  ($form->{description}, $form->{fee}, $form->{roundchange}) = $dbh->selectrow_array($query);

  $dbh->disconnect;

}


sub save_paymentmethod {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{description} =~ s/-(-)+/-/g;
  $form->{description} =~ s/ ( )+/ /g;

  $form->{roundchange} *= 1;
  
  if ($form->{id} *= 1) {
    $query = qq|UPDATE paymentmethod SET
		description = |.$dbh->quote($form->{description}).qq|,
		roundchange = $form->{roundchange},
		fee = |.$form->parse_amount($myconfig, $form->{fee}).qq|
		WHERE id = $form->{id}|;
  } else {
    $query = qq|SELECT MAX(rn) FROM paymentmethod|;
    my ($rn) = $dbh->selectrow_array($query);
    $rn++;
    
    $query = qq|INSERT INTO paymentmethod 
                (rn, description, fee, roundchange)
		VALUES ($rn, |
		.$dbh->quote($form->{description}).qq|, |.
		$form->parse_amount($myconfig, $form->{fee})
		.qq|, $form->{roundchange}|.qq|)|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'paymentmethod',
                     reference  => $form->{description},
		     formname   => '',
		     action     => 'saved',
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  $dbh->disconnect;

}


sub delete_paymentmethod {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;
  
  &reorder_rn("", $dbh, "paymentmethod", $form->{id});
 
  my $query = qq|DELETE FROM paymentmethod
 	         WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'paymentmethod',
                     reference  => $form->{description},
		     formname   => '',
		     action     => 'deleted',
		     id         => $form->{id} );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  $dbh->disconnect;

}


sub reorder_rn {
  my ($self, $dbh, $db, $id) = @_;

  my $query = qq|SELECT rn FROM $db
                 WHERE id = $id|;
  my ($rn) = $dbh->selectrow_array($query);
  
  $query = qq|UPDATE $db SET rn = rn - 1
              WHERE rn > $rn|;
  $dbh->do($query) || $form->dberror($query);

}


sub sic {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{sort} = "code" unless $form->{sort};
  my @sf = qw(code description);
  my %ordinal = ( code		=> 1,
                  description	=> 3 );
  my $sortorder = $form->sort_order(\@sf, \%ordinal);
  my $query = qq|SELECT code, sictype, description
                 FROM sic
		 ORDER BY $sortorder|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}



sub get_sic {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT code, sictype, description
                 FROM sic
	         WHERE code = |.$dbh->quote($form->{code});
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;

  $dbh->disconnect;

}


sub save_sic {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  foreach my $item (qw(code description)) {
    $form->{$item} =~ s/-(-)+/-/g;
  }
 
  # if there is an id
  if ($form->{id}) {
    $query = qq|UPDATE sic SET
                code = |.$dbh->quote($form->{code}).qq|,
		sictype = '$form->{sictype}',
		description = |.$dbh->quote($form->{description}).qq|
		WHERE code = |.$dbh->quote($form->{id});
  } else {
    $query = qq|INSERT INTO sic 
                (code, sictype, description)
                VALUES (|
		.$dbh->quote($form->{code}).qq|,
		'$form->{sictype}',|
		.$dbh->quote($form->{description}).qq|)|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'sic',
                     reference  => $form->{code},
		     formname   => '',
		     action     => 'saved',
		     id         => 1 );
  
  $form->audittrail($dbh, "", \%audittrail);
  
  $dbh->disconnect;

}


sub delete_sic {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $query = qq|DELETE FROM sic
	      WHERE code = |.$dbh->quote($form->{code});
  $dbh->do($query);
  
  my %audittrail = ( tablename  => 'sic',
                     reference  => $form->{code},
		     formname   => '',
		     action     => 'deleted',
		     id         => 1 );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  $dbh->disconnect;

}


sub language {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{sort} = "code" unless $form->{sort};
  my @sf = qw(code description);
  my %ordinal = ( code		=> 1,
                  description	=> 2 );
  my $sortorder = $form->sort_order(\@sf, \%ordinal);
  
  my $query = qq|SELECT code, description
                 FROM language
		 ORDER BY $sortorder|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}



sub get_language {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT *
                 FROM language
	         WHERE code = |.$dbh->quote($form->{code});
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;

  $dbh->disconnect;

}


sub save_language {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{code} =~ s/ //g;
  for (qw(code description)) {
    $form->{$_} =~ s/-(-)+/-/g;
    $form->{$_} =~ s/ ( )+/-/g;
  }
  
  # if there is an id
  if ($form->{id}) {
    $query = qq|UPDATE language SET
                code = |.$dbh->quote($form->{code}).qq|,
		description = |.$dbh->quote($form->{description}).qq|
		WHERE code = |.$dbh->quote($form->{id});
  } else {
    $query = qq|INSERT INTO language
                (code, description)
                VALUES (|
		.$dbh->quote($form->{code}).qq|,|
		.$dbh->quote($form->{description}).qq|)|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'language',
                     reference  => $form->{code},
		     formname   => '',
		     action     => 'saved',
		     id         => 1 );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  $dbh->disconnect;

}


sub delete_language {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $query = qq|DELETE FROM language
	      WHERE code = |.$dbh->quote($form->{code});
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'language',
                     reference  => $form->{code},
		     formname   => '',
		     action     => 'deleted',
		     id         => 1 );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  $dbh->disconnect;

}


sub mimetypes {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{sort} = "extension" unless $form->{sort};
  my @sf = qw(extension contenttype);
  my %ordinal = ( extension	=> 1,
                  contenttype	=> 2 );
  my $sortorder = $form->sort_order(\@sf, \%ordinal);
  
  my $query = qq|SELECT extension, contenttype
                 FROM mimetype
		 ORDER BY $sortorder|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub save_mimetype {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{extension} =~ s/(\s|\W)//g;

  my $query = qq|SELECT extension FROM mimetype
                 WHERE extension = ?|;
  my $sth = $dbh->prepare($query);
  $sth->execute($form->{extension}) || $form->dberror($query);
  my ($ok) = $sth->fetchrow_array;
  $sth->finish;

  if ($ok) {
    $query = qq|UPDATE mimetype SET
		contenttype = ?
		WHERE extension = ?|;
  } else {
    $query = qq|INSERT INTO mimetype
                (contenttype, extension)
                VALUES (?, ?)|;
  }

  $sth = $dbh->prepare($query);
  $sth->execute($form->{contenttype}, $form->{extension}) || $form->dberror($query);
  $sth->finish;

  my %audittrail = ( tablename  => 'mimetype',
                     reference  => $form->{extension},
		     formname   => '',
		     action     => 'saved',
		     id         => 1 );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  $dbh->disconnect;

}


sub delete_mimetype {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $query = qq|DELETE FROM mimetype
	      WHERE extension = |.$dbh->quote($form->{extension});
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename  => 'mimetype',
                     reference  => $form->{extension},
		     formname   => '',
		     action     => 'deleted',
		     id         => 1 );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  $dbh->disconnect;

}



sub recurring_transactions {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  # get default currency
  $query = qq|SELECT curr FROM curr
              ORDER BY rn|;
  my ($defaultcurrency) = $dbh->selectrow_array($query);
 
  $query = qq|SELECT 'ar' AS module, 'ar' AS transaction, a.invoice,
                 a.description, n.name, n.customernumber AS vcnumber,
		 n.id AS name_id, a.amount, s.*, se.formname AS recurringemail,
                 sp.formname AS recurringprint,
		 s.nextdate - current_date AS overdue, 'customer' AS vc,
		 ex.exchangerate, a.curr,
		 (s.nextdate IS NULL OR s.nextdate > s.enddate) AS expired
                 FROM recurring s
		 JOIN ar a ON (a.id = s.id)
		 JOIN customer n ON (n.id = a.customer_id)
                 LEFT JOIN recurringemail se ON (se.id = s.id)
                 LEFT JOIN recurringprint sp ON (sp.id = s.id)
		 LEFT JOIN exchangerate ex ON
		      (ex.curr = a.curr AND a.transdate = ex.transdate)

	 UNION

                 SELECT 'ap' AS module, 'ap' AS transaction, a.invoice,
		 a.description, n.name, n.vendornumber AS vcnumber,
		 n.id AS name_id, a.amount, s.*, se.formname AS recurringemail,
                 sp.formname AS recurringprint,
		 s.nextdate - current_date AS overdue, 'vendor' AS vc,
		 ex.exchangerate, a.curr,
		 (s.nextdate IS NULL OR s.nextdate > s.enddate) AS expired
                 FROM recurring s
		 JOIN ap a ON (a.id = s.id)
		 JOIN vendor n ON (n.id = a.vendor_id)
                 LEFT JOIN recurringemail se ON (se.id = s.id)
                 LEFT JOIN recurringprint sp ON (sp.id = s.id)
		 LEFT JOIN exchangerate ex ON
		      (ex.curr = a.curr AND a.transdate = ex.transdate)
	
	 UNION

                 SELECT 'gl' AS module, 'gl' AS transaction, FALSE AS invoice,
		 a.description, '' AS name, '' AS vcnumber, 0 AS name_id,
		 (SELECT SUM(ac.amount) FROM acc_trans ac WHERE ac.trans_id = a.id AND ac.amount > 0) AS amount,
                 s.*, se.formname AS recurringemail,
                 sp.formname AS recurringprint,
		 s.nextdate - current_date AS overdue, '' AS vc,
		 '1' AS exchangerate, '$defaultcurrency' AS curr,
		 (s.nextdate IS NULL OR s.nextdate > s.enddate) AS expired
                 FROM recurring s
		 JOIN gl a ON (a.id = s.id)
                 LEFT JOIN recurringemail se ON (se.id = s.id)
                 LEFT JOIN recurringprint sp ON (sp.id = s.id)
	
	UNION

                 SELECT 'oe' AS module, 'so' AS transaction, FALSE AS invoice,
		 a.description, n.name, n.customernumber AS vcnumber,
		 n.id AS name_id, a.amount, s.*, se.formname AS recurringemail,
                 sp.formname AS recurringprint,
		 s.nextdate - current_date AS overdue, 'customer' AS vc,
		 ex.exchangerate, a.curr,
		 (s.nextdate IS NULL OR s.nextdate > s.enddate) AS expired
                 FROM recurring s
		 JOIN oe a ON (a.id = s.id)
		 JOIN customer n ON (n.id = a.customer_id)
                 LEFT JOIN recurringemail se ON (se.id = s.id)
                 LEFT JOIN recurringprint sp ON (sp.id = s.id)
		 LEFT JOIN exchangerate ex ON
		      (ex.curr = a.curr AND a.transdate = ex.transdate)
		 WHERE a.quotation = '0'
		 
	UNION

                 SELECT 'oe' AS module, 'po' AS transaction, FALSE AS invoice,
		 a.description, n.name, n.vendornumber AS vcnumber,
		 n.id AS name_id, a.amount, s.*, se.formname AS recurringemail,
                 sp.formname AS recurringprint,
		 s.nextdate - current_date AS overdue, 'vendor' AS vc,
		 ex.exchangerate, a.curr,
		 (s.nextdate IS NULL OR s.nextdate > s.enddate) AS expired
                 FROM recurring s
		 JOIN oe a ON (a.id = s.id)
		 JOIN vendor n ON (n.id = a.vendor_id)
                 LEFT JOIN recurringemail se ON (se.id = s.id)
                 LEFT JOIN recurringprint sp ON (sp.id = s.id)
		 LEFT JOIN exchangerate ex ON
		      (ex.curr = a.curr AND a.transdate = ex.transdate)
		 WHERE a.quotation = '0'|;

  $form->{sort} ||= "nextdate";
  my @sf = ($form->{sort});
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $id;
  my $transaction;
  my %e = ();
  my %p = ();
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    $ref->{exchangerate} ||= 1;
    
    if ($ref->{id} != $id) {

      if (%e) {
	$form->{transactions}{$transaction}->[$i]->{recurringemail} = "";
	for (keys %e) { $form->{transactions}{$transaction}->[$i]->{recurringemail} .= "${_}:" }
	chop $form->{transactions}{$transaction}->[$i]->{recurringemail};
      }
      if (%p) {
	$form->{transactions}{$transaction}->[$i]->{recurringprint} = "";
	for (keys %p) { $form->{transactions}{$transaction}->[$i]->{recurringprint} .= "${_}:" }
	chop $form->{transactions}{$transaction}->[$i]->{recurringprint};
      }
	 
      %e = ();
      %p = ();
      
      push @{ $form->{transactions}{$ref->{transaction}} }, $ref;
      
      $id = $ref->{id};
      $i = $#{ $form->{transactions}{$ref->{transaction}} };

    }
    
    $transaction = $ref->{transaction};
   
    $e{$ref->{recurringemail}} = 1 if $ref->{recurringemail};
    $p{$ref->{recurringprint}} = 1 if $ref->{recurringprint};
 
  }
  $sth->finish;

  # this is for the last row
  if (%e) {
    $form->{transactions}{$transaction}->[$i]->{recurringemail} = "";
    for (keys %e) { $form->{transactions}{$transaction}->[$i]->{recurringemail} .= "${_}:" }
    chop $form->{transactions}{$transaction}->[$i]->{recurringemail};
  }
  if (%p) {
    $form->{transactions}{$transaction}->[$i]->{recurringprint} = "";
    for (keys %p) { $form->{transactions}{$transaction}->[$i]->{recurringprint} .= "${_}:" }
    chop $form->{transactions}{$transaction}->[$i]->{recurringprint};
  }


  $dbh->disconnect;
  
}


sub recurring_details {
  my ($self, $myconfig, $form, $id) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT s.*, ar.id AS arid, ar.invoice AS arinvoice,
                 ap.id AS apid, ap.invoice AS apinvoice,
		 ar.duedate - ar.transdate AS overdue,
		 ar.datepaid - ar.transdate AS paid,
		 oe.reqdate - oe.transdate AS req,
		 oe.id AS oeid, oe.customer_id, oe.vendor_id
                 FROM recurring s
                 LEFT JOIN ar ON (ar.id = s.id)
		 LEFT JOIN ap ON (ap.id = s.id)
		 LEFT JOIN oe ON (oe.id = s.id)
                 WHERE s.id = $id|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  $form->{vc} = "customer" if $ref->{customer_id};
  $form->{vc} = "vendor" if $ref->{vendor_id};
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;
  
  $form->{invoice} = ($form->{arid} && $form->{arinvoice});
  $form->{invoice} = ($form->{apid} && $form->{apinvoice}) unless $form->{invoice};
  
  $query = qq|SELECT * FROM recurringemail
              WHERE id = $id|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $form->{recurringemail} = "";
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{recurringemail} .= "$ref->{formname}:$ref->{format}:";
    $form->{message} = $ref->{message};
  }
  $sth->finish;
  
  $query = qq|SELECT * FROM recurringprint
              WHERE id = $id|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $form->{recurringprint} = "";
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{recurringprint} .= "$ref->{formname}:$ref->{format}:$ref->{printer}:";
  }
  $sth->finish;
  
  chop $form->{recurringemail};
  chop $form->{recurringprint};
  
  for (qw(arinvoice apinvoice)) { delete $form->{$_} }

  $dbh->disconnect;
  
}


sub update_recurring {
  my ($self, $myconfig, $form, $id) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT repeat, unit
                 FROM recurring
		 WHERE id = $id|;
  my ($repeat, $unit) = $dbh->selectrow_array($query);
  
  my %advance = ( 'Pg' => qq|(date '$form->{nextdate}' + interval '$repeat $unit')|,
              'Sybase' => qq|dateadd($myconfig->{dateformat}, $repeat $unit, $form->{nextdate})|,
                 'DB2' => qq|(date ('$form->{nextdate}') + "$repeat $unit")|,
		 );
  for (qw(PgPP Oracle)) { $interval{$_} = $interval{Pg} }

  # check if it is the last date
  $query = qq|SELECT $advance{$myconfig->{dbdriver}} > enddate
              FROM recurring
	      WHERE id = $id|;
  my ($last_repeat) = $dbh->selectrow_array($query);
  if ($last_repeat) {
    $advance{$myconfig->{dbdriver}} = "NULL";
  }
  
  $query = qq|UPDATE recurring SET
              nextdate = $advance{$myconfig->{dbdriver}}
	      WHERE id = $id|;
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}

 
sub load_template {
  my ($self, $form) = @_;
  
  open(TEMPLATE, "$form->{file}");

  while (<TEMPLATE>) {
    $form->{body} .= $_;
  }

  close(TEMPLATE);

}


sub save_template {
  my ($self, $form) = @_;

  my @f = split /\//, $form->{file};
  my $dir;
  
  pop @f;
  
  for (@f) {
    if ($_) {
      $dir .= "$_\/";
      if (! -d $dir) {
	umask(002);
	mkdir "$dir", oct("771");
      }
    }
  }
  
  open(TEMPLATE, ">$form->{file}") or $form->error("$form->{file} : $!");
  
  # strip 
  $form->{body} =~ s/\r//g;
  chomp $form->{body};
  print TEMPLATE $form->{body};

  close(TEMPLATE);

}


sub save_preferences {
  my ($self, $form, $memberfile, $userspath) = @_;

  my $config = new User $memberfile, $form->{login};
  my $admin = new User $memberfile, "admin\@$config->{dbname}";
  $config->{templates} = $admin->{templates};

  for (keys %$form) {
    $config->{$_} = $form->{$_};
  }

  if ($form->{oldpassword} eq $form->{new_password}) {
    $config->{encrypted} = 1;
  } else {
    $config->{password} = $form->{new_password};
  }

  $config->save_member($memberfile, $userspath);
  $form->{sessioncookie} = $config->{sessioncookie};

  1;

}


sub save_defaults {
  my ($self, $myconfig, $form) = @_;

  for (qw(IC IC_income IC_expense fxgainloss cashovershort)) { ($form->{$_}) = split /--/, $form->{$_} }
  $form->{inventory_accno} = $form->{IC};
  $form->{income_accno} = $form->{IC_income};
  $form->{expense_accno} = $form->{IC_expense};
  $form->{fxgainloss_accno} = $form->{fxgainloss};
  $form->{cashovershort_accno} = $form->{cashovershort};
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  
  $query = qq|DELETE FROM defaults|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|INSERT INTO defaults (fldname, fldvalue)
              VALUES (?, ?)|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  # must be present
  $sth->execute('version', $form->{dbversion}) || $form->dberror;
  $sth->finish;
  
  for (qw(inventory income expense fxgainloss cashovershort)) {
    $query = qq|INSERT INTO defaults (fldname, fldvalue)
                VALUES ('${_}_accno_id', (SELECT id
		                FROM chart
				WHERE accno = '$form->{"${_}_accno"}'))|;
    $dbh->do($query) || $form->dberror($query);
  }
 
  for (qw(glnumber sinumber sonumber vinumber batchnumber vouchernumber ponumber sqnumber rfqnumber employeenumber customernumber vendornumber)) {
    $sth->execute($_, $form->{$_}) || $form->dberror;
    $sth->finish;
  }
  $sth->execute("precision", $form->{precision}) || $form->dberror;
  $sth->finish;


  # optional
  for (split / /, $form->{optional}) {
    if ($form->{$_}) {
      $sth->execute($_, $form->{$_}) || $form->dberror;
      $sth->finish;
    }
  }
  
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}


sub defaultaccounts {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query;
  my $sth;
  
  # get defaults from defaults table
  my %defaults = $form->get_defaults($dbh);

  for (keys %defaults) { $form->{$_} = $defaults{$_} }
  
  $form->{defaults}{IC} = $form->{inventory_accno_id};
  $form->{defaults}{IC_income} = $form->{income_accno_id};
  $form->{defaults}{IC_sale} = $form->{income_accno_id};
  $form->{defaults}{IC_expense} = $form->{expense_accno_id};
  $form->{defaults}{IC_cogs} = $form->{expense_accno_id};
  $form->{defaults}{fxgainloss} = $form->{fxgainloss_accno_id};
  $form->{defaults}{cashovershort} = $form->{cashovershort_accno_id};
  
  $query = qq|SELECT c.id, c.accno, c.description, c.link,
              l.description AS translation
              FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
              WHERE c.link LIKE '%IC%'
              ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $nkey;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    foreach my $key (split(/:/, $ref->{link})) {
      if ($key =~ /IC/) {
	$nkey = $key;
	if ($key =~ /cogs/) {
	  $nkey = "IC_expense";
	}
	if ($key =~ /sale/) {
	  $nkey = "IC_income";
	}
	$ref->{description} = $ref->{translation} if $ref->{translation};

        %{ $form->{accno}{$nkey}{$ref->{accno}} } = ( id => $ref->{id},
                                        description => $ref->{description} );
      }
    }
  }
  $sth->finish;


  $query = qq|SELECT c.id, c.accno, c.description,
              l.description AS translation
              FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE (c.category = 'I' OR c.category = 'E')
	      AND c.charttype = 'A'
              ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};

    %{ $form->{accno}{fxgainloss}{$ref->{accno}} } = ( id => $ref->{id},
                                      description => $ref->{description} );
    %{ $form->{accno}{cashovershort}{$ref->{accno}} } = ( id => $ref->{id},
                                      description => $ref->{description} );
  }
  $sth->finish;
  
  for (qw(AR AP)) {
    $query = qq|SELECT c.id, c.accno, c.description,
		l.description AS translation
		FROM chart c
		LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		WHERE c.link = '$_'
		ORDER BY c.accno|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{description} = $ref->{translation} if $ref->{translation};

      %{ $form->{accno}{$_}{$ref->{accno}} } = ( id => $ref->{id},
					description => $ref->{description} );
    }
    $sth->finish;
  }

  $dbh->disconnect;
  
}


sub taxes {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT c.id, c.accno, c.description, c.closed,
              t.rate * 100 AS rate, t.taxnumber, t.validto,
	      l.description AS translation
              FROM chart c
	      JOIN tax t ON (c.id = t.chart_id)
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      ORDER BY 2, 7|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{taxrates} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub save_taxes {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query = qq|DELETE FROM tax|;
  $dbh->do($query) || $form->dberror($query);

  my %chart;
 
  foreach my $item (split / /, $form->{taxaccounts}) {
    my ($chart_id, $i) = split /_/, $item;
    $chart{$chart_id} = 1;
    my $rate = $form->parse_amount($myconfig, $form->{"taxrate_$i"}) / 100;
    $query = qq|INSERT INTO tax (chart_id, rate, taxnumber, validto)
                VALUES ($chart_id, $rate, |
		.$dbh->quote($form->{"taxnumber_$i"}).qq|, |
		.$form->dbquote($form->{"validto_$i"}, SQL_DATE)
		.qq|)|;
    $dbh->do($query) || $form->dberror($query);
  }

  for (keys %chart) {
    $form->{"closed_$_"} *= 1;
    $query = qq|UPDATE chart SET
                closed = '$form->{"closed_$_"}'
                WHERE id = '$_'|;
    $dbh->do($query) || $form->dberror($query);
  }

  my %audittrail = ( tablename  => 'tax',
                     reference  => '',
		     formname   => '',
		     action     => 'saved',
		     id         => 1 );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
 
}


sub backup {
  my ($self, $myconfig, $form, $userspath, $gzip) = @_;
  
  my $mail;
  my $err;
  
  my @t = localtime;
  $t[4]++;
  $t[5] += 1900;
  $t[3] = substr("0$t[3]", -2);
  $t[4] = substr("0$t[4]", -2);

  my $boundary = time;
  my $tmpfile = "$userspath/$boundary.$myconfig->{dbname}-$form->{version}-$t[5]$t[4]$t[3].sql";
  my $out = $form->{OUT};
  $form->{OUT} = ">$tmpfile";

  open(OUT, "$form->{OUT}") or $form->error("$form->{OUT} : $!");

  # get sequences, functions and triggers
  my %tables;
  my %references;
  my %sequences;
  my @functions;
  my @triggers;
  my @schema;
  
  # get dbversion from -tables.sql
  my $file = "$myconfig->{dbdriver}-tables.sql";

  open(FH, "sql/$file") or $form->error("sql/$file : $!");

  my @file = <FH>;
  close(FH);

  @dbversion = grep /VALUES \(.{1}version.{1}, .*\){1}/, @file;
  
  $dbversion = "@dbversion";
  $dbversion =~ /(\d+\.\d+\.\d+)/;

  $dbversion = User::calc_version($1);

  opendir SQLDIR, "sql/." or $form->error($!);
  @file = grep /$myconfig->{dbdriver}-upgrade-.*?\.sql$/, readdir SQLDIR;
  closedir SQLDIR;

  my $mindb;
  my $maxdb;

  foreach my $line (@file) {

    $upgradescript = $line;
    $line =~ s/(^$myconfig->{dbdriver}-upgrade-|\.sql$)//g;
    
    ($mindb, $maxdb) = split /-/, $line;
    $mindb = User::calc_version($mindb);

    next if $mindb < $dbversion;
    
    $maxdb = User::calc_version($maxdb);
    
    $upgradescripts{$maxdb} = $upgradescript;
  }

  $upgradescripts{$dbversion} = "$myconfig->{dbdriver}-tables.sql";
  $upgradescripts{functions} = "$myconfig->{dbdriver}-functions.sql";

  if (-f "sql/$myconfig->{dbdriver}-custom_tables.sql") {
    $upgradescripts{customtables} = "$myconfig->{dbdriver}-custom_tables.sql";
  }
  if (-f "sql/$myconfig->{dbdriver}-custom_functions.sql") {
    $upgradescripts{customfunctions} = "$myconfig->{dbdriver}-custom_functions.sql";
  }
  
  my $el;
  
  foreach my $key (sort keys %upgradescripts) {

    $file = $upgradescripts{$key};
  
    open(FH, "sql/$file") or $form->error("sql/$file : $!");

    push @schema, qq|-- $file\n|;
   
    while (<FH>) {

      if (/references (\w+)/i) {
	$references{$el} = 1;
      }
      
      if (/create table (\w+)/i) {
	$el = $1;
	$tables{$1} = 1;
      }

      if (/create sequence (\w+)/i) {
	$sequences{$1} = 1;
	next;
      }

      if (/end function/i) {
	push @functions, $_;
	$function = 0;
	$temp = 0;
	next;
      }

      if (/create function /i) {
	$function = 1;
      }
      
      if ($function) {
	push @functions, $_;
	next;
      }

      if (/end trigger/i) {
	push @triggers, $_;
	$trigger = 0;
	next;
      }

      if (/create trigger/i) {
	$trigger = 1;
      }

      if ($trigger) {
	push @triggers, $_;
	next;
      }
      
      push @schema, $_ if $_ !~ /^(insert|--)/i;
      
    }
    close(FH);
    
  }


  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my %audittrail = ( tablename  => '',
                     reference  => $form->{media},
		     formname   => '',
		     action     => 'backup',
		     id         => 1 );
  
  $form->audittrail($dbh, "", \%audittrail);
 
  my $today = scalar localtime;

  $myconfig->{dbhost} = 'localhost' unless $myconfig->{dbhost};
  
  print OUT qq|-- SQL-Ledger Backup
-- Dataset: $myconfig->{dbname}
-- Version: $form->{dbversion}
-- Host: $myconfig->{dbhost}
-- Login: $form->{login}
-- User: $myconfig->{name}
-- Date: $today
--
|;


  # drop references first
  for (keys %references) { print OUT qq|DROP TABLE $_;\n| }
  
  delete $tables{temp};
  # drop tables and sequences
  for (keys %tables) {
    if (! exists $references{$_}) {
      print OUT qq|DROP TABLE $_;\n|;
    }
  }

  print OUT "--\n";
  
  # triggers and index files are dropped with the tables
  
  # drop functions
  foreach $item (@functions) {
    if ($item =~ /create function (.*\))/i) {
      print OUT qq|DROP FUNCTION $1;\n|;
    }
  }
  
  delete $sequences{tempid};
  # create sequences
  foreach $item (keys %sequences) {
    if ($myconfig->{dbdriver} eq 'DB2') {
      $query = qq|SELECT NEXTVAL FOR $item FROM sysibm.sysdummy1|;
    } else {
      $query = qq|SELECT last_value FROM $item|;
    }
    
    my ($id) = $dbh->selectrow_array($query);
  
    if ($myconfig->{dbdriver} eq 'DB2') {
      print OUT qq|DROP SEQUENCE $item RESTRICT
CREATE SEQUENCE $item AS INTEGER START WITH $id INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1 CACHE 5;\n|;
    } else {
      if ($myconfig->{dbdriver} eq 'Pg') {
	print OUT qq|CREATE SEQUENCE $item;
SELECT SETVAL('$item', $id, FALSE);\n|;
      } else {
	print OUT qq|DROP SEQUENCE $item;
CREATE SEQUENCE $item START $id;\n|;
      }
    }
  }
 
  # add schema
  print OUT @schema;
  print OUT "\n";
  
  print OUT qq|-- set options
$myconfig->{dboptions};
--
|;

  my $query;
  my $sth;
  my @arr;
  my $fields;
  
  delete $tables{semaphore};
  
  foreach $table (keys %tables) {

    $query = qq|SELECT * FROM $table|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $query = qq|INSERT INTO $table (|;
    $query .= join ',', (map { $sth->{NAME_lc}->[$_] } (0 .. $sth->{NUM_OF_FIELDS} - 1));
    $query .= qq|) VALUES|;
    
    while (@arr = $sth->fetchrow_array) {

      $fields = "(";
      
      $fields .= join ',', map { $dbh->quote($_) } @arr;
      $fields .= ")";
	
      print OUT qq|$query $fields;\n|;
    }
    
    $sth->finish;
  }

  print OUT "--\n";
  
  # functions
  for (@functions) { print OUT $_ }

  # triggers
  for (@triggers) { print OUT $_ }

  # add the index files
  open(FH, "sql/$myconfig->{dbdriver}-indices.sql");
  @file = <FH>;
  close(FH);
  print OUT @file;
  
  close(OUT);
  
  $dbh->disconnect;

  # compress backup if gzip defined
  my $suffix = "";
  if ($gzip) {
    my @args = split / /, $gzip;
    my @s = @args;

    push @args, "$tmpfile";
    system(@args) == 0 or $form->error("$args[0] : $?");

    shift @s;
    my %s = @s;
    $suffix = ${-S} || ".gz";
    $tmpfile .= $suffix;
  }

  if ($form->{media} eq 'email') {
   
    use SL::Mailer;
    $mail = new Mailer;

    $mail->{charset} = $form->{charset};
    $mail->{to} = qq|"$myconfig->{name}" <$myconfig->{email}>|;
    $mail->{from} = qq|"$myconfig->{name}" <$myconfig->{email}>|;
    $mail->{subject} = "SQL-Ledger Backup / $myconfig->{dbname}-$form->{version}-$t[5]$t[4]$t[3].sql$suffix";
    @{ $mail->{attachments} } = ($tmpfile);
    $mail->{version} = $form->{version};
    $mail->{fileid} = "$boundary.";

    $myconfig->{signature} =~ s/\\n/\n/g;
    $mail->{message} = "-- \n$myconfig->{signature}";
    
    $err = $mail->send($out);
  }
  
  if ($form->{media} eq 'file') {
   
    open(IN, "$tmpfile") or $form->error("$tmpfile : $!");
    open(OUT, ">-") or $form->error("STDOUT : $!");
   
    print OUT qq|Content-Type: application/file;
Content-Disposition: attachment; filename=$myconfig->{dbname}-$form->{version}-$t[5]$t[4]$t[3].sql$suffix\n\n|;

    binmode(IN);
    binmode(OUT);
    
    while (<IN>) {
      print OUT $_;
    }

    close(IN);
    close(OUT);
    
  }

  unlink "$tmpfile";
   
}


sub closedto {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);
  
  my %defaults = $form->get_defaults($dbh, \@{[qw(closedto revtrans audittrail)]});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  $dbh->disconnect;
  
}

 
sub closebooks {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect_noauto($myconfig);
  my $query = qq|DELETE FROM defaults
                 WHERE fldname = ?|;
  my $dth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|INSERT INTO defaults (fldname, fldvalue)
              VALUES (?, ?)|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  $form->{closedto} = $form->datetonum($myconfig, $form->{closedto});
  for (qw(revtrans closedto audittrail)) {
    $dth->execute($_) || $form->dberror;
    $dth->finish;

    if ($form->{$_}) {
      $sth->execute($_, $form->{$_}) || $form->dberror;
      $sth->finish;
    }
  }
      
  if ($form->{removeaudittrail}) {
    $query = qq|DELETE FROM audittrail
                WHERE transdate < '$form->{removeaudittrail}'|;
    $dbh->do($query) || $form->dberror($query);
  }

  $dbh->commit;
  $dbh->disconnect;
  
}


sub earningsaccounts {
  my ($self, $myconfig, $form) = @_;

  my ($query, $sth, $ref);

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  # get chart of accounts
  $query = qq|SELECT c.accno, c.description,
              l.description AS translation
              FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
              WHERE c.charttype = 'A'
	      AND c.category = 'Q'
              ORDER by c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  $form->{chart} = "";
						  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{chart} }, $ref;
  }
  $sth->finish;

  my %defaults = $form->get_defaults($dbh, \@{['method', 'precision']});
  $form->{precision} = $defaults{precision};
  $form->{method} ||= "accrual";
  
  $dbh->disconnect;
      
}


sub post_yearend {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $uid = localtime;
  $uid .= $$;

  my $curr = substr($form->get_currencies($myconfig, $dbh),0,3);
  $query = qq|INSERT INTO gl (reference, employee_id, curr)
	      VALUES ('$uid', (SELECT id FROM employee
			       WHERE login = '$form->{login}'), '$curr')|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|SELECT id FROM gl
	      WHERE reference = '$uid'|;
  ($form->{id}) = $dbh->selectrow_array($query);

  $form->{reference} = $form->update_defaults($myconfig, 'glnumber', $dbh) unless $form->{reference};
  
  $query = qq|UPDATE gl SET 
	      reference = |.$dbh->quote($form->{reference}).qq|,
	      description = |.$dbh->quote($form->{description}).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      transdate = '$form->{transdate}',
	      department_id = 0,
	      exchangerate = 1
	      WHERE id = $form->{id}|;

  $dbh->do($query) || $form->dberror($query);

  my $amount;
  my $accno;
  
  # insert acc_trans transactions
  for my $i (1 .. $form->{rowcount}) {
    # extract accno
    ($accno) = split(/--/, $form->{"accno_$i"});
    $amount = 0;

    if ($form->{"credit_$i"}) {
      $amount = $form->{"credit_$i"};
    }
    if ($form->{"debit_$i"}) {
      $amount = $form->{"debit_$i"} * -1;
    }

    # if there is an amount, add the record
    if ($amount = $form->round_amount($amount, $form->{precision})) {
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
                  source)
		  VALUES
		  ($form->{id}, (SELECT id
		                 FROM chart
				 WHERE accno = '$accno'),
		   $amount, '$form->{transdate}', |
		   .$dbh->quote($form->{reference}).qq|)|;
    
      $dbh->do($query) || $form->dberror($query);
    }
  }

  $query = qq|INSERT INTO yearend (trans_id, transdate)
              VALUES ($form->{id}, '$form->{transdate}')|;
  $dbh->do($query) || $form->dberror($query);

  my %audittrail = ( tablename	=> 'gl',
                     reference	=> $form->{reference},
	  	     formname	=> 'yearend',
		     action	=> 'posted',
		     id		=> $form->{id} );
  $form->audittrail($dbh, "", \%audittrail);
  
  # commit and redirect
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub company_defaults {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my %defaults = $form->get_defaults($dbh, \@{['company','address']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $login = $form->{login};
  $login =~ s/@.*//;
  my $query = qq|SELECT name
                 FROM employee
		 WHERE login = '$login'|;
  ($form->{username}) = $dbh->selectrow_array($query);
  
  $form->{username} ||= 'admin' if $login eq 'admin';
 
  $dbh->disconnect;

}


sub bank_accounts {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT c.id, c.accno, c.description, c.closed,
                 bk.name, bk.iban, bk.bic, bk.membernumber, bk.clearingnumber,
		 bk.dcn, bk.rvc,
		 ad.address1, ad.address2, ad.city,
                 ad.state, ad.zipcode, ad.country,
		 l.description AS translation
                 FROM chart c
		 LEFT JOIN bank bk ON (bk.id = c.id)
		 LEFT JOIN address ad ON (c.id = ad.trans_id)
		 LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		 WHERE c.link LIKE '%_paid%'
		 ORDER BY 2|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{address} = "";
    for (qw(address1 address2 city state zipcode country)) {
      $ref->{address} .= "$ref->{$_}\n" if $ref->{$_};
    }
    chop $ref->{address};

    $ref->{description} = $ref->{translation} if $ref->{translation};

    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub get_bank {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{id} *= 1;
  
  $query = qq|SELECT c.accno, c.description, c.closed,
              bk.name, bk.iban, bk.bic, bk.membernumber, bk.clearingnumber,
	      bk.dcn, bk.rvc,
	      ad.address1, ad.address2, ad.city,
              ad.state, ad.zipcode, ad.country,
	      l.description AS translation
	      FROM chart c
	      LEFT JOIN bank bk ON (c.id = bk.id)
	      LEFT JOIN address ad ON (c.id = ad.trans_id)
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.id = $form->{id}|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $ref = $sth->fetchrow_hashref(NAME_lc);
  $ref->{account} = "$ref->{accno}--";
  $ref->{account} .= ($ref->{translation}) ? $ref->{translation} : $ref->{description};
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;

  my %defaults = $form->get_defaults($dbh, \@{["check\_$form->{accno}", "receipt\_$form->{accno}"]});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  $dbh->disconnect;

}


sub save_bank {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  $form->{id} *= 1;
  
  my $query = qq|SELECT id FROM bank
                 WHERE id = $form->{id}|;
  my ($id) = $dbh->selectrow_array($query);

  $form->{closed} *= 1;
  $query = qq|UPDATE chart SET
              closed = '$form->{closed}'
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  my $ok;
  for (qw(name iban bic address1 address2 city state zipcode country membernumber clearingnumber rvc dcn)) {
    if ($form->{$_}) {
      $ok = 1;
      last;
    }
  }

  my $audittrail;
  

  if ($ok) {
    if ($id) {
      $query = qq|UPDATE bank SET
		  name = |.$dbh->quote(uc $form->{name}).qq|,
		  iban = |.$dbh->quote($form->{iban}).qq|,
		  bic = |.$dbh->quote(uc $form->{bic}).qq|,
		  membernumber = |.$dbh->quote($form->{membernumber}).qq|,
		  clearingnumber = |.$dbh->quote($form->{clearingnumber}).qq|,
		  rvc = |.$dbh->quote($form->{rvc}).qq|,
		  dcn = |.$dbh->quote($form->{dcn}).qq|
		  WHERE id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);
    } else {
      $query = qq|INSERT INTO bank (id, name, iban, bic, membernumber,
                  clearingnumber, rvc, dcn)
		  VALUES ($form->{id}, |
		  .$dbh->quote(uc $form->{name}).qq|, |
		  .$dbh->quote(uc $form->{iban}).qq|, |
		  .$dbh->quote($form->{bic}).qq|, |
		  .$dbh->quote($form->{membernumber}).qq|, |
		  .$dbh->quote($form->{clearingnumber}).qq|, |
		  .$dbh->quote($form->{rvc}).qq|, |
		  .$dbh->quote($form->{dcn}).qq|
		  )|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|SELECT address_id
                  FROM bank
		  WHERE id = $form->{id}|;
      ($id) = $dbh->selectrow_array($query);

      $query = qq|INSERT INTO address (id, trans_id)
		  VALUES ($id, $form->{id})|;
      $dbh->do($query) || $form->dberror($query);
    }
    
    $query = qq|UPDATE address SET
		address1 = |.$dbh->quote(uc $form->{address1}).qq|,
		address2 = |.$dbh->quote(uc $form->{address2}).qq|,
		city = |.$dbh->quote(uc $form->{city}).qq|,
		state = |.$dbh->quote(uc $form->{state}).qq|,
		zipcode = |.$dbh->quote(uc $form->{zipcode}).qq|,
		country = |.$dbh->quote(uc $form->{country}).qq|
		WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
    
    %audittrail = ( tablename  => 'bank',
                    reference  => uc $form->{name},
		    formname   => '',
		    action     => 'saved',
		    id         => $form->{id} );
  
  } else {
    $query = qq|DELETE FROM bank
                WHERE id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|DELETE FROM address
                WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
    
    %audittrail = ( tablename  => 'bank',
                     reference  => uc $form->{name},
		     formname   => '',
		     action     => 'deleted',
		     id         => $form->{id} );

  }

  my ($accno) = split /--/, $form->{account};
  if ($accno) {
    $query = qq|DELETE FROM defaults
                WHERE fldname = ?|;
    my $dth = $dbh->prepare($query) || $form->dberror($query);

    $query = qq|INSERT INTO defaults (fldname, fldvalue)
                VALUES (?, ?)|;
    my $sth = $dbh->prepare($query) || $form->dberror($query);

    for (qw(check receipt)) {
      $dth->execute("${_}_$accno");
      $dth->finish;

      if ($form->{"${_}_$accno"}) {
        $sth->execute("${_}_$accno", $form->{"${_}_$accno"});
        $dth->finish;
      }
    }
  }
 
  $form->audittrail($dbh, "", \%audittrail);

  my $rc = $dbh->commit;

  $dbh->disconnect;

  $rc;

}


sub exchangerates {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{currencies} = $form->get_currencies($myconfig, $dbh);

  $form->all_years($myconfig);

  $dbh->disconnect;

}



sub get_exchangerates {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $where = "1 = 1";

  $form->{currencies} = $form->get_currencies($myconfig, $dbh);

  unless ($form->{transdatefrom} || $form->{transdateto}) {
    ($form->{transdatefrom}, $form->{transdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  }
  
  $where .= " AND transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
  $where .= " AND transdate <= '$form->{transdateto}'" if $form->{transdateto};   
  $where .= " AND curr = '$form->{currency}'" if $form->{currency};

  my @sf = qw(transdate);
  my %ordinal = ( curr => 1,
                  transdate => 2,
                  exchangerate => 3
                );
  my $sortorder = $form->sort_order(\@sf, \%ordinal);
 
  my $query = qq|SELECT * FROM exchangerate
                 WHERE $where
		 ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{transactions} }, $ref;
  }
  $sth->finish;
  $dbh->disconnect;

}


sub save_exchangerate {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my $query;
  my $sth;
  my $dth;
  my %audittrail;

  $query = qq|DELETE FROM exchangerate
	      WHERE transdate = ?
	      AND curr = ?|;
  $dth = $dbh->prepare($query) || $form->dberror($query);
    
  $query = qq|INSERT INTO exchangerate
	      (transdate, exchangerate, curr)
	      VALUES (?,?,?)|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  for (split /:/, $form->{currencies}) {
    
    if ($form->{$_}) {
      
      $dth->execute($form->{transdate}, $_) || $form->dberror;
      $dth->finish;
      
      $form->{"${_}exchangerate"} = $form->parse_amount($myconfig, $form->{"${_}exchangerate"});
      
      if ($form->{"${_}exchangerate"}) {
	$sth->execute($form->{transdate}, $form->{"${_}exchangerate"}, $_) || $form->dberror;
	$sth->finish;
      }
      %audittrail = ( tablename	=> 'exchangerate',
		      reference	=> $form->{transdate},
		      formname	=> $_,
		      action	=> 'saved',
		      id	=> 1 );
      $form->audittrail($dbh, "", \%audittrail);
    }
  }
  

  $dbh->commit;
  $dbh->disconnect;

}


sub remove_locks {
  my ($self, $myconfig, $form, $userspath) = @_;
  
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|DELETE FROM semaphore|;
  $dbh->do($query) || $form->dberror($query);

  $dbh->disconnect;

}


sub get_defaults {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);
  
  my %defaults = $form->get_defaults($dbh, \@{[qw(printer\_%)]});

  my %pr;
  
  for (sort keys %defaults) {
    ($label, $command) = split /=/, $defaults{$_};
    if (! $pr{$label}) {
      push @{ $form->{all_printer} }, { printer => $label };
      $pr{$label} = 1;
    }
  }

  # get name, email from employee
  $login = $form->{login};
  $login =~ s/\@.*//;

  $query = qq|SELECT name, email
              FROM employee
	      WHERE login = '$login'|;
  ($form->{name}, $form->{email}) = $dbh->selectrow_array($query);
  
  $dbh->disconnect;
  
}


sub currencies {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{sort} = "rn" unless $form->{sort};
  my @sf = qw(rn curr);
  my %ordinal = ( rn	=> 1,
                  curr	=> 2 );
  my $sortorder = $form->sort_order(\@sf, \%ordinal);

  my $query = qq|SELECT * FROM curr
		 ORDER BY $sortorder|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub get_currency {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT * FROM curr
	         WHERE curr = |.$dbh->quote($form->{curr});
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  
  my $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;

  $query = qq|SELECT DISTINCT curr FROM ar WHERE curr = '$form->{curr}'
        UNION SELECT DISTINCT curr FROM ap WHERE curr = '$form->{curr}'
	UNION SELECT DISTINCT curr FROM oe WHERE curr = '$form->{curr}'|;
  ($form->{orphaned}) = $dbh->selectrow_array($query);
  $form->{orphaned} = !$form->{orphaned};

  $dbh->disconnect;

}


sub save_currency {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{curr} = uc substr($form->{curr}, 0, 3);

  $query = qq|SELECT curr
	      FROM curr
	      WHERE curr = '$form->{curr}'|;
  my ($curr) = $dbh->selectrow_array($query);

  my $rn;
  
  if (!$curr) {
    $query = qq|SELECT MAX(rn) FROM curr|;
    ($rn) = $dbh->selectrow_array($query);
    $rn++;
    
    $query = qq|INSERT INTO curr (rn, curr)
                VALUES ($rn, '$form->{curr}')|;
    $dbh->do($query) || $form->dberror($query);
  }

  $form->{prec} *= 1;
  $query = qq|UPDATE curr SET
	      prec = $form->{prec}
	      WHERE curr = '$form->{curr}'|;
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename	=> 'curr',
		     reference	=> $form->{curr},
		     formname	=> '',
		     action	=> 'saved',
		     id	=> 1 );
  $form->audittrail($dbh, "", \%audittrail);

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub delete_currency {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my $query = qq|SELECT rn FROM curr
                 WHERE curr = |.$dbh->quote($form->{curr});
  my ($rn) = $dbh->selectrow_array($query);
  
  $query = qq|UPDATE curr SET rn = rn - 1
              WHERE rn > $rn|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|DELETE FROM curr
	      WHERE curr = |.$dbh->quote($form->{curr});
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename	=> 'curr',
		     reference	=> $form->{curr},
		     formname	=> '',
		     action	=> 'deleted',
		     id	=> 1 );
  $form->audittrail($dbh, "", \%audittrail);

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub workstations {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my %defaults = $form->get_defaults($dbh, \@{['workstation\_%','printer\_%','cashdrawer%','poledisplay%']});

  my $fld;
  my $ws;
  my $tp;
  my $command;
  my %ws;

  $form->{numprinters} = 1;
  
  for (keys %defaults) {

    if ($_ =~ /printer_/) {
      ($fld, $ws, $tp) = split /_/, $_;
	
      if ($tp) {
	($fld, $command) = split /=/, $defaults{$_};

	$ws{$ws}{workstation}{$tp} = $ws;
	
	$ws{$ws}{printer}{$tp} = $fld;
	$ws{$ws}{command}{$tp} = $command;
	
      } else {
	# main
	($fld, $command) = split /=/, $defaults{$_};

	$form->{$_} = $fld;
	($fld, $tp) = split /_/, $_;
	$form->{"command_$tp"} = $command;

	$form->{numprinters}++;
      }
    } else {
      ($fld, $ws) = split /_/, $_;
      if ($ws) {
	$ws{$ws}{$fld} = $defaults{$_};
      } else {
	# main
	$form->{$_} = $defaults{$_};
      }
    }
  }

  my $i = 1;
  for (sort { $a <=> $b } keys %ws) {

    for $item (qw(workstation cashdrawer poledisplay poledisplayon)) {
      $form->{"${item}_$i"} = $ws{$_}{$item};
    }

    for $tp (keys %{ $ws{$_}{printer} }) {
      $form->{"printer_${i}_$tp"} = $ws{$_}{printer}{$tp};
      $form->{"command_${i}_$tp"} = $ws{$_}{command}{$tp};
      $form->{"numprinters_$i"}++;
    }
    $form->{"numprinters_$i"}++;

    $i++;
  }
  $form->{numworkstations} = $i;

  $dbh->disconnect;

}


sub save_workstations {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|DELETE FROM defaults
                 WHERE fldname LIKE ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  for (qw(workstation printer cashdrawer poledisplay)) {
    $sth->execute("${_}%");
    $sth->finish;
  }

  $query = qq|INSERT INTO defaults (fldname, fldvalue)
              VALUES (?,?)|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  for (1 .. $form->{numprinters}) {
    if ($form->{"printer_$_"}) {
      $sth->execute("printer_$_", qq|$form->{"printer_$_"}=$form->{"command_$_"}|);
      $sth->finish;
    }
  }
  
  for (qw(workstation cashdrawer poledisplay poledisplayon)) {
    if ($form->{$_}) {
      $sth->execute($_, $form->{$_});
      $sth->finish;
    }
  }

  my %audittrail;
  
  for $ws (1 .. $form->{numworkstations}) {
    for (1 .. $form->{"numprinters_$ws"}) {
      if ($form->{"printer_${ws}_$_"}) {
	$sth->execute(qq|printer_$form->{"workstation_$ws"}_$_|, qq|$form->{"printer_${ws}_$_"}=$form->{"command_${ws}_$_"}|);
	$sth->finish;
	
	%audittrail = ( tablename	=> 'defaults',
			reference	=> $form->{"printer_${ws}_$_"},
			formname	=> '',
			action		=> 'saved',
			id		=> 1 );

	$form->audittrail($dbh, "", \%audittrail);

      }
    }
    
    for (qw(workstation cashdrawer poledisplay poledisplayon)) {
      if ($form->{"${_}_$ws"}) {
	$sth->execute(qq|${_}_$form->{"workstation_$ws"}|, $form->{"${_}_$ws"});
	$sth->finish;
      }
    }
  }

  $dbh->disconnect;

  1;

}


sub move {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $id;
  
  for (qw(db fld id)) { $form->{$_} =~ s/;//g }

  my $query = qq|SELECT rn FROM $form->{db}
                 WHERE $form->{fld} = '$form->{id}'|;
  my ($rn) = $dbh->selectrow_array($query);

  $query = qq|SELECT MAX(rn) FROM $form->{db}|;
  my ($lastrn) = $dbh->selectrow_array($query);
  
  $query = qq|SELECT MIN(rn) FROM $form->{db}|;
  my ($firstrn) = $dbh->selectrow_array($query);
  
  if ($form->{move} eq 'down') {
    
    if ($rn == $lastrn) {
      $query = qq|UPDATE $form->{db} SET rn = rn + 1|;
      $dbh->do($query) || $form->dberror($query);
     
      $query = qq|UPDATE $form->{db} SET rn = $firstrn
		  WHERE $form->{fld} = '$form->{id}'|;
      $dbh->do($query) || $form->dberror($query);
    } else {
      $query = qq|SELECT $form->{fld} FROM $form->{db}
		  WHERE rn = $rn + 1|;
      ($id) = $dbh->selectrow_array($query);

      $query = qq|UPDATE $form->{db} SET rn = $rn + 1
		  WHERE $form->{fld} = '$form->{id}'|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|UPDATE $form->{db} SET rn = $rn
		  WHERE $form->{fld} = '$id'|;
      $dbh->do($query) || $form->dberror($query);
    }
    
  }
  
  if ($form->{move} eq 'up') {
    
    if ($rn == $firstrn) {
      $query = qq|UPDATE $form->{db} SET rn = rn - 1|;
      $dbh->do($query) || $form->dberror($query);
      
      $query = qq|UPDATE $form->{db} SET rn = $lastrn
		  WHERE $form->{fld} = '$form->{id}'|;
      $dbh->do($query) || $form->dberror($query);
    } else {
      $query = qq|SELECT $form->{fld} FROM $form->{db}
		  WHERE rn = $rn - 1|;
      ($id) = $dbh->selectrow_array($query);

      $query = qq|UPDATE $form->{db} SET rn = $rn - 1
		  WHERE $form->{fld} = '$form->{id}'|;
      $dbh->do($query) || $form->dberror($query);
      
      $query = qq|UPDATE $form->{db} SET rn = $rn
		  WHERE $form->{fld} = '$id'|;
      $dbh->do($query) || $form->dberror($query);
    }

  }
  
  $dbh->disconnect;

}


sub roles {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{sort} = "rn" unless $form->{sort};
  my @sf = qw(rn description);
  my %ordinal = ( rn	=> 4,
                  description	=> 2 );
  my $sortorder = $form->sort_order(\@sf, \%ordinal);

  my $query = qq|SELECT * FROM acsrole
		 ORDER BY $sortorder|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{rn}{$ref->{description}} = $ref->{rn};
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub get_role {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{id} *= 1;
  
  my $query = qq|SELECT * FROM acsrole
	         WHERE id = $form->{id}|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  
  my $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;

  # see if it is in use
  $query = qq|SELECT * FROM employee
              WHERE acsrole_id = $form->{id}|;
  ($form->{orphaned}) = $dbh->selectrow_array($query);
  $form->{orphaned} = !$form->{orphaned};

  $dbh->disconnect;

}


sub save_role {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  if ($form->{id} *= 1) {
    $query = qq|SELECT id
                FROM acsrole
		WHERE id = $form->{id}|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }
 
  if (!$form->{id}) {
    $uid = localtime;
    $uid .= $$;
    
    $query = qq|SELECT MAX(rn)
                FROM acsrole|;
    my ($rn) = $dbh->selectrow_array($query);
    $rn++;
    
    $query = qq|INSERT INTO acsrole (description, rn)
                VALUES ('$uid', $rn)|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id
                FROM acsrole
		WHERE description = '$uid'|;
    ($form->{id}) = $dbh->selectrow_array($query);
    
  }
  
  my $acs;
  my $item;
  my $item1;
  my $item2;
  my $heading;

  for (split /;/, $form->{acs}) {
    $item = $form->escape($_,1);
    if (!$form->{$item}) {
      if ($heading) {
	if ($item !~ /^$heading/) {
	  $acs .= $form->unescape($_).";";
	  $heading = "$item--";
	}
      } else {
	$acs .= $form->unescape($_).";";
	($item1, $item2) = split /--/, $item;
	if ($item1 eq $item2) {
	  $heading = "$item1--";
	} else {
	  $heading = "$item--";
	}
      }
    }
  }

  $query = qq|UPDATE acsrole SET
	      description = |.$dbh->quote($form->{description}).qq|,
	      acs = '$acs'
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub delete_role {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  $form->{id} *= 1;
  
  my $query = qq|SELECT rn FROM acsrole
                 WHERE id = $form->{id}|;
  my ($rn) = $dbh->selectrow_array($query);
  
  $query = qq|UPDATE acsrole SET rn = rn - 1
              WHERE rn > $rn|;
  $dbh->do($query) || $form->dberror($query);
 
  $query = qq|DELETE FROM acsrole
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub restore {
  my ($self, $myconfig, $form, $backupfile) = @_;
  
  my $file = "sql/$myconfig->{dbdriver}-tables.sql";
  open(FH, "$file");
  my @sql = <FH>;
  close(FH);
  
  $file = "sql/$myconfig->{dbdriver}-custom_tables.sql";
  if (open(FH, "$file")) {
    push @sql, <FH>;
    close(FH);
  }

  my $el;
  my %references;
  my %tables;
  my %sequences;

  for (@sql) {
    
    if (/references /i) {
      $references{$el} = 1;
    }
    
    if (/create table (\w+)/i) {
      $el = $1;
      $tables{$1} = 1;
    }

    if (/create sequence (\w+)/i) {
      $sequences{$1} = 1;
    }

  }

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  if (!$dbh) {
    $form->info($DBI::errstr);
    return 0;
  }

  $dbh->{PrintError} = 0;

  for ($dbh->tables) {
    if ($myconfig->{dbdriver} =~ /Pg/) {
      if (!/(pg_catalog|information_schema)/) {
        $_ =~ s/public\.//;
        $tables{$_} = 1;
      }
    } else {
      $tables{$_} = 1;
    }
  }
  
  # drop references first
  for (keys %references) {
    $query = qq|DROP TABLE $_;|;
    $dbh->do($query);
  }

  # drop tables and sequences
  for (keys %tables) {
    unless ($references{$_}) {
      $query = qq|DROP TABLE $_;|;
      $dbh->do($query);
    }
  }

  # drop sequences
  for (keys %sequences) {
    $query = qq|DROP SEQUENCE $_;|;
    $dbh->do($query);
  }

  open(FH, "$backupfile") or $form->error($!);
  @sql = <FH>;
  close(FH);
  
  for (@sql) {
    next if /^--/;

    $query .= $_;
    
    if (/create function/i) {
      while (!/-- end function/i) {
        $_ = shift @sql;
        $query .= $_;
      }
    }
    
    if (/;\s*$/) {
      if ($query =~ /VALUES/) {
        next if $query !~ /\);$/;
      }
      $query =~ s/;(\s*)$//;

      if ($query =~ /^DROP /) {
        (undef, undef, $el) = split / /, $query;
        if ($tables{$el} || $references{$el}) {
          $query = "";
          next;
        }
      }
      $dbh->do($query) if $query;
      $query = "";
    }
  }

  $dbh->disconnect;

  1;
  
}


sub audit_log_links {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT DISTINCT action
                 FROM audittrail
		 ORDER BY action|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_action} }, $ref;
  }
  $sth->finish;

  $form->all_employees($myconfig, $dbh);

  $dbh->disconnect;
  
}
  
  
sub audit_log {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $id;
  my $where = "WHERE 1 = 1";

  if ($form->{employee}) {
    (undef, $id) = split /--/, $form->{employee};
    $where .= qq| AND a.employee_id = $id|;
  }
  if ($form->{transdatefrom}) {
    $where .= qq| AND a.transdate >= '$form->{transdatefrom}'|;
  }
  if ($form->{transdateto}) {
    $where .= qq| AND a.transdate < date '$form->{transdateto}' + 1|;
  }
  if ($form->{logaction}) {
    $where .= qq| AND a.action = |.$dbh->quote($form->{logaction});
  }
  my $var;
  if ($form->{reference}) {
    $var = $form->like(lc $form->{reference});
    $where .= qq| AND lower(a.reference) LIKE '$var'|;
  }
  
  my $dateformat = $myconfig->{dateformat};
  $dateformat =~ s/yy$/yyyy/;
  $dateformat =~ s/yyyyyy/yyyy/;

  my %datestyle = ( Pg => "set DateStyle to SQL, US" );
  
  my $query = qq|$datestyle{$myconfig->{dbdriver}};
                 SELECT a.*, e.name, e.employeenumber, e.login,
                 to_char(a.transdate, '$dateformat') AS transdate,
		 to_char(a.transdate, 'HH24:MI:SS') AS transtime
                 FROM audittrail a
		 LEFT JOIN employee e ON (e.id = a.employee_id)
		 $where|;

  $form->{sort} ||= "transdate";
  my @sf;
  push @sf, ($form->{sort} eq 'transdate') ? qw(transdate transtime) : $form->{sort};
  my %ordinal = $form->ordinal_order($dbh, $query);
  my $sortorder = $form->sort_order(\@sf, \%ordinal);

  if ($form->{sort} eq 'transdate') {
    $sortorder =~ s/12/12 $form->{direction}/;
  }

  $query .= " ORDER BY $sortorder" if $sortorder;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{login} = 'admin' if $ref->{employee_id} == 0;
    push @{ $form->{ALL} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}


1;

