[SQL-Ledger Documentation](index.md) ▶ Development

# Development

## Perldoc

The perldoc is quite minimal, containing mainly the names of functions
across the modules. You can view it by opening the file `sql-ledger.pod` in any
Perldoc viewer.

## Testing

The test scripts are located in directory `t`. If you call

```bash
prove -r t
```

on a correctly installed system, all of them should either pass or be skipped
and the overall result has to be a success.

They are organized according to the following structure:

| Directory        | Test Object                                      |
|------------------|--------------------------------------------------|
| t/01-sl          | modules in SL/                                   |
| t/02-bin_mozilla | scripts in bin/mozilla/                          |
| t/03-frontend    | scripts in base directory                        |
| t/04-config      | config files in config/sql-ledger, users/members |
| t/05-live-safe   | availability of the menu entries                 |
| t/06-live-unsafe | work with the system, possibly destructive       |

The safe live tests need a configuration file at `t/testdata/testconfig.yml`
with the following basic structure:

```yaml
---
server:
  url: …
  username: …
  password: …
```

To activate the live tests, set the environment variable `SL_LIVETEST` to a true
value.

```bash
SL_LIVETEST=1 prove -r t/05-live-safe
```

The so-called unsafe tests create, update, print, delete object and potentially
corrupt data; they must not be run in production environments. These tests are
restricted to core developers and are currently undocumented.

## Contributing

If you encounter an error or have a feature idea, first of all open an issue on
our [GitHub repository](https://github.com/Tekki/sql-ledger/issues) so we can
discuss it further. Pull requests without prior discussion will not get
reviewed, except for small corrections of obvious errors.

The entire contribution process is:

* opening of an issue
* description of the facts
* discussion of the options
* assessment of the risks
* decision on the path to be taken
* code change
* opening of a pull request
* check if the new code meets the expectations
* publication of a new release

Familiarity with Git and creating pull requests on GitHub is required. Sign the
commits. Remember that changing the code is step 6 on the above list, not the
first.

Some coding rules:

* Always include tests. Ideally, add tests first and then adjust the code until
  they all pass.
* Format the updated code with the `.perltidyrc` configuration found in this
  repository. Skip formatting any sections that generate HTML output.
* Use short, but meaningful variable names and never use the same name at the
  same place for different purposes. Variables are here for humans to understand
  the code.
* Explicitly return values from subroutines with keyword `return`.
* Write `qw|a b c|` with vertical bar and not with parentheses.
* Write `for` instead of `foreach`.
* Use suffix statements like `for`, `if`, `unless` only if the code fits on one
  line.
* Use postfix dereferencing.
* Use subroutine signatures.
* Separate subroutines with two line breaks.
* Read about new Perl features up to v5.40 and don't hesitate to use them.
* Feel free to change existing code that doesn't follow these rules.
