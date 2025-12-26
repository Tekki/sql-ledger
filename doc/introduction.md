[SQL-Ledger Documentation](index.md) ▶ Introduction

# Introduction

## Quick Start

To establish a fully operational system, follow these steps:

- Install the server: [Installation](installation.md).
- Configure the system: [Global Configuration](configuration.md#global).
- Create at least one database.
- Log in to this database.
- Edit the preferences of the administrator. 
- Edit the chart of accounts via `System → Chart of Accounts`.
- Configure the database: [Database Configuration](configuration.md#database).
- Add at least one user without admin permissions via the `HR` menu: [User
  Configuration](configuration.md#user).

## Feature List

### System Management

- multiple companies
- create new database using preconfigured chart of account and printing
  templates
- lock and unlock individual databases or the whole system
- extended menu for all, some companies or some users

### Company

- departments
- cost centers
- editable chart of accounts
- unlimited number of employees
- user logins with individual access rights
- optional MFA (multi-factor authentication)
- database backups
- database snapshots

### User Interface

- individual settings for
  - language
  - number and date formats
  - color theme
  - e-mail signature
- list of recently used objects
- keyboard shortcuts
- storable reports

### Business Contacts

- customers and vendors
- individual language settings
- individual pricelists
- customer and vendor groups
- reports for
  - search
  - related transactions
  - history

### Goods and Services

- multiple types of parts
  - stock items
  - services
  - kits
  - assemblies
- translations for text fields
- images for parts
- reports for
  - search
  - related transactions
  - supply and demand
  - requirements

### Invoicing

- convert orders and quotations to invoices
- import invoices in different formats
- import vendor invoices from Swiss QR Bills
- reports for
  - search
  - outstanding
- export reports to XLSX spreadsheets

### Payment Management

- manually add single or multiple payments
- export outgoing payments in different formats, including Swiss Payment Standard
  pain.001
- import incoming payments in different formats, including ISO 20022 camt.054
- reminders

### Quotations and Orders

- requests for quotations
- purchase orders
- quotations
- sales orders
- reports
- export reports to XLSX spreadsheets

### Projects

- projects for services
- jobs for assemblies
- time recording for invoicing and post-calculation
- convert time cards to sales orders

### Accounting

- foreign currencies
- general ledger transactions
- reconciliation of bank accounts
- reports for
  - trial balance
  - income statement
  - balance sheet
  - value added tax
- export reports to XLSX spreadsheets

### Printing and E-Mailing

- multiple sets of templates for different languages or business purposes
  (domestic sales, export)
- create PDF files from all types of transactions
- preview in screen, print to physical printer or queue
- send as e-mail directly to customers and vendors
- mass printing and e-mailing of transactions
- combine queued documents into a single PDF
- download queued documents as ZIP archive

### Document Management

- attach document to virtually any entity
- deduplication to save space
- report to search and manage documents

### Data Import and Export

- import CSV or XLSX format
- import of
  - customers
  - vendors
  - goods and services
  - invoices
  - payments
  - orders
  - general ledger transactions
- export of
  - customers
  - vendors
  - payments
- edit exported customers and vendors for re-importing

### Automation

- timetable to repeat invoices or transactions automatically
- mass billing
- JSON API to search customers, orders and transactions, to add payments and
  upload documents
- HTML API to simulate any user interaction
