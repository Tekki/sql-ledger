[SQL-Ledger Documentation](index.md) ▶ Upgrade

# Upgrade

## Change to Git Version Control

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

## Upgrade within Version 4

### Upgrade from Version 4.n.x to 4.n.y

A new number at the third position means that small changes were made to the
program. This probably includes new functionality or error corrections. To
perform such an upgrade, lock the application by creating a lock file and
download the new code.

```bash
echo 'System Upgrade.' > users/nologin.LCK
git pull
```

If there are no error messages, delete the lock file.

```bash
rm users/nologin.LCK
```

After a small upgrade, it is always possible to jump back to the previous
version.

### Upgrade from Version 4.x to 4.y

Bigger changes are indicated by a new number at the second position. In most of
the cases they include modifications to the database. Because of that, it is not
possible to switch back to the old version without restoring a backup.

Before starting a big upgrade, create a backup of all datasets. Then download
the new code and call the database upgrade script. It is not recommended to rely
on the automatic update made by the program itself, not at last because it is
not triggered by users that are already logged in.

```bash
echo 'System Upgrade.' > users/nologin.LCK
git pull
make dbupgrade  # or: util/upgrade-datasets.pl
```

As after a small upgrade, delete the lock file if there were no errors.

```bash
rm users/nologin.LCK
```

## Upgrade from Version 3 to Version 4

Before starting, ensure your system satisfies the prerequisites listed in
[Manual Installation](installation.md#manual-installation).

After installing the required packages, switch to the branch `main` containing
version 4 and run the upgrade script:

```bash
git switch main
util/v4-upgrade.pl
```

The script performs the following transformations:

- `sql-ledger.conf` to YAML `config/sql-ledger.yml`
- `config/sql-ledger.yml` to binary `config/sql-ledger.bin`
- `users/members` to YAML `users/members.yml`
- `users/members.yml` and all user config files to binary format

Existing YAML files will not be overwritten, but `members.yml` is updated with
new users from `members`. The old config files are not deleted.

Finally, log in to your database to complete the upgrade to version 4.

Custom scripts written for version 3 have to consider the following changes:

- The names of the SQL-Ledger Perl modules are built using their relative path,
  for example `SL::Form`.
- The global variables no longer exist as such, but have been moved to the new
  global hash `%slconfig`. The former `$userspath` for example is now called as
  `$slconfig{userspath}`.
- Buttons in the user interface built with HTML `<input>` tags are no longer
  supported and function calls are not translated back to English. Buttons are
  now written using `<button>` tags with the name of the targeted function as
  value.

## Downgrade from Version 4 to Version 3

You can always revert from a version 4.0 database to any release of 3.2.12.65 or
newer. When your branches point to one of those versions, run `git switch full`
to move to the 3.x line and `git switch main` to return to the 4.x line.
Remember that each branch uses its own configuration files (conf vs. YAML
format) and changes in one set are not mirrored to the other.

Versions 4.1 and higher contain database changes and are no longer compatible
with version 3.
