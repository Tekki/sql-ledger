# What is SQL-Ledger?

[SQL-Ledger](https://github.com/Tekki/sql-ledger) is a web-based open source ERP
and accounting platform that delivers all the essential tools for order
management, invoicing, and accounting. Its modular architecture includes

- quotations
- orders
- invoices
- accounting
- employee management
- payroll

It is built to support multiple clients, users, and languages. Documents are
generated as PDF files that can be downloaded, printed, or sent directly to
recipients.

Technically, SQL-Ledger is a Perl-based application that relies on PostgreSQL as
its database backend and serves its content through an Apache web server. It is
possible to extend the code with custom scripts.

# Global Reach and Swiss-Specific Additions

SQL-Ledger, originally developed in Canada, can be configured to almost any
country. Besides that, it offers some Swiss-specific enhancements, including:

- automatic retrieval of company names and addresses from the UID Register
- a script to fetch the most recent foreign-exchange rates from the Federal
 Finance Department
- variables that enable generation of QR Bills in accordance with Swiss
 standards
- import and export functionality for payment transfer that complies with the
 Swiss Payment Standard

# Quick Start and Documentation

If you are new here and want to get a glimpse of the software, clone the
repository, start a container and navigate to
[localhost/sql-ledger](http://localhost/sql-ledger). We assume that you have
`git` and `docker` already installed.

```bash
git clone https://github.com/Tekki/sql-ledger
cd sql-ledger/docker
docker compose -p sql-ledger up
```

For more information, take a look at the [documentation](doc/index.md).

# History

SQL-Ledger was developed from 1999 until 2023 by [DWS Systems
Inc.](https://sql-ledger.com) in Edmonton, Canada. The first additions and
bugfixes by Tekki date back to 2007. They are partially included in the original
code and were in bigger parts published separately. The most important
improvement is the full [Unicode](https://perldoc.perl.org/perluniintro.html)
support.

## Copyright and License

© 1999-2023 DWS Systems Inc.

© 2007-2025 Tekki (Rolf Stöckli)

[GPL3](LICENSE)
