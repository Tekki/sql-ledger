#======================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# routines to retrieve / manipulate win ini style files
# ORDER is used to keep the elements in the order they appear in .ini
#
#======================================================================
use v5.40;

package SL::Inifile;


sub new ($type, $file) {

  $type = ref($type) || $type;
  my $self = bless {}, $type;
  $self->add_file($file) if defined $file;

  return $self;
}


sub add_file ($self, $file) {

  my $id = "";
  my %menuorder = ();

  for (@{$self->{ORDER}}) { $menuorder{$_} = 1 }

  open my $fh, '<:encoding(UTF-8)', "$file" or SL::Form->error("$file : $!");

  while (<$fh>) {
    next if /^(#|;|\s)/;
    last if /^\./;

    chop;

    # strip comments
    s/\s*(#|;).*//g;

    # remove any trailing whitespace
    s/^\s*(.*?)\s*$/$1/;

    if (/^\[/) {
      s/(\[|\])//g;
      $id = $_;
      push @{$self->{ORDER}}, $_ if ! $menuorder{$_};
      $menuorder{$_} = 1;
      next;
    }

    # add key=value to $id
    my ($key, $value) = split /=/, $_, 2;

    $self->{$id}{$key} = $value;

  }
  close $fh;

}


1;


=encoding utf8

=head1 NAME

SL::Inifile - Routines to retrieve / manipulate win ini style files

=head1 DESCRIPTION

L<SL::Inifile> contains the routines to retrieve / manipulate win ini style files,
ORDER is used to keep the elements in the order they appear in .ini.

=head1 CONSTRUCTOR

L<SL::Inifile> uses the following constructor:

=head2 new

  $inifile = SL::Inifile->new($file);

=head1 METHODS

L<SL::Inifile> implements the following methods:

=head2 add_file

  $inifile->add_file($file);

=cut
