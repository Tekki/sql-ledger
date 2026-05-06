[SQL-Ledger Documentation](index.md) ▶ Customization

# Customization

Customization means modifying the program itself, either by adding new or by
changing existing functionality. It is used when then the possibilities provided
by the [configuration](configuration.md) are not sufficient.

To customize the program, add files to `bin/mozilla/custom` or to its
subdirectories. Don't edit the original program files; this would make it
difficult or even impossible to update to newer versions.

## Structure

Custom files are either named `menu.ini` or after one of the `*.pl` files in
`bin/mozilla`. They are processed after the original files in the following
order:

| # | directory                         | active for                     |
|---|-----------------------------------|--------------------------------|
| 1 | `bin/mozilla/custom`              | the whole server               |
| 2 | `bin/mozilla/custom/company`      | all users of dataset `company` |
| 3 | `bin/mozilla/custom/user@company` | only `user` of `company`       |

If the files contain the same directives, the earlier ones are replaced by the
later ones.

## Menu

Menu files are called `menu.ini`. They add new entries inside the existing tree
or additional entries below `Logout`. Horizontal lines can be used to separate
the headers.

```
[<hr>]

[My reports]

[My reports--Outstanding Invoices]
module=ar.pl
action=search
outstanding=1
nextsub=transactions
```

Experienced users create menu entries that directly generate the output of
reports.

## Program code

Custom program files use the same names as the files in `bin/mozilla`. They are
loaded whenever the original file with the same name is called. If the contain
the a function name that exists in the original, it is replaced. If the function
names are new, the are added to the program.

```perl
# bin/mozilla/custom/aa.pl

sub add {
  # replaces the add function
}


sub my_new_function {
  # creates a new function
}
```

### Customized Reports

The sample files for customized reports, located in `doc/custom`, are good
examples to learn how to to create custom program files. They override
functions, for example `_search_defaults` and `_transactions_defaults` in
`bin/mozilla/am.pl`. They are used to modify the default values on the frontends
of the reports and for some of them to change the order of the columns and their
sort order.

| sample                  | target                     | for reports                                      |
|-------------------------|----------------------------|--------------------------------------------------|
| [aa.txt](custom/aa.txt) | `bin/mozilla/custom/aa.pl` | AR--Reports--Transactions                        |
|                         |                            | AR--Reports--Outstanding                         |
|                         |                            | AP--Reports--Transactions                        |
|                         |                            | AP--Reports--Outstanding                         |
| [ct.txt](custom/ct.txt) | `bin/mozilla/custom/ct.pl` | Customers--Reports--Search                       |
|                         |                            | Vendors--Reports--Search                         |
| [gl.txt](custom/gl.txt) | `bin/mozilla/custom/gl.pl` | General Ledger--Reports                          |
| [rp.txt](custom/rp.txt) | `bin/mozilla/custom/rp.pl` | AR--Reports--AR Aging                            |
|                         |                            | AR--Reports--Reminder                            |
|                         |                            | AR--Reports--Tax collected                       |
|                         |                            | AR--Reports--Non-taxable                         |
|                         |                            | AP--Reports--AP Aging                            |
|                         |                            | AP--Reports--Tax paid                            |
|                         |                            | AP--Reports--Non-taxable                         |
|                         |                            | Cash--Reports--Receipts                          |
|                         |                            | Cash--Reports--Payments                          |
|                         |                            | Projects & Jobs--Projects--Reports--Transactions |
|                         |                            | Reports--Trial Balance                           |
|                         |                            | Reports--Income Statement                        |
|                         |                            | Reports--Balance Sheet                           |
