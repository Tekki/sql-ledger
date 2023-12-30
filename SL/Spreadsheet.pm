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
    column_index => [],
    date_length  => 14,
    group_count  => {},
    group_by     => [],
    group_label  => {},
    group_title  => {},
    height       => {
      title => 23.25,
    },
    maxwidth   => 40,
    structure  => {},
    url_params => qq|&path=$form->{path}&login=$form->{login}|,
    width      => [],
  );

  ($self{url}) = $ENV{HTTP_REFERER} =~ /(.+?)\/[a-z]+\.pl/;

  $form->{tmpfile} = "$userspath/" . time . "$$.xlsx";
  $self{workbook} = Excel::Writer::XLSX->new($form->{tmpfile})
    or $form->error("$form->{tmpfile}: $!");

  my $localized_date    = 14;
  my $localized_decimal = 4;
  my %formats = (
    default  => {font => 'Calibri', size => 11,},
    group_title => {
      bold         => 1,
      border_color => '#4472C4',
      font         => 'Calibri',
      size         => 11,
    },
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
    my %settings = $formats{$format}->%*;
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

sub adjust_columns {
  my ($self) = @_;

  for (0 .. $#{$self->{width}}) {
    my $width = $self->{width}[$_] || next;
    $self->{worksheet}->set_column($_, $_, min($width, $self->{maxwidth}));
  }

  return $self;
}

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

sub change_format {
  my ($self, $name, %properties) = @_;

  my $filter = $name eq ':all' ? '.*' : "^${name}_";

  for my $format (grep /$filter/, keys $self->{format}->%*) {
    $self->{format}{$format}->set_format_properties(%properties);
  }

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

  $self->{col} = 0;
  for my $column ($self->{column_index}->@*) {
    my $type = $self->{structure}{$structure}{$column} || $default_type;

    my $value = $row->{$column};
    unless (defined $value) {
      $self->text('', $format);
      next;
    }

    if ($type eq 'text') {

      $self->text($value, $format)->set_width(length($value) * $scale + 2);

    } elsif ($type eq 'date') {

      if ($value =~ /\d{4}-?\d{2}-?\d{2}/) {
        $self->date($value, $format)->set_width($self->{date_length} * $scale);
      } else {
        $self->text($value, $format)->set_width(length($value) * $scale + 2);
      }

    } elsif ($type eq 'link') {

      if (my $link = $row->{"${column}_link"}) {
        if ($link =~ /^[a-z]+\.pl/) {
          $link = qq|$self->{url}/$link$self->{url_params}|;
        }

        $self->link($link, $value, $format)->set_width(length($value) * $scale + 2);
      } else {
        $self->text($value, $format)->set_width(length($value) * $scale + 2);
      }

    } elsif ($type eq 'email') {

      $self->link("mailto:$value", $value, $format)->set_width(length($value) * $scale + 2);

    } elsif ($type eq 'bool') {

      $self->bool($value, $format);

    } else {

      $self->$type($value, $format);

      if ($value) {
        my $length = $type =~ /decimal/ ? length(sprintf "%.2f", $value) : length($value);
        $self->set_width($length * $scale + 2);
      }

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

  $self->{workbook}->close;

  return $self;
}

sub freeze_panes {
  my ($self, $row, $col) = @_;

  $self->{worksheet}->freeze_panes($row // $self->{row}, $col // $self->{col});

  return $self;
}

sub group_by {
  my ($self, $newvalues) = @_;

  if (defined $newvalues) {
    $self->{group_by} = $newvalues;

    return $self;
  } else {
    return $self->{group_by};
  }
}

sub group_label {
  my ($self, $newvalues) = @_;

  if (defined $newvalues) {
    $self->{group_label} = {};
    $self->{group_label}{$_} = 1 for $newvalues->@*;

    return $self;
  } else {
    return [sort keys $self->{group_label}->%*];
  }
}

sub group_title {
  my ($self, $newvalues) = @_;

  if (defined $newvalues) {
    $self->{group_title} = $newvalues;

    return $self;
  } else {
    return $self->{group_title};
  }
}

sub header_row {
  my ($self, $header, %params) = @_;

  my %data;
  if ($params{parse}) {
    for my $column ($self->{column_index}->@*) {
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

sub nonzero_decimal {
  my ($self, $decimal, $format) = @_;

  if ($decimal * 1) {
    $self->decimal($decimal, $format);
  } else {
    $self->text('', $format);
  }

  return $self;
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
  my ($self, $group) = @_;

  if ($self->{group_count}{$group}) {
    my $sum = delete $self->{group_sum}{$group};
    if ($self->{group_label}{$group}) {
      $sum->{$self->{column_index}->[0]} = $self->{last}{$group};
    }

    $self->data_row($sum, format => 'subtotal');
    $self->{group_count}{$group} = 0;
  }

  return $self;
}

sub tab {
  my ($self, $times) = @_;

  $self->{col} += $times // 1;

  return $self;
}

sub table_row {
  my ($self, $row, %params) = @_;

  for my $group (reverse $self->{group_by}->@*) {
    my $lastid = $self->{last}{$group} || '';
    if ($lastid ne $row->{$group}) {
      if ($lastid) {
        $self->subtotal_row($group);
      }
      $self->title_row($group, $row);
    }
  }

  if ($self->{group_sum}{total}) {

    for my $field ($self->totalize->@*) {
      if (looks_like_number($row->{$field})) {
        for my $group ('total', $self->{group_by}->@*) {
          $self->{group_sum}{$group}{$field} += $row->{$field};
        }
      }
    }

    for my $group ($self->{group_by}->@*) {
      $self->{last}{$group} = $row->{$group};
      $self->{group_count}{$group}++;
    }

  }

  return $self->data_row($row, %params);
}

sub text {
  my ($self, $text, $format) = @_;

  $format ||= 'default';

  $self->{worksheet}
    ->write_string($self->{row}, $self->{col}, $text, $self->{format}{"${format}_text"});

  return $self;
}

sub title_row {
  my ($self, $group, $row) = @_;

  if (my $title = $self->{group_title}{$group}) {
    my $title_string = ref $title eq 'CODE' ? $title->($self->{_form}, $row) : $title;

    my %data = ($self->{column_index}[0] => $title_string);

    $self->data_row(\%data, format => 'group_title');
  }

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

  for my $group (reverse $self->{group_by}->@*) {
    $self->subtotal_row($group);
  }

  if (my $update = $params{update}) {
    $self->{group_sum}{total}{$_} = $update->{$_} for keys %$update;
  }

  $params{format}  ||= 'total';
  $params{rowtype} ||= 'total';
  $params{scale}   ||= 1.2;

  $self->data_row($self->{group_sum}{total}, %params);

  return $self;
}

sub totalize {
  my ($self, $newvalues) = @_;
  if (defined $newvalues) {
    $self->{totalize} = [];

    delete $self->{$_} for qw|total subtotal subtotalcount|;
    for my $val (@$newvalues) {
      if ($val eq ':decimal') {

        for my $column ($self->{column_index}->@*) {
          if (!$self->{structure}{columns}{$column}
            || $self->{structure}{columns}{$column} =~ /decimal$/)
          {
            push $self->{totalize}->@*, $column;
            $self->{group_sum}{total}{$column} = 0;
          }
        }

      } else {
        push $self->{totalize}->@*, $val;
        $self->{group_sum}{total}{$val} = 0;
      }
    }

    return $self;
  } else {
    return $self->{totalize};
  }
}

sub worksheet {
  my ($self, %params) = @_;

  my $title;
  if ($params{form_title}) {
    $title = $self->{_form}{title} =~ s/ \/.*$//r;
  } elsif ($params{title}) {
    $title = $params{title};
  }
  $title =~ tr'\/?*[]'--.+()';
  $title =~ s/^\.+//;
  $title = substr $title, 0, 31;

  $self->{worksheet} = $self->{workbook}->add_worksheet($title);

  $self->{$_} = 0  for qw|row col|;
  $self->{$_} = {} for qw|last group_sum|;
  $self->{$_} = [] for qw|width|;

  return $self;
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
    $ss->worksheet;
    $ss->structure(\%spreadsheet_info);
    $ss->column_index(\@index);
    $ss->totalize(\@columns);
    $ss->group_by(\@groups);
    $ss->group_label(\@groups);
    $ss->group_title(\%titles);
    $ss->change_format($name, %new_properties);

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
    $ss->nonzero_decimal($decimal, $format);
    $ss->link($url, $text, $format);
    $ss->number($number, $format);
    $ss->text($text, $format);

    $ss->data_row(\%data);

    $ss->header_row(\%header);
    $ss->freeze_panes;
    for my $row (@rows) {
      $ss->table_row($row);
    }
    $ss->total_row;

    $ss->finish;

    $form->download_tmpfile(\%myconfig, "$filename.xlsx");

=head1 DESCRIPTION

L<SL::Spreadsheet> provides the backend to create spreadsheets.

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

=head2 adjust_columns

  $ss = $ss->adjust_columns;

=head2 bool

  $ss = $ss->bool($bool);
  $ss = $ss->bool($bool, $format);

=head2 change_format

  $ss = $ss->change_format($name, %new_properties);
  $ss = $ss->change_format(':all', %new_properties);

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

=head2 group_by

  $ss     = $ss->group_by(\@groups);
  $groups = $ss->group_by;

=head2 group_label

  $ss     = $ss->group_label(\@groups);
  $groups = $ss->group_label;

=head2 group_title

  $ss     = $ss->group_title(\%titles);
  $titles = $ss->group_title;

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

=head2 nonzero_decimal

  $ss = $ss->nonzero_decimal($decimal);
  $ss = $ss->nonzero_decimal($decimal, $format);

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

=head2 subtotal_row

  $ss = $ss->subtotal_row($group);

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

=head2 worksheet

  $ss = $ss->worksheet;
  $ss = $ss->worksheet(form_title => 1);
  $ss = $ss->worksheet(title => $title);

=cut
