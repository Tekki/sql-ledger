#!/usr/bin/perl
#
#######################################################################
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2025 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#######################################################################
#
# this script is the frontend called from bin/$terminal/$script
# all the accounting modules are linked to this script which in
# turn execute the same script in bin/$terminal/
#
#######################################################################

BEGIN {
  push @INC, '.';
}

use open ':std', OUT => ':encoding(UTF-8)';
use Storable ();
use SL::Form;
use SL::Locale;

$| = 1;

our (%slconfig, %myconfig, $form, $locale);

eval {
  %slconfig = Storable::retrieve('config/sql-ledger.bin')->%*;
};

if ($@) {
  %slconfig = (
    userspath     => 'users',
    spool         => 'spool',
    templates     => 'templates',
    images        => 'images',
    memberfile    => 'users/members',
    sendmail      => '| /usr/sbin/sendmail -f <%from%> -t',
    accessfolders => ['templates', 'css'],
  );
}

$form = SL::Form->new($slconfig{userspath});

# name of this script
$0 =~ tr/\\/\//;
$pos = rindex $0, '/';
$script = substr($0, $pos + 1);

# we use $script for the language module
$form->{script} = $script;
# strip .pl for translation files
$script =~ s/\.pl//;

# pull in DBI
use DBI qw(:sql_types);

$form->{login} =~ s/(\.\.|\/|\\|\x00)//g;

eval { %myconfig = Storable::retrieve("$slconfig{userspath}/$form->{login}.bin")->%*; };

if ($@) {
  $form->json_error('Access Denied!');
}

$myconfig{dateformat}   = 'yyyy-mm-dd';
$myconfig{dboptions}    = '';
$myconfig{numberformat} = '1000.00';
$myconfig{countrycode}  = '';

# locale messages
$locale = SL::Locale->new("$myconfig{countrycode}", "$script");

# $form->{charset} = $myconfig{charset};

# send warnings to browser
$SIG{__WARN__} = sub { eval { $form->info($_[0], 'warn'); } };

# send errors to browser
$SIG{__DIE__} = sub { eval { $form->json_error($_[0]); } };

$myconfig{dbpasswd} = unpack 'u', $myconfig{dbpasswd} if $myconfig{dbpasswd};
map { $form->{$_} = $myconfig{$_} } qw(stylesheet timeout) unless ($form->{type} eq 'preferences');

$form->{path} =~ s/\.\.//g;
if ($form->{path} !~ /^bin\//) {
  $form->json_error($locale->text('Invalid path!')."\n");
}

# global lock out
if (-f "$slconfig{userspath}/nologin.LCK") {
  if (-s "$slconfig{userspath}/nologin.LCK") {
    open my $fh, "$slconfig{userspath}/nologin.LCK";
    $message = <$fh>;
    close $fh;
    $form->json_error($message);
  }
  $form->json_error($locale->text('System currently down for maintenance!'));
}

# dataset lock out
if (-f "$slconfig{userspath}/$myconfig{dbname}.LCK" && $form->{login} ne "admin\@$myconfig{dbname}") {
  if (-s "$slconfig{userspath}/$myconfig{dbname}.LCK") {
    open my $fh, "$slconfig{userspath}/$myconfig{dbname}.LCK";
    $message = <$fh>;
    close $fh;
    $form->json_error($message);
  }
  $form->json_error($locale->text('Dataset currently down for maintenance!'));
}

# pull in the main code
require "$form->{path}/$form->{script}";

# customized scripts
if (-f "$form->{path}/custom/$form->{script}") {
  eval { require "$form->{path}/custom/$form->{script}"; };
}

# customized scripts for login
if (-f "$form->{path}/custom/$form->{login}/$form->{script}") {
  eval { require "$form->{path}/custom/$form->{login}/$form->{script}"; };
}


if ($form->{action}) {
  # window title bar, user info
  $form->{titlebar} = "SQL-Ledger - $myconfig{name} - $myconfig{dbname}";

  &check_password;

  if (substr($form->{action}, 0, 1) =~ /( |\.)/) {
    &{ $form->{nextsub} };
  } else {
    &{ $locale->findsub($form->{action}) };
  }
} else {
  $form->json_error($locale->text('action= not defined!'));
}

1;
# end


sub check_password {

  if ($myconfig{password}) {

    if ($form->{password}) {

      my $err;
      if ($myconfig{totp_activated} || $form->{admin} && $admin_totp_activated) {
        require SL::TOTP;
        $form->{password} = crypt $form->{password}, substr($form->{login}, 0, 2);
        $err = !(
          SL::TOTP::check_code(\%myconfig, $form->{totp})
          && crypt($form->{password}, substr($form->{login}, 0, 2)) eq $myconfig{password}
        );
      } else {
        $err = crypt($form->{password}, substr($form->{login}, 0, 2)) ne $myconfig{password};
      }

      if ($err) {
        $form->json_error($locale->text("Access Denied!"));
      } else {
        # password checked out, create session
        if ($ENV{HTTP_USER_AGENT}) {
          # create new session
          use SL::User;
          $user = SL::User->new($slconfig{memberfile}, $form->{login});
          $user->{password} = $form->{password};
          $user->create_config("$slconfig{userspath}/$form->{login}.bin");
          $form->{sessioncookie} = $user->{sessioncookie};
          $myconfig{sessionkey} = $user->{sessionkey};
        }
      }
    } elsif ($ENV{HTTP_SL_TOKEN} && $myconfig{sessionkey}) {
      require Digest::SHA;

      if ($ENV{HTTP_SL_TOKEN} ne Digest::SHA::sha256_base64($myconfig{sessionkey})) {
        $form->json_error($locale->text('Access Denied!'));
      }
    } else {

      if ($ENV{HTTP_USER_AGENT}) {
        $ENV{HTTP_COOKIE} =~ s/;\s*/;/g;
        @cookies = split /;/, $ENV{HTTP_COOKIE};
        %cookie = ();
        foreach (@cookies) {
          ($name,$value) = split /=/, $_, 2;
          $cookie{$name} = $value;
        }

        $login = $form->{login};
        $login =~ s/(\@| )/_/g;

        if ($cookie{"SL-$login"}) {

          $form->{sessioncookie} = $cookie{"SL-$login"};

          $s = "";
          %ndx = ();
          $l = length $form->{sessioncookie};

          for $i (0 .. $l - 1) {
            $j = substr($myconfig{sessionkey}, $i * 2, 2);
            $ndx{$j} = substr($cookie{"SL-$login"}, $i, 1);
          }

          for (sort keys %ndx) {
            $s .= $ndx{$_};
          }

          $l = length $form->{login};
          $login = substr($s, 0, $l);
          $password = substr($s, $l, (length $s) - ($l + 10));

          $flogin = $form->{login};
          $flogin =~ s/(\@| )/_/g;

          # validate cookie
          if (($login ne $flogin) || ($myconfig{password} ne crypt $password, substr($form->{login}, 0, 2))) {
            $form->json_error($locale->text('Access Denied!'));
          }

        } else {

          if ($form->{action} ne 'display') {
            $form->json_error($locale->text('Access Denied!'));
          }

        }
      } else {
        exit;
      }
    }
  }
}
