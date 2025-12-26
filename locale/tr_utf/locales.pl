#! /usr/bin/env perl
#
# Usage:
# ./locales.pl     create translation files
# ./locales.pl -n  do not include custom scripts

use v5.40;
use feature 'class';
no warnings 'experimental::class';

use Cwd;
use FindBin;
use Tie::IxHash;
use Time::Piece;
use YAML::PP;

chdir $FindBin::Bin;

my $basedir  = '../..';
my $bindir   = "$basedir/bin/mozilla";
my $menufile = 'menu.ini';
my ($locale) = getcwd =~ /.*\/(.+)/;

my %arg;
for my $item (@ARGV) {
  $item =~ s/-//g;
  $arg{$item} = 1;
}

my ($fh, $dir);

opendir $dir, $bindir or die "Unable to open $bindir: $!";
my @progfiles = grep {/\.pl/} readdir $dir;
closedir $dir;

# custom logins
my @customlogins;
unless ($arg{n}) {
  if (opendir $dir, "$bindir/custom") {
    @customlogins = grep !/(\.pl|\.)/, readdir $dir;
    closedir $dir;
  }
}

my $yp = YAML::PP->new;

my (%all_texts, %diff_texts);
if (-f 'all.yml') {
  my $all = $yp->load_file('all.yml');
  die "$all->{locale}: wrong locale in all.yml." if $all->{locale} ne $locale;
  %all_texts = $all->{texts}->%*;
}
if (-f 'all_diff.yml') {
  my $diff = $yp->load_file('all_diff.yml');
  die "$diff->{locale}: wrong locale in all_diff.yml." if $diff->{locale} ne $locale;
  %diff_texts = $diff->{texts}->%*;
}

for my $file (@progfiles) {

  my $tr = Translation->new(all => \%all_texts, diff => \%diff_texts);

  $tr->scanfile("$bindir/$file");

  # scan custom/{module}.pl and custom/{login}/{module}.pl files
  $tr->scanfile("$bindir/custom/$file");

  for my $customlogin (@customlogins) {
    $tr->scanfile("$bindir/custom/$customlogin/$file");
  }

  # if this is the menu.pl file
  if ($file eq 'menu.pl') {
    $tr->scanmenu("$basedir/$menufile");
    $tr->scanmenu("$bindir/custom/$menufile");

    for my $customlogin (@customlogins) {
      $tr->scanmenu("$bindir/custom/$customlogin/$menufile");
    }
  }

  $tr->generate;
}


# redo the all file

tie my %new_all, 'Tie::IxHash', (locale => $locale, texts => {});

my ($count, $notext);
for my $key (keys %all_texts) {
  $count++;
  $notext++ unless $all_texts{$key};

  $new_all{texts}{$key} = $all_texts{$key};
}

$yp->dump_file('all.yml', \%new_all);

unless (-f 'all_diff.yml') {
  $yp->dump_file('all_diff.yml', {locale => $locale, texts => {}});
}

# update date

if (-f 'COPYING') {
  open my $in, '<:encoding(UTF-8)', 'COPYING';
  my $copying;
  { local $/ = undef; $copying = <$in>; }
  close $in;

  my $today = localtime->ymd;
  $copying =~ s/# Update:.*/# Update: $today/;

  open my $out, '>:encoding(UTF-8)', 'COPYING';
  print $out $copying;
  close $out;
}

# print summary

printf "%s - %.1f %%\n", $locale, ($count - $notext) / $count * 100;

# classes

class Translation {
  use Storable;

  field $all  :param;
  field $diff :param;
  field $code;

  field %texts  = ();
  field %submit = ();
  field %subrt  = ();

  method generate () {
    my $tr_file = "$code.bin";
    my %new_tr  = (texts => {}, subs => {});
    my %old_tr  = -f $tr_file ? retrieve($tr_file)->%* : (texts => {}, subs => {});

    for my $key (keys %texts) {
      $all->{$key} //= '';
      my $text = $diff->{$key}{$code} || $all->{$key};

      $new_tr{texts}{$key} = $text if $text;
    }

    for my $key (keys %subrt) {
      my $text = $key;

      $new_tr{subs}{$text} = $text;
    }

    for my $key (keys %submit) {
      my $text = $diff->{$key}{$code} || $all->{$key} or next;

      my $english_sub    = lc $key;
      my $translated_sub = lc $text;
      $english_sub    =~ s/( |-|,|\/|\.$|\\')/_/g;
      $translated_sub =~ s/( |-|,|\/|\.$|\\')/_/g;

      $new_tr{subs}{$translated_sub} = $english_sub;
    }

    my $diff = keys($new_tr{texts}->%*) != keys($old_tr{texts}->%*)
      || keys($new_tr{subs}->%*) != keys($old_tr{subs}->%*);

    for my $key (keys $new_tr{texts}->%*) {
      last if $diff;
      $diff ||= $new_tr{texts}{$key} ne $old_tr{texts}{$key};
    }
    for my $key (keys $new_tr{subs}->%*) {
      last if $diff;
      $diff ||= $new_tr{subs}{$key} ne $old_tr{subs}{$key};
    }

    store \%new_tr, "$code.bin" if $diff;
  }

  method scanfile ($file, $level = 0) {

    open my $fh, '<:encoding(UTF-8)', $file or return $self;
    my @lines = <$fh>;
    close $fh;

    unless ($code) {
      ($code) = $file =~ /.*\/(\w+)\.pl/;
    }

    my %temp;

    for my $line (@lines) {

      # is this another file
      if ($line =~ /require\s+\W.*\.pl/) {
        my $newfile = $&;
        $newfile =~ s/require\s+\W//;
        $newfile =~ s/\$form->\{path}\///;

        if ($newfile !~ /(custom|\$form->\{login})/) {
          $self->scanfile("$bindir/$newfile", 1);
        }
      }

      # is this a sub ?
      if ($line =~ /^sub /) {
        (undef, my $sub) = split / +/, $line;
        $subrt{$sub} = 1;
        next;
      }

      my $string = '';
      my $rc     = 1;

      while ($rc) {
        if ($line =~ /Locale/) {
          unless ($line =~ /^use /) {
            (undef, my $country) = split /,/, $line;
            $country =~ s/^ +["']//;
            $country =~ s/["'].*//;
          }
        }

        if ($line =~ /\$locale->text.*?\W\)/) {
          $string = $&;
          $string =~ s/\$locale->text\(\s*['"(q|qq)]['\/\\\|~]*//;
          $string =~ s/\W\)+.*$//;

          # if there is no $ in the string record it
          unless ($string =~ /\$\D.*/) {

            # this guarantees one instance of string
            $texts{$string} = 1;

            # is it a submit button before $locale->
            if ($line =~ /type=submit/i) {
              $submit{$string} = 1;
            }

            # is it a value before $locale->
            if ($line =~ /value => \$locale/) {
              $submit{$string} = 1;
            }
          }
        }

        # strip text
        $line =~ s/^.*?\$locale->text.*?\)//;

        # exit loop if there are no more locales on this line
        $rc = $line =~ /\$locale->text/;
      }
    }

    return $self;
  }

  method scanmenu ($file) {

    open my $fh, '<:encoding(UTF-8)', $file or return $self;
    my @a = grep /^\[/, <$fh>;
    close $fh;

    # strip []
    grep {s/(\[|\])//g} @a;

    for my $item (@a) {
      $item =~ s/ *$//;
      my @b = split /--/, $item;
      for my $string (@b) {
        chomp $string;
        if ($string !~ /^\s*$/) {
          $texts{$string} = 1;
        }
      }
    }
  }
}
