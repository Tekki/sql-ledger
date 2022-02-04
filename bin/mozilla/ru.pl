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

sub list_recent {
  my %labels = (
    RU::AP_TRANSACTION    => $locale->text('AP Transactions'),
    RU::AR_TRANSACTION    => $locale->text('AR Transactions'),
    RU::CUSTOMER          => $locale->text('Customers'),
    RU::GL_TRANSACTION    => $locale->text('GL Transactions'),
    RU::ITEM              => $locale->text('Items'),
    RU::PROJECT           => $locale->text('Projects'),
    RU::PURCHASE_ORDER    => $locale->text('Purchase Orders'),
    RU::REQUEST_QUOTATION => $locale->text('Request for Quotations'),
    RU::SALES_INVOICE     => $locale->text('Sales Invoices'),
    RU::SALES_ORDER       => $locale->text('Sales Orders'),
    RU::SALES_QUOTATION   => $locale->text('Quotations'),
    RU::TIMECARD          => $locale->text('Time Cards'),
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
    = qq|<th width=1%><a class=listheading href="$href&sort=number" accesskey="N" title="[N]">|
    . $locale->text('Number')
    . '</a></th>';
  $column_header{description}
    = qq|<th><a class=listheading href="$href&sort=description" accesskey="D" title="[D]">|
    . $locale->text('Description')
    . '</a></th>';
  $column_header{code}
    = qq|<th><a class=listheading href="$href&sort=code" accesskey="C" title="[C]">|
    . $locale->text('Category')
    . "</a></th>";

  $form->{title}
    = ($form->{title}) ? $form->{title} : $locale->text('Recently Used');
  $form->{title} .= " / $myconfig{name}";

  my $version_url
    = qq|am.pl?path=$form->{path}&login=$form->{login}&action=company_logo|;

  $form->header;

  print qq|
<body onload="window.focus()">
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

  my ($i, $j, $samecode);
  my $url_suffix = "&path=$form->{path}&login=$form->{login}&callback=$callback";
  my $unregister_url
    = "$form->{script}?action=unregister_recent$url_suffix";
  for my $ref (@{$form->{all_recent}}) {
    $i++;
    my $object_url = RU::CODES->{$ref->{code}}->{object}
      . "&id=$ref->{object_id}$url_suffix";

    my $accesskey = $i < 10 ? qq| accesskey="$i" title="[$i]"| : '';
    $column_data{number}
      = qq|<td><a href="$object_url"$accesskey>$ref->{number}</a></td>|;
    $column_data{description} = "<td>$ref->{description}</td>";
    if ($ref->{code} eq $samecode) {
      $column_data{code} = q|<td>&nbsp;</td>|;
    } else {
      my $report_url = RU::CODES->{$ref->{code}}->{report}
        . "&path=$form->{path}&login=$form->{login}";

      $column_data{code}
        = qq|<td>
  <a href="$report_url">$labels{$ref->{code}}</a>
  <a href="$unregister_url&code=$ref->{code}">&#10005</a>
</td>|;
      $samecode = $ref->{code};
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
      </table>
    </td>
  </tr>
</table>

</body>
</html>
|;
}

sub unregister_recent {
  RU->unregister(\%myconfig, $form);
  $form->redirect;
}

1;

=encoding utf8

=head1 NAME

bin/mozilla/ru.pl - frontend for recently used objects

=head1 DESCRIPTION

L<bin::mozilla::ru> contains frontend for recently used object.

=head1 DEPENDENCIES

L<bin::mozilla::ru>

=over

=item * uses
L<SL::RU>

=back

=head1 FUNCTIONS

=head2 list_recent

=cut
