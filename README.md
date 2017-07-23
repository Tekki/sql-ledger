What is SQL-Ledger?
===================

SQL-Ledger is an open source ERP and accounting system. It gives you all the functionality you need for quotations, order management, invoices, payrolls and much more. The program is written in Perl, runs on an Apache webserver, uses a PostgreSQL database and is highly configurable.

About this repo
===============

SQL-Ledger is developed by [DWS Systems Inc.](http://sql-ledger.com). The `master` branch contains the original version from DWS. It has version tags, so you can download a specific version back to 2.6.0 from October 1, 2005.

The `full` branch, which is checked out by default, provides some additions:

* WLprinter
* JSON API
* full UTF-8 support
* Swiss charts of accounts in German, French and Italian
* security patch for template editor

Installation
============

To install the program on Debian, you can use the [Ansible Role for SQL-Ledger](https://github.com/Tekki/ansible-sql-ledger). If you are on a different distribution, either follow the [instructions from DWS](http://sql-ledger.com/cgi-bin/nav.pl?page=source/readme.txt&title=README), or open an issue in the other repo (the chances that you get an update depend on your Github name, the weather and the lunar phase).

WLprinter
=========

WLprinter, included in the `full` branch, is a Java program that is executed on the client PC and allows to print directly from SQL-Ledger to your local printers. It is available for printing if you add a printer with command `wlprinter` at `System--Workstations`. The client program is started from `Batch--WLprinter`. You will probably have to add a Java security exception for your SQL-Ledger server.

Contributing
============

As mentioned above, what you find here is more or less a copy of the code from DWS. 'copy' means that the code flows from DWS to here and rarely in the other direction. 'more or less' means that the differences between the `full` and the `master` branch should always be as small that it is possible to include updates without problems. 2 merge conflics are not a problem, but 100 conflics are.

So if you want the DWS code to change, you have to speak with them. If on the other hand you want this repo to change, don't care about the moon calendar and create an issue.
