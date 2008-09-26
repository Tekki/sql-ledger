#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2003
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#======================================================================
#
# Batch printing module backend routines
#
#======================================================================

package BP;


sub get_vc {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my %arap = ( invoice => { ar => customer, ap => vendor },
               packing_list => { oe => customer, ar => customer, ap => vendor },
	       sales_order => { oe => customer },
	       work_order => { oe => customer },
	       pick_list => { oe => customer, ar => customer, ap => vendor },
	       purchase_order => { oe => vendor },
	       bin_list => { oe => customer, ar => customer, ap => vendor },
	       sales_quotation => { oe => customer },
	       request_quotation => { oe => vendor },
	       timecard => { jcitems => employee },
	     );
  
  my $query = "";
  my $sth;
  my $count;
  my $item;
  my $vc;
  my $wildcard = ($form->{type} eq 'invoice') ? '%' : '';

  foreach $item (keys %{ $arap{$form->{type}} }) {
    $query = qq|
              SELECT count(*)
	      FROM (SELECT DISTINCT vc.id
		    FROM $arap{$form->{type}}{$item} vc, $item a, status s
		    WHERE a.$arap{$form->{type}}{$item}_id = vc.id
		    AND s.trans_id = a.id
		    AND s.formname LIKE '$wildcard$form->{type}'
		    AND s.spoolfile IS NOT NULL) AS total|;
    ($vc) = $dbh->selectrow_array($query);
    $form->{$arap{$form->{type}}{$item}} ||= $vc;
    $count += $vc;
  }

  # build selection list
  my $union = "";
  $query = "";
  if (($count < $myconfig->{vclimit}) && $count) {
    foreach $item (keys %{ $arap{$form->{type}} }) {
      $query .= qq|
                  $union
		  SELECT DISTINCT ON (vc.name, vc.id) vc.id, vc.name, '$arap{$form->{type}}{$item}' AS vclabel
		  FROM $item a
		  JOIN $arap{$form->{type}}{$item} vc ON (a.$arap{$form->{type}}{$item}_id = vc.id)
		  JOIN status s ON (s.trans_id = a.id)
		  WHERE s.formname LIKE '$wildcard$form->{type}'
		  AND s.spoolfile IS NOT NULL|;
      $union = "UNION";
    }
    $query .= qq| ORDER BY 2, 1|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{"all_$ref->{vclabel}"} }, $ref;
    }
    $sth->finish;
  }

  $form->all_years($myconfig, $dbh);

  $dbh->disconnect;

  $count;
 
}

  
sub get_spoolfiles {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $invnumber = "invnumber";
  my $item;
  my $wildcard = ($form->{type} eq 'invoice') ? '%' : '';
  
  my %arap = ( invoice => { ar => customer, ap => vendor },
               packing_list => { oe => customer, ar => customer, ap => vendor },
	       sales_order => { oe => customer },
	       work_order => { oe => customer },
	       pick_list => { oe => customer, ar => customer, ap => vendor },
	       purchase_order => { oe => vendor },
	       bin_list => { oe => customer, ar => customer, ap => vendor },
	       sales_quotation => { oe => customer },
	       request_quotation => { oe => vendor },
	       timecard => { jcitems => employee },
	     );
 
  ($form->{transdatefrom}, $form->{transdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};

  if ($form->{type} eq 'timecard') {
    my $dateformat = $myconfig->{dateformat};
    $dateformat =~ s/yy/yyyy/;
    $dateformat =~ s/yyyyyy/yyyy/;

    $invnumber = 'id';
    
    $query = qq|SELECT j.id, e.name, j.id AS invnumber,
                to_char(j.checkedin, '$dateformat') AS transdate,
		'' AS ordnumber, '' AS quonumber, '0' AS invoice,
		'$jcitems' AS module, s.spoolfile
		FROM jcitems j
		JOIN employee e ON (e.id = j.employee_id)
		JOIN status s ON (s.trans_id = j.id)
		WHERE s.formname = '$form->{type}'
		AND s.spoolfile IS NOT NULL|;

    my ($employee, $employee_id) = split /--/, $form->{$arap{$form->{type}}{jcitems}};
    if ($employee_id) {
      $query .= qq| AND j.$arap{$form->{type}}{jcitems}_id = $employee_id|;
    } else {
      if ($employee) {
	$item = $form->like(lc $employee);
	$query .= " AND lower(e.name) LIKE '$item'";
      }
    }

    $query .= " AND j.checkedin >= '$form->{transdatefrom}'" if $form->{transdatefrom};
    $query .= " AND j.checkedin <= '$form->{transdateto}'" if $form->{transdateto};

  } else {
    
    foreach $item (keys %{ $arap{$form->{type}} }) {
      ($form->{$arap{$form->{type}}{$item}}, $form->{"$arap{$form->{type}}{$item}_id"}) = split /--/, $form->{$arap{$form->{type}}{$item}};
    }

    foreach $item (keys %{ $arap{$form->{type}} }) {
      
      $invoice = "a.invoice";
      $invnumber = "invnumber";
      
      if ($item eq 'oe') {
	$invnumber = "ordnumber";
	$invoice = "'0'"; 
      }
      
      if ($form->{"print$arap{$form->{type}}{$item}"} ne 'Y') {
	$form->{$arap{$form->{type}}{$item}} = "x";
	$form->{"$arap{$form->{type}}{$item}_id"} = 0;
      }
	
      $query .= qq|
		$union
		SELECT a.id, vc.name, a.$invnumber AS invnumber, a.transdate,
		a.ordnumber, a.quonumber, $invoice AS invoice,
		'$item' AS module, s.spoolfile
		FROM $item a, $arap{$form->{type}}{$item} vc, status s
		WHERE s.trans_id = a.id
		AND s.spoolfile IS NOT NULL
		AND s.formname LIKE '$wildcard$form->{type}'
		AND a.$arap{$form->{type}}{$item}_id = vc.id|;

      if ($form->{$arap{$form->{type}}{$item}}) {
	if ($form->{"$arap{$form->{type}}{$item}_id"} ne "") {
	  $query .= qq| AND a.$arap{$form->{type}}{$item}_id = $form->{"$arap{$form->{type}}{$item}_id"}|;
	} else {
	  $item = $form->like(lc $form->{$arap{$form->{type}}{$item}});
	  $query .= " AND lower(vc.name) LIKE '$item'";
	}
      }
      if ($form->{invnumber} ne "") {
	$item = $form->like(lc $form->{invnumber});
	$query .= " AND lower(a.invnumber) LIKE '$item'";
      }
      if ($form->{ordnumber} ne "") {
	$item = $form->like(lc $form->{ordnumber});
	$query .= " AND lower(a.ordnumber) LIKE '$item'";
      }
      if ($form->{quonumber} ne "") {
	$item = $form->like(lc $form->{quonumber});
	$query .= " AND lower(a.quonumber) LIKE '$item'";
      }

      $query .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
      $query .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};

      $union = "UNION";

    }
  }

  my %ordinal = ( 'name' => 2,
                  'invnumber' => 3,
                  'transdate' => 4,
		  'ordnumber' => 5,
		  'quonumber' => 6,
		);

  my @a = ();
  push @a, ("transdate", "$invnumber", "name");
  my $sortorder = $form->sort_order(\@a, \%ordinal);
  $query .= " ORDER by $sortorder";

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{SPOOL} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;

}


sub delete_spool {
  my ($self, $myconfig, $form, $spool) = @_;

  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my %audittrail;
  
  $query = qq|UPDATE status SET
	       spoolfile = NULL
	       WHERE spoolfile = ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  foreach my $i (1 .. $form->{rowcount}) {
    if ($form->{"checked_$i"}) {
      $sth->execute($form->{"spoolfile_$i"}) || $form->dberror($query);
      $sth->finish;
      
      %audittrail = ( tablename  => $form->{module},
                      reference  => $form->{"reference_$i"},
		      formname   => $form->{type},
		      action     => 'dequeued',
		      id         => $form->{"id_$i"} );
 
      $form->audittrail($dbh, "", \%audittrail);
    }
  }
    
  # commit
  my $rc = $dbh->commit;
  $dbh->disconnect;

  if ($rc) {
    foreach my $i (1 .. $form->{rowcount}) {
      $_ = qq|$spool/$form->{"spoolfile_$i"}|;
      if ($form->{"checked_$i"}) {
	unlink;
      }
    }
  }

  $rc;
  
}


sub print_spool {
  my ($self, $myconfig, $form, $spool) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my %audittrail;
  
  my $query = qq|UPDATE status SET
		 printed = '1'
                 WHERE spoolfile = ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  foreach my $i (1 .. $form->{rowcount}) {
    if ($form->{"checked_$i"}) {
      open(OUT, $form->{OUT}) or $form->error("$form->{OUT} : $!");
      binmode(OUT);
      
      $spoolfile = qq|$spool/$form->{"spoolfile_$i"}|;
      
      # send file to printer
      open(IN, $spoolfile) or $form->error("$spoolfile : $!");
      binmode(IN);

      while (<IN>) {
	print OUT $_;
      }
      close(IN);
      close(OUT);

      $sth->execute($form->{"spoolfile_$i"}) || $form->dberror($query);
      $sth->finish;
      
      %audittrail = ( tablename  => $form->{module},
                      reference  => $form->{"reference_$i"},
		      formname   => $form->{type},
		      action     => 'printed',
		      id         => $form->{"id_$i"} );
 
      $form->audittrail($dbh, "", \%audittrail);
      
      $dbh->commit;
    }
  }

  $dbh->disconnect;

}


1;

