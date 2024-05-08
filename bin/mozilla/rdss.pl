#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2022
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Spreadsheet Functions for Reference Documents
#
#======================================================================

use SL::Spreadsheet;

sub documents_spreadsheet {
  my ($report_options, $column_index, $header, $module) = @_;

  my %spreadsheet_info = (
    columns => {
      confidential    => 'bool',
      description     => 'link',
      document_number => 'link',
      filename        => 'link',
      folder          => 'text',
      formname        => 'text',
    }
  );

  my $ss = SL::Spreadsheet->new($form, $userspath);
  $ss->worksheet(form_title => 1)->structure(\%spreadsheet_info)
    ->column_index($column_index);

  $ss->title($form->{title})->crlf->report_options($report_options);

  $ss->crlf->header_row($header, parse => 1)->freeze_panes;

  for my $ref ($form->{all_documents}->@*) {

    # links
    $ref->{description_link} = qq|rd.pl?action=edit&id=$ref->{id}|;
    if ($ref->{archive_id}) {
      $ref->{filename_link} = qq|rd.pl?action=display_documents&id=$ref->{archive_id}|;
    }

    if ($ref->{formname}) {
      if ($module->{$ref->{formname}}{script}) {
        $ref->{document_number_link}
          = qq|$module->{$ref->{formname}}{script}.pl?action=edit&id=$ref->{trans_id}|;
        $ref->{document_number_link} .= "&$module->{$ref->{formname}}{var}"
          if $module->{$ref->{formname}}{var};
      }

      $ref->{formname} = $module->{$ref->{formname}}{label};
    }

    $ss->table_row($ref);
  }

  $ss->adjust_columns->finish;

  $form->download_tmpfile(\%myconfig, "$form->{title}.xlsx");
}


1;

=encoding utf8

=head1 NAME

bin/mozilla/rdss.pl - Spreadsheet Functions for Reference Documents

=head1 DESCRIPTION

L<bin::mozilla::ss> contains functions to create and download spreadsheets for Reference Documents.

=head1 DEPENDENCIES

L<bin::mozilla::rdss>

=over

=item * uses
L<Excel::Writer::XLSX>,
L<SL::Spreadsheet>

=back

=head1 FUNCTIONS

L<bin::mozilla::rdss> implements the following functions:

=head2 documents_spreadsheet

  &documents_spreadsheet($report_options, $column_index, $header, $module);

=cut
