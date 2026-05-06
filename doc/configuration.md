[SQL-Ledger Documentation](index.md) ▶ Configuration

# Configuration

For more possibilities, take a look at [Customization](customization.md).

## Storage Location

The configuration is stored either in the filesystem or in the database.

| Configuration | File                  | Database Table |
|---------------|-----------------------|----------------|
| Global        | config/sql-ledger.yml |                |
| Company       |                       | defaults       |
| User          | users/members.yml     |                |

The YAML files can be edited directly on the server. They have binary
counterparts with the `.bin` extension, which are optimized for fast reading by
SQL-Ledger.

**Important:** After any change to a YAML file, the `util/update-config.pl`
script must be run to update the binary files.

## Global Configuration

To set the global configuration, create a file named `config/sql-ledger.yml`. A
detailed example is provided in `config/sql-ledger-sample.yml`. The
configuration is exposed to the program via the global variable `%slconfig`. If
the file itself or any of the following keys is missing, their values are set
to:

```perl
  %slconfig = (
    userspath     => 'users',
    templates     => 'templates',
    spool         => 'spool',
    images        => 'images',
    notes         => 'notes',
    memberfile    => 'users/members',
    sendmail      => '| /usr/sbin/sendmail -f <%from%> -t',
    accessfolders => ['templates', 'notes'],
  );
```

If `stylesheet` is not set, `horizon-flex.css` will be used for the login and
administrator screens..

## Database Configuration

The database configuration is performed via the `System → Defaults` menu, which
is available to administrators. Directly editing values in the database is
strongly discouraged.

## User Configuration

Using the `HR` menu, administrators can create employee accounts and grant them
access to the user interface. Users can then customize their settings in
`Preferences`.

The user configuration is stored in the file `users/members.yml` and a
corresponding binary version. Experienced administrators frequently edit the
YAML file to apply bulk changes.

## Passwords

The user passwords are managed by the users themselves or by the administrators
of the respective datasets through the `HR` menu. If administrators forget their
own password or if the password of the root login at `admin.pl` gets lost, the
script `util/admin-login.pl` is available to create a new one.

## Localized Postal Addresses

### Prerequisites

To enable localization and extended address validation, navigate to
`System → Defaults` and check the «Localized Addresses» option. Make sure the
company country is specified using a valid two-letter ISO code; otherwise,
attempting to save will produce an error.

Once activated, each address entry must either omit the country field or provide
a valid country code. If you prefer not to use this feature, simply leave
“Loaclized Addresses” unchecked.

### Customer and Vendor Screens

As noted, the 'Country' field for customers and vendors must contain a valid
country code. If left blank, the address defaults to your company’s country.

Next to each address is a preview that shows how the entered values are
interpreted and formatted according to the recipient's country rules. Beneath
the preview, a button lets you copy the formatted address to the clipboard.

The same logic applies to shipping addresses. Each address on the screen is
formatted individually. For instance, a German customer with a delivery address
in France will see two distinct formats: the German format places the street
name before the building number, while the French format reverses the order. As
on the main screen, copy buttons are available for every address.

### Templates

In the print templates, four new variables are available. The are described in
[Variables for Localized Addresses](latex_templates.md#variables-for-localized-addresses).

### Missing Localizations

Currently, localization is limited to Europe and North America. The default
address format follows the pattern: street name, building number, postal code,
and city, with no text transformation applied. As a result, users outside these
regions may see addresses that look incorrect. In such a case, please open an
[issue on GitHub](https://github.com/Tekki/sql-ledger/issues).
