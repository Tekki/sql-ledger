#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2018
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Material Requirements Planning
#
#======================================================================

use SL::MRP;
use SL::TagHelpers;

sub part_requirements {

  MRP->part_requirements(\%myconfig, $form);

  return $form->render_json if $form->accepts_json;

  my $html = TagHelpers->new(\%myconfig, $form)->callback('action', 'id');

  $form->header;
  print $html->start_body;

  print $html->table(
    params => {width => '100%'},
    rows   => [
      {
        columns => [
          {
            content => $locale->text('Part Requirements'),
            params  => {head => 1, colspan => 3},
          },
        ],
        params => {class => 'listtop'},
      },
      $html->search_part(action => 'part_requirements', script => 'mrp.pl'),
      {
        columns => [
          {
            content => $locale->text('Part Number'),
            params  => {width => '20%'},
          },
          {
            content => $locale->text('Description'),
            params  => {width => '50%'},
          },
          {
            content => $locale->text('Partsgroup'),
            params  => {width => '30%'},
          },
        ],
        common_params => {align => 'left', head => 1},
      },
      {
        columns =>
          [\'form.partnumber', \'form.description', \'form.partsgroup',],
      }
    ],
  );

  print $html->table(
    params => {width => '100%'},
    rows   => [
      {
        columns => [
          $locale->text('Date'),     $locale->text('Order'),
          $locale->text('Vendor'),   $locale->text('Customer'),
          $locale->text('Incoming'), $locale->text('Outgoing'),
          $locale->text('Total'),
        ],
        common_params => {head  => 1},
        params        => {class => 'listheading'},
      },
      {
        columns => [
          {content => \'item.date', params => {type => 'date'}},
          $html->order_link(\'item.order_type', \'item.id', \'item.ordnumber'),
          $html->vendor_link(\'item.vendor_id', \'item.vendor_name'),
          $html->customer_link(\'item.customer_id', \'item.customer_name'),
          {content => \'item.qty_in',  params => {type => 'number'}},
          {content => \'item.qty_out', params => {type => 'number'}},
          {content => \'item.total',   params => {type => 'number'}},
        ],
        params => {class => 'zebra', for => 'item in form.requirements',},
      },
      {
        columns => [
          $locale->text('Total'),
          '',
          '',
          '',
          {content => \'form.total_in',  params => {type => 'number'}},
          {content => \'form.total_out', params => {type => 'number'}},
          {content => \'form.total_qty', params => {type => 'number'}},
        ],
        common_params => {head  => 1},
        params        => {class => 'listtotal'},
      },
    ],
  );

  print $html->end_body;
}

sub warnings {

  MRP->warnings(\%myconfig, $form);

  my $html = TagHelpers->new(\%myconfig, $form)->callback('action');

  $form->header;
  print $html->start_body;
  print $html->table(
    params => {width => '100%'},
    rows   => [
      {
        columns => [
          {
            content => $locale->text('Requirement Warnings'),
            params  => {head => 1, colspan => 3},
          },
        ],
        params => {class => 'listtop'},
      },
    ],
  );

  print $html->table(
    params => {width => '100%'},
    rows   => [
      {
        columns => [
          $locale->text('Part Number'), $locale->text('Description'),
          $locale->text('Onhand'),      $locale->text('Incoming'),
          $locale->text('Outgoing'),    $locale->text('Total'),
        ],
        common_params => {head  => 1},
        params        => {class => 'listheading'},
      },
      {
        columns => [
          $html->requirements_link(\'item.id', \'item.partnumber'),
          \'item.description',
          {content => \'item.onhand',   params => {type => 'number'}},
          {content => \'item.incoming', params => {type => 'number'}},
          {content => \'item.outgoing', params => {type => 'number'}},
          {content => \'item.total',    params => {type => 'number'}},
        ],
        params => {class => 'zebra', for => 'item in form.warnings'},
      },
    ],
  );

  print $html->end_body;
}

1;

=encoding utf8

=head1 NAME

bin/mozilla/mrp.pl - Material Requirements Planning

=head1 DESCRIPTION

L<bin::mozilla:mrp> contains functions for material requirements planning.

=head1 DEPENDENCIES

L<bin::mozilla:mrp>

=over

=item * uses
L<SL::MRP>,
L<SL::TagHelpers>

=back

=head1 FUNCTIONS

L<bin::mozilla:mrp> implements the following functions:

=head2 part_requirements

  &part_requirements;

=head2 warnings

  &warnings;

=cut
