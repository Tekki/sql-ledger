[SQL-Ledger Documentation](index.md) ▶ Installation

# Installation

This document explains how to install the SQL-Ledger program code. As detailed
in the [Quick Start](introduction.md#quick-start), this is only the first step
required to achieve a fully operational system.

## GitHub Repository

It is always recommended to install the program via Git, either through the
Ansible role or a manual installation. Both approaches are described below.
Downloading and extracting archive files introduces unnecessary complications
during [upgrades](upgrade.md#upgrade).

The GitHub repository is structured as follows:

| Branch |         | Content                     |
|--------|---------|-----------------------------|
| main   | default | Version 4                   |
| full   |         | extended Version 3 by Tekki |
| dws    |         | DWS Version 3               |

`main` is the default branch and contains version 4. The repository has version
tags, so you can download a specific version back to 2.6.0 from October 1, 2005.

## Requirements

SQL-Ledger Version 4 requires

- Perl 5.40 or higher
- PostgreSQL 17 or highter

Version 3 runs on older systems too.

## Ansible Role

The recommended installation method is to use the [Ansible
role](https://github.com/Tekki/ansible-sql-ledger). It will install and
configure SQL-Ledger on a preinstalled Debian 13 Trixie.

## Manual Installation

For a manual installation, the procedure is:

- generate the locales
- install Git, Perl, PostgreSQL database and Apache web server
- install the Perl modules
- clone the SQL-Ledger repository
- set the file access permissions
- configure the web server

The Perl modules required for a complete installation are:

| Module                 | Debian package                |
|------------------------|-------------------------------|
| Archive::Extract       | libarchive-extract-perl       |
| Archive::Zip           | libarchive-zip-perl           |
| DBD::Mock              | libdbd-mock-perl              |
| DBD::Pg                | libdbd-pg-perl                |
| Excel::Writer::XLSX    | libexcel-writer-xlsx-perl     |
| HTML::Form             | libhtml-form-perl             |
| IO::Socket::SSL        | libio-socket-ssl-perl         |
| Image::Magick          | libimage-magick-perl          |
| Imager::zxing          | -                             |
| Mojolicious            | libmojolicious-perl           |
| Print::Colored         | -                             |
| Spreadsheet::ParseXLSX | libspreadsheet-parsexlsx-perl |
| Template               | libtemplate-perl              |
| Text::QRCode           | libtext-qrcode-perl           |
| Tie::IxHash            | libtie-ixhash-perl            |
| YAML::PP               | libyaml-pp-perl               |

On a simple system, you should at least install `Archive::Zip`, `DBD::Pg`, and
`Excel::Writer::XLSX`. `HTML::Form` and `DBD::Mock` are only used in tests and
`Template` only in the script that generates templates. If you're not planning
to import QR Bills, you don't need `Image::Magick` and `Imager::zxing`.

Always clone the repository using `git`, don't download and extract the code
from an archive file.

For more details, take a closer look at the Ansible role and the files related
to the Docker images.

## Virtualization

There are several reasons why production SQL-Ledger is not suitable to be run in
a Docker container. Use either a dedicated server, a virtual machine, or a LXC.

For tests or development on the other hand, Docker is a convenient solution.
There are two Docker files and corresponding compose scripts available in
directory `docker`:
- `Dockerfile` and `docker-compose.yml` for Debian Trixie
- `DockerfileAlma` and `docker-compose-alma` for AlmaLinux 9

They create a simple test and development environment that doesn't include a
LaTeX environment to create PDF files.

To start the Debian container, use the shell commands
```bash
cd docker
docker compose -p sql-ledger up -d
```

or for AlmaLinux
```bash
cd docker
docker compose -f docker-compose-alma.yml -p sql-ledger up -d
```

This will set up a system with 4 containers, one for SQL-Ledger, one for
PostgreSQL, and another two for the database management tools
[Adminer](https://www.adminer.org) and [pgAdmin](https://pgadmin.org).

Access these services from your local browser
- SQL-Ledger: [localhost/sql-ledger](http://localhost/sql-ledger)
- Adminer: [localhost:8080](http://localhost:8080)
- pgAdmin: [localhost:8085](http://localhost:8085) 

To connect to the database, you have to use hostname `db` with username and
password `sql-ledger`.
