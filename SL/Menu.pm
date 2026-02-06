#======================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
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

sub _url ($form, $s) {
  $s = '' if !defined $s;
  return $form->escape($s, 1);
}

sub _ha ($s) {
  $s = '' if !defined $s;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/>/&gt;/g;
  $s =~ s/"/&quot;/g;
  return $s;
}


sub menuitem ($self, $myconfig, $form, $item, $) {

  my $module = ($self->{$item}{module}) ? $self->{$item}{module} : $form->{script};
  my $action = ($self->{$item}{action}) ? $self->{$item}{action} : "section_menu";
  my $target = ($self->{$item}{target}) ? $self->{$item}{target} : "";

  my $legacy = $self->{$item}{jsmenu} ? 1 : 0;

  my $href = $module
    . '?path='  . _url($form, $form->{path})
    . '&action='. _url($form, $action)
    . '&level=' . _url($form, $item)
    . '&login=' . _url($form, $form->{login})
    . '&js='    . _url($form, $form->{js});

  my $str;

  my @vars = qw(module action target href);

  if ($self->{$item}{href}) {
    $href = $self->{$item}{href};
    @vars = qw(module target href);
  }

  for (@vars) { delete $self->{$item}{$_} }

  delete $self->{$item}{submenu};

  foreach my $key (keys %{ $self->{$item} // {} }) {
    $href .= "&" . _url($form, $key) . "=";
    my ($value, $conf) = split /=/, $self->{$item}{$key}, 2;
    $value = "$myconfig->{$value}$conf" if $self->{$item}{$key} =~ /=/;

    $href .= _url($form, $value);
  }

  my $tag = $form->{tag} // 0;
  $href .= qq|#id$tag| if $target eq 'acc_menu' && !$form->{js};

  if ($legacy) {
    $str = qq|<a href=$href|;
    $str .= qq| target=$target| if $target;
    $str .= qq|>|;
    return $str;
  }

  my $href_html = _ha($href);
  $str = qq|<a href="$href_html"|;

  if ($target) {
    my $t_html = _ha($target);
    $str .= qq| target="$t_html"|;
    $str .= qq| rel="noopener noreferrer"| if $target eq '_blank';
  }

  $str .= qq|>|;
  return $str;

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
