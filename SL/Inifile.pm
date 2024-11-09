#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#=====================================================================
#
# routines to retrieve / manipulate win ini style files
# ORDER is used to keep the elements in the order they appear in .ini
#
#=====================================================================

package Inifile;


sub new {
  my ($type, $file) = @_;

  $type = ref($type) || $type;
  my $self = bless {}, $type;
  $self->add_file($file) if defined $file;

  return $self;
}


sub add_file {
  my ($self, $file) = @_;

  my $id = "";
  my %menuorder = ();

  for (@{$self->{ORDER}}) { $menuorder{$_} = 1 }

  open(FH, '<:utf8', "$file") or Form->error("$file : $!");

  while (<FH>) {
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
  close FH;

}


1;


=encoding utf8

=head1 NAME

Inifile - Routines to retrieve / manipulate win ini style files

=head1 DESCRIPTION

L<SL::Inifile> contains the routines to retrieve / manipulate win ini style files,
ORDER is used to keep the elements in the order they appear in .ini.

=head1 CONSTRUCTOR

L<SL::Inifile> uses the following constructor:

=head2 new

  $inifile = Inifile->new($file);

=head1 METHODS

L<SL::Inifile> implements the following methods:

=head2 add_file

  $inifile->add_file($file);

=cut
