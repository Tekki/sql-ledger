#=================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================

package Form;


sub new {
  my $type = shift;
  
  my $self = {};

  read(STDIN, $_, $ENV{CONTENT_LENGTH});

  if ($ENV{QUERY_STRING}) {
    $_ = $ENV{QUERY_STRING};
  }

  if ($ARGV[0]) {
    $_ = $ARGV[0];
  }

  %$self = split /[&=]/;

  my $esc = 1;
  
  # if multipart form take apart on boundary
  my ($content, $boundary) = split /; /, $ENV{CONTENT_TYPE};

  if ($boundary) {
    $esc = 0;
    %$self = ();
    
    ($content, $boundary) = split /=/, $boundary;
    my $var;

    @a = split /\r/, $_;

    foreach $line (@a) {
      $line =~ s/^\n//;

      last if $line =~ /${boundary}--/;
      next if $line =~ /${boundary}/;

      if ($line =~ /^Content-Disposition: form-data;/) {
	my @b = split /; /, $line;
	my @c = split /=/, $b[1];
	$c[1] =~ s/(^"|"$)//g;
	$var = $c[1];
	$line = shift @a;
        shift @a if $line =~ /^Content-Type:/;
	
	$self->{$var} = "" if $var;
	next;
      }
      
      if ($self->{$var}) {
	$self->{$var} .= "\n$line";
      } else {
	$self->{$var} = $line;
      }
    }
  }

  if ($esc) {
    for (keys %$self) { $self->{$_} = unescape("", $self->{$_}) }
  }
 
  if (substr($self->{action}, 0, 1) !~ /( |\.)/) {
    $self->{action} = lc $self->{action};
    $self->{action} =~ s/( |-|,|\#|\/|\.$)/_/g;
  }

  $self->{menubar} = 1 if $self->{path} =~ /lynx/i;

  $self->{version} = "2.8.28";
  $self->{dbversion} = "2.8.10";

  bless $self, $type;
  
}


sub debug {
  my ($self, $file) = @_;
  
  if ($file) {
    open(FH, "> $file") or die $!;
    for (sort keys %$self) { print FH "$_ = $self->{$_}\n" }
    close(FH);
  } else {
    print "\n";
    for (sort keys %$self) { print "$_ = $self->{$_}\n" }
  }
  
} 

  
sub escape {
  my ($self, $str, $beenthere) = @_;

  # for Apache 2 we escape strings twice
  if (($ENV{SERVER_SIGNATURE} =~ /Apache\/2\.(\d+)\.(\d+)/) && !$beenthere) {
    $str = $self->escape($str, 1) if $1 == 0 && $2 < 44;
  }

  $str =~ s/([^a-zA-Z0-9_.-])/sprintf("%%%02x", ord($1))/ge;
  $str;

}


sub unescape {
  my ($self, $str) = @_;
  
  $str =~ tr/+/ /;
  $str =~ s/\\$//;

  $str =~ s/%([0-9a-fA-Z]{2})/pack("c",hex($1))/eg;
  $str =~ s/\r?\n/\n/g;

  $str;

}


sub quote {
  my ($self, $str) = @_;

  if ($str && ! ref($str)) {
    $str =~ s/"/&quot;/g;
    $str =~ s/\+/\&#43;/g;
  }

  $str;

}


sub unquote {
  my ($self, $str) = @_;

  if ($str && ! ref($str)) {
    $str =~ s/&quot;/"/g;
  }

  $str;

}


sub select_option {
  my ($self, $list, $selected, $removeid, $rev) = @_;

  my $str;
  my @a = split /\r?\n/, $self->unescape($list);
  my $var;
  
  for (@a) {
    $var = $_ = $self->quote($_);
    if (defined $rev) {
      $_ =~ s/--.*//g;
      $var =~ s/.*--//g;
    }
    if (defined $removeid) {
      $var =~ s/--.*//g;
    }
    
    $str .= qq|<option|;
    $str .= qq| value="$_"| if ($removeid || $rev);
    $str .= qq| selected| if $_ ne "" && $_ eq $self->quote($selected);
    $str .= qq|>$var\n|;
  }

  $str;
  
}


sub hide_form {
  my $self = shift;

  my $str;

  if (@_) {
    for (@_) { $str .= qq|<input type="hidden" name="$_" value="|.$self->quote($self->{$_}).qq|">\n| }
    print qq|$str| if $self->{header};
  } else {
    delete $self->{header};
    for (sort keys %$self) {
      print qq|<input type="hidden" name="$_" value="|.$self->quote($self->{$_}).qq|">\n|;
    }
  }

  $str;
  
}


sub error {
  my ($self, $msg) = @_;

  if ($ENV{HTTP_USER_AGENT}) {
    $self->{msg} = $msg;
    $self->{format} = "html";
    $self->format_string(msg);

    delete $self->{pre};

    if (!$self->{header}) {
      $self->header(0,1);
    }

    print qq|<body><h2 class=error>Error!</h2>
    
    <p><b>$self->{msg}</b>|;

    exit;

  }
  
  die "Error: $msg\n";
  
}


sub info {
  my ($self, $msg) = @_;

  if ($ENV{HTTP_USER_AGENT}) {
    $msg =~ s/\n/<br>/g;

    delete $self->{pre};

    if (!$self->{header}) {
      $self->header(0,1);
      print qq|
      <body>|;
    }

    print "<b>$msg</b>";

  } else {
  
    print "$msg\n";
    
  }
  
}


sub numtextrows {
  my ($self, $str, $cols, $maxrows) = @_;

  my $rows = 0;

  for (split /\n/, $str) { $rows += int (((length) - 2)/$cols) + 1 }
  $maxrows = $rows unless defined $maxrows;

  return ($rows > $maxrows) ? $maxrows : $rows;

}


sub dberror {
  my ($self, $msg) = @_;

  $self->error("$msg\n".$DBI::errstr);
  
}


sub isblank {
  my ($self, $name, $msg) = @_;

  $self->error($msg) if $self->{$name} =~ /^\s*$/;

}
  

sub header {
  my ($self, $endsession, $nocookie) = @_;

  return if $self->{header};

  my ($stylesheet, $favicon, $charset);

  if ($ENV{HTTP_USER_AGENT}) {

    if ($self->{stylesheet} && (-f "css/$self->{stylesheet}")) {
      $stylesheet = qq|<LINK REL="stylesheet" HREF="css/$self->{stylesheet}" TYPE="text/css" TITLE="SQL-Ledger stylesheet">
  |;
    }

    if ($self->{favicon} && (-f "$self->{favicon}")) {
      $favicon = qq|<LINK REL="icon" HREF="$self->{favicon}" TYPE="image/x-icon">
<LINK REL="shortcut icon" HREF="$self->{favicon}" TYPE="image/x-icon">
  |;
    }

    if ($self->{charset}) {
      $charset = qq|<META HTTP-EQUIV="Content-Type" CONTENT="text/plain; charset=$self->{charset}">
  |;
    }

    $self->{titlebar} = ($self->{title}) ? "$self->{title} - $self->{titlebar}" : $self->{titlebar};

    $self->set_cookie($endsession) unless $nocookie;

    print qq|Content-Type: text/html

<head>
  <title>$self->{titlebar}</title>
  <META NAME="robots" CONTENT="noindex,nofollow" />
  $favicon
  $stylesheet
  $charset
</head>

$self->{pre}
|;
  }

  $self->{header} = 1;
  delete $self->{sessioncookie};
  
}


sub set_cookie {
  my ($self, $endsession) = @_;

  $self->{timeout} ||= 31557600;
  my $t = ($endsession) ? time : time + $self->{timeout};
  my $login = ($self->{"root login"}) ? "root login" : $self->{login};

  if ($ENV{HTTP_USER_AGENT}) {
    my @d = split / +/, scalar gmtime($t);

    my $today = "$d[0], $d[2]-$d[1]-$d[4] $d[3] GMT";

    if ($login) {
      if ($self->{sessioncookie}) {
	print qq|Set-Cookie: SL-${login}=$self->{sessioncookie}; expires=$today; path=/;\n|;
      } else {
	print qq|Set-Cookie: SL-${login}=; expires=$today; path=/;\n|;
      }
    }
  }

}


sub redirect {
  my ($self, $msg) = @_;

  if ($self->{callback}) {

    my ($script, $argv) = split(/\?/, $self->{callback});
    exec ("perl", $script, $argv);
   
  } else {
    
    $self->info($msg);

  }

}


sub sort_columns {
  my ($self, @columns) = @_;

  if ($self->{sort}) {
    $self->{sort} =~ s/;//g;
    if (@columns) {
      @columns = grep !/^$self->{sort}$/, @columns;
      splice @columns, 0, 0, $self->{sort};
    }
  }

  @columns;
  
}


sub sort_order {
  my ($self, $columns, $ordinal) = @_;

  # setup direction
  if ($self->{direction}) {
    if ($self->{sort} eq $self->{oldsort}) {
      if ($self->{direction} eq 'ASC') {
	$self->{direction} = "DESC";
      } else {
	$self->{direction} = "ASC";
      }
    }
  } else {
    $self->{direction} = "ASC";
  }
  $self->{oldsort} = $self->{sort};

  my @a = $self->sort_columns(@{$columns});
  if (%$ordinal) {
    $a[0] = ($ordinal->{$a[$_]}) ? "$ordinal->{$a[0]} $self->{direction}" : "$a[0] $self->{direction}";
    for (1 .. $#a) { $a[$_] = $ordinal->{$a[$_]} if $ordinal->{$a[$_]} }
  } else {
    $a[0] .= " $self->{direction}";
  }

  $sortorder = join ',', @a;

  $sortorder;

}


sub format_amount {
  my ($self, $myconfig, $amount, $places, $dash) = @_;

  if ($places =~ /\d+/) {
    $amount = $self->round_amount($amount, $places);
  }

  # is the amount negative
  my $negative = ($amount < 0);
  
  if ($amount) {
    if ($myconfig->{numberformat}) {
      my ($whole, $dec) = split /\./, "$amount";
      $whole =~ s/-//;
      $amount = join '', reverse split //, $whole;
      if ($places) {
	$dec .= "0" x $places;
	$dec = substr($dec, 0, $places);
      }
      
      if ($myconfig->{numberformat} eq '1,000.00') {
	$amount =~ s/\d{3,}?/$&,/g;
	$amount =~ s/,$//;
	$amount = join '', reverse split //, $amount;
	$amount .= "\.$dec" if ($dec ne "");
      }

      if ($myconfig->{numberformat} eq "1'000.00") {
	$amount =~ s/\d{3,}?/$&'/g;
	$amount =~ s/'$//;
	$amount = join '', reverse split //, $amount;
	$amount .= "\.$dec" if ($dec ne "");
      }
      
      if ($myconfig->{numberformat} eq '1.000,00') {
	$amount =~ s/\d{3,}?/$&./g;
	$amount =~ s/\.$//;
	$amount = join '', reverse split //, $amount;
	$amount .= ",$dec" if ($dec ne "");
      }
      
      if ($myconfig->{numberformat} eq '1000,00') {
	$amount = "$whole";
	$amount .= ",$dec" if ($dec ne "");
      }
      
      if ($myconfig->{numberformat} eq '1000.00') {
	$amount = "$whole";
	$amount .= ".$dec" if ($dec ne "");
      }

      if ($dash =~ /-/) {
	$amount = ($negative) ? "($amount)" : "$amount";
      } elsif ($dash =~ /DRCR/) {
	$amount = ($negative) ? "$amount DR" : "$amount CR";
      } else {
	$amount = ($negative) ? "-$amount" : "$amount";
      }
    }
  } else {
    if ($dash eq "0" && $places) {
      if ($myconfig->{numberformat} eq '1.000,00') {
	$amount = "0".","."0" x $places;
      } else {
	$amount = "0"."."."0" x $places;
      }
    } else {
      $amount = ($dash ne "") ? "$dash" : "";
    }
  }

  $amount;

}


sub parse_amount {
  my ($self, $myconfig, $amount) = @_;

  if (($myconfig->{numberformat} eq '1.000,00') ||
      ($myconfig->{numberformat} eq '1000,00')) {
    $amount =~ s/\.//g;
    $amount =~ s/,/\./;
  }

  if ($myconfig->{numberformat} eq "1'000.00") {
    $amount =~ s/'//g;
  }

  $amount =~ s/,//g;
  
  return ($amount * 1);

}


sub round_amount {
  my ($self, $amount, $places) = @_;

  my ($null, $dec) = split /\./, $amount;
  $dec = length $dec;
  $dec = ($dec > $places) ? $dec : $places;
  my $adj = ($amount < 0) ? (1/10**($dec+2)) * -1 : (1/10**($dec+2));

  if (($places * 1) >= 0) {
    $amount = sprintf("%.${places}f", $amount + $adj) * 1;
  } else {
    $places *= -1;
    $amount = sprintf("%.0f", $amount);
    $amount = sprintf("%.f", $amount / (10 ** $places)) * (10 ** $places);
  }

  $amount;

}


sub parse_template {
  my ($self, $myconfig, $userspath) = @_;
  
  my ($chars_per_line, $lines_on_first_page, $lines_on_second_page) = (0, 0, 0);
  my ($current_page, $current_line) = (1, 1);
  my $pagebreak = "";
  my $sum;

  my $subdir = "";
  my $err = "";

  my %include = ();
  my $ok;

  if (-f "$self->{templates}/$self->{language_code}/$self->{IN}") {
    open(IN, "$self->{templates}/$self->{language_code}/$self->{IN}") or $self->error("$self->{templates}/$self->{language_code}/$self->{IN} : $!");
  } else {
    open(IN, "$self->{templates}/$self->{IN}") or $self->error("$self->{templates}/$self->{IN} : $!");
  }

  my @texform = <IN>;
  close(IN);
  
 
  # OUT is used for the media, screen, printer, email
  # for postscript we store a copy in a temporary file
  my $fileid = time;
  my $tmpfile = $self->{IN};
  $tmpfile =~ s/\./_$self->{fileid}./ if $self->{fileid};
  $self->{tmpfile} = "$userspath/${fileid}_${tmpfile}";
  
  if ($self->{format} =~ /(postscript|pdf)/ || $self->{media} eq 'email') {
    $out = $self->{OUT};
    $self->{OUT} = ">$self->{tmpfile}";
  }


  if ($self->{OUT}) {
    open(OUT, "$self->{OUT}") or $self->error("$self->{OUT} : $!");
  } else {
    open(OUT, ">-") or $self->error("STDOUT : $!");

    $self->header;
    
  }

  $self->{copies} ||= 1;

  # first we generate a tmpfile
  # read file and replace <%variable%>

  $self->{copy} = "";

  for my $i (1 .. $self->{copies}) {

    $sum = 0;
    $self->{copy} = 1 if $i == 2;

    if ($self->{format} =~ /(postscript|pdf)/ && $self->{copies} > 1) {
      if ($i == 1) {
	@_ = ();
	while ($_ = shift @texform) {
	  if (/\\end{document}/) {
	    push @_, qq|\\newpage\n|;
	    last;
	  }
	  push @_, $_;
	}
	@texform = @_;
      }

      if ($i == 2) {
	while ($_ = shift @texform) {
	  last if /\\begin{document}/;
	}
      }

      if ($i == $self->{copies}) {
	push @texform, q|\end{document}|;
      }
    }

    @_ = @texform;

    while ($_ = shift) {
	
      $par = "";
      $var = $_;

      # detect pagebreak block and its parameters
      if (/<%pagebreak ([0-9]+) ([0-9]+) ([0-9]+)%>/) {
	$chars_per_line = $1;
	$lines_on_first_page = $2;
	$lines_on_second_page = $3;
	
	while ($_ = shift) {
	  last if (/<%end pagebreak%>/);
	  $pagebreak .= $_;
	}
      }

      
      if (/<%foreach /) {
	
	# this one we need for the count
	chomp $var;
	$var =~ s/.*?<%foreach\s+?(.+?)%>/$1/;
	while ($_ = shift) {
	  last if /<%end \Q$var\E%>/;

	  # store line in $par
	  $par .= $_;
	}

	# display contents of $self->{number}[] array
	for my $j (0 .. $#{ $self->{$var} }) {

	  if ($var =~ /^(part|service)$/) {
	    next if $self->{$var}[$j] eq 'NULL';
	  }

	  # Try to detect whether a manual page break is necessary
	  # but only if there was a <%pagebreak ...%> block before
	  
	  if ($var eq 'number' || $var eq 'part' || $var eq 'service') {
	    if ($chars_per_line && defined $self->{$var}) {
	      my $line;
	      my $lines = 0;
	      my $item = $self->{description}[$j];
	      $item .= "\n".$self->{itemnotes}[$j] if $self->{itemnotes}[$j];
	      
	      foreach $line (split /\r?\n/, $item) {
		$lines++;
		$lines += int(length($line) / $chars_per_line);
	      }
	      
	      my $lpp;
	      
	      if ($current_page == 1) {
		$lpp = $lines_on_first_page;
	      } else {
		$lpp = $lines_on_second_page;
	      }

	      # Yes we need a manual page break
	      if (($current_line + $lines) > $lpp) {
		my $pb = $pagebreak;
		
		# replace the special variables <%sumcarriedforward%>
		# and <%lastpage%>
		
		my $psum = $self->format_amount($myconfig, $sum, $self->{precision});
		$pb =~ s/<%sumcarriedforward%>/$psum/g;
		$pb =~ s/<%lastpage%>/$current_page/g;
		
		# only "normal" variables are supported here
		# (no <%if, no <%foreach, no <%include)
		
		$pb =~ s/<%(.+?)%>/$self->{$1}/g;
		
		# page break block is ready to rock
		print(OUT $pb);
		$current_page++;
		$current_line = 1;
		$lines = 0;
	      }
	      $current_line += $lines;
	    }
	    $sum += $self->parse_amount($myconfig, $self->{linetotal}[$j]);
	  }

	  # don't parse par, we need it for each line
	  print OUT $self->format_line($par, $j);
	  
	}
	next;
      }

      # if not comes before if!
      if (/<%if\s+?not /) {
	# check if it is not set and display
	chop;
	s/.*?<%if\s+?not\s+?(.+?)%>/$1/;

	$var = $1;

	if (! $self->{$var}) {
	  s/^$var//;

	  if (/<%end /) {
	    s/<%end\s+?$var%>//;
	    $par = $_;
	  } else {
	    $par = $_;
	    while ($_ = shift) {
	      last if /<%end /;
	      # store line in $par
	      $par .= $_;
	    }
	  }
	  
	  $_ = $var = $par;
	  
	} else {
	  if (! /<%end /) {
	    while ($_ = shift) {
	      last if /<%end /;
	    }
	  }
	  next;
	}
      }
   
      if (/<%if /) {
	# check if it is set and display
	chop;
	s/.*?<%if\s+?(.+?)%>/$1/;

	$var = $1;

	if ($var =~ /\s/) {
	  @a = split / /, $var, 3;
	  $ok = eval qq|$self->{$a[0]} $a[1] "$a[2]"|;
	} else {
	  $ok = $self->{$var};
	}
	  
	if ($ok) {
	  s/^$var//;
	  if (/<%end /) {
	    s/<%end\s+?$var%>//;
	    $par = $_;
	  } else {
	    $par = $_;
	    while ($_ = shift) {
	      last if /<%end /;
	      # store line in $par
	      $par .= $_;
	    }
	  }
	  
	  $_ = $var = $par;
	  
	} else {
	  if (! /<%end /) {
	    while ($_ = shift) {
	      last if /<%end /;
	    }
	  }
	  next;
	}
      }
     
      # check for <%include filename%>
      if (/<%include /) {
	
	# get the filename
	chomp $var;
	$var =~ s/.*?<%include\s+?(.+?)%>/$1/;

	# remove / .. for security reasons
	$var =~ s/(\/|\.\.)//g;

	# assume loop after 10 includes of the same file
	next if $include{$var} > 10;

	unless (open(INC, "$self->{templates}/$self->{language_code}/$var")) {
	  $err = $!;
	  $self->cleanup;
	  $self->error("$self->{templates}/$self->{language_code}/$var : $err");
	}
	unshift(@_, <INC>);
	close(INC);

	$include{$var}++;

	next;
      }
      
      print OUT $self->format_line($_);
      
    }
  }

  close(OUT);


  # Convert the tex file to postscript
  if ($self->{format} =~ /(postscript|pdf)/) {

    use Cwd;
    $self->{cwd} = cwd();
    $self->{tmpdir} = "$self->{cwd}/$userspath";

    unless (chdir("$userspath")) {
      $err = $!;
      $self->cleanup;
      $self->error("chdir : $err");
    }

    $self->{tmpfile} =~ s/$userspath\///g;

    $self->{errfile} = $self->{tmpfile};
    $self->{errfile} =~ s/tex$/err/;

    my $r = 1;
    if ($self->{format} eq 'postscript') {

      system("latex --interaction=nonstopmode $self->{tmpfile} > $self->{errfile}");
      while ($self->rerun_latex) {
	system("latex --interaction=nonstopmode $self->{tmpfile} > $self->{errfile}");
	last if ++$r > 4;
      }
      $self->{tmpfile} =~ s/tex$/dvi/;
      $self->error($self->cleanup) if ! (-f $self->{tmpfile});
 
      system("dvips $self->{tmpfile} -o -q");
      $self->error($self->cleanup."dvips : $!") if ($?);
      $self->{tmpfile} =~ s/dvi$/ps/;
    }
    if ($self->{format} eq 'pdf') {
      system("pdflatex --interaction=nonstopmode $self->{tmpfile} > $self->{errfile}");
      while ($self->rerun_latex) {
	system("pdflatex --interaction=nonstopmode $self->{tmpfile} > $self->{errfile}");
	last if ++$r > 4;
      }
      
      $self->{tmpfile} =~ s/tex$/pdf/;
      $self->error($self->cleanup) if ! (-f $self->{tmpfile});
    }

  }


  if ($self->{format} =~ /(postscript|pdf)/ || $self->{media} eq 'email') {

    if ($self->{media} eq 'email') {
      
      use SL::Mailer;

      my $mail = new Mailer;
      
      for (qw(cc bcc subject message version format charset notify)) { $mail->{$_} = $self->{$_} }
      $mail->{to} = qq|$self->{email}|;
      $mail->{from} = qq|"$myconfig->{name}" <$myconfig->{email}>|;
      $mail->{fileid} = "$fileid.";

      # if we send html or plain text inline
      if (($self->{format} =~ /(html|txt)/) && ($self->{sendmode} eq 'inline')) {
	my $br = "";
	$br = "<br>" if $self->{format} eq 'html';
	  
	$mail->{contenttype} = "text/$self->{format}";

        $mail->{message} =~ s/\r?\n/$br\n/g;
	$myconfig->{signature} =~ s/\\n/$br\n/g;
	$mail->{message} .= "$br\n-- $br\n$myconfig->{signature}\n$br" if $myconfig->{signature};
	
	unless (open(IN, $self->{tmpfile})) {
	  $err = $!;
	  $self->cleanup;
	  $self->error("$self->{tmpfile} : $err");
	}

	while (<IN>) {
	  $mail->{message} .= $_;
	}

	close(IN);

      } else {

	@{ $mail->{attachments} } = ($self->{tmpfile});

	$myconfig->{signature} =~ s/\\n/\n/g;
	$mail->{message} .= "\n-- \n$myconfig->{signature}" if $myconfig->{signature};

      }

      if ($err = $mail->send($out)) {
	$self->cleanup;
	$self->error($err);
      }
      
    } else {

      $self->{OUT} = $out;
      unless (open(IN, $self->{tmpfile})) {
        $err = $!;
	$self->cleanup;
	$self->error("$self->{tmpfile} : $err");
      }

      binmode(IN);

      chdir("$self->{cwd}");
      
      if ($self->{OUT}) {
	unless (open(OUT, $self->{OUT})) {
	  $err = $!;
	  $self->cleanup;
	  $self->error("$self->{OUT} : $err");
	}
      } else {

	# launch application
	print qq|Content-Type: application/$self->{format}
Content-Disposition: attachment; filename="$self->{tmpfile}"\n\n|;

	unless (open(OUT, ">-")) {
	  $err = $!;
	  $self->cleanup;
	  $self->error("STDOUT : $err");
	}

      }

      binmode(OUT);
     
      while (<IN>) {
	print OUT $_;
      }
      
      close(IN);
      close(OUT);
    }

    $self->cleanup;

  }

}


sub format_line {
  my $self = shift;

  $_ = shift;
  my $i = shift;
  
  my $str;
  my $newstr;
  my $pos;
  my $l;
  my $lf;
  my $line;
  my $var = "";
  my %a;
  my @a;
  my $offset;
  my $pad;
  my $item;
  my $key;
  my $value;

  while (/<%(.+?)%>/) {

    $var = $1;
    $newstr = "";
    
    %a = ();
    if ($var =~ /(align|width|offset|group)\s*?=/) {
      @a = split / /, $var;
      $var = $a[0];
      foreach $item (@a) {
	($key, $value) = split /=/, $item;
	if ($value ne "") {
	  $a{$key} = $value;
	}
      }
    }

    if ($var =~ /\s/) {
      $str = "";

      @a = split / /, $var, 3;
      if ($var =~ /^if\s+?not /) {
	$a[1] = $a[2];
	pop @a;
      }

      if ($#a == 2) {
	for $j (0 .. 2) {
	  $item = $a[$j];
	  if ($item !~ /'/) {
	    if (defined $i) {
	      if (exists $self->{$item}[$i]) {
		$a[$j] = qq|'$self->{$item}[$i]'|;
	      }
	    } else {
	      if (exists $self->{$item}) {
		$a[$j] = qq|'$self->{$item}'|;
	      }
	    }
	  }
	}
	$str = eval qq|$a[0] $a[1] $a[2]|;
      } else {
	if (defined $i) {
	  $str = $self->{$a[1]}[$i];
	} else {
	  $str = $self->{$a[1]};
	}
      }
    } else {
      if (defined $i) {
	$str = $self->{$var}[$i];
      } else {
	$str = $self->{$var};
      }
    }
    $newstr = $str;

    if ($var =~ /^if\s+not /) {
      if ($str) {
	$var =~ s/if\s+?not\s+?//;
	s/<%if\s+not\s+?$var%>.*?(<%end\s+?$var%>|$)//s;
      } else {
	s/<%$var%>//;
      }
      next;
    }

    if ($var =~ /^if /) {
      if ($str) {
	s/<%$var%>//;
      } else {
	$var =~ s/if\s+?//;
	s/<%if\s+?$var%>.*?(<%(end|else)\s+?$var%>|$)//s;
      }
      next;
    }

    if ($var =~ /^else /) {
      if ($str) {
	$var =~ s/else\s+?//;
	s/<%else\s+?$var%>.*?(<%end\s+?$var%>|$)//s;
      } else {
	s/<%$var%>//;
      }
      next;
    }
    
    if ($var =~ /^end /) {
      s/<%$var%>//;
      next;
    }

    if ($a{align} || $a{width} || $a{offset}) {

      $newstr = "";
      $offset = 0;
      $lf = "";

      chomp $str;
      $str .= "\n";
      
      foreach $str (split /\n/, $str) {

	$line = $str;
	$l = length $str;

	do {
	  if (($pos = length $str) > $a{width}) {
	    if (($pos = rindex $str, " ", $a{width}) > 0) {
	      $line = substr($str, 0, $pos);
	    }
	    $pos = length $str if $pos == -1;
	  }

	  $l = length $line;

	  # pad left, right or center
	  $l = ($a{width} - $l);
	  
	  $pad = " " x $l;
	  
	  if ($a{align} =~ /right/i) {
	    $line = " " x $offset . $pad . $line;
	  }

	  if ($a{align} =~ /left/i) {
	    $line = " " x $offset . $line . $pad;
	  }

	  if ($a{align} =~ /center/i) {
	    $pad = " " x ($l/2);
	    $line = " " x $offset . $pad . $line;
	    $pad = " " x ($l/2);
	    $line .= $pad;
	  }

	  $newstr .= "$lf$line";

	  $str = substr($str, $pos + 1);
          $line = $str;
	  $lf = "\n";
	  
	  $offset = $a{offset};

	} while ($str);
      }
    }

    if ($a{group}) {
      
      $a{group} =~ s/\d+//;
      $n = $&;
      @a = split //, $str;

      if ($a{group} =~ /right/i) {
	@a = reverse @a;
      }

      my $j = $n - 1;
      $newstr = "";
      foreach $str (@a) {
	$j++;
	if (! ($j % $n)) {
	  $newstr .= " $str";
	} else {
	  $newstr .= $str;
	}
      }

      if ($a{group} =~ /right/i) {
	$newstr = reverse split //, $newstr;
      }
    }

    if ($a{ASCII}) {
      my $carret;
      my $nn;
      $n = 0;
      if ($a{ASCII} =~ /^\^/) {
	$carret = '^';
      }
      if ($a{ASCII} =~ /\d+/) {
	$n = length $&;
	$nn = $&;
      }

      $newstr = "";
      for (split //, $str) {
	$newstr .= "$carret";
	if ($n) {
	  $newstr .= substr($nn . ord, -$n);
	} else {
	  $newstr .= ord;
	}
      }
    }

    s/<%(.+?)%>/$newstr/;

  }

  $_;

}


sub format_dcn {
  my $self = shift;

  $_ = shift;
  
  my $str;
  my $modulo;
  my $var;
  my $padl;
  my $param;
  
  my @m = (0, 9, 4, 6, 8, 2, 7, 1, 3, 5);
  my %m;
  my $m;
  my $e;
  my @e;
  my $i;

  my $d;
  my @n;
  my $n;
  my $w;
  my $cd;
  my $lr;

  for (0 .. $#m) {
    @{ $m{$_} } = @m;
    $m = shift @m;
    push @m, $m;
  }
  
  if (/<%/) {
    
    while (/<%(.+?)%>/) {

      $param = $1;
      $str = $param;

      ($var, $padl) = split / /, $param;
      $padl *= 1;

      if ($var eq 'membernumber') {
	
	$str = $self->{$var};
	$str =~ s/\W//g;
	$str = substr('0' x $padl . $str, -$padl) if $padl;
	
      } elsif ($var =~ /modulo/) {

	$str = qq|\x01$str\x01|;
      
      } else {
	$i = 0;
	$str = $self->{$var};
	$str =~ s/\D/++$i/ge;
	$str = substr('0' x $padl . $str, -$padl) if $padl;
      }

      s/<%$param%>/$str/;

    }

    /(.+?)\x01modulo/;
    $modulo = $1;

    while (/\x01(modulo.+?)\x01/) {
      
      $param = $1;

      @e = split //, $modulo;
      $str = "";

      if ($param eq 'modulo10') {
	$e = 0;

	for $n (@e) {
	  $e = $m{$e}[$n];
	}
	$str = substr(10 - $e, -1);
      }

      if ($param =~ /modulo(1\d+)+?_/) {
	($n, $w, $lr) = split /_/, $param;
	$cd = 0;
	$m = $1;
	
	if ($lr eq 'right') {
	  @e = reverse @e;
	}

	if ($w eq '12' || $w eq '21') {
	  @n = split //, $w;

	  for $i (0 .. $#e) {
	    $n = $i % 2;
	    if (($d = $e[$i] * $n[$n]) > 9) {
	      for $n (split //, $d) {
		$cd += $n;
	      }
	    } else {
	      $cd += $d;
	    }
	  }
	} else {
	  @n = split //, $w;
	  for $i (0 .. $#e) {
	    $n = $i % 2;
	    $cd += $e[$i] * $n[$n];
	  }
	}
	
	$str = $cd % $m;
	if ($m eq '10') {
	  if ($str > 0) {
	    $str = $m - $str;
	  }
	}
      }

      s/\x01$param\x01/$str/;
      
      /(.+?)\x01modulo/;
      $modulo = $1;

    }

  }

  $_;

}


sub cleanup {
  my $self = shift;

  chdir("$self->{tmpdir}");

  my @err = ();
  if (-f "$self->{errfile}") {
    open(FH, "$self->{errfile}");
    @err = <FH>;
    close(FH);
  }
  
  if ($self->{tmpfile}) {
    # strip extension
    $self->{tmpfile} =~ s/\.\w+$//g;
    my $tmpfile = $self->{tmpfile};
    unlink(<$tmpfile.*>);
  }

  chdir("$self->{cwd}");
  
  "@err";
  
}


sub rerun_latex {
  my $self = shift;

  my $a = 0;
  if (-f "$self->{errfile}") {
    open(FH, "$self->{errfile}");
    $a = grep /(longtable Warning:|Warning:.*?LastPage)/, <FH>;
    close(FH);
  }
  
  $a;
  
}


sub format_string {
  my ($self, @fields) = @_;

  my $format = $self->{format};
  if ($self->{format} =~ /(postscript|pdf)/) {
    $format = ($self->{charset} =~ /utf/i) ? 'utf' : 'tex';
  }

  my %replace = ( 'order' => { html => [ '<', '>', '\n', '\r' ],
                               txt  => [ '\n', '\r' ],
                               tex  => [ quotemeta('\\'), '&', '\n',
			                 '\r', '\$', '%', '_', '#',
					 quotemeta('^'), '{', '}', '<', '>',
					 '£' ],
			       utf  => [ quotemeta('\\'), '&', '\n',
			                 '\r', '\$', '%', '_', '#',
					 quotemeta('^'), '{', '}', '<', '>']
			     },
                   html => { '<' => '&lt;', '>' => '&gt;',
                             '\n' => '<br>', '\r' => '<br>'
		           },
		   txt  => { '\n' => "\n", '\r' => "\r" },
	           tex  => { '&' => '\&', '\$' => '\$', '%' => '\%',
		             '_' => '\_', '#' => '\#',
			     quotemeta('^') => '\^\\', '{' => '\{',
			     '}' => '\}', '<' => '$<$', '>' => '$>$',
		             '\n' => '\newline ', '\r' => '\newline ',
		             '£' => '\pounds ', quotemeta('\\') => '/'
			   }
	        );

  $replace{utf} = $replace{tex};
  
  my $key;
  foreach $key (@{ $replace{order}{$format} }) {
    for (@fields) { $self->{$_} =~ s/$key/$replace{$format}{$key}/g }
  }

}


sub datediff {
  my ($self, $myconfig, $date1, $date2) = @_;

  use Time::Local;
  
  my ($yy1, $mm1, $dd1);
  my ($yy2, $mm2, $dd2);
  
  if (($date1 && $date1 =~ /\D/) && ($date2 && $date2 =~ /\D/)) {

    if ($myconfig->{dateformat} =~ /^yy/) {
      ($yy1, $mm1, $dd1) = split /\D/, $date1;
      ($yy2, $mm2, $dd2) = split /\D/, $date2;
    }
    if ($myconfig->{dateformat} =~ /^mm/) {
      ($mm1, $dd1, $yy1) = split /\D/, $date1;
      ($mm2, $dd2, $yy2) = split /\D/, $date2;
    }
    if ($myconfig->{dateformat} =~ /^dd/) {
      ($dd1, $mm1, $yy1) = split /\D/, $date1;
      ($dd2, $mm2, $yy2) = split /\D/, $date2;
    }
    
    $dd1 *= 1;
    $dd2 *= 1;
    $mm1--;
    $mm2--;
    $mm1 *= 1;
    $mm2 *= 1;
    $yy1 += 2000 if length $yy1 == 2;
    $yy2 += 2000 if length $yy2 == 2;

  }

  sprintf("%.0f", (timelocal(0,0,12,$dd2,$mm2,$yy2) - timelocal(0,0,12,$dd1,$mm1,$yy1))/86400);
  
}


sub datetonum {
  my ($self, $myconfig, $date) = @_;

  my ($mm, $dd, $yy);
  
  if ($date && $date =~ /\D/) {

    if ($myconfig->{dateformat} =~ /^yy/) {
      ($yy, $mm, $dd) = split /\D/, $date;
    }
    if ($myconfig->{dateformat} =~ /^mm/) {
      ($mm, $dd, $yy) = split /\D/, $date;
    }
    if ($myconfig->{dateformat} =~ /^dd/) {
      ($dd, $mm, $yy) = split /\D/, $date;
    }
    
    $dd *= 1;
    $mm *= 1;
    $yy += 2000 if length $yy == 2;

    $dd = substr("0$dd", -2);
    $mm = substr("0$mm", -2);
    
    $date = "$yy$mm$dd";
  }

  $date;
  
}


sub add_date {
  my ($self, $myconfig, $date, $repeat, $unit) = @_;

  use Time::Local;
  
  my $diff = 0;
  my $spc = $myconfig->{dateformat};
  $spc =~ s/\w//g;
  $spc = substr($spc, 0, 1);
  
  if ($date) {
    if ($date =~ /\D/) {

      if ($myconfig->{dateformat} =~ /^yy/) {
	($yy, $mm, $dd) = split /\D/, $date;
      }
      if ($myconfig->{dateformat} =~ /^mm/) {
	($mm, $dd, $yy) = split /\D/, $date;
      }
      if ($myconfig->{dateformat} =~ /^dd/) {
	($dd, $mm, $yy) = split /\D/, $date;
      }
      
    } else {
      # ISO
      $date =~ /(....)(..)(..)/;
      $yy = $1;
      $mm = $2;
      $dd = $3;
    }

    if ($unit eq 'days') {
      $diff = $repeat * 86400;
    }
    if ($unit eq 'weeks') {
      $diff = $repeat * 604800;
    }
    if ($unit eq 'months') {
      $diff = $mm + $repeat;

      my $whole = int($diff / 12);
      $yy += $whole;

      $mm = ($diff % 12) + 1;
      $diff = 0;
    }
    if ($unit eq 'years') {
      $yy++;
    }

    $mm--;

    @t = localtime(timelocal(0,0,12,$dd,$mm,$yy) + $diff);

    $t[4]++;
    $mm = substr("0$t[4]",-2);
    $dd = substr("0$t[3]",-2);
    $yy = $t[5] + 1900;

    if ($date =~ /\D/) {

      if ($myconfig->{dateformat} =~ /^yy/) {
	$date = "$yy$spc$mm$spc$dd";
      }
      if ($myconfig->{dateformat} =~ /^mm/) {
	$date = "$mm$spc$dd$spc$yy";
      }
      if ($myconfig->{dateformat} =~ /^dd/) {
	$date = "$dd$spc$mm$spc$yy";
      }
      
    } else {
      $date = "$yy$mm$dd";
    }
  }

  $date;

}


sub format_date {
  my ($self, $dateformat, $date) = @_;

  use Time::Local;
  
  my $spc = $dateformat;
  $spc =~ s/\w//g;
  $spc = substr($spc, 0, 1);
  
  # ISO
  $date =~ /(....)(..)(..)/;
  $yy = $1;
  $mm = $2;
  $dd = $3;

  if ($spc) {

    if ($dateformat =~ /^yy/) {
      $date = "$yy$spc$mm$spc$dd";
    }
    if ($dateformat =~ /^mm/) {
      $date = "$mm$spc$dd$spc$yy";
    }
    if ($dateformat =~ /^dd/) {
      $date = "$dd$spc$mm$spc$yy";
    }
    
  } else {
    $date = "$yy$mm$dd";
  }

  $date;

}


sub print_button {
  my ($self, $button, $name) = @_;

  print qq|<input class=submit type=submit name=action value="$button->{$name}{value}" accesskey="$button->{$name}{key}" title="$button->{$name}{value} [Alt-$button->{$name}{key}]">\n|;

}
  

# Database routines used throughout

sub dbconnect {
  my ($self, $myconfig) = @_;

  # connect to database
  my $dbh = DBI->connect($myconfig->{dbconnect}, $myconfig->{dbuser}, $myconfig->{dbpasswd}) or $self->dberror;

  # set db options
  if ($myconfig->{dboptions}) {
    $dbh->do($myconfig->{dboptions}) || $self->dberror($myconfig->{dboptions});
  }

  $dbh;

}


sub dbconnect_noauto {
  my ($self, $myconfig) = @_;

  # connect to database
  $dbh = DBI->connect($myconfig->{dbconnect}, $myconfig->{dbuser}, $myconfig->{dbpasswd}, {AutoCommit => 0}) or $self->dberror;

  # set db options
  if ($myconfig->{dboptions}) {
    $dbh->do($myconfig->{dboptions});
  }

  $dbh;

}


sub dbquote {
  my ($self, $var, $type) = @_;

  $var =~ s/;/\\;/g;
  
  # DBI does not return NULL for SQL_DATE if the date is empty
  if ($type eq 'SQL_DATE') {
    $_ = ($var) ? "'$var'" : "NULL";
  }
  if ($type eq 'SQL_INT') {
    $_ = $var * 1;
  }
  
  $_;

}


sub update_balance {
  my ($self, $dbh, $table, $field, $where, $value) = @_;

  # if we have a value, go do it
  if ($value) {
    # retrieve balance from table
    my $query = "SELECT $field FROM $table WHERE $where FOR UPDATE";
    my ($balance) = $dbh->selectrow_array($query);

    $balance += $value;
    # update balance
    $query = "UPDATE $table SET $field = $balance WHERE $where";
    $dbh->do($query) || $self->dberror($query);
  }
}


sub update_exchangerate {
  my ($self, $dbh, $curr, $transdate, $buy, $sell) = @_;

  # some sanity check for currency
  return if (!$curr || $self->{currency} eq $self->{defaultcurrency});

  my $query = qq|SELECT curr FROM exchangerate
                 WHERE curr = '$curr'
	         AND transdate = '$transdate'
		 FOR UPDATE|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);
  
  my $set;
  if ($buy && $sell) {
    $set = "buy = $buy, sell = $sell";
  } elsif ($buy) {
    $set = "buy = $buy";
  } elsif ($sell) {
    $set = "sell = $sell";
  }
  
  if ($sth->fetchrow_array) {
    $query = qq|UPDATE exchangerate
                SET $set
		WHERE curr = '$curr'
		AND transdate = '$transdate'|;
  } else {
    $query = qq|INSERT INTO exchangerate (curr, buy, sell, transdate)
                VALUES ('$curr', $buy, $sell, '$transdate')|;
  }
  $sth->finish;

  $dbh->do($query) || $self->dberror($query);
  
}


sub save_exchangerate {
  my ($self, $myconfig, $currency, $transdate, $rate, $fld) = @_;

  my $dbh = $self->dbconnect($myconfig);

  my ($buy, $sell) = (0, 0);
  $buy = $rate if $fld eq 'buy';
  $sell = $rate if $fld eq 'sell';
  
  $self->update_exchangerate($dbh, $currency, $transdate, $buy, $sell);

  $dbh->disconnect;
  
}


sub get_exchangerate {
  my ($self, $myconfig, $dbh, $curr, $transdate, $fld) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;

  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }
  
  my $exchangerate = 1;

  if ($transdate) {
    my $query = qq|SELECT $fld FROM exchangerate
		   WHERE curr = '$curr'
		   AND transdate = '$transdate'|;
    ($exchangerate) = $dbh->selectrow_array($query);
  }

  $dbh->disconnect if $disconnect;

  $exchangerate;

}


sub check_exchangerate {
  my ($self, $myconfig, $currency, $transdate, $fld) = @_;

  return "" if ! $transdate || $self->{defaultcurrency} eq $currency;
    
  my $dbh = $self->dbconnect($myconfig);

  my $query;
  my $exchangerate;
  
  $fld ||= 'buy';
  $query = qq|SELECT $fld, buy, sell FROM exchangerate
	      WHERE curr = '$currency'
	      AND transdate = |.$self->dbquote($transdate, SQL_DATE);
  ($exchangerate, $self->{fxbuy}, $self->{fxsell}) = $dbh->selectrow_array($query);
  
  $query = qq|SELECT precision FROM curr
              WHERE curr = '$currency'|;
  ($self->{precision}) = $dbh->selectrow_array($query);
	      
  $dbh->disconnect;
  
  $exchangerate;
  
}


sub add_shipto {
  my ($self, $dbh, $id) = @_;

  my $shipto;
  foreach my $item (qw(name address1 address2 city state zipcode country contact phone fax email)) {
    if ($self->{"shipto$item"} ne "") {
      $shipto = 1 if ($self->{$item} ne $self->{"shipto$item"});
    }
  }

  if ($shipto) {
    my $query = qq|INSERT INTO shipto (trans_id, shiptoname, shiptoaddress1,
                   shiptoaddress2, shiptocity, shiptostate,
		   shiptozipcode, shiptocountry, shiptocontact,
		   shiptophone, shiptofax, shiptoemail) VALUES ($id, |
		   .$dbh->quote($self->{shiptoname}).qq|, |
		   .$dbh->quote($self->{shiptoaddress1}).qq|, |
		   .$dbh->quote($self->{shiptoaddress2}).qq|, |
		   .$dbh->quote($self->{shiptocity}).qq|, |
		   .$dbh->quote($self->{shiptostate}).qq|, |
		   .$dbh->quote($self->{shiptozipcode}).qq|, |
		   .$dbh->quote($self->{shiptocountry}).qq|, |
		   .$dbh->quote($self->{shiptocontact}).qq|,
		   '$self->{shiptophone}', '$self->{shiptofax}',
		   '$self->{shiptoemail}')|;
    $dbh->do($query) || $self->dberror($query);
  }

}


sub get_employee {
  my ($self, $dbh) = @_;

  my $login = $self->{login};
  $login =~ s/@.*//;
  my $query = qq|SELECT name, id FROM employee 
                 WHERE login = '$login'|;
  my (@a) = $dbh->selectrow_array($query);
  $a[1] *= 1;
  
  @a;

}


# this sub gets the id and name from $table
sub get_name {
  my ($self, $myconfig, $table, $transdate) = @_;

  # connect to database
  my $dbh = $self->dbconnect($myconfig);
  
  my $where = "1=1";
  if ($transdate) {
    $where .= qq| AND (ct.startdate IS NULL OR ct.startdate <= '$transdate')
                  AND (ct.enddate IS NULL OR ct.enddate >= '$transdate')|;
  }

  my %defaults = $self->get_defaults($dbh, \@{['namesbynumber']});
  
  my $sortorder = "name";
  $sortorder = $self->{searchby} if $self->{searchby};
   
  my $var;

  if ($sortorder eq 'name') {
    $var = $self->like(lc $self->{$table});
    $where .= qq| AND lower(ct.name) LIKE '$var'|;
  } else {
    $var = $self->like(lc $self->{"${table}number"});
    $where .= qq| AND lower(ct.${table}number) LIKE '$var'|;
  }
  
  if ($defaults{namesbynumber}) {
    $sortorder = "${table}number";
  }
   
  my $query = qq|SELECT ct.*,
                 ad.address1, ad.address2, ad.city, ad.state,
		 ad.zipcode, ad.country
                 FROM $table ct
		 JOIN address ad ON (ad.trans_id = ct.id)
		 WHERE $where
		 ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);

  $sth->execute || $self->dberror($query);

  my $i = 0;
  @{ $self->{name_list} } = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push(@{ $self->{name_list} }, $ref);
    $i++;
  }
  $sth->finish;
  $dbh->disconnect;

  $i;
  
}


sub get_currencies {
  my ($self, $dbh, $myconfig) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;
  
  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }

  my $currencies;
  my $curr;
  my $precision;
  
  my $query = qq|SELECT curr, precision FROM curr
                 ORDER BY rn|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);

  while (($curr, $precision) = $sth->fetchrow_array) {
    if ($self->{currency} eq $curr) {
      $self->{precision} = $precision;
    }
    $currencies .= "$curr:";
  }
  $sth->finish;

  $dbh->disconnect if $disconnect;
  
  chop $currencies;
  $currencies;

}

 
sub get_defaults {
  my ($self, $dbh, $flds) = @_;

  my $query;
  my %defaults;

  if (@{$flds}) {
    $query = qq|SELECT * FROM defaults
                WHERE fldname LIKE '$flds->[0]'|;
    shift @{$flds};

    for (@{$flds}) {
      $query .= qq| OR fldname LIKE '$_'|;
    }
  } else {
    $query = qq|SELECT * FROM defaults|;
  }

  my $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $defaults{$ref->{fldname}} = $ref->{fldvalue};
  }
  $sth->finish;

  %defaults;
  
}

  
sub all_vc {
  my ($self, $myconfig, $vc, $module, $dbh, $transdate, $job, $openinv) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;
  
  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }

  my $sth;
  my $ref;
  
  my $query;
  my $arap = lc $module;
  my $joinarap;
  my $where = "1 = 1";
  
  if ($transdate) {
    $where .= qq| AND (vc.startdate IS NULL OR vc.startdate <= '$transdate')
                  AND (vc.enddate IS NULL OR vc.enddate >= '$transdate')|;
  }
  if ($openinv) {
    $joinarap = "JOIN $arap a ON (a.${vc}_id = vc.id)";
    $where .= " AND a.amount != a.paid";
  }
  $query .= qq|SELECT count(*) FROM $vc vc
               $joinarap
               WHERE $where|;
  my ($count) = $dbh->selectrow_array($query);

  # build selection list
  if ($count < $myconfig->{vclimit}) {
    $self->{"${vc}_id"} *= 1;
    $query = qq|SELECT vc.id, vc.name
		FROM $vc vc
		$joinarap
		WHERE $where
		UNION SELECT vc.id, vc.name
		FROM $vc vc
		WHERE vc.id = $self->{"${vc}_id"}
		ORDER BY name|;
    $sth = $dbh->prepare($query);
    $sth->execute || $self->dberror($query);

    @{ $self->{"all_$vc"} } = ();
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $self->{"all_$vc"} }, $ref;
    }
    $sth->finish;
    
  }

  
  # get self
  if (! $self->{employee_id}) {
    ($self->{employee}, $self->{employee_id}) = split /--/, $self->{employee};
    ($self->{employee}, $self->{employee_id}) = $self->get_employee($dbh) unless $self->{employee_id};
  }
  
  $self->all_employees($myconfig, $dbh, $transdate, 1);

  $self->all_departments($myconfig, $dbh, $vc);
  
  $self->all_warehouses($myconfig, $dbh, $vc);
  
  $self->all_projects($myconfig, $dbh, $transdate, $job);

  $self->all_languages($myconfig, $dbh);

  $self->all_taxaccounts($myconfig, $dbh, $transdate);

  $dbh->disconnect if $disconnect;

}


sub all_languages {
  my ($self, $myconfig, $dbh) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;

  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }
  my $sth;
  my $query;

  $query = qq|SELECT *
              FROM language
	      ORDER BY 2|;
  $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);

  $self->{all_language} = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $self->{all_language} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect if $disconnect;
  
}


sub all_taxaccounts {
  my ($self, $myconfig, $dbh, $transdate) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;

  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }
  my $sth;
  my $query;
  my $where;
  
  if ($transdate) {
    $where = qq| AND (t.validto >= '$transdate' OR t.validto IS NULL)|;
  }
  
  if ($self->{taxaccounts}) {
    # rebuild tax rates
    $query = qq|SELECT t.rate, t.taxnumber
                FROM tax t
		JOIN chart c ON (c.id = t.chart_id)
		WHERE c.accno = ?
		$where
		ORDER BY accno, validto|;
    $sth = $dbh->prepare($query) || $self->dberror($query);
   
    foreach my $accno (split / /, $self->{taxaccounts}) {
      $sth->execute("$accno");
      ($self->{"${accno}_rate"}, $self->{"${accno}_taxnumber"}) = $sth->fetchrow_array;
      $sth->finish;
    }
  }

  $dbh->disconnect if $disconnect;
  
}


sub all_employees {
  my ($self, $myconfig, $dbh, $transdate, $sales) = @_;
  
  # setup employees/sales contacts
  my $query = qq|SELECT id, name
 	         FROM employee
		 WHERE 1 = 1|;
		 
  if ($transdate) {
    $query .= qq| AND (startdate IS NULL OR startdate <= '$transdate')
                  AND (enddate IS NULL OR enddate >= '$transdate')|;
  } else {
    $query .= qq| AND enddate IS NULL|;
  }
  
  if ($sales) {
    $query .= qq| AND sales = '1'|;
  }

  $query .= qq|
	         ORDER BY name|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $self->{all_employee} }, $ref;
  }
  $sth->finish;

}



sub all_projects {
  my ($self, $myconfig, $dbh, $transdate, $job) = @_;

  my $disconnect = ($dbh) ? 0 : 1;

  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }
  
  my $where = "1 = 1";

  $where = qq|id NOT IN (SELECT id
                         FROM parts
			 WHERE project_id > 0)| if ! $job;
			 
  my $query = qq|SELECT *
                 FROM project
		 WHERE $where|;

  if ($form->{language_code}) {
    $query = qq|SELECT pr.*, t.description AS translation
                FROM project pr
		LEFT JOIN translation t ON (t.trans_id = pr.id)
		WHERE t.language_code = '$form->{language_code}'|;
  }

  if ($transdate) {
    $query .= qq| AND (startdate IS NULL OR startdate <= '$transdate')
                  AND (enddate IS NULL OR enddate >= '$transdate')|;
  }

  $query .= qq|
	         ORDER BY projectnumber|;

  $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);

  @{ $self->{all_project} } = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $self->{all_project} }, $ref;
  }
  $sth->finish;
  
  $dbh->disconnect if $disconnect;

}


sub all_departments {
  my ($self, $myconfig, $dbh, $vc) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;
  
  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }
  
  my $where = "1 = 1";
  
  if ($vc) {
    if ($vc eq 'customer') {
      $where = " role = 'P'";
    }
  }
  
  my $query = qq|SELECT id, description
                 FROM department
	         WHERE $where
	         ORDER BY 2|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);
  
  @{ $self->{all_department} } = ();
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $self->{all_department} }, $ref;
  }
  $sth->finish;
  
  $self->all_years($myconfig, $dbh);

  $dbh->disconnect if $disconnect;

}


sub all_warehouses {
  my ($self, $myconfig, $dbh, $vc) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;
  
  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }
  
  my $query = qq|SELECT id, description
                 FROM warehouse
	         ORDER BY 2|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);
  
  @{ $self->{all_warehouse} } = ();
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $self->{all_warehouse} }, $ref;
  }
  $sth->finish;
  
  $dbh->disconnect if $disconnect;

}



sub all_years {
  my ($self, $myconfig, $dbh) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;

  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }
 
  # get years
  my $query = qq|SELECT MIN(transdate) FROM acc_trans|;
  my ($startdate) = $dbh->selectrow_array($query);
  my $query = qq|SELECT MAX(transdate) FROM acc_trans|;
  my ($enddate) = $dbh->selectrow_array($query);

  if ($myconfig->{dateformat} =~ /^yy/) {
    ($startdate) = split /\W/, $startdate;
    ($enddate) = split /\W/, $enddate;
  } else { 
    (@_) = split /\W/, $startdate;
    $startdate = $_[2];
    (@_) = split /\W/, $enddate;
    $enddate = $_[2]; 
  }

  $self->{all_years} = ();
  $startdate = substr($startdate,0,4);
  $enddate = substr($enddate,0,4);
  
  if ($startdate) {
    while ($enddate >= $startdate) {
      push @{ $self->{all_years} }, $enddate--;
    }
  }

  %{ $self->{all_month} } = ( '01' => 'January',
			  '02' => 'February',
			  '03' => 'March',
			  '04' => 'April',
			  '05' => 'May ',
			  '06' => 'June',
			  '07' => 'July',
			  '08' => 'August',
			  '09' => 'September',
			  '10' => 'October',
			  '11' => 'November',
			  '12' => 'December' );
  
  my %defaults = $self->get_defaults($dbh, \@{[qw(method precision namesbynumber)]});
  for (keys %defaults) { $self->{$_} = $defaults{$_} }
  $self->{method} ||= "accrual";

  $dbh->disconnect if $disconnect;
  
}


sub create_links {
  my ($self, $module, $myconfig, $vc, $job) = @_;
 
  # get last customers or vendors
  my ($query, $sth);
  
  my $dbh = $self->dbconnect($myconfig);

  my %xkeyref = ();

  my %defaults = $self->get_defaults($dbh, \@{[qw(closedto revtrans weightunit cdt precision)]});
  for (keys %defaults) { $self->{$_} = $defaults{$_} }

  # now get the account numbers
  $query = qq|SELECT c.accno, c.description, c.link,
              l.description AS translation
              FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.link LIKE '%$module%'
	      ORDER BY c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);

  $self->{accounts} = "";
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    
    foreach my $key (split /:/, $ref->{link}) {
      if ($key =~ /$module/) {
	# cross reference for keys
	$xkeyref{$ref->{accno}} = $key;
	
	$ref->{description} = $ref->{translation} if $ref->{translation};

	push @{ $self->{"${module}_links"}{$key} }, { accno => $ref->{accno},
                                       description => $ref->{description} };

        $self->{accounts} .= "$ref->{accno} " if $key !~ /tax/;
      }
    }
  }
  $sth->finish;

  my $arap = ($vc eq 'customer') ? 'ar' : 'ap';
 
  $self->remove_locks($myconfig, $dbh);

  if ($self->{id}) {
    
    $query = qq|SELECT a.invnumber, a.transdate,
                a.${vc}_id, a.datepaid, a.duedate, a.ordnumber,
		a.taxincluded, a.curr AS currency, a.notes, a.intnotes,
		a.terms, a.cashdiscount, a.discountterms,
		c.name AS $vc, c.${vc}number, a.department_id,
		d.description AS department,
		a.amount AS oldinvtotal, a.paid AS oldtotalpaid,
		a.employee_id, e.name AS employee, c.language_code,
		a.ponumber, a.approved,
		br.id AS batchid, br.description AS batchdescription,
		a.description, a.onhold, a.exchangerate, a.dcn,
		ch.accno AS bank_accno, ch.description AS bank_accno_description,
		t.description AS bank_accno_translation,
		pm.description AS paymentmethod, a.paymentmethod_id
		FROM $arap a
		JOIN $vc c ON (a.${vc}_id = c.id)
		LEFT JOIN employee e ON (e.id = a.employee_id)
		LEFT JOIN department d ON (d.id = a.department_id)
		LEFT JOIN vr ON (vr.trans_id = a.id)
		LEFT JOIN br ON (br.id = vr.br_id)
		LEFT JOIN chart ch ON (ch.id = a.bank_id)
		LEFT JOIN translation t ON (t.trans_id = ch.id AND t.language_code = '$myconfig->{countrycode}')
		LEFT JOIN paymentmethod pm ON (pm.id = a.paymentmethod_id)
		WHERE a.id = $self->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $self->dberror($query);
    
    $ref = $sth->fetchrow_hashref(NAME_lc);
    
    $ref->{exchangerate} ||= 1;

    for (qw(oldinvtotal oldtotalpaid)) { $ref->{$_} = $self->round_amount($ref->{$_} / $ref->{exchangerate}, $self->{precision}) }
    foreach $key (keys %$ref) {
      $self->{$key} = $ref->{$key};
    }
    $sth->finish;

    if ($self->{bank_accno}) {
      $self->{payment_accno} = ($self->{bank_accno_translation}) ? "$self->{bank_accno}--$self->{bank_accno_translation}" : "$self->{bank_accno}--$self->{bank_accno_description}";
    }

    if ($self->{paymentmethod_id}) {
      $self->{payment_method} = "$self->{paymentmethod}--$self->{paymentmethod_id}";
    }

    # get printed, emailed
    $query = qq|SELECT s.printed, s.emailed, s.spoolfile, s.formname
                FROM status s
		WHERE s.trans_id = $self->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $self->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $self->{printed} .= "$ref->{formname} " if $ref->{printed};
      $self->{emailed} .= "$ref->{formname} " if $ref->{emailed};
      $self->{queued} .= "$ref->{formname} $ref->{spoolfile} " if $ref->{spoolfile};
    }
    $sth->finish;
    for (qw(printed emailed queued)) { $self->{$_} =~ s/ +$//g }

    # get recurring
    $self->get_recurring($dbh);

    # get amounts from individual entries
    $query = qq|SELECT c.accno, c.description, ac.source, ac.amount,
                ac.memo, ac.transdate, ac.cleared, ac.project_id,
		p.projectnumber, ac.id, y.exchangerate,
		l.description AS translation,
		pm.description AS paymentmethod, y.paymentmethod_id
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		LEFT JOIN project p ON (p.id = ac.project_id)
		LEFT JOIN payment y ON (y.trans_id = ac.trans_id AND ac.id = y.id)
		LEFT JOIN paymentmethod pm ON (pm.id = y.paymentmethod_id)
		LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		WHERE ac.trans_id = $self->{id}
		AND ac.fx_transaction = '0'
		ORDER BY ac.transdate|;
    $sth = $dbh->prepare($query);
    $sth->execute || $self->dberror($query);

    # store amounts in {acc_trans}{$key} for multiple accounts
    while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{description} = $ref->{translation} if $ref->{translation};
      $ref->{exchangerate} ||= 1;
      push @{ $self->{acc_trans}{$xkeyref{$ref->{accno}}} }, $ref;
    }
    $sth->finish;
    
    $self->create_lock($myconfig, $dbh, $self->{id}, $arap);

  } else {
   
    # get date
    if (!$self->{transdate}) {
      $self->{transdate} = $self->current_date($myconfig);
    }
    if (! $self->{"$self->{vc}_id"}) {
      $self->lastname_used($myconfig, $dbh, $vc, $module);
    }

  }
  
  $self->all_vc($myconfig, $vc, $module, $dbh, $self->{transdate}, $job);
 
  $self->{currencies} = $self->get_currencies($dbh, $myconfig);
  
  # get paymentmethod
  $query = qq|SELECT *
	      FROM paymentmethod
	      ORDER BY rn|;
  $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);

  @{ $self->{"all_paymentmethod"} } = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $self->{"all_paymentmethod"} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}


sub create_lock {
  my ($self, $myconfig, $dbh, $id, $module) = @_;
  
  my $query;
  my $expires = time;
  
  my $disconnect = ($dbh) ? 0 : 1;
  
  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }
 
  # remove expired locks
  $query = qq|DELETE FROM semaphore
              WHERE expires < '$expires'|;
  $dbh->do($query) || $self->dberror($query);
	      
  $expires = time + $myconfig->{timeout};
  
  if ($id) {
    $query = qq|SELECT id, login FROM semaphore
		WHERE id = $id|;
    my ($readonly, $login) = $dbh->selectrow_array($query);
    
    if ($readonly) {
      $login =~ s/@.*//;
      $query = qq|SELECT name FROM employee
		  WHERE login = '$login'|;
      ($self->{haslock}) = $dbh->selectrow_array($query);
      $self->{readonly} = 1;
    } else {
      $query = qq|INSERT INTO semaphore (id, login, module, expires)
		  VALUES ($id, '$self->{login}', '$module', '$expires')|;
      $dbh->do($query) || $self->dberror($query);
    }
  }
   
  $dbh->disconnect if $disconnect;

}


sub remove_locks {
  my ($self, $myconfig, $dbh, $module) = @_;
  
  my $disconnect = ($dbh) ? 0 : 1;

  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }

  my $query = qq|DELETE FROM semaphore
	         WHERE login = '$self->{login}'|;
  $query .= qq|
		 AND module = '$module'| if $module;
  $dbh->do($query) || $self->dberror($query);

  $dbh->disconnect if $disconnect;

}


sub lastname_used {
  my ($self, $myconfig, $dbh, $vc, $module) = @_;

  my $arap = ($vc eq 'customer') ? "ar" : "ap";
  my $where = "1 = 1";
  my $sth;
  
  if ($self->{type} =~ /_order/) {
    $arap = 'oe';
    $where = "quotation = '0'";
  }
  if ($self->{type} =~ /_quotation/) {
    $arap = 'oe'; 
    $where = "quotation = '1'";
  }
  
  my $query = qq|SELECT id FROM $arap
                 WHERE id IN (SELECT MAX(id) FROM $arap
		              WHERE $where
			      AND ${vc}_id > 0)|;
  my ($trans_id) = $dbh->selectrow_array($query);
  
  $trans_id *= 1;

  my $duedate;
  if ($myconfig->{dbdriver} eq 'DB2') {
    $duedate = ($self->{transdate}) ? qq|date '$self->{transdate}' + ct.terms DAYS| : qq|current_date + ct.terms DAYS|;
  } elsif ($myconfig->{dbdriver} eq 'Sybase') {
    $duedate = ($self->{transdate}) ? qq|dateadd($myconfig->{dateformat}, ct.terms DAYS, $self->{transdate})| : qq|dateadd($myconfig->{dateformat}, ct.terms DAYS, current_date)|;
  } else {
    $duedate = ($self->{transdate}) ? qq|date '$self->{transdate}' + ct.terms| : qq|current_date + ct.terms|;
  }
    
  $query = qq|SELECT ct.name AS $vc, ct.${vc}number, a.curr AS currency,
              a.${vc}_id,
              $duedate AS duedate, a.department_id,
	      d.description AS department, ct.notes AS intnotes,
	      ct.curr AS currency, ct.remittancevoucher
	      FROM $arap a
	      JOIN $vc ct ON (a.${vc}_id = ct.id)
	      LEFT JOIN department d ON (a.department_id = d.id)
	      WHERE a.id = $trans_id|;
  $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) { $self->{$_} = $ref->{$_} }
  $sth->finish;

}



sub current_date {
  my ($self, $myconfig, $date) = @_;

  use Time::Local;
  
  my $spc = $myconfig->{dateformat};
  $spc =~ s/\w//g;
  $spc = substr($spc, 0, 1);
  my @t = localtime;
  my $dd;
  my $mm;
  my $yy;
  
  if ($date) {
    if ($date =~ /\D/) {

      if ($myconfig->{dateformat} =~ /^yy/) {
	($yy, $mm, $dd) = split /\D/, $date;
      }
      if ($myconfig->{dateformat} =~ /^mm/) {
	($mm, $dd, $yy) = split /\D/, $date;
      }
      if ($myconfig->{dateformat} =~ /^dd/) {
	($dd, $mm, $yy) = split /\D/, $date;
      }
      
    } else {
      # ISO
      $date =~ /(....)(..)(..)/;
      $yy = $1;
      $mm = $2;
      $dd = $3;
    }

    $mm--;
    @t = (1,0,0,$dd,$mm,$yy);
  }

  @t = localtime(timelocal(@t));

  $t[4]++;
  $mm = substr("0$t[4]",-2);
  $dd = substr("0$t[3]",-2);
  $yy = $t[5] + 1900;

  if ($myconfig->{dateformat} =~ /\D/) {

    if ($myconfig->{dateformat} =~ /^yy/) {
      $date = "$yy$spc$mm$spc$dd";
    }
    if ($myconfig->{dateformat} =~ /^mm/) {
      $date = "$mm$spc$dd$spc$yy";
    }
    if ($myconfig->{dateformat} =~ /^dd/) {
      $date = "$dd$spc$mm$spc$yy";
    }
    
  } else {
    $date = "$yy$mm$dd";
  }

  $date;

}


sub like {
  my ($self, $str) = @_;

  $str =~ s/;/\\;/g;
  
  if ($str !~ /(%|_)/) {
    if ($str =~ /(^").*("$)/) {
      $str =~ s/(^"|"$)//g;
    } else {
      $str = "%$str%";
    }
  }

  $str =~ s/'/''/g;
  $str;
  
}


sub redo_rows {
  my ($self, $flds, $new, $count, $numrows) = @_;

  my @ndx = ();

  for (1 .. $count) { push @ndx, { num => $new->[$_-1]->{runningnumber}, ndx => $_ } }

  my $i = 0;
  # fill rows
  foreach my $item (sort { $a->{num} <=> $b->{num} } @ndx) {
    $i++;
    $j = $item->{ndx} - 1;
    for (@{$flds}) { $self->{"${_}_$i"} = $new->[$j]->{$_} }
  }

  # delete empty rows
  for $i ($count + 1 .. $numrows) {
    for (@{$flds}) { delete $self->{"${_}_$i"} }
  }

}


sub get_partsgroup {
  my ($self, $myconfig, $p) = @_;

  my $dbh = $self->dbconnect($myconfig);

  my $query = qq|SELECT DISTINCT pg.*
                 FROM partsgroup pg
		 JOIN parts p ON (p.partsgroup_id = pg.id)|;
  my $where = qq|WHERE p.obsolete = '0'|;
  my $sortorder = "partsgroup";
  
  if ($p->{searchitems} eq 'part') {
    $where .= qq|
                 AND (p.inventory_accno_id > 0
		        AND p.income_accno_id > 0)|;
  }
  if ($p->{searchitems} eq 'service') {
    $where .= qq|
                 AND p.inventory_accno_id IS NULL|;
  }
  if ($p->{searchitems} eq 'assembly') {
    $where .= qq|
                 AND p.assembly = '1'|;
  }
  if ($p->{searchitems} eq 'labor') {
    $where .= qq|
                 AND p.inventory_accno_id > 0 AND p.income_accno_id IS NULL|;
  }
  if ($p->{searchitems} eq 'nolabor') {
    $where .= qq|
                 AND p.income_accno_id > 0|;
  }

  if ($p->{all}) {
    $query = qq|SELECT id, partsgroup, pos
                FROM partsgroup|;
    $where = "";
  } 

  if ($p->{language_code}) {
    $sortorder = "translation";
    
    $query = qq|SELECT DISTINCT pg.*, t.description AS translation
		FROM partsgroup pg
		JOIN parts p ON (p.partsgroup_id = pg.id)
		LEFT JOIN translation t ON (t.trans_id = pg.id AND t.language_code = '$p->{language_code}')|;
  }
  
  $query .= qq| $where
		 ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $self->dberror($query);

  $self->{all_partsgroup} = ();
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $self->{all_partsgroup} }, $ref;
  }
  $sth->finish;

  my %defaults = $self->get_defaults($dbh, \@{['method']});
  $self->{method} = ($defaults{method}) ? $defaults{method} : "accrual";
  
  $dbh->disconnect;

}


sub update_status {
  my ($self, $myconfig) = @_;

  # no id return
  return unless $self->{id};

  my $dbh = $self->dbconnect_noauto($myconfig);

  my %queued = split / +/, $self->{queued};
  my $spoolfile = ($queued{$self->{formname}}) ? "'$queued{$self->{formname}}'" : 'NULL';
  my $query = qq|DELETE FROM status
 	         WHERE formname = '$self->{formname}'
	         AND trans_id = $self->{id}|;
  $dbh->do($query) || $self->dberror($query);

  my $printed = ($self->{printed} =~ /$self->{formname}/) ? "1" : "0";
  my $emailed = ($self->{emailed} =~ /$self->{formname}/) ? "1" : "0";
  
  $query = qq|INSERT INTO status (trans_id, printed, emailed,
	      spoolfile, formname) VALUES ($self->{id}, '$printed',
	      '$emailed', $spoolfile,
	      '$self->{formname}')|;
  $dbh->do($query) || $self->dberror($query);

  $dbh->commit;
  $dbh->disconnect;

}


sub save_status {
  my ($self, $dbh) = @_;

  my $formnames = $self->{printed};
  my $emailforms = $self->{emailed};

  my $query = qq|DELETE FROM status
		 WHERE trans_id = $self->{id}|;
  $dbh->do($query) || $self->dberror($query);

  my %queued;
  my $formname;
  
  if ($self->{queued}) {
    %queued = split / +/, $self->{queued};

    foreach $formname (keys %queued) {
      
      $printed = ($self->{printed} =~ /$formname/) ? "1" : "0";
      $emailed = ($self->{emailed} =~ /$formname/) ? "1" : "0";
      
      if ($queued{$formname}) {
	$query = qq|INSERT INTO status (trans_id, printed, emailed,
		    spoolfile, formname)
		    VALUES ($self->{id}, '$printed', '$emailed',
		    '$queued{$formname}', '$formname')|;
	$dbh->do($query) || $self->dberror($query);
      }
      
      $formnames =~ s/$formname//;
      $emailforms =~ s/$formname//;
      
    }
  }

  # save printed, emailed info
  $formnames =~ s/^ +//g;
  $emailforms =~ s/^ +//g;

  my %status = ();
  for (split / +/, $formnames) { $status{$_}{printed} = 1 }
  for (split / +/, $emailforms) { $status{$_}{emailed} = 1 }
  
  foreach my $formname (keys %status) {
    $printed = ($formnames =~ /$self->{formname}/) ? "1" : "0";
    $emailed = ($emailforms =~ /$self->{formname}/) ? "1" : "0";
    
    $query = qq|INSERT INTO status (trans_id, printed, emailed, formname)
		VALUES ($self->{id}, '$printed', '$emailed', '$formname')|;
    $dbh->do($query) || $self->dberror($query);
  }

}


sub get_recurring {
  my ($self, $dbh) = @_;
  
  my $query = qq~SELECT s.*, se.formname || ':' || se.format AS emaila,
              se.message,
	      sp.formname || ':' || sp.format || ':' || sp.printer AS printa
	      FROM recurring s
	      LEFT JOIN recurringemail se ON (s.id = se.id)
	      LEFT JOIN recurringprint sp ON (s.id = sp.id)
	      WHERE s.id = $self->{id}~;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  for (qw(email print)) { $self->{"recurring$_"} = "" }
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    for (keys %$ref) { $self->{"recurring$_"} = $ref->{$_} }
    $self->{recurringemail} .= "$ref->{emaila}:";
    $self->{recurringprint} .= "$ref->{printa}:";
    for (qw(emaila printa)) { delete $self->{"recurring$_"} }
  }
  $sth->finish;
  chop $self->{recurringemail};
  chop $self->{recurringprint};

  if ($self->{recurringstartdate}) {
    for (qw(reference description message)) { $self->{"recurring$_"} = $self->escape($self->{"recurring$_"},1) }
    for (qw(reference description startdate repeat unit howmany payment print email message)) { $self->{recurring} .= qq|$self->{"recurring$_"},| }
    chop $self->{recurring};
  }

}


sub save_recurring {
  my ($self, $dbh, $myconfig) = @_;

  my $disconnect = ($dbh) ? 0 : 1;

  if (! $dbh) {
    $dbh = $self->dbconnect_noauto($myconfig);
  }
  
  my $query;
  
  for (qw(recurring recurringemail recurringprint)) {
    $query = qq|DELETE FROM $_ WHERE id = $self->{id}|;
    $dbh->do($query) || $self->dberror($query);
  }
  
  if ($self->{recurring}) {
    my %s = ();
    ($s{reference}, $s{description}, $s{startdate}, $s{repeat}, $s{unit}, $s{howmany}, $s{payment}, $s{print}, $s{email}, $s{message}) = split /,/, $self->{recurring};

    for (qw(reference description message)) { $s{$_} = $self->unescape($s{$_}) }
    for (qw(repeat howmany payment)) { $s{$_} *= 1 }

    # calculate enddate
    my $advance = $s{repeat} * ($s{howmany} - 1);
    my %interval = ( 'Pg' => "(date '$s{startdate}' + interval '$advance $s{unit}')",
                  'Sybase' => "dateadd($myconfig->{dateformat}, $advance $s{unit}, $s{startdate})",
                    'DB2' => qq|(date ('$s{startdate}') + "$advance $s{unit}")|,
                   );
    $interval{Oracle} = $interval{PgPP} = $interval{Pg};
    $query = qq|SELECT $interval{$myconfig->{dbdriver}}
		FROM defaults
		WHERE fldname = 'version'|;
    my ($enddate) = $dbh->selectrow_array($query);
    
    # calculate nextdate
    if ($myconfig->{dbdriver} eq 'Sybase') {
      $query = qq|SELECT datediff($myconfig->{dateformat}, $s{startdate}, current_date) AS a,
		  datediff($myconfig->{dateformat}, current_date, $enddate) AS b
		  FROM defaults
		  WHERE fldname = 'version'|;
    } else {
      $query = qq|SELECT current_date - date '$s{startdate}' AS a,
		  date '$enddate' - current_date AS b
		  FROM defaults
		  WHERE fldname = 'version'|;
    }
    my ($a, $b) = $dbh->selectrow_array($query);
    
    if ($a + $b) {
      $advance = int(($a / ($a + $b)) * ($s{howmany} - 1) + 1) * $s{repeat};
    } else {
      $advance = 0;
    }

    my $nextdate = $enddate;
    if ($advance > 0) {
      if ($advance < ($s{repeat} * $s{howmany})) {
	%interval = ( 'Pg' => "(date '$s{startdate}' + interval '$advance $s{unit}')",
	            'Sybase' => "dateadd($myconfig->{dateformat}, $advance $s{unit}, $s{startdate})",
		      'DB2' => qq|(date ('$s{startdate}') + "$advance $s{unit}")|,
		    );
	$interval{Oracle} = $interval{PgPP} = $interval{Pg};
	$query = qq|SELECT $interval{$myconfig->{dbdriver}}
		    FROM defaults
		    WHERE fldname = 'version'|;
	($nextdate) = $dbh->selectrow_array($query);
      }
    } else {
      $nextdate = $s{startdate};
    }

    if ($self->{recurringnextdate}) {
      $nextdate = $self->{recurringnextdate};
      
      $query = qq|SELECT '$enddate' - date '$nextdate'
                  FROM defaults
		  WHERE fldname = 'version'|;
      if ($myconfig->{dbdriver} eq 'Sybase') {
	$query = qq|SELECT datediff($myconfig->{dateformat}, $enddate, $nextdate)
	            FROM defaults
		    WHERE fldname = 'version'|;
      }

      if ($dbh->selectrow_array($query) < 0) {
	undef $nextdate;
      }
    }

    $self->{recurringpayment} *= 1;
    $query = qq|INSERT INTO recurring (id, reference, description,
                startdate, enddate, nextdate,
		repeat, unit, howmany, payment)
                VALUES ($self->{id}, |.$dbh->quote($s{reference}).qq|,
		|.$dbh->quote($s{description}).qq|,
		'$s{startdate}', '$enddate', |.
		$self->dbquote($nextdate, SQL_DATE).
		qq|, $s{repeat}, '$s{unit}', $s{howmany}, '$s{payment}')|;
    $dbh->do($query) || $self->dberror($query);

    my @p;
    my $p;
    my $i;
    my $sth;
    
    if ($s{email}) {
      # formname:format
      @p = split /:/, $s{email};
      
      $query = qq|INSERT INTO recurringemail (id, formname, format, message)
		  VALUES ($self->{id}, ?, ?, ?)|;
      $sth = $dbh->prepare($query) || $self->dberror($query);

      for ($i = 0; $i <= $#p; $i += 2) {
	$sth->execute($p[$i], $p[$i+1], $s{message});
      }
      $sth->finish;
    }
    
    if ($s{print}) {
      # formname:format:printer
      @p = split /:/, $s{print};
      
      $query = qq|INSERT INTO recurringprint (id, formname, format, printer)
		  VALUES ($self->{id}, ?, ?, ?)|;
      $sth = $dbh->prepare($query) || $self->dberror($query);

      for ($i = 0; $i <= $#p; $i += 3) {
	$p = ($p[$i+2]) ? $p[$i+2] : "";
	$sth->execute($p[$i], $p[$i+1], $p);
      }
      $sth->finish;
    }

  }

  if ($disconnect) {
    $dbh->commit;
    $dbh->disconnect;
  }

}


sub save_intnotes {
  my ($self, $myconfig, $vc) = @_;

  # no id return
  return unless $self->{id};

  my $dbh = $self->dbconnect($myconfig);

  my $query = qq|UPDATE $vc SET
                 intnotes = |.$dbh->quote($self->{intnotes}).qq|
                 WHERE id = $self->{id}|;
  $dbh->do($query) || $self->dberror($query);

  $dbh->disconnect;

}


sub update_defaults {
  my ($self, $myconfig, $fld, $dbh) = @_;

  my $disconnect = ($dbh) ? 0 : 1;
  
  if (! $dbh) {
    $dbh = $self->dbconnect_noauto($myconfig);
  }
  
  my $query = qq|SELECT fldname FROM defaults
                 WHERE fldname = '$fld'|;

  if (! $dbh->selectrow_array($query)) {
    $query = qq|INSERT INTO defaults (fldname)
                VALUES ('$fld')|;
    $dbh->do($query) || $self->dberror($query);
    $dbh->commit;
  }

  $query = qq|SELECT fldvalue FROM defaults
              WHERE fldname = '$fld' FOR UPDATE|;
  ($_) = $dbh->selectrow_array($query);

  $_ = "0" unless $_;

  # check for and replace
  # <%DATE%>, <%YYMMDD%>, <%YEAR%>, <%MONTH%>, <%DAY%> or variations of
  # <%NAME 1 1 3%>, <%BUSINESS%>, <%BUSINESS 10%>, <%CURR...%>
  # <%DESCRIPTION 1 1 3%>, <%ITEM 1 1 3%>, <%PARTSGROUP 1 1 3%> only for parts
  # <%PHONE%> for customer and vendors
  # <%YY%>, <%MM%>, <%DD%>, <%FDM%>, <%LDM%>
  
  my $num = $_;
  $num =~ s/.*?<%.*?%>//g;
  ($num) = $num =~ /(\d+)/;

  if (defined $num) {
    my $incnum;
    # if we have leading zeros check how long it is
    if ($num =~ /^0/) {
      my $l = length $num;
      $incnum = $num + 1;
      $l -= length $incnum;

      # pad it out with zeros
      my $padzero = "0" x $l;
      $incnum = ("0" x $l) . $incnum;
    } else {
      $incnum = $num + 1;
    }
      
    s/$num/$incnum/;
  }

  my $dbvar = $_;
  my $var = $_;
  my $str;
  my $param;
  
  if (/<%/) {
    while (/<%/) {
      s/<%.*?%>//;
      last unless $&;
      $param = $&;
      $str = "";
      
      if ($param =~ /<%date%>/i) {
	$str = ($self->split_date($myconfig->{dateformat}, $self->{transdate}))[0];
	$var =~ s/$param/$str/;
      }

      if ($param =~ /<%(name|business|description|item|partsgroup|phone|custom)/i) {
	my $fld = lc $1;
	if ($fld =~ /name/) {
	  if ($self->{type}) {
	    $fld = $self->{vc};
	  }
	}

        my $p = $param;
	$p =~ s/(<|>|%)//g;
	my @p = split / /, $p;
	my @n = split / /, uc $self->{$fld};
	if ($#p > 0) {
	  for (my $i = 1; $i <= $#p; $i++) {
	    $str .= substr($n[$i-1], 0, $p[$i]);
	  }
	} else {
	  ($str) = split /--/, $self->{$fld};
	}
	$var =~ s/$param/$str/;

	$var =~ s/\W//g if $fld eq 'phone';
      }
	
      if ($param =~ /<%(yy|mm|dd)/i) {
        my $p = $param;
	my $mdy = $1;
	$p =~ s/(<|>|%)//g;
       
	if (! $ml) { 
	  my $spc = $p;
	  $spc =~ s/\w//g;
	  $spc = substr($spc, 0, 1);
	  my %d = ( yy => 1, mm => 2, dd => 3 );
	  my @p = ();

	  my @a = $self->split_date($myconfig->{dateformat}, $self->{transdate});
	  for (sort keys %d) { push @p, $a[$d{$_}] if ($p =~ /$_/) }
	  $str = join $spc, @p;
	}

	$var =~ s/$param/$str/i;
      }

      if ($param =~ /<%(fdm|ldm)%>/i) {
	$str = $self->dayofmonth($myconfig->{dateformat}, $self->{transdate}, $1);
	$var =~ s/$param/$str/i;
      }
      
      if ($param =~ /<%curr/i) {
	$var =~ s/$param/$self->{currency}/i;
      }

    }
  }

  $query = qq|UPDATE defaults
              SET fldvalue = '$dbvar'
	      WHERE fldname = '$fld'|;
  $dbh->do($query) || $self->dberror($query);

  if ($disconnect) {
    $dbh->commit;
    $dbh->disconnect;
  }

  $var;

}


sub split_date {
  my ($self, $dateformat, $date) = @_;
  
  my @t = localtime;
  my $mm;
  my $dd;
  my $yy;
  my $rv;

  if (! $date) {
    $dd = $t[3];
    $mm = ++$t[4];
    $yy = substr($t[5],-2);
    $mm = substr("0$mm", -2);
    $dd = substr("0$dd", -2);
  }

  if ($dateformat =~ /^yy/) {
    if ($date) {
      if ($date =~ /\D/) {
	($yy, $mm, $dd) = split /\D/, $date;
	$mm *= 1;
	$dd *= 1;
	$rv = "$yy$mm$dd";
      } else {
	$rv = $date;
	$date =~ /(....)(..)(..)/;
	$yy = $1;
	$mm = $2;
	$dd = $3;
      }
      $mm = substr("0$mm", -2);
      $dd = substr("0$dd", -2);
      $yy = substr($yy, -2);
    } else {
      $rv = "$yy$mm$dd";
    }
  }
  
  if ($dateformat =~ /^mm/) {
    if ($date) { 
      if ($date =~ /\D/) {
	($mm, $dd, $yy) = split /\D/, $date;
	$mm *= 1;
	$dd *= 1;
	$mm = substr("0$mm", -2);
	$dd = substr("0$dd", -2);
	$yy = substr($yy, -2);
	$rv = "$mm$dd$yy";
      } else {
	$rv = $date;
      }
    } else {
      $rv = "$mm$dd$yy";
    }
  }
  
  if ($dateformat =~ /^dd/) {
    if ($date) {
      if ($date =~ /\D/) {
	($dd, $mm, $yy) = split /\D/, $date;
	$mm *= 1;
	$dd *= 1;
	$mm = substr("0$mm", -2);
	$dd = substr("0$dd", -2);
	$yy = substr($yy, -2);
	$rv = "$dd$mm$yy";
      } else {
	$rv = $date;
      }
    } else {
      $rv = "$dd$mm$yy";
    }
  }

  ($rv, $yy, $mm, $dd);

}
    

sub dayofmonth {
  my ($self, $dateformat, $date, $fdm) = @_;

  my $rv = $date;
  my @a = $self->split_date($dateformat, $date);
  my $bd = 0;

  my $spc = $date;
  $spc =~ s/\w//g;
  $spc = substr($spc, 0, 1);
 
  use Time::Local;

  $a[2]-- if $a[2];
  
  if (lc $fdm ne 'fdm') {
    $bd = 1;
    $a[2]++;
    if ($a[2] > 11) {
      $a[2] = 0;
      $a[1]++;
    }
  }

  my @t = localtime(timelocal(0,0,0,1,$a[2],$a[1]) - $bd);
  
  $t[4]++;
  $t[4] = substr("0$t[4]",-2);
  $t[3] = substr("0$t[3]",-2);
  $t[5] += 1900;
  
  if ($dateformat =~ /^yy/) {
    $rv = "$t[5]$spc$t[4]$spc$t[3]";
  }
  
  if ($dateformat =~ /^mm/) {
    $rv = "$t[4]$spc$t[3]$spc$t[5]";
  }
  
  if ($dateformat =~ /^dd/) {
    $rv = "$t[3]$spc$t[4]$spc$t[5]";
  }

  $rv;

}


sub from_to {
  my ($self, $yy, $mm, $interval) = @_;

  use Time::Local;
  
  my @t;
  my $dd = 1;
  my $fromdate = "$yy${mm}01";
  my $bd = 1;
  
  if (defined $interval) {
    if ($interval == 12) {
      $yy++;
    } else {
      if (($mm += $interval) > 12) {
	$mm -= 12;
	$yy++;
      }
      if ($interval == 0) {
	@t = localtime;
	$dd = $t[3];
	$mm = $t[4] + 1;
	$yy = $t[5] + 1900;
	$bd = 0;
      }
    }
  } else {
    if (++$mm > 12) {
      $mm -= 12;
      $yy++;
    }
  }

  $mm--;
  @t = localtime(timelocal(0,0,0,$dd,$mm,$yy) - $bd);
  
  $t[4]++;
  $t[4] = substr("0$t[4]",-2);
  $t[3] = substr("0$t[3]",-2);
  $t[5] += 1900;
  
  ($fromdate, "$t[5]$t[4]$t[3]");

}


sub fdld {
  my ($self, $myconfig, $locale) = @_;

  $self->{fdm} = $self->dayofmonth($myconfig->{dateformat}, $self->{transdate}, 'fdm');
  $self->{ldm} = $self->dayofmonth($myconfig->{dateformat}, $self->{transdate});
  
  my $transdate = $self->datetonum($myconfig, $self->{transdate});
  
  $self->{yy} = substr($transdate, 2, 2);
  ($self->{yyyy}, $self->{mm}, $self->{dd}) = $transdate =~ /(....)(..)(..)/;

  my $m1;
  my $m2;
  my $y1;
  my $y2;
  my $d1;
  my $d2;
  my $d3;
  my $d4;
  
  for (1 .. 11) {
    $m1 = $self->{mm} + $_;
    $y1 = $self->{yyyy};
    if ($m1 > 12) {
      $m1 -= 12;
      $y1++;
    }
    $m1 = substr("0$m1", -2);

    $m2 = $self->{mm} - $_;
    $y2 = $self->{yyyy};
    if ($m2 < 1) {
      $m2 += 12;
      $y2--;
    }
    $m2 = substr("0$m2", -2);

    $d1 = $self->format_date($myconfig->{dateformat}, "$y1${m1}01");
    $d2 = $self->format_date($myconfig->{dateformat}, $self->dayofmonth("yyyymmdd", "$y1${m1}01"));
    $d3 = $self->format_date($myconfig->{dateformat}, "$y2${m2}01");
    $d4 = $self->format_date($myconfig->{dateformat}, $self->dayofmonth("yyyymmdd", "$y2${m2}01"));

    if (exists $self->{longformat}) {
      $self->{"fdm+$_"} = $locale->date($myconfig, $d1, $self->{longformat});
      $self->{"ldm+$_"} = $locale->date($myconfig, $d2, $self->{longformat});
      $self->{"fdm-$_"} = $locale->date($myconfig, $d3, $self->{longformat});
      $self->{"ldm-$_"} = $locale->date($myconfig, $d4, $self->{longformat});
    } else {
      $self->{"fdm+$_"} = $d1;
      $self->{"ldm+$_"} = $d2;
      $self->{"fdm-$_"} = $d3;
      $self->{"ldm-$_"} = $d4;
    }
  }
 
  $d1 = $self->format_date($myconfig->{dateformat}, "$self->{yyyy}$self->{mm}01");
  $d2 = $self->format_date($myconfig->{dateformat}, $self->dayofmonth("yyyymmdd", "$self->{yyyy}$form->{mm}01"));

  if (exists $self->{longformat}) {
    $self->{fdm} = $locale->date($myconfig, $self->{fdm}, $self->{longformat});
    $self->{ldm} = $locale->date($myconfig, $self->{ldm}, $self->{longformat});
    $self->{fdy} = $locale->date($myconfig, $d1, $self->{longformat});
    $self->{ldy} = $locale->date($myconfig, $d2, $self->{longformat});
  } else {
    $self->{fdy} = $d1;
    $self->{ldy} = $d2;
  }

  for (1 .. 3) {
    $y1 = $self->{yyyy} + $_;
    $y2 = $self->{yyyy} - $_;

    $d1 = $self->format_date($myconfig->{dateformat}, "$y1$self->{mm}01");
    $d2 = $self->format_date($myconfig->{dateformat}, $self->dayofmonth("yyyymmdd", "$y1$self->{mm}01"));
    $d3 = $self->format_date($myconfig->{dateformat}, "$y2$self->{mm}01");
    $d4 = $self->format_date($myconfig->{dateformat}, $self->dayofmonth("yyyymmdd", "$y2$self->{mm}01"));

    if (exists $self->{longformat}) {
      $self->{"fdy+$_"} = $locale->date($myconfig, $d1, $self->{longformat});
      $self->{"ldy+$_"} = $locale->date($myconfig, $d2, $self->{longformat});
      $self->{"fdy-$_"} = $locale->date($myconfig, $d3, $self->{longformat});
      $self->{"ldy-$_"} = $locale->date($myconfig, $d4, $self->{longformat});
    } else {
      $self->{"fdy+$_"} = $d1;
      $self->{"ldy+$_"} = $d2;
      $self->{"fdy-$_"} = $d3;
      $self->{"ldy-$_"} = $d4;
    }

  }

}


sub audittrail {
  my ($self, $dbh, $myconfig, $audittrail) = @_;
  
# table, $reference, $formname, $action, $id, $transdate) = @_;

  my $query;
  my $rv;
  my $disconnect = ($dbh) ? 0 : 1;

  if (! $dbh) {
    $dbh = $self->dbconnect($myconfig);
  }
    
  # if we have an id add audittrail, otherwise get a new timestamp
  
  if ($audittrail->{id}) {
    
    my %defaults = $self->get_defaults($dbh, \@{['audittrail']});
    
    if ($defaults{audittrail}) {
      my ($null, $employee_id) = $self->get_employee($dbh);

      if ($self->{audittrail} && !$myconfig) {
	chop $self->{audittrail};
	
	my @a = split /\|/, $self->{audittrail};
	my %newtrail = ();
	my $key;
	my $i;
	my @flds = qw(tablename reference formname action transdate);

	# put into hash and remove dups
	while (@a) {
	  $key = "$a[2]$a[3]";
	  $i = 0;
	  $newtrail{$key} = { map { $_ => $a[$i++] } @flds };
	  splice @a, 0, 5;
	}
	
	$query = qq|INSERT INTO audittrail (trans_id, tablename, reference,
		    formname, action, employee_id, transdate)
	            VALUES ($audittrail->{id}, ?, ?,
		    ?, ?, $employee_id, ?)|;
	my $sth = $dbh->prepare($query) || $self->dberror($query);

	foreach $key (sort { $newtrail{$a}{transdate} cmp $newtrail{$b}{transdate} } keys %newtrail) {
	  $i = 1;
	  for (@flds) { $sth->bind_param($i++, $newtrail{$key}{$_}) }

	  $sth->execute || $self->dberror;
	  $sth->finish;
	}
      }

     
      if ($audittrail->{transdate}) {
	$query = qq|INSERT INTO audittrail (trans_id, tablename, reference,
		    formname, action, employee_id, transdate) VALUES (
		    $audittrail->{id}, '$audittrail->{tablename}', |
		    .$dbh->quote($audittrail->{reference}).qq|',
		    '$audittrail->{formname}', '$audittrail->{action}',
		    $employee_id, '$audittrail->{transdate}')|;
      } else {
	$query = qq|INSERT INTO audittrail (trans_id, tablename, reference,
		    formname, action, employee_id) VALUES ($audittrail->{id},
		    '$audittrail->{tablename}', |
		    .$dbh->quote($audittrail->{reference}).qq|,
		    '$audittrail->{formname}', '$audittrail->{action}',
		    $employee_id)|;
      }
      $dbh->do($query);
    }
  } else {
    
    $query = qq|SELECT current_timestamp FROM defaults
                WHERE fldname = 'version'|;
    my ($timestamp) = $dbh->selectrow_array($query);

    $rv = "$audittrail->{tablename}|$audittrail->{reference}|$audittrail->{formname}|$audittrail->{action}|$timestamp|";
  }

  $dbh->disconnect if $disconnect;
  
  $rv;
  
}



package Locale;


sub new {
  my ($type, $country, $NLS_file) = @_;
  my $self = {};

  %self = ();
  if ($country && -d "locale/$country") {
    $self->{countrycode} = $country;
    eval { require "locale/$country/$NLS_file"; };
  }

  $self->{NLS_file} = $NLS_file;
  $self->{charset} = $self{charset};
  
  push @{ $self->{LONG_MONTH} }, ("January", "February", "March", "April", "May ", "June", "July", "August", "September", "October", "November", "December");
  push @{ $self->{SHORT_MONTH} }, (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec));
  
  bless $self, $type;

}


sub text {
  my ($self, $text) = @_;
  
  return (exists $self{texts}{$text}) ? $self{texts}{$text} : $text;
  
}


sub findsub {
  my ($self, $text) = @_;

  if (exists $self{subs}{$text}) {
    $text = $self{subs}{$text};
  } else {
    if ($self->{countrycode} && $self->{NLS_file}) {
      Form->error("$text not defined in locale/$self->{countrycode}/$self->{NLS_file}");
    }
  }

  $text;

}


sub date {
  my ($self, $myconfig, $date, $longformat) = @_;

  my $longdate = "";
  my $longmonth = ($longformat) ? 'LONG_MONTH' : 'SHORT_MONTH';


  if ($date) {
    # get separator
    $spc = $myconfig->{dateformat};
    $spc =~ s/\w//g;
    $spc = substr($spc, 0, 1);

    if ($date =~ /\D/) {
      if ($myconfig->{dateformat} =~ /^yy/) {
	($yy, $mm, $dd) = split /\D/, $date;
      }
      if ($myconfig->{dateformat} =~ /^mm/) {
	($mm, $dd, $yy) = split /\D/, $date;
      }
      if ($myconfig->{dateformat} =~ /^dd/) {
	($dd, $mm, $yy) = split /\D/, $date;
      }
    } else {
      if (length $date > 6) {
	($yy, $mm, $dd) = ($date =~ /(....)(..)(..)/);
      } else {
	($yy, $mm, $dd) = ($date =~ /(..)(..)(..)/);
      }
    }
    
    $dd *= 1;
    $mm--;
    $yy += 2000 if length $yy == 2;

    if ($myconfig->{dateformat} =~ /^dd/) {
      $mm++;
      $dd = substr("0$dd", -2);
      $mm = substr("0$mm", -2);
      $longdate = "$dd$spc$mm$spc$yy";

      if (defined $longformat) {
	$longdate = "$dd";
	$longdate .= ($spc eq '.') ? ". " : " ";
	$longdate .= &text($self, $self->{$longmonth}[--$mm])." $yy";
      }
    } elsif ($myconfig->{dateformat} =~ /^yy/) {
      $mm++;
      $dd = substr("0$dd", -2);
      $mm = substr("0$mm", -2);
      $longdate = "$yy$spc$mm$spc$dd"; 

      if (defined $longformat) {
	$longdate = &text($self, $self->{$longmonth}[--$mm])." $dd $yy";
      }
    } else {
	$mm++;
	$dd = substr("0$dd", -2);
	$mm = substr("0$mm", -2);
	$longdate = "$mm$spc$dd$spc$yy"; 

      if (defined $longformat) {
	$longdate = &text($self, $self->{$longmonth}[--$mm])." $dd $yy";
      }
    }

  }

  $longdate;

}


1;

