1;

sub pg_dump {

  my @t = localtime;
  $t[4]++;
  $t[5] += 1900;
  $t[3] = substr("0$t[3]", -2);
  $t[4] = substr("0$t[4]", -2);

  my $boundary = time;
  my $tmpfile
    = "$userspath/$boundary.$myconfig{dbname}-$form->{version}-$t[5]$t[4]$t[3].dump";

  my @args = ('pg_dump');
  if ($myconfig{dbpasswd}) {
    push @args,
      "--dbname=postgresql://$myconfig{dbuser}:$myconfig{dbpasswd}\@/$myconfig{dbname}";
  } else {
    push @args, '-U', $myconfig{dbuser}, $myconfig{dbname};
  }
  push @args, '-f', $tmpfile;
  system(@args) == 0 or $form->error("$args[0] : $?");

  if ($gzip) {
    my @args = split / /, $gzip;
    my @s = @args;

    push @args, "$tmpfile";
    system(@args) == 0 or $form->error("$args[0] : $?");

    shift @s;
    my %s = @s;
    $suffix = ${-S} || ".gz";
    $tmpfile .= $suffix;
  }

  open(IN,  "$tmpfile") or $form->error("$tmpfile : $!");
  open(OUT, ">-")       or $form->error("STDOUT : $!");

  print OUT qq|Content-Type: application/file;
Content-Disposition: attachment; filename=$myconfig{dbname}-$form->{version}-$t[5]$t[4]$t[3].dump$suffix\n\n|;

  binmode(IN);
  binmode(OUT);

  while (<IN>) {
    print OUT $_;
  }

  close(IN);
  close(OUT);

  unlink "$tmpfile";
}
