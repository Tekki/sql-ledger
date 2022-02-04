#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2022
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Spreadsheet Module
#
#======================================================================
package SL::Spreadsheet;

use strict;
use warnings;

use List::Util qw|max min|;
use Scalar::Util 'looks_like_number';

# constructor

sub new {
  my ($class, $form, $userspath) = @_;
  my %self = (
    _form        => $form,
    col          => 0,
    column_index => [],
    date_length  => 14,
    height       => {
      title        => 23.25,
    },
    maxwidth   => 40,
    row        => 0,
    structure  => {},
    url_params => qq|&path=$form->{path}&login=$form->{login}|,
    width      => [],
  );

  ($self{url}) = $ENV{HTTP_REFERER} =~ /(.+?)\/[a-z]+\.pl/;

  $form->{tmpfile} = "$userspath/" . time . "$$.xlsx";
  $self{workbook} = Excel::Writer::XLSX->new($form->{tmpfile})
    or $form->error("$form->{tmpfile}: $!");
  $self{worksheet} = $self{workbook}->add_worksheet;

  my $localized_date    = 14;
  my $localized_decimal = 4;
  my %formats = (
    default  => {font => 'Calibri', size => 11,},
    heading3 => {
      align        => 'center',
      bold         => 1,
      border_color => '#8EA9DB',
      bottom       => 2,
      color        => '#44546A',
      font         => 'Calibri',
      size         => 11,
    },
    heading4 => {
      align => 'center',
      bold  => 1,
      color => '#44546A',
      font  => 'Calibri',
      size  => 11,
    },
    subsubtotal => {
      bold         => 1,
      font         => 'Calibri',
      size         => 11,
    },
    subtotal => {
      bold         => 1,
      border_color => '#4472C4',
      bottom       => 1,
      font         => 'Calibri',
      size         => 11,
      top          => 1,
    },
    total => {
      bold         => 1,
      border_color => '#4472C4',
      bottom       => 6,
      font         => 'Calibri',
      size         => 11,
      top          => 1,
    },
  );
  $self{format}
    = {
    title => $self{workbook}->add_format(font => 'Calibri Light', size => 18, color => '#44546A'),
    };

  for my $format (keys %formats) {
    my %settings = %{$formats{$format}};
    $self{format}{"${format}_text"}   = $self{workbook}->add_format(%settings);
    $self{format}{"${format}_bool"}
      = $self{workbook}->add_format(%settings, align => 'center');
    $self{format}{"${format}_date"}
      = $self{workbook}->add_format(%settings, num_format => $localized_date);
    $self{format}{"${format}_decimal"}
      = $self{workbook}->add_format(%settings, num_format => $localized_decimal);
    $self{format}{"${format}_link"}
      = $self{workbook}->add_format(%settings, color => 'blue', underline => 1);
  }

  return bless \%self, $class;
}

# methods

sub bool {
  my ($self, $bool, $format) = @_;
  $format ||= 'default';

  $self->{worksheet}->write_string(
    $self->{row}, $self->{col},
    $bool ? "\x{00D7}" : '',
    $self->{format}{"${format}_bool"},
  );

  return $self;
}

sub column_index {
  my ($self, $newvalue) = @_;
  if (defined $newvalue) {
    $self->{column_index} = $newvalue;
    $self->{maxcol} = scalar @$newvalue;

    return $self;
  } else {
    return $self->{column_index};
  }
}

sub crlf {
  my ($self, $times) = @_;

  $self->{row} += $times // 1;
  $self->{col} = 0;

  return $self;
}

sub data_row {
  my ($self, $row, %params) = @_;

  my $default_type = $params{default_type} || 'decimal';
  my $format       = $params{format}       || 'default';
  my $rowtype      = $params{rowtype}      || 'data';
  my $scale        = $params{scale}        || 1;
  my $structure    = $params{structure}    || 'columns';

  if (my $fn = $self->{structure}{"init_$rowtype"}) {
    &$fn($row);
  }

  if ( $params{subtotal}
    && $self->{structure}{group_by}
    && $self->{lastid}
    && $self->{lastid} ne $row->{$self->{structure}{group_by}})
  {
    $self->subtotal_row;
  }

  if ($self->{total} && $rowtype eq 'data') {

    for (keys %{$self->{total}}) {
      if (looks_like_number($row->{$_})) {
        $self->{total}{$_}    += $row->{$_};
        $self->{subtotal}{$_} += $row->{$_};
      }
    }

    $self->{lastid} = $row->{$self->{structure}{group_by}} if $self->{structure}{group_by};
    $self->{subtotalcount}++;
  }

  $self->{col} = 0;
  for my $column (@{$self->{column_index}}) {
    my $type = $self->{structure}{$structure}{$column} || $default_type;

    my $value = $row->{$column};
    unless (defined $value) {
      $self->text('', $format);
      next;
    }

    if ($type eq 'text') {

      $self->text($value, $format)->set_width(length($value) * $scale + 2);

    } elsif ($type eq 'date') {

      $self->date($value, $format)->set_width($self->{date_length} * $scale);

    } elsif ($type eq 'link') {

      $self->link(qq|$self->{url}/$row->{"${column}_link"}$self->{url_params}|, $value, $format)
        ->set_width(length($value) * $scale + 2);

    } elsif ($type eq 'bool') {

      $self->bool($value, $format);

    } else {

      $self->$type($value, $format)->set_width(length($value) * $scale + 2);

    }
  } continue {
    $self->{col}++;
  }

  $self->crlf;

  return $self;
}

sub date {
  my ($self, $date, $format) = @_;
  
  $format ||= 'default';

  $date =~ s/(\d{4})(\d{2})/$1-$2-/;
  $self->{worksheet}
    ->write_date_time($self->{row}, $self->{col}, "${date}T", $self->{format}{"${format}_date"});

  return $self;
}

sub decimal {
  my ($self, $decimal, $format) = @_;
  $format ||= 'default';

  if (looks_like_number($decimal)) {
    $self->{worksheet}
      ->write_number($self->{row}, $self->{col}, $decimal, $self->{format}{"${format}_decimal"});
  } else {
    $self->{worksheet}
      ->write_string($self->{row}, $self->{col}, '', $self->{format}{"${format}_decimal"});
  }

  return $self;
}

sub finish {
  my ($self) = @_;
  
  for (0 .. $#{$self->{width}}) {
    my $width = $self->{width}[$_] || next;
    $self->{worksheet}->set_column($_, $_, min($width, $self->{maxwidth}));
  }

  $self->{workbook}->close;

  return $self;
}

sub freeze_panes {
  my ($self, $row, $col) = @_;

  $self->{worksheet}->freeze_panes($row // $self->{row}, $col // $self->{col});

  return $self;
}

sub header_row {
  my ($self, $header, %params) = @_;

  my %data;
  if ($params{parse}) {
    for my $column (@{$self->{column_index}}) {
      ($data{$column}) = $header->{$column} =~ /.*>([^<]+)</;
      $data{$column} =~ s/&nbsp;/ /g;
    }
  }
  else {
    %data = (%$header);
  }

  $params{default_type} ||= 'text';
  $params{format}       ||= 'heading3';
  $params{rowtype}      ||= 'header';
  $params{scale}        ||= 1.2;
  $params{structure}    ||= 'header';

  $self->data_row(\%data, %params);

  return $self;
}

sub lf {
  my ($self, $times) = @_;

  $self->{row} += $times // 1;

  return $self;
}

sub link {
  my ($self, $url, $text, $format) = @_;
  $text   ||= $url;
  $format ||= 'default';

  $self->{worksheet}
    ->write_url($self->{row}, $self->{col}, $url, $self->{format}{"${format}_link"}, $text);

  return $self;
}

sub maxwidth {
  $_[0]->_get_set('maxwidth', $_[1]);
}

sub number {
  my ($self, $number, $format) = @_;
  $format ||= 'default';

  if (looks_like_number($number)) {
    $self->{worksheet}
      ->write_number($self->{row}, $self->{col}, $number, $self->{format}{"${format}_text"});
  } else {
    $self->{worksheet}
      ->write_string($self->{row}, $self->{col}, '', $self->{format}{"${format}_text"});
  }

  return $self;
}

sub report_options {
  my ($self, $options) = @_;

  if ($options) {
    $options =~ s/<br>//g;
    $options =~ s/&nbsp;/ /g;

    $self->crlf->text($_) for split /\n/, $options;
    $self->crlf;
  }

  return $self;
}

sub reset_width {
  my ($self) = @_;

  $self->{width} = [];

  return $self;
}

sub set_width {
  my ($self, $width) = @_;

  $self->{width}[$self->{col}] //= 0;
  $self->{width}[$self->{col}] = max $self->{width}[$self->{col}], $width;

  return $self;
}

sub structure {
  $_[0]->_get_set('structure', $_[1]);
}

sub subtotal_row {
  my ($self, %params) = @_;

  my $group = $self->{structure}{group_by};
  if ( $self->{_form}{l_subtotal}
    && $self->{subtotalcount})
  {
    $params{format}  ||= 'subtotal';
    $params{rowtype} ||= 'total';

    $self->data_row($self->{subtotal}, %params);
    delete $self->{subtotal};
  }

  return $self;
}

sub tab {
  my ($self, $times) = @_;

  $self->{col} += $times // 1;

  return $self;
}

sub text {
  my ($self, $text, $format) = @_;

  $format ||= 'default';

  $self->{worksheet}
    ->write_string($self->{row}, $self->{col}, $text, $self->{format}{"${format}_text"});

  return $self;
}

sub title {
  my ($self, $text) = @_;

  $self->{worksheet}
    ->write_string($self->{row}, $self->{col}, $text, $self->{format}{title});

  $self->{worksheet}->set_row($self->{row}, $self->{height}{title});

  return $self;
}

sub total_row {
  my ($self, %params) = @_;

  $params{format}  ||= 'total';
  $params{rowtype} ||= 'total';
  $params{scale}   ||= 1.2;

  $self->data_row($self->{total}, %params);

  return $self;
}

sub totalize {
  my ($self, $newvalues) = @_;
  if (defined $newvalues) {
    $self->{totalize} = $newvalues;

    delete $self->{$_} for qw|total subtotal subtotalcount|;
    for my $val (@$newvalues) {
      if ($val eq ':decimal') {

        for my $column (@{$self->{column_index}}) {
          if (!$self->{structure}{columns}{$column}
            || $self->{structure}{columns}{$column} eq 'decimal')
          {
            $self->{total}{$column} = 0;
          }
        }

      } else {
        $self->{total}{$val} = 0;
      }
    }

    return $self;
  } else {
    return $self->{totalize};
  }
}

# internal methods

sub _get_set {
  my ($self, $fld, $newvalue) = @_;

  if (defined $newvalue) {
    $self->{$fld} = $newvalue;
    return $self;
  } else {
    return $self->{$fld};
  }
}

1;

=encoding utf8

=head1 NAME

SL::Spreadsheet - Spreadsheet Module

=head1 SYNOPSIS

    use SL::Spreadsheet;

    my $ss = SL::Spreadsheet->new($form, $userspath);

    my %spreadsheet_info = (
      columns  => {},
      group_by => $field,
    );
    $ss->structure(\%spreadsheet_info);
    $ss->column_index(\@index);
    $ss->totalize(\@columns);

    $ss->title($title, $format);
    $ss->report_options($options);

    $ss->tab;
    $ss->lf;
    $ss->crlf;
    $ss->maxwidth($maxwidth);
    $ss->set_width($width);

    $ss->bool($bool, $format);
    $ss->date($date, $format);
    $ss->decimal($decimal, $format);
    $ss->link($url, $text, $format);
    $ss->number($number, $format);
    $ss->text($text, $format);

    $ss->header_row(\%header);
    $ss->freeze_panes;
    $ss->data_row(\%data);
    $ss->subtotal_row;
    $ss->total_row;

    $ss->finish;

    $form->download_tmpfile('application/vnd.ms-excel', "$filename.xlsx");

=head1 DESCRIPTION

L<SL::Spreadsheet> is the backend to create spreadsheets.

=head1 DEPENDENCIES

L<SL::Spreadsheet>

=over

=item * uses
L<Excel::Writer::XLSX>,
L<List::Util>,
L<Scalar::Util>

=back

=head1 CONSTRUCTOR

=head2 new

  $ss = SL::Spreadsheet->new($form, $userspath);

=head1 METHODS

=head2 bool

  $ss = $ss->bool($bool);
  $ss = $ss->bool($bool, $format);

=head2 column_index

  $ss    = $ss->column_index(\@index);
  $index = $ss->column_index;

=head2 crlf

  $ss = $ss->crlf;
  $ss = $ss->crlf($times);

=head2 data_row

  $ss = $ss->data_row(\%data);
  $ss = $ss->data_row(\%data, %params);

=head2 date

  $ss = $ss->date($date);
  $ss = $ss->date($date, $format);

=head2 decimal

  $ss = $ss->decimal($decimal);
  $ss = $ss->decimal($decimal, $format);

=head2 finish

  $ss = $ss->finish;

=head2 freeze_panes

  $ss = $ss->freeze_panes;
  $ss = $ss->freeze_panes($row, $col);

=head2 header_row

  $ss = $ss->header_row(\%data);
  $ss = $ss->header_row(\%data, %params);

=head2 lf

  $ss = $ss->lf;
  $ss = $ss->lf($times);

=head2 link

  $ss = $ss->link($link);
  $ss = $ss->link($link, $text);
  $ss = $ss->link($link, $text, $format);

=head2 maxwidth

  $ss       = $ss->maxwidth($maxwidth);
  $maxwidth = $ss->maxwidth;

=head2 number

  $ss = $ss->number($number);
  $ss = $ss->number($number, $format);

=head2 report_options

  $ss = $ss->report_options($options);

=head2 reset_width

  $ss = $ss->reset_width;

=head2 set_width

  $ss = $ss->set_width($width);

=head2 structure

  $ss = $ss->structure(\%spreadsheet_info);

=head2 tab

  $ss = $ss->tab;
  $ss = $ss->tab($times);

=head2 text

  $ss = $ss->text($text);
  $ss = $ss->text($text, $format);

=head2 total_row

  $ss = $ss->total_row;
  $ss = $ss->total_row(%params);

=head2 totalize

  $ss      = $ss->totalize(\@columns);
  $columns = $ss->totalize;

=head2 title

  $ss = $ss->title($text);
  $ss = $ss->title($text, $format);

=cut
