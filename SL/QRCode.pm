#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2025
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Generator and decoder for QR Codes
#
#======================================================================
package SL::QRCode;

use strict;
use warnings;

use POSIX 'fmax';

sub decode_file {
  my ($path, %param) = @_;

  require Imager::zxing;

  my %rv;

  unless (-f $path) {
    %rv = (result => 'error', errstr => "File not found: $path");
    return \%rv;
  }

  my $decoder = Imager::zxing::Decoder->new;
  $decoder->set_formats('QRCode');

  my $source;

  if ($path =~ /\.pdf$/) {
    require Image::Magick;
    my $im = Image::Magick->new;

    my $err = $im->Read($path);
    if ($err) {
      %rv = (result => 'error', errstr => "$err");
      return \%rv;
    }

    my $page = $im->[($param{page} // 1) - 1];
    my $im_data
      = $param{no_flatten}
      ? $page->ImageToBlob(magick => 'png')
      : $page->Flatten->ImageToBlob(magick => 'png');

    $source = Imager->new(data => $im_data, type => 'png');

    for (qw|left width|) {
      $param{$_} = $source->getwidth * $param{$_} / 100 if $param{$_};
    }
    for (qw|top height|) {
      $param{$_} = $source->getheight * $param{$_} / 100 if $param{$_};
    }
  } else {
    $source = Imager->new(file => $path);
  }

  unless ($source) {
    %rv = (result => 'error', errstr => "Unable to read $path: ". Imager->errstr);
    return \%rv;
  }

  if ($param{left} || $param{top} || $param{width} || $param{height}) {
    my %args = (
      left   => $param{left}   || 0,
      top    => $param{top}    || 0,
      width  => $param{width}  || $source->getwidth -  ($param{left} || 0),
      height => $param{height} || $source->getheight - ($param{top}  || 0),
    );

    $source = $source->crop(%args);
  }

  my @results = $decoder->decode($source);
  unless (@results) {
    %rv = (result => 'error', errstr => 'No code found');
    return \%rv;
  }

  %rv = (
    result => 'ok',
    data   => $results[0]->text,
  );

  return \%rv;
}

sub decode_qrbill {
  my ($path, $page) = @_;

  my %param;

  if ($path =~ /\.pdf$/) {
    %param = (
      page   => $page // 0,
      left   => 6200 / 210,
      top    => 20400 / 297,
      width  => 5700 / 210,
      height => 5700 / 297,
    );
  }

  my $rv = &decode_file($path, %param);
  if ($rv->{result} eq 'error' && $path =~ /\.pdf$/) {
    $param{no_flatten} = 1;
    $rv = &decode_file($path, %param);
  }
  return $rv if $rv->{result} eq 'error';

  $rv->{data} =~ s/\r//g;
  unless ($rv->{data} =~ /^SPC\n0200\n1/) {
    $rv->{result} = 'error';
    $rv->{errstr} = 'Not a QR Bill';
    return $rv;
  }

  my @data = split /\n/, $rv->{data};
  my %structured = (
    amount   => ($data[18] || 0) * 1,
    currency => $data[19],
    dcn      => $data[28],
    qriban   => $data[3],
  );

  my %pos = (vendor => 4, recipient => 20);
  for my $key (keys %pos) {
    my $offset = $pos{$key};

    $structured{$key}{name}    = $data[$offset + 1];
    $structured{$key}{country} = $data[$offset + 6];

    if ($data[$offset] eq 'S') {

      $structured{$key}{streetname}     = $data[$offset + 2];
      $structured{$key}{buildingnumber} = $data[$offset + 3];
      $structured{$key}{zipcode}        = $data[$offset + 4];
      $structured{$key}{city}           = $data[$offset + 5];

    } else {

      ($structured{$key}{streetname}, $structured{$key}{buildingnumber})
        = $data[$offset + 2] =~ /(.*)\s+(\d.*)/;
      unless ($structured{$key}{streetname}) {
        $structured{$key}{address1} = $data[$offset + 2];
      }

      ($structured{$key}{zipcode}, $structured{$key}{city}) = $data[$offset + 3] =~ /(\d+)\s+(.*)/;
    }
  }

  if ($data[31] && $data[31] =~ qr|^//S1/(.+)|) {
    my %alt = split /\//, $1;

    if ($alt{10}) {
      $structured{invnumber} = $alt{10};
    }

    if ($alt{11}) {
      $structured{transdate} = "20$alt{11}";
    }

    if ($alt{40} && $alt{40} =~ /0:(\d+)/) {
      $structured{terms} = $1 * 1;
    }

    if ($alt{30} && $alt{30} =~ /(\d{3})(\d{3})(\d{3})/) {
      $structured{vendor}{taxnumber} = "CHE-$1.$2.$3";
      $structured{vendor}{taxnumber} .= ' MWST' if $alt{31};
    }
  }

  $rv->{structured_data} = \%structured;

  return $rv;
}

sub plot_latex {
  my ($text, %param) = @_;

  require Text::QRCode;

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

  require Text::QRCode;

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

    my $res = SL::QRCode::decode_file($path, %params);

    my $res = SL::QRCode::decode_qrbill($path, $page);

    my $latex = SL::QRCode::plot_latex($text, %params, height => $height);

    my $svg = SL::QRCode::plot_svg($text, %params);

=head1 DESCRIPTION

L<SL::QRCode> provides functions to generate QR Codes.

=head1 DEPENDENCIES

L<SL::QRCode>

=over

=item * requires
L<Text::QRCode> for generator,
L<Image::Magick>,
L<Imager::zxing> for decoder

=back

=head1 FUNCTIONS

=head2 decode_file

    my %default_params = (
      left       => 0,
      top        => 0,
      width      => undef,    # calculated
      height     => undef,    # calculated
      page       => 1,        # for PDF, 0 = last
      no_flatten => 0,        # for PDF
    );

    my $res = SL::QRCode::decode_file($path, %params);

=head2 decode_qrbill

    my $res = SL::QRCode::decode_qrbill($path);          # last page
    my $res = SL::QRCode::decode_qrbill($path, $page);

=head2 plot_latex

    my %default_params = (
      level               => 'M',
      version             => 0,
      background          => undef,
      foreground          => 'black',
      unit                => 'mm',
      height              => undef,     # recommended, calculated if not provided
      margin              => 0,
      additional_elements => undef,
    );

    my $latex = SL::QRCode::plot_latex($text, height => $height);
    my $latex = SL::QRCode::plot_latex($text, %params);
    my $latex = SL::QRCode::plot_latex($text, %params, additional_elements => \@el);

=head2 plot_svg

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

    my $svg = SL::QRCode::plot_svg($text);
    my $svg = SL::QRCode::plot_svg($text, %params);

=cut
