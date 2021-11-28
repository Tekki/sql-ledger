#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================


1;
# end of main


sub getpassword {
  my ($s) = @_;

  $locale = new Locale "$myconfig{countrycode}", "pw";

  if (-f "$form->{path}/custom/pw.pl") {
    require "$form->{path}/custom/pw.pl";
  }

  my $login = ($form->{"root login"}) ? "root" : $form->{login};
  $login =~ s/(\@| )/_/g;

  my @d = split / +/, scalar gmtime(time);
  my $today = "$d[0], $d[2]-$d[1]-$d[4] $d[3] GMT";

  $pwt = $locale->text('Password');

  if ($form->{stylesheet} && (-f "css/$form->{stylesheet}")) {
    $stylesheet = qq|<link rel="stylesheet" href="css/$form->{stylesheet}" type="text/css" title="SQL-Ledger stylesheet">
|;
  }

  my $charset;

  if ($form->{charset}) {
    $charset = qq|<meta http-equiv="Content-Type" content="text/html; charset=$form->{charset}">
|;
  }

  print qq|Set-Cookie: SL-$login=; expires=$today; path=/;
Content-Type: text/html

<!DOCTYPE HTML>
<html>
<head>
  <title>$pwt</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  $stylesheet
  $charset
</head>
|;

  $sessionexpired = qq|<b><font color=red><blink>|.$locale->text('Session expired!').qq|</blink></font></b><p>| if $s;

  print qq|
<script language="javascript" type="text/javascript">
<!--
function sf(){
    document.forms[0].password.focus();
}
// End -->
</script>

<body onload="sf()">

  $sessionexpired

<form method=post action=$form->{script}>

<table>
  <tr>
    <th align=right>$pwt</th>
    <td><input type=password name=password size=30></td>
    <td><input type=submit class=submit value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]"></td>
  </tr>
</table>

|;

  for (qw(script password header sessioncookie)) { delete $form->{$_} }

  foreach $item (split /;/, $form->{acs}) {
    $item = $form->escape($item,1);
    if ($form->{$item}) {
      delete $form->{$item};
      $item = $form->unescape($item);
      $form->{$item} = 1;
    }
  }

  $form->hide_form;

  print qq|
</form>

</body>
</html>
|;

}

=encoding utf8

=head1 NAME

bin/mozilla/pw.pl - Password dialog

=head1 DESCRIPTION

L<bin::mozilla::pw> contains functions for the password dialog.

=head1 DEPENDENCIES

L<bin::mozilla::pw>

=over

=item * optionally requires
F<bin/mozilla/custom/pw.pl>

=back

=head1 FUNCTIONS

L<bin::mozilla::pw> implements the following functions:

=head2 getpassword

  &getpassword($s);

=cut
