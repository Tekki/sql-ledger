#======================================================================
# SQL-Ledger ERP
#
# © 2007-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# routines to create Javascript functions
#
#======================================================================
use v5.40;

package SL::JS;


sub change_report {
  my ($self, $form, $input, $checked, $radio) = @_;

  print qq|
<script language="javascript">
<!--

function ChangeReport() {

  var frm = document.forms[0];

|;

  for (@{$input}, @{$checked}, keys %{$radio}) {
    print qq|  var $_ = Array->new;\n|;
  }

  print "\n";

  for (@{$input}, @{$checked}, keys %{$radio}) {
    print qq|  ${_}[0] = "$form->{$_}";\n|;
  }

  my $i = 1;
  my $item;
  my $found;
  my %column_index;

  for my $ref (@{ $form->{all_report} }) {
    for (@{$input}, @{$checked}) {
      print qq|  ${_}[$i] = "$form->{all_reportvars}{$ref->{reportid}}{"report_$_"}";\n|;
    }
    for $item (keys %{$radio}) {
      $found = 0;
      for (keys %{ $radio->{$item} }) {
        if (($form->{all_reportvars}{$ref->{reportid}}{"report_$item"} // '') eq $_) {
          print qq|  ${item}\[$i\] = "$radio->{$item}{$_}";\n|;
          $found = 1;
        }
      }
      if (!$found) {
        print qq|  ${item}\[$i\] = "0";\n|;
      }
    }
    print "\n";

    %column_index = split /[,=]/, $form->{all_reportvars}{$ref->{reportid}}{report_column_index} // '';
    for (@{$checked}) {
      my $s = $_;
      $s =~ s/l_//;
      if (exists $column_index{$s}) {
        print qq|  ${_}[$i] = "1";\n|;
      }
    }
    $i++;
  }

  print qq|
  var e = frm.report;
  var v = e.options.selectedIndex;

|;

  for (@{$input}) {
    print qq|  frm.${_}.value = ${_}[v];\n|;
  }

  for (@{$checked}) {
    print qq|  frm.${_}.checked = ${_}[v];\n|;
  }

  for (keys %{$radio}) {
    print qq|  frm.${_}[${_}[v]].checked = true;\n|;
  }

  print qq|

}
// -->
</script>
|;

}


sub check_all {
  my ($self, $checkbox, $match) = @_;

  print qq|
<script language="javascript">
<!--

function CheckAll() {

  var frm = document.forms[0]
  var el = frm.elements
  var re = /$match/;

  for (i = 0; i < el.length; i++) {
    if (el[i].type == 'checkbox' && re.test(el[i].name)) {
      el[i].checked = frm.${checkbox}.checked
    }
  }
}

// -->
</script>
|;

}


1;


=encoding utf8

=head1 NAME

SL::JS - Routines to create javascript functions

=head1 DESCRIPTION

L<SL::JS> contains the routines to create javascript functions.

=head1 FUNCTIONS

L<SL::JS> implements the following functions:

=head2 change_report

  SL::JS->change_report($form, $input, $checked, $radio);

=head2 check_all

  SL::JS->check_all($checkbox, $match);

=cut
