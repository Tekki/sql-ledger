#!/usr/bin/perl
#
######################################################################
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#######################################################################
#
# this script is the frontend called from bin/$terminal/$script
# all the accounting modules are linked to this script which in
# turn execute the same script in bin/$terminal/
#
#######################################################################

# setup defaults, DO NOT CHANGE
$userspath = "users";
$spool = "spool";
$templates = "templates";
$images = "images";
$memberfile = "users/members";
$sendmail = "| /usr/sbin/sendmail -t";
$latex = 0;
%printer = ();
########## end ###########################################

$| = 1;

use SL::Form;

eval { require "sql-ledger.conf"; };

$form = new Form $userspath;

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

# check for user config file, could be missing or ???
eval { require("$userspath/$form->{login}.conf"); };

if ($@) {
  $locale = new Locale "$language", "$script";
  
  $form->{callback} = "";
  $msg1 = $locale->text('You are logged out!');
  $msg2 = $locale->text('Login');
  $form->redirect("$msg1 <p><a href=login.pl target=_top>$msg2</a>");
  exit;
}

# locale messages
$locale = new Locale "$myconfig{countrycode}", "$script";
$form->{charset} = $locale->{charset};

# send warnings to browser
$SIG{__WARN__} = sub { eval { $form->info($_[0]); } };

# send errors to browser
$SIG{__DIE__} = sub { eval { $form->error($_[0]); exit; } };

$myconfig{dbpasswd} = unpack 'u', $myconfig{dbpasswd};
map { $form->{$_} = $myconfig{$_} } qw(stylesheet timeout) unless ($form->{type} eq 'preferences');

$form->{path} =~ s/\.\.//g;
if ($form->{path} !~ /^bin\//) {
  $form->error($locale->text('Invalid path!')."\n");
}

# global lock out
if (-f "$userspath/nologin.LCK") {
  if (-s "$userspath/nologin.LCK") {
    open(FH, "$userspath/nologin.LCK");
    $message = <FH>;
    close(FH);
    $form->error($message);
  }
  $form->error($locale->text('System currently down for maintenance!'));
}

# dataset lock out
if (-f "$userspath/$myconfig{dbname}.LCK" && $form->{login} ne "admin\@$myconfig{dbname}") {
  if (-s "$userspath/$myconfig{dbname}.LCK") {
    open(FH, "$userspath/$myconfig{dbname}.LCK");
    $message = <FH>;
    close(FH);
    $form->error($message);
  }
  $form->error($locale->text('Dataset currently down for maintenance!'));
} 

# pull in the main code
require "$form->{path}/$form->{script}";

# customized scripts
if (-f "$form->{path}/custom_$form->{script}") {
  eval { require "$form->{path}/custom_$form->{script}"; };
}

# customized scripts for login
if (-f "$form->{path}/$form->{login}_$form->{script}") {
  eval { require "$form->{path}/$form->{login}_$form->{script}"; };
}


if ($form->{action}) {
  # window title bar, user info
  $form->{titlebar} = "SQL-Ledger ".$locale->text('Version'). " $form->{version} - $myconfig{name} - $myconfig{dbname}";

  &check_password;

  if (substr($form->{action}, 0, 1) =~ /( |\.)/) {
    &{ $form->{nextsub} };
  } else {
    &{ $locale->findsub($form->{action}) };
  }
} else {
  $form->error($locale->text('action= not defined!'));
}

1;
# end


sub check_password {

  if ($myconfig{password}) {

    require "$form->{path}/pw.pl";

    if ($form->{password}) {
      if ((crypt $form->{password}, substr($form->{login}, 0, 2)) ne $myconfig{password}) {
	if ($ENV{HTTP_USER_AGENT}) {
	  &getpassword;
	} else {
	  $form->error($locale->text('Access Denied!'));
	}
	exit;
      } else {
        # password checked out, create session
	if ($ENV{HTTP_USER_AGENT}) {
	  # create new session
	  use SL::User;
	  $user = new User $memberfile, $form->{login};
	  $user->{password} = $form->{password};
	  $user->create_config("$userspath/$form->{login}.conf");
	  $form->{sessioncookie} = $user->{sessioncookie};
	}
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

	if ($cookie{"SL-$form->{login}"}) {

	  $form->{sessioncookie} = $cookie{"SL-$form->{login}"};

	  $s = "";
	  %ndx = ();
	  $l = length $form->{sessioncookie};

	  for $i (0 .. $l - 1) {
	    $j = substr($myconfig{sessionkey}, $i * 2, 2);
	    $ndx{$j} = substr($cookie{"SL-$form->{login}"}, $i, 1);
	  }

	  for (sort keys %ndx) {
	    $s .= $ndx{$_};
	  }

	  $l = length $form->{login};
	  $login = substr($s, 0, $l);
	  $password = substr($s, $l, (length $s) - ($l + 10));

          # validate cookie
	  if (($login ne $form->{login}) || ($myconfig{password} ne crypt $password, substr($form->{login}, 0, 2))) {
	    &getpassword(1);
	    exit;
	  }

	} else {

	  if ($form->{action} ne 'display') {
	    &getpassword(1);
	    exit;
	  }

	}
      } else {
	exit;
      }
    }
  }
}


