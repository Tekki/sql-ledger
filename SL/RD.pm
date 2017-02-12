#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# CMS backend routines
#
#======================================================================

package RD;


sub all_documents {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect($myconfig);
  
  my $login = $form->{login};
  $login =~ s/\@.*//;

  my $var;
  
  # get reference documents
  my $query = qq|SELECT r.*, a.filename
		 FROM reference r
		 LEFT JOIN archive a ON (a.id = r.archive_id)
		 WHERE 1 = 1|;
  if ($form->{description}) {
    $var = $form->like(lc $form->{description});
    
    $query .= qq|
	      AND lower(r.description) LIKE '$var'|;
  }
  if ($form->{filename}) {
    $var = $form->like(lc $form->{filename});
    
    $query .= qq|
	      AND lower(a.filename) LIKE '$var'|;
  }
  if ($form->{folder}) {
    $var = $form->like(lc $form->{folder});
    
    $query .= qq|
	      AND lower(r.folder) LIKE '$var'|;
  }
  if ($form->{formname}) {
    (undef, $var) = split /--/, $form->{formname};
    
    $query .= qq|
	      AND r.formname = '$var'|;
  }

  my @sf = (description);
  my %ordinal = $form->ordinal_order($dbh, $query);
  $query .= qq| ORDER BY | .$form->sort_order(\@sf, \%ordinal);

  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    if ($ref->{login}) {
      next if $ref->{login} ne $login;
    }
    push @{ $form->{all_documents} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}


sub get_document {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect($myconfig);
  
  my $query;
  my $sth;
  my $ref;
  
  if ($form->{id} *= 1) {
    $query = qq|SELECT *
                FROM reference
		WHERE id = $form->{id}|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    $ref->{confidential} = ($ref->{login}) ? 1 : 0;
    delete $ref->{login};
    
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $form->{id} = $ref->{id};
    $sth->finish;
 
    if ($form->{archive_id}) {
      $query = qq|SELECT filename
		  FROM archive
		  WHERE id = $form->{archive_id}|;
      ($form->{filename}) = $dbh->selectrow_array($query);
    }
  }

  $dbh->disconnect;

}


sub save_document {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my $query;
  my $sth;
  my $upload;
  my $login = $form->{login};
  $login =~ s/\@.*//;
  $login = '' unless $form->{confidential};
  
  if ($form->{id} *= 1) {

    $query = qq|UPDATE reference SET
		description = |.$dbh->quote($form->{description}).qq|,
		folder = |.$dbh->quote($form->{folder}).qq|,
		login = '$login'
		WHERE id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT archive_id
		FROM reference
		WHERE id = $form->{id}|;
    ($archive_id) = $dbh->selectrow_array($query);

    if ($archive_id) {
      $query = qq|UPDATE archive SET
		  filename = |.$dbh->quote($form->{file}).qq|
		  WHERE id = $archive_id|;
      $dbh->do($query) || $form->dberror($query);
    }
    
  } else {
    # upload document
    $form->{reference_rows} = 1;
    $form->{filename} = ($form->{file}) ? $form->{file} : $form->{filename};
    for (qw(description folder filename confidential tmpfile)) { $form->{"reference${_}_1"} = $form->{$_} }
    delete $form->{filename};
    $form->save_reference($dbh, $formname);
  }

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}


sub delete_document {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;

  $dbh = $form->dbconnect_noauto($myconfig) unless $dbh;
  
  my $query;
  my $count;
  
  $form->{id} *= 1;
  
  $query = qq|SELECT archive_id
	      FROM reference
	      WHERE id = $form->{id}|;
  ($form->{archive_id}) = $dbh->selectrow_array($query);
  
  if ($form->{archive_id} *= 1) {
    $query = qq|SELECT count(*)
		FROM reference
		WHERE archive_id = $form->{archive_id}|;
    ($count) = $dbh->selectrow_array($query);

    if ($count == 1) {
      $query = qq|DELETE FROM archive
		  WHERE id = $form->{archive_id}|;
      $dbh->do($query) || $form->dberror($query);
    }
    
  }
  
  $query = qq|DELETE FROM reference
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
 
  my $rc = $dbh->commit;
  
  $dbh->disconnect if $disconnect;

  $rc;
  
}


sub delete_documents {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect_noauto($myconfig);

  for (1 .. $form->{rowcount}) {
    if ($form->{"id_$_"}) {
      $form->{id} = $form->{"id_$_"};
      RD->delete_document($myconfig, $form, $dbh);
    }
  }

  $dbh->disconnect;

  1;

}


sub detach_document {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my $query;
  
  $query = qq|UPDATE reference SET
              trans_id = NULL,
	      formname = NULL
	      WHERE id = $form->{id} * 1|;
  $dbh->do($query) || $form->dberror($query);
  
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}


sub attach_document {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my $query;
  my $sth;
  my $ref;

  $form->{trans_id} *= 1;
  $form->{id} *= 1;

  $query = qq|SELECT id
              FROM $form->{db}
	      WHERE id = $form->{trans_id}|;
  my ($id) = $dbh->selectrow_array($query);

  if ($id) {
    $query = qq|SELECT *
                FROM reference
		WHERE id = $form->{id}|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute || $form->dberror($query);
    $ref = $sth->fetchrow_hashref(NAME_lc);
    
    if ($ref->{trans_id}) {
      $query = qq|INSERT INTO reference (code, trans_id, description,
                  archive_id, login, formname, folder) VALUES (
		  '$ref->{code}', '$form->{trans_id}', '$ref->{description}',
		  '$ref->{archive_id}', '$ref->{login}', '$form->{formname}',
		  '$ref->{folder}')|;
    } else {
      $query = qq|UPDATE reference SET
		  trans_id = $form->{trans_id},
		  formname = '$form->{formname}'
		  WHERE id = $form->{id}|;
    }
    $dbh->do($query) || $form->dberror($query);
    
    $sth->finish;
  }
  
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $id;
  
}


1;

