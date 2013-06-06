#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================


1;
# end of main


sub getpassword {
  my ($s) = @_;

  if (-f "$form->{path}/custom_pw.pl") {
    require "$form->{path}/custom_pw.pl";
  }

  my $login = ($form->{"root login"}) ? "root login" : $form->{login};
  
  my @d = split / +/, scalar gmtime(time);
  my $today = "$d[0], $d[2]-$d[1]-$d[4] $d[3] GMT";
  
  $pwt = $locale->text('Password');

  if ($form->{stylesheet} && (-f "css/$form->{stylesheet}")) {
    $stylesheet = qq|<LINK REL="stylesheet" HREF="css/$form->{stylesheet}" TYPE="text/css" TITLE="SQL-Ledger stylesheet">
|;
  }

  if ($form->{charset}) {
    $charset = qq|<META HTTP-EQUIV="Content-Type" CONTENT="text/plain; charset=$form->{charset}">
|;
  }

  print qq|Set-Cookie: SL-$login=; expires=$today; path=/;
Content-Type: text/html

<head>
  <title>$form->{titlebar}</title>
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
    <td><input type=password name=password value="$form->{password}" size=30></td>
    <td><input type=submit class=submit value="|.$locale->text('Continue').qq|"></td>
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


