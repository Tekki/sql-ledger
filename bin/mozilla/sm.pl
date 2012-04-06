#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2009
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Maintainance module
#
#======================================================================

use SL::SM;
use SL::IS;
use SL::IR;

1;
# end of main


sub repost_invoices {

  # enter a date for which to repost invoices
  # reverse invoices and save in temporary tables
  # post vendor invoices then sales invoices

  $form->helpref("repost_invoices", $myconfig{countrycode});

  $form->{title} = $locale->text('Repost Invoices');
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listtop>
    <th>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <td>|.$locale->text('Beginning date').qq|
	  
          <td><input name="transdate" size="11" class="date" title="$myconfig{dateformat}"></td>
	</tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<br>
<input class="submit" type="submit" name="action" value="|.$locale->text('Continue').qq|">|;

  $form->{nextsub} = "do_repost_invoices";
  
  $form->hide_form(qw(nextsub path login));

  print qq|
</form>

</body>
</html>
|;

}


sub do_repost_invoices {

  $form->isblank('transdate', $locale->text('Date missing'));
  
  $form->header;
  print "Reposting Invoices ... ";
  if ($ENV{HTTP_USER_AGENT}) {
    print "<blink><font color=red>please wait</font></blink>\n";
  } else {
    print "please wait\n";
  }

  $SIG{INT} = 'IGNORE';
  
  open(FH, ">$userspath/$myconfig{dbname}.LCK") or $form->error($!);
  close(FH);

  $err = SM->repost_invoices(\%myconfig, \%$form, $userspath);
  
  unlink "$userspath/$myconfig{dbname}.LCK";

  if ($err == -1) {
    $form->error('AR account does not exist!');
  }
  if ($err == -2) {
    $form->error('AP account does not exist!');
  }

  print "... done\n";

}


sub delete_invoices {
  
  $form->{title} = $locale->text('Delete Open Invoices');
  
  $form->helpref("delete_open_invoices", $myconfig{countrycode});
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listtop>
    <th>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <td>|.$locale->text('From').qq|
	  
          <td><input name="transdatefrom" size="11" class="date" title="$myconfig{dateformat}"></td>
	  <td>|.$locale->text('To').qq|
	  
          <td><input name="transdateto" size="11" class="date" title="$myconfig{dateformat}"></td>
	</tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<br>
<input class="submit" type="submit" name=action value="|.$locale->text('Continue').qq|">|;
  
  $form->{nextsub} = "do_delete_invoices";
  
  $form->hide_form(qw(nextsub path login));

  print qq|
</form>

</body>
</html>
|;
}


sub do_delete_invoices {

  $form->header;
  
  print $locale->text('Deleting Invoices ... ');
  
  if ($ENV{HTTP_USER_AGENT}) {
    print "<blink><font color=red>".$locale->text('please wait')."</font></blink>\n";
  } else {
    print $locale->text('please wait')."\n";
  }
  
  $SIG{INT} = 'IGNORE';
  
  IS->delete_invoices(\%myconfig, \%$form, $spool);
  
  print "... ".$locale->text('done');
  
}


sub continue { &{ $form->{nextsub} } };


