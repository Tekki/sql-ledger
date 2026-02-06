#======================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
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
use Storable ();

sub h {
  my ($s) = @_;
  $s = '' unless defined $s;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/>/&gt;/g;
  $s =~ s/"/&quot;/g;
  $s =~ s/'/&#39;/g;
  return $s;
}


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

sub login_env_html {
  my ($form, $locale) = @_;

  my $env = $form->environment;

  my %env_label = (
    dev  => $locale->text('Development Environment'),
    test => $locale->text('Test Environment'),
  );

  my $version_label = $locale->text('Version');

  if (exists $env_label{$env}) {
    return qq{
      <div class="login-env">
        <header class="login-env-header smallcaps">
          <h1>$env_label{$env}</h1>
          <h3>$version_label $form->{version}-$form->{cssversion}</h3>
        </header>
      </div>
    };
  }

  return qq{
    <div class="login-env">
      <header class="login-env-header smallcaps">
        <h3>$version_label $form->{version}-$form->{cssversion}</h3>
      </header>
    </div>
  };
}

sub login_screen {

  $form->{stylesheet} = "blue.css";
  $form->{favicon} = "favicon.ico";

  $form->header;

  $focus = ($form->{login}) ? "user" : "login";

  my $env_html = login_env_html($form, $locale);

  print qq|
<body class="login">

<div class="login-wrapper">
  <div class="login-column">
    <div class="login-brand">
      <div class="flip-card">
        <div class="flip-card-inner">
          <div class="flip-card-front">
            <img src="$slconfig{images}/sql-ledger.png" class="flip-logo" alt="SQL-Ledger">
            <h1>|.$locale->text('Open source ERP system').qq|</h1>
          </div>
          <div class="flip-card-back smallcaps">
            <h3>Credits</h3>
            <div class="ai-row">
              <div class="ai-half">
                <a href="https://github.com/Tekki/sql-ledger"><img src="$slconfig{images}/sql-ledger.png" height="100" class="image-hover" alt=""></a>
                <br><b>|.$locale->text('based').qq|</b>
              </div>
              <div class="ai-half">
                <a href="mailto:spam.spam@spam.spam" data-email-user="info" data-email-domain="domain.com"><img src="$slconfig{images}/sql-ledger.png" height="100" class="image-hover" alt=""></a>
                <br><b>|.$locale->text('operated by').qq|</b>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    $env_html
    <div class="login-form">
      <form method="post" name="main" action="$form->{script}">
        <div class="card">
          <div class="login-field floating">
            <input id="login" name="login" class="login-input" type="text" autocomplete="username" required placeholder=" ">
            <label for="login">|.$locale->text('User').qq|</label>
          </div>
          <div class="login-field floating">
            <input id="password" name="password" class="login-input" type="password" autocomplete="current-password" required placeholder=" ">
            <label for="password">|.$locale->text('Password').qq|</label>
            <div class="capslock-warning" hidden>
              |.$locale->text('Caps Lock is ON').qq|
            </div>
          </div>
          <div class="login-field">
            <button type="submit" class="button login-button" name="action" value="login">|.$locale->text('Login').qq|</button>
          </div>
            |;
            $form->hide_form(qw(js path small_device));
            print qq|
        </div>
      </form>
    </div>
    <div class="login-quote">
      <noscript>
        <em>|.$locale->text('Welcome').qq|</em>
      </noscript>
      <script src="https://www.citatum.hu/js.php?kategoria=B%F6lcsess%E9g"></script>
    </div>
  </div>
</div>

<script>
document.addEventListener("DOMContentLoaded", function () {
  const form = document.forms[0];
  if (!form) return;

  document.querySelectorAll('a[data-email-user][data-email-domain]').forEach((a) => {
    const user = a.dataset.emailUser;
    const domain = a.dataset.emailDomain;
    if (user && domain) a.href = `mailto:${user}@${domain}`;
  });

  form.addEventListener("submit", function (e) {
    if (typeof checkform === "function" && !checkform()) {
      e.preventDefault();
    }
  });

  if (form.js) {
    form.js.value = "1";
  }

  function checkWidth(mql) {
    if (form.small_device) {
      form.small_device.value = mql.matches ? 1 : 0;
    }
  }

  if (window.matchMedia) {
    const mql = window.matchMedia("(max-width: 700px)");
    checkWidth(mql);

    if (mql.addEventListener) {
      mql.addEventListener("change", checkWidth);
    } else if (mql.addListener) {
      mql.addListener(checkWidth);
    }
  }

  const focus = "$focus";
  if (form[focus]) {
    form[focus].focus();
  }
});
</script>

<script>
document.addEventListener("DOMContentLoaded", function () {
  const pwd = document.getElementById("password");
  if (!pwd) return;

  const warning = pwd
    .closest(".login-field")
    .querySelector(".capslock-warning");

  function checkCaps(e) {
    const caps = e.getModifierState && e.getModifierState("CapsLock");
    warning.hidden = !caps;
  }

  pwd.addEventListener("keydown", checkCaps);
  pwd.addEventListener("keyup", checkCaps);
  pwd.addEventListener("focus", checkCaps);
  pwd.addEventListener("blur", () => warning.hidden = true);
});
</script>

</body>
</html>
|;

}


sub selectdataset {
  my ($login) = @_;

  if (-f "css/blue.css") {
    $form->{stylesheet} = "blue.css";
  }
  if (-f 'favicon.ico') {
    $form->{favicon} = "favicon.ico";
  }

  delete $form->{sessioncookie};
  $form->header(1);

  my $env_html = login_env_html($form, $locale);
  my $login_h  = h($form->{login});

  print qq|
<body class="login">

<div class="login-wrapper">
  <div class="login-column">
    <div class="login-brand">
      <div class="flip-card">
        <div class="flip-card-inner">
          <div class="flip-card-front">
            <img src="$slconfig{images}/sql-ledger.png" class="flip-logo" alt="SQL-Ledger">
            <h1>|.$locale->text('Open source ERP system').qq|</h1>
          </div>
          <div class="flip-card-back smallcaps">
            <h3>Credits</h3>
            <div class="ai-row">
              <div class="ai-half">
                <a href="https://github.com/Tekki/sql-ledger"><img src="$slconfig{images}/sql-ledger.png" height="100" class="image-hover" alt=""></a>
                <br><b>|.$locale->text('based').qq|</b>
              </div>
              <div class="ai-half">
                <a href="mailto:spam.spam@spam.spam" data-email-user="info" data-email-domain="domain.com"><img src="$slconfig{images}/sql-ledger.png" height="100" class="image-hover" alt=""></a>
                <br><b>|.$locale->text('operated by').qq|</b>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    $env_html
    <div class="login-form">
      <form method="post" action="$form->{script}">
        <div class="card">
          <div class="login-field floating">
            <input id="login" name="login_display" class="login-input login-static" type="text" value="|.$login_h.qq|" readonly tabindex="-1" placeholder=" ">
            <label for="login">|.$locale->text('User').qq|</label>
          </div>
          <div class="login-field floating">
            <input id="password" name="password" class="login-input" type="password" autocomplete="current-password" required placeholder=" ">
            <label for="password">|.$locale->text('Password').qq|</label>
          </div>
        </div>
        <div class="card login-dataset">
          <div class="login-dataset-header">
            <svg class="dataset-icon" aria-hidden="true">
              <use href="images/icons.svg#icon-database"></use>
            </svg>
            <div class="dataset-text">
              <div class="dataset-label">
                |.$locale->text('Select Company').qq|
              </div>
            </div>
          </div>
          <div class="login-field">
            <select id="company" name="login" class="login-input" aria-label="|.$locale->text('Select Company').qq|">
              |;
              for my $key ( sort { lc( $login->{$a}{company} // $a ) cmp lc( $login->{$b}{company} // $b ) } keys %{ $login } ) {
              my $label = $login->{$key}{company} // $key;
              my $sel   = ($current && $current eq $key) ? ' selected' : '';
              my $key_h   = h($key);
              my $label_h = h($label);
              print qq|<option value="$key_h"$sel>$label_h</option>\n|;
              }
              print qq|
            </select>
          </div>
            |;
            print qq|
          <div class="login-field">
            <button type="submit" class="button login-button" name="action" value="login">|.$locale->text('Login').qq|</button>
          </div>
        </div>
      </form>
    </div>
  </div>
</div>

<script>
document.addEventListener("DOMContentLoaded", function () {
  const form = document.forms[0];
  if (!form) return;

  document.querySelectorAll('a[data-email-user][data-email-domain]').forEach((a) => {
    const user = a.dataset.emailUser;
    const domain = a.dataset.emailDomain;
    if (user && domain) a.href = `mailto:${user}@${domain}`;
  });

  form.addEventListener("submit", function (e) {
    if (typeof checkform === "function" && !checkform()) {
      e.preventDefault();
    }
  });

  if (form.password) {
    form.password.focus();
  }
});
</script>

</body>
</html>
|;


}


sub login {

  $form->{stylesheet} = "blue.css";
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
      if ($form->{login} !~ /\@/ && keys %login == 1) {
        my ($only) = keys %login;
        $form->{login} = $only if defined $only && $only =~ /\@/;
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

      my $login_u = $form->escape($form->{login}, 1);
      my $path_u  = $form->escape($form->{path}, 1);
      my $js_u    = $form->escape($form->{js}, 1);
      my $sess_u  = defined $form->{sessioncookie} ? $form->escape($form->{sessioncookie}, 1) : '';
      my $sd_u    = defined $form->{small_device} ? $form->escape($form->{small_device}, 1) : '';

      my $href = "menu.pl?action=display&main=company_logo&login=$login_u&path=$path_u&js=$js_u";
      $href   .= "&sessioncookie=$sess_u" if defined $form->{sessioncookie} && length $form->{sessioncookie};
      $href   .= "&small_device=$sd_u"    if defined $form->{small_device} && length $form->{small_device};

      my $href_h = h($href);
      $form->info('<p><a href="' . $href_h . '">' . $locale->text('Continue') . '</a>');

      exit;

    }

    if ($errno == 5) {
      if (-f "$slconfig{userspath}/$user->{dbname}.LCK") {
        if (-s "$slconfig{userspath}/$user->{dbname}.LCK") {
          open my $fh, '<', "$slconfig{userspath}/$user->{dbname}.LCK" or $form->error("$slconfig{userspath}/$user->{dbname}.LCK : $!");
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
        my $login_u = $form->escape($form->{login}, 1);
        my $path_u  = $form->escape($form->{path}, 1);
        my $js_u    = $form->escape($form->{js}, 1);
        my $sess_u  = defined $form->{sessioncookie} ? $form->escape($form->{sessioncookie}, 1) : '';
        my $sd_u    = defined $form->{small_device} ? $form->escape($form->{small_device}, 1) : '';

        my $href = "menu.pl?action=display&main=company_logo&login=$login_u&path=$path_u&js=$js_u";
        $href   .= "&sessioncookie=$sess_u" if defined $form->{sessioncookie} && length $form->{sessioncookie};
        $href   .= "&small_device=$sd_u"    if defined $form->{small_device} && length $form->{small_device};

        my $href_h = h($href);
        $form->info('<p><a href="' . $href_h . '">' . $locale->text('Continue') . '</a>');

        for (qw(dbname dbhost dbport dbdriver dbconnect dbuser dbpasswd)) { $form->{$_} = $user->{$_} }

        $form->info($locale->text('Upgrading to Version')." $form->{version} ... ");

        $user->dbupdate($form);

        # remove lock file
        unlink "$slconfig{userspath}/$user->{dbname}.LCK";

      }

      # Do NOT put password in query string. Hand off via POST.
      my $login_h = h($form->{login});
      my $path_h  = h($form->{path});
      my $js_h    = h($form->{js});
      my $pwd_h   = h($form->{password});

      my $post = qq|
<p>
<form method="post" action="menu.pl" autocomplete="off">
  <input type="hidden" name="login" value="$login_h">
  <input type="hidden" name="path" value="$path_h">
  <input type="hidden" name="js" value="$js_h">
  <input type="hidden" name="action" value="display">
  <input type="hidden" name="main" value="company_logo">
  <input type="hidden" name="password" value="$pwd_h">
  <input type="submit" class="button login-button" value="|.$locale->text('Continue').qq|">
</form>
|;
      $form->info($post);

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
  for my $k (qw(login path js sessioncookie small_device)) {
    my $v = $form->{$k};
    next unless defined $v;
    $form->{callback} .= "&$k=" . $form->escape($v, 1);
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

  open my $fh, '<', '/dev/urandom'
  or $form->error('Cannot open /dev/urandom');

  my $n = read $fh, my $buf, 6;
  close $fh;

  $form->error('Cannot read /dev/urandom') unless defined $n && $n == 6;

  my $tan = join '', map { ord($_) % 10 } split //, $buf;

  for ($user->{name}, $user->{email}) {s/[\r\n]//g if defined;}

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

  my $env_html = login_env_html($form, $locale);

  print qq|

<body class="login">

<div class="login-wrapper">
  <div class="login-column">
    <div class="login-brand">
      <div class="flip-card">
        <div class="flip-card-inner">
          <div class="flip-card-front">
            <img src="$slconfig{images}/sql-ledger.png" class="flip-logo" alt="SQL-Ledger">
            <h1>|.$locale->text('Open source ERP system').qq|</h1>
          </div>
          <div class="flip-card-back smallcaps">
            <h3>Credits</h3>
            <div class="ai-row">
              <div class="ai-half">
                <a href="https://github.com/Tekki/sql-ledger"><img src="$slconfig{images}/sql-ledger.png" height="100" class="image-hover" alt=""></a>
                <br><b>|.$locale->text('based').qq|</b>
              </div>
              <div class="ai-half">
                <a href="mailto:spam.spam@spam.spam" data-email-user="info" data-email-domain="domain.com"><img src="$slconfig{images}/sql-ledger.png" height="100" class="image-hover" alt=""></a>
                <br><b>|.$locale->text('operated by').qq|</b>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    $env_html
    <div class="login-form">
      <form method="post" action="$form->{script}">
        <div class="card">
          <div class="login-field floating">
            <input id="password" name="password" class="login-input" type="password" autocomplete="current-password" required placeholder=" ">
            <label for="password">|.$locale->text('One-time code (6 digits)').qq|</label>
          </div>
          <div class="login-field">
            <input type="submit" class="button login-button" name="action" value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">
          </div>
        </div>
          |;
          $form->hide_form(qw(nextsub js login path));
          print qq|
      </form>
    </div>
  </div>
</div>

<script>
document.addEventListener("DOMContentLoaded", function () {
  const form = document.forms[0];
  if (!form) return;

  document.querySelectorAll('a[data-email-user][data-email-domain]').forEach((a) => {
    const user = a.dataset.emailUser;
    const domain = a.dataset.emailDomain;
    if (user && domain) a.href = `mailto:${user}@${domain}`;
  });

  if (form.password) {
    form.password.focus();
  }
});
</script>

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
      open my $fh, '+<', "$slconfig{userspath}/$form->{login}.tan" or $form->error("$slconfig{userspath}/$form->{login}.tan : $!");

      $tries = <$fh>;
      $tries++;

      seek($fh, 0, 0);
      truncate($fh, 0);
      print {$fh} $tries;
      close $fh;

      if ($tries > 3) {
        unlink "$slconfig{userspath}/$form->{login}.bin";
        unlink "$slconfig{userspath}/$form->{login}.tan";
        $form->error($locale->text('Maximum tries exceeded!'));
      }
    } else {
      open my $fh, '>', "$slconfig{userspath}/$form->{login}.tan" or $form->error("$slconfig{userspath}/$form->{login}.tan : $!");
      print {$fh} "1";
      close $fh;
    }

    $form->error($locale->text('Invalid TAN'));
  } else {

    # remove stale locks
    $form->remove_locks(\%myconfig);

    unlink "$slconfig{userspath}/$form->{login}.tan";

    # TAN flow: menu.pl must receive the TAN code (in field 'password') to proceed.
    # Do NOT put it in the query string -> hand off via POST (auto-submit).
    my $h = sub {
      my ($s) = @_;
      $s = '' unless defined $s;
      $s =~ s/&/&amp;/g;
      $s =~ s/</&lt;/g;
      $s =~ s/>/&gt;/g;
      $s =~ s/"/&quot;/g;
      $s =~ s/'/&#39;/g;
      return $s;
    };

    # If available in the stored config, keep sessioncookie around (optional but harmless)
    $form->{sessioncookie} ||= $myconfig{sessioncookie} if defined $myconfig{sessioncookie};

    $form->{stylesheet} ||= $myconfig{stylesheet} || "blue.css";
    $form->{favicon}   ||= "favicon.ico";
    $form->header;

    my $login_h = $h->($form->{login});
    my $path_h  = $h->($form->{path});
    my $js_h    = $h->($form->{js});
    my $pwd_h   = $h->($form->{password});  # TAN code arrives as 'password'
    my $sess_h  = $h->($form->{sessioncookie});
    my $sd_h    = $h->($form->{small_device});

    print qq|
<body class="login">
  <div class="login-wrapper">
    <div class="login-column">
      <div class="login-form">
        <form id="post_tan" method="post" action="menu.pl" autocomplete="off">
          <input type="hidden" name="action" value="display">
          <input type="hidden" name="main" value="company_logo">
          <input type="hidden" name="login" value="$login_h">
          <input type="hidden" name="path" value="$path_h">
          <input type="hidden" name="js" value="$js_h">
          <input type="hidden" name="password" value="$pwd_h">
|;
    if (defined $form->{sessioncookie} && length $form->{sessioncookie}) {
      print qq|          <input type="hidden" name="sessioncookie" value="$sess_h">\n|;
    }
    if (defined $form->{small_device} && length $form->{small_device}) {
      print qq|          <input type="hidden" name="small_device" value="$sd_h">\n|;
    }

    print qq|
          <noscript>
            <div class="card">
              <div class="login-field">|.$locale->text('Continue').qq|</div>
              <div class="login-field">
                <input type="submit" class="button login-button" value="|.$locale->text('Continue').qq|">
              </div>
            </div>
          </noscript>
        </form>
      </div>
    </div>
  </div>
  <script>
    document.addEventListener("DOMContentLoaded", function () {
      var f = document.getElementById("post_tan");
      if (f) f.submit();
    });
  </script>
</body>
</html>
|;
    exit;

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
          <div class="totp-setup">
            <div class="help-text">|.$locale->text('Scan the following code with your Authenticator App:').qq|</div>
            <div class="totp-qrcode">
|. SL::QRCode::plot_svg(SL::TOTP::url($user), scale => 4) . qq|
            </div>
            <div class="totp-secret">$user->{totp_secret}</div>
          </div>|;
  }

  $form->{stylesheet} = $user->{stylesheet};
  $form->{favicon}    = 'favicon.ico';
  $form->{nextsub}    = 'totp_login';

  $form->header;

  my $env_html = login_env_html($form, $locale);

  print qq|

<body class="login">

<div class="login-wrapper">
  <div class="login-column">
    <div class="login-brand">
      <div class="flip-card">
        <div class="flip-card-inner">
          <div class="flip-card-front">
            <img src="$slconfig{images}/sql-ledger.png" class="flip-logo" alt="SQL-Ledger">
            <h1>|.$locale->text('Open source ERP system').qq|</h1>
          </div>
          <div class="flip-card-back smallcaps">
            <h3>Credits</h3>
            <div class="ai-row">
              <div class="ai-half">
                <a href="https://github.com/Tekki/sql-ledger"><img src="$slconfig{images}/sql-ledger.png" height="100" class="image-hover" alt=""></a>
                <br><b>|.$locale->text('based').qq|</b>
              </div>
              <div class="ai-half">
                <a href="mailto:spam.spam@spam.spam" data-email-user="info" data-email-domain="domain.com"><img src="$slconfig{images}/sql-ledger.png" height="100" class="image-hover" alt=""></a>
                <br><b>|.$locale->text('operated by').qq|</b>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    $env_html
    <div class="login-form">
      <form method="post" action="$form->{script}">
        <div class="card">
          <h3 class="smallcaps">$form->{login}</h3>
          $qrcode
          <div class="login-field floating">
            <input id="totp" name="totp" class="login-input" type="text" inputmode="numeric" pattern="[0-9]{6}" maxlength="6" autocomplete="one-time-code" required placeholder=" ">
            <label for="totp">|.$locale->text('Code from Authenticator').qq|</label>
          </div>
          <div class="login-field">
            <input type="submit" class="button login-button" name="action" value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">
          </div>
        </div>
          |;
          $form->hide_form(qw|nextsub js login path|);
          print qq|
      </form>
    </div>
  </div>
</div>

<script>
document.addEventListener("DOMContentLoaded", function () {
  const form = document.forms[0];
  if (!form) return;

  document.querySelectorAll('a[data-email-user][data-email-domain]').forEach((a) => {
    const user = a.dataset.emailUser;
    const domain = a.dataset.emailDomain;
    if (user && domain) a.href = `mailto:${user}@${domain}`;
  });

  if (form.totp) {
    form.totp.focus();
  }
});
</script>

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
  for my $k (qw(login path js sessioncookie small_device)) {
    my $v = $form->{$k};
    next unless defined $v;
    $form->{callback} .= "&$k=" . $form->escape($v, 1);
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
