[SQL-Ledger Documentation](index.md) ▶ Backup

# Backup

## Database Backup

### Backup Formats

SQL-Ledger produces two different backup formats:

- SQL format with `System → Backup → Send by E-Mail` and
  `System → Backup → Save to File`.
- Dump format with `System → Backup → Download Dump`.

SQL format is created by SQL-Ledger itself. It is fragile, slow to restore and
may result in empty tables if the database was modified by the user.

Dump format is created by the external program `pg_dump` that is part of
PostgreSQL. These backups are reliable and can be restored on PostgreSQL of the
same or a newer version, if the user names and permissions are the same on both
systems.

### Encrypted Backups

Your country's legislation may stipulate that you store only encrypted backups.

To comply with this, install [GnuPG](https://gnupg.org/) on your server, create
a directory `/var/www/gnupg` or any other accessible by the web server and
change its owner to `www-data:www-data` on Debian or `apache:apache` on Fedora
based distributions. Set the parameter `gpg` in `config/sql-ledger.yml`
accordingly and run `util/update-config.pl`.

Generate a key pair locally. Sign in to your database, navigate to
`System → Defaults`, and paste the public key into the field in the `Encryption`
section. From that point forward, this key will encrypt all backups.

### Restore

Always restore a backup on the command line and not in
`System → Maintenance → Restore`. It is recommended to restore to an empty
database, therefore delete an re-create it with `dropdb` and `createdb` before
you run the restore command.

```bash
gunzip -c $BACKUPFILE | pqsl -U $DB_USER -p $DB_NAME
```

Replace the variables `$BACKUPFILE`, `$DB_USER` and `$DB_NAME` with the correct
values. If the backup is encrypted, decrypt it on your host before copying it to
the server.

```bash
gpg -d $ENCRYPTED -o $BACKUPFILE
```

## File System Backup

The commands described above backup only the PostgreSQL database. Additional
mission-critical data is stored in the file system and must also be backed up.
The following directories need to be preserved:

| Directory          | Content                     |
|--------------------|-----------------------------|
| config             | global system configuration |
| users              | user configuration          |
| templates          | printing templates          |
| images             | uploaded images             |
| bin/mozilla/custom | custom scripts and menus    |

If you use the queue for more than transient storage, back up `spool` as well.
