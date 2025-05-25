#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2025
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Generator for QR Codes
#
#======================================================================
package SL::QRCode;

use strict;
use warnings;

use POSIX 'fmax';
use Text::QRCode;

sub plot_latex {
  my ($text, %param) = @_;

  $param{foreground} ||= 'black';
  $param{level}      ||= 'M';
  $param{margin}     ||= 0;
  $param{unit}       ||= 'mm';
  $param{version}    ||= 0;

  my @code = Text::QRCode->new(level => $param{level}, version => $param{version})->plot($text)->@*;

  $param{height} ||= @code + 2 * $param{margin};
  my $dotsize = ($param{height} - 2 * $param{margin}) / @code;

  my $n_max   = @code - 1;
  my (@elements, @dot);

  if ($param{background}) {
    push @elements, qq|  \\filldraw[draw=$param{background}, fill=$param{background}] (0,0) rectangle ($param{height},$param{height});|;
  }

  my $rect = sub {
    my ($x, $y, $width, $height) = @_;

    my $x1 = $x * $dotsize + $param{margin};
    my $y1 = ($n_max - $y) * $dotsize + $param{margin};
    my $x2 = $x1 + $width * $dotsize;
    my $y2 = $y1 + $height * $dotsize;

    push @elements, sprintf '  \filldraw (%0.3f,%0.3f) rectangle (%0.3f,%0.3f);', $x1, $y1, $x2, $y2;
  };

  my $add_dot = sub {
    if (@dot) {
      $rect->(@dot);
      @dot = ();
    }
  };

  for my $y (0 .. $n_max) {
    for my $x (0 .. $n_max) {
      if ($code[$y][$x] eq '*') {
        if (@dot) {
          $dot[2]++;
        } else {
          @dot = ($x, $y, 1, 1);
        }
      } else {
        $add_dot->();
      }
    }
    $add_dot->();
  }

  push @elements, $param{additional_elements}->@* if $param{additional_elements};
  
  my $latex
    = qq|\\begin{tikzpicture}[x=1$param{unit}, y=1$param{unit}, draw=$param{foreground}, fill=$param{foreground}]\n|
    . join("\n", @elements)
    . qq|\n\\end{tikzpicture}|;

  return $latex;
}

sub plot_svg {
  my ($text, %param) = @_;

  $param{background} ||= 'white';
  $param{dotsize}    ||= 1;
  $param{foreground} ||= 'black';
  $param{height}     ||= 0;
  $param{level}      ||= 'M';
  $param{margin}     ||= 2;
  $param{scale}      ||= 1;
  $param{version}    ||= 0;
  $param{width}      ||= 0;

  my @code = Text::QRCode->new(level => $param{level}, version => $param{version})->plot($text)->@*;

  my $vbwidth = my $vbheight = 0;
  my $x_max   = $code[0]->@* - 1;
  my $y_max   = @code - 1;

  my @elements = (qq|  <rect width="100%" height="100%" fill="$param{background}"/>|);
  my @dot;

  my $rect = sub {
    my ($x, $y, $width, $height) = @_;

    my $x1 = $x + $param{margin};
    my $y1 = $y + $param{margin};
    $vbwidth  = fmax $vbwidth,  $x1 + $width;
    $vbheight = fmax $vbheight, $y1 + $height;

    push @elements,
      qq|  <rect x="$x1" y="$y1" width="$width" height="$height" fill="$param{foreground}"/>|;

  };

  my $add_dot = sub {
    if (@dot) {
      $rect->(@dot);
      @dot = ();
    }
  };

  for my $y (0 .. $y_max) {
    for my $x (0 .. $x_max) {
      if ($code[$y][$x] eq '*') {
        if (@dot) {
          $dot[2] += $param{dotsize};
        } else {
          @dot = ($x * $param{dotsize}, $y * $param{dotsize}, $param{dotsize}, $param{dotsize});
        }
      } else {
        $add_dot->();
      }
    }
    $add_dot->();
  }

  $vbheight += $param{margin};
  $vbwidth  += $param{margin};

  my @attr = (qq|viewBox="0 0 $vbwidth $vbheight"|);

  my $height     = $vbheight * $param{scale};
  my $width      = $vbwidth * $param{scale};
  my $attributes = sprintf 'viewBox="0 0 %d %d" width="%d" height="%d"', $vbwidth, $vbheight,
    $param{width} || $vbwidth * $param{scale}, $param{height} || $vbheight * $param{scale};

  my $svg
    = qq|<svg $attributes xmlns="http://www.w3.org/2000/svg">\n|
    . join("\n", @elements)
    . qq|\n</svg>|;

  return $svg;
}

1;

=encoding utf8

=head1 NAME

SL::QRCode - Generator for QR Codes

=head1 SYNOPSIS

    use SL::QRCode;

    my %default_latex_params = (
      level               => 'M',
      version             => 0,
      background          => undef,
      foreground          => 'black',
      unit                => 'mm',
      height              => undef,     # calculated if not provided
      margin              => 0,
      additional_elements => undef,
    );

    my $latex = SL::QRCode::plot_latex($text, %default_latex_params, height => $height);

    my %default_svg_params = (
      level      => 'M',
      version    => 0,
      background => 'white',
      foreground => 'black',
      dotsize    => 1,
      width      => 0,
      height     => 0,
      margin     => 2,
      scale      => 1,
    );

    my $svg = SL::QRCode::plot_svg($text, %default_svg_params);

=head1 DESCRIPTION

L<SL::QRCode> provides functions to generate QR Codes.

=head1 DEPENDENCIES

L<SL::QRCode>

=over

=item * uses
L<Text::QRCode>

=back

=head1 FUNCTIONS

=head2 plot_latex

    my $latex = SL::QRCode::plot_latex($text, height => $height);
    my $latex = SL::QRCode::plot_latex($text, %params);
    my $latex = SL::QRCode::plot_latex($text, %params, additional_elements => \@el);

=head2 plot_svg

    my $svg = SL::QRCode::plot_svg($text);
    my $svg = SL::QRCode::plot_svg($text, %params);

=cut
