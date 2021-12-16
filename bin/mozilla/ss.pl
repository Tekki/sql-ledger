#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2021
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Spreadsheet Functions
#
#======================================================================

use List::Util qw|max min|;
use Scalar::Util 'looks_like_number';

$form->load_module(['Excel::Writer::XLSX'], $locale->text('Module not installed:'));

sub create_spreadsheet {
  my ($spreadsheet_info, $report_options, $column_index, $header, $data) = @_;
  my @index = grep !/delete|runningnumber/, @$column_index;

  my $tmpfile  = $form->{tmpfile} = "$userspath/" . time . "$$.xlsx";
  my $workbook = Excel::Writer::XLSX->new($tmpfile) or $form->error("$tmpfile: $!");

  my $dateformat = $myconfig{dateformat};
  $dateformat =~ s/yy$/yyyy/;
  my %format = (
    big_title => $workbook->add_format(font => 'Calibri Light', size => 18, color => '#44546A',),
    bool      => $workbook->add_format(font => 'Calibri',       size => 11, align => 'center',),
    date      => $workbook->add_format(
      font       => 'Calibri',
      size       => 11,
      num_format => $dateformat,
    ),
    decimal => $workbook->add_format(
      font       => 'Calibri',
      size       => 11,
      num_format => q|#,##0.00|,
    ),
    link  => $workbook->add_format(font => 'Calibri', size => 11, color => 'blue', underline => 1,),
    text  => $workbook->add_format(font => 'Calibri', size => 11,),
    title => $workbook->add_format(font => 'Calibri', size => 11, bold => 1, align => 'center',),
  );
  $format{number} = $format{text};

  my $worksheet = $workbook->add_worksheet;
  my $row       = 0;
  my $col       = -1;
  my $maxwidth  = 40;
  my @width;
  my ($url) = $ENV{HTTP_REFERER} =~ /(.+?)\/[a-z]+\.pl/;
  my $url_params = qq|&path=$form->{path}&login=$form->{login}|;

  # column format
  for my $column (@index) {
    $col++;
    my $type = $spreadsheet_info->{columns}{$column} || 'decimal';
    $type = 'text' if $type eq 'link';
    $worksheet->set_column($col, $col, undef, $format{$type});
  }
  
  # title
  $col=0;
  $worksheet->set_row($row, 23.25);
  $worksheet->write_string($row, $col, $form->{title}, $format{big_title});

  # options
  if ($report_options) {
    $row++;
    $report_options =~ s/<br>//g;
    $report_options =~ s/&nbsp;/ /g;
    for my $option (split /\n/, $report_options) {
      $row++;
      $worksheet->write_string($row, $col, $option, $format{text});
    }
  }

  # header
  $row += 2;
  $col = -1;
  $worksheet->set_row($row, undef, $format{title});
  for my $column (@index) {
    $col++;
    my ($title) = $header->{$column} =~ /.*>([^<]+)</;
    $title =~ s/&nbsp;/ /g;
    $worksheet->write_string($row, $col, $title || '');

    $width[$col] = max $width[$col], int(length($title) * 1.2 + 1.5);
  }

  # data
  for my $ref (@$data) {
    $row++;
    $col = -1;

    if (my $fn = $spreadsheet_info->{init_row}) {
      &$fn($ref);
    }

    for my $column (@index) {
      $col++;

      my $type  = $spreadsheet_info->{columns}{$column};
      my $value = $ref->{$column} // next;

      if ($type eq 'text') {

        $worksheet->write_string($row, $col, $value);
        $width[$col] = max $width[$col], length($value) + 2;

      } elsif ($type eq 'date') {

        $worksheet->write_date_time($row, $col, "${value}T");
        $width[$col] = length($dateformat) + 2;

      } elsif ($type eq 'link') {

        $worksheet->write_url($row, $col, qq|$url/$ref->{"${column}_link"}$url_params|,
          $format{link}, $value);
        $width[$col] = max $width[$col], length($value) + 2;

      } elsif ($type eq 'bool') {

        $worksheet->write_string($row, $col,"\x{00D7}") if $value;

      } else {

        next unless looks_like_number($value);
        $worksheet->write_number($row, $col, $value);
        $width[$col] = max $width[$col], length($value) + 2;

      }
    }

  }

  # column width
  for (0 .. $#width) {
    $worksheet->set_column($_, $_, min($width[$_], $maxwidth));
  }

  $workbook->close;
}

sub download_spreadsheet {
  &create_spreadsheet(@_);
  $form->download_tmpfile('application/vnd.ms-excel', "$form->{title}.xlsx");

  exit;
}

1;


=encoding utf8

=head1 NAME

bin/mozilla/ss.pl - Spreadsheet Functions

=head1 DESCRIPTION

L<bin::mozilla::ss> contains functions to create and download spreadsheets

=head1 DEPENDENCIES

L<bin::mozilla::ss>

=over

=item * uses
L<Excel::Writer::XLSX>

=back

=head1 FUNCTIONS

L<bin::mozilla::ss> implements the following functions:

=head2 create_spreadsheet

  &create_spreadsheet($spreadsheet_info, $report_options, $column_index, $header, $data);

=head2 download_spreadsheet

  &download_spreadsheet($spreadsheet_info, $report_options, $column_index, $header, $data);

=cut
