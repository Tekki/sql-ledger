#======================================================================
# SQL-Ledger ERP
#
# © 2026-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# Spreadsheet Functions for Administration
#
#======================================================================

use SL::Spreadsheet;


sub sql_command_spreadsheet {

  $form->{title} = $locale->text('Database Monitor');
  my %spreadsheet_info = (columns => $form->{COLUMNS},);

  my %header = map {$_ => $_} $form->{COLUMN_INDEX}->@*;
  
  my $ss = SL::Spreadsheet->new($form, $slconfig{userspath});
  $ss->worksheet(form_title => 1)->structure(\%spreadsheet_info)
    ->column_index($form->{COLUMN_INDEX});

  $ss->title($form->{title})->crlf;

  $ss->crlf->header_row(\%header)->freeze_panes;
  
  for my $ref ($form->{DATA}->@*) {
    $ss->table_row($ref);
  }

  $ss->adjust_columns->finish;

  $form->download_tmpfile(\%myconfig, "$form->{title}.xlsx");
}


1;

=encoding utf8

=head1 NAME

bin/mozilla/amss.pl - Spreadsheet Functions for Administration

=head1 DESCRIPTION

L<bin::mozilla::amss> contains functions to create and download
spreadsheets for administration.

=head1 DEPENDENCIES

L<bin::mozilla::amss>

=over

=item * uses
L<Excel::Writer::XLSX>,
L<SL::Spreadsheet>

=back

=head1 FUNCTIONS

L<bin::mozilla::amss> implements the following functions:

=head2 sql_command_spreadsheet

  &sql_command_spreadsheet;

=cut
