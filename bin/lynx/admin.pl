#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# setup module
# add/edit/delete users
#
#======================================================================

$menufile = "menu.ini";

use SL::Form;
use SL::User;


$form = new Form;

$locale = new Locale $language, "admin";
$form->{charset} = $locale->{charset};

eval { require DBI; };
$form->error($locale->text('DBI not installed!')) if ($@);

$form->{stylesheet} = "sql-ledger.css";
$form->{favicon} = "favicon.ico";
$form->{timeout} = 600;
$form->{"root login"} = 1;

require "$form->{path}/pw.pl";

# customization
if (-f "$form->{path}/custom_$form->{script}") {
  eval { require "$form->{path}/custom_$form->{script}"; };
  $form->error($@) if ($@);
}


if ($form->{action}) {

  &check_password unless $form->{action} eq 'logout';
  
  &{ $locale->findsub($form->{action}) };
    
} else {

  # if there are no drivers bail out
  $form->error($locale->text('No Database Drivers available!')) unless (User->dbdrivers);

  # create memberfile
  if (! -f $memberfile) {
    open(FH, ">$memberfile") or $form->error("$memberfile : $!");
    print FH qq|# SQL-Ledger Accounting members

[root login]
password=

|;
    close FH;
  }

  &adminlogin;

}

1;
# end


sub adminlogin {

  $form->{title} = qq|SQL-Ledger $form->{version} |.$locale->text('Administration');
  
  $form->header;
  
    print qq|
<script language="JavaScript" type="text/javascript">
<!--
function sf(){
  document.forms[0].password.focus();
}
// End -->
</script>

<body class=admin onload="sf()">

<div align=center>

<a href="http://www.sql-ledger.org"><img src=$images/sql-ledger.gif border=0 target=_blank></a>
<h1 class=login>|.$locale->text('Version').qq| $form->{version}<p>|.$locale->text('Administration').qq|</h1>

<form method=post action="$form->{script}">

<table>
  <tr>
    <th>|.$locale->text('Password').qq|</th>
    <td><input type=password name=password></td>
    <td><input type=submit class=submit name=action value="|.$locale->text('Login').qq|"></td>
  </tr>
<input type=hidden name=action value=login>
<input type=hidden name=path value=$form->{path}>
</table>

</form>

<a href=http://www.sql-ledger.org target=_blank>SQL-Ledger |.$locale->text('website').qq|</a>

</div>

</body>
</html>
|;

}


sub create_config {

  $form->{sessionkey} = "";
  $form->{sessioncookie} = "";
  
  if ($form->{password}) {
    my $t = time + $form->{timeout};
    srand( time() ^ ($$ + ($$ << 15)) );
    $key = "root login$form->{password}$t";

    my $i = 0;
    my $l = length $key;
    my $j = $l;
    my %ndx = ();
    my $pos;

    while ($j > 0) {
      $pos = int rand($l);
      next if $ndx{$pos};
      $ndx{$pos} = 1;
      $form->{sessioncookie} .= substr($key, $pos, 1);
      $form->{sessionkey} .= substr("0$pos", -2);
      $j--;
    }
  }

  open(CONF, ">$userspath/root login.conf") or $form->error("root login.conf : $!");
  print CONF qq|# configuration file for root login

\%rootconfig = (
sessionkey => '$form->{sessionkey}'
);\n\n|;

  close CONF;

}


sub login {

  &create_config;
  &list_users;

}


sub logout {

  $form->{callback} = "$form->{script}?path=$form->{path}";
  $form->redirect($locale->text('You are logged out'));

}


sub add_user {
  
  $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." ".$locale->text('Administration')." / ".$locale->text('Add User');

  $form->{Oracle_sid} = $sid;
  $form->{Oracle_dbport} = '1521';
  $form->{Oracle_dbhost} = `hostname`;

  if (-f "css/sql-ledger.css") {
    $myconfig->{stylesheet} = "sql-ledger.css";
  }
  $myconfig->{vclimit} = 1000;
  $myconfig->{menuwidth} = 155;
  $myconfig->{timeout} = 10800;
  
  &form_header;
  &form_footer;
  
}



sub edit {

  $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." ".$locale->text('Administration')." / ".$locale->text('Edit User');
  $form->{edit} = 1;

  &form_header;
  &form_footer;

}


sub form_footer {

  if ($form->{edit}) {
    $delete = qq|<input type=submit class=submit name=action value="|.$locale->text('Delete').qq|">
<input type=hidden name=edit value=1>|;
  }

  print qq|

<input name=callback type=hidden value="$form->{script}?action=list_users&path=$form->{path}">

<input type=hidden name=path value=$form->{path}>

<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">
$delete

</form>

</body>
</html>
|;

}


sub list_users {

  open(FH, "$memberfile") or $form->error("$memberfile : $!");

  $nologin = qq|
<input type=submit class=submit name=action value="|.$locale->text('Lock System').qq|">|;

  if (-e "$userspath/nologin") {
    $nologin = qq|
<input type=submit class=submit name=action value="|.$locale->text('Unlock System').qq|">|;
  }


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

<input type=submit class=submit name=action value="|.$locale->text('Logout').qq|">

</form>

|.$locale->text('Click on login name to edit!').qq|
<br>
|.$locale->text('To add a user to a group edit a name, change the login name and save.  A new user with the same variables will then be saved under the new login name.').qq|

</body>
</html>
|;

}



sub form_header {

  # if there is a login, get user
  if ($form->{login}) {
    # get user
    $myconfig = new User "$memberfile", "$form->{login}";

    $myconfig->{signature} =~ s/\\n/\n/g;

    # strip basedir from templates directory
    $myconfig->{templates} =~ s/^$templates\///;

    $myconfig->{dbpasswd} = unpack 'u', $myconfig->{dbpasswd};
  }

  for (qw(mm-dd-yy mm/dd/yy dd-mm-yy dd/mm/yy dd.mm.yy yyyy-mm-dd)) { $selectdateformat .= "$_\n" }

  for (qw(1,000.00 1000.00 1.000,00 1000,00 1'000.00)) { $selectnumberformat .= "$_\n" }

  %countrycodes = User->country_codes;
  $selectcountrycodes = "";
  
  for (sort { $countrycodes{$a} cmp $countrycodes{$b} } keys %countrycodes) { $selectcountrycodes .= "${_}--$countrycodes{$_}" }
  $selectcountrycodes = qq|--English\n$selectcountrycodes|;

  # is there a templates basedir
  if (! -d "$templates") {
    $form->error($locale->text('Directory').": $templates ".$locale->text('does not exist'));
  }

  opendir TEMPLATEDIR, "$templates/." or $form->error("$templates : $!");
  @all = grep !/^\.\.?$/, readdir TEMPLATEDIR;
  closedir TEMPLATEDIR;

  @allhtml = sort grep /\.html/, @all;

  @alldir = ();
  for (@all) {
    if (-d "$templates/$_") {
      push @alldir, $_;
    }
  }
  
  @allhtml = reverse grep !/Default/, @allhtml;
  push @allhtml, 'Default';
  @allhtml = reverse @allhtml;
  
  for (sort @alldir) { $selectusetemplates .= qq|$_\n| }
  
  $lastitem = $allhtml[0];
  $lastitem =~ s/-.*//g;
  $selectmastertemplates = qq|$lastitem\n|;
  for (@allhtml) {
    $_ =~ s/-.*//g;
    
    if ($_ ne $lastitem) {
      $selectmastertemplates .= qq|$_\n|;
      $lastitem = $_;
    }
  }

  opendir CSS, "css/.";
  @all = grep /.*\.css$/, readdir CSS;
  closedir CSS;
  
  $selectstylesheet = "\n";
  for (sort @all) { $selectstylesheet .= qq|$_\n| }
  
  if (%printer && $latex) {
    $selectprinter = "\n";
    for (sort keys %printer) { $selectprinter .= "$_\n" }

    $printer = qq|
	<tr>
	  <th align=right>|.$locale->text('Printer').qq|</th>
	  <td><select name=printer>|.$form->select_option($selectprinter, $myconfig->{printer}).qq|</td>
	</tr>
|;

  }
  
  $form->header;
 
  print qq|
<body class=admin>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listheading><th colspan=2>$form->{title}</th></tr>
  <tr size=5></tr>
  <tr valign=top>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Login').qq|</th>
	  <td><input name=login value="$myconfig->{login}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Password').qq|</th>
	  <td><input type=password name=new_password size=8 value=$myconfig->{password}></td>
	  <input type=hidden name=old_password value=$myconfig->{password}>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Name').qq|</th>
	  <td><input name=name size=15 value="|.$form->quote($myconfig->{name}).qq|"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('E-mail').qq|</th>
	  <td><input name=email size=30 value="$myconfig->{email}"></td>
	</tr>
	<tr valign=top>
	  <th align=right>|.$locale->text('Signature').qq|</th>
	  <td><textarea name=signature rows=3 cols=35>$myconfig->{signature}</textarea></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Phone').qq|</th>
	  <td><input name=tel size=14 value="$myconfig->{tel}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Fax').qq|</th>
	  <td><input name=fax size=14 value="$myconfig->{fax}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Company').qq|</th>
	  <td><input name=company size=35 value="|.$form->quote($myconfig->{company}).qq|"></td>
	</tr>
      </table>
    </td>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Date Format').qq|</th>
	  <td><select name=dateformat>|.$form->select_option($selectdateformat, $myconfig->{dateformat}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Number Format').qq|</th>
	  <td><select name=numberformat>|.$form->select_option($selectnumberformat, $myconfig->{numberformat}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Dropdown Limit').qq|</th>
	  <td><input name=vclimit value="$myconfig->{vclimit}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Menu Width').qq|</th>
	  <td><input name=menuwidth value="$myconfig->{menuwidth}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Language').qq|</th>
	  <td><select name=countrycode>|.$form->select_option($selectcountrycodes, $myconfig->{countrycode}, undef, 1).qq|</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Session Timeout').qq|</th>
	  <td><input name=newtimeout value="$myconfig->{timeout}"></td>
	</tr>

	<tr>
	  <th align=right>|.$locale->text('Stylesheet').qq|</th>
	  <td><select name=userstylesheet>|.$form->select_option($selectstylesheet, $myconfig->{stylesheet}).qq|</select></td>
	</tr>
	$printer
	<tr>
	  <th align=right>|.$locale->text('Use Templates').qq|</th>
	  <td><select name=usetemplates>|.$form->select_option($selectusetemplates, $myconfig->{templates}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('New Templates').qq|</th>
	  <td><input name=newtemplates></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Setup Templates').qq|</th>
	  <td><select name=mastertemplates>|.$form->select_option($selectmastertemplates, $myconfig->{templates}).qq|</select></td>
	</tr>
	<input type=hidden name=templates value=$myconfig->{templates}>
      </table>
    </td>
  </tr>
  <tr class=listheading>
    <th colspan=2>|.$locale->text('Database').qq|</th>
  </tr>|;

    # list section for database drivers
    foreach $item (User->dbdrivers) {
      
    print qq|
  <tr>
    <td colspan=2>
      <table>
	<tr>|;

    $checked = "";
    if ($myconfig->{dbdriver} eq $item) {
      for (qw(dbhost dbport dbuser dbpasswd dbname sid)) { $form->{"${item}_$_"} = $myconfig->{$_} }
      $checked = "checked";
    }

    print qq|
	  <th align=right>|.$locale->text('Driver').qq|</th>
	  <td><input name=dbdriver type=radio class=radio value=$item $checked>&nbsp;$item</td>
	  <th align=right>|.$locale->text('Host').qq|</th>
	  <td><input name="${item}_dbhost" size=30 value=$form->{"${item}_dbhost"}></td>
	</tr>
	<tr>|;

    if ($item =~ /(Pg|Sybase)/) {
      print qq|
	  <th align=right>|.$locale->text('Dataset').qq|</th>
	  <td><input name="${item}_dbname" size=15 value=$form->{"${item}_dbname"}></td>
	  <th align=right>|.$locale->text('Port').qq|</th>
	  <td><input name="${item}_dbport" size=4 value=$form->{"${item}_dbport"}></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('User').qq|</th>
	  <td><input name="${item}_dbuser" size=15 value=$form->{"${item}_dbuser"}></td>
	  <th align=right>|.$locale->text('Password').qq|</th>
	  <td><input name="${item}_dbpasswd" type=password size=10 value=$form->{"${item}_dbpasswd"}></td>
	</tr>|;

    }

    if ($item eq 'Oracle') {
      print qq|
	  <th align=right>SID</th>
	  <td><input name=Oracle_sid value=$form->{Oracle_sid}></td>
	  <th align=right>|.$locale->text('Port').qq|</th>
	  <td><input name="${item}_dbport size=4 value=$form->{"${item}_dbport"}></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Dataset').qq|</th>
	  <td><input name="${item}_dbuser" size=15 value=$form->{"${item}_dbuser"}></td>
	  <th align=right>|.$locale->text('Password').qq|</th>
	  <td><input name="${item}_dbpasswd" type=password size=10 value=$form->{"${item}_dbpasswd"}></td>
	  
	</tr>|;
    }
    
      
    print qq|
	<input type=hidden name=old_dbpasswd value=$myconfig->{dbpasswd}>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=2><hr size=2 noshade></td>
  </tr>
|;

  }


  # access control
  open(FH, $menufile) or $form->error("$menufile : $!");
  # scan for first menu level
  @a = <FH>;
  close(FH);
  
  if (open(FH, "custom_$menufile")) {
    push @a, <FH>;
  }
  close(FH);

  foreach $item (@a) {
    next unless $item =~ /\[\w+/;
    next if $item =~ /\#/;

    $item =~ s/(\[|\])//g;
    chop $item;

    if ($item =~ /--/) {
      ($level, $menuitem) = split /--/, $item, 2;
    } else {
      $level = $item;
      $menuitem = $item;
      push @acsorder, $item;
    }

    push @{ $acs{$level} }, $menuitem;

  }
  
  %role = ( 'admin' => $locale->text('Administrator'),
            'user' => $locale->text('User'),
            'supervisor' => $locale->text('Supervisor'),
	    'manager' => $locale->text('Manager')

	   );
	    
  $selectrole = "";
  for (qw(user admin supervisor manager)) { $selectrole .= "$_--$role{$_}\n" }
  
  print qq|
  <tr class=listheading>
    <th colspan=2>|.$locale->text('Access Control').qq|</th>
  </tr>
  <tr>
    <td><select name=role>|.$form->select_option($selectrole, $myconfig->{role}, undef, 1).qq|</select></td>
  </tr>
|;
  
  foreach $item (split /;/, $myconfig->{acs}) {
    ($key, $value) = split /--/, $item, 2;
    $excl{$key}{$value} = 1;
  }
  
  foreach $key (@acsorder) {

    $checked = "checked";
    if ($form->{login}) {
      $checked = ($excl{$key}{$key}) ? "" : "checked";
    }
    
    # can't have variable names with & and spaces
    $item = $form->escape("${key}--$key",1);

    $acsheading = $key;
    $acsheading =~ s/ /&nbsp;/g;

    $acsheading = qq|
    <th align=left nowrap><input name="$item" class=checkbox type=checkbox value=1 $checked>&nbsp;$acsheading</th>\n|;
    $menuitems .= "$item;";
    $acsdata = "
    <td>";

    foreach $item (@{ $acs{$key} }) {

      next if ($key eq $item);

      $checked = "checked";
      if ($form->{login}) {
	$checked = ($excl{$key}{$item}) ? "" : "checked";
      }

      $acsitem = $form->escape("${key}--$item",1);

      $acsdata .= qq|
    <br><input name="$acsitem" class=checkbox type=checkbox value=1 $checked>&nbsp;$item|;
      $menuitems .= "$acsitem;";
    }

    $acsdata .= "
    </td>";

    print qq|
  <tr valign=top>$acsheading $acsdata
  </tr>
|;
  }
  
  print qq|<input type=hidden name=acs value="$menuitems">
  
   <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
</div>
|;

}


sub save {

  # no driver checked
  $form->error($locale->text('Database Driver not checked!')) unless $form->{dbdriver};
  
  $form->isblank("login", $locale->text('Login name missing!'));
 
  # no spaces or strange characters allowed in login name
  $form->error($locale->text('No space allowed for login!')) if $form->{login} =~ / /;
  if ($form->{login} =~ /\W/) {
    $login = $form->{login};
    $login =~ s/\@//;
    
    $form->error($locale->text('login may only contain alphanumeric characters!')) if $login =~ /\W/;
  }
  
  # check for duplicates
  if (!$form->{edit}) {
    $temp = new User "$memberfile", "$form->{login}";
   
    if ($temp->{login}) {
      $form->error("$form->{login} ".$locale->text('is already a member!'));
    }
  }
  
  # no spaces allowed in directories
  $form->{newtemplates} =~ s/( |\.\.|\*)//g;
  
  if ($form->{newtemplates} ne "") {
    $form->{templates} = $form->{newtemplates};
  } else {
    $form->{templates} = ($form->{usetemplates}) ? $form->{usetemplates} : $form->{login};
  }
  
  # is there a basedir
  if (! -d "$templates") {
    $form->error($locale->text('Directory').": $templates ".$locale->text('does not exist'));
  }

  # add base directory to $form->{templates}
  $form->{templates} = "$templates/$form->{templates}";


  $myconfig = new User "$memberfile", "$form->{login}";

  # redo acs variable and delete all the acs codes
  @acs = split /;/, $form->{acs};

  $form->{acs} = "";
  foreach $item (@acs) {
    $item = $form->escape($item,1);
    if (!$form->{$item}) {
      $form->{acs} .= $form->unescape($form->unescape("$item")).";";
    }
    delete $form->{$item};
  }

  # check which database was filled in
  
  $form->{dbhost} = $form->{"$form->{dbdriver}_dbhost"};
  $form->{dbport} = $form->{"$form->{dbdriver}_dbport"};
  $form->{dbpasswd} = $form->{"$form->{dbdriver}_dbpasswd"};
  $form->{dbuser} = $form->{"$form->{dbdriver}_dbuser"};
  $form->{dbname} = $form->{"$form->{dbdriver}_dbname"};

  if ($form->{dbdriver} eq 'Oracle') {
    $form->{sid} = $form->{Oracle_sid}, ;

    $form->isblank("dbhost", $locale->text('Hostname missing!'));
    $form->isblank("dbport", $locale->text('Port missing!'));
    $form->isblank("dbuser", $locale->text('Dataset missing!'));
  }
  if ($form->{dbdriver} =~ /(Pg|Sybase)/) {
    $form->isblank("dbname", $locale->text('Dataset missing!'));
    $form->isblank("dbuser", $locale->text('Database User missing!'));
  }
    
  for (keys %{$form}) {
    $myconfig->{$_} = $form->{$_};
  }

  $myconfig->{encrypted} = $form->{new_password} eq $form->{old_password};
  $myconfig->{password} = $form->{new_password};

  $myconfig->{timeout} = $form->{newtimeout};

  delete $myconfig->{stylesheet};
  if ($form->{userstylesheet}) {
    $myconfig->{stylesheet} = $form->{userstylesheet};
  }
  
  $myconfig->{packpw} = 1;
  delete $myconfig->{"root login"};
  
  $myconfig->save_member($memberfile, $userspath);

  # create user template directory and copy master files
  if (! -d "$form->{templates}") {
    
    umask(002);
    
    if (mkdir "$form->{templates}", oct("771")) {
      
      umask(007);
      
      # copy templates to the directory
      opendir TEMPLATEDIR, "$templates/." or $form->error("$templates : $!");
      @templates = grep /$form->{mastertemplates}-/, readdir TEMPLATEDIR;
      closedir TEMPLATEDIR;

      foreach $file (@templates) {
	open(TEMP, "$templates/$file") or $form->error("$templates/$file : $!");
	
	$file =~ s/$form->{mastertemplates}-//;
	open(NEW, ">$form->{templates}/$file") or $form->error("$form->{templates}/$file : $!");
	  
	while ($line = <TEMP>) {
	  print NEW $line;
	}
	close(TEMP);
	close(NEW);
      }
    } else {
      $form->error("$form->{templates} : $!");
    }
  }

  $form->redirect($locale->text('User saved!'));
  
}


sub delete {

  $form->{templates} = ($form->{templates}) ? "$templates/$form->{templates}" : "$templates/$form->{login}";
  
  $form->error("$memberfile ".$locale->text('locked!')) if (-f ${memberfile}.LCK);

  open(FH, ">${memberfile}.LCK") or $form->error("${memberfile}.LCK : $!");
  close(FH);
  
  if (! open(CONF, "+<$memberfile")) {
    unlink "${memberfile}.LCK";
    $form->error("$memberfile : $!");
  }

  @config = <CONF>;

  seek(CONF, 0, 0);
  truncate(CONF, 0);
  
  while ($line = shift @config) {

    chop $line;

    if ($line =~ /^\[/) {
      last if ($line eq "[$form->{login}]");
      $login = &login_name($line);
    }
    
    if ($line =~ /^templates=/) {
      ($null, $user{$login}) = split /=/, $line, 2;
    }

    print CONF "$line\n";
  }

  # remove everything up to next login or EOF
  # and save template variable
  while ($line = shift @config) {

    chop $line;
    
    ($key, $value) = split /=/, $line, 2;
    $myconfig{$key} = $value;
    
    last if ($line =~ /^\[/);
  }

  # this one is either the next login or EOF
  print CONF "$line\n";

  $login = &login_name($line);
  

  while ($line = shift @config) {

    chop $line;

    if ($line =~ /^\[/) {
      $login = &login_name($line);
    }
    
    if ($line =~ /^templates=/) {
      ($null, $user{$login}) = split /=/, $line, 2;
    }
    
    print CONF "$line\n";
  }

  close(CONF);
  unlink "${memberfile}.LCK";

  # scan %user for $templatedir
  foreach $login (keys %user) {
    last if ($found = ($form->{templates} eq $user{$login}));
  }

  # if found keep directory otherwise delete
  if (!$found) {
    # delete it if there is a template directory
    $dir = "$form->{templates}";
    if (-d "$dir") {
      unlink <$dir/*>;
      rmdir "$dir";
    }
  }

  if ($myconfig{dbconnect}) {
    $myconfig{dbpasswd} = unpack 'u', $myconfig{dbpasswd};
    for (keys %myconfig) { $form->{$_} = $myconfig{$_} }

    User->delete_login(\%$form);
  
    # delete config file for user
    unlink "$userspath/$form->{login}.conf";
  }

  $form->redirect($locale->text('User deleted!'));
  
}


sub login_name {
  my $login = shift;
  
  $login =~ s/\[\]//g;
  return ($login) ? $login : undef;
  
}


sub change_admin_password {

  $form->{title} = qq|SQL-Ledger |.$locale->text('Accounting')." ".$locale->text('Administration')." / ".$locale->text('Change Admin Password');

  $form->header;

  print qq|
<body class=admin>

<form method=post action=$form->{script}>

<table>
  <tr>
  <tr class=listheading>
    <th>|.$locale->text('Change Password').qq|</th>
  </tr>
  <tr size=5></tr>
  <tr>
    <td>
      <table width=100%>
        <tr>
          <th align=right>|.$locale->text('Password').qq|</th>
	  <td><input type=password name=new_password></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Confirm').qq|</th>
	  <td><input type=password name=confirm_password></td>
	</tr>
      </table>
    </td>
  </tr>

</table>

<br>
<hr size=3 noshade>
<input type=hidden name=path value=$form->{path}>

<p>
<input type=submit class=submit name=action value="|.$locale->text('Change Password').qq|">

</form>

</body>
</html>
|;

}


sub change_password {

  $form->error($locale->text('Passwords do not match!')) if $form->{new_password} ne $form->{confirm_password};
  
  $root->{password} = $form->{new_password};
  
  $root->{'root login'} = 1;
  $root->{login} = "root login";
  $root->save_member($memberfile);

  $form->{password} = $form->{new_password};
  &create_config;
  
  $form->{callback} = "$form->{script}?action=list_users&path=$form->{path}&password=$form->{password}";

  $form->redirect($locale->text('Password changed!'));

}


sub check_password {

  $root = new User "$memberfile", "root login";

  $rootname = "root login";
  eval { require "$userspath/${rootname}.conf"; };
  
  if ($root->{password}) {
      
    if ($form->{password}) {
      $form->{callback} .= "&password=$form->{password}" if $form->{callback};
      if ($root->{password} ne crypt $form->{password}, 'ro') {
	&getpassword;
	exit;
      }

      # create config
      &create_config;
      
    } else {
      
      if ($ENV{HTTP_USER_AGENT}) {
	$ENV{HTTP_COOKIE} =~ s/;\s*/;/g;
	@cookies = split /;/, $ENV{HTTP_COOKIE};
	%cookie = ();
	foreach (@cookies) {
	  ($name,$value) = split /=/, $_, 2;
	  $cookie{$name} = $value;
	}
	
	$cookie = ($form->{path} eq 'bin/lynx') ? $cookie{login} : $cookie{"SL-root login"};

        if ($cookie) {
	  $form->{sessioncookie} = $cookie;

	  $s = "";
	  %ndx = ();
	  $l = length $form->{sessioncookie};

	  for $i (0 .. $l - 1) {
	    $j = substr($rootconfig{sessionkey}, $i * 2, 2);
	    $ndx{$j} = substr($cookie, $i, 1);
	  }

	  for (sort keys %ndx) {
	    $s .= $ndx{$_};
	  }

	  $l = length 'root login';
	  $login = substr($s, 0, $l);
	  $time = substr($s, -10);
	  $password = substr($s, $l, (length $s) - ($l + 10));
	  
	  if ((time > $time) || ($login ne 'root login') || ($root->{password} ne crypt $password, 'ro')) {
	    &getpassword;
	    exit;
	  }

	} else {
	  &getpassword;
	  exit;
	}
      } else {
	&getpassword;
	exit;
      }
    }
  }

}


sub pg_database_administration {

  $form->{dbdriver} = 'Pg';
  &dbselect_source;

}


sub pgpp_database_administration {

  $form->{dbdriver} = 'PgPP';
  &dbselect_source;

}


sub oracle_database_administration {
  
  $form->{dbdriver} = 'Oracle';
  &dbselect_source;

}


sub sybase_database_administration {
  
  $form->{dbdriver} = 'Sybase';
  &dbselect_source;

}


sub dbdriver_defaults {

  # load some defaults for the selected driver
  %driverdefaults = ( 'Pg' => { dbport => '',
                                dbuser => 'sql-ledger',
		             dbdefault => 'template1',
				dbhost => '',
			 connectstring => $locale->text('Connect to')
			      },
                  'Oracle' => { dbport => '1521',
		                dbuser => 'oralin',
		             dbdefault => $sid,
				dbhost => `hostname`,
			 connectstring => 'SID'
			      },
                   'Sybase' => { dbport => '',
		                dbuser => 'sql-ledger',
		             dbdefault => '',
				dbhost => '',
			 connectstring => $locale->text('Connect to')
			      }
                    );

  $driverdefaults{PgPP} = $driverdefaults{Pg};

  for (keys %{ $driverdefaults{Pg} }) { $form->{$_} = $driverdefaults{$form->{dbdriver}}{$_} }

}
  

sub dbselect_source {

  &dbdriver_defaults;

 $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." / ".$locale->text('Database Administration');
  
  $form->header;

  print qq|
<body class=admin>

<center>
<h2>$form->{title}</h2>

<form method=post action=$form->{script}>

<table>
  <tr>
    <td>
      <table>
	<tr class=listheading>
	  <th colspan=4>|.$locale->text('Database').qq|</th>
	</tr>
	<input type=hidden name=dbdriver value=$form->{dbdriver}>
	<tr>
	  <td>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Host').qq|</th>
		<td><input name=dbhost size=25 value=$form->{dbhost}></td>
		<th align=right>|.$locale->text('Port').qq|</th>
		<td><input name=dbport size=5 value=$form->{dbport}></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('User').qq|</th>
		<td><input name=dbuser size=10 value=$form->{dbuser}></td>
		<th align=right>|.$locale->text('Password').qq|</th>
		<td><input type=password name=dbpasswd size=10></td>
	      </tr>
	      <tr>

		<th align=right>$form->{connectstring}</th>
		<td colspan=3><input name=dbdefault size=10 value=$form->{dbdefault}></td>

	      </tr>
	    </table>
	  </td>
	</tr>
      </table>

<input name=callback type=hidden value="$form->{script}?action=list_users&path=$form->{path}">
<input type=hidden name=path value=$form->{path}>

<br>

<input type=submit class=submit name=action value="|.$locale->text('Create Dataset').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Update Dataset').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Delete Dataset').qq|">

</form>

    </td>
  </tr>
</table>

<p>|.$locale->text('This is a preliminary check for existing sources. Nothing will be created or deleted at this stage!')

.qq|
</body>
</html>
|;

}


sub continue {

  &{ $form->{nextsub} };

}


sub update_dataset {

  %needsupdate = User->dbneedsupdate(\%$form);

  $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." ".$locale->text('Database Administration')." / ".$locale->text('Update Dataset');
  
  $form->header;

  print qq|
<body class=admin>


<center>
<h2>$form->{title}</h2>
|;


  foreach $key (sort keys %needsupdate) {
    if ($needsupdate{$key} ne $form->{dbversion}) {
      $upd .= qq|<input name="db$key" class=checkbox type=checkbox value=1 checked> $key\n|;
      $form->{dbupdate} .= "db$key ";
    }
  }

  chop $form->{dbupdate};


  if ($form->{dbupdate}) {

    print qq|
<table width=100%>
<form method=post action=$form->{script}>
|;

    $form->{callback} = "$form->{script}?action=list_users&path=$form->{path}";
    $form->{nextsub} = "dbupdate";
    $form->hide_form(qw(dbdriver dbhost dbport dbuser dbpasswd dbdefault dbupdate mextsub callback path));

    print qq|
<tr class=listheading>
  <th>|.$locale->text('The following Datasets need to be updated').qq|</th>
</tr>
<tr>
<td>

$upd

</td>
</tr>
<tr>
<td>

<hr size=3 noshade>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Main Menu').qq|">

</td></tr>
</table>
</form>
|;

  } else {

    print $locale->text('DBA')." : $form->{dbuser} : " .$locale->text('All Datasets up to date!');

  }
  
  print qq|

</body>
</html>
|;

}


sub dbupdate {

  User->dbupdate(\%$form);

  $form->redirect($locale->text('Dataset updated!'));
  
}


sub create_dataset {

  @dbsources = sort User->dbsources(\%$form);

  opendir SQLDIR, "sql/." or $form->error($!);
  foreach $item (sort grep /-chart\.sql/, readdir SQLDIR) {
    next if ($item eq 'Default-chart.sql');
    $item =~ s/-chart\.sql//;
    push @charts, qq|<input name=chart class=radio type=radio value="$item">$item|;
  }
  closedir SQLDIR;

  # add Default at beginning
  unshift @charts, qq|<input name=chart class=radio type=radio value="Default" checked>Default|;

  $selectencoding{Pg} = qq|<option>
  <option value=SQL_ASCII>ASCII
  <option value=UTF8>Unicode (UTF-8)
  <option value=EUC_CN>Chinese EUC
  <option value=EUC_JP>Japanese EUC
  <option value=EUC_KR>Korean EUC
  <option value=JOHAB>Korean (Hangul)
  <option value=EUC_TW>Taiwan EUC
  <option value=KOI8>KOI8-R(U)
  <option value=LATIN1>ISO 8859-1/ECMA 94 (Latin alphabet no. 1)
  <option value=LATIN2>ISO 8859-2/ECMA 94 (Latin alphabet no. 2)
  <option value=LATIN3>ISO 8859-3/ECMA 94 (Latin alphabet no. 3)
  <option value=LATIN4>ISO 8859-4/ECMA 94 (Latin alphabet no. 4)
  <option value=LATIN5>ISO 8859-9/ECMA 128 (Latin alphabet no. 5)
  <option value=LATIN6>ISO 8859-10/ECMA 144 (Latin alphabet no. 6)
  <option value=LATIN7>ISO 8859-13 (Latin alphabet no. 7)
  <option value=LATIN8>ISO 8859-14 (Latin alphabet no. 8)
  <option value=LATIN9>ISO 8859-15 (Latin alphabet no. 9)
  <option value=LATIN10>ISO 8859-16/ASRO SR 14111 (Latin alphabet no. 10)
  <option value=ISO_8859_5>ISO 8859-5/ECMA 113 (Latin/Cyrillic)
  <option value=ISO_8859_6>ISO 8859-6/ECMA 114 (Latin/Arabic)
  <option value=ISO_8859_7>ISO 8859-7/ECMA 118 (Latin/Greek)
  <option value=ISO_8859_8>ISO 8859-8/ECMA 121 (Latin/Hebrew)
  <option value=MULE_INTERNAL>Mule internal type
  <option value=ALT>Windows CP866 (Cyrillic)
  <option value=WIN1250>Windows CP1250 (Central Euope)
  <option value=WIN>Windows CP1251 (Cyrillic)
  <option value=WIN1252>Windows CP1252 (Western European)
  <option value=WIN1256>Windows CP1256 (Arabic)
  <option value=TCVN>Windows CP1258 (Vietnamese)
  <option value=WIN874>Windows CP874 (Thai)
  |;
  
  $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." ".$locale->text('Database Administration')." / ".$locale->text('Create Dataset');
  
  $form->header;

  print qq|
<body class=admin>


<center>
<h2>$form->{title}</h2>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listheading>
    <th colspan=2>&nbsp;</th>
  </tr>

  <tr>

    <th align=right nowrap>|.$locale->text('Existing Datasets').qq|</th>
    <td>
|;

    for (@dbsources) { print "[&nbsp;$_&nbsp;] " }
    
    print qq|
    </td>
  </tr>
  
  <tr>

    <th align=right nowrap>|.$locale->text('Create Dataset').qq|</th>
    <td><input name=db></td>

  </tr>
|;

  if ($selectencoding{$form->{dbdriver}}) {
    print qq|
  <tr>

    <th align=right nowrap>|.$locale->text('Multibyte Encoding').qq|</th>
    <td><select name=encoding>$selectencoding{$form->{dbdriver}}</select></td>

  </tr>
|;
  }

  print qq|
 
  <tr>

    <th align=right nowrap>|.$locale->text('Create Chart of Accounts').qq|</th>
    <td>
      <table>
|;

  while (@charts) {
    print qq|
        <tr>
|;

    for (0 .. 2) { print "<td>$charts[$_]</td>\n" }

    print qq|
        </tr>
|;

    splice @charts, 0, 3;
  }

  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=2>
    <hr size=3 noshade>
    </td>
  </tr>
</table>
|;

  $form->hide_form(qw(dbdriver dbuser dbhost dbport dbpasswd dbdefault path));
  
  print qq|
  
<input name=callback type=hidden value="$form->{script}?action=list_users&path=$form->{path}">
<input type=hidden name=nextsub value=dbcreate>
  
<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Main Menu').qq|">


</form>

</body>
</html>
|;

}


sub dbcreate {

  $form->isblank("db", $locale->text('Dataset missing!'));

  User->dbcreate(\%$form);
  
  $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." ".$locale->text('Database Administration')." / ".$locale->text('Create Dataset');

  $form->header;

  print qq|
<body class=admin>


<center>
<h2>$form->{title}</h2>

<form method=post action=$form->{script}>|

.$locale->text('Dataset')." $form->{db} ".$locale->text('successfully created!')

.qq|

<input type=hidden name=path value="$form->{path}">

<input type=hidden name=nextsub value=list_users>

<p><input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Main Menu').qq|">
</form>


</body>
</html>
|;

}


sub delete_dataset {

  if (@dbsources = User->dbsources_unused(\%$form, $memberfile)) {
    foreach $item (sort @dbsources) {
      $dbsources .= qq|<input name=db class=radio type=radio value=$item>&nbsp;$item |;
    }
  } else {
    $form->error($locale->text('Nothing to delete!'));
  }

  $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." ".$locale->text('Database Administration')." / ".$locale->text('Delete Dataset');

  $form->header;

  print qq|
<body class=admin>

<h2>$form->{title}</h2>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listheading>
    <th>|.$locale->text('The following Datasets are not in use and can be deleted').qq|</th>
  </tr>

  <tr>
    <td>
    $dbsources
    </td>
  </tr>
  
  <tr><td>
<p>
<input type=hidden name=dbdriver value=$form->{dbdriver}>
<input type=hidden name=dbuser value=$form->{dbuser}>
<input type=hidden name=dbhost value=$form->{dbhost}>
<input type=hidden name=dbport value=$form->{dbport}>
<input type=hidden name=dbpasswd value=$form->{dbpasswd}>
<input type=hidden name=dbdefault value=$form->{dbdefault}>

<input name=callback type=hidden value="$form->{script}?action=list_users&path=$form->{path}">

<input type=hidden name=path value="$form->{path}">

<input type=hidden name=nextsub value=dbdelete>

<hr size=3 noshade>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Main Menu').qq|">

  </td></tr>
</table>

</form>

</body>
</html>
|;

}


sub dbdelete {

  if (!$form->{db}) {
    $form->error($locale->text('No Dataset selected!'));
  }

  User->dbdelete(\%$form);

  $form->{title} = "SQL-Ledger ".$locale->text('Accounting')." ".$locale->text('Database Administration')." / ".$locale->text('Delete Dataset');

  $form->header;

  print qq|
<body class=admin>


<center>
<h2>$form->{title}</h2>

<form method=post action=$form->{script}>

$form->{db} |.$locale->text('successfully deleted!')

.qq|

<input type=hidden name=path value="$form->{path}">

<input type=hidden name=nextsub value=list_users>

<p><input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Main').qq|">
</form>


</body>
</html>
|;

}


sub unlock_system {

  unlink "$userspath/nologin";
  
  $form->{callback} = "$form->{script}?action=list_users&path=$form->{path}";

  $form->redirect($locale->text('Lockfile removed!'));

}


sub lock_system {

  open(FH, ">$userspath/nologin") or $form->error($locale->text('Cannot create Lock!'));
  close(FH);
  
  $form->{callback} = "$form->{script}?action=list_users&path=$form->{path}";

  $form->redirect($locale->text('Lockfile created!'));

}


sub main_menu { $form->redirect }

