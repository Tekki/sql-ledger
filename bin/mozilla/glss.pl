#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2024
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Spreadsheet Functions for General Ledger
#
#======================================================================

use SL::Spreadsheet;

sub transactions_spreadsheet {
  my ($report_options, $column_index, $header, $href) = @_;

  my %spreadsheet_info = (
    columns => {
      accno       => 'link',
      address     => 'text',
      contra      => 'text',
      credit      => 'nonzero_decimal',
      debit       => 'nonzero_decimal',
      department  => 'text',
      description => 'text',
      gifi_accno  => 'link',
      id          => 'text',
      memo        => 'text',
      name        => 'text',
      notes       => 'text',
      project     => 'text',
      reference   => 'link',
      source      => 'text',
      transdate   => 'date',
      vcnumber    => 'text',
    },
  );

  my $ss = SL::Spreadsheet->new($form, $userspath);

  $ss->change_format(':all', color => undef, border_color => undef, underline => 0);
  $ss->change_format('total', bottom => 1);

  $ss->worksheet(form_title => 1)->structure(\%spreadsheet_info)
    ->column_index( $column_index)
    ->totalize(['credit', 'debit',]);

  my (@group_by, @group_label, %group_title);

  if ($form->{l_splitledger}) {
    push @group_by,    'accno';
    push @group_label, 'accno';

    $group_title{accno} = sub {
      my ($form, $row) = @_;
      return qq|$row->{accno}--$row->{account_description}|;
    };

        my %category = (A => -1, L => 1, I => 1, E => -1, Q => 1);
        my %ca       = (0 => 1, 1 => -1);

    $ss->balance_column('balance')->balance_group('accno');
    $ss->balance_fn(
      sub {
        my ($ss, $row) = @_;

        return $ss->{balance} + $row->{amount} * $category{$row->{category}} * $ca{$row->{ca}};
      }
    );
    $ss->balance_start(
      sub {
        my ($ss, $row) = @_;

        return $row->{balance} * $category{$row->{category}} * $ca{$row->{ca}};
      }
    );
  }

  if ($form->{l_subtotal}) {
    push @group_by,    $form->{sort};
    push @group_label, $form->{sort};
  }

  $ss->group_by(\@group_by)       if @group_by;
  $ss->group_label(\@group_label) if @group_label;
  $ss->group_title(\%group_title) if keys %group_title;

  $ss->title($form->{title})->crlf->report_options($report_options);

  $ss->crlf->header_row($header)->freeze_panes;

  for my $ref ($form->{GL}->@*) {

    $ref->{reference_link}  = qq|$ref->{module}.pl?action=edit&id=$ref->{id}|;
    $ref->{accno_link}      = qq|$href&accno=$ref->{accno}|;
    $ref->{gifi_accno_link} = qq|$href&gifi_accno=$ref->{gifi_accno}|;

    $ss->table_row($ref);

  }

  $ss->total_row->adjust_columns;
  $ss->finish;

  $form->download_tmpfile(\%myconfig, "$form->{title}.xlsx");
}



1;

=encoding utf8

=head1 NAME

bin/mozilla/glss.pl - Spreadsheet Functions for General Ledger Reports

=head1 DESCRIPTION

L<bin::mozilla::glss> contains functions to create and download spreadsheets for general ledger reports.

=head1 DEPENDENCIES

L<bin::mozilla::glss>

=over

=item * uses
L<Excel::Writer::XLSX>,
L<SL::Spreadsheet>

=back

=head1 FUNCTIONS

L<bin::mozilla::glss> implements the following functions:

=head2 transactions_spreadsheet

  &transactions_spreadsheet($report_options, $column_index, $header);

=cut
