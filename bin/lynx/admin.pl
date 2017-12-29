#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
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

$form->{charset} = $charset;

eval { require DBI; };
$form->error($locale->text('DBI not installed!')) if ($@);

$form->{stylesheet} = "sql-ledger.css";
$form->{favicon} = "favicon.ico";
$form->{timeout} = 86400;
$form->{"root login"} = 1;

require "$form->{path}/pw.pl";

# customization
if (-f "$form->{path}/custom/$form->{script}") {
  eval { require "$form->{path}/custom/$form->{script}"; };
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
  document.main.password.focus();
}
// End -->
</script>

<body class=admin onload="sf()">

<div align=center>

<a href="http://www.sql-ledger.com"><img src=$images/sql-ledger.gif border=0 target=_blank></a>
<h1 class=login>|.$locale->text('Version').qq| $form->{version}<p>|.$locale->text('Administration').qq|</h1>

<form method=post name=main action="$form->{script}">

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
    $key = "root$form->{password}$t";

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
  print CONF qq|# configuration file for root

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

  %button = ('Delete' => { ndx => 2, key => 'D', value => $locale->text('Delete') },
             'Change Password' => { ndx => 4, key => 'C', value => $locale->text('Change Password') },
             'Change Host' => { ndx => 5, key => 'H', value => $locale->text('Change Host') },
            );

  if (-f "$userspath/$form->{dbname}.LCK") {
    $button{'Unlock Dataset'} = { ndx => 1, key => 'U', value => $locale->text('Unlock Dataset') };
  } else {
    $button{'Lock Dataset'} = { ndx => 1, key => 'L', value => $locale->text('Lock Dataset') };
  }

  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}";

  $form->hide_form(qw(company dbname dbhost dbdriver dbuser path callback));

  $form->print_button(\%button);

  print qq|

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

  my %member;
  my $member;

  while (<FH>) {
    if (/^\[(.*)\]/) {
      $member = $+;
      if ($member =~ /^admin\@/) {
        $member = substr($member,6);
        $new = 1;
      } else {
        $new = 0;
      }
    }
    if ($new) {
      if (/^(company|dbname|dbdriver|dbhost|dbuser|templates)=/) {
        $var = $1;
        (undef, $member{$member}{$var}) = split /=/, $_, 2;
        $member{$member}{$var} =~ s/(\r\n|\n)//;
      }
    }
  }
  
  close(FH);

  delete $member{"root login"};

  for (keys %member) {
    $member{$_}{locked} = "x" if -f "$userspath/$member{$_}{dbname}.LCK";
  }

  $column_data{company} = qq|<th>|.$locale->text('Company').qq|</th>|;
  $column_data{dbdriver} = qq|<th>|.$locale->text('Driver').qq|</th>|;
  $column_data{dbhost} = qq|<th>|.$locale->text('Host').qq|</th>|;
  $column_data{dbuser} = qq|<th>|.$locale->text('User').qq|</th>|;
  $column_data{dbname} = qq|<th>|.$locale->text('Dataset').qq|</th>|;
  $column_data{templates} = qq|<th>|.$locale->text('Templates').qq|</th>|;
  $column_data{locked} = qq|<th width=1%>|.$locale->text('Locked').qq|</th>|;

  @column_index = qw(dbname company templates locked dbdriver dbuser dbhost);
  
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
    $href = "$script?action=edit&dbname=$key&path=$form->{path}&locked=$member{$key}{locked}&dbhost=$member{$key}{dbhost}&dbdriver=$member{$key}{dbdriver}&dbuser=$member{$key}{dbuser}";
    $href .= "&company=".$form->escape($member{$key}{company},1);

    $member{$key}{dbname} = $member{$key}{dbuser} if ($member{$key}{dbdriver} eq 'Oracle');

    for (qw(company dbdriver dbhost dbuser templates)) { $column_data{$_} = qq|<td>$member{$key}{$_}</td>| }
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
|;

  %button = ('Add Dataset' => { ndx => 1, key => 'A', value => $locale->text('Add Dataset') },
             'Change Password' => { ndx => 2, key => 'C', value => $locale->text('Change Password') },
             'Logout' => { ndx => 4, key => 'X', value => $locale->text('Logout') }
            );

  if (-f "$userspath/nologin.LCK") {
    $button{'Unlock System'} = { ndx => 3, key => 'U', value => $locale->text('Unlock System') };
  } else {
    $button{'Lock System'} = { ndx => 3, key => 'L', value => $locale->text('Lock System') };
  }

  $form->print_button(\%button);
  
  print qq|

</form>

</body>
</html>
|;

}


sub add_dataset { &{ "$form->{dbdriver}" } }


sub form_header {

  $form->header;

  $focus = "lock";

  if ($form->{locked}) {
    $locked = qq|
          <td>$form->{lock}</td>|;
  } else {
    $locked = qq|
          <td><input name=lock size=25 value="$form->{lock}"></td>|;
  }

  print qq|
<body class=admin onload="document.main.${focus}.focus()" />

<form name=main method=post action=$form->{script}>

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
  while ($_ = shift @db) {
    
    if (/^\[(.*)\]/) {
      $user = $+;
      next;
    }

    chop;
    ($var, $value) = split /=/, $_, 2;
    $temp{$user}{$var} = $value;

  }

  for $user (keys %temp) {
    $dbname = $temp{$user}{dbname};
    for (keys %{$temp{$user}}) {
      $db{$dbname}{$_} = $temp{$user}{$_};
      $member{$dbname}{$user}{$_} = $temp{$user}{$_};
    }
  }

  $form->{dbdriver} = $db{$form->{dbname}}{dbdriver};
  &dbdriver_defaults;
  for (qw(dbconnect dbuser dbhost dbport templates)) { $form->{$_} = $db{$form->{dbname}}{$_} }
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
      if ($user) {
        print FH "\[$user\]\n";
        for $var (sort keys %{ $member{$db}{$user} }) {
          print FH "${var}=$member{$db}{$user}{$var}\n" if $member{$db}{$user}{$var};
        }
        print FH "\n";
      }
    }
  }
  close(FH);
  
  # delete spool and template directory if it is not shared
  # compare dbname and templates
  for (qw(dbname spool)) {

    if ($_ eq "dbname") {
      $dir = "$templates/$form->{dbname}";
      $form->{templates} ||= $form->{dbname};
      next if ($form->{dbname} ne $form->{templates});
    }

    if ($_ eq "spool") {
      $dir = "$spool/$form->{dbname}";
    }

    if (-d $dir) {
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
  
  unlink "${memberfile}.LCK";
  unlink "$userspath/$form->{dbname}.LCK";

  $form->redirect($locale->text('Dataset deleted!'));

}


sub change_password {

  $form->{title} = $locale->text('Change Password');

  if ($form->{dbname}) {
    $form->{title} = $locale->text('Change Password for Dataset')." $form->{dbname}";
  }

  $focus = "new_password";

  $form->header;

  print qq|
<body class=admin onload="document.main.${focus}.focus()" />

<form method=post name=main action=$form->{script}>

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

  $form->hide_form(qw(path nextsub dbname));

  print qq|
</form>

</body>
</html>
|;

}


sub do_change_password {

  if ($form->{new_password}) {
    $form->error('Password may not contain ? or &') if $form->{new_password} =~ /\?|\&/;
    if ($form->{new_password} ne $form->{confirm_password}) {
      $form->error($locale->text('Password does not match!'));
    }
  }

  if ($form->{dbname}) {
    # get connection details from members file
    $admin = new User $memberfile, "admin\@$form->{dbname}";

    for (qw(dbconnect dbuser dbpasswd dbhost dbdriver)) { $form->{$_} = $admin->{$_} }
    $form->{dbpasswd} = unpack 'u', $form->{dbpasswd};

    open(FH, ">${memberfile}.LCK") or $form->error("${memberfile}.LCK : $!");
    close(FH);
  
    if (! open(FH, "+<$memberfile")) {
      unlink "${memberfile}.LCK";
      $form->error("$memberfile : $!");
    }
    @member = <FH>;

    while ($_ = shift @member) {
      if (/^\[.*\]/) {
        chop;
        $member = $_;
        $member =~ s/(^\[|\]$)//g;
        $_ = shift @member;
        do {
          chop;
          ($var, $val) = split /=/, $_, 2;
          $member{$member}{$var} = $val;
          $_ = shift @member;
        } until /^\s+$/;
      }
    }
    
    # change password
    User->dbpassword(\%$form);

    # change passwords in members file
    $form->{dbpasswd} = pack 'u', $form->{new_password};
    chomp $form->{dbpasswd};

    seek(FH, 0, 0);
    truncate(FH, 0);

    print FH qq|# SQL-Ledger members

[root login]\n|;

    for (sort keys %{$member{"root login"}}) {
      print FH qq|$_=$member{"root login"}{$_}\n|;
    }
    print FH "\n";
    delete $member{"root login"};

    for (keys %member) {
      if ($member{$_}{dbdriver} eq $form->{dbdriver}) {
        if ($member{$_}{dbuser} eq $form->{dbuser}) {
          if ($member{$_}{dbhost} eq $form->{dbhost}) {
            $member{$_}{dbpasswd} = $form->{dbpasswd};
          }
        }
      }
    }

    for $member (sort keys %member) {
      print FH qq|[$member]\n|;
      for (sort keys %{$member{$member}}) {
        print FH qq|$_=$member{$member}{$_}\n|;
      }
      print FH "\n";
    }
    close(FH);

    unlink "${memberfile}.LCK";

  } else {

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
    
  }

  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}&password=$form->{password}";

  $form->redirect($locale->text('Password changed!'));

}


sub change_host {

  $form->{title} = $locale->text('Change Host for Dataset')." $form->{dbname}";

  $focus = "new_host";

  $form->header;

  print qq|
<body class=admin onload="document.main.${focus}.focus()" />

<form method=post name=main action=$form->{script}>

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
	  <th align=right>|.$locale->text('Host').qq|</th>
	  <td><input name=new_host size=40 value=$form->{dbhost}></td>
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

  $form->{nextsub} = "do_change_host";

  $form->hide_form(qw(path nextsub dbname dbhost dbdriver));

  print qq|
</form>

</body>
</html>
|;

}


sub do_change_host {

  open(FH, ">${memberfile}.LCK") or $form->error("${memberfile}.LCK : $!");
  close(FH);

  if (! open(FH, "+<$memberfile")) {
    unlink "${memberfile}.LCK";
    $form->error("$memberfile : $!");
  }
  @member = <FH>;

  while ($_ = shift @member) {
    if (/^\[.*\]/) {
      chop;
      $member = $_;
      $member =~ s/(^\[|\]$)//g;
      $_ = shift @member;
      do {
        chop;
        ($var, $val) = split /=/, $_, 2;
        $member{$member}{$var} = $val;
        $_ = shift @member;
      } until /^\s+$/;
    }
  }

  seek(FH, 0, 0);
  truncate(FH, 0);

  print FH qq|# SQL-Ledger members

[root login]\n|;

  for (sort keys %{$member{"root login"}}) {
    print FH qq|$_=$member{"root login"}{$_}\n|;
  }
  print FH "\n";
  delete $member{"root login"};

  for (keys %member) {
    if ($member{$_}{dbdriver} eq $form->{dbdriver}) {
      if ($member{$_}{dbname} eq $form->{dbname}) {
        if ($form->{new_host} ne $member{$_}{dbhost}) {
          $member{$_}{dbhost} = $form->{new_host};
          if ($form->{dbdriver} =~ /(Pg|Sybase)/) {
            $member{$_}{dbconnect} = "dbi:$form->{dbdriver}:dbname=$form->{dbname}";
          }
          if ($form->{dbdriver} eq 'Oracle') {
            $form->{dbconnect} = "dbi:Oracle:sid=$member{$_}{sid}";
          }

          if ($form->{new_host}) {
            $member{$_}{dbconnect} .= ";host=$form->{new_host}";
          } else {
            delete $member{$_}{dbhost};
          }
        }
      }
    }
  }

  for $member (sort keys %member) {
    print FH qq|[$member]\n|;
    for (sort keys %{$member{$member}}) {
      print FH qq|$_=$member{$member}{$_}\n|;
    }
    print FH "\n";
  }
  close(FH);

  unlink "${memberfile}.LCK";

  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}";

  $form->redirect($locale->text('Lockfile removed!'));

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

	$cookie = ($form->{path} eq 'bin/lynx') ? $cookie{login} : $cookie{"SL-root"};

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

	  $l = 4;
	  $login = substr($s, 0, $l);
	  $time = substr($s, -10);
	  $password = substr($s, $l, (length $s) - ($l + 10));

	  if ((time > $time) || ($login ne 'root') || ($root->{password} ne crypt $password, 'ro')) {
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
  
  $focus = "dbhost";

  $form->header;

  print qq|
<body class=admin onLoad="document.main.${focus}.focus()" />

<form name=main method=post action=$form->{script}>

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

  opendir SQLDIR, "sql" or $form->error($!);
  foreach $item (sort grep /-chart\.sql/, readdir SQLDIR) {
    next if ($item eq 'Default-chart.sql');
    $item =~ s/-chart\.sql//;
    $selectchart .= "$item\n";
  }

  $selectchart = "Default\n$selectchart" if (-f 'sql/Default-chart.sql');
  closedir SQLDIR;

  $form->{name} ||= $locale->text('Admin');
  
  $templatedir = "doc/templates";

  if (-d "$templatedir") {
    opendir TEMPLATEDIR, "$templatedir" or $form->error("$templatedir : $!");

    @all = grep !/^\./, readdir TEMPLATEDIR;
    closedir TEMPLATEDIR;

    for (@all) { push @alldir, $_ if -d "$templatedir/$_" }

    @alldir = sort grep !/Default/, @alldir;
    unshift @alldir, 'Default' if -d "$templatedir/Default";

    for (@alldir) { $selecttemplates .= qq|$_\n| }

  }

  $selectencoding = User->encoding($form->{dbdriver});
  $form->{charset} = $charset;

  # get subdirectories from templates directory
  if (-d $templates) {
    opendir TEMPLATEDIR, "$templates" or $form->error("$templates : $!");
    @d = grep !/^\./, readdir TEMPLATEDIR;
    closedir TEMPLATEDIR;
    for (@d) { push @dir, $_ if -d "$templates/$_" }

    if (@dir) {
      $selectusetemplates = "\n";
      for (sort @dir) { $selectusetemplates .= "$_\n" }
      chop $selectusetemplates;

      $usetemplates = qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Use Templates').qq|</th>
          <td><select name=usetemplates>|.$form->select_option($selectusetemplates).qq|</select></td>
        </tr>
|;
    }

  }

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
          <td><input name=company size=35></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Administrator').qq|</th>
          <td><input name=name size=35 value="$form->{name}"></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('E-mail').qq|</th>
          <td><input name=email size=35></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Password').qq|</th>
          <td><input name=adminpassword type=password size=25></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Templates').qq|</th>
          <td><select name=mastertemplates>|.$form->select_option($selecttemplates).qq|</select></td>
        </tr>
        $usetemplates
|;

  if ($selectencoding) {
    print qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Multibyte Encoding').qq|</th>
          <td><select name=encoding>|.$form->select_option($selectencoding, $form->{charset},1,1).qq|</select></td>
        </tr>
|;
  }

  print qq|
 
        <tr>
          <th align=right nowrap>|.$locale->text('Create Chart of Accounts').qq|</th>
          <td><select name=chart>|.$form->select_option($selectchart).qq|</select></td>
        </tr>
|;

  print qq|
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

  # check if dbname is already in use
  open(FH, "$memberfile") or $form->error("$memberfile : $!");
  @member = <FH>;
  close(FH);

  while ($_ = shift @member) {
    if (/^\[(.*)\]/) {
      $user = $+;
      $user =~ s/.*\@//;
    }

    if (/^dbname=/) {
      chop;
      (undef, $dbname) = split /=/, $_, 2;
       $member{$user} = $dbname;
    }
  }

  $form->error($locale->text('Duplicate Dataset!')) if $form->{db} eq $member{$form->{db}};

  open(FH, ">${memberfile}.LCK") or $form->error("${memberfile}.LCK : $!");
  close(FH);
 
  $templatedir = "doc/templates";

  umask(002);

  if (! -d "$templates") {
    mkdir "$templates", oct("771") or $form->error("$templates : $!");
  }

  $form->{company} ||= $form->{db};
  
  # create user template directory and copy master files
  $form->{templates} = ($form->{usetemplates}) ? "$form->{usetemplates}" : "$form->{db}";

  # get templates from master
  opendir TEMPLATEDIR, "$templatedir/$form->{mastertemplates}" or $form->error("$templates : $!");
  @templates = grep !/^\./, readdir TEMPLATEDIR;
  closedir TEMPLATEDIR;

  if (! -d "$templates/$form->{templates}") {
    mkdir "$templates/$form->{templates}", oct("771") or $form->error("$templates/$form->{templates} : $!");
  }

  foreach $file (@templates) {
    if (! -f "$templates/$form->{templates}/$file") {
      open(TEMP, "$templatedir/$form->{mastertemplates}/$file") or $form->error("$templatedir/$form->{mastertemplates}/$file : $!");
      open(NEW, ">$templates/$form->{templates}/$file") or $form->error("$templates/$form->{templates}/$file : $!");
      
      for (<TEMP>) { print NEW $_ }
      close(NEW);
      close(TEMP);
    }
  }

  # copy logo files
  for $ext (qw(eps png)) {
    if (! -f "$templates/$form->{templates}/logo.$ext") {
      open(TEMP, "$userspath/sql-ledger.$ext");
      open(NEW, ">$templates/$form->{templates}/logo.$ext");
      for (<TEMP>) { print NEW $_ }
      close(NEW);
      close(TEMP);
    }
  }

  if (! -d "$spool/$form->{db}") {
    mkdir "$spool/$form->{db}", oct("771") or $form->error("$spool/$form->{db} : $!");
  }
  
  # add admin to members file
  if (! open(FH, ">>$memberfile")) {
    unlink "${memberfile}.LCK";
    $form->error("$memberfile : $!");
  }

  # create dataset
  User->dbcreate(\%$form);

  $form->{charset} = $form->{encoding};
  $form->{dbname} = $form->{db};
  $form->{login} = "admin\@$form->{db}";
  $form->{stylesheet} = "sql-ledger.css";
  $form->{dateformat} = "mm-dd-yy";
  $form->{numberformat} = "1,000.00";
  $form->{dboptions} = "set DateStyle to 'POSTGRES, US'";
  $form->{dboptions} .= ';set client_encoding to \''.$form->{encoding}."'" if $form->{encoding};
  $form->{vclimit} = "1000";

  print FH "\[$form->{login}\]\n";
  
  if ($form->{dbpasswd}) {
    $form->{dbpasswd} = pack 'u', $form->{dbpasswd};
    chomp $form->{dbpasswd};
  }

  if ($form->{adminpassword}) {
    srand( time() ^ ($$ + ($$ << 15)) );
    $form->{password} = crypt $form->{adminpassword}, 'ad';
  }
  
  for (sort (qw(company name email dbconnect dbdriver dbhost dbname dboptions dbpasswd dbport dbuser stylesheet password dateformat numberformat charset vclimit templates))) {
    print FH "$_=$form->{$_}\n" if $form->{$_};
  }
  print FH "\n";
  close(FH);

  unlink "${memberfile}.LCK";
 
  delete $form->{password};

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

  $focus = "lock";

  $form->header;

  print qq|
<body class=admin onLoad="document.main.${focus}.focus()" />

<form name=main method=post action=$form->{script}>

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


