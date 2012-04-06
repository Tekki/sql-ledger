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
# this script sets up the terminal and runs the scripts
# in bin/$terminal directory
# admin.pl is linked to this script
#
#######################################################################


# setup defaults, DO NOT CHANGE
$userspath = "users";
$spool = "spool";
$templates = "templates";
$images = "images";
$memberfile = "users/members";
$sendmail = "| /usr/sbin/sendmail -t";
%printer = ();
########## end ###########################################


$| = 1;

eval { require "sql-ledger.conf"; };


if ($ENV{CONTENT_LENGTH}) {
  read(STDIN, $_, $ENV{CONTENT_LENGTH});
}

if ($ENV{QUERY_STRING}) {
  $_ = $ENV{QUERY_STRING};
}

if ($ARGV[0]) {
  $_ = $ARGV[0];
}


%form = split /[&=]/;

# fix for apache 2.0 bug
map { $form{$_} =~ s/\\$// } keys %form;

# name of this script
$0 =~ tr/\\/\//;
$pos = rindex $0, '/';
$script = substr($0, $pos + 1);

@scripts = qw(login.pl admin.pl custom_login.pl custom_admin.pl);

if (grep !/^\Q$form{script}\E/, @scripts) {
  print "Content-Type: text/html\n\n" if $ENV{HTTP_USER_AGENT};
  print "\nAccess denied!\n";
  exit;
}

if (-f "$userspath/nologin.LCK" && $script ne 'admin.pl') {
  print "Content-Type: text/html\n\n" if $ENV{HTTP_USER_AGENT};
  if (-s "$userspath/nologin.LCK") {
    open(FH, "$userspath/nologin.LCK");
    $message = <FH>;
    close(FH);
    print "\n$message\n";
  } else {
    print "\nLogin disabled!\n";
  }
  exit;
}


if ($form{path}) {
  $form{path} =~ s/%2f/\//gi;
  $form{path} =~ s/\.\.//g;

  if ($form{path} !~ /^bin\//) {
    print "Content-Type: text/html\n\n" if $ENV{HTTP_USER_AGENT};
    print "\nInvalid path!\n";
    exit;
  }


  $ARGV[0] = "$_&script=$script";
  require "$form{path}/$script";
} else {

  if (!$form{terminal}) {
    if ($ENV{HTTP_USER_AGENT}) {
      # web browser
      $form{terminal} = "lynx";
      if ($ENV{HTTP_USER_AGENT} !~ /lynx/i) {
	$form{terminal} = "mozilla";
      }
    } else {
      if ($ENV{TERM} =~ /xterm/) {
	$form{terminal} = "xterm";
      }
      if ($ENV{TERM} =~ /(console|linux|vt.*)/i) {
	$form{terminal} = "console";
      }
    }
  }


  if ($form{terminal}) {
    $form{terminal} =~ s/%2f/\//gi;
    $form{terminal} =~ s/\.\.//g;

    $ARGV[0] = "path=bin/$form{terminal}&script=$script";
    map { $ARGV[0] .= "&${_}=$form{$_}" } keys %form;

    require "bin/$form{terminal}/$script";
    
  } else {

    print "Content-Type: text/html\n\n" if $ENV{HTTP_USER_AGENT};
    print qq|\nUnknown terminal\n|;
  }

}

1;
# end of main

