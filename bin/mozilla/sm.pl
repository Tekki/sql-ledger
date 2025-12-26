#======================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2025 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# Maintainance module
#
#======================================================================

use SL::SM;
use SL::IS;
use SL::IR;
require "$form->{path}/js.pl";

1;
# end of main


sub repost_invoices {

  # enter a date for which to repost invoices
  # reverse invoices and save in temporary tables
  # post vendor invoices then sales invoices

  $form->helpref("repost_invoices", $myconfig{countrycode});

  $form->{title} = $locale->text('Repost Invoices');

  $form->header;

  &calendar;

  print qq|
<body>

<form method="post" name="main" action="$form->{script}">

<table width=100%>
  <tr class=listtop>
    <th>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
          <th>|.$locale->text('Beginning date').qq|</th>
          <td><input name="transdate" size="11" class="date" title="$myconfig{dateformat}">|.&js_calendar("main", "transdate").qq|</td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<br>
<input class="submit" type="submit" name="action" value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">|;

  $form->{nextsub} = "do_repost_invoices";

  $form->hide_form(qw(nextsub path login));

  print qq|
</form>

</body>
</html>
|;

}


sub do_repost_invoices {

  $form->isblank('transdate', $locale->text('Date missing!'));

  $form->header;
  print $locale->text('Reposting Invoices ... ');
  if ($ENV{HTTP_USER_AGENT}) {
    print "<blink><font color=red>".$locale->text('please wait')."</font></blink>\n";
  } else {
    print $locale->text('please wait')."\n";
  }

  $SIG{INT} = 'IGNORE';

  open my $fh, ">$slconfig{userspath}/$myconfig{dbname}.LCK" or $form->error($!);
  close $fh;

  $err = SL::SM->repost_invoices(\%myconfig, $form, $slconfig{userspath});

  unlink "$slconfig{userspath}/$myconfig{dbname}.LCK";

  if ($err == -1) {
    $form->error($locale->text('AR account does not exist!'));
  }
  if ($err == -2) {
    $form->error($locale->text('AP account does not exist!'));
  }

  print "... ".$locale->text('done')."\n";

}


sub fld_config {

# list formnames

# pick one to edit


}


sub fld_edit {

}


sub fld_save {

}


sub continue { &{ $form->{nextsub} } };



=encoding utf8

=head1 NAME

bin/mozilla/sm.pl - Maintainance module

=head1 DESCRIPTION

L<bin::mozilla::sm> contains the maintainance module.

=head1 DEPENDENCIES

L<bin::mozilla::sm>

=over

=item * uses
L<SL::IR>,
L<SL::IS>,
L<SL::SM>

=item * requires
L<bin::mozilla::js>

=back

=head1 FUNCTIONS

L<bin::mozilla::sm> implements the following functions:

=head2 continue

Calls C<< &{ $form->{nextsub} } >>.

=head2 do_repost_invoices

=head2 fld_config

=head2 fld_edit

=head2 fld_save

=head2 repost_invoices

=cut
