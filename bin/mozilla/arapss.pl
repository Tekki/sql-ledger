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
      accno          => 'text',
      address        => 'text',
      address1       => 'text',
      address2       => 'text',
      city           => 'text',
      contacttitle   => 'text',
      country        => 'text',
      curr           => 'text',
      customernumber => 'text',
      datepaid       => 'date',
      dcn            => 'text',
      department     => 'text',
      description    => 'text',
      duedate        => 'date',
      email          => 'email',
      employee       => 'text',
      firstname      => 'text',
      id             => 'number',
      invnumber      => 'link',
      lastname       => 'text',
      memo           => 'text',
      mobile         => 'text',
      name           => 'link',
      notes          => 'text',
      occupation     => 'text',
      ordnumber      => 'text',
      paid           => 'nonzero_decimal',
      paymentaccount => 'text',
      paymentdiff    => 'number',
      paymentmethod  => 'text',
      phone          => 'text',
      ponumber       => 'text',
      projectnumber  => 'text',
      salutation     => 'text',
      shippingpoint  => 'text',
      shipvia        => 'text',
      source         => 'text',
      taxnumber      => 'text',
      till           => 'text',
      transdate      => 'date',
      warehouse      => 'text',
      waybill        => 'text',
      zipcode        => 'text',
    },
  );

  my $ss = SL::Spreadsheet->new($form, $userspath);
  $ss->worksheet(form_title => 1)->structure(\%spreadsheet_info)
    ->column_index([grep !/delete|runningnumber/, @$column_index])->totalize([':decimal']);
  if ($form->{l_subtotal}) {
    $ss->group_by([$form->{sort}])->group_label([$form->{sort}]);
  }

  $ss->title($form->{title})->crlf->report_options($report_options);

  $ss->crlf->header_row($header, parse => 1)->freeze_panes;

  for my $ref ($form->{transactions}->@*) {

    # links
    $ref->{name_link} = qq|ct.pl?action=edit&id=$ref->{"$form->{vc}_id"}&db=$form->{vc}|;

    my $module = $ref->{invoice} ? $form->{ARAP} eq 'AR' ? 'is.pl' : 'ir.pl' : $form->{script};
    $module = 'ps.pl' if $ref->{till};
    $ref->{invnumber_link} = qq|$module?action=edit&id=$ref->{id}|;

    # amounts
    if ($form->{l_curr}) {
      if ($ref->{curr} ne $form->{defaultcurrency}) {
        for (qw|netamount amount paid|) {
          $ref->{"$ref->{curr}_$_"}
            = $form->round_amount($ref->{$_} / $ref->{exchangerate}, $form->{precision})
            if $ref->{$_};
        }
        $ref->{"$ref->{curr}_tax"}
          = $ref->{"$ref->{curr}_amount"} - $ref->{"$ref->{curr}_netamount"};
        if ($ref->{paid} != $ref->{amount}) {
          $ref->{"$ref->{curr}_due"}
            = $ref->{"$ref->{curr}_amount"} - $ref->{"$ref->{curr}_paid"};
        }
      }
    }

    $ref->{tax} = $ref->{amount} - $ref->{netamount};

    if ($ref->{paid} != $ref->{amount}) {
      $ref->{due} = $ref->{amount} - $ref->{paid};
    }

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

bin/mozilla/arapss.pl - Spreadsheet Functions for AR / AP

=head1 DESCRIPTION

L<bin::mozilla::ss> contains functions to create and download spreadsheets for AR and AP.

=head1 DEPENDENCIES

L<bin::mozilla::arapss>

=over

=item * uses
L<Excel::Writer::XLSX>,
L<SL::Spreadsheet>

=back

=head1 FUNCTIONS

L<bin::mozilla::arapss> implements the following functions:

=head2 transactions_spreadsheet

  &transactions_spreadsheet($report_options, $column_index, $header);

=cut
