#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Attach Reference Documents to transactions
# CMS is in rd.pl and RD.pm
#
#======================================================================


sub all_references {

  my $i = 0;
  for $ref (@{ $form->{all_reference} }) {
    $i++;
    for (qw(id code description archive_id filename confidential folder)) { $form->{"reference${_}_$i"} = $ref->{$_} }
  }
  $form->{reference_rows} = $i;
  
}


sub references {

  # reshuffle
  my @flds = map { "reference$_" } qw(id code description tmpfile archive_id filename confidential folder);

  my $count = 0;
  my @f = ();
  my $checked;
  my $i;
  
  for $i (1 .. $form->{reference_rows}) {
    if ($form->{"referencedescription_$i"}) {
      push @f, {};
      $j = $#f;

      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
  $form->redo_rows(\@flds, \@f, $count, $form->{reference_rows});
  $form->{reference_rows} = $count + 1;
  
  $_ = qq|
	    <table>
	      <tr class=listheading>
		<th class=listheading colspan=2>|.$locale->text('Reference Documents').qq|</th>
	      </tr>
|;

  for $i (1 .. $form->{reference_rows}) {

    $checked = ($form->{"referenceconfidential_$i"}) ? "checked" : "";
    $_ .= qq|
	      <tr>
		<td><input name="referencedescription_$i" size=40 value="|.$form->quote($form->{"referencedescription_$i"}).qq|"></td>
		<td><input name="referenceconfidential_$i" type=checkbox class=checkbox value="1" $checked></td>
|;

    if ($form->{referenceurl}) {
      $_ .= qq|
		<td><input name="referencecode_$i" size=10 value="$form->{"referencecode_$i"}">
		<a href=$form->{referenceurl}$form->{"referencecode_$i"} target=popup>?</a>
|;
    } else {
      $_ .= qq|
		<td>
		<input type="hidden" name="referencecode_$i" value="$form->{"referencecode_$i"}">
		<a href="rd.pl?action=upload&login=$form->{login}&path=$form->{path}&row=$i&id=$form->{"referencearchive_id_$i"}&description=|.$form->escape($form->{"referencedescription_$i"},1) . qq|" target=popup>?</a>
|;
    }

    $_ .= $form->hide_form(map { "reference${_}_$i" } qw(tmpfile archive_id filename folder));
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


1;

