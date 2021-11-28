# Keyboard Shortcuts

Advanced users try to avoid to switch from keyboard to mouse, they do most of
their work with the keyboard only. For them, many shortcuts are available.

## Access Keys

It is possible to use keyboard combinations to press a button or to jump
directly to an input field. The keys used to activate the command depend on the
browser and the operating system. On Windows and Linux, it can be either:

- `Alt-[key]`
- `Alt-Shift-[key]`

and on MacOS:

- `Control-Option-[key]`
- `Control-Option-Shift-[key]`
- `Control-Alt-[key]`

The `[key]` is revealed when the mouse is moved over the input field or the
button in question. Notice that in some browsers and on some operating systems
not all combinations are available.

Some of the commonly used shortcuts for buttons are:

| key | command  |
|-----|----------|
| U   | Update   |
| C   | Continue |
| S   | Save     |
| O   | Post     |
| V   | Preview  |
| P   | Print    |

The following keys move the cursor directly to an input field:

| key   | jump to                   |
|-------|---------------------------|
| 1 … 9 | row 1 … 9 of the document |
| 0     | last row of the document  |
| /     | customer or vendor        |
| *     | document date             |
| -     | description               |
| +     | notes                     |
| .     | payment date              |

The shortcuts for customer or vendor, date, description, and notes are
available in the frontend of the reports, too.

## Quick Date Entry

It is not necessary to enter full dates, they can be abbreviated and will be
expanded as soon as the cursor jumps out of the date field, for example by
pressing `Tab`.

Let's assume the current date is November 26, 2021 and the date format is set
to `dd.mm.yy`.

| input  | is expanded to |
|--------|----------------|
| +5     | 01.12.2021     |
| -10    | 16.11.2021     |
| 3      | 03.11.2021     |
| 5-2    | 05.02.2021     |
| 4.3.22 | 04.03.2022     |

### `+/- n`: plus or minus days

A `+` or `-` followed by a number `n` will set the date to today in `n` days or
to `n` days ago.

### `n`: day

A single number sets the date to day `n` in the current month and year.

### `n1 n2`: day and month

Two numbers define the day and month in the current year. They can be separated
by any non-numeric character. Depending on the date format set in the user
preferences, the first number is either the day or the month.

### `n1 n2 n3`: day, month, year

Three numbers set day, month and year, in the order according to the date
format. Days and months are always written with two digits, they get a leading
zero if necessary. Years lower than 100 are expanded to `20..` if they are
below 70, to `19..` if they are above.
