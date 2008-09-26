#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2002
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
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
  
  my $id = "";

  $self ||= {};
  $type = ref($self) || $self;
  
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
      push @{$self->{ORDER}}, $_;
      next;
    }

    # add key=value to $id
    my ($key, $value) = split /=/, $_, 2;
    
    $self->{$id}{$key} = $value;

  }
  close FH;
  
  bless $self, $type;
  
}


1;

