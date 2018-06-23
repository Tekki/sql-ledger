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

  # prepare content
  my $html = TagHelpers->new(\%myconfig, $form)->callback('action', 'id');

  # header
  my %header = (
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
      $html->search_part(
        not_found    => $locale->text('Nothing found!'),
        placeholders => [
          $locale->text('Search Part Number'),
          $locale->text('Search Description')
        ],
        selected => {
          action => 'part_requirements',
          script => 'mrp.pl',
        }
      ),
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

  # requirements table
  my %requirements = (
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
          {content => \'req.date', params => {type => 'date'}},
          $html->order_link(\'req.order_type', \'req.id', \'req.ordnumber'),
          $html->vendor_link(\'req.vendor_id', \'req.vendor_name'),
          $html->customer_link(\'req.customer_id', \'req.customer_name'),
          {content => \'req.qty_in',  params => {type => 'number'}},
          {content => \'req.qty_out', params => {type => 'number'}},
          {content => \'req.total',   params => {type => 'number'}},
        ],
        params => {class => 'zebra', for => 'req in form.requirements',},
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

  # render page
  $form->header;
  print $html->start_body;
  print $html->table(%header);
  print $html->table(%requirements);
  print $html->end_body;
}

sub warnings {

  MRP->warnings(\%myconfig, $form);

  return $form->render_json if $form->accepts_json;

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
          $html->requirements_link(\'warning.id', \'warning.partnumber'),
          \'warning.description',
          {content => \'warning.onhand',   params => {type => 'number'}},
          {content => \'warning.incoming', params => {type => 'number'}},
          {content => \'warning.outgoing', params => {type => 'number'}},
          {content => \'warning.total',    params => {type => 'number'}},
        ],
        params => {class => 'zebra', for => 'warning in form.warnings'},
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

Returns HTML or JSON.

=head2 warnings

  &warnings;

Returns HTML or JSON.

=cut
