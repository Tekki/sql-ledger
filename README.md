# What is SQL-Ledger?

[SQL-Ledger](https://sql-ledger.com) is an open source ERP and accounting
system. It gives you all the functionality you need for quotations, order
management, invoices, payrolls and much more. The program is written in
[Perl](https://www.perl.org), runs on an [Apache](https://httpd.apache.org)
webserver, uses a [PostgreSQL](https://www.postgresql.org) database and is
highly configurable.

# About this repo

SQL-Ledger is developed by [DWS Systems Inc.](https://sql-ledger.com). The
`master` branch contains the original version from DWS. It has version tags, so
you can download a specific version back to 2.6.0 from October 1, 2005.

The `full` branch, which is checked out by default, provides some additions:

* real Unicode support
* extended keyboard shortcuts ([docs](doc/shortcuts.md))
* spreadsheet downloads
* recently used objects
* improved document management with drag and drop and deduplication
* dark mode
* markdown for bold, italic and links in templates
* database snapshots
* encrypted backups
* JSON API ([introduction](doc/api.md))
* support for ISO 20022 camt.054 files
* Docker files for containerized test environment
* WLprinter
* minimalistic documentation
* Swiss charts of accounts in German, French and Italian
* several security patches

# Installation

To install the program on Debian, you can use the [Ansible Role for
SQL-Ledger](https://github.com/Tekki/ansible-sql-ledger). If you are on a
different distribution, either follow the [instructions from
DWS](https://sql-ledger.com/cgi-bin/nav.pl?page=source/readme.txt&title=README),
or open an issue on GitHub.

# Encrypted Backups

If [GnuPG](https://gnupg.org/) is installed on your server, you can
use it to encrypt backups. Uncomment the `$gpg` variable in
`sql-ledger.conf`, create a directory `/var/www/gnupg` and change its
owner to `www-data:www-data` on Debian or `apache:apache` on Fedora
based distributions.

# Unicode Support

In difference to the original SQL-Ledger, the version in the `full` branch
internally works with [Unicode characters](https://perldoc.perl.org/perlunicode.html).
This requires that your database, your templates and translations are
all encoded in UTF-8.

# Docker

With

    cd docker
    docker-compose -p sql-ledger up -d

you can start a simple test environment (without LaTeX support) on
Debian Bookworm. SQL-Ledger will run at
[localhost/sql-ledger](http://localhost/sql-ledger). At
[localhost:8080](http://localhost:8080) and
[localhost:8085](http://localhost:8085) you find the database
management tools [Adminer](https://www.adminer.org) and
[pgAdmin](https://pgadmin.org). You'll have to connect them to the
PostgreSQL database that runs on service `db` with username and
password `sql-ledger`.

If you want to try the program on AlmaLinux 9, use the second compose
file

    cd docker
    docker-compose -f docker-compose-alma.yml -p sql-ledger up -d

# WLprinter

WLprinter, included in the `full` branch, is a [Java](https://java.com) program
that is executed on the client PC and allows to print directly from SQL-Ledger
to your local printers. It is available for printing if you add a printer with
command `wlprinter` at `System--Workstations`. The client program is started
from `Batch--WLprinter`. You will have to add a Java security exception for
your SQL-Ledger server.

# Documentation

The documentation is very minimalistic and doesn't contain much more than the
function names of the different modules. If you have
[Mojolicious](https://metacpan.org/pod/Mojolicious) and
[Mojolicious::Plugin::PODViewer](https://metacpan.org/pod/Mojolicious::Plugin::PODViewer)
installed, you can start a perldoc server from your SQL-Ledger base directory
with

    perl -I. -Mojo -E'plugin "PODViewer"; a->start' daemon

and browse to
[localhost:3000/perldoc/sql-ledger](http://localhost:3000/perldoc/sql-ledger).

# Contributing

As mentioned above, what you find here is more or less a copy of the code from
DWS. 'copy' means that the code flows from DWS to here and rarely in the other
direction. 'more or less' means that the differences between the `full` and the
`master` branch should always be as small that it is possible to include
updates without problems. 2 merge conflics are not a problem, but 100 conflics
are.

It follows that if you want the DWS code to change, you have to speak with
them. If on the other hand you want this repo to change, don't care about the
moon calendar and create an issue.

It was mentioned too that the `full` branch contains some additions, like
Unicode support and documentation. So it's probably more correct to call it a
superset of the DWS code.
