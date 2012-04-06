1;

# Tekki: Software Administration

sub software_administration {

  my @branches = `git branch -v`;

  $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." / ".$locale->text('Software Administration');
  $msg &&= "<pre>$msg</pre>"; 
  $form->header;

  print qq|
<body class="admin">
$msg
<center>
<h2>$form->{title}</h2>

<form method="post" action="$script">
<input type="hidden" name="path" value="$form->{path}">
<input type="hidden" name="callback" value="$script?action=list_datasets=$form->{path}">
<table>
  <tr class="listheading">
    <th colspan=4>|.$locale->text('Local branches').qq|</th>
  <tr>|;
  for (@branches) {
  	my ( $active, $name, $commit ) = /(.).(.*?)\s+(.*?)\s+/;
  	my $link = $active eq '*' ?
  	  '' : "<a href=\"$script?action=switch_branch&branch=$name&path=$form->{path}\">".$locale->text('Switch branch')."</a>";
  	$i++; $i %= 2;
  	print qq|
  <tr class="listrow$i">
    <td>$active</td>
    <td>$name</td>
    <td>$commit</td>
    <td>$link</td>
  </tr>
|;
  }
  print qq|
  <tr>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td colspan="4">
      <input class="submit" type="submit" name="action" value="|.$locale->text('Update Software').qq|">
      <input class="submit" type="submit" name="action" value="|.$locale->text('Main Menu').qq|">
    </td>
  </tr>
</table>
</form>

</center>
</body>
</html>
|;
}

sub main_menu {
  &list_datasets;
}

sub switch_branch {
  my $newbranch = $form->{branch};
  $msg = `sudo git checkout $newbranch 2>&1`;
  &software_administration;
}

sub update_software {
  $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." / ".$locale->text('Update Software');
  $form->header;

  print qq|
<body class="admin">
<h2>$form->{title}</h2>
<pre>|;
  print $_ for `sudo git pull 2>&1`;
  print qq|
<pre>

<form action="$script">
<input type="hidden" name="path" value="$form->{path}">
<input type="hidden" name="nextsub" value="software_administration">
<input type="submit" class="submit" name="action" value="|.$locale->text('Continue').qq|">
</form>
</body>
</html>
|;
}
