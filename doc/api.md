# Introduction to the API

## Prerequisites

The API is an additional script that runs in the SQL-Ledger infrastructure.
This means it uses the same frontend as the other parts of SQL-Ledger and calls
to the endpoints are made with the `action` parameter. The client that makes
these calls must be able to store SQL-Ledger's authentication cookie.

The following examples are written in Perl, but the same approach can be used
in other languages. It is even possible to access the API from the browser.

To run the examples, two additional Perl modules have to be installed with
```
cpanm Mojolicious Print::Colored
```

## Authentication

### Authenticated client (recommended)

To create an authenticated client, the first call has to be made to `login.pl`
with `username` and `password` as parameters.

| parameter | value         |
|-----------|---------------|
| action    | 'login'       |
| login     | your username |
| password  | your password |

As SQL-Ledger always returns 200 as status code you probably want to check
the response for login errors.

```perl
#! /usr/bin/env perl
use Mojo::Base -strict;
use open ':std', ':encoding(utf8)';

use Mojo::UserAgent;
use Print::Colored ':all';

my $sl_url = prompt_input 'URL: ';

say 'Login data for SQL-Ledger';

my $sl_username = prompt_input 'Username: ';

my $sl_password = password_input 'Password: ';

my $ua        = Mojo::UserAgent->new;
my %sl_params = (login => $sl_username, path => 'bin/mozilla',);
my %search_params;

my $res = $ua->post(
    "$sl_url/login.pl",
    form => {action => 'login', password => $sl_password, %sl_params}
  )->result;
```

For the following examples `$ua` created with this code is used as client. The
next calls are always made to `api.pl`.

### Login with every request (alternative)

As an alternative it is possible to login with every request. This maybe useful
if just a single request has to be made to the API, but not recommended for
multiple requests.

```perl
my %sl_params = (login => $sl_username, password => $sl_password, path => 'bin/mozilla',);
```

For this, add the password to `%sl_params` and directly call one of the
following endpoints.

## List Accounts

List all accounts from the chart of accounts.

| parameter | value            |
|-----------|------------------|
| action    | 'list\_accounts' |

```json
{ "accounts": [ ... ] }
```

Returns a hash with an array of all accounts.

```perl
$res = $ua->post(
    "$sl_url/api.pl",
    form => {action => 'list_accounts', %sl_params}
  )->result;

if (my $accounts = $res->json->{accounts}) {
  say_ok @$accounts . ' accounts found';

  for my $account (@$accounts) {
    printf "%-6s %-20s\n", $account->{accno}, $account->{description};
  }

} else {
  say_warn 'No accounts found';
}
```

## Search Customers

Search customers using any of the parameters from `Customers--Reports--Search`.

| parameter | value              |
|-----------|--------------------|
| action    | 'search\_customer' |

```json
{ "customers": [ ... ] }
```

Returns a hash with an array of the customers that meet the search criteria. If
no customers are found the array is `null`.

```perl
my %search_params = (name => 'hans');  # search for name like 'hans'

$res = $ua->post(
    "$sl_url/api.pl",
    form => {action => 'search_customer', %search_params, %sl_params}
  )->result;

if (my $customers = $res->json->{customers}) {
  say_ok @$customers . ' customers found';

  for my $customer (@$customers) {
    printf "%-30s %-10s %s\n", $customer->{name}, $customer->{typeofcontact}, $customer->{email};
  }

} else {
  say_warn 'No customers found';
}
```

## Customer Details

Load all details of a customer.

| parameter | value               |
|-----------|---------------------|
| action    | 'customer\_details' |
| id        | a valid customer ID |

```json
{ "id": ..., "name": ..., ... }
```

Returns a hash containing all the values for this customer. If no ID is
provided or if it does not exists the hash just contains some default values.

```perl
%search_params = (id => $customer_id);  # with a valid ID

$res
  = $ua->post("$sl_url/api.pl", form => {action => 'customer_details', %search_params, %sl_params})
  ->result;

say_info dumper $res->json;

```

## Search Order

Search for a sales or purchase order using any of the parameters from `Order
Entry--Reports--Sales Orders`.

| parameter | value                                                 |
|-----------|-------------------------------------------------------|
| action    | 'search\_order'                                       |
| open      | default '1'                                           |
| type      | default 'sales\_order', alternative 'purchase\_order' |
| vc        | default 'customer', alternative 'vendor'              |

```json
{ "orders": [ ... ] }
```

Returns a hash with an array of the orders that meet the search criteria. If no
orders are found the array is `null`.

```perl
# list all closed orders from 2020
%search_params = (
  closed => 1,
  transdatefrom => '2020-01-01',
  transdateto => '2020-12-31'
);

$res = $ua->post(
    "$sl_url/api.pl",
    form => {action => 'search_order', %search_params, %sl_params}
  )->result;

if (my $orders = $res->json->{orders}) {
  say_ok @$orders . ' orders found';

  for my $order (@$orders) {
    printf "%-6s %-10s %s\n", $order->{ordnumber}, $order->{transdate}, $order->{name};
  }

} else {
  say_warn 'No orders found';
}
```

## Search Transaction

Search for transactions using any of the parameters from
`AR--Reports--Transactions` or `AR--Reports--Outstanding`.

| parameter | value                                   |
|-----------|-----------------------------------------|
| action    | 'search\_transaction'                   |
| open      | default '1' if `outstanding` is not set |
| summary   | default '1'                             |

```json
{ "transactions": [ ... ] }
```

Returns a hash with an array of the transactions that meet the search criteria.
If none are found the array is `null`.

```perl
# list open invoices from December 31, 2020
%search_params = (
  outstanding => 1,
  transdateto => '2020-12-31'
);

$res = $ua->post(
    "$sl_url/api.pl",
      form => {action => 'search_transaction', %search_params, %sl_params}
  )->result;

if (my $transactions = $res->json->{transactions}) {
  say_ok @$transactions . ' transactions found';

  for my $transaction (@$transactions) {
    printf "%-6s %-10s %-30s %9.2f %-10s\n", $transaction->{invnumber}, $transaction->{transdate},
      $transaction->{name}, $transaction->{amount}, $transaction->{datepaid} || '';
  }

} else {
  say_warn 'No transactions found';
}
```

## Invoice Details

Load all the details of a sales invoice.

| parameter | value                       |
|-----------|-----------------------------|
| action    | 'invoice\_details'          |
| id        | valid ID of a sales invoice |
| dcn       | DCN                         |
| invnumber | invoice number              |
| waybill   | content of field `waybill`  |

Only the first of `id`, `dcn`, `invnumber`, or `waybill` is taken into account
and the most recent invoice that meets the criteria is returned.

```json
{ "id": ..., "invnumber": ..., ... }
```

Returns a hash containing all the values for the invoice. If none is found the
hash contains no ID and just some default values.

```perl
%search_params = (dcn => $dcn);  # a valid DCN

$res = $ua->post(
    "$sl_url/api.pl",
    form => {action => 'invoice_details', %search_params, %sl_params}
  )->result;

if ($res->json->{id}) {
  say_info dumper $res->json;
} else {
  say_warn 'No invoice found';
}
```

## Add Payment

Add a payment to a sales invoice.

| parameter      | value                              |
|----------------|------------------------------------|
| action         | 'add\_payment'                     |
| amount         | amout paid                         |
| datepaid       | payment date                       |
| currency       | (optional)                         |
| exchangerate   | required if `currency` is provided |
| memo           | (optional)                         |
| paymentaccount | account number for the payment     |
| paymentmethod  | (optional)                         |
| source         | (optional)                         |

The invoice has to be identified using one of `id`, `dcn`, `invnumber`, or
`waybill`.

```json
{ "result": "success" }
```
Returns success or error.

```perl
my %payment_params = (
  amount         => $amount,
  dcn            => $dcn,
  datepaid       => $date,
  paymentaccount => $account,
);

$res = $ua->post(
    "$sl_url/api.pl",
    form => {action => 'add_payment', %payment_params, %sl_params}
  )->result;

if ($res->json->{result} eq 'success') {
  say_ok 'Payment added.';
} else {
  say_error 'Error, payment not added!';
}
```

## Add Reference

Add a reference to an external document to a sales invoice.

| parameter            | value                                    |
|----------------------|------------------------------------------|
| action               | 'add\_reference'                         |
| referencecode        | code of the reference to create the link |
| referencedescription | description of the reference             |

The invoice has to be identified using one of `id`, `dcn`, `invnumber`, or
`waybill`.

```json
{ "result": "success" }
```
Returns success or error.

```perl
my %reference_params = (
  dcn                  => $dcn,
  referencecode        => $code,
  referencedescription => $description,
);

$res = $ua->post(
    "$sl_url/api.pl",
    form => {action => 'add_reference', %reference_params, %sl_params}
  )->result;

if ($res->json->{result} eq 'success') {
  say_ok 'Reference added.';
} else {
  say_error 'Error, reference not added!';
}
```
