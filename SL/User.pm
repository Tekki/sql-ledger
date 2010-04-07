#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#=====================================================================
#
# user related functions
#
#=====================================================================

package User;


sub new {
  my ($type, $memfile, $login) = @_;
  my $self = {};

  if ($login ne "") {
    &error("", "$memfile locked!") if (-f "${memfile}.LCK");
    
    open(MEMBER, "$memfile") or &error("", "$memfile : $!");
    
    while (<MEMBER>) {
      if (/^\[$login\]/) {
	while (<MEMBER>) {
	  last if /^\[/;
	  next if /^(#|\s)/;
	  
	  # remove comments
	  s/^\s*#.*//g;

	  # remove any trailing whitespace
	  s/^\s*(.*?)\s*$/$1/;

	  ($key, $value) = split /=/, $_, 2;
	  
	  $self->{$key} = $value;
	}
	
	$self->{login} = $login;

	last;
      }
    }
    close MEMBER;
  }
  
  bless $self, $type;
}


sub country_codes {

  my %cc = ();
  my @language = ();
  
  # scan the locale directory and read in the LANGUAGE files
  opendir DIR, "locale";

  my @dir = grep !/(^\.\.?$|\..*)/, readdir DIR;
  
  foreach my $dir (@dir) {
    next unless open(FH, "locale/$dir/LANGUAGE");
    @language = <FH>;
    close FH;

    $cc{$dir} = "@language";
  }

  closedir(DIR);
  
  %cc;

}


sub login {
  my ($self, $form, $userspath) = @_;

  my $rc = -1;
  
  if ($self->{login} ne "") {

    if ($self->{password} ne "") {
      my $password = crypt $form->{password}, substr($self->{login}, 0, 2);
      if ($self->{password} ne $password) {
	return -1;
      }
    }

    $self->{password} = $form->{password};
    $self->create_config("$userspath/$self->{login}.conf");
    
    $self->{password} = $form->{password};
      
    do "$userspath/$self->{login}.conf";
    $myconfig{dbpasswd} = unpack 'u', $myconfig{dbpasswd};
  
    # check if database is down
    my $dbh = DBI->connect($myconfig{dbconnect}, $myconfig{dbuser}, $myconfig{dbpasswd}) or $self->error($DBI::errstr);

    # we got a connection, check the version
    
    my %defaults;
    my $dbversion;
    my $audittrail;

    my $query = qq|SELECT * FROM defaults|;
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    if ($sth->{NAME}->[0] eq 'fldname') {
      %defaults = $form->get_defaults($dbh, \@{[qw(version audittrail)]});
      $dbversion = $defaults{version};
      $audittrail = $defaults{audittrail};
    } else {
      $query = qq|SELECT version, audittrail FROM defaults|;
      ($dbversion, $audittrail) = $dbh->selectrow_array($query);
    }
    $sth->finish;

    # add login to employee table if it does not exist
    # no error check for employee table, ignore if it does not exist
    my $login = $self->{login};
    $login =~ s/@.*//;
    $query = qq|SELECT id FROM employee WHERE login = '$login'|;
    my ($id) = $dbh->selectrow_array($query);

    if (! $id) {
      $query = qq|INSERT INTO employee (login, name, workphone,
                  role)
                  VALUES ('$login', '$myconfig{name}',
		  '$myconfig{tel}', '$myconfig{role}')|;
      $dbh->do($query);
      
      $query = qq|SELECT id FROM employee WHERE login = '$login'|;
      ($id) = $dbh->selectrow_array($query);
    }

    if ($audittrail) {
      $id *= 1;
      $query = qq|INSERT INTO audittrail (employee_id, action)
                  VALUES ($id, 'login')|;
      $dbh->do($query);
    }
    
    $dbh->disconnect;

    $rc = 0;

    
    if ($form->{dbversion} ne $dbversion) {
      $rc = -3;
      $dbupdate = (calc_version($dbversion) < calc_version($form->{dbversion}));
    }

    if ($dbupdate) {
      $rc = -4;

      # if DB2 bale out
      if ($myconfig{dbdriver} eq 'DB2') {
	$rc = -2;
      }
    }
  }

  $rc;
  
}


sub check_recurring {
  my ($self, $form) = @_;

  $self->{dbpasswd} = unpack 'u', $self->{dbpasswd};

  my $dbh = DBI->connect($self->{dbconnect}, $self->{dbuser}, $self->{dbpasswd}) or $form->dberror;

  my $query = qq|SELECT count(*) FROM recurring
                 WHERE enddate >= current_date AND nextdate <= current_date|;
  ($_) = $dbh->selectrow_array($query);
  
  $dbh->disconnect;

  $_;

}


sub dbconnect_vars {
  my ($form, $db) = @_;
  
  my %dboptions = (
     'Pg' => {
        'yy-mm-dd' => 'set DateStyle to \'ISO\'',
	'mm/dd/yy' => 'set DateStyle to \'SQL, US\'',
	'mm-dd-yy' => 'set DateStyle to \'POSTGRES, US\'',
	'dd/mm/yy' => 'set DateStyle to \'SQL, EUROPEAN\'',
	'dd-mm-yy' => 'set DateStyle to \'POSTGRES, EUROPEAN\'',
	'dd.mm.yy' => 'set DateStyle to \'GERMAN\''
	     }
     );

  if ($form->{dbdriver} eq 'Oracle') {
    $dboptions{Oracle}{$form->{dateformat}} = qq|ALTER SESSION SET NLS_DATE_FORMAT = '$form->{dateformat}'|;
  }
  if ($form->{dbdriver} eq 'Sybase') {
    $dboptions{Sybase}{$form->{dateformat}} = qq|SET DateFormat $form->{dateformat}|;
  }

  $form->{dboptions} = $dboptions{$form->{dbdriver}}{$form->{dateformat}};

  if ($form->{dbdriver} =~ /(Pg|Sybase)/) {
    $form->{dbconnect} = "dbi:$form->{dbdriver}:dbname=$db";
  }

  if ($form->{dbdriver} eq 'Oracle') {
    $form->{dbconnect} = "dbi:Oracle:sid=$form->{sid}";
  }

  if ($form->{dbhost}) {
    $form->{dbconnect} .= ";host=$form->{dbhost}";
  }
  if ($form->{dbport}) {
    $form->{dbconnect} .= ";port=$form->{dbport}";
  }
  
}


sub dbdrivers {

  my @drivers = DBI->available_drivers();

  return (grep { /(Sybase|Pg)/ } @drivers);

}


sub dbsources {
  my ($self, $form) = @_;

  my @dbsources = ();
  my ($sth, $query);
  
  $form->{dbdefault} = $form->{dbuser} unless $form->{dbdefault};
  $form->{sid} = $form->{dbdefault};
  &dbconnect_vars($form, $form->{dbdefault});

  my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;


  if ($form->{dbdriver} eq 'Pg') {

    $query = qq|SELECT datname FROM pg_database|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    while (my ($db) = $sth->fetchrow_array) {

      if ($form->{only_acc_db}) {
	
	next if ($db =~ /^template/);

	&dbconnect_vars($form, $db);
	my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;

	$query = qq|SELECT tablename FROM pg_tables
		    WHERE tablename = 'defaults'
		    AND tableowner = '$form->{dbuser}'|;
	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	if ($sth->fetchrow_array) {
	  push @dbsources, $db;
	}
	$sth->finish;
	$dbh->disconnect;
	next;
      }
      push @dbsources, $db;
    }
  }

  if ($form->{dbdriver} eq 'Oracle') {
    if ($form->{only_acc_db}) {
      $query = qq|SELECT owner FROM dba_objects
		  WHERE object_name = 'DEFAULTS'
		  AND object_type = 'TABLE'|;
    } else {
      $query = qq|SELECT username FROM dba_users|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my ($db) = $sth->fetchrow_array) {
      push @dbsources, $db;
    }
  }

  if ($form->{dbdriver} eq 'Sybase') {

    $query = qq|SELECT schemaname FROM syscat.schemata|;
    
    if ($form->{only_acc_db}) {
      $query = qq|SELECT tabschema FROM syscat.tables WHERE tabname = 'DEFAULTS'|;
    }
    
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
     
    while (my ($db) = $sth->fetchrow_array) {
      push @dbsources, $db;
    }
  }
  
# JJR
  if ($form->{dbdriver} eq 'DB2') {
    if ($form->{only_acc_db}) {
      $query = qq|SELECT tabschema FROM syscat.tables WHERE tabname = 'DEFAULTS'|;
    } else {
      $query = qq|SELECT DISTINCT schemaname FROM syscat.schemata WHERE definer != 'SYSIBM' AND schemaname != 'NULLID'|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my ($db) = $sth->fetchrow_array) {
      push @dbsources, $db;
    }
  }
# End JJR

# the above is not used but leave it in for future reference
# DS, Oct. 28, 2003

  
  $sth->finish;
  $dbh->disconnect;
  
  return @dbsources;

}


sub dbcreate {
  my ($self, $form) = @_;

  my %dbcreate = ( 'Pg' => qq|CREATE DATABASE "$form->{db}"|,
                'Sybase' => qq|CREATE DATABASE $form->{db}|,
               'Oracle' => qq|CREATE USER "$form->{db}" DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP IDENTIFIED BY "$form->{db}"|);

  $dbcreate{Pg} .= " WITH ENCODING = '$form->{encoding}'" if $form->{encoding};
  $dbcreate{Sybase} .= " CHARACTER SET $form->{encoding}" if $form->{encoding};
  
  $form->{sid} = $form->{dbdefault};
  &dbconnect_vars($form, $form->{dbdefault});
  my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;
  my $query = qq|$dbcreate{$form->{dbdriver}}|;
  $dbh->do($query);

  if ($form->{dbdriver} eq 'Oracle') {
    $query = qq|GRANT CONNECT,RESOURCE TO "$form->{db}"|;
    $dbh->do($query) || $form->dberror($query);
  }
  $dbh->disconnect;


  # setup variables for the new database
  if ($form->{dbdriver} eq 'Oracle') {
    $form->{dbuser} = $form->{db};
    $form->{dbpasswd} = $form->{db};
  }
  
  
  &dbconnect_vars($form, $form->{db});
  
  $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;
  
  # create the tables
  my $dbdriver = ($form->{dbdriver} =~ /Pg/) ? 'Pg' : $form->{dbdriver};
  
  my $filename = qq|sql/${dbdriver}-tables.sql|;
  $self->process_query($form, $dbh, $filename);
  
  # create functions
  $filename = qq|sql/${dbdriver}-functions.sql|;
  $self->process_query($form, $dbh, $filename);

  # load gifi
  ($filename) = split /_/, $form->{chart};
  $filename =~ s/_//;
  $self->process_query($form, $dbh, "sql/${filename}-gifi.sql");
 
  # load chart of accounts
  $filename = qq|sql/$form->{chart}-chart.sql|;
  $self->process_query($form, $dbh, $filename);

  # create indices
  $filename = qq|sql/${dbdriver}-indices.sql|;
  $self->process_query($form, $dbh, $filename);

  # create custom tables and functions
  my $item;
  foreach $item (qw(tables functions)) {
    $filename = "sql/${dbdriver}-custom_${item}.sql";
    if (-f "$filename") {
      $self->process_query($form, $dbh, $filename);
    }
  }
  
  $dbh->disconnect;

}



sub process_query {
  my ($self, $form, $dbh, $filename) = @_;
  
  return unless (-f $filename);
  
  open(FH, "$filename") or $form->error("$filename : $!\n");
  my $query = "";
  my $loop = 0;
  my $sth;
  

  while (<FH>) {

    if ($loop && /^--\s*end\s*(procedure|function|trigger)/i) {
      $loop = 0;

      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);
      $sth->finish;
      
      $query = "";
      next;
    }
    
    if ($loop || /^create *(or replace)? *(procedure|function|trigger)/i) {
      $loop = 1;
      next if /^(--.*|\s+)$/;

      $query .= $_;
      next;
    }
    
    # don't add comments or empty lines
    next if /^(--.*|\s+)$/;
    
    # anything else, add to query
    $query .= $_;
     
    if (/;\s*$/) {
      # strip ;... Oracle doesn't like it
      $query =~ s/;\s*$//;
      $query =~ s/\\'/''/g;

      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);
      $sth->finish;

      $query = "";
    }

  }
  close FH;
 
}



sub dbdelete {
  my ($self, $form) = @_;

  my %dbdelete = ( 'Pg' => qq|DROP DATABASE "$form->{db}"|,
                'Sybase' => qq|DROP DATABASE $form->{db}|,
               'Oracle' => qq|DROP USER $form->{db} CASCADE|
	         );

  $form->{sid} = $form->{dbdefault};
  &dbconnect_vars($form, $form->{dbdefault});
  my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;
  my $query = qq|$dbdelete{$form->{dbdriver}}|;
  $dbh->do($query) || $form->dberror($query);

  $dbh->disconnect;

}
  


sub dbsources_unused {
  my ($self, $form, $memfile) = @_;

  my @dbexcl = ();
  my @dbsources = ();
  
  $form->error("$memfile locked!") if (-f "${memfile}.LCK");
  
  # open members file
  open(FH, "$memfile") or $form->error("$memfile : $!");

  while (<FH>) {
    if (/^dbname=/) {
      my ($null,$item) = split /=/;
      push @dbexcl, $item;
    }
  }

  close FH;

  $form->{only_acc_db} = 1;
  my @db = &dbsources("", $form);

  push @dbexcl, $form->{dbdefault};

  foreach $item (@db) {
    unless (grep /$item$/, @dbexcl) {
      push @dbsources, $item;
    }
  }

  return @dbsources;

}


sub dbneedsupdate {
  my ($self, $form) = @_;

  my %dbsources = ();
  my $query;

  $form->{sid} = $form->{dbdefault};
  &dbconnect_vars($form, $form->{dbdefault});

  my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;

  my $sth;
  my $version;
  my %defaults;

  if ($form->{dbdriver} =~ /Pg/) {

    $query = qq|SELECT d.datname FROM pg_database d, pg_user u
                WHERE d.datdba = u.usesysid
		AND u.usename = '$form->{dbuser}'|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my ($db) = $sth->fetchrow_array) {
      
      next if ($db =~ /^template/);
      
      &dbconnect_vars($form, $db);
     
      my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;

      $query = qq|SELECT tablename FROM pg_tables
		  WHERE tablename = 'defaults'|;

      if ($dbh->selectrow_array($query)) {
	$query = qq|SELECT * FROM defaults|;
	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	if ($sth->{NAME}->[0] eq 'fldname') {
	  %defaults = $form->get_defaults($dbh, \@{['version']});
	  $version = $defaults{version};
	} else {
	  $query = qq|SELECT version FROM defaults|;
	  ($version) = $dbh->selectrow_array($query);
	}
	$sth->finish;

	$dbsources{$db} = $version if $version;
      }
      
      $dbh->disconnect;
    }
    $sth->finish;
  }


  if ($form->{dbdriver} eq 'Oracle') {
    $query = qq|SELECT owner FROM dba_objects
		WHERE object_name = 'DEFAULTS'
		AND object_type = 'TABLE'|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my ($db) = $sth->fetchrow_array) {
      
      $form->{dbuser} = $db;
      &dbconnect_vars($form, $db);
      
      my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;
      
      $query = qq|SELECT * FROM defaults|;
      my $sth->execute || $form->dberror($query);
      
      if ($sth->{NAME}->[0] eq 'fldname') {
	%defaults = $form->get_defaults($dbh, \@{['version']});
	$version = $defaults{version};
      } else {
	$query = qq|SELECT version FROM defaults|;
	($version) = $dbh->selectrow_array($query);
      }
      $sth->finish;

      $dbsources{$db} = $version if $version;
      
      $dbh->disconnect;
    }
    $sth->finish;
  }

  if ($form->{dbdriver} eq 'Sybase') {
    $query = qq|SELECT tabschema FROM syscat.tables WHERE tabname = 'DEFAULTS'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
 
    while (my ($db) = $sth->fetchrow_array) {
      
      &dbconnect_vars($form, $db);
     
      my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;

      $query = qq|SELECT * FROM defaults|;
      my $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);

      if ($sth->{NAME}->[0] eq 'fldname') {
	%defaults = $form->get_defaults($dbh, \@{['version']});
	$version = $defaults{version};
      } else {
	$query = qq|SELECT version FROM defaults|;
	($version) = $dbh->selectrow_array($query);
      }
      $sth->finish;

      $dbsources{$db} = $version if $version;
      
      $dbh->disconnect;
    }
    $sth->finish;
  }


# JJR
  if ($form->{dbdriver} eq 'DB2') {
    $query = qq|SELECT tabschema FROM syscat.tables WHERE tabname = 'DEFAULTS'|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my ($db) = $sth->fetchrow_array) {

      &dbconnect_vars($form, $db);

      my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;

      my %defaults = $form->get_defaults($dbh, \@{['version']});
      
      if (my $version = $defaults{version}) {
	$dbsources{$db} = $version;
      }

      $dbh->disconnect;
    }
    $sth->finish;
  }
# End JJR
  
# code for DB2 is not used, keep for future reference
# DS, Oct. 28, 2003
  
  $dbh->disconnect;
  
  %dbsources;

}


sub dbupdate {
  my ($self, $form) = @_;

  $form->{sid} = $form->{dbdefault};
  
  my @upgradescripts = ();
  my $query;
  my $rc = -2;
  
  if ($form->{dbupdate}) {
    # read update scripts into memory
    opendir SQLDIR, "sql/." or $form->error($!);
    @upgradescripts = sort script_version grep /$form->{dbdriver}-upgrade-.*?\.sql$/, readdir SQLDIR;
    closedir SQLDIR;
  }


  foreach my $db (split / /, $form->{dbupdate}) {

    next unless $form->{$db};

    # strip db from dataset
    $db =~ s/^db//;
    &dbconnect_vars($form, $db);
    
    my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}) or $form->dberror;

    # check version
    $query = qq|SELECT * FROM defaults|;
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    my %defaults;
    my $version;

    if ($sth->{NAME}->[0] eq 'fldname') {
      %defaults = $form->get_defaults($dbh, \@{['version']});
      $version = $defaults{version};
    } else {
      $query = qq|SELECT version FROM defaults|;
      ($version) = $dbh->selectrow_array($query);
    }
    $sth->finish;
    
    next unless $version;

    $version = calc_version($version);
    my $dbversion = calc_version($form->{dbversion});

    foreach my $upgradescript (@upgradescripts) {
      my $a = $upgradescript;
      $a =~ s/(^$form->{dbdriver}-upgrade-|\.sql$)//g;
      
      my ($mindb, $maxdb) = split /-/, $a;
      $mindb = calc_version($mindb);
      $maxdb = calc_version($maxdb);

      next if ($version >= $maxdb);

      # exit if there is no upgrade script or version == mindb
      last if ($version < $mindb || $version >= $dbversion);

      # apply upgrade
      $self->process_query($form, $dbh, "sql/$upgradescript");

      $version = $maxdb;
 
    }
    
    $rc = 0;
    $dbh->disconnect;
    
  }

  $rc;

}
  

sub calc_version {
  
  my @v = split /\./, $_[0];
  my $version = 0;
  my $i;
  
  for ($i = 0; $i <= $#v; $i++) {
    $version *= 1000;
    $version += $v[$i];
  }

  return $version;
  
}

  
sub script_version {
  my ($my_a, $my_b) = ($a, $b);
  
  my ($a_from, $a_to, $b_from, $b_to);
  my ($res_a, $res_b, $i);

  $my_a =~ s/.*-upgrade-//;
  $my_a =~ s/.sql$//;
  $my_b =~ s/.*-upgrade-//;
  $my_b =~ s/.sql$//;
  ($a_from, $a_to) = split(/-/, $my_a);
  ($b_from, $b_to) = split(/-/, $my_b);

  $res_a = calc_version($a_from);
  $res_b = calc_version($b_from);

  if ($res_a == $res_b) {
    $res_a = calc_version($a_to);
    $res_b = calc_version($b_to);
  }

  return $res_a <=> $res_b;
  
}


sub create_config {
  my ($self, $filename) = @_;

  @config = &config_vars;
  
  my $password = $self->{password};
  my $key = "";

  $self->{sessionkey} = "";
  $self->{sessioncookie} = "";

  if ($self->{password}) {
    my $t = time + $self->{timeout};
    srand( time() ^ ($$ + ($$ << 15)) );
    $key = "$self->{login}$self->{password}$t";

    my $i = 0;
    my $l = length $key;
    my $j = $l;
    my %ndx = ();
    my $pos;

    while ($j > 0) {
      $pos = int rand($l);
      next if $ndx{$pos};
      $ndx{$pos} = 1;
      $self->{sessioncookie} .= substr($key, $pos, 1);
      $self->{sessionkey} .= substr("0$pos", -2);
      $j--;
    }
    
    $self->{password} = crypt $self->{password}, substr($self->{login}, 0, 2) if ! $self->{encrypted};
  }

  umask(002);
  open(CONF, ">$filename") or $self->error("$filename : $!");
  
  # create the config file
  print CONF qq|# configuration file for $self->{login}

\%myconfig = (
|;

  foreach $key (sort @config) {
    $self->{$key} =~ s/\\/\\\\/g;
    $self->{$key} =~ s/'/\\'/g;
    print CONF qq|  $key => '$self->{$key}',\n|;
  }

   
  print CONF qq|);\n\n|;

  close CONF;
  
  foreach $key (sort @config) {
    $self->{$key} =~ s/\\\\/\\/g;
    $self->{$key} =~ s/\\'/'/g;
  }

  $self->{password} = $password;
  
}


sub save_member {
  my ($self, $memberfile, $userspath) = @_;

  # format dbconnect and dboptions string
  &dbconnect_vars($self, $self->{dbname});
  
  $self->error("$memberfile locked!") if (-f "${memberfile}.LCK");
  open(FH, ">${memberfile}.LCK") or $self->error("${memberfile}.LCK : $!");
  close(FH);
  
  if (! open(CONF, "+<$memberfile")) {
    unlink "${memberfile}.LCK";
    $self->error("$memberfile : $!");
  }
  
  @config = <CONF>;
  
  seek(CONF, 0, 0);
  truncate(CONF, 0);
  
  while ($line = shift @config) {
    last if ($line =~ /^\[$self->{login}\]/);
    print CONF $line;
  }

  # remove everything up to next login or EOF
  while ($line = shift @config) {
    last if ($line =~ /^\[/);
  }

  # this one is either the next login or EOF
  print CONF $line;

  while ($line = shift @config) {
    print CONF $line;
  }

  print CONF qq|[$self->{login}]\n|;
  
  if ($self->{packpw}) {
    $self->{dbpasswd} = pack 'u', $self->{dbpasswd};
    chop $self->{dbpasswd};
  }

  my $password = $self->{password};
  if (!$self->{encrypted}) {
    $self->{password} = crypt $self->{password}, substr($self->{login}, 0, 2) if $self->{password};
  }

  if ($self->{'root login'}) {
    @config = qw(password);
  } else {
    @config = &config_vars;
    @config = grep !/^session/, @config;
  }
 
  # replace \r\n with \n
  $self->{signature} =~ s/\r?\n/\\n/g;

  for (sort @config) { print CONF qq|$_=$self->{$_}\n| }

  print CONF "\n";
  close CONF;
  unlink "${memberfile}.LCK";

  # create conf file
  if (! $self->{'root login'}) {
    $self->{password} = $password;
    $self->create_config("$userspath/$self->{login}.conf");

    $self->{dbpasswd} = unpack 'u', $self->{dbpasswd};
    
    # check if login is in database
    my $dbh = DBI->connect($self->{dbconnect}, $self->{dbuser}, $self->{dbpasswd}, {AutoCommit => 0}) or $self->error($DBI::errstr);
    
    # add login to employee table if it does not exist
    my $login = $self->{login};
    $login =~ s/@.*//;
    my $query = qq|SELECT id FROM employee WHERE login = '$login'|;
    my ($id) = $dbh->selectrow_array($query);

    if ($id) {
      $query = qq|UPDATE employee SET
                  role = '$self->{role}',
		  email = '$self->{email}',
		  workphone = '$self->{tel}',
		  workfax = '$self->{fax}',
		  name = '$self->{name}'
                  WHERE login = '$login'|;

    } else {
      $query = qq|INSERT INTO employee (login, name, workphone, workfax,
                  role, email, sales)
		  VALUES ('$login', '$self->{name}',
		  '$self->{tel}', '$self->{fax}', '$self->{role}',
		  '$self->{email}', '1')|;
    }
    
    $dbh->do($query);
    $dbh->commit;
    $dbh->disconnect;

  }

}


sub delete_login {
  my ($self, $form) = @_;

  my $dbh = DBI->connect($form->{dbconnect}, $form->{dbuser}, $form->{dbpasswd}, {AutoCommit} => 0) or $form->dberror;
  
  my $login = $form->{login};
  $login =~ s/@.*//;
  my $query = qq|SELECT id FROM employee
                 WHERE login = '$login'|; 
  my ($id) = $dbh->selectrow_array($query);
	
  my $query = qq|UPDATE employee SET
		 login = NULL,
		 enddate = current_date
		 WHERE login = '$login'|;
  $dbh->do($query);
 
  $dbh->commit;
  $dbh->disconnect;

}


sub config_vars {

  my @conf = qw(acs company countrycode dateformat
             dbconnect dbdriver dbhost dbname dboptions dbpasswd
	     dbport dbuser email fax menuwidth name numberformat password
	     outputformat printer role sessionkey sid signature
	     stylesheet tel templates timeout vclimit);

  @conf;

}


sub error {
  my ($self, $msg) = @_;

  if ($ENV{HTTP_USER_AGENT}) {
    print qq|Content-Type: text/html

<body bgcolor=ffffff>

<h2><font color=red>Error!</font></h2>
<p><b>$msg</b>|;

  }
  
  die "Error: $msg\n";
  
}


1;

