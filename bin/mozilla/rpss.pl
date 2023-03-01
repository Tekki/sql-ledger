#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2022
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# Spreadsheet Functions for Yearend Reports
#
#======================================================================

$form->load_module(['Excel::Writer::XLSX', 'SL::Spreadsheet'],
  $locale->text('Module not installed:'));

sub tax_spreadsheet {
  my ($report_options, $column_index, $header) = @_;

  # structure
  my %spreadsheet_info = (
    columns => {
      accno       => 'text',
      address     => 'text',
      country     => 'text',
      description => 'text',
      id          => 'number',
      invnumber   => 'text',
      name        => 'text',
      transdate   => 'date',
    },
  );

  for my $curr ($form->{_used_currencies}->@*) {
    $spreadsheet_info{columns}{"${curr}_curr"} = 'text';
  }

  my $ss = SL::Spreadsheet->new($form, $userspath);
  $ss->structure(\%spreadsheet_info)->column_index($column_index)->totalize([':decimal']);
  if ($form->{l_subtotal}) {
    $ss->group_by(['accno', $form->{sort}]);
  } else {
    $ss->group_by(['accno']);
  }
  $ss->group_label(['accno']);
  $ss->group_title(
    {
      accno => sub {
        my ($form, $row) = @_;
        return qq|$row->{accno}--$form->{"$row->{accno}_description"}|;
      }
    }
  );

  $ss->change_format(':all', color => undef, border_color => undef);
  $ss->change_format('total', bottom => 1);

  $ss->title($form->{title})->crlf;

  $ss->crlf->text($form->{company})->lf;
  $ss->text($form->{method} eq 'cash' ? $locale->text('Cash') : $locale->text('Accrual'))->lf;
  $ss->date($form->{fromdate})->lf->date($form->{todate})->lf;

  $ss->crlf->header_row($header, parse => 1)->freeze_panes;

  for my $ref ($form->{TR}->@*) {
    $ss->table_row($ref);
  }
  $ss->total_row;

  $ss->finish;

  $form->download_tmpfile(\%myconfig, "$form->{title}-$form->{company}.xlsx");
}

sub yearend_spreadsheet {
  my ($report_code, $periods) = @_;

  my $ss = SL::Spreadsheet->new($form, $userspath);

  $ss->change_format(':all', color => undef, border_color => undef);
  $ss->change_format('total', bottom => 1);

  # structure
  my %spreadsheet_info = (
    columns => {
      accno       => 'text',
      description => 'text',
    }
  );

  my (@column_index, @amount_columns);
  if ($form->{previousyear}) {
    if ($form->{reversedisplay}) {
      @amount_columns = map { ("previous_$_", "this_$_") } @$periods;
    } else {
      @amount_columns = map { ("this_$_", "previous_$_") } @$periods;
    }
  } else {
    @amount_columns = map {"this_$_"} @$periods;
  }
  my $tab = $form->{l_accno} ? 1 : 0;
  push @column_index, 'accno' if $tab;
  push @column_index, 'description', @amount_columns;

  $spreadsheet_info{header}{$_} = 'date' for @amount_columns;

  $ss->structure(\%spreadsheet_info)->column_index(\@column_index)->maxwidth(50);

  $ss->text($form->{company})->crlf;
  $ss->text($_)->crlf for split /\n/, $form->{address};
  $ss->crlf;

  my (@categories, %header_data);
  if ($report_code eq 'balance_sheet') {
    $form->{title} = $locale->text('Balance Sheet');
    @categories = qw|A L Q|;

    $ss->title($form->{title})->crlf(2);
    $ss->tab($tab)->text($locale->text('as at'), 'heading4')->lf->date($form->{todate}, 'heading4')
      ->crlf(2);

    if ($form->{department}) {
      (my $val) = split /--/, $form->{department};
      $ss->tab($tab)->text($val, 'heading4')->crlf(2);
    }

  } else {
    $form->{title} = $locale->text('Income Statement');
    @categories = qw|I E|;

    $ss->title($form->{title})->crlf(2);
    $ss->tab($tab)->text($locale->text('for Period'), 'heading4')
      ->lf->date($form->{fromdate}, 'heading4')->lf->date($form->{todate}, 'heading4')->crlf(2);

    if ($form->{department} || $form->{projectnumber}) {
      for (qw|department projectnumber|) {
        if ($form->{$_}) {
          (my $val) = split /--/, $form->{$_};
          $ss->tab($tab)->text($val, 'heading4')->crlf;
        }
      }

      $ss->crlf;
    }

    for my $column (@amount_columns) {
      $column =~ /(.*)_(.*)/;
      $header_data{$column} = $form->{period}{$2}{$1}{fromdate};
    }
    $ss->header_row(\%header_data, format => 'heading4');
  }

  for my $column (@amount_columns) {
    $column =~ /(.*)_(.*)/;
    $header_data{$column} = $form->{period}{$2}{$1}{todate};
  }
  $ss->header_row(\%header_data)->freeze_panes(undef, $tab + 1);

  my %total = (description => $locale->text('Income / (Loss)'));
  &_ss_section($ss, $_, \@amount_columns, \%total) for @categories;

  $ss->data_row(\%total, format => 'total') if $report_code eq 'income_statement';

  $ss->finish;

  $form->download_tmpfile(\%myconfig, "$form->{title}-$form->{company}.xlsx");
}

sub _ss_section {
  my ($ss, $category, $amount_columns, $total) = @_;

  my %subtotal;
  my %accounts = (
    A => $locale->text('Assets'),
    E => $locale->text('Expenses'),
    I => $locale->text('Income'),
    L => $locale->text('Liabilities'),
    Q => $locale->text('Equity'),
  );

  my %column_data = (description => $accounts{$category});
  $ss->data_row(\%column_data, format => 'subsubtotal');

  my $ml             = $category =~ /I|L|Q/ ? 1 : -1;
  my $print_subtotal = 0;
  for my $accno (sort keys $form->{$category}->%*) {
    my $charttype = $form->{$category}{$accno}{this}{0}{charttype}
      || $form->{$category}{$accno}{previous}{0}{charttype};
    my $do_print
      = $charttype eq 'H' && $form->{l_heading} || $charttype eq 'A' && $form->{l_account};

    if ($print_subtotal && $charttype eq 'H') {
      &_ss_subtotal($ss, \%subtotal);
    }

    $print_subtotal = 1;

    %column_data = (accno => $accno, description => $form->{accounts}{$accno}{description});
    if ($charttype eq 'H') {
      %subtotal = (accno => $accno, description => $form->{accounts}{$accno}{description});
    }

    for my $column (@$amount_columns) {
      my ($year, $period) = $column =~ /(.*)_(.*)/;
      if ($charttype eq 'H') {
        $subtotal{$column} = $form->{$category}{$accno}{$year}{$period}{amount} * $ml;
        $form->{$category}{$accno}{$year}{$period}{amount} = 0;
      }

      my $amount = $form->{$category}{$accno}{$year}{$period}{amount};
      $column_data{$column} = $amount * $ml || '';

      $total->{$category}{$column} += $amount * $ml;
      $total->{$column} += $amount;
    }

    $ss->data_row(\%column_data) if $do_print;
  }

  if ($category eq 'Q') {
    %column_data = (description => $locale->text('Current Earnings'));

    for my $column (@$amount_columns) {
      my ($year, $period) = $column =~ /(.*)_(.*)/;

      my $currentearnings
        = $total->{A}{$column} - $total->{L}{$column} - $total->{Q}{$column};
      $column_data{$column} = $currentearnings;

      $subtotal{$column}   += $currentearnings if $form->{l_subtotal} && $form->{l_heading};
      $total->{Q}{$column} += $currentearnings;
    }

    $ss->crlf->data_row(\%column_data, format => 'subtotal')->crlf;
  }

  &_ss_subtotal($ss, \%subtotal);

  %column_data
    = (description => $locale->text('Total') . qq| $accounts{$category}|, $total->{$category}->%*);
  $ss->data_row(\%column_data, format => 'subtotal')->crlf;
}

sub _ss_subtotal {
  my ($ss, $subtotal) = @_;

  if ($form->{l_subtotal} && $subtotal->{accno}) {
    $ss->data_row($subtotal, format => 'subsubtotal')->crlf;
    $subtotal = {};
  }
}

1;

=encoding utf8

=head1 NAME

bin/mozilla/rpss.pl - Spreadsheet Functions for Yearend Reports

=head1 DESCRIPTION

L<bin::mozilla::ss> contains functions to create and download spreadsheets for yearend reports.

=head1 DEPENDENCIES

L<bin::mozilla::ss>

=over

=item * uses
L<Excel::Writer::XLSX>,
L<SL::Spreadsheet>

=back

=head1 FUNCTIONS

L<bin::mozilla::ss> implements the following functions:

=head2 yearend_spreadsheet

  &yearend_spreadsheet($report_code, $periods);

=cut
