
1;


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
	    'timesheet' => $locale->text('Timesheet'),
            'supervisor' => $locale->text('Supervisor'),
	    'manager' => $locale->text('Manager')

	   );
	    
  $selectrole = "";
  for (qw(user timesheet admin supervisor manager)) { $selectrole .= "$_--$role{$_}\n" }
  
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


