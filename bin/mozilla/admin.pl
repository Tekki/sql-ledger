#======================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2025 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# setup module
# add/edit/delete users
#
#======================================================================

use SL::Form;
use SL::Locale;
use SL::User;

use Storable ();
use YAML::PP;

$form = SL::Form->new;

$locale = SL::Locale->new($slconfig{language}, "admin");

# $form->{charset} = $slconfig{charset};

eval { require DBI; };
$form->error($locale->text('DBI not installed!')) if ($@);

$form->{stylesheet} = "sql-ledger.css";
$form->{favicon} = "favicon.ico";
$form->{timeout} = 86400;
$form->{'root login'} = 1;

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
  $form->error($locale->text('Database Driver missing!')) unless (SL::User->dbdrivers);

  # create memberfile
  unless (-f "$slconfig{memberfile}.bin") {
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

<a href="https://github.com/Tekki/sql-ledger"><img src=$slconfig{images}/sql-ledger.gif border=0 target=_blank></a>
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

<a href="https://github.com/Tekki/sql-ledger" target=_blank>SQL-Ledger |.$locale->text('website').qq|</a>

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

  Storable::store {sessionkey => $form->{sessionkey}}, "$slconfig{userspath}/root login.bin";

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

  if (-f "$slconfig{userspath}/$form->{dbname}.LCK") {
    open my $fh, "$slconfig{userspath}/$form->{dbname}.LCK" or $form->error("$slconfig{userspath}/$form->{dbname}.LCK : $!");
    $form->{lock} = <$fh>;
    close $fh;
  }

  &form_header;
  &form_footer;

}


sub form_footer {

  %button = ('Delete' => { ndx => 2, key => 'D', value => $locale->text('Delete') },
             'Change Password' => { ndx => 4, key => 'C', value => $locale->text('Change Password') },
             'Change Host' => { ndx => 5, key => 'H', value => $locale->text('Change Host') },
            );

  if (-f "$slconfig{userspath}/$form->{dbname}.LCK") {
    $button{'Unlock Dataset'} = { ndx => 1, key => 'U', value => $locale->text('Unlock Dataset') };
  } else {
    $button{'Lock Dataset'} = { ndx => 1, key => 'L', value => $locale->text('Lock Dataset') };
  }

  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}";

  $form->hide_form(qw(templates company dbname dbhost dbport dbdriver dbuser path callback));

  $form->print_button(\%button);

  print qq|

</form>

</body>
</html>
|;

}


sub list_datasets {

# type=submit $locale->text('Pg')
# type=submit $locale->text('Mock')

  my (%member, %datasets);
  eval { %member = Storable::retrieve("$slconfig{memberfile}.bin")->%*; };
  $form->error("$slconfig{memberfile}.bin: $@") if $@;

  delete $member{'root login'};

  for (grep /^admin@/, keys %member) {
    $datasets{$member{$_}{dbname}} = $member{$_};
    $datasets{$_}{locked} = "x" if -f "$slconfig{userspath}/$member{$_}{dbname}.LCK";
  }

  SL::User::add_db_size($form, \%datasets);

  $column_data{company}   = qq|<th>| . $locale->text('Company') . qq|</th>|;
  $column_data{dbdriver}  = qq|<th>| . $locale->text('Driver') . qq|</th>|;
  $column_data{dbhost}    = qq|<th>| . $locale->text('Host') . qq|</th>|;
  $column_data{dbname}    = qq|<th>| . $locale->text('Dataset') . qq|</th>|;
  $column_data{dbport}    = qq|<th>| . $locale->text('Port') . qq|</th>|;
  $column_data{dbuser}    = qq|<th>| . $locale->text('User') . qq|</th>|;
  $column_data{locked}    = qq|<th width=1%>| . $locale->text('Locked') . qq|</th>|;
  $column_data{size}      = qq|<th>| . $locale->text('Dataset Size') . qq|</th>|;
  $column_data{templates} = qq|<th>| . $locale->text('Templates') . qq|</th>|;

  @column_index = qw(dbname company size templates locked dbdriver dbuser dbhost dbport);

  my $perl_modules;
  if (my @missing = $form->load_module($form->perl_modules)) {
    $perl_modules = $locale->text('Module not installed:') . ' ' . join ', ', @missing;
  } else {
    $perl_modules = $locale->text('ok');
  }

  $dbdriver ||= "Pg";
  $dbdriver{$dbdriver} = "checked";

  for (SL::User->dbdrivers) {
    $dbdrivers .= qq|
               <input name=dbdriver type=radio class=radio value="$_" $dbdriver{$_}>|.$locale->text($_).qq|&nbsp;|;
  }

  $form->{title} = "SQL-Ledger ".$locale->text('Administration');


  $form->header;

  # Tekki: Software Administration
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

  for $key (sort keys %datasets) {
    my $dataset = $datasets{$key};
    $href = "$script?action=edit&dbname=$key&path=$form->{path}&locked=$dataset->{locked}&dbhost=$dataset->{dbhost}&dbport=$dataset->{dbport}&dbdriver=$dataset->{dbdriver}&dbuser=$dataset->{dbuser}&templates=$dataset->{templates}";
    $href .= "&company=".$form->escape($dataset->{company},1);

    for (qw(company dbdriver dbhost dbport dbuser templates)) {
      $column_data{$_} = qq|<td>$dataset->{$_}</td>|;
    }
    $column_data{dbname} = qq|<td><a href=$href>$dataset->{dbname}</a></td>|;
    $column_data{locked} = qq|<td align=center>$dataset->{locked}</td>|;
    $column_data{size}   = qq|<td align=right>$dataset->{size}</td>|;

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

<p>
<b>|.$locale->text('Perl Modules').qq|</b> $perl_modules
</p>
<p>
$dbdrivers
</p>
<p>
|;

  %button = ('Add Dataset' => { ndx => 1, key => 'A', value => $locale->text('Add Dataset') },
             'Change Password' => { ndx => 2, key => 'C', value => $locale->text('Change Password') },
             'Logout' => { ndx => 4, key => 'X', value => $locale->text('Logout') }
            );

  if (-f "$slconfig{userspath}/nologin.LCK") {
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
<body class=admin onload="document.main.${focus}.focus()">

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

  $form->error("$slconfig{memberfile}.bin : ".$locale->text('locked!')) if -f "$slconfig{memberfile}.LCK";

  open my $fh, '>', "$slconfig{memberfile}.LCK" or $form->error("$slconfig{memberfile}.LCK : $!");
  close $fh;

  my %member;
  eval { %member = Storable::retrieve("$slconfig{memberfile}.bin")->%*; };

  if ($@) {
    unlink "$slconfig{memberfile}.LCK";
    $form->error("$slconfig{memberfile}.bin: $@");
  }

  my %db;
  for $user (keys %member) {
    my $dbname = $member{$user}{dbname};

    $db{$dbname} ||= $member{$user};

    # for (keys %{$temp{$user}}) {
    #   $db{$dbname}{$_} = $temp{$user}{$_};
    #   $member{$dbname}{$user}{$_} = $temp{$user}{$_};
    # }
  }

  $form->{dbdriver} = $db{$form->{dbname}}{dbdriver};
  &dbdriver_defaults;
  for (qw(dbconnect dbuser dbhost dbport templates)) { $form->{$_} = $db{$form->{dbname}}{$_} }
  $form->{dbpasswd} = unpack 'u', $db{$form->{dbname}}{dbpasswd} if $db{$form->{dbname}}{dbpasswd};

  # delete dataset
  SL::User->dbdelete($form);

  # delete conf for users
  for (grep /.*\@$form->{dbname}/, keys %member) {
    unlink "$slconfig{userspath}/${_}.bin";
    delete $member{$_};
  }

  delete $member{$form->{dbname}};

  $templatedir = $db{$form->{dbname}}{templates} || $form->{dbname};
  delete $db{$form->{dbname}};
  for (keys %db) {
    if ($db{$_}{templates} eq $templatedir) {
      $skiptemplates = 1;
      last;
    }
  }

  YAML::PP->new->dump_file("$slconfig{memberfile}.yml", \%member);
  Storable::store \%member, "$slconfig{memberfile}.bin";

  # delete spool, images and template directory if it is not shared
  for (qw(templates spool images)) {

    if ($_ eq "templates") {
      $dir = "$slconfig{templates}/$templatedir";
      next if $skiptemplates;
    }

    if ($_ eq "spool") {
      $dir = "$slconfig{spool}/$form->{dbname}";
    }

    if ($_ eq "images") {
      $dir = "$slconfig{images}/$form->{dbname}";
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

  unlink "$slconfig{memberfile}.LCK";
  unlink "$slconfig{userspath}/$form->{dbname}.LCK";

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
<body class=admin onload="document.main.${focus}.focus()">

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

<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">|;

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
    $admin = SL::User->new($slconfig{memberfile}, "admin\@$form->{dbname}");

    for (qw(dbconnect dbuser dbpasswd dbhost dbport dbdriver)) { $form->{$_} = $admin->{$_} }
    $form->{dbpasswd} = unpack 'u', $form->{dbpasswd} if $form->{dbpasswd};

    open my $fh, '>', "$slconfig{memberfile}.LCK" or $form->error("$slconfig{memberfile}.LCK : $!");
    close $fh;

    my %member;
    eval { %member = Storable::retrieve("$slconfig{memberfile}.bin")->%*; };

    if ($@) {
      unlink "$slconfig{memberfile}.LCK";
      $form->error("$slconfig{memberfile}.bin: $@");
    }

    # change password
    SL::User->dbpassword($form);

    # change passwords in members file
    $form->{dbpasswd} = pack 'u', $form->{new_password};
    chomp $form->{dbpasswd};

    for my $param (values %member) {
      if ( $param->{dbdriver} eq $form->{dbdriver}
        && $param->{dbuser} eq $form->{dbuser}
        && $param->{dbhost} eq $form->{dbhost}
        && $param->{dbport} eq $form->{dbport})
      {
        $param->{dbpasswd} = $form->{dbpasswd};
      }
    }

    YAML::PP->new->dump_file("$slconfig{memberfile}.yml", \%member);
    Storable::store \%member, "$slconfig{memberfile}.bin";
    unlink "$slconfig{memberfile}.LCK";

  } else {

    $root->{password} = $form->{new_password};

    unless (-f "$slconfig{memberfile}.bin") {
      my %member = ('root login' => {});
      Storable::store \%member, "$slconfig{memberfile}.bin";
    }

    $root->{'root login'} = 1;
    $root->{login} = 'root login';
    $root->save_member($slconfig{memberfile}, $slconfig{userspath});

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
<body class=admin onload="document.main.${focus}.focus()">

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
        <tr>
          <th align=right>|.$locale->text('Port').qq|</th>
          <td><input name=new_port size=5 value=$form->{dbport}></td>
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

<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">|;

  $form->{nextsub} = "do_change_host";

  $form->hide_form(qw(path nextsub dbname dbhost dbport dbdriver));

  print qq|
</form>

</body>
</html>
|;

}


sub do_change_host {

  open my $fh, '>', "$slconfig{memberfile}.LCK" or $form->error("$slconfig{memberfile}.LCK : $!");
  close $fh;

  my %member;
  eval { %member = Storable::retrieve("$slconfig{memberfile}.bin")->%*; };

  if ($@) {
    unlink "$slconfig{memberfile}.LCK";
    $form->error("$slconfig{memberfile}.bin: $@");
  }

  for my $user (keys %member) {
    my $param = $member{$user};
    if ( $param->{dbdriver} eq $form->{dbdriver}
      && $param->{dbname} eq $form->{dbname}
      && ($form->{new_host} ne $param->{dbhost} || $form->{new_port} ne $param->{dbport}))
    {
      $param->{dbhost}    = $form->{new_host};
      $param->{dbport}    = $form->{new_port};
      $param->{dbconnect} = "dbi:$form->{dbdriver}:dbname=$form->{dbname}";
      if ($form->{new_host}) {
        $param->{dbconnect} .= ";host=$form->{new_host}";
      }
      if ($form->{new_port}) {
        $param->{dbconnect} .= ";port=$form->{new_port}";
      }

      if (-f "$slconfig{userspath}/$user.bin") {
        my $config = Storable::retrieve "$slconfig{userspath}/$user.bin";
        $config->{$_} = $param->{$_} for qw|dbdriver dbname dbhost dbport dbconnect|;
        Storable::store $config, "$slconfig{userspath}/$user.bin";
      }
    }
  }

  YAML::PP->new->dump_file("$slconfig{memberfile}.yml", \%member);
  Storable::store \%member, "$slconfig{memberfile}.bin";
  unlink "$slconfig{memberfile}.LCK";

  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}";

  $form->redirect($locale->text('Lockfile removed!'));

}


sub check_password {

  $root = SL::User->new($slconfig{memberfile}, 'root login');

  eval { %rootconfig = Storable::retrieve("$slconfig{userspath}/root login.bin")->%*; };

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
sub Mock { &dbselect_source }


sub dbdriver_defaults {

  # load some defaults for the selected driver
  %driverdefaults = (
    Pg => {
      dbport        => '',
      dbuser        => 'sql-ledger',
      dbdefault     => 'template1',
      dbhost        => '',
      connectstring => $locale->text('Connect to')
    },
  );

  $driverdefaults{Mock} = $driverdefaults{Pg};

  for (keys %{ $driverdefaults{Pg} }) { $form->{$_} = $driverdefaults{$form->{dbdriver}}{$_} }

}


sub dbselect_source {

  &dbdriver_defaults;

  $form->{title} = "SQL-Ledger / ".$locale->text('Add Dataset');

  $form->{callback} = "$form->{script}?action=list_datasets&path=$form->{path}";

  $focus = "dbhost";

  $form->header;

  print qq|
<body class=admin onLoad="document.main.${focus}.focus()">

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
          <td><input name=dbhost size=50 value=$form->{dbhost}></td>
          <th align=right>|.$locale->text('Port').qq|</th>
          <td><input name=dbport size=5 value=$form->{dbport}></td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('User').qq|</th>
          <td><input name=dbuser size=25 value=$form->{dbuser}></td>
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
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">
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

  @dbsources = sort SL::User->dbsources($form);

  opendir SQLDIR, "sql" or $form->error($!);
  foreach $item (sort grep /-chart\.sql/, readdir SQLDIR) {
    next if ($item eq 'Default-chart.sql');
    $item =~ s/-chart\.sql//;
    $selectchart .= "$item\n";
  }

  $selectchart = "Default\n$selectchart" if (-f 'sql/Default-chart.sql');
  closedir SQLDIR;

  $form->{name} ||= lc $locale->text('Admin');

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

  $selectencoding = SL::User->encoding($form->{dbdriver});
  $form->{charset} = $slconfig{charset};

  # get subdirectories from templates directory
  if (-d $slconfig{templates}) {
    opendir TEMPLATEDIR, "$slconfig{templates}" or $form->error("$slconfig{templates} : $!");
    @d = grep !/^\./, readdir TEMPLATEDIR;
    closedir TEMPLATEDIR;
    for (@d) { push @dir, $_ if -d "$slconfig{templates}/$_" }

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
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">
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

  $form->error("$slconfig{memberfile} : ".$locale->text('locked!')) if -f "$slconfig{memberfile}.LCK";
  $form->error($locale->text('Cannot use') . " $form->{db}") if $form->{dbdriver} =~ /Pg/ && $form->{db} =~ /^template(0|1)$/;

  # check if dbname is already in use
  my %member;
  eval { %member = Storable::retrieve("$slconfig{memberfile}.bin")->%*; };
  $form->error("$slconfig{memberfile}.bin: $@") if $@;

  my %db;
  for my $user (keys %member) {
    $user =~ /.*@/;
    $db{$'} = $member{$user}{dbname};
  }

  $form->error($locale->text('Duplicate Dataset!')) if $form->{db} eq $db{$form->{db}};

  open my $fh, '>', "$slconfig{memberfile}.LCK" or $form->error("$slconfig{memberfile}.LCK : $!");
  close $fh;

  $templatedir = "doc/templates";

  umask(002);

  if (! -d "$slconfig{templates}") {
    mkdir "$slconfig{templates}", oct("771") or $form->error("$slconfig{templates} : $!");
  }

  $form->{company} ||= $form->{db};

  # create user template directory and copy master files
  $form->{templates} = ($form->{usetemplates}) ? "$form->{usetemplates}" : "$form->{db}";

  # get templates from master
  opendir TEMPLATEDIR, "$templatedir/$form->{mastertemplates}" or $form->error("$slconfig{templates} : $!");
  @templates = grep !/^\./, readdir TEMPLATEDIR;
  closedir TEMPLATEDIR;

  if (! -d "$slconfig{templates}/$form->{templates}") {
    mkdir "$slconfig{templates}/$form->{templates}", oct("771") or $form->error("$slconfig{templates}/$form->{templates} : $!");
  }

  foreach $file (@templates) {
    if (! -f "$slconfig{templates}/$form->{templates}/$file") {
      open $temp, "$templatedir/$form->{mastertemplates}/$file" or $form->error("$templatedir/$form->{mastertemplates}/$file : $!");
      open $new, ">$slconfig{templates}/$form->{templates}/$file" or $form->error("$slconfig{templates}/$form->{templates}/$file : $!");

      for (<$temp>) { print $new $_ }
      close $new;
      close $temp;
    }
  }

  # copy logo files
  for $ext (qw(eps png)) {
    if (! -f "$slconfig{templates}/$form->{templates}/logo.$ext") {
      open $temp, "$slconfig{userspath}/sql-ledger.$ext";
      open $new, ">$slconfig{templates}/$form->{templates}/logo.$ext";
      for (<$temp>) { print $new $_ }
      close $new;
      close $temp;
    }
  }

  if (! -d "$slconfig{spool}/$form->{db}") {
    mkdir "$slconfig{spool}/$form->{db}", oct("771") or $form->error("$slconfig{spool}/$form->{db} : $!");
  }

  if (! -d "$slconfig{images}/$form->{db}") {
    mkdir "$slconfig{images}/$form->{db}", oct("771") or $form->error("$slconfig{images}/$form->{db} : $!");
  }

  # add admin to members file

  if ($@) {
    unlink "$slconfig{memberfile}.LCK";
    $form->error("$slconfig{memberfile}.bin: $@");
  }

  # create dataset
  SL::User->dbcreate($form);

  $form->{charset} = $form->{encoding};
  $form->{dbname} = $form->{db};
  $form->{login} = "admin\@$form->{db}";
  $form->{stylesheet} = "sql-ledger.css";
  $form->{dateformat} = "mm-dd-yy";
  $form->{numberformat} = "1,000.00";
  $form->{dboptions} = "set DateStyle to 'POSTGRES, US'";
  $form->{dboptions} .= ';set client_encoding to \''.$form->{encoding}."'" if $form->{encoding};
  $form->{vclimit} = "1000";

  if ($form->{dbpasswd}) {
    $form->{dbpasswd} = pack 'u', $form->{dbpasswd};
    chomp $form->{dbpasswd};
  }

  if ($form->{adminpassword}) {
    srand( time() ^ ($$ + ($$ << 15)) );
    $form->{password} = crypt $form->{adminpassword}, 'ad';
  }

  for (
    'charset', 'company',      'dateformat', 'dbconnect',  'dbdriver',  'dbhost',
    'dbname',  'dboptions',    'dbpasswd',   'dbport',     'dbuser',    'email',
    'name',    'numberformat', 'password',   'stylesheet', 'templates', 'vclimit',
    )
  {
    $member{$form->{login}}{$_} = $form->{$_} if $form->{$_};
  }
  YAML::PP->new->dump_file("$slconfig{memberfile}.yml", \%member);
  Storable::store \%member, "$slconfig{memberfile}.bin";

  unlink "$slconfig{memberfile}.LCK";

  delete $form->{password};

  &list_datasets;

}


sub unlock_dataset { &unlock_system }

sub unlock_system {

  if ($form->{dbname}) {
    $filename = "$slconfig{userspath}/$form->{dbname}.LCK";
  } else {
    $filename = "$slconfig{userspath}/nologin.LCK";
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
<body class=admin onLoad="document.main.${focus}.focus()">

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
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">|;

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
    open $fh, ">$slconfig{userspath}/$form->{dbname}.LCK" or $form->error($locale->text('Cannot create Lock!'));
  } else {
    open $fh, ">$slconfig{userspath}/nologin.LCK" or $form->error($locale->text('Cannot create Lock!'));
  }

  if ($form->{lock}) {
    print $fh $form->{lock};
  }
  close $fh;

  $form->redirect($locale->text('Lockfile created!'));

}



=encoding utf8

=head1 NAME

bin/mozilla/admin.pl - Setup module

=head1 DESCRIPTION

L<bin::mozilla::admin> contains the setup module,
add/edit/delete users.

=head1 DEPENDENCIES

L<bin::mozilla::admin>

=over

=item * uses
L<SL::Form>,
L<SL::User>

=item * requires
L<DBI>,
L<bin::mozilla::pw>

=item * optionally requires
C<$slconfig{userspath}/${rootname}.conf>,
F<< bin/mozilla/custom/admin.pl >>

=back

=head1 FUNCTIONS

L<bin::mozilla::admin> implements the following functions:

=head2 Mock

=head2 Pg

=head2 add_dataset

Calls C<< &{ "$form->{dbdriver}" } >>.

=head2 adminlogin

=head2 change_host

=head2 change_password

=head2 check_password

=head2 continue

Calls C<< &{ $form->{nextsub} } >>.

=head2 create_config

=head2 create_dataset

=head2 dbcreate

=head2 dbdriver_defaults

=head2 dbselect_source

=head2 delete

=head2 do_change_host

=head2 do_change_password

=head2 do_delete

=head2 do_lock_system

=head2 edit

=head2 form_footer

=head2 form_header

=head2 list_datasets

=head2 lock_dataset

=head2 lock_system

=head2 login

=head2 logout

=head2 unlock_dataset

=head2 unlock_system

=head2 yes

Calls C<< &{ $form->{nextsub} } >>.

=cut
