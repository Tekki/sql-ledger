#======================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2025 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# login frontend
#
#======================================================================


use DBI;
use SL::User;
use SL::Form;
use SL::Locale;


$form = SL::Form->new;


$locale = SL::Locale->new($slconfig{language}, "login");

# $form->{charset} = $slconfig{charset};

# customization
if (-f "$form->{path}/custom/$form->{script}") {
  eval { require "$form->{path}/custom/$form->{script}"; };
  $form->error($@) if ($@);
}

# per login customization
if (-f "$form->{path}/custom/$form->{login}/$form->{script}") {
  eval { require "$form->{path}/custom/$form->{login}/$form->{script}"; };
  $form->error($@) if ($@);
}

if ($form->{action}) {
  &{ $locale->findsub($form->{action}) };
} else {
  &login_screen;
}


1;


sub login_screen {

  $form->{stylesheet} = "sql-ledger.css";
  $form->{favicon} = "favicon.ico";

  $form->header;

  $focus = ($form->{login}) ? "password" : "login";

  print qq|
<body class=login onload="jsp(); document.forms[0].${focus}.focus()">

<pre>






</pre>

<center>
<table class=login border=3 cellpadding=20>
  <tr>
    <td class=login align=center><a href="https://github.com/Tekki/sql-ledger" target=_blank><img src=$slconfig{images}/sql-ledger.png border=0></a>
<h1 class=login align=center>|.$locale->text('Version').qq| $form->{version}</h1>
<p>

    <form method=post name=main action=$form->{script}>

      <table width=100%>
        <tr>
          <td align=center>
            <table>
              <tr>
                <th align=right>|.$locale->text('Name').qq|</th>
                <td><input class=login name=login size=30></td>
              </tr>
              <tr>
                <th align=right>|.$locale->text('Password').qq|</th>
                <td><input class=login type=password name=password size=30></td>
              </tr>
            </table>

            <br>
            <input type=submit name=action value="|.$locale->text('Login').qq|">
          </td>
        </tr>
      </table>
|;

    $form->hide_form(qw(js path small_device));

  print qq|
      </form>

    </td>
  </tr>
</table>

<script>
<!--
var agt = navigator.userAgent.toLowerCase();
var is_major = parseInt(navigator.appVersion);
var is_nav = ((agt.indexOf('mozilla') != -1) && (agt.indexOf('spoofer') == -1)
           && (agt.indexOf('compatible') == -1) && (agt.indexOf('opera') == -1)
           && (agt.indexOf('webtv') == -1));
var is_nav4lo = (is_nav && (is_major <= 4));

function jsp() {
  if (is_nav4lo)
    document.forms[0].js.value = ""
  else
    document.forms[0].js.value = "1"
}

function checkWidth(window_x) {
  if (window_x.matches) {
    document.forms[0].small_device.value = 1;
  } else {
    document.forms[0].small_device.value = 0;
  }
}

var window_x = window.matchMedia("(max-width: 700px)");
checkWidth(window_x);
window_x.addListener(checkWidth);
// End -->
</script>

</body>
</html>
|;

}


sub selectdataset {
  my ($login) = @_;

  if (-f "css/sql-ledger.css") {
    $form->{stylesheet} = "sql-ledger.css";
  }
  if (-f 'favicon.ico') {
    $form->{favicon} = "favicon.ico";
  }

  delete $self->{sessioncookie};
  $form->header(1);

  print qq|
<body class=login onload="document.forms[0].password.focus()">

<pre>

</pre>

<center>
<table class=login border=3 cellpadding=20>
  <tr>
    <td class=login align=center><a href="https://github.com/Tekki/sql-ledger" target=_blank><img src=$slconfig{images}/sql-ledger.png border=0></a>
<h1 class=login align=center>|.$locale->text('Version').qq| $form->{version}</h1>

<p>

<form method=post action=$form->{script}>

<input type=hidden name=beenthere value=1>

      <table width=100%>
        <tr>
          <td align=center>
            <table>
              <tr>
                <th align=right>|.$locale->text('Name').qq|</th>
                <td>$form->{login}</td>
              </tr>
              <tr>
                <th align=right>|.$locale->text('Password').qq|</th>
                <td><input class=login type=password name=password size=30 value=$form->{password}></td>
              </tr>
              <tr>
                <th align=right>|.$locale->text('Company').qq|</th>
                <td>|;

                $form->hide_form(qw(js path));

                $checked = "checked";
                for (sort { lc $login->{$a} cmp lc $login->{$b} } keys %$login) {
                  print qq|
                  <br><input class="login" type="radio" name="login" value="$_" $checked>$login->{$_}
                  |;
                  $checked = "";
                }

                print qq|
                  </td>
              </tr>
            </table>
            <br>
            <input type=submit name=action value="|.$locale->text('Login').qq|">
          </td>
        </tr>
      </table>

</form>

    </td>
  </tr>
</table>

</body>
</html>
|;


}


sub login {

  $form->{stylesheet} = "sql-ledger.css";
  $form->{favicon} = "favicon.ico";

  $form->error($locale->text('You did not enter a name!')) unless ($form->{login});

  if (! $form->{beenthere}) {

    my $members = Storable::retrieve "$slconfig{memberfile}.bin";

    my %login;
    for (grep /^\Q$form->{login}\E(\@|$)/, keys %$members) {
      $login{$_} = $members->{$_}{dbname};
    }

    if (keys %login > 1) {
      if ($slconfig{helpful_login}) {
        &selectdataset(\%login);
        exit;
      } else {
        $form->error($locale->text('Incorrect Username or Password!'));
      }
    } else {
      if ($form->{login} !~ /\@/) {
        $form->{login} .= "\@$dbname";
      }
    }
  }

  $user = SL::User->new($slconfig{memberfile}, $form->{login});

  # if we get an error back, bale out
  if (($errno = $user->login($form, $slconfig{userspath})) <= -1) {

    $errno *= -1;
    if ($slconfig{helpful_login}) {
      $err[1] = $locale->text('Incorrect Username!');
      $err[2] = $locale->text('Incorrect Password!');
    } else {
      $err[1] = $err[2] = $locale->text('Incorrect Username or Password!');
    }
    $err[3] = $locale->text('Incorrect Dataset version!');
    $err[4] = $locale->text('Dataset is newer than version!');


    if ($errno == 1 && $form->{admin} && $slconfig{helpful_login}) {
      $err[1] = $locale->text('admin does not exist!');
    }

    if ($errno == 4 && $form->{admin}) {

      $form->info($err[4]);

      $form->info("<p><a href=menu.pl?login=$form->{login}&path=$form->{path}&action=display&main=company_logo&js=$form->{js}&password=$form->{password}>".$locale->text('Continue')."</a>");

      exit;

    }

    if ($errno == 5) {
      if (-f "$slconfig{userspath}/$user->{dbname}.LCK") {
        if (-s "$slconfig{userspath}/$user->{dbname}.LCK") {
          open my $fh, "$slconfig{userspath}/$user->{dbname}.LCK" ;
          $msg = <$fh>;
          close $fh;
          if ($form->{admin}) {
            $form->info($msg);
          } else {
            $form->error($msg);
          }
        } else {
          $msg = $locale->text('Dataset locked!');
          if ($form->{admin}) {
            $form->info($msg);
          } else {
            $form->error($msg);
          }
        }

      } else {

        # upgrade dataset and log in again
        open FH, ">$slconfig{userspath}/$user->{dbname}.LCK" or $form->error($!);

        for (qw(dbname dbhost dbport dbdriver dbconnect dbuser dbpasswd)) { $form->{$_} = $user->{$_} }

        $form->info($locale->text('Upgrading to Version')." $form->{version} ... ");

        $user->dbupdate($form);

        # remove lock file
        unlink "$slconfig{userspath}/$user->{dbname}.LCK";

      }

      $form->info("<p><a href=menu.pl?login=$form->{login}&path=$form->{path}&action=display&main=company_logo&js=$form->{js}&password=$form->{password}>".$locale->text('Continue')."</a>");

      exit;

    }

    $form->error($err[$errno]);

  }

  for (qw(dbconnect dbhost dbport dbname dbuser dbpasswd)) { $myconfig{$_} = $user->{$_} }

  # create image directory
  if (! -d "$slconfig{images}/$myconfig{dbname}") {
    mkdir "$slconfig{images}/$myconfig{dbname}", oct("771") or $form->error("$slconfig{images}/$myconfig{dbname} : $!");
  }

  if ($user->{totp_activated} || $form->{admin} && $slconfig{admin_totp_activated}) {
    &totp_screen;
    exit;
  } elsif ($user->{tan} && $slconfig{sendmail}) {
    &email_tan;
    exit;
  }

  # remove stale locks
  $form->remove_locks(\%myconfig);

  $form->{timeout} = $user->{timeout};
  $form->{sessioncookie} = $user->{sessioncookie};

  # made it this far, setup callback for the menu
  $form->{callback} = "menu.pl?action=display";
  for (qw(login path password js sessioncookie small_device)) { $form->{callback} .= "&$_=$form->{$_}" }

  # check for recurring transactions
  if ($user->{acs} !~ /Recurring Transactions/) {
    if ($user->check_recurring($form)) {
      $form->{callback} .= "&main=recurring_transactions";
    } else {
      $form->{callback} .= "&main=list_recent";
    }
  } else {
    $form->{callback} .= "&main=list_recent";
  }

  $form->redirect;

}


sub logout {

  $form->{callback} = "$form->{script}?path=$form->{path}&end session=1";

  if (-f "$slconfig{userspath}/$form->{login}.bin") {
    $form->{callback} .= "&login=$form->{login}";
    %myconfig = Storable::retrieve("$slconfig{userspath}/$form->{login}.bin")->%*;
    $myconfig{dbpasswd} = unpack 'u', $myconfig{dbpasswd} if $myconfig{dbpasswd};

    SL::User->logout(\%myconfig, $form);
  }

  $form->redirect;

}


sub email_tan {

  $form->error($locale->text('No email address for')." $user->{name}") unless ($user->{email});

  use SL::Mailer;
  $mail = SL::Mailer->new;

  srand( time() ^ ($$ + ($$ << 15)) );
  $digits = "0123456789";
  $tan = "";
  while (length($tan) < 4) {
    $tan .= substr($digits, (int(rand(length($digits)))), 1);
  }

  $mail->{message} = $locale->text('TAN').": $tan";
  $mail->{from} = $mail->{to} = qq|"$user->{name}" <$user->{email}>|;
  $mail->{subject} = "SQL-Ledger $form->{version} $user->{company} $mail->{message}";


  $form->error($err) if ($err = $mail->send($slconfig{sendmail}));

  $form->{stylesheet} = $user->{stylesheet};
  $form->{favicon} = "favicon.ico";
  $form->{nextsub} = "tan_login";

  $user->{password} = $tan;

  $user->create_config("$slconfig{userspath}/$form->{login}.bin");


  $form->header;

  print qq|

<body class=login>

<pre>

</pre>

<center>
<table class=login border=3 cellpadding=20>
  <tr>
    <td class=login align=center><a href="https://github.com/Tekki/sql-ledger" target=_blank><img src=$slconfig{images}/sql-ledger.png border=0></a>
<h1 class=login align=center>|.$locale->text('Version').qq| $form->{version}</h1>
<h1 class=login align=center>$user->{company}</h1>

<p>

      <form method=post action=$form->{script}>

      <table width=100%>
        <tr>
          <td align=center>
            <table>
              <tr>
                <th align=right>|.$locale->text('TAN').qq|</th>
                <td><input class=login type=password name=password size=30></td>
              </tr>
            </table>
            <br>
            <input type=submit name=action value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">
          </td>
        </tr>
      </table>
|;


    $form->hide_form(qw(nextsub js login path));

  print qq|
      </form>

    </td>
  </tr>
</table>

</body>
</html>
|;

}


sub tan_login {

  $form->{login} =~ s/(\.\.|\/|\\|\x00)//g;

  # check for user config file, could be missing or ???
  eval { %myconfig = Storable::retrieve("$slconfig{userspath}/$form->{login}.bin")->%*; };

  if ($@) {
    $form->error($locale->text('Configuration file missing!'));
    exit;
  }

  if ((crypt $form->{password}, substr($form->{login}, 0, 2)) ne $myconfig{password}) {
    if (-f "$slconfig{userspath}/$form->{login}.tan") {
      open my $fh, "+<$slconfig{userspath}/$form->{login}.tan" or $form->error("$slconfig{userspath}/$form->{login}.tan : $!");

      $tries = <$fh>;
      $tries++;

      seek($fh, 0, 0);
      truncate($fh, 0);
      print $fh $tries;
      close $fh;

      if ($tries > 3) {
        unlink "$slconfig{userspath}/$form->{login}.bin";
        unlink "$slconfig{userspath}/$form->{login}.tan";
        $form->error($locale->text('Maximum tries exceeded!'));
      }
    } else {
      open my $fh, ">$slconfig{userspath}/$form->{login}.tan" or $form->error("$slconfig{userspath}/$form->{login}.tan : $!");
      print $fh "1";
      close $fh;
    }

    $form->error($locale->text('Invalid TAN'));
  } else {

    # remove stale locks
    $form->remove_locks(\%myconfig);

    unlink "$slconfig{userspath}/$form->{login}.tan";

    $form->{callback} = "menu.pl?action=display";
    for (qw(login path js password)) { $form->{callback} .= "&$_=$form->{$_}" }
    $form->{callback} .= "&main=company_logo";

    $form->redirect;

  }

}


sub totp_screen {

  my $qrcode = '';
  unless ($user->{totp_secret}) {
    $form->load_module(['Text::QRCode'], $locale->text('Module not installed:'));
    require SL::QRCode;
    require SL::TOTP;

    SL::TOTP::add_secret($user, $slconfig{memberfile}, $slconfig{userspath});

    $qrcode = qq|
              <tr>
                <th colspan="2">|.$locale->text('Scan the following code with your Authenticator App:').qq|</th>
              </tr>
              <tr><td>&nbsp;</td></tr>
              <tr>
                <th colspan="2">
|. SL::QRCode::plot_svg(SL::TOTP::url($user), scale => 4) . qq|
                </th>
              </tr>
              <tr>
                <th colspan="2">$user->{totp_secret}</th>
              </tr>
              <tr><td>&nbsp;</td></tr>|;
  }

  $form->{stylesheet} = $user->{stylesheet};
  $form->{favicon}    = 'favicon.ico';
  $form->{nextsub}    = 'totp_login';

  $form->header;

  print qq|

<body class=login onload="document.forms[0].totp.focus()">

<pre>

</pre>

<center>
<table class=login border=3 cellpadding=20>
  <tr>
    <td class=login align=center><a href="https://github.com/Tekki/sql-ledger" target=_blank><img src=$slconfig{images}/sql-ledger.png border=0></a>
<h1 class=login align=center>|.$locale->text('Version').qq| $form->{version}</h1>
<p>

      <form method=post action=$form->{script}>

      <table width=100%>
        <tr>
          <td align=center>
            <table>
              <tr>
                <th colspan=2>$form->{login}</th>
              </tr>$qrcode
              <tr>
                <th align=right>|.$locale->text('Code from Authenticator').qq|</th>
                <td><input class=login type=text name=totp size=6></td>
              </tr>
            </table>
            <br>
            <input type=submit name=action value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">
          </td>
        </tr>
      </table>
|;

    $form->hide_form(qw|nextsub js login path|);

  print qq|
      </form>

    </td>
  </tr>
</table>

</body>
</html>
|;

}


sub totp_login {

  require SL::TOTP;

  $user = SL::User->new($slconfig{memberfile}, $form->{login});

  unless (SL::TOTP::check_code($user, $form->{totp})) {
    sleep 5;
    $form->{stylesheet} = $user->{stylesheet};
    $form->error($locale->text('Invalid Code'));
  }

  $user->create_config("$slconfig{userspath}/$form->{login}.bin");
  $user->{dbpasswd} = unpack 'u', $user->{dbpasswd} if $user->{dbpasswd};

  %myconfig = $user->%{qw|dbconnect dbhost dbname dbuser dbpasswd|};

  # remove stale locks
  $form->remove_locks(\%myconfig);

  $form->{timeout}       = $user->{timeout};
  $form->{sessioncookie} = $user->{sessioncookie};

  # made it this far, setup callback for the menu
  $form->{callback} = "menu.pl?action=display";
  for (qw(login path password js sessioncookie small_device)) {
    $form->{callback} .= "&$_=$form->{$_}";
  }

  # check for recurring transactions
  if ($user->{acs} !~ /Recurring Transactions/) {
    if ($user->check_recurring($form)) {
      $form->{callback} .= "&main=recurring_transactions";
    } else {
      $form->{callback} .= "&main=list_recent";
    }
  } else {
    $form->{callback} .= "&main=list_recent";
  }

  $form->redirect;

}


sub continue { &{ $form->{nextsub} } };

=encoding utf8

=head1 NAME

bin/mozilla/login.pl - Login frontend

=head1 DESCRIPTION

L<bin::mozilla::login> contains functions for login frontend.

=head1 DEPENDENCIES

L<bin::mozilla::login>

=over

=item * uses
L<DBI>,
L<SL::Form>,
L<SL::User>

=item * requires
F<< $slconfig{userspath}/$form->{login}.bin >>

=item * optionally requires
F<< bin/mozilla/custom/$form->{login}/login.pl >>,
F<< bin/mozilla/custom/$form->login.pl >>

=back

=head1 FUNCTIONS

L<bin::mozilla::login> implements the following functions:

=head2 continue

Calls C<< &{ $form->{nextsub} } >>.

=head2 email_tan

=head2 login

=head2 login_screen

=head2 logout

=head2 selectdataset

  &selectdataset($login);

=head2 tan_login

=head2 totp_login

=head2 totp_screen

=cut
