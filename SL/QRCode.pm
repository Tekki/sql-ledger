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

use POSIX 'fmax';
use Text::QRCode;

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

    my %default_params = (
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

    my $svg = SL::QRCode::plot_svg($text, %default_params);

=head1 DESCRIPTION

L<SL::QRCode> provides functions to generate QR Codes.

=head1 DEPENDENCIES

L<SL::QRCode>

=over

=item * uses
L<Text::QRCode>

=back

=head1 FUNCTIONS

=head2 plot_svg

    my $svg = SL::QRCode::plot_svg($text);
    my $svg = SL::QRCode::plot_svg($text, %params);

=cut
