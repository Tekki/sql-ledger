# WLprinter start
$printer{WLprinter} = "wlprinter/fileprinter.pl $form->{login}";
# WLprinter end

1;

# Tekki: Software Administration
sub list_users {

  open(FH, "$memberfile") or $form->error("$memberfile : $!");

  $nologin = qq|
<input type=submit class=submit name=action value="|.$locale->text('Lock System').qq|">|;

  if (-e "$userspath/nologin") {
    $nologin = qq|
<input type=submit class=submit name=action value="|.$locale->text('Unlock System').qq|">|;
  }

  $software = qq|
<input type=submit class=submit name=action value="|.$locale->text('Software Administration').qq|">|;

  while (<FH>) {
    chop;
    
    if (/^\[.*\]/) {
      $login = $_;
      $login =~ s/(\[|\])//g;
    }

    if (/^(name=|company=|templates=|dbuser=|dbdriver=|dbname=|dbhost=)/) {
      chop ($var = $&);
      ($null, $member{$login}{$var}) = split /=/, $_, 2;
    }
  }
  
  close(FH);

# type=submit $locale->text('Pg Database Administration')
# type=submit $locale->text('PgPP Database Administration')
# type=submit $locale->text('Oracle Database Administration')
# type=submit $locale->text('Sybase Database Administration')

  foreach $item (User->dbdrivers) {
    $dbdrivers .= qq|<input name=action type=submit class=submit value="|.$locale->text("$item Database Administration").qq|">|;
  }


  $column_header{login} = qq|<th>|.$locale->text('Login').qq|</th>|;
  $column_header{name} = qq|<th>|.$locale->text('Name').qq|</th>|;
  $column_header{company} = qq|<th>|.$locale->text('Company').qq|</th>|;
  $column_header{dbdriver} = qq|<th>|.$locale->text('Driver').qq|</th>|;
  $column_header{dbhost} = qq|<th>|.$locale->text('Host').qq|</th>|;
  $column_header{dataset} = qq|<th>|.$locale->text('Dataset').qq|</th>|;
  $column_header{templates} = qq|<th>|.$locale->text('Templates').qq|</th>|;

  @column_index = qw(login name company dbdriver dbhost dataset templates);

  $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." ".$locale->text('Administration');


  $form->header;

  print qq|
<body class=admin>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
  <tr class=listheading>
    <th>$form->{title}</th>
  </tr>
  <tr size=5></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>|;

  for (@column_index) { print "$column_header{$_}\n" }
  
  print qq|
        </tr>
|;

foreach $key (sort keys %member) {
  $href = "$script?action=edit&login=$key&path=$form->{path}";
  $href =~ s/ /%20/g;
  
  $member{$key}{templates} =~ s/^$templates\///;
  $member{$key}{dbhost} = $locale->text('localhost') unless $member{$key}{dbhost};
  $member{$key}{dbname} = $member{$key}{dbuser} if ($member{$key}{dbdriver} eq 'Oracle');

  $column_data{login} = qq|<td><a href=$href>$key</a></td>|;
  $column_data{name} = qq|<td>$member{$key}{name}</td>|;
  $column_data{company} = qq|<td>$member{$key}{company}</td>|;
  $column_data{dbdriver} = qq|<td>$member{$key}{dbdriver}</td>|;
  $column_data{dbhost} = qq|<td>$member{$key}{dbhost}</td>|;
  $column_data{dataset} = qq|<td>$member{$key}{dbname}</td>|;
  $column_data{templates} = qq|<td>$member{$key}{templates}</td>|;
  
  $i++; $i %= 2;
  print qq|
        <tr class=listrow$i>|;

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>|;
}


print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=path value=$form->{path}>

<br><input type=submit class=submit name=action value="|.$locale->text('Add User').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Change Admin Password').qq|">

$dbdrivers
$nologin
$software

<input type=submit class=submit name=action value="|.$locale->text('Logout').qq|">

</form>

|.$locale->text('Click on login name to edit!').qq|
<br>
|.$locale->text('To add a user to a group edit a name, change the login name and save.  A new user with the same variables will then be saved under the new login name.').qq|

</body>
</html>
|;

}

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
<input type="hidden" name="callback" value="$script?action=list_users&path=$form->{path}">
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
