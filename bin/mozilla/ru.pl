#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2018-2019
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#  Version: 0.1
#
#======================================================================
#
# routines and frontend for recently used objects
#
#======================================================================

use SL::RU;

sub delete_recent {
  RU->delete(\%myconfig, $form);
}

sub list_recent {
  my %labels = (
    RU::AP_TRANSACTION    => $locale->text('AP Transactions'),
    RU::AR_TRANSACTION    => $locale->text('AR Transactions'),
    RU::CUSTOMER          => $locale->text('Customers'),
    RU::ITEM              => $locale->text('Items'),
    RU::PURCHASE_ORDER    => $locale->text('Purchase Orders'),
    RU::REQUEST_QUOTATION => $locale->text('Request for Quotations'),
    RU::SALES_INVOICE     => $locale->text('Sales Invoices'),
    RU::SALES_ORDER       => $locale->text('Sales Orders'),
    RU::SALES_QUOTATION   => $locale->text('Quotations'),
    RU::VENDOR            => $locale->text('Vendors'),
    RU::VENDOR_INVOICE    => $locale->text('Vendor Invoices'),
  );

  $callback = "$form->{script}?action=list_recent";
  for (qw|sort direction path login|) { $callback .= "&$_=$form->{$_}" }
  $callback = $form->escape($callback);

  RU->list(\%myconfig, $form);

  $href = "$form->{script}?action=list_recent";
  for (qw|direction oldsort path login|) { $href .= "&$_=$form->{$_}" }

  my @columns = qw|number description|;
  if ($form->{sort} eq 'code') {
    unshift @columns, 'code';
  } else {
    push @columns, 'code';
  }

  my @column_index = @columns;
  $column_header{number}
    = qq|<th width=1%><a class=listheading href="$href&sort=number">|
    . $locale->text('Number')
    . '</a></th>';
  $column_header{description}
    = qq|<th><a class=listheading href="$href&sort=description">|
    . $locale->text('Description')
    . '</a></th>';
  $column_header{code}
    = qq|<th><a class=listheading href="$href&sort=code">|
    . $locale->text('Category')
    . "</a></th>";

  $form->{title}
    = ($form->{title}) ? $form->{title} : $locale->text('Recently Used');
  $form->{title} .= " / $myconfig{name}";

  my $version_url
    = qq|am.pl?path=$form->{path}&login=$form->{login}&action=company_logo|;

  $form->header;

  print qq|
<body>
<table width=100%>
  <tr>
    <th>
      <a href="$version_url"><img src=$images/sql-ledger.png border=0></a>
    </th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th class=listtop><a class=listtop href="$href">$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
        </tr>
|;

  my ($j, $sameitem);
  for my $ref (@{$form->{all_recent}}) {
    $url = RU::CODES->{$ref->{code}}
      . "&id=$ref->{object_id}&path=$form->{path}&login=$form->{login}&callback=$callback";

    $column_data{number}      = qq|<td><a href="$url">$ref->{number}</a></td>|;
    $column_data{description} = "<td>$ref->{description}</td>";
    $column_data{code}        = "<td>$labels{$ref->{code}}</td>";

    if ($form->{sort}) {
      my $new_sameitem = $column_data{$form->{sort}};
      if ($new_sameitem eq $sameitem) {
        $column_data{$form->{sort}} = q|<td>&nbsp;</td>|;
      }
      $sameitem = $new_sameitem;
    }

    $j++;
    $j %= 2;
    print qq|
        <tr class=listrow$j>
|;

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
        </tr>
|;
  }

  print qq|

</body>
</html>
|;
}

sub register_recent {
  RU->register(\%myconfig, $form);
}

1;

=encoding utf8

=head1 NAME

bin/mozilla/ru.pl - routines and frontend for recently used objects

=head1 DESCRIPTION

L<bin::mozilla::ru> contains routines and frontend for recently used object.

=head1 DEPENDENCIES

L<bin::mozilla::ru>

=over

=item * uses
L<SL::RU>

=back

=head1 FUNCTIONS

=head2 delete_recent

=head2 list_recent

=head2 register_recent

=cut
