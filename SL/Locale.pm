#=================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2025 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
use v5.40;

package SL::Locale;

use Storable;

sub new ($type, $country, $NLS_file) {
  my $self = {};

  if ($country && -d "locale/$country") {
    $self = retrieve "locale/$country/$NLS_file.bin";
    $self->{countrycode} = $country;
  }

  $self->{NLS_file} = $NLS_file;

  $self->{LONG_MONTH} = [
    'January', 'February', 'March',     'April',   'May ',     'June',
    'July',    'August',   'September', 'October', 'November', 'December'
  ];
  $self->{SHORT_MONTH} = [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)];

  return bless $self, $type;

}


sub text ($self, $text) {

  $text //= '';
  return  $self->{texts}{$text} // $text;

}


sub findsub ($self, $text) {

  return  $self->{subs}{$text} // $text;

}


sub date ($self, $myconfig, $date, $longformat = '') {
  return $date unless $myconfig->{dateformat};

  my $longdate = '';
  my $longmonth = $longformat ? 'LONG_MONTH' : 'SHORT_MONTH';

  if ($date) {
    my ($spc, $dd, $mm, $yy);

    # get separator
    $spc = $myconfig->{dateformat};
    $spc =~ s/\w//g;
    $spc = substr($spc, 0, 1);

    if ($date =~ /\D/) {
      if ($myconfig->{dateformat} =~ /^yy/) {
        ($yy, $mm, $dd) = split /\D/, $date;
      }
      if ($myconfig->{dateformat} =~ /^mm/) {
        ($mm, $dd, $yy) = split /\D/, $date;
      }
      if ($myconfig->{dateformat} =~ /^dd/) {
        ($dd, $mm, $yy) = split /\D/, $date;
      }
    } else {
      if (length $date > 6) {
        ($yy, $mm, $dd) = ($date =~ /(....)(..)(..)/);
      } else {
        ($yy, $mm, $dd) = ($date =~ /(..)(..)(..)/);
      }
    }

    $dd *= 1;
    $yy += 2000 if length $yy == 2;

    if ($myconfig->{dateformat} =~ /^dd/) {
      $dd = substr("0$dd", -2);
      $mm = substr("0$mm", -2);
      $longdate = "$dd$spc$mm$spc$yy";

      if ($longformat ne "") {
        $longdate = "$dd";
        $longdate .= ($spc eq '.') ? ". " : " ";
        $longdate .= &text($self, $self->{$longmonth}[$mm - 1])." $yy";
      }
    } elsif ($myconfig->{dateformat} =~ /^yy/) {
      $dd = substr("0$dd", -2);
      $mm = substr("0$mm", -2);
      $longdate = "$yy$spc$mm$spc$dd";

      if ($longformat ne "") {
        $longdate = $self->text($self->{$longmonth}[$mm - 1])." $dd $yy";
      }
    } else {
      $dd = substr("0$dd", -2);
      $mm = substr("0$mm", -2);
      $longdate = "$mm$spc$dd$spc$yy";

      if ($longformat ne "") {
        $longdate = $self->text($self->{$longmonth}[$mm - 1])." $dd $yy";
      }
    }
  }

  return $longdate;

}


1;

=encoding utf8

=head1 NAME

SL::Locale - Translation module

=head1 DESCRIPTION

L<SL::Locale> contains the translation module.


=head1 CONSTRUCTOR

L<SL::Locale> uses the following constructor:

=head2 new

  $locale = SL::Locale->new($country, $NLS_file);

=head1 METHODS

L<SL::Locale> implements the following methods:

=head2 date

  $locale->date($myconfig, $date, $longformat);

=head2 findsub

  $locale->findsub($text);

=head2 text

  $locale->text($text);

=cut
