1;

# Tekki: Logo screen with branch info
sub company_logo {
  
  $myconfig{dbhost} = $locale->text('localhost') unless $myconfig{dbhost};

  AM->company_defaults(\%myconfig, \%$form);
  $form->{address} =~ s/\n/<br>/g;
  
  $form->{stylesheet} = $myconfig{stylesheet};

  $form->{title} = $locale->text('About');

  # collect branch information
  my @branches = `git branch -v`;
  if (@branches) {
  	$branches = '<table>';
  	for (@branches) {
      my ( $active, $name, $commit ) = /(..)(.*?)\s+(.*?)\s+/;
      $i++; $i %= 2;
      $branches .= qq|
  <tr class="listrow$i">
    <td>$active</td>
    <td>$name</td>
    <td>$commit</td>
  </tr>|;
  	}
  	$branches .= qq|
</table>|;
  }

  # create the logo screen
  $form->header;

  print qq|
<body>

<pre>





</pre>
<center>
<a href="http://www.sql-ledger.org" target=_blank><img src=$images/sql-ledger.gif border=0></a>
<h1 class=login>|.$locale->text('Version').qq| $form->{version}</h1>
$branches
<p>
|.$locale->text('Licensed to').qq|
<p>
<b>
$form->{company}
<br>$form->{address}
</b>

<p>
<table border=0>
  <tr>
    <th align=right>|.$locale->text('User').qq|</th>
    <td>$myconfig{name}</td>
  </tr>
  <tr>
    <th align=right>|.$locale->text('Dataset').qq|</th>
    <td>$myconfig{dbname}</td>
  </tr>
  <tr>
    <th align=right>|.$locale->text('Database Host').qq|</th>
    <td>$myconfig{dbhost}</td>
  </tr>
</table>

</center>

</body>
</html>
|;

}
