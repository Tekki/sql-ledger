#=====================================================================
# SQL-Ledger ERP
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Reference Documents
#
#======================================================================

1;

sub reference_documents {

  $form->{reference_rows} ||= 1;
  $form->{reference_rows}++ if $form->{"referenceid_$form->{reference_rows}"};

  $_ = qq|
	    <table>
	      <tr class=listheading>
		<th class=listheading colspan=2>|.$locale->text('Reference Documents').qq|</th>
	      </tr>
|;

  for $i (1 .. $form->{reference_rows}) {
    $_ .= qq|
	      <tr>
		<td><input name="referencedescription_$i" size=20 value="|.$form->quote($form->{"referencedescription_$i"}).qq|"></td>
		<td><input name="referenceid_$i" size=10 value="$form->{"referenceid_$i"}">
|;

    if ($form->{referenceurl}) {
      $_ .= qq|
		<a href=$form->{referenceurl}$form->{"referenceid_$i"} target=_blank>?</a>
|;
    }

    $_ .= qq|
		</td>
	      </tr>
|;
  }

  $_ .= qq|
	    </table>
|;

  $_;

}

