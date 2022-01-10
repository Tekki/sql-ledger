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

$form->load_module(['Excel::Writer::XLSX', 'SL::Spreadsheet'], $locale->text('Module not installed:'));

sub create_spreadsheet {
  my ($spreadsheet_info, $report_options, $column_index, $header, $data) = @_;
  my @index = grep !/delete|runningnumber/, @$column_index;

  my $ss = SL::Spreadsheet->new($form, $userspath);

  # structure
  $ss->structure($spreadsheet_info)->column_index(\@index)->totalize($spreadsheet_info->{totalize});

  # title
  $ss->title($form->{title})->crlf;

  # options
  if ($report_options) {
    $report_options =~ s/<br>//g;
    $report_options =~ s/&nbsp;/ /g;

    $ss->crlf->text($_) for split /\n/, $report_options;
    $ss->crlf;
  }

  # header
  $ss->crlf->header_row($header, parse => 1);
  $ss->freeze_panes;

  # data
  $ss->data_row($_) for @$data;
  $ss->total_row;

  $ss->finish;
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
L<Excel::Writer::XLSX>,
L<SL::Spreadsheet>

=back

=head1 FUNCTIONS

L<bin::mozilla::ss> implements the following functions:

=head2 create_spreadsheet

  &create_spreadsheet($spreadsheet_info, $report_options, $column_index, $header, $data);

=head2 download_spreadsheet

  &download_spreadsheet($spreadsheet_info, $report_options, $column_index, $header, $data);

=cut
