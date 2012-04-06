#!/usr/bin/perl
#
######################################################################
# SQL-Ledger ERP Installer
# Copyright (c) 2007, DWS Systems Inc.
#
#     Web: http://www.sql-ledger.com
#
#######################################################################

$| = 1;

if ($ENV{HTTP_USER_AGENT}) {
  print "
This does not work yet!
use $0 from the command line";
  exit;
}

$lynx = `lynx -version`;      # if LWP is not installed use lynx
$wget = `wget --version 2>&1`;
$gzip = `gzip -V 2>&1`;            # gz decompression utility
$tar = `tar --version 2>&1`;       # tar archiver
$latex = `latex -version`;

%checkversion = ( www => 1, abacus => 2 );

%source = (
	    1 => { url => "http://www.sql-ledger.com/source", site => "www.sql-ledger.com", locale => us },
            2 => { url => "http://abacus.sql-ledger.com/source", site => "abacus.sql-ledger.com", locale => ca },
	  );

$userspath = "users";         # default for new installation

eval { require "sql-ledger.conf"; };

$filename = shift;
chomp $filename;

$newinstall = 1;

# is LWP installed
eval { require LWP::Simple; };
$lwp = !($@);

unless ($lwp || $wget || $lynx || $filename) {
  die "You must have either lynx, wget or LWP installed or specify a filename.
perl $0 <filename>\n";
}

if ($filename) {
  # extract version
  die "Not a SQL-Ledger archive\n" if ($filename !~ /^sql-ledger/);
  
  $version = $filename;
  $version =~ s/sql-ledger-(\d+\.\d+\.\d+).*$/$1/;

}
  
if (-f "VERSION") {
  # get installed version from VERSION file
  open(FH, "VERSION");
  @a = <FH>;
  close(FH);
  $version = $a[0];
  chomp $version;

  $newinstall = !$version;

  if (! -f "sql-ledger.conf") {
    $newinstall = 1;
  }
}

$webowner = "nobody";
$webgroup = "nogroup";

if ($httpd = `find /etc /usr/local/etc -type f -name 'httpd*.conf'`) {
  chomp $httpd;
  $webowner = `grep "^User " $httpd`;
  $webgroup = `grep "^Group " $httpd`;

  chomp $webowner;
  chomp $webgroup;
  
  ($null, $webowner) = split / /, $webowner;
  ($null, $webgroup) = split / /, $webgroup;

}

if ($confd = `find /etc /usr/local/etc -type d -name 'apache*/conf.d'`) {
  chomp $confd;
}

system("tput clear");

if ($filename) {
  $install = "\ninstall $version from (f)ile\n";
}

# check for latest version
&get_latest_version;
chomp $latest_version;

if (!$newinstall) {

  $install .= "\n(r)einstall $version\n";
  
}


if ($version && $latest_version) {
  if (calcversion($version) < calcversion($latest_version)) {
    $install .= "\n(u)pgrade to $latest_version\n";
  }
}


$install .= "\n(i)nstall $latest_version (from Internet)\n" if $latest_version;

$install .= "\n(d)ownload $latest_version (no installation)" unless $filename;

  print qq|


               SQL-Ledger ERP Installation



$install


Enter: |;

$a = <STDIN>;
chomp $a;

exit unless $a;
$a = lc $a;

if ($a !~ /d/) {

  print qq|\nEnter httpd owner [$webowner] : |;
  $web = <STDIN>;
  chomp $web;
  $webowner = $web if $web;

  print qq|\nEnter httpd group [$webgroup] : |;
  $web = <STDIN>;
  chomp $web;
  $webgroup = $web if $web;
  
}


if ($a eq 'd') {
  &download;
}
if ($a =~ /(i|u)/) {
  &install;
}
if ($a eq 'r') {
  $latest_version = $version;
  &install;
}
if ($a eq 'f') {
  &install;
}

exit;
# end main


sub calcversion {
  my $v = shift;

  @v = split /\./, $v;

  for (0 .. 2) {
    $v[$_] = 1000 + $v[$_];
  }

  return join '', @v;

}


sub download {

  &get_source_code;

}


sub get_latest_version {
  
  print "Checking for latest version number ....\n";

  if ($filename) {
    print "skipping, filename supplied\n";
    return;
  }

  if ($lwp) {
    $found = 0;
    foreach $source (qw(www abacus)) {
      $url = $source{$checkversion{$source}}{url};
      print "$source{$checkversion{$source}}{site} ... ";

      $latest_version = LWP::Simple::get("$url/latest_version");
      
      if ($latest_version) {
	$found = 1;
	last;
      } else {
	print "not found\n";
      }
    }
    
    if (! $found) {
      $lwp = 0;
      &get_latest_version;
    }
    
  } elsif ($wget) {
    $found = 0;
    foreach $source (qw(www abacus)) {
      $url = $source{$checkversion{$source}}{url};
      print "$source{$checkversion{$source}}{site} ... ";
      if ($latest_version = `wget -q -O - $url/latest_version`) {
	$found = 1;
	last;
      } else {
	print "not found\n";
      }
    }
    
    if (! $found) {
      $wget = 0;
      &get_latest_version;
    }
    
  } else {
    if (!$lynx) {
      print "\nYou must have either wget, lynx or LWP installed";
      exit 1;
    }

    foreach $source (qw(www abacus)) {
      $url = $source{$checkversion{$source}}{url};
      print "$source{$checkversion{$source}}{site} ... ";
      $ok = `lynx -dump -head $url/latest_version`;
      if ($ok = ($ok =~ s/HTTP.*?200 //)) {
	$latest_version = `lynx -dump $url/latest_version`;
	last;
      } else {
	print "not found\n";
      }
    }
    die unless $ok;
  }

  if ($latest_version) {
    print "ok\n";
  }

}


sub get_source_code {

  $err = 0;

  @order = ();
  
  for (sort { $a <=> $b } keys %source) {
    push @order, $_;
  }

  if ($latest_version) {
    # download it
    chomp $latest_version;
    $latest_version = "sql-ledger-${latest_version}.tar.gz";

    print "\nStatus\n";
    print "Downloading $latest_version .... ";

    foreach $key (@order) {
      print "\n$source{$key}{site} .... ";

      if ($lwp) {
	$err = LWP::Simple::getstore("$source{$key}{url}/$latest_version", "$latest_version");
	$err -= 200;
      } elsif ($wget) {
	$ok = `wget -Sqc $source{$key}{url}/$latest_version`;
	if ($ok =~ /HTTP.*?(20|416)/) {
	  $err = 0;
	}
      } else {
	$ok = `lynx -dump -head $source{$key}{url}/$latest_version`;
	$err = !($ok =~ s/HTTP.*?200 //);

	if (!$err) {
	  $err = system("lynx -dump $source{$key}{url}/$latest_version > $latest_version");
	}
      }

      if ($err) {
	print "failed!";
      } else {
	last;
      }

    }
    
  } else {
    $err = -1;
  }
  
  if ($err) {
    die "Cannot get $latest_version";
  } else {
    print "ok\n";
  }

  $latest_version;

}


sub install {

  if ($filename) {
    $latest_version = $filename;
  } else {
    $latest_version = &get_source_code;
  }

  &decompress;

  if ($newinstall) {
    open(FH, "sql-ledger.conf.default");
    @f = <FH>;
    close(FH);
    unless ($latex) {
      grep { s/^\$latex.*/\$latex = 0;/ } @f;
    }
    open(FH, ">sql-ledger.conf");
    print FH @f;
    close(FH);

    $alias = $absolutealias = $ENV{'PWD'};
    $alias =~ s/.*\///g;
    
    $httpddir = `dirname $httpd`;
    if ($confd) {
      $httpddir = $confd;
    }
    chomp $httpddir;
    $filename = "sql-ledger-httpd.conf";

    # do we have write permission?
    if (!open(FH, ">>$httpddir/$filename")) {
      open(FH, ">$filename");
      $norw = 1;
    }

    $directives = qq|
Alias /$alias $absolutealias/
<Directory $absolutealias>
  AllowOverride All
  AddHandler cgi-script .pl
  Options ExecCGI Includes FollowSymlinks
  Order Allow,Deny
  Allow from All
</Directory>

<Directory $absolutealias/users>
  Order Deny,Allow
  Deny from All
</Directory>
  
|;

    print FH $directives;
    close(FH);
    
    print qq|
This is a new installation.

|;

    if ($norw) {
      print qq|
Webserver directives were written to $filename
      
Copy $filename to $httpddir
|;

      if (!$confd) {
	print qq| and add
# SQL-Ledger
Include $httpddir/$filename

to $httpd
|;
      }

      print qq| and restart your webserver!\n|;

      if (!$permset) {
	print qq|
WARNING: permissions for templates, users, css and spool directory
could not be set. Login as root and set permissions

# chown -hR :$webgroup users templates css spool
# chmod 771 users templates css spool

|;
      }

    } else {
      
       print qq|
Webserver directives were written to

  $httpddir/$filename
|;
     
      if (!$confd) {
	if (!(`grep "^# SQL-Ledger" $httpd`)) {

	  print qq|Please add

# SQL-Ledger
Include $httpddir/$filename

to your httpd configuration file and restart the web server.
|;
	  
	}
      }
    }
  }
  
  # if this is not root, check if user is part of $webgroup
  if ($>) {
    if ($permset = ($) =~ getgrnam $webgroup)) {
      `chown -hR :$webgroup users templates css spool`;
      chmod 0771, 'users', 'templates', 'css', 'spool';
      `chown :$webgroup sql-ledger.conf`;
    }
  } else {
    # root
    `chown -hR 0:0 *`;
    `chown -hR $webowner:$webgroup users templates css spool`;
    chmod 0771, 'users', 'templates', 'css', 'spool';
    `chown $webowner:$webgroup sql-ledger.conf`;
  }
  
  chmod 0644, 'sql-ledger.conf';
  unlink "sql-ledger.conf.default";

  &cleanup;

  while ($a !~ /(Y|N)/) {
    print qq|\nDisplay README (Y/n) : |;
    $a = <STDIN>;
    chomp $a;
    $a = ($a) ? uc $a : 'Y';
    
    if ($a eq 'Y') {
      @args = ("more", "doc/README");
      system(@args);
    }
  }
  
}


sub decompress {
  
  die "Error: gzip not installed\n" unless ($gzip);
  die "Error: tar not installed\n" unless ($tar);
  
  &create_lockfile;

  # ungzip and extract source code
  print "Decompressing $latest_version ... ";
    
  if (system("gzip -df $latest_version")) {
    print "Error: Could not decompress $latest_version\n";
    &remove_lockfile;
    exit;
  } else {
    print "done\n";
  }

  # strip gz from latest_version
  $latest_version =~ s/\.gz//;
  
  # now untar it
  print "Unpacking $latest_version ... ";
  if (system("tar -xf $latest_version")) {
    print "Error: Could not unpack $latest_version\n";
    &remove_lockfile;
    exit;
  } else {
    # now we have a copy in sql-ledger
    if (system("tar -cf $latest_version -C sql-ledger .")) {
      print "Error: Could not create archive for $latest_version\n";
      &remove_lockfile;
      exit;
    } else {
      if (system("tar -xf $latest_version")) {
        print "Error: Could not unpack $latest_version\n";
	&remove_lockfile;
	exit;
      } else {
        print "done\n";
        print "cleaning up ... ";
        `rm -rf sql-ledger`;
        print "done\n";
      }
    }
  }
}


sub create_lockfile {

  if (-d "$userspath") {
    open(FH, ">$userspath/nologin.LCK");
    close(FH);
  }
  
}


sub cleanup {

  unlink "$latest_version";
  unlink "$userspath/members.default" if (-f "$userspath/members.default");

  &remove_lockfile;
  
}


sub remove_lockfile { unlink "$userspath/nologin.LCK" if (-f "$userspath/nologin.LCK") };


