# What is SQL-Ledger?

[SQL-Ledger](https://sql-ledger.com) is an open source ERP and accounting
system. It gives you all the functionality you need for quotations, order
management, invoices, payrolls and much more. The program is written in
[Perl](https://www.perl.org), runs on an [Apache](https://httpd.apache.org)
webserver, uses a [PostgreSQL](https://www.postgresql.org) database and is
highly configurable.

# About this repo

SQL-Ledger was developed until 2023 by [DWS Systems Inc.](https://sql-ledger.com).
The `master` branch contains the original version from DWS. It has version tags,
so you can download a specific version back to 2.6.0 from October 1, 2005.

The `full` branch, checked out by default, is based on the latest DWS version
and contains more than 100 corrections and improvements. The most important
additions are:

* real Unicode support
* MFA with time-based one-time passwords (TOTP, codes from Authenticator App)
* extended keyboard shortcuts ([docs](doc/shortcuts.md))
* spreadsheet downloads
* recently used objects
* document management with drag and drop and deduplication
* data export for editing and reimport
* dark mode
* markdown for bold, italic and links in templates ([docs](doc/latex_templates.md#md))
* directive for QR Codes in templates ([docs](doc/latex_templates.md#qrcode))
* localized postal addresses (docs for [addresses](doc/localaddress.md), [templates](doc/latex_templates.md#localaddr))
* database snapshots
* encrypted backups
* JSON API ([introduction](doc/api.md))
* variables for Swiss QR Bill ([docs](doc/latex_templates.md#qrbill))
* import of Swiss QR Bills into invoices and transactions
* XML payment export, pain.001 Swiss Payment Standard 2024
* XML payment import, ISO 20022 camt.054
* Docker files for containerized test environment
* WLprinter
* minimalist documentation
* Swiss charts of accounts in German, French and Italian
* several security patches

# Installation

To install the program on Debian, you can use the [Ansible Role for
SQL-Ledger](https://github.com/Tekki/ansible-sql-ledger). If you are on a
different distribution, either follow the [instructions from
DWS](https://sql-ledger.com/cgi-bin/nav.pl?page=source/readme.txt&title=README),
or open an issue on GitHub.

The Perl modules required to run this application with all additions are:

| Module                 | Debian package                |
|------------------------|-------------------------------|
| Archive::Extract       | libarchive-extract-perl       |
| Archive::Zip           | libarchive-zip-perl           |
| DBD::Pg                | libdbd-pg-perl                |
| Excel::Writer::XLSX    | libexcel-writer-xlsx-perl     |
| Image::Magick          | libimage-magick-perl          |
| Imager::zxing          | -                             |
| IO::Socket::SSL        | libio-socket-ssl-perl         |
| Mojolicious            | libmojolicious-perl           |
| Spreadsheet::ParseXLSX | libspreadsheet-parsexlsx-perl |
| Text::QRCode           | libtext-qrcode-perl           |

For a simple system, you should at least install `Archive::Zip`, `DBD::Pg`, and
`Excel::Writer::XLSX`. `Image::Magick` and `Imager::zxing` are only required for
import of QR Bills.

# Encrypted Backups

If [GnuPG](https://gnupg.org/) is installed on your server, you can
use it to encrypt backups. Uncomment the `$gpg` variable in
`sql-ledger.conf`, create a directory `/var/www/gnupg` and change its
owner to `www-data:www-data` on Debian or `apache:apache` on Fedora
based distributions.

# Unicode Support

In difference to the original SQL-Ledger, the version in the `full` branch
internally works with [Unicode characters](https://perldoc.perl.org/perluniintro.html).
This requires that your database, your templates and translations are
all encoded in UTF-8.

# Docker

With

```bash
cd docker
docker compose -p sql-ledger up -d
```

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

```bash
cd docker
docker compose -f docker-compose-alma.yml -p sql-ledger up -d
```

# WLprinter

WLprinter, included in the `full` branch, is a [Java](https://java.com) program
that is executed on the client PC and allows to print directly from SQL-Ledger
to your local printers. It is available for printing if you add a printer with
command `wlprinter` at `System--Workstations`. The client program is started
from `Batch--WLprinter`. You will have to add a Java security exception for
your SQL-Ledger server.

# Documentation

The documentation is very minimalist and doesn't contain much more than the
function names of the different modules. You can browse through it if you open
file `sql-ledger.pod` in any Perldoc viewer.

# Contributing

If you encounter an error or have an idea for new functionality, open an issue.

## Copyright and License

© 1999-2023 DWS Systems Inc.

© 2007-2025 Tekki (Rolf Stöckli)

[GPL3](LICENSE)
