[SQL-Ledger Documentation](index.md) ▶ Upgrade

# Upgrade

## Git Version Control

This documentation presumes you manage your SQL-Ledger installation with Git and
refrain from copying downloaded program files. If you have followed a different
method so far, switch to Git management before proceeding with any further
upgrades.

First, identify the specific version shown on the login page. Next, rename your
program’s directory and clone the repository.

```bash
mv sql-ledger sql-ledger-old
git clone https://github.com/Tekki/sql-ledger
cd sql-ledger
```

Copy all your own files to the new directory. These are:

- `sql-ledger.conf`
- `users/members` and all files with name `users/*.conf`
- all subdirectories of `templates`
- all subdirectories of `images` 
- all files inside `bin/mozilla/custom`

Grant the webserver write access to the `images`, `spool`, `templates`,
and `users` directories.

Set the code to the version you were using before. If this was 3.2.12.66, use
the command

```bash
git checkout tags/v3.2.12.066
```

Log in to the program and check if everything is working. If it does, log out,
jump to the most recent version 4 and log in again.

```bash
git checkout HEAD
```

If you want to stay on version 3 for the moment, change to branch `full`.

```bash
git switch full
```

## Upgrade Within Major Version

A single command updates the code installed via the Ansible role or manually
through Git.

```bash
git pull
```
Then log in to trigger any pending database upgrades.

If you have modified the original program code, proceed differently: first
identify any pending changes with `git status`. Commit them, then merge the new
updates from Github.

## Upgrade from Version 3 to Version 4

Before starting, ensure your system satisfies the prerequisites listed in
[Manual Installation](installation.md#manual-installation).

After installing the required packages, switch to the branch `main` containing
version 4 and run the upgrade script:

```bash
git switch main
script/v4-upgrade.pl
```

The script performs the following transformations:

- `sql-ledger.conf` to YAML `config/sql-ledger.yml`
- `config/sql-ledger.yml` to binary `config/sql-ledger.bin`
- `users/members` to YAML `users/members.yml`
- `users/members.yml` and all user config files to binary format

Existing YAML files will not be overwritten and the old config files are not
deleted.

Finally, log in to your database to complete the upgrade to version 4.

## Downgrade from Version 4 to Version 3

You can always revert from version 4.0 to any release of 3.2.12.65 or newer.
When your branches point to one of those versions, run `git switch full` to move
to the 3.x line and `git switch main` to return to the 4.x line. Remember that
each branch uses its own configuration files (conf vs. YAML format) and changes
in one set are not mirrored to the other.
