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
# routines for menu items
#
#=====================================================================

package Menu;

use SL::Inifile;
@ISA = qw/Inifile/;


sub menuitem {
  my ($self, $myconfig, $form, $item) = @_;

  my $module = ($self->{$item}{module}) ? $self->{$item}{module} : $form->{script};
  my $action = ($self->{$item}{action}) ? $self->{$item}{action} : "section_menu";
  my $target = ($self->{$item}{target}) ? $self->{$item}{target} : "";

  my $level = $form->escape($item);
  my $str = qq|<a href=$module?path=$form->{path}&action=$action&level=$level&login=$form->{login}&js=$form->{js}|;

  my @vars = qw(module action target href);
  
  if ($self->{$item}{href}) {
    $str = qq|<a href=$self->{$item}{href}|;
    @vars = qw(module target href);
  }

  for (@vars) { delete $self->{$item}{$_} }
  
  delete $self->{$item}{submenu};
 
  # add other params
  foreach my $key (keys %{ $self->{$item} }) {
    $str .= "&".$form->escape($key)."=";
    ($value, $conf) = split /=/, $self->{$item}{$key}, 2;
    $value = "$myconfig->{$value}$conf" if $self->{$item}{$key} =~ /=/;
    
    $str .= $form->escape($value);
  }

  $str .= qq|#id$form->{tag}| if $target eq 'acc_menu';
  
  if ($target) {
    $str .= qq| target=$target|;
  }
  
  $str .= qq|>|;
  
}


sub access_control {
  my ($self, $myconfig, $menulevel) = @_;
  
  my @menu = ();

  if ($menulevel eq "") {
    @menu = grep { !/--/ } @{ $self->{ORDER} };
  } else {
    @menu = grep { /^${menulevel}--/; } @{ $self->{ORDER} };
  }

  my @a = split /;/, $myconfig->{acs};
  my $excl = ();

  # remove --AR, --AP from array
  grep { ($a, $b) = split /--/; s/--$a$//; } @a;

  for (@a) { $excl{$_} = 1 }

  @a = ();
  for (@menu) { push @a, $_ unless $excl{$_} }

  @a;

}


1;

