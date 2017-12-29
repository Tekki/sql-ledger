#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2010
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Price Matrix for IS, IR, OE
#
#======================================================================

package PM;


sub price_matrix_query {
  my ($self, $dbh, $form) = @_;

  my $query;
  my $sth;

  if ($form->{customer_id}) {
    $query = qq|SELECT p.id AS parts_id, 0 AS customer_id, 0 AS pricegroup_id,
             0 AS pricebreak, p.sellprice, NULL AS validfrom, NULL AS validto,
	     '$form->{defaultcurrency}' AS curr, '' AS pricegroup
	     FROM parts p
	     WHERE p.id = ?

	     UNION
    
             SELECT p.*, g.pricegroup
             FROM partscustomer p
	     LEFT JOIN pricegroup g ON (g.id = p.pricegroup_id)
	     WHERE p.parts_id = ?
	     AND p.customer_id = $form->{customer_id}

	     UNION

	     SELECT p.*, g.pricegroup
	     FROM partscustomer p
	     LEFT JOIN pricegroup g ON (g.id = p.pricegroup_id)
	     JOIN customer c ON (c.pricegroup_id = g.id)
	     WHERE p.parts_id = ?
	     AND c.id = $form->{customer_id}

	     UNION

	     SELECT p.*, '' AS pricegroup
	     FROM partscustomer p
	     WHERE p.customer_id = 0
	     AND p.pricegroup_id = 0
	     AND p.parts_id = ?

	     ORDER BY 2 DESC, 3 DESC, 4|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
  }
  
  if ($form->{vendor_id}) {
    # price matrix and vendor's partnumber
    $query = qq|SELECT partnumber, lastcost, curr
		FROM partsvendor
		WHERE parts_id = ?
		AND vendor_id = $form->{vendor_id}|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
  }
  
  $sth;

}


sub price_matrix {
  my ($self, $pmh, $ref, $transdate, $decimalplaces, $form, $myconfig) = @_;

  $ref->{pricematrix} = "";
  my $customerprice;
  my $pricegroupprice;
  my $sellprice;
  my $baseprice;
  my $mref;
  my %p = ();
  my $i = 1;

  # depends if this is a customer or vendor
  if ($form->{customer_id}) {
    $pmh->execute($ref->{id}, $ref->{id}, $ref->{id}, $ref->{id});

    while ($mref = $pmh->fetchrow_hashref(NAME_lc)) {

      # check date
      if ($mref->{validfrom}) {
	next if $transdate < $form->datetonum($myconfig, $mref->{validfrom});
      }
      if ($mref->{validto}) {
	next if $transdate > $form->datetonum($myconfig, $mref->{validto});
      }

      # convert price
      $sellprice = $form->round_amount($mref->{sellprice} * $form->{$mref->{curr}}, $decimalplaces);
      
      $mref->{pricebreak} *= 1;
      
      if ($mref->{customer_id}) {
	$ref->{sellprice} = $sellprice if !$mref->{pricebreak};
	$p{$mref->{pricebreak}} = $sellprice;
	$customerprice = 1;
      }

      if ($mref->{pricegroup_id}) {
	if (! $customerprice) {
	  $ref->{sellprice} = $sellprice if !$mref->{pricebreak};
	  $p{$mref->{pricebreak}} = $sellprice;
	}
	$pricegroupprice = 1;
      }

      if (!$customerprice && !$pricegroupprice) {
	$p{$mref->{pricebreak}} = $sellprice;
      }

      if (($mref->{pricebreak} + $mref->{customer_id} + $mref->{pricegroup_id}) == 0) {
	$baseprice = $sellprice;
      }
      
      $i++;

    }
    $pmh->finish;

    if (! exists $p{0}) {
      $p{0} = $baseprice;
    }
    
    if ($i > 1) {
      $ref->{sellprice} = $form->round_amount($p{0} * (1 - $form->{tradediscount}), $decimalplaces);
      for (sort { $a <=> $b } keys %p) {
        $p{$_} = $form->round_amount($p{$_} * (1 - $form->{tradediscount}), $decimalplaces);
        $ref->{pricematrix} .= "${_}:$p{$_} ";
      }
    } else {
      $ref->{sellprice} = $form->round_amount($p{0} * (1 - $form->{tradediscount}), $decimalplaces);
      $ref->{pricematrix} = "0:$ref->{sellprice} " if $ref->{sellprice};
    }
    chop $ref->{pricematrix};

  }

  if ($form->{vendor_id}) {
    $pmh->execute($ref->{id});
    
    $mref = $pmh->fetchrow_hashref(NAME_lc);

    if ($mref->{partnumber} ne "") {
      $ref->{partnumber} = $mref->{partnumber};
    }

    if ($mref->{lastcost}) {
      # do a conversion
      $ref->{sellprice} = $form->round_amount($mref->{lastcost} * $form->{$mref->{curr}}, $decimalplaces);
    }
    $pmh->finish;

    $ref->{sellprice} *= 1;

    # add 0:price to matrix
    $ref->{pricematrix} = "0:$ref->{sellprice}";

  }

}


1;

