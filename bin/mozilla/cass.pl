#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2024
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Spreadsheet Functions for Chart of Accounts
#
#======================================================================

use SL::Spreadsheet;

sub transactions_spreadsheet {
  my ($report_options, $column_index, $header) = @_;

  my %spreadsheet_info = (
    columns => {
      accno       => 'text',
      cleared     => 'bool',
      credit      => 'nonzero_decimal',
      debit       => 'nonzero_decimal',
      description => 'link',
      reference   => 'link',
      source      => 'text',
      transdate   => 'date',
    },
  );

  my $ss = SL::Spreadsheet->new($form, $userspath);

  $ss->change_format(':all', color => undef, border_color => undef, underline => 0);
  $ss->change_format('total', bottom => 1);

  $ss->worksheet(form_title => 1)->structure(\%spreadsheet_info)->column_index($column_index)
    ->totalize(['debit', 'credit']);
  if ($form->{l_subtotal}) {
    $ss->group_by([$form->{sort}])->group_label([$form->{sort}]);
  }

  $ss->title($form->{title})->crlf->report_options($report_options);

  $ss->crlf->header_row($header, parse => 1)->freeze_panes;

  my $ml = ($form->{category} =~ /(A|E)/) ? -1 : 1;
  $ml *= -1 if $form->{contra};

  $ss->table_row({balance => $form->{balance} * $ml, transdate => $form->{fromdate}});

  for my $ref ($form->{CA}->@*) {
    $form->{balance} += $ref->{amount};
    $ref->{balance} = $form->{balance} * $ml;

    $ref->{accno} = join ', ', $ref->{accno}->@*;

    if ($ref->{vc_id}) {
      $ref->{description_link} = qq|ct.pl?action=edit&id=$ref->{vc_id}&db=$ref->{db}|;
    }

    $ref->{reference_link} = qq|$ref->{module}.pl?action=edit&id=$ref->{id}|;

    $ss->table_row($ref);
  }

  $ss->total_row(update => {balance => $form->{balance} * $ml, transdate => $form->{todate}})
    ->adjust_columns;
  $ss->finish;

  $form->download_tmpfile(\%myconfig, "$form->{title}.xlsx");
}

1;

=encoding utf8

=head1 NAME

bin/mozilla/cass.pl - Spreadsheet Functions for Chart of Accounts

=head1 DESCRIPTION

L<bin::mozilla::cass> contains functions to create and download
spreadsheets of accounts.

=head1 DEPENDENCIES

L<bin::mozilla::cass>

=over

=item * uses
L<Excel::Writer::XLSX>,
L<SL::Spreadsheet>

=back

=head1 FUNCTIONS

L<bin::mozilla::cass> implements the following functions:

=head2 transactions_spreadsheet

  &transactions_spreadsheet($report_options, $column_index, $header);

=cut
