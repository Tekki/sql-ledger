#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2002
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors: Tony Fraser <tony@sybaspace.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#=====================================================================
#
# routines to retrieve / manipulate win ini style files
# ORDER is used to keep the elements in the order they appear in .ini
#
#=====================================================================

package Inifile;


sub new {
  my ($type, $file) = @_;

  warn "$type has no copy constructor! creating a new object." if ref($type);
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
  
  open FH, "$file" or Form->error("$file : $!");

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

