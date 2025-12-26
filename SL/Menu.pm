#======================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2025 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# routines for menu items
#
#======================================================================
use v5.40;

package SL::Menu;

use SL::Inifile;
use parent 'SL::Inifile';


sub menuitem ($self, $myconfig, $form, $item, $) {

  my $module = ($self->{$item}{module}) ? $self->{$item}{module} : $form->{script};
  my $action = ($self->{$item}{action}) ? $self->{$item}{action} : "section_menu";
  my $target = ($self->{$item}{target}) ? $self->{$item}{target} : "";

  my $level = $form->escape($item);
  my $login = $form->{login};
  $login =~ s/ /\%20/;

  my $str = qq|<a href=$module?path=$form->{path}&action=$action&level=$level&login=$login&js=$form->{js}|;

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
    my ($value, $conf) = split /=/, $self->{$item}{$key}, 2;
    $value = "$myconfig->{$value}$conf" if $self->{$item}{$key} =~ /=/;

    $str .= $form->escape($value);
  }

  $str .= qq|#id$form->{tag}| if $target eq 'acc_menu';

  if ($target) {
    $str .= qq| target=$target|;
  }

  $str .= qq|>|;

}


sub access_control ($self, $myconfig, $menulevel) {

  my @menu = ();
  $menulevel //= '';

  if ($menulevel eq "") {
    @menu = grep { !/--/ } @{ $self->{ORDER} };
  } else {
    @menu = grep { /^${menulevel}--/; } @{ $self->{ORDER} };
  }

  my @acs = split /;/, $myconfig->{acs} // '';
  my %excl = ();

  grep { ($a, $b) = split /--/; s/--$a$//; } @acs;
  for (@acs) { $excl{$_} = 1 }
  @acs = ();

  my @item;
  my $acs;
  my $n;

  for (@menu) {
    $acs = "";
    $n = 0;
    for my $item (split /--/, $_) {
      $acs .= $item;
      if ($excl{$acs}) {
        $n = 1;
        last;
      }
      $acs .= "--";
    }
    next if $n;

    push @acs, $_;

  }

  @acs;

}


1;


=encoding utf8

=head1 NAME

SL::Menu - Routines for menu items

=head1 DESCRIPTION

L<SL::Menu> contains the routines for menu items.

=head1 METHODS

L<SL::Menu> implements all methods from L<SL::Inifile> and the following new ones:

=head2 access_control

  $menu->access_control($myconfig, $menulevel);

=head2 menuitem

  $menu->menuitem($myconfig, $form, $item);

=cut
