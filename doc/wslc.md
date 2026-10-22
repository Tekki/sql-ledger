[SQL-Ledger Documentation](index.md) ▶ [Installation](installation.md) ▶ WSL Container

# WSL Container

This is a temporary documentation to be used until the `compose` command is
introduced to
[WSL containers](https://learn.microsoft.com/en-us/windows/wsl/wsl-container).

## Prerequisites

Check the WSL version. You need at least Version 3.

```powershell
wsl --version
```

If you are on a lower version, update WSL.

```powershell
wsl --update
wsl --version
wslc --version
```

## Build the SQL-Ledger image

Open PowerShell in the base folder of the downloaded SQL-Ledger code.

```powershell
cd docker
wslc image build -t sql-ledger-test:0.25 .
```

## Create a network

```powershell
wslc network create sql-ledger-net
```

## Start the 4 containers

```powershell
# PostgreSQL
wslc container run -dit --rm `
  --name db `
  -e POSTGRES_PASSWORD=sql-ledger `
  -e POSTGRES_USER=sql-ledger `
  -p 54320:5432 `
  -v db17:/var/lib/postgresql/data `
  --network sql-ledger-net `
  postgres:17

# Adminer
wslc container run -d --rm `
  --name dbadmin `
  -e ADMINER_DESIGN=nette `
  -p 8080:8080 `
  --network sql-ledger-net `
  adminer

# pgAdmin
wslc container run -d --rm `
  --name pgadmin `
  -e PGADMIN_DEFAULT_EMAIL=user@domain.com `
  -e PGADMIN_DEFAULT_PASSWORD=SuperSecret `
  -p 8085:80 `
  -v pgadmin:/var/lib/pgadmin `
  --network sql-ledger-net `
  dpage/pgadmin4

# SQL-Ledger app
wslc container run -dit --rm `
  --name app `
  -p 80:80 `
  -v ../.:/usr/local/apache2/htdocs/sql-ledger `
  -v gnupg:/usr/local/apache2/gnupg `
  --network sql-ledger-net `
  sql-ledger-test:0.25
```

Check if they are all running.

```powershell
wslc container ls
```

Now the system is at the same state as described for Docker containers in Linux
at [Virtualization](installation.md#virtualization).

When you finished working, stop the containers with

```powershell
wslc container stop app pgadmin dbadmin db
```
