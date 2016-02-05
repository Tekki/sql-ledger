#!/usr/bin/perl

# -n do not include custom scripts
# -a build all file
# -m do not generate missing files

use FileHandle;


$basedir = "../..";
$bindir = "$basedir/bin/mozilla";
$menufile = "menu.ini";

foreach $item (@ARGV) {
  $item =~ s/-//g;
  $arg{$item} = 1;
}

open(FH, "LANGUAGE");
$language = <FH>;
close(FH);
chomp $language;
$language =~ s/\((.*)\)/$1/;
$charset = $1;

opendir DIR, "$bindir" or die "$!";
@progfiles = grep { /\.pl/ } readdir DIR;
closedir DIR;

# custom logins
if (!$arg{n}) {
  if (opendir DIR, "$bindir/custom") {
    @customlogins = grep !/(\.pl|\.)/, readdir DIR;
    closedir DIR;
  }
}

if (-f "all") {
  eval { require "all"; };
  %all = %{$self{texts}};
  %{$self{texts}} = ();
} else {
  # build %all file from individual files
  foreach $file (@progfiles) {
    &scanfile("$bindir/$file");
  }
}
 
# remove the old missing file
if (-f 'missing') {
  unlink "missing";
}

foreach $file (@progfiles) {
  
  %locale = ();
  %submit = ();
  %subrt = ();
  @missing = ();
  %missing = ();
  
  &scanfile("$bindir/$file");

  # scan custom/{module}.pl and custom/{login}/{module}.pl files
  &scanfile("$bindir/custom/$file");

  foreach $customlogin (@customlogins) {
    &scanfile("$bindir/custom/$customlogin/$file");
  }
  
  # if this is the menu.pl file
  if ($file eq 'menu.pl') {
    &scanmenu("$basedir/$menufile");
    &scanmenu("$bindir/custom/$menufile");

    foreach $customlogin (@customlogins) {
      &scanmenu("$bindir/custom/$customlogin/$menufile");
    }
  }
  
  $file =~ s/\.pl//;
  
  if (-f "$file.missing") {
    eval { require "$file.missing"; };
    unlink "$file.missing";

    for (keys %$missing) {
      $self{texts}{$_} ||= $missing->{$_};
    }
  }

  open FH, ">$file" or die "$! : $file";

  if ($charset) {
    print FH qq|\$self{charset} = '$charset';\n\n|;
  }

  print FH q|$self{texts} = {
|;

  foreach $key (sort keys %locale) {
    $text = ($self{texts}{$key}) ? $self{texts}{$key} : $all{$key};
    $count++;
    
    $text =~ s/'/\\'/g;
    $text =~ s/\\$/\\\\/;

    $keytext = $key;
    $keytext =~ s/'/\\'/g;
    $keytext =~ s/\\$/\\\\/;
    
    if (!$text) {
      $notext++;
      push @missing, $keytext;
      $all{$keytext} = '';
      next;
    }
    
    print FH qq|  '$keytext'|.(' ' x (27-length($keytext))).qq| => '$text',\n|;
  }

  print FH q|};

$self{subs} = {
|;
  
  foreach $key (sort keys %subrt) {
    $text = $key;
    $text =~ s/'/\\'/g;
    $text =~ s/\\$/\\\\/;
    print FH qq|  '$text'|.(' ' x (27-length($text))).qq| => '$text',\n|;
  }

  foreach $key (sort keys %submit) {
    $text = ($self{texts}{$key}) ? $self{texts}{$key} : $all{$key};
    next unless $text;

    $text =~ s/'/\\'/g;
    $text =~ s/\\$/\\\\/;

    $english_sub = $key;
    $english_sub =~ s/'/\\'/g;
    $english_sub =~ s/\\$/\\\\/;
    $english_sub = lc $key;
    
    $translated_sub = lc $text;
    $english_sub =~ s/( |-|,|\/|\.$)/_/g;
    $translated_sub =~ s/( |-|,|\/|\.$)/_/g;
    print FH qq|  '$translated_sub'|.(' ' x (27-length($translated_sub))).qq| => '$english_sub',\n|;
  }
  
  print FH q|};

1;

|;

  close FH;

  if (!$arg{m}) {  
    if (@missing) {
      open FH, ">$file.missing" or die "$! : missing";

      print FH qq|# module $file
# add the missing texts and run locales.pl to rebuild

\$missing = {
|;

      foreach $text (@missing) {
	$text =~ s/'/\\'/g;
	$text =~ s/\\$/\\\\/;
	print FH qq|  '$text'|.(' ' x (27-length($text))).qq| => '',\n|;
      }

      print FH q|};

1;
|;

      close FH;
      
    }
  }
}

  
  # redo the all file
  if ($arg{a}) {
    open FH, ">all" or die "$! : all";

    print FH q|# These are all the texts to build the translations files.
# to build unique strings edit the module files instead
# this file is just a shortcut to build strings which are the same
|;

    if ($charset) {
      print FH qq|\$self{charset} = '$charset';\n\n|;
    }

    print FH q|
$self{texts} = {
|;

    foreach $key (sort keys %all) {
      $keytext = $key;
      $keytext =~ s/'/\\'/g;
      $keytext =~ s/\\$/\\\\/;
   
      $text = $all{$key};
      $text =~ s/'/\\'/g;
      $text =~ s/\\$/\\\\/;
      print FH qq|  '$keytext'|.(' ' x (27-length($keytext))).qq| => '$text',\n|;
    }

    print FH q|};

1;
|;

    close FH;
    
  }


#####################
# combine admin and menu
%{$self{texts}} = ();
do "menu";
%menu = %{$self{texts}};

%{$self{texts}} = ();
do "admin";
%admin = %{$self{texts}};

for (keys %menu) {
  $self{texts}{$_} ||= $menu{$_};
}
open FH, ">admin" or die "$! : admin";

if ($self{charset}) {
  print FH qq|\$self{charset} = '|.$self{charset}.qq|';\n\n|;
}

print FH q|$self{texts} = {
|;

  foreach $key (sort keys %{ $self{texts} }) {

    $keytext = $key;
    $keytext =~ s/'/\\'/g;
    $keytext =~ s/\\$/\\\\/;
 
    $text = $self{texts}{$key};
    $text =~ s/'/\\'/g;
    $text =~ s/\\$/\\\\/;
    print FH qq|  '$keytext'|.(' ' x (27-length($keytext))).qq| => '$text',\n|;
  }

  print FH q|};
|;

  print FH q|
$self{subs} = {
|;

  for (sort keys %{ $self{subs} }) {
    print FH qq|  '$_'|.(' ' x (27-length($_))).qq| => '$self{subs}{$_}',\n|;
  }
  
  print FH q|};
  
1;
|;

close FH;



$per = sprintf("%.1f", ($count - $notext) / $count * 100);
print "\n$language - ${per}%\n";

exit;
# eof


sub scanfile {
  my ($file, $level) = @_;

  my $fh = new FileHandle;
  return unless open $fh, "$file";

  $file =~ s/\.pl//;
  $file =~ s/$bindir\///;
  
  %temp = ();
  for (keys %{$self{texts}}) {
    $temp{$_} = $self{texts}{$_};
  }
      
  # read translation file if it exists
  if (-f $file) {
    eval { do "$file"; };
    for (keys %{$self{texts}}) {
      $all{$_} ||= $self{texts}{$_};
      if ($level) {
	$temp{$_} ||= $self{texts}{$_};
      } else {
	$temp{$_} = $self{texts}{$_};
      }
    }
  }

  %{$self{texts}} = ();
  for (sort keys %temp) {
    $self{texts}{$_} = $temp{$_};
  }
  
  
  while (<$fh>) {
    # is this another file
    if (/require\s+\W.*\.pl/) {
      my $newfile = $&;
      $newfile =~ s/require\s+\W//;
      $newfile =~ s/\$form->{path}\///;

      if ($newfile !~ /(custom|\$form->{login})/) {
	&scanfile("$bindir/$newfile", 1);
      }
    }
   
    # is this a sub ?
    if (/^sub /) {
      ($null, $subrt) = split / +/;
      $subrt{$subrt} = 1;
      next;
    }
    
    my $rc = 1;
    
    while ($rc) {
      if (/Locale/) {
	if (!/^use /) {
	  my ($null, $country) = split /,/;
	  $country =~ s/^ +["']//;
	  $country =~ s/["'].*//;
	}
      }

      if (/\$locale->text.*?\W\)/) {
	my $string = $&;
	$string =~ s/\$locale->text\(\s*['"(q|qq)]['\/\\\|~]*//;
	$string =~ s/\W\)+.*$//;

        # if there is no $ in the string record it
	unless ($string =~ /\$\D.*/) {
	  # this guarantees one instance of string
	  $locale{$string} = 1;

          # is it a submit button before $locale->
          if (/type=submit/i) {
	    $submit{$string} = 1;
          }

          # is it a value before $locale->
          if (/value => \$locale/) {
	    $submit{$string} = 1;
          }

	}
      }

      # exit loop if there are no more locales on this line
      ($rc) = ($' =~ /\$locale->text/);
      # strip text
      s/^.*?\$locale->text.*?\)//;
    }
  }

  close($fh);

}


sub scanmenu {
  my $file = shift;

  my $fh = new FileHandle;
  retunr unless open $fh, "$file";

  my @a = grep /^\[/, <$fh>;
  close($fh);

  # strip []
  grep { s/(\[|\])//g } @a;
  
  foreach my $item (@a) {
    $item =~ s/ *$//;
    @b = split /--/, $item;
    foreach $string (@b) {
      chomp $string;
      if ($string !~ /^\s*$/) {
	$locale{$string} = 1;
      }
    }
  }
  
}


