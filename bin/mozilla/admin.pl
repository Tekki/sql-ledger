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

use SL::Form;
use SL::User;


$form = new Form;

$locale = new Locale $language, "admin";

$form->{charset} = $locale->{charset};

eval { require DBI; };
$form->error($locale->text('DBI not installed!')) if ($@);

$form->{stylesheet} = "sql-ledger.css";
$form->{favicon} = "favicon.ico";
$form->{timeout} = 86400;
$form->{"root login"} = 1;

require "$form->{path}/pw.pl";

# customization
if (-f "$form->{path}/custom_$form->{script}") {
  eval { require "$form->{path}/custom_$form->{script}"; };
  $form->error($@) if ($@);
}


if ($form->{action}) {

  &check_password unless $form->{action} eq $locale->text('logout');
  
  &{ $locale->findsub($form->{action}) };
    
} else {

  # if there are no drivers bail out
  $form->error($locale->text('Database Driver missing!')) unless (User->dbdrivers);

  # create memberfile
  if (! -f $memberfile) {
    &change_password;
    exit;
  }

  &adminlogin;

}

1;
# end


sub adminlogin {

  $form->{title} = qq|SQL-Ledger |.$locale->text('Version').qq| $form->{version} |.$locale->text('Administration');
  
  $form->header;
  
    print qq|
<script language="javascript" type="text/javascript">
<!--
function sf(){
  document.forms[0].password.focus();
}
// End -->
</script>

<body class=admin onload="sf()">

<div align=center>

<a href="http://www.sql-ledger.com"><img src=$images/sql-ledger.gif border=0 target=_blank></a>
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

<a href=http://www.sql-ledger.com target=_blank>SQL-Ledger |.$locale->text('website').qq|</a>

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
  &list_datasets;

}


sub logout {

  $form->{callback} = "$form->{script}?path=$form->{path}";
  $form->redirect($locale->text('You are logged out'));

}


sub edit {

  $form->{title} = "SQL-Ledger ".$locale->text('Administration');
  
  if (-f "$userspath/$form->{dbname}.LCK") {
    open(FH, "$userspath/$form->{dbname}.LCK") or $form->error("$userspath/$form->{dbname}.LCK : $!");
    $form->{lock} = <FH>;
    close(FH);
  }

  &form_header;
  &form_footer;

}


sub form_footer {

  $nologin = qq|
<input type=submit class=submit name=action value="|.$locale->text('Lock Dataset').qq|">|;

  if (-f "$userspath/$form->{dbname}.LCK") {
    $nologin = qq|
<input type=submit class=submit name=action value="|.$locale->text('Unlock Dataset').qq|">|;
  }

  $delete = qq|<input type=submit class=submit name=action value="|.$locale->text('Delete').qq|">|;
  
  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}";

  $form->hide_form(qw(company dbname path callback));
  
  print qq|

$nologin
$delete

</form>

</body>
</html>
|;

}


sub list_datasets {
  
# type=submit $locale->text('Pg')
# type=submit $locale->text('PgPP')
# type=submit $locale->text('Oracle')
# type=submit $locale->text('Sybase')

  open(FH, "$memberfile") or $form->error("$memberfile : $!");
  my @member = <FH>;
  close(FH);
  
  $nologin = qq|
<input type=submit class=submit name=action value="|.$locale->text('Lock System').qq|">|;

  if (-f "$userspath/nologin.LCK") {
    $nologin = qq|
<input type=submit class=submit name=action value="|.$locale->text('Unlock System').qq|">|;
  }

  $login = "";

  while (@member) {
    $_ = shift @member;
    
    if (/^\[.*\]/) {
      %temp = ();
      do {
	if (/^(company|dbname|dbdriver|dbhost|dbuser)=/) {
	  chop ($var = $&);
	  ($null, $temp{$var}) = split /=/, $_, 2;
	}
	$_ = shift @member;
      } until /^\s+$/;

      chop $temp{dbname};
      for (keys %temp) { $member{$temp{dbname}}{$_} = $temp{$_} }
      $member{$temp{dbname}}{locked} = "x" if -f "$userspath/$member{$temp{dbname}}{dbname}.LCK";
    }
  }
  
  delete $member{""};

  $column_data{company} = qq|<th>|.$locale->text('Company').qq|</th>|;
  $column_data{dbdriver} = qq|<th>|.$locale->text('Driver').qq|</th>|;
  $column_data{dbhost} = qq|<th>|.$locale->text('Host').qq|</th>|;
  $column_data{dbuser} = qq|<th>|.$locale->text('User').qq|</th>|;
  $column_data{dbname} = qq|<th>|.$locale->text('Dataset').qq|</th>|;
  $column_data{locked} = qq|<th width=1%>|.$locale->text('Locked').qq|</th>|;

  @column_index = qw(dbname company locked dbdriver dbuser dbhost);
  
  $dbdriver ||= "Pg";
  $dbdriver{$dbdriver} = "checked";
  
  for (User->dbdrivers) {
    $dbdrivers .= qq|
               <input name=dbdriver type=radio class=radio value="$_" $dbdriver{$_}>|.$locale->text($_).qq|&nbsp;|;
  }

  $form->{title} = "SQL-Ledger ".$locale->text('Administration');


  $form->header;

  print qq|
<body class=admin>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listheading>
    <th>$form->{title}</th>
  </tr>
  <tr size=5></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>|;

  for (@column_index) { print "$column_data{$_}\n" }
  
  print qq|
        </tr>
|;

  foreach $key (sort keys %member) {
    chomp $member{$key}{company};
    $href = "$script?action=edit&dbname=$key&path=$form->{path}&company=$member{$key}{company}&locked=$member{$key}{locked}";
    $href =~ s/ /%20/g;
    
    $member{$key}{dbname} = $member{$key}{dbuser} if ($member{$key}{dbdriver} eq 'Oracle');

    $column_data{company} = qq|<td>$member{$key}{company}</td>|;
    $column_data{dbdriver} = qq|<td>$member{$key}{dbdriver}</td>|;
    $column_data{dbhost} = qq|<td>$member{$key}{dbhost}</td>|;
    $column_data{dbuser} = qq|<td>$member{$key}{dbuser}</td>|;
    $column_data{dbname} = qq|<td><a href=$href>$member{$key}{dbname}</a></td>|;
    $column_data{locked} = qq|<td align=center>$member{$key}{locked}</td>|;
    
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

$dbdrivers

<p>
<input type=submit class=submit name=action value="|.$locale->text('Add Dataset').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Change Password').qq|">
$nologin
<input type=submit class=submit name=action value="|.$locale->text('Logout').qq|">

</form>

</body>
</html>
|;

}


sub add_dataset { &{ "$form->{dbdriver}" } }


sub form_header {

  $form->header;

  if ($form->{locked}) {
    $locked = qq|
          <td>$form->{lock}</td>|;
  } else {
    $locked = qq|
          <td><input name=lock size=25 value="$form->{lock}"></td>|;
  }

  print qq|
<body class=admin>

<form method=post action=$form->{script}>

<table>
  <tr class=listheading><th>$form->{title}</th></tr>
  <tr size=5></tr>
  <tr valign=top>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Company').qq|</th>
	  <td>$form->{company}</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Dataset').qq|</th>
	  <td>$form->{dbname}</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Lock Message').qq|</th>
	  $locked
	</tr>
      </table>
    </td>
  </tr>

   <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
</div>
|;

}


sub delete {

  $form->{title} = $locale->text('Confirm!');
  
  $form->header;

  print qq|
<body class=admin>

<form method=post action=$form->{script}>
|;

  $form->{nextsub} = "do_delete";
  $form->{action} = "do_delete";

  delete $form->{script};

  $form->hide_form;

  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|.$locale->text('Are you sure you want to delete dataset').qq| $form->{dbname}</h4>

<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>

</body>
</html>
|;

}


sub do_delete {

  $form->{db} = $form->{dbname};

  $form->error("$memberfile : ".$locale->text('locked!')) if (-f ${memberfile}.LCK);

  open(FH, ">${memberfile}.LCK") or $form->error("${memberfile}.LCK : $!");
  close(FH);
  
  if (! open(FH, "+<$memberfile")) {
    unlink "${memberfile}.LCK";
    $form->error("$memberfile : $!");
  }
  @db = <FH>;

  for (@db) {
    last if /^\[/;
    push @member, $_;
  }
  
  # get variables for dbname
  while (@db) {
    $_ = shift @db;
    
    if (/^\[(.*)\]/) {
      $user = $+;
      %temp = ();
      do {
	chop;
	($var, $value) = split /=/, $_, 2;
	if ($value) {
	  $temp{$var} = $value;
	}
	$_ = shift @db;
      } until /^\s/;

      for (keys %temp) {
	$db{$temp{dbname}}{$_} = $temp{$_};
	$member{$temp{dbname}}{$user}{$_} = $temp{$_};
      }
    }
  }
  
  $form->{dbdriver} = $db{$form->{dbname}}{dbdriver};
  &dbdriver_defaults;
  for (qw(dbconnect dbuser dbhost dbport)) { $form->{$_} = $db{$form->{dbname}}{$_} }
  $form->{dbpasswd} = unpack 'u', $db{$form->{dbname}}{dbpasswd};

  # delete dataset
  User->dbdelete(\%$form);

  # delete conf for users
  for (keys %{ $member{$form->{dbname}} }) {
    unlink "$userspath/${_}.conf";
  }

  delete $member{$form->{dbname}};

  seek(FH, 0, 0);
  truncate(FH, 0);

  for (@member) {
    print FH $_;
  }
  
  for $db (sort keys %member) {
    for $user (sort keys %{ $member{$db} }) {
      print FH "\[$user\]\n";
      for $var (sort keys %{ $member{$db}{$user} }) {
	print FH "${var}=$member{$db}{$user}{$var}\n";
      }
      print FH "\n";
    }
  }
  close(FH);
  
  unlink "${memberfile}.LCK";
  unlink "$userspath/$form->{dbname}.LCK";

  # delete spool and template directory
  for $dir ("$templates/$form->{dbname}", "$spool/$form->{dbname}") {
    if (-d "$dir") {
      opendir DIR, $dir;
      @all = grep !/^\./, readdir DIR;
      closedir DIR;
      for $subdir (@all) {
	if (-d "$dir/$subdir") {
	  unlink <$dir/$subdir/*>;
	  rmdir "$dir/$subdir";
	}
      }
      unlink <$dir/*>;
      rmdir "$dir";
    }
  }
  
  $form->redirect($locale->text('Dataset deleted!'));

}


sub change_password {

  $form->{title} = $locale->text('Change Password');

  $form->header;

  print qq|
<body class=admin>

<form method=post action=$form->{script}>

<table>
  <tr>
  <tr class=listheading>
    <th>$form->{title}</th>
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
  <tr>
    <td>
      <hr size=3 noshade>
    </td>
  </tr>
</table>

<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->{nextsub} = "do_change_password";
  $form->hide_form(qw(path nextsub));

  print qq|
</form>

</body>
</html>
|;

}


sub do_change_password {

  $form->error($locale->text('Passwords do not match!')) if $form->{new_password} ne $form->{confirm_password};

  $root->{password} = $form->{new_password};
  
  if (! -f $memberfile) {
    open(FH, ">$memberfile") or $form->error("$memberfile : $!");
    print FH qq|# SQL-Ledger members

[root login]
|;
    close FH;
  }
 
  $root->{'root login'} = 1;
  $root->{login} = "root login";
  $root->save_member($memberfile);

  $form->{password} = $form->{new_password};
  &create_config;
  
  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}&password=$form->{password}";

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


sub Pg { &dbselect_source }
sub PgPP { &dbselect_source }
sub Oracle { &dbselect_source }
sub Sybase { &dbselect_source }


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
  
  $form->{title} = "SQL-Ledger / ".$locale->text('Add Dataset');
  
  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}";
  
  $form->header;

  print qq|
<body class=admin>

<form method=post action=$form->{script}>

<table>
  <tr class=listheading>
    <th>$form->{title}</th>
  </tr>
  <tr size=5></tr>
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
	  <td><input type=password name=dbpasswd size=10 value=$form->{dbpasswd}></td>
	</tr>
	<tr>
	  <th align=right>$form->{connectstring}</th>
	  <td colspan=3><input name=dbdefault size=10 value=$form->{dbdefault}></td>
	</tr>
      </table>
    </td>
  </tr>
</table>
<hr size=3 noshade>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
|;

  $form->{nextsub} = "create_dataset";
  $form->hide_form(qw(dbdriver path nextsub callback));

  print qq|
</form>

</body>
</html>
|;

}


sub continue { &{ $form->{nextsub} } }
sub yes { &{ $form->{nextsub} } }


sub create_dataset {
  
  @dbsources = sort User->dbsources(\%$form);

  opendir SQLDIR, "sql/." or $form->error($!);
  foreach $item (sort grep /-chart\.sql/, readdir SQLDIR) {
    next if ($item eq 'Default-chart.sql');
    $item =~ s/-chart\.sql//;
    push @charts, qq|<input name=chart class=radio type=radio value="$item">$item|;
  }
  closedir SQLDIR;
  
  # is there a template basedir
  if (! -d "$templates") {
    $form->error($locale->text('Directory').": $templates ".$locale->text('does not exist'));
  }

  opendir TEMPLATEDIR, "$templates/." or $form->error("$templates : $!");
  @all = grep !/^\.\.?$/, readdir TEMPLATEDIR;
  closedir TEMPLATEDIR;

  @allhtml = sort grep /\.html/, @all;

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
  
  $form->{title} = "SQL-Ledger / ".$locale->text('Create Dataset');
  
  $form->header;

  print qq|
<body class=admin>

<form method=post action=$form->{script}>

<table>
  <tr class=listheading>
    <th>$form->{title}</th>
  </tr>
  <tr size=5></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Existing Datasets').qq|</th>
	  <td>
      |;

	  for (@dbsources) { print "[&nbsp;$_&nbsp;] " }
	  
	  print qq|
	  </td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Dataset').qq|</th>
	  <td><input name=db></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Company').qq|</th>
	  <td><input name=company size=25></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Templates').qq|</th>
	  <td><select name=mastertemplates>|.$form->select_option($selectmastertemplates).qq|</select></td>
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
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>
<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
|;

  $form->{nextsub} = "dbcreate";
  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}";
  
  $form->hide_form(qw(dbdriver dbuser dbhost dbport dbpasswd dbdefault path nextsub callback));

  print qq|
</form>

</body>
</html>
|;

}


sub dbcreate {

  $form->isblank("db", $locale->text('Dataset missing!'));
  
  $form->error("$memberfile : ".$locale->text('locked!')) if (-f ${memberfile}.LCK);

  open(FH, ">${memberfile}.LCK") or $form->error("${memberfile}.LCK : $!");
  close(FH);
 
  # is there a basedir
  if (! -d "$templates") {
    $form->error($locale->text('Directory').": $templates ".$locale->text('does not exist'));
  }

  $form->{company} = $form->{db} unless $form->{company};
  
  User->dbcreate(\%$form);

  # create user template directory and copy master files
  $form->{templates} = "$templates/$form->{db}";
  
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
	  
	for (<TEMP>) {
	  print NEW $_;
	}
	close(TEMP);
	close(NEW);
      }
    } else {
      $form->error("$form->{templates} : $!");
    }
  }
  
  if (! -d "$spool/$form->{db}") {
    if (! (mkdir "$spool/$form->{db}", oct("771")) ) {
      $form->error("$spool/$form->{db} : $!");
    }
  }
  
  # add admin to members file
  if (! open(FH, ">>$memberfile")) {
    unlink "${memberfile}.LCK";
    $form->error("$memberfile : $!");
  }

  $form->{dbname} = $form->{db};
  $form->{login} = "admin\@$form->{dbname}";
  $form->{stylesheet} = "sql-ledger.css";

  print FH "\n\[$form->{login}\]\n";
  
  if ($form->{dbpasswd}) {
    $form->{dbpasswd} = pack 'u', $form->{dbpasswd};
    chomp $form->{dbpasswd};
  }
  
  for (qw(company dbconnect dbdriver dbhost dbname dboptions dbpasswd dbport dbuser stylesheet)) {
    print FH "$_=$form->{$_}\n" if $form->{$_};
  }
  print FH "\n";
  close(FH);

  unlink "${memberfile}.LCK";
 
  &list_datasets;

}


sub unlock_dataset { &unlock_system }

sub unlock_system {

  if ($form->{dbname}) {
    $filename = "$userspath/$form->{dbname}.LCK";
  } else {
    $filename = "$userspath/nologin.LCK";
  }
  unlink "$filename";
  
  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}";

  $form->redirect($locale->text('Lockfile removed!'));

}


sub lock_dataset { &do_lock_system }


sub lock_system {
  
   $form->{title} = "SQL-Ledger / ";
   
   if ($form->{dbname}) {
     $form->{title} .= $locale->text('Lock Dataset')." / ".$form->{dbname};
   } else {
     $form->{title} .= $locale->text('Lock System');
   }
  
  $form->header;

  print qq|
<body class=admin>

<form method=post action=$form->{script}>

<table>
  <tr class=listheading>
    <th>$form->{title}</th>
  </tr>
  <tr size=5></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Lock Message').qq|</th>
	  <td><input name=lock size=25></td>
	</tr>
      </table>
    </td>
  </tr>
</table>
<hr size=3 noshade>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">|;
  
  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}";
  $form->{nextsub} = "do_lock_system";
  $form->hide_form(qw(callback dbname dbdriver path nextsub));

  print qq|
</form>

</body>
</html>
|;

}


sub do_lock_system {

  if ($form->{dbname}) {
    open(FH, ">$userspath/$form->{dbname}.LCK") or $form->error($locale->text('Cannot create Lock!'));
  } else {
    open(FH, ">$userspath/nologin.LCK") or $form->error($locale->text('Cannot create Lock!'));
  }

  if ($form->{lock}) {
    print FH $form->{lock};
  }
  close(FH);
  
  $form->redirect($locale->text('Lockfile created!'));

}


