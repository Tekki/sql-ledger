# Localized Postal Addresses

## Prerequisites

To enable the extended support for addresses, you have to go to
`System--Defaults` and activate the checkbox for "Check Addresses". Next you
have to make sure you entered a valid two-character ISO code as country of your
company. Otherwise you'll get an error message as soon as you try to save the
settings.

From now on, you're required to enter either nothing or a valid country code
into the country fields of all addresses. This means on the other hand, if you
don't want to use the functionality described here, leave "Check Addresses"
deactivated.

## Customer and Vendor Screens

As mentioned, the customers and vendors need valid country codes in field
"Country". An empty value is interpreted to be the in same country as your own
company.

Right of the address, you see how the values you entered are interpreted and
formatted according to the rules of the country of the recipient. Below that,
there is a button that you can click to copy this text into the clipboard.

The same applies to the shipping addresses. Each address on this screen is
formatted individually. This means for example, if a customer is located in
Germany and the delivery address is in France, you get two different formats,
the first with the street name written before the building number, the second
one with the inverse order. As on the main screen, there are buttons to copy the
addresses.

## Templates

In the print templates, four new variables are available.

The first are `countryname` and `shiptocountryname` with the full names that
correspond to the country codes. They are empty if the address points to the own
country.

The others are `localaddress` and `shiptolocaladdress`. They contain the
formatted addresses you see in the customer and vendor screens. You can use them
instead of the blocks with individual fields.

## Missing Localizations

At the moment, the localization is focused on Europe and North America. The
default format is street name followed by building number and postal code
followed by city, with no text transformation. This means if you are located
elsewhere, you probably get wrong looking addresses. In this case, please open
an [issue on Github](https://github.com/Tekki/sql-ledger/issues).
