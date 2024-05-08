#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2022
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Spreadsheet Functions for AR / AP
#
#======================================================================

use SL::Spreadsheet;

sub transactions_spreadsheet {
  my ($report_options, $column_index, $header) = @_;

  my %spreadsheet_info = (
    columns => {
      closed         => 'bool',
      curr           => 'text',
      customernumber => 'text',
      description    => 'text',
      employee       => 'text',
      id             => 'number',
      memo           => 'text',
      name           => 'link',
      notes          => 'text',
      open           => 'bool',
      ordnumber      => 'link',
      ponumber       => 'text',
      quonumber      => 'link',
      reqdate        => 'date',
      shippingpoint  => 'text',
      shipvia        => 'text',
      transdate      => 'date',
      vendornumber   => 'text',
      warehouse      => 'text',
      waybill        => 'text',
    },
  );

  my $ss = SL::Spreadsheet->new($form, $userspath);
  $ss->worksheet(form_title => 1)->structure(\%spreadsheet_info)
    ->column_index([grep !/delete|runningnumber/, @$column_index])
    ->totalize(['netamount', 'tax', 'amount']);
  if ($form->{l_subtotal}) {
    $ss->group_by([$form->{sort}])->group_label([$form->{sort}]);
  }

  $ss->title($form->{title})->crlf->report_options($report_options);

  $ss->crlf->header_row($header, parse => 1)->freeze_panes;

  for my $ref ($form->{OE}->@*) {

    # links
    $ref->{name_link} = qq|ct.pl?action=edit&id=$ref->{"$form->{vc}_id"}&db=$form->{vc}|;

    my $action = $form->{type} =~ /(ship|receive)_order/ ? 'ship_receive' : 'edit';
    $ref->{"${ordnumber}_link"}
      = qq|$form->{script}?action=$action&type=$form->{type}&id=$ref->{id}&warehouse=$warehouse&vc=$form->{vc}|;

    # amounts
    if ($form->{l_curr}) {
      for (qw|netamount amount|) {
        $ref->{"fx_$_"} = $ref->{$_};
        $ref->{$_} = $form->round_amount($ref->{$_} * $ref->{exchangerate}, $form->{precision});
      }
      $ref->{fx_tax} = $ref->{fx_amount} - $ref->{fx_netamount};
    }

    $ref->{tax} = $ref->{amount} - $ref->{netamount};

    # open / closed
    $ref->{open} = !$ref->{closed};

    # write to spreadsheet
    $ss->table_row($ref);
  }

  $ss->total_row->adjust_columns;
  $ss->finish;

  $form->download_tmpfile(\%myconfig, "$form->{title}.xlsx");
}

1;

=encoding utf8

=head1 NAME

bin/mozilla/oess.pl - Spreadsheet Functions for orders and quotations

=head1 DESCRIPTION

L<bin::mozilla::oess> contains functions to create and download
spreadsheets for orders and quotations.

=head1 DEPENDENCIES

L<bin::mozilla::oess>

=over

=item * uses
L<Excel::Writer::XLSX>,
L<SL::Spreadsheet>

=back

=head1 FUNCTIONS

L<bin::mozilla::oess> implements the following functions:

=head2 transactions_spreadsheet

  &transactions_spreadsheet($report_options, $column_index, $header);

=cut
