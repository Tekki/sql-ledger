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

sub account_spreadsheet {
  my ($report_options) = @_;

  $form->{title} = $locale->text('Accounts');

  my $ss = SL::Spreadsheet->new($form, $userspath);

  $ss->change_format(':all', color => undef, border_color => undef, underline => 0);
  $ss->change_format('total', bottom => 1);

  # trial balance
  &_trialbalance_worksheet($ss);

  # accounts

  my %spreadsheet_info = (
    columns => {
      accnos      => 'text',
      cleared     => 'bool',
      credit      => 'nonzero_decimal',
      debit       => 'nonzero_decimal',
      description => 'text',
      reference   => 'link',
      source      => 'text',
      transdate   => 'date',
    },
  );

  my %header_data = (
    accnos      => $locale->text('Contra'),
    balance     => $locale->text('Balance'),
    cleared     => $locale->text('R'),
    credit      => $locale->text('Credit'),
    debit       => $locale->text('Debit'),
    description => $locale->text('Description'),
    reference   => $locale->text('Reference'),
    source      => $locale->text('Source'),
    transdate   => $locale->text('Date'),
  );

  $ss->structure(\%spreadsheet_info);

  my $oldform = $form;
  for my $ref (sort { $a->{accno} cmp $b->{accno} } @{$oldform->{TB}}) {
    next unless $ref->{charttype} eq 'A';

    $form = bless {%$oldform}, Form;
    $form->{accno}     = $ref->{accno};
    $form->{l_accno}   = 1;
    $form->{sort}      = 'transdate';
    $form->{subreport} = 1;

    &_account_worksheet($ss, \%header_data);
  }

  $ss->finish;

  $form->download_tmpfile(\%myconfig, "$oldform->{title}-$oldform->{company}.xlsx");
}

sub _trialbalance_worksheet {
  my ($ss) = @_;

  # trial balance

  my $title = $locale->text('Trial Balance');

  my %spreadsheet_info = (
    columns => {
      accno       => 'link',
      address     => 'text',
      credit      => 'nonzero_decimal',
      debit       => 'nonzero_decimal',
      description => 'text',
    },
  );

  my @column_index = qw|accno description begbalance debit credit endbalance|;

  my %header_data = (
    accno => $form->{accounttype} eq 'gifi' ? $locale->text('GIFI') : $locale->text('Account'),
    begbalance  => $locale->text('Beginning Balance'),
    credit      => $locale->text('Credit'),
    debit       => $locale->text('Debit'),
    description => $locale->text('Description'),
    endbalance  => $locale->text('Ending Balance'),
  );

  $ss->worksheet(title => $title)->structure(\%spreadsheet_info)->column_index(\@column_index)
    ->totalize(['debit', 'credit']);

  $ss->text($form->{company})->crlf;
  $ss->text($_)->crlf for split /\n/, $form->{address};
  $ss->crlf;

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

  $ss->crlf->header_row(\%header_data)->freeze_panes;

  for my $ref ($form->{TB}->@*) {
    next if $ref->{charttype} ne 'A';

    my $ml = ($ref->{category} =~ /(A|E)/) ? -1 : 1;
    $ml *= -1 if $ref->{contra};

    $ref->{begbalance} = $ref->{balance} * $ml;
    $ref->{endbalance} = ($ref->{balance} + $ref->{amount}) * $ml;
    $ref->{accno_link} = qq|internal:$ref->{accno}!A1|;

    $ss->table_row($ref);
  }
  $ss->total_row->adjust_columns;
}

sub _account_worksheet {
  my ($ss, $header_data) = @_;

  CA->all_transactions(\%myconfig, \%$form);

  my @column_index = qw|transdate reference description|;
  push @column_index, qw|source cleared| if $form->{link} =~ /_paid/;
  push @column_index, 'accnos'           if $form->{l_accno};
  push @column_index, qw|debit credit balance|;

  $ss->worksheet(title => $form->{accno})->column_index(\@column_index)
    ->totalize(['debit', 'credit']);

  $form->{title}
    = ($form->{accounttype} eq 'gifi') ? $locale->text('GIFI') : $locale->text('Account');
  $form->{title} .= " $form->{accno} - $form->{description}";
  $ss->title($form->{title})->crlf(2);

  $ss->crlf->header_row($header_data)->freeze_panes;

  my $ml = ($form->{category} =~ /(A|E)/) ? -1 : 1;
  $ml *= -1 if $form->{contra};

  $ss->table_row({balance => $form->{balance} * $ml, transdate => $form->{fromdate}});

  for my $ref ($form->{CA}->@*) {
    $form->{balance} += $ref->{amount};
    $ref->{balance} = $form->{balance} * $ml;

    $ref->{accnos} = join ', ', $ref->{accno}->@*;

    $ref->{reference_link} = qq|$ref->{module}.pl?action=edit&id=$ref->{id}|;

    $ss->table_row($ref);
  }

  $ss->total_row(update => {balance => $form->{balance} * $ml, transdate => $form->{todate}})
    ->adjust_columns;
}

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
  $ss->worksheet(form_title => 1)->structure(\%spreadsheet_info)->column_index($column_index)
    ->totalize([':decimal']);
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
  $ss->total_row->adjust_columns;

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

  $form->{title}
    = $reportcode eq 'balance_sheet'
    ? $locale->text('Balance Sheet')
    : $locale->text('Income Statement');
  $ss->worksheet(form_title => 1)->structure(\%spreadsheet_info)->column_index(\@column_index)
    ->maxwidth(50);

  $ss->text($form->{company})->crlf;
  $ss->text($_)->crlf for split /\n/, $form->{address};
  $ss->crlf;

  my (@categories, %header_data);
  if ($report_code eq 'balance_sheet') {
    @categories = qw|A L Q|;

    $ss->title($form->{title})->crlf(2);
    $ss->tab($tab)->text($locale->text('as at'), 'heading4')->lf->date($form->{todate}, 'heading4')
      ->crlf(2);

    if ($form->{department}) {
      (my $val) = split /--/, $form->{department};
      $ss->tab($tab)->text($val, 'heading4')->crlf(2);
    }

  } else {
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

  $ss->adjust_columns->finish;

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
