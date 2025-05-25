# Extensions for LaTeX templates

This version of SQL-Ledger provides some additional functions and variables that
can be used in LaTeX templates.

## <a id="md"></a>Text decoration and links

Input fields accepts simple accept simple markdown commands to format the output
as italic or bold.

```
This word is *italic*. And this one is **bold**.
```

In a PDF, it will look like: «This word is *italic*. And this one is **bold**.»

Links are written with a combination of square and round brackets.

```
The repo for this code on [Github](https://github.com/Tekki/sql-ledger).
```

Will be printed as: «The repo for this code on
[Github](https://github.com/Tekki/sql-ledger).»

## <a id="localaddr"></a>Variables for localized addresses

If localized addresses are activted, there are four new variables available:

| variable           | content                                            |
|--------------------|----------------------------------------------------|
| countryname        | full name of the country of the customer or vendor |
| shiptocountryname  | full name of the shipto country                    |
| localaddress       | formatted address of the customer or vendor        |
| shiptolocaladdress | formatted shipto address                           |

Formatted addresses contain all the name and address fields and are formatted
following the rules published by the Universal Postal Union.

## <a id="qrbill"></a>Variables for Swiss QR Bill

For documents sent to customers, several variables are prepared that can be used
for the LaTeX `qrcode` package so generate QR Codes for Swiss QR Bills.

| variable            | content                                     |
|---------------------|---------------------------------------------|
| qr_company_name     | the name of the own company                 |
| qr_company_address  | the own postal address                      |
| qr_company_city     | the own zipcode and city                    |
| qr_company_country  | the ISO code of the own country             |
| qr_customer_name    | the name of the customer                    |
| qr_customer_address | the postal address of the customer          |
| qr_customer_city    | the zipcode and city of the customer        |
| qr_customer_country | the ISO code of the country of the customer |

The the `qrcode` LaTeX package is not only terribly slow, its behavior is rather
tricky when it has to process UTF-8 characters. The above variables work
together with `xelatex`. For other cases, there are two more sets, one with
prefix `qr2e_` instead of `qr_` that contains characters that are encoded twice
and one with prefix `qrasc_` with plain ASCII texts.

## <a id="qrcode"></a>Directive for QR Codes

This directive inserts a QR Code as TikZ graphics into the `.tex` file. The
calculation of the code is made inside SQL-Ledger an not delegated to LaTeX.

This function requires that all the Perl modules are installed (check the
version screen as admin for this) and the template loads TikZ.

```latex
\usepackage{tikz}
```

A QR Code can now be generated with

```
<%var qrcode=height%>
```

where `var` is the name of the variable and `height` the height of the image in
millimeters.

A QR Code for the partnumber with height 15 mm for example is produced with

```
<%partnumber qrcode=15%>
```

The following parameters modify the appearance of the code:

| parameter  | default | function                                                   |
|------------|---------|------------------------------------------------------------|
| foreground | black   | color of the dots                                          |
| background | (none)  | color of the background                                    |
| margin     | 0       | margin between the code and the border of the image        |
| unit       | mm      | length unit for height and margin                          |
| level      | M       | error correction level, one of M, L, Q, and H              |
| version    | 0       | version of the symbol, with 0 it is adapted to the content |

If the code for the partnumber needs a margin of 10 mm and a green background,
it would be written as

```
<%partnumber qrcode=35% margin=10 background=green>
```
