#=====================================================================
# SQL-Ledger Accounting
# Copyright (c) 2004
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
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


1;
# end of main


sub getpassword {
  my ($s) = @_;

  my $login = ($form->{"root login"}) ? "root login" : $form->{login};
  
  my @d = split / +/, scalar gmtime(time);
  my $today = "$d[0], $d[2]-$d[1]-$d[4] $d[3] GMT";
  
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
<script language="JavaScript" type="text/javascript">
<!--
function sf(){
    document.pw.password.focus();
}
// End -->
</script>

<body onload="sf()">

  $sessionexpired

<form method=post action=$form->{script} name=pw>

<table>
  <tr>
    <th align=right>|.$locale->text('Password').qq|</th>
    <td><input type=password name=password size=30></td>
    <td><input type=submit value="|.$locale->text('Continue').qq|"></td>
  </tr>
</table>

|;

  for (qw(script password header sessioncookie)) { delete $form->{$_} }
  $form->hide_form;
  
  print qq|
</form>

</body>
</html>
|;

}


