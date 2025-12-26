[SQL-Ledger Documentation](index.md) ▶ Translations

# Translations

## File Structure

The translations reside in subdirectories of the `locale` directory. Each
subdirectory is named using a country code followed by `_utf`. They consist of
the following files:

| File         | Content                   |
|--------------|---------------------------|
| all.yml      | main translation          |
| all_diff.yml | differing translations    |
| Num2text     | number to text conversion |
| locales.pl   | update script             |
| LANGUAGE     | name of the language      |
| COPYING      | copyright information     |

Plus around 40 binary files created by `locales.pl`.

## Updating and Creating Translations

Only modify translation strings in the program code if you intend to patch the
application. Changing them otherwise risks breaking future updates.

To add a new translation:
- Create a directory for the language.
- Add the `LANGUAGE` file.
- Copy `locales.pl` from an existing language directory and run it. This
  generates `all.yml` and `all_diff.yml`.
- Edit `all.yml` in a Markdown-compatible editor, adding your translations.
- Run `./locales.pl` again to refresh the binary files.

Check the user interface screens to grasp context and do not aim for a 100 %
complete translation.

`all_diff.yml` lists terms that vary across screens. Efforts are ongoing to
eliminate any ambiguous English terms, so this file should eventually stay
empty.
