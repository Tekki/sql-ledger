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


sub prepare_search {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT DISTINCT formname FROM reference|;

  my $sth = $dbh->prepare($query);
  $sth->execute or $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
    $form->{has_formname}{$ref->{formname}} = 1;
  }
  $sth->finish;

  $query = qq|
    SELECT DISTINCT folder
    FROM reference
    ORDER BY folder|;

  my $sth = $dbh->prepare($query);
  $sth->execute or $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
    push $form->{all_folder}->@*, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}


sub all_documents {
  my ($self, $myconfig, $form, $formnames) = @_;

  my $dbh = $form->dbconnect($myconfig);

  $form->load_defaults(undef, $dbh, ['company', 'referenceurl']);

  my $login = $form->{login};
  $login =~ s/\@.*//;

  my %numbers;
  for my $f (values %$formnames) {
    my $db = $f->{db};
    $numbers{$f->{db}} ||= {
      field  => "$db.$f->{number}::text",
      join   => "LEFT JOIN $db ON $db.id = r.trans_id",
    };
  }

  my ($joins, @all_numbers, $var);

  for (sort keys %numbers) {
    push @all_numbers, $numbers{$_}{field};
    $joins .= qq|
      $numbers{$_}{join}|;
  }

  # get reference documents
  my $where = '1=1';

  if ($form->{description}) {
    $var = $form->like(lc $form->{description});

    $where .= qq|
        AND lower(r.description) LIKE '$var'|;
  }
  if ($form->{filename}) {
    $var = $form->like(lc $form->{filename});

    $where .= qq|
        AND lower(a.filename) LIKE '$var'|;
  }
  if ($form->{folder}) {
    $var = $form->like(lc $form->{folder});

    $where .= qq|
        AND lower(r.folder) LIKE '$var'|;
  }
  if ($form->{formname}) {
    (undef, $var) = split /--/, $form->{formname};

    $where .= qq|
        AND r.formname = '$var'|;
  }
  if ($form->{confidential}) {
    $where .= qq|
        AND r.login = '$login'|;
  }

  my @sf = $form->{referenceurl} ? qw|description| : qw|filename description document_number|;
  my $order = $form->sort_order(\@sf);

  my $query = qq|
      SELECT
        r.*,
        a.filename,
        COALESCE(|. join(',', @all_numbers) .qq|) AS document_number
      FROM reference r
      LEFT JOIN archive a ON (a.id = r.archive_id)$joins
      WHERE $where
      ORDER BY $order|;

  if ($form->{document_number}) {
    $var = $form->like(lc $form->{document_number});

    $query = qq|
    WITH all_numbers AS ($query
    )
    SELECT *
    FROM all_numbers
    WHERE lower(document_number) LIKE '$var'|;
  }

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
              WHERE $form->{number_field} = ?|;
  my ($id) = $dbh->selectrow_array($query, undef, $form->{document_number});

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
                  '$ref->{code}', '$id', '$ref->{description}',
                  '$ref->{archive_id}', '$ref->{login}', '$form->{formname}',
                  '$ref->{folder}')|;
    } else {
      $query = qq|UPDATE reference SET
                  trans_id = $id,
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


=encoding utf8

=head1 NAME

RD - Cms backend routines

=head1 DESCRIPTION

L<SL::RD> contains the cms backend routines.

=head1 FUNCTIONS

L<SL::RD> implements the following functions:

=head2 all_documents

  RD->all_documents($myconfig, $form);

=head2 attach_document

  RD->attach_document($myconfig, $form);

=head2 delete_document

  RD->delete_document($myconfig, $form, $dbh);

=head2 delete_documents

  RD->delete_documents($myconfig, $form);

=head2 detach_document

  RD->detach_document($myconfig, $form);

=head2 get_document

  RD->get_document($myconfig, $form);

=head2 save_document

  RD->save_document($myconfig, $form);

=cut
