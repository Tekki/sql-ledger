# Introduction to the API

## JSON and HTML API

There are two ways to communicate programmatically with SQL-Ledger. The first
is to make requests to the API endpoint that returns a JSON response. The
second is to simulate a browser and imitate step by step the actions of a user.

## Prerequisites

In both approaches scripts that run in the SQL-Ledger infrastructure are
called.

The following code is written in Perl, but the same method can be used in other
languages, for example in Python or in PowerShell. It is even possible to make
simple API calls in the browser, with `curl` or `wget`.

To run the examples, two, respectively three additional Perl modules have to be
installed with

```
cpanm Mojolicious \
  Print::Colored  \
  HTML::Form      # only for the HTML API
```

## Authentication

### Access token (recommended)

To get an access token, the first call has to be made to `api.pl` with
`username` and `password` as parameters.

| parameter | value         |
|-----------|---------------|
| action    | 'get\_token'  |
| login     | your username |
| password  | your password |

```json
{ "token": ... }
```

Returns a hash that contains the access token. The token has to be used as
`SL-Token` in the header of the requests. It is valid until the session
expires, this means until the same user logs in again.

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
    "$sl_url/api.pl",
    form => {action => 'get_token', password => $sl_password, %sl_params}
  )->result;

my $json      = $res->json;
my $token     = $json->{token};
my %sl_header = ('SL-Token' => $token);
say_info "Access token: $token";
```

SQL-Ledger always returns 200 as status code, so you probably want to check
the response for login errors in the body of the response.

```perl
if ($json->{error}) {
  die color_error $json->{message};
}
```

In the following examples `%sl_header` with the token is included as
header in every request.

### Login with every request (alternative)

As an alternative it is possible to login with every request. This may be
useful if just a single request has to be made, but not recommended for
multiple requests.

```perl
my %sl_params = (login => $sl_username, password => $sl_password, path => 'bin/mozilla',);
```

For this, add the password to `%sl_params` and directly call one of the
following endpoints.

## JSON API

Calls to the JSON API are made to `api.pl` with the endpoint in the `action`
parameter.

### List Accounts

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
    \%sl_header,
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

### Search Customers

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
    \%sl_header,
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

### Customer Details

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

$res = $ua->post(
    "$sl_url/api.pl",
    \%sl_header,
    form => {action => 'customer_details', %search_params, %sl_params}
  )->result;

say_info dumper $res->json;

```

### Search Order

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
    \%sl_header,
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

### Search Transaction

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
    \%sl_header,
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

### Invoice Details

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
    \%sl_header,
    form => {action => 'invoice_details', %search_params, %sl_params}
  )->result;

if ($res->json->{id}) {
  say_info dumper $res->json;
} else {
  say_warn 'No invoice found';
}
```

### Add Payment

Add a payment to a sales invoice.

| parameter      | value                              |
|----------------|------------------------------------|
| action         | 'add\_payment'                     |
| amount         | amount paid                        |
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
    \%sl_header,
    form => {action => 'add_payment', %payment_params, %sl_params}
  )->result;

if ($res->json->{result} eq 'success') {
  say_ok 'Payment added.';
} else {
  say_error 'Error, payment not added!';
}
```

### Add Reference

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
    \%sl_header,
    form => {action => 'add_reference', %reference_params, %sl_params}
  )->result;

if ($res->json->{result} eq 'success') {
  say_ok 'Reference added.';
} else {
  say_error 'Error, reference not added!';
}
```
## HTML API

This is not a real API, we just reproduce what a user is doing when he works
with SQL-Ledger in a browser.

### Preparation

To get a consistent behavior of the screens, the Drop-down Limit in the
Preferences of the user should be set to zero. As already mentioned, we need
more Perl modules and the header of the script looks like this:

```perl
#! /usr/bin/env perl
use Mojo::Base -strict;
use open ':std', ':encoding(utf8)';

use HTML::Form;
use Mojo::Util 'decode';
use Mojo::UserAgent;
use Print::Colored ':all';
```

### Add an invoice with 3 rows

As an example we create an invoice for customer with number 1109. We start with
creating variables for the content of the invoice.

```perl
# content of the invoice

my $customernumber = 1109;
my $description    = 'Generated Invoice';
my @rows
  = ({partnumber => 300016, qty => 5}, {partnumber => 300011, qty => 2}, {partnumber => 300005},);
```

The first step for a user would be to click on `AR--Sales Invoice` in the menu.
In the script we simulate this with a call to `is.pl`.

```perl
# open page AR--Sales Invoice

$res = $ua->post(
    "$sl_url/is.pl",
    \%sl_header,
    form => {action => 'add',
    type => 'invoice', %sl_params}
  )->result;
```

Next he would choose the customer and add the description.

```perl
# add customer number and description

%form                 = HTML::Form->parse(decode($charset, $res->body), %parse_params)->form;
$form{customernumber} = $customernumber;
$form{description}    = $description;

$form{action} = 'update';
$res = $ua->post("$sl_url/is.pl", \%sl_header, form => \%form)->result;
```

Then he would add the part numbers and quantities to the rows and press the
`Update` button after each row.

```perl
# add rows

my $i;
for my $row (@rows) {
  $i++;

  %form = HTML::Form->parse(decode($charset, $res->body), %parse_params)->form;
  for (keys %$row) {
    $form{"${_}_$i"} = $row->{$_};
  }

  $form{action} = 'update';
  $res = $ua->post("$sl_url/is.pl", \%sl_header, form => \%form)->result;
}
```

At the end, the user would press the `Post` button.

```perl
# post invoice

%form         = HTML::Form->parse(decode($charset, $res->body), %parse_params)->form;
$form{action} = 'post';
$res          = $ua->post("$sl_url/is.pl", \%sl_header, form => \%form)->result;

say_ok 'Invoice posted.';
```

Now the new invoice is created and it appears at the top of the list of this
user's recently used objects.
