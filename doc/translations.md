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

If you are updating a translation for more then just personal use, you should be
familiar with the technical vocabulary around trade and manufacturing and with
the current accounting standards of your country.

Only modify translation strings in the original code if you intend to patch the
application and create a pull request on GitHub. Changing them otherwise risks
breaking future updates. For your private translation, create a new directory.

To add a new translation:
- Create a directory for the language.
- Add the `LANGUAGE` file.
- Copy `locales.pl` from an existing language directory and run it. This
  generates `all.yml` and `all_diff.yml`.
- Edit `all.yml` in a Markdown-compatible editor, adding your translations.
- Edit `all_diff.yml` if necessary.
- Run `./locales.pl` again to refresh the binary files.
- Optionally copy `Num2text` from another directory.

Check the user interface screens to grasp the context of the terms. And do not
aim for a 100 % complete translation.

`all_diff.yml` lists translations that vary across screens. Efforts are ongoing
to eliminate any ambiguous English terms, so this file should eventually stay
empty.

If you need variants on different screens, add them to `all_diff.yml` in the
following way:

```yaml
texts:
  English Term:
    script1: Translation for Script 1
    script2: Translation for Script 2
```

Take a look at `locale/chd_utf/all_diff.yml` as an example.

The number to text conversion is used in certain countries, mainly to print
checks. To improve an existing conversion script or to add a new one, always
start with a copy of `t/01-sl/num2text-en.t` that is adapted to the desired
language. Then modify `Num2text` until it produces the expected output and the
test passes.
