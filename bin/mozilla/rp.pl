#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# module for preparing Income Statement and Balance Sheet
#
#======================================================================

require "$form->{path}/arap.pl";

use SL::PE;
use SL::RP;
use SL::CP;

1;
# end of main

# this is for our long dates
# $locale->text('January')
# $locale->text('February')
# $locale->text('March')
# $locale->text('April')
# $locale->text('May ')
# $locale->text('June')
# $locale->text('July')
# $locale->text('August')
# $locale->text('September')
# $locale->text('October')
# $locale->text('November')
# $locale->text('December')

# this is for our short month
# $locale->text('Jan')
# $locale->text('Feb')
# $locale->text('Mar')
# $locale->text('Apr')
# $locale->text('May')
# $locale->text('Jun')
# $locale->text('Jul')
# $locale->text('Aug')
# $locale->text('Sep')
# $locale->text('Oct')
# $locale->text('Nov')
# $locale->text('Dec')

# $locale->text('Balance Sheet')
# $locale->text('Income Statement')
# $locale->text('Trial Balance')
# $locale->text('AR Aging')
# $locale->text('AP Aging')
# $locale->text('Tax collected')
# $locale->text('Tax paid')
# $locale->text('Receipts')
# $locale->text('Payments')
# $locale->text('Project Transactions')
# $locale->text('Non-taxable Sales')
# $locale->text('Non-taxable Purchases')
# $locale->text('Reminder')


sub report {

  %report = ( balance_sheet        => { title => 'Balance Sheet' },
             income_statement        => { title => 'Income Statement' },
             trial_balance        => { title => 'Trial Balance' },
             ar_aging                => { title => 'AR Aging', vc => 'customer' },
             ap_aging                => { title => 'AP Aging', vc => 'vendor' },
             tax_collected        => { title => 'Tax collected', vc => 'customer' },
             tax_paid                => { title => 'Tax paid' },
             nontaxable_sales        => { title => 'Non-taxable Sales', vc => 'customer' },
             nontaxable_purchases => { title => 'Non-taxable Purchases' },
             receipts                => { title => 'Receipts', vc => 'customer' },
             payments                => { title => 'Payments' },
             projects                => { title => 'Project Transactions' },
             reminder                => { title => 'Reminder', vc => 'customer' },
           );

  $form->{title} = $locale->text($report{$form->{reportcode}}->{title});

  $form->{nextsub} = "generate_$form->{reportcode}";

  $form->helpref("rp_$form->{reportcode}", $myconfig{countrycode});

  %checked = ();
  $form->{accounttype} = "standard" unless $form->{accounttype} =~ /(standard|gifi)/;
  $checked{$form->{accounttype}} = "checked";

  $gifi = qq|
<tr>
  <th align=right>|.$locale->text('Accounts').qq|</th>
  <td><input name=accounttype class=radio type=radio value=standard $checked{standard}> |.$locale->text('Standard').qq|

      <input name=accounttype class=radio type=radio value=gifi $checked{gifi}> |.$locale->text('GIFI').qq|
  </td>
</tr>
|;


  RP->create_links(\%myconfig, \%$form, $report{$form->{reportcode}}->{vc});

  # departments
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "\n";

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|$_->{description}--$_->{id}\n| }
  }

  $department = qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Department').qq|</th>
          <td colspan=3><select name=department>|
          .$form->select_option($form->{selectdepartment}, $form->{department}, 1)
          .qq|
          </select></td>
        </tr>
| if $form->{selectdepartment};

  $fromto = qq|
        <tr>
          <th align=right>|.$locale->text('From').qq|</th>
          <td colspan=3 nowrap><input name=fromdate size=11 class=date title="$myconfig{dateformat}" value=$form->{fromdate}>|.&js_calendar("main", "fromdate").qq| <b>|.$locale->text('To').qq|</b> <input name=todate size=11 class=date title="$myconfig{dateformat}">|.&js_calendar("main", "todate").qq|</td>
        </tr>
|;

  if (@{ $form->{all_years} }) {
    # accounting years
    $selectaccountingyear = "\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|$_\n| }
    $selectaccountingmonth = "\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|$_--|.$locale->text($form->{all_month}{$_}).qq|\n| }

    %checked = ();
    $form->{interval} = "0" unless $form->{interval} =~ /(0|1|3|12)/;
    $checked{$form->{interval}} = "checked";

    $selectfrom = qq|
        <tr>
          <th align=right>|.$locale->text('Period').qq|</th>
          <td colspan=3>
          <select name=month>|.$form->select_option($selectaccountingmonth, $form->{month}, 1, 1).qq|</select>
          <select name=year>|.$form->select_option($selectaccountingyear, $form->{year}, 1).qq|</select>
          <input name=interval class=radio type=radio value=0 $checked{0}>&nbsp;|.$locale->text('Current').qq|
          <input name=interval class=radio type=radio value=1 $checked{1}>&nbsp;|.$locale->text('Month').qq|
          <input name=interval class=radio type=radio value=3 $checked{3}>&nbsp;|.$locale->text('Quarter').qq|
          <input name=interval class=radio type=radio value=12 $checked{12}>&nbsp;|.$locale->text('Year').qq|
          </td>
        </tr>
|;

  }

  %checked = ();
  $form->{summary} = "1" unless $form->{summary} =~ /(0|1)/;
  $checked{$form->{summary}} = "checked";

  if ($form->{reportcode} =~ /^tax_/) {
    $taxsummary = q|
          <input name=summary type=radio class=radio value=2> |.$locale->text('Only Sums');
  }

  $summary = qq|
        <tr>
          <th></th>
          <td><input name=summary type=radio class=radio value=1 $checked{1}> |.$locale->text('Summary').qq|
          <input name=summary type=radio class=radio value=0 $checked{0}> |.$locale->text('Detail').qq|$taxsummary
          </td>
        </tr>
|;

  # projects
  if (@{ $form->{all_project} }) {
    $form->{selectprojectnumber} = "\n";
    for (@{ $form->{all_project} }) { $form->{selectprojectnumber} .= qq|$_->{projectnumber}--$_->{id}\n| }

    $project = qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Project').qq|</th>
          <td colspan=3><select name=projectnumber>|
          .$form->select_option($form->{selectprojectnumber}, $form->{projectnumber}, 1)
          .qq|</select></td>
        </tr>|;

  }

  if (@{ $form->{all_language} }) {
    $form->{language_code} = $myconfig{countrycode};
    $form->{selectlanguage_code} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage_code} .= qq|$_->{code}--$_->{description}\n| }

    $lang = qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Language').qq|</th>
          <td colspan=3><select name=language_code>|.$form->select_option($form->{selectlanguage_code}, $form->{language_code}, undef, 1).qq|</select></td>
        </tr>|;

  }

  if (@{ $form->{all_report} }) {
    $form->{selectreportform} = "\n";
    for (@{ $form->{all_report} }) { $form->{selectreportform} .= qq|$_->{reportdescription}--$_->{reportid}\n| }

    $reportform = qq|
      <tr>
        <th align=right>|.$locale->text('Report').qq|</th>
        <td>
          <select name=report onChange="ChangeReport();">|.$form->select_option($form->{selectreportform}, undef, 1)
          .qq|</select>
        </td>
      </tr>
|;
  }


  $form->{decimalplaces} = $form->{precision};

  %checked = ();
  $form->{method} = "accrual" unless $form->{method} =~ /(accrual|cash)/;
  $checked{$form->{method}} = "checked";

  if ($form->{reportcode} eq 'balance_sheet' || $form->{reportcode} eq 'income_statement') {
    $form->{currencies} = $form->get_currencies(\%myconfig);

    if ($form->{currencies}) {
      @curr = split /:/, $form->{currencies};
      $form->{defaultcurrency} = $curr[0];
      for (@curr) { $form->{selectcurrency} .= "$_\n" }

      $curr = qq|
          <tr>
            <th align=right>|.$locale->text('Currency').qq|</th>
            <td><select name=currency>|
            .$form->select_option($form->{selectcurrency}, $form->{defaultcurrency})
            .qq|</select></td>
          </tr>|
            .$form->hide_form(defaultcurrency);
    }
  }


  $method = qq|
        <tr>
          <th align=right>|.$locale->text('Method').qq|</th>
          <td colspan=3><input name=method class=radio type=radio value=accrual $checked{accrual}>&nbsp;|.$locale->text('Accrual').qq|
          &nbsp;<input name=method class=radio type=radio value=cash $checked{cash}>&nbsp;|.$locale->text('Cash').qq|</td>
        </tr>
|;

  %checked = ();
  $form->{includeperiod} = "year" unless $form->{includeperiod} =~ /(month|quarter|year)/;
  $checked{$form->{includeperiod}} = "checked";

  for (qw(previousyear reversedisplay)) { $checked{$_} = "checked" if $form->{$_} }

  $includeperiod = qq|
        <tr>
          <th></th>
          <td colspan=3>
          <input name=includeperiod class=radio type=radio value=month $checked{month}>&nbsp;|.$locale->text('Months').qq|
          <input name=includeperiod class=radio type=radio value=quarter $checked{quarter}>&nbsp;|.$locale->text('Quarters').qq|
          <input name=includeperiod class=radio type=radio value=year $checked{year}>&nbsp;|.$locale->text('Year').qq|
          </td>
        </tr>

        <tr>
          <th align=right></th>
          <td colspan=3><input name=previousyear class=checkbox type=checkbox value=Y $checked{previousyear}>&nbsp;|.$locale->text('Previous Year').qq|
          <input name=reversedisplay class=checkbox type=checkbox value=Y $checked{reversedisplay}>&nbsp;|.$locale->text('Reverse Display').qq|
          </td>
        </tr>
|;

  if ($form->{reportcode} eq 'trial_balance') {
    @checked = qw(l_heading l_subtotal all_accounts);
    @input = qw(fromdate todate month year reportlogin);
    for (qw(department language_code)) {
      push @input, $_ if $form->{"select$_"};
    }
    %radio = ( interval => { 0 => 0, 1 => 1, 3 => 2, 12 => 3 },
                  accounttype => { standard => 0, gifi => 1 }
             );
  }

  if ($form->{reportcode} eq 'projects') {
    @checked = qw(l_heading l_subtotal);
    @input = qw(fromdate todate month year reportlogin);
    for (qw(department projectnumber)) {
      push @input, $_ if $form->{"select$_"};
    }
    %radio = ( interval => { 0 => 0, 1 => 1, 3 => 2, 12 => 3 },
                  accounttype => { standard => 0, gifi => 1 }
             );
  }

  if ($form->{reportcode} =~ /_aging/) {
    $form->{month} = "";
    $form->{year} = "";
    for (qw(c0 c30 c60 c90)) { $form->{$_} = 1 }

    @checked = qw(c0 c30 c60 c90 c15 c45 c75);
    @input = qw(todate month year reportlogin);
    for (qw(department)) {
      push @input, $_ if $form->{"select$_"};
    }
    push @input, $report{$form->{reportcode}}->{vc};
    push @input, "$report{$form->{reportcode}}->{vc}number" unless $myconfig{vclimit};

    %radio = ( summary => { 1 => 0, 0 => 1 },
                     overdue => { 0 => 0, 1 => 1 }
             );
  }


  if ($form->{reportcode} eq 'reminder') {
    $form->{month} = "";
    $form->{year} = "";

    @input = qw(reportlogin);
    for (qw(department)) {
      push @input, $_ if $form->{"select$_"};
    }
    push @input, $report{$form->{reportcode}}->{vc};
    push @input, "$report{$form->{reportcode}}->{vc}number" unless $myconfig{vclimit};
  }


  if ($form->{reportcode} =~ /^tax_/) {
    $gifi = "";

    $form->{db} = ($form->{reportcode} =~ /_collected/) ? "ar" : "ap";

    RP->get_taxaccounts(\%myconfig, \%$form);

    $form->{sort} ||= "transdate";

    for (qw(invnumber transdate description name address taxnumber netamount tax total)) { $form->{"l_$_"} = 1 }

    @checked = map { "l_$_" } qw(id invnumber transdate description name netamount tax subtotal total);
    if ($form->{db} eq 'ar') {
      push @checked, "l_customernumber";
    } else {
      push @checked, "l_vendornumber";
    }

    @input = qw(fromdate todate month year reportlogin);
    for (qw(department)) {
      push @input, $_ if $form->{"select$_"};
    }

    %radio = ( interval => { 0 => 0, 1 => 1, 3 => 2, 12 => 3 },
                      summary => { 1 => 0, 0 => 1 },
                       method => { accrual => 0, cash => 1 }
             );

    $i = 0;
    foreach $ref (@{ $form->{taxaccounts} }) {
      push @checked, "accno_".$form->quote($ref->{accno});
    }
    foreach $ref (@{ $form->{gifi_taxaccounts} }) {
      push @checked, "gifi_".$form->quote($ref->{accno});
    }

  }


  if ($form->{reportcode} =~ /^nontaxable_/) {

    $form->{sort} ||= "transdate";

    for (qw(invnumber transdate description name address netamount)) { $form->{"l_$_"} = 1 }

    @checked = map { "l_$_" } qw(id invnumber transdate description name address netamount subtotal);
    $form->{db} = ($form->{reportcode} =~ /_sales/) ? "ar" : "ap";

    if ($form->{db} eq 'ar') {
      push @checked, "l_customernumber";
    } else {
      push @checked, "l_vendornumber";
    }

    @input = qw(fromdate todate month year reportlogin);
    for (qw(department)) {
      push @input, $_ if $form->{"select$_"};
    }

    %radio = ( interval => { 0 => 0, 1 => 1, 3 => 2, 12 => 3 },
                      summary => { 1 => 0, 0 => 1 },
                       method => { accrual => 0, cash => 1 }
             );

  }


  if ($form->{reportcode} =~ /(receipts|payments)$/) {

    $form->{db} = ($form->{reportcode} =~ /payments/) ? "ap" : "ar";
    $form->{vc} = ($form->{db} eq 'ar') ? 'customer' : 'vendor';

    for (qw(transdate reference description name paid source memo)) { $form->{"l_$_"} = 1 }

    @checked = qw(fx_transaction);
    push @checked, map { "l_$_" } qw(transdate reference name description paid source memo subtotal);
    push @checked, "l_$form->{vc}number";

    @input = qw(account description source memo fromdate todate month year reportlogin);
    for (qw(department)) {
      push @input, $_ if $form->{"select$_"};
    }
    push @input, $form->{vc};
    push @input, "$form->{vc}number" unless $myconfig{vclimit};

    %radio = ( interval => { 0 => 0, 1 => 1, 3 => 2, 12 => 3 } );

  }


  if ($form->{reportcode} eq 'balance_sheet') {

    @checked = qw(l_heading l_subtotal l_accno previousyear reversedisplay usetemplate);

    @input = qw(todate tomonth toyear decimalplaces reportlogin);
    for (qw(department currency language_code)) {
      push @input, $_ if $form->{"select$_"};
    }

    %radio = ( method => { accrual => 0, cash => 1 },
          accounttype => { standard => 0, gifi => 1 },
        includeperiod => { month => 0, quarter => 1, year => 2 }
             );

  }


  if ($form->{reportcode} eq 'income_statement') {

    @checked = qw(l_heading l_subtotal l_accno previousyear reversedisplay usetemplate);

    @input = qw(fromdate todate frommonth fromyear decimalplaces reportlogin);
    for (qw(projectnumber department currency language_code)) {
      push @input, $_ if $form->{"select$_"};
    }

    %radio = ( interval => { 0 => 0, 1 => 1, 3 => 2, 12 => 3 },
                 method => { accrual => 0, cash => 1 },
            accounttype => { standard => 0, gifi => 1 },
          includeperiod => { month => 0, quarter => 1, year => 2 }
             );

  }

  $form->header;

  &change_report(\%$form, \@input, \@checked, \%radio);

  &calendar;

  print qq|
<body>

<form method="post" name="main" action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
      $reportform
      $department
|;

  %checked = ( l_heading => "checked", l_subtotal => "checked" );
  for (qw(l_heading l_subtotal)) {
    $checked{$_} = ($form->{$_}) ? "checked" : "";
  }

  if ($form->{reportcode} eq "projects") {

    print qq|
        $project
        $fromto
        $selectfrom
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        <tr>
          <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
          <td><input name=l_heading class=checkbox type=checkbox value=Y $checked{l_heading}>&nbsp;|.$locale->text('Heading').qq|
          <input name=l_subtotal class=checkbox type=checkbox value=Y $checked{l_subtotal}>&nbsp;|.$locale->text('Subtotal').qq|</td>
        </tr>
|;
  }

  if ($form->{reportcode} eq "income_statement") {

    print qq|
        $project
        $fromto
|;

    if ($selectfrom) {

      %checked = ();
      $form->{interval} = "0" unless $form->{interval} =~ /(0|1|3|12)/;
      $checked{$form->{interval}} = "checked";

      print qq|
        <tr>
          <th align=right>|.$locale->text('Period').qq|</th>
          <td colspan=3>
          <select name=frommonth>|.$form->select_option($selectaccountingmonth, $form->{frommonth}, 1, 1).qq|</select>
          <select name=fromyear>|.$form->select_option($selectaccountingyear, $form->{fromyear}).qq|</select>
          <input name=interval class=radio type=radio value=0 $checked{0}>&nbsp;|.$locale->text('Current').qq|
          <input name=interval class=radio type=radio value=1 $checked{1}>&nbsp;|.$locale->text('Month').qq|
          <input name=interval class=radio type=radio value=3 $checked{3}>&nbsp;|.$locale->text('Quarter').qq|
          <input name=interval class=radio type=radio value=12 $checked{12}>&nbsp;|.$locale->text('Year').qq|
          </td>
        </tr>
|;
    }

    %checked = ( l_heading => "checked", l_accno => "checked" );
    for (qw(l_heading l_subtotal l_accno)) {
      $checked{$_} = ($form->{$_}) ? "checked" : "";
    }

    print qq|
        $curr
        <tr>
          <th align=right>|.$locale->text('Decimalplaces').qq|</th>
          <td><input name=decimalplaces size=3 value=$form->{decimalplaces}></td>
        </tr>
        $lang
        <tr>
          <th align=right>|.$locale->text('Template').qq|</th>
          <td><input name=usetemplate class=checkbox type=checkbox value=Y $checked{usetemplate}>
          </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        $method

        <tr>
          <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
          <td colspan=3><input name=l_heading class=checkbox type=checkbox value=Y $checked{l_heading}>&nbsp;|.$locale->text('Heading').qq|
          <input name=l_subtotal class=checkbox type=checkbox value=Y $checked{l_subtotal}>&nbsp;|.$locale->text('Subtotal').qq|
          <input name=l_accno class=checkbox type=checkbox value=Y $checked{l_accno}>&nbsp;|.$locale->text('Account Number').qq|</td>
        </tr>

        $includeperiod
|;

  }


  if ($form->{reportcode} eq 'balance_sheet') {

    print qq|
        <tr>
          <th align=right>|.$locale->text('as at').qq|</th>
          <td nowrap><input name=todate size=11 class=date title="$myconfig{dateformat}" value=$form->{todate}>|.&js_calendar("main", "todate").qq|</td>
|;

   if ($selectfrom) {
     print qq|
          <td>
          <select name=tomonth>|.$form->select_option($selectaccountingmonth, $form->{tomonth}, 1, 1).qq|</select>
          <select name=toyear>|.$form->select_option($selectaccountingyear, $form->{toyear}).qq|</select>
          </td>
|;
   }

   %checked = ( l_heading => "checked", l_accno => "checked" );
   for (qw(l_heading l_subtotal l_accno reversedisplay usetemplate)) {
     $checked{$_} = ($form->{$_}) ? "checked" : "";
   }

   print qq|
        </tr>
        <tr>
          $curr
          <th align=right>|.$locale->text('Decimalplaces').qq|</th>
          <td><input name=decimalplaces size=3 value=$form->{precision}></td>
        </tr>
        $lang
        <tr>
          <th align=right>|.$locale->text('Template').qq|</th>
          <td><input name=usetemplate class=checkbox type=checkbox value=Y $checked{usetemplate}>
          </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        $method

        <tr>
          <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
          <td><input name=l_heading class=checkbox type=checkbox value=Y $checked{l_heading}>&nbsp;|.$locale->text('Heading').qq|
          <input name=l_subtotal class=checkbox type=checkbox value=Y $checked{l_subtotal}>&nbsp;|.$locale->text('Subtotal').qq|
          <input name=l_accno class=checkbox type=checkbox value=Y $checked{l_accno}>&nbsp;|.$locale->text('Account Number').qq|</td>
        </tr>

        $includeperiod
|;

  }

  if ($form->{reportcode} eq "trial_balance") {

    %checked = ();
    for (qw(l_heading l_subtotal all_accounts)) {
      $checked{$_} = ($form->{$_}) ? "checked" : "";
    }

    print qq|
        $fromto
        $selectfrom
        $lang
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        <tr>
          <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
          <td><input name=l_heading class=checkbox type=checkbox value=Y $checked{l_heading}>&nbsp;|.$locale->text('Heading').qq|
          <input name=l_subtotal class=checkbox type=checkbox value=Y $checked{l_subtotal}>&nbsp;|.$locale->text('Subtotal').qq|
          <input name=all_accounts class=checkbox type=checkbox value=Y $checked{all_accounts}>&nbsp;|.$locale->text('All Accounts').qq|</td>
        </tr>
|;
  }


  if ($form->{reportcode} =~ /^tax_/) {

    $form->{nextsub} = "generate_tax_report";

    print qq|
        $fromto
        $selectfrom
        $summary
        <tr>
          <th align=right>|.$locale->text('Report for').qq|</th>
          <td colspan=3>
|;

  $taxaccounts = "";
  foreach $ref (@{ $form->{taxaccounts} }) {

    $accno = $form->quote($ref->{accno});
    print qq|<input name="accno_$accno" class=checkbox type=checkbox checked>&nbsp;$ref->{description}

    <input name="$ref->{accno}_description" type=hidden value="|.$form->quote($ref->{description}).qq|">|;

    $taxaccounts .= "$accno ";
  }
  chop $taxaccounts;
  $form->{taxaccounts} = $taxaccounts;

  $form->{sort} ||= "transdate";

  $form->hide_form(qw(sort db));

  print qq|
          </td>
        </tr>
|;


  if (@{ $form->{gifi_taxaccounts} }) {
    print qq|
        <tr>
          <th align=right>|.$locale->text('GIFI').qq|</th>
          <td colspan=3>
|;

    $taxaccounts = "";
    foreach $ref (@{ $form->{gifi_taxaccounts} }) {

      $accno = $form->quote($ref->{accno});
      print qq|<input name="gifi_$accno" class=checkbox type=checkbox>&nbsp;$ref->{description}

      <input name="gifi_$ref->{accno}_description" type=hidden value="|.$form->quote($ref->{description}).qq|">|;

      $taxaccounts .= "$accno ";

    }
    chop $taxaccounts;
    $form->{gifi_taxaccounts} = $taxaccounts;

    print qq|
          </td>
        </tr>
|;
  }

  if ($form->{db} eq 'ar') {
    $vc = qq|
    <td><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
    <td>|.$locale->text('Customer').qq|</td>
    <td><input name="l_customernumber" class=checkbox type=checkbox value=Y></td>
    <td>|.$locale->text('Customer Number').qq|</td>|;
  }

  if ($form->{db} eq 'ap') {
    $vc = qq|
    <td><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
    <td>|.$locale->text('Vendor').qq|</td>
    <td><input name="l_vendornumber" class=checkbox type=checkbox value=Y></td>
    <td>|.$locale->text('Vendor Number').qq|</td>|;
  }


print qq|
        $method
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        <tr>
          <th align=right>|.$locale->text('Include in Report').qq|</th>
          <td>
            <table>
              <tr>
          <td><input name="l_id" class=checkbox type=checkbox value=Y></td>
          <td>|.$locale->text('ID').qq|</td>
          <td><input name="l_invnumber" class=checkbox type=checkbox value=Y checked></td>
          <td>|.$locale->text('Invoice').qq|</td>
          <td><input name="l_transdate" class=checkbox type=checkbox value=Y checked></td>
          <td>|.$locale->text('Date').qq|</td>
                  <td><input name="l_description" class=checkbox type=checkbox value=Y checked></td>
          <td>|.$locale->text('Description').qq|</td>
              </tr>

              <tr>
                $vc
          <td><input name="l_address" class=checkbox type=checkbox value=Y></td>
          <td>|.$locale->text('Address').qq|</td>
          <td><input name="l_country" class=checkbox type=checkbox value=Y></td>
          <td>|.$locale->text('Country').qq|</td>
              </tr>

              <tr>
          <td><input name="l_taxnumber" class=checkbox type=checkbox value=Y></td>
          <td>|.$locale->text('Taxnumber').qq|</td>
          <td><input name="l_netamount" class=checkbox type=checkbox value=Y checked></td>
          <td>|.$locale->text('Amount').qq|</td>

          <td><input name="l_tax" class=checkbox type=checkbox value=Y checked></td>
          <td>|.$locale->text('Tax').qq|</td>
          <td><input name="l_total" class=checkbox type=checkbox value=Y checked></td>
          <td>|.$locale->text('Total').qq|</td>

              </tr>
              <tr>
                <td><input name="l_subtotal" class=checkbox type=checkbox value=Y></td>
                      <td>|.$locale->text('Subtotal').qq|</td>
              </tr>
            </table>
          </td>
        </tr>
|;

    $form->hide_form(qw(taxaccounts gifi_taxaccounts));
  }


  if ($form->{reportcode} =~ /^nontaxable_/) {
    $gifi = "";

    $form->{db} = ($form->{reportcode} =~ /_sales/) ? "ar" : "ap";

    $form->{nextsub} = "generate_tax_report";

    if ($form->{db} eq 'ar') {
      $vc = qq|
      <td><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
      <td>|.$locale->text('Customer').qq|</td>
      <td><input name="l_customernumber" class=checkbox type=checkbox value=Y></td>
      <td>|.$locale->text('Customer Number').qq|</td>|;
    }

    if ($form->{db} eq 'ap') {
      $vc = qq|
      <td><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
      <td>|.$locale->text('Vendor').qq|</td>
      <td><input name="l_vendornumber" class=checkbox type=checkbox value=Y></td>
      <td>|.$locale->text('Vendor Number').qq|</td>|;
    }

    $form->{sort} ||= "transdate";

    $form->hide_form(qw(db sort));

    print qq|
        $fromto
        $selectfrom
        $summary
        $method
        <tr>
          <th align=right>|.$locale->text('Include in Report').qq|</th>
          <td colspan=3>
            <table>
              <tr>
          <td><input name="l_id" class=checkbox type=checkbox value=Y></td>
          <td>|.$locale->text('ID').qq|</td>
          <td><input name="l_invnumber" class=checkbox type=checkbox value=Y checked></td>
          <td>|.$locale->text('Invoice').qq|</td>
          <td><input name="l_transdate" class=checkbox type=checkbox value=Y checked></td>
          <td>|.$locale->text('Date').qq|</td>
                <td><input name="l_description" class=checkbox type=checkbox value=Y checked></td>
          <td>|.$locale->text('Description').qq|</td>
              </tr>
              <tr>

                $vc

          <td><input name="l_address" class=checkbox type=checkbox value=Y></td>
          <td>|.$locale->text('Address').qq|</td>

          <td><input name="l_country" class=checkbox type=checkbox value=Y></td>
          <td>|.$locale->text('Country').qq|</td>

              </tr>
              <tr>
          <td><input name="l_netamount" class=checkbox type=checkbox value=Y checked></td>
                      <td>|.$locale->text('Amount').qq|</td>
              </tr>
              <tr>
                <td><input name="l_subtotal" class=checkbox type=checkbox value=Y></td>
                      <td>|.$locale->text('Subtotal').qq|</td>
              </tr>
            </table>
          </td>
        </tr>
|;

  }


  if ($form->{reportcode} =~ /(ar|ap)_aging/) {
    $gifi = "";

    if ($form->{reportcode} eq 'ar_aging') {
      $vclabel = $locale->text('Customer');
      $vcnumber = $locale->text('Customer Number');
      $form->{vc} = 'customer';
      $form->{sort} = "customernumber" if $form->{namesbynumber};
    } else {
      $vclabel = $locale->text('Vendor');
      $vcnumber = $locale->text('Vendor Number');
      $form->{vc} = 'vendor';
    }
    $form->{sort} = ($form->{namesbynumber}) ? "$form->{vc}number" : "name";

    $form->{type} = "statement";
    $form->{format} ||= $myconfig{outputformat};
    $form->{media} ||= $myconfig{printer};

    # setup vc selection
    $form->all_vc(\%myconfig, $form->{vc}, ($form->{vc} eq 'customer') ? "AR" : "AP", undef, undef, undef, 1);

    if (@{ $form->{"all_$form->{vc}"} }) {
      $vc = qq|
           <tr>
             <th align=right nowrap>$vclabel</th>
             <td colspan=2><select name=$form->{vc}><option>\n|;

      for (@{ $form->{"all_$form->{vc}"} }) { $vc .= qq|<option value="|.$form->quote($_->{name}).qq|--$_->{id}">$_->{name}\n| }

      $vc .= qq|</select>
             </td>
           </tr>
|;
    } else {
      $vc = qq|
                <tr>
                  <th align=right nowrap>$vclabel</th>
                  <td colspan=2><input name=$form->{vc} size=35>
                  </td>
                </tr>
                <tr>
                  <th align=right nowrap>$vcnumber</th>
                  <td colspan=3><input name="$form->{vc}number" size=35>
                  </td>
                </tr>
|;
    }

    print qq|
        $vc
  <tr>
    <th align=right>|.$locale->text('To').qq|</th>
    <td nowrap><input name=todate size=11 class=date title="$myconfig{dateformat}">|.&js_calendar("main", "todate").qq|</td>
  </tr>
  <tr>
    <th align=right></th>
    <td>
    <select name=month>|.$form->select_option($selectaccountingmonth, undef, 1, 1).qq|</select>
    <select name=year>|.$form->select_option($selectaccountingyear, undef).qq|</select>
    </td>
  </tr>
  <input type=hidden name=action value="$form->{nextsub}">
  $summary
  <tr>
    <table>
      <tr>
        <th>|.$locale->text('Include in Report').qq|</th>

        <td>
          <table>
            <tr>
              <td nowrap><input name=overdue type=radio class=radio value=0 checked> |.$locale->text('Aged').qq|</td>
              <td nowrap><input name=overdue type=radio class=radio value=1> |.$locale->text('Overdue').qq|</td>
            </tr>
            <tr>
              <td nowrap width=70><input name=c0 type=checkbox class=checkbox value=1 checked> |.$locale->text('Current').qq|</td>
              <td nowrap width=70><input name=c30 type=checkbox class=checkbox value=1 checked> 30</td>
              <td nowrap width=70><input name=c60 type=checkbox class=checkbox value=1 checked> 60</td>
              <td nowrap width=70><input name=c90 type=checkbox class=checkbox value=1 checked> 90</td>
            </tr>
            <tr>
              <td nowrap width=70><input name=c15 type=checkbox class=checkbox value=1> 15</td>
              <td nowrap width=70><input name=c45 type=checkbox class=checkbox value=1> 45</td>
              <td nowrap width=70><input name=c75 type=checkbox class=checkbox value=1> 75</td>
            </tr>
          </table>
              </td>
            </tr>
          </table>
        </tr>

|;

    $form->hide_form(qw(type format media sort));

  }


  if ($form->{reportcode} eq 'reminder') {
    $gifi = "";

    $vclabel = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
    $form->{vc} = 'customer';
    $form->{sort} = "customernumber" if $form->{namesbynumber};
    $form->{sort} = ($form->{namesbynumber}) ? "$form->{vc}number" : "name";

    $form->{type} = "reminder";
    $form->{format} ||= $myconfig{outputformat};
    $form->{media} ||= $myconfig{printer};

    # setup vc selection
    $form->all_vc(\%myconfig, $form->{vc}, ($form->{vc} eq 'customer') ? "AR" : "AP", undef, undef, undef, 1);

    if (@{ $form->{"all_$form->{vc}"} }) {
      $vc = qq|
           <tr>
             <th align=right nowrap>$vclabel</th>
             <td colspan=2><select name=$form->{vc}><option>\n|;

      for (@{ $form->{"all_$form->{vc}"} }) { $vc .= qq|<option value="|.$form->quote($_->{name}).qq|--$_->{id}">$_->{name}\n| }

      $vc .= qq|</select>
             </td>
           </tr>
|;
    } else {
      $vc = qq|
                <tr>
                  <th align=right nowrap>$vclabel</th>
                  <td colspan=2><input name=$form->{vc} size=35>
                  </td>
                </tr>
                <tr>
                  <th align=right nowrap>$vcnumber</th>
                  <td colspan=3><input name="$form->{vc}number" size=35>
                  </td>
                </tr>
|;
    }

    print qq|
        $vc
        <input type=hidden name=action value="$form->{nextsub}">
|;

    $form->hide_form(qw(type format media sort));

  }

# above action can be removed if there is more than one input field


  if ($form->{reportcode} =~ /(receipts|payments)$/) {

    $form->{nextsub} = "list_payments";

    $gifi = "";

    RP->paymentaccounts(\%myconfig, \%$form);

    $selectpaymentaccount = "\n";
    foreach $ref (@{ $form->{PR} }) {
      $form->{paymentaccounts} .= "$ref->{accno} ";
      $selectpaymentaccount .= qq|$ref->{accno}--$ref->{description}\n|;
    }

    chop $form->{paymentaccounts};

    $form->hide_form(qw(paymentaccounts));

    if ($form->{vc} eq 'customer') {
      $vclabel = $locale->text('Customer');
      $vcnumber = $locale->text('Customer Number');
      $form->all_vc(\%myconfig, $form->{vc}, "AR");
    } else {
      $form->all_vc(\%myconfig, $form->{vc}, "AP");
      $vclabel = $locale->text('Vendor');
      $vcnumber = $locale->text('Vendor Number');
    }

    # setup vc selection
    if ($@{ $form->{"all_$form->{vc}"} }) {
      $vc = qq|
           <tr>
             <th align=right nowrap>$vclabel</th>
             <td colspan=2><select name=$form->{vc}><option>\n|;

      for (@{ $form->{"all_$form->{vc}"} }) { $vc .= qq|<option value="|.$form->quote($_->{name}).qq|--$_->{id}">$_->{name}\n| }

      $vc .= qq|</select>
             </td>
           </tr>
|;
    } else {
      $vc = qq|
                <tr>
                  <th align=right nowrap>$vclabel</th>
                  <td colspan=2><input name=$form->{vc} size=35>
                  </td>
                </tr>
                <tr>
                  <th align=right nowrap>$vcnumber</th>
                  <td colspan=3><input name="$form->{vc}number" size=35>
                  </td>
                </tr>
|;
    }

    print qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Account').qq|</th>
          <td colspan=3><select name=account>|
          .$form->select_option($selectpaymentaccount)
          .qq|</select>
          </td>
        </tr>
        $vc
        <tr>
          <th align=right nowrap>|.$locale->text('Description').qq|</th>
          <td colspan=3><input name=description size=35></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Source').qq|</th>
          <td colspan=3><input name=source></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Memo').qq|</th>
          <td colspan=3><input name=memo size=30></td>
        </tr>
        $fromto
        $selectfrom
        <tr>
          <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
          <td>
            <table width=100%>
              <tr>
                <td align=right><input type=checkbox class=checkbox name=fx_transaction value=1 checked> |.$locale->text('Exchange Rate Difference').qq|</td>
              </tr>
|;

    @a = ();

    push @a, qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked> |.$locale->text('Date');
    push @a, qq|<input name="l_reference" class=checkbox type=checkbox value=Y checked> |.$locale->text('Reference');
    push @a, qq|<input name="l_name" class=checkbox type=checkbox value=Y checked> |.$locale->text($vclabel);
    push @a, qq|<input name="l_$form->{vc}number" class=checkbox type=checkbox value=Y> |.$locale->text($vcnumber);
    push @a, qq|<input name="l_description" class=checkbox type=checkbox value=Y checked> |.$locale->text('Description');
    push @a, qq|<input name="l_paid" class=checkbox type=checkbox value=Y checked> |.$locale->text('Amount');
    push @a, qq|<input name="l_source" class=checkbox type=checkbox value=Y checked> |.$locale->text('Source');
    push @a, qq|<input name="l_memo" class=checkbox type=checkbox value=Y checked> |.$locale->text('Memo');

    while (@a) {
      print qq|<tr>\n|;
      for (1 .. 5) {
        print qq|<td nowrap>|. shift @a;
        print qq|</td>\n|;
      }
      print qq|</tr>\n|;
    }

    print qq|
              <tr>
                <td><input name=l_subtotal class=checkbox type=checkbox value=Y> |.$locale->text('Subtotal').qq|</td>
              </tr>
            </table>
          </td>
        </tr>
|;

    $form->{sort} = 'transdate';
    $form->hide_form(qw(vc db sort));

  }


  print qq|

      $gifi

      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">
|;

  $form->hide_form(qw(helpref reportcode reportlogin title nextsub path login));

  print qq|

</form>
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|

</body>
</html>
|;

}


sub continue { &{$form->{nextsub}} };


sub generate_income_statement {

  $form->{callback} = "$form->{script}?action=generate_income_statement";
  for (qw(path login accounttype currency decimalplaces fromdate frommonth fromyear interval method todate reportcode reportlogin l_heading l_subtotal l_accno includeperiod previousyear reversedisplay usetemplate)) { $form->{callback} .= "&$_=$form->{$_}" if $form->{$_} }
  for (qw(department language_code projectnumber report)) { $form->{callback} .= "&$_=".$form->escape($form->{$_},1) if $form->{$_} }

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};

  RP->income_statement(\%myconfig, \%$form, \%$locale);

  ($form->{department}) = split /--/, $form->{department};
  ($form->{projectnumber}) = split /--/, $form->{projectnumber};

  $form->format_string(qw(company address businessnumber companyemail companywebsite));
  $form->{address} =~ s/\n/<br>/g;

  $timeperiod = $locale->date(\%myconfig, $form->{fromdate}, $form->{longformat}) .qq| | .$locale->text('To') .qq| | .$locale->date(\%myconfig, $form->{todate}, $form->{longformat});

  %button = ('Save Report' => { ndx => 8, key => 'S', value => $locale->text('Save Report') }
            );

  if (!$form->{admin}) {
    delete $button{'Save Report'} unless $form->{savereport};
  }

  $this = "this";
  $previous = "previous";
  @periods = reverse sort { $a <=> $b } keys %{ $form->{period} };
  pop @periods;
  unshift @periods, "0";
  if ($form->{reversedisplay}) {
    @periods = reverse @periods;
    if ($form->{previousyear}) {
      $this = "previous";
      $previous = "this";
    }
  }

  # this section applies to the old template
  if ($form->{usetemplate}) {
    $form->{templates} = "$templates/$myconfig{templates}";
    $form->{IN} = "income_statement.html";

    &build_report(qw(I E));
  }


  if ($form->{usetemplate}) {
    $form->parse_template(\%myconfig, $userspath);
  } else {

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th>$form->{company}<br>
    $form->{address}
    </th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th>|;

  print $locale->text('Income Statement');
  print qq|<br>|.$locale->text('for Period');

  print qq|<br>$timeperiod
    </th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th>$form->{department}
    <br>$form->{projectnumber}
    </th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
|;


  print qq|
        <tr>
          <td></td>
|;

  $colspan = 1;
  for $period (@periods) {
    $colspan++;
    print qq|<th align=right>$form->{period}{$period}{$this}{fromdate}<br>$form->{period}{$period}{$this}{todate}</th>|;
    if ($form->{previousyear}) {
      $colspan++;
      print qq|<th align=right>$form->{period}{$period}{$previous}{fromdate}<br>$form->{period}{$period}{$previous}{todate}</th>|;
    }
  }

  print qq|
        </tr>
|;

  %accounts = ( I => $locale->text('Income'),
                E => $locale->text('Expenses')
              );

  %spacer = ( H => '',
              A => '&nbsp;&nbsp;&nbsp;'
            );

  for $category (qw(I E)) {
    $ml = ($category eq 'I') ? 1 : -1;
    &section_display;
  }

  print qq|
        <tr height="15"></tr>
        <tr>
          <th align=left>|.$locale->text('Income / (Loss)').qq|</th>|;

    for $period (@periods) {
      print qq|
          <th align=right>|.$form->format_amount(\%myconfig, $total{$this}{$period}, $form->{decimalplaces}).qq|</th>|;
      if ($form->{previousyear}) {
        print qq|
          <th align=right>|.$form->format_amount(\%myconfig, $total{$previous}{$period}, $form->{decimalplaces}).qq|</th>|;
      }
    }

  print qq|
        </tr>
      </table>
    </td>
  </tr>
</table>
|;
}

  $form->header;

print qq|
<p>
<form method="post" name="main" action="$form->{script}" />
|;

  # created in RP.pm
  if ($form->{fromyear} && $form->{frommonth}) {
    delete $form->{fromdate};
    delete $form->{todate};
  }

  $form->hide_form(qw(department projectnumber fromdate todate frommonth fromyear previousyear interval includeperiod currency decimalplaces language_code l_heading l_subtotal l_accno accounttype method reversedisplay usetemplate));

  $form->hide_form(qw(callback path login report reportid reportcode reportdescription reportlogin column_index flds sort direction));

  $form->print_button(\%button);

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
</form>

</body>
</html>
|;

}


sub section_display {

  $subtotal = 0;

  print qq|
        <tr class=listheading>
          <th align=left colspan=$colspan>$accounts{$category}</th>
        </tr>|;

  for $accno (sort keys %{ $form->{$category} }) {
    $spacer = $spacer{$form->{accounts}{$accno}{charttype}};

    if ($subtotal && (($form->{$category}{$accno}{$this}{0}{charttype} eq 'H') || ($form->{$category}{$accno}{$previous}{0}{charttype} eq 'H'))) {
      &section_subtotal;
    }

    if (($form->{$category}{$accno}{$this}{0}{charttype} eq 'H') || ($form->{$category}{$accno}{$previous}{0}{charttype} eq 'H')) {
      next unless $form->{l_heading};
    }

    $subtotal = 1;

    $i++; $i %= 2;
    print qq|
        <tr class=listrow$i>
          <th align=left nowrap>$spacer|;

        if (($form->{$category}{$accno}{$this}{0}{charttype} eq 'H') || ($form->{$category}{$accno}{$previous}{0}{charttype} eq 'H')) {
          if ($form->{l_heading}) {
            if ($form->{l_accno}) {
              print qq|$accno - $form->{accounts}{$accno}{description}</th>|;
            } else {
              print qq|$form->{accounts}{$accno}{description}</th>|;
            }
          }
        } else {
          if ($form->{l_accno}) {
            print qq|$accno - |;
          }
          print qq|$form->{accounts}{$accno}{description}</th>|;
        }

        for $period (@periods) {
          if ($form->{$category}{$accno}{$this}{$period}{charttype} eq 'H') {
            $subtotal{accno} = $form->{accounts}{$accno}{description};
            $subtotal{$this}{$period} = $form->{$category}{$accno}{$this}{$period}{amount} * $ml;
            $form->{$category}{$accno}{$this}{$period}{amount} = 0;
          }

          $total{$category}{$this}{$period} += $form->{$category}{$accno}{$this}{$period}{amount} * $ml;
          $total{$this}{$period} += $form->{$category}{$accno}{$this}{$period}{amount};

          print qq|<td align=right>|;
          print $form->format_amount(\%myconfig, $form->{$category}{$accno}{$this}{$period}{amount} * $ml, $form->{decimalplaces}, '-');
          print qq|</td>|;
          if ($form->{previousyear}) {
            if ($form->{$category}{$accno}{$previous}{$period}{charttype} eq 'H') {
              $subtotal{accno} = $form->{accounts}{$accno}{description};
              $subtotal{$previous}{$period} = $form->{$category}{$accno}{$previous}{$period}{amount} * $ml;
              $form->{$category}{$accno}{$previous}{$period}{amount} = 0;
            }

            $total{$category}{$previous}{$period} += $form->{$category}{$accno}{$previous}{$period}{amount} * $ml;
            $total{$previous}{$period} += $form->{$category}{$accno}{$previous}{$period}{amount};

            print qq|<td align=right>|;
            print $form->format_amount(\%myconfig, $form->{$category}{$accno}{$previous}{$period}{amount} * $ml, $form->{decimalplaces}, '-');
            print qq|</td>|;
          }
        }

    print qq|
        </tr>
|;
  }

  if ($category eq 'Q') {
    $i++; $i %= 2;
    print qq|
        <tr class=listrow$i>
          <th align=left nowrap>$spacer|.$locale->text('Current Earnings').qq|</th>|;

    for $period (@periods) {
      $currentearnings = $total{A}{$this}{$period} - $total{L}{$this}{$period} - $total{Q}{$this}{$period};

      print qq|
            <td align=right>|.$form->format_amount(\%myconfig, $currentearnings, $form->{decimalplaces}, '-').qq|</td>|;

      $subtotal{$this}{$period} += $currentearnings if ($form->{l_subtotal} && $form->{l_heading});
      $total{Q}{$this}{$period} += $currentearnings;

      if ($form->{previousyear}) {
        $previousearnings = $total{A}{$previous}{$period} - $total{L}{$previous}{$period} - $total{Q}{$previous}{$period};
        print qq|
            <td align=right>|.$form->format_amount(\%myconfig, $previousearnings, $form->{decimalplaces}, '-').qq|</td>|;

        $subtotal{$previous}{$period} += $currentearnings if ($form->{l_subtotal} && $form->{l_heading});
        $total{Q}{$previous}{$period} += $previousearnings;
      }
    }

    print qq|
        </tr>
|;

  }

  &section_subtotal;

  print qq|
        <tr class=listtotal>
          <th align=left>|.$locale->text('Total').qq| $accounts{$category}</th>
|;
  for $period (@periods) {
    print qq|
        <th align=right>|.$form->format_amount(\%myconfig, $total{$category}{$this}{$period}, $form->{decimalplaces}).qq|</th>|;
    if ($form->{previousyear}) {
      print qq|
        <th align=right>|.$form->format_amount(\%myconfig, $total{$category}{$previous}{$period}, $form->{decimalplaces}).qq|</th>|;
    }
  }

  print qq|
        </tr>
        <tr>
          <td colspan=$colspan>&nbsp;</td>
        </tr>
|;

}


sub section_subtotal {

  return unless $form->{l_subtotal};

  $i++; $i %= 2;
  print qq|
    <tr class=listrow$i>
      <th align=left nowrap>$subtotal{accno}</th>|;

  for $period (@periods) {
    print qq|<td align=right>|;
    print $form->format_amount(\%myconfig, $subtotal{$this}{$period}, $form->{decimalplaces});
    print qq|</td>|;
    if ($form->{previousyear}) {
      print qq|<td align=right>|;
      print $form->format_amount(\%myconfig, $subtotal{$previous}{$period}, $form->{decimalplaces});
      print qq|</td>|;
    }
    $subtotal{$this}{$period} = 0;
    $subtotal{$previous}{$period} = 0;
  }

  print qq|
        </tr>
        <tr>
          <td colspan=$colspan>&nbsp;</td>
        </tr>
|;

}


sub build_report {
  my @category = @_;

  $form->{padding} = "&nbsp;&nbsp;";
  $form->{bold} = "<strong>";
  $form->{endbold} = "</strong>";
  $form->{br} = "<br>";

  %account = ( 'I' => { 'type' => 'income',
                        'ml' => 1 },
               'E' => { 'type' => 'expense',
                        'ml' => -1 },
               'A' => { 'type' => 'asset',
                        'ml' => -1 },
               'L' => { 'type' => 'liability',
                        'ml' => 1 },
               'Q' => { 'type' => 'equity',
                        'ml' => 1 }
               );

  for $category (@category) {

    for $accno (sort keys %{ $form->{$category} }) {

      $str = ($form->{l_heading}) ? $form->{padding} : "";

      $account{charttype} = $form->{$category}{$accno}{$this}{0}{charttype} || $form->{$category}{$accno}{$previous}{0}{charttype};
      $account{description} = $form->{$category}{$accno}{$this}{0}{description} || $form->{$category}{$accno}{$previous}{0}{description};

      if ($account{charttype} eq "A") {
        $str .= ($form->{l_accno}) ? "$accno - $account{description}" : "$account{description}";
      }
      if ($account{charttype} eq "H") {
        if ($account{subtotal} && $form->{l_subtotal}) {
          $dash = "- ";
          push(@{$form->{"${type}_account"}}, "$str$form->{bold}$account{subdescription}$form->{endbold}");
          push(@{$form->{"${type}_${this}_period"}}, $form->format_amount(\%myconfig, $account{"sub$this"} * $account{ml}, $form->{decimalplaces}, $dash));

          if ($form->{previousyear}) {
            push(@{$form->{"${type}_${previous}_period"}}, $form->format_amount(\%myconfig, $account{"sub$previous"} * $account{ml}, $form->{decimalplaces}, $dash));
          }
        }

        $str = "$form->{br}$form->{bold}$account{description}$form->{endbold}";

        $account{"sub$this"} = $form->{$category}{$accno}{$this}{0}{amount};
        $account{"sub$previous"} = $form->{$category}{$accno}{$previous}{0}{amount};
        $account{subdescription} = $account{description};

        $account{subtotal} = 1;
        $account{ml} = $account{$category}{ml};

        $form->{$category}{$accno}{$this}{0}{amount} = 0;
        $form->{$category}{$accno}{$previous}{0}{amount} = 0;

        next unless $form->{l_heading};

        $dash = " ";
      }

      push(@{$form->{"$account{$category}{type}_account"}}, $str);

      if ($account{charttype} eq 'A') {
        $form->{"total_$account{$category}{type}_${this}_period"} += $form->{$category}{$accno}{$this}{0}{amount} * $account{$category}{ml};
        $dash = "- ";
      }

      push(@{$form->{"$account{$category}{type}_${this}_period"}}, $form->format_amount(\%myconfig, $form->{$category}{$accno}{$this}{0}{amount} * $account{$category}{ml}, $form->{decimalplaces}, $dash));

      if ($form->{previousyear}) {
        $form->{"total_$account{$category}{type}_${previous}_period"} += $form->{$category}{$accno}{$previous}{0}{amount} * $account{$category}{ml};
        push(@{$form->{"$account{$category}{type}_${previous}_period"}}, $form->format_amount(\%myconfig, $form->{$category}{$accno}{$previous}{0}{amount} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
      }

      $type = $account{$category}{type};
      $ml = $account{$category}{ml};

    }
  }

  $str = ($form->{l_heading}) ? $form->{padding} : "";

  # period dates
  $form->{this_period} = qq|$form->{period}{0}{$this}{fromdate}<br>\n$form->{period}{0}{$this}{todate}|;
  $form->{previous_period} = qq|$form->{period}{0}{$previous}{fromdate}<br>\n$form->{period}{0}{$previous}{todate}|;

  if (grep /I/, @category) {
    # total for income/loss
    $form->{total_this_period} = $form->format_amount(\%myconfig, $form->{total_income_this_period} - $form->{total_expense_this_period}, $form->{decimalplaces}, $dash);
    $form->{total_previous_period} = $form->format_amount(\%myconfig, $form->{total_income_previous_period} - $form->{total_expense_previous_period}, $form->{decimalplaces}, $dash);

    $form->{total_income_this_period} = $form->format_amount(\%myconfig, $form->{total_income_this_period}, $form->{decimalplaces}, $dash);
    $form->{total_expense_this_period} = $form->format_amount(\%myconfig, $form->{total_expense_this_period}, $form->{decimalplaces}, $dash);

    $form->{total_income_previous_period} = $form->format_amount(\%myconfig, $form->{total_income_previous_period}, $form->{decimalplaces}, $dash);
    $form->{total_expense_previous_period} = $form->format_amount(\%myconfig, $form->{total_expense_previous_period}, $form->{decimalplaces}, $dash);

  } else {

    $currentearnings = $form->round_amount($form->{"total_asset_${this}_period"} - $form->{"total_liability_${this}_period"} - $form->{"total_equity_${this}_period"}, $form->{decimalplaces});

    $previousearnings = $form->round_amount($form->{"total_asset_${previous}_period"} - $form->{"total_liability_${previous}_period"} - $form->{"total_equity_${previous}_period"}, $form->{decimalplaces});

    $form->{total_this_period} = $form->format_amount(\%myconfig, $form->{total_liability_this_period} + $form->{total_equity_this_period} + $currentearnings, $form->{decimalplaces}, $dash);
    $form->{total_previous_period} = $form->format_amount(\%myconfig, $form->{total_liability_previous_period} + $form->{total_equity_previous_period} + $previousearnings, $form->{decimalplaces}, $dash);

    # totals for assets, liabilities
    $form->{total_asset_this_period} = $form->format_amount(\%myconfig, $form->{total_asset_this_period}, $form->{decimalplaces}, $dash);
    $form->{total_asset_previous_period} = $form->format_amount(\%myconfig, $form->{total_asset_previous_period}, $form->{decimalplaces}, $dash);

    $form->{total_liability_this_period} = $form->format_amount(\%myconfig, $form->{total_liability_this_period}, $form->{decimalplaces}, $dash);
    $form->{total_liability_previous_period} = $form->format_amount(\%myconfig, $form->{total_liability_previous_period}, $form->{decimalplaces}, $dash);

    $form->{total_equity_this_period} = $form->format_amount(\%myconfig, $form->{total_equity_this_period} + $currentearnings, $form->{decimalplaces}, $dash);
    $form->{total_equity_previous_period} = $form->format_amount(\%myconfig, $form->{total_equity_previous_period} + $previousearnings, $form->{decimalplaces}, $dash);
  }

  # last subtotal
  if ($account{subtotal} && $form->{l_subtotal}) {
    push(@{$form->{"${type}_account"}}, "$str$form->{bold}$account{subdescription}$form->{endbold}");
    push(@{$form->{"${type}_${this}_period"}}, $form->format_amount(\%myconfig, $account{"sub$this"} * $ml, $form->{decimalplaces}, $dash));
    push(@{$form->{"${type}_${previous}_period"}}, $form->format_amount(\%myconfig, $account{"sub$previous"} * $ml, $form->{decimalplaces}, $dash));
  }

  if (grep /Q/, @category) {
    if ($currentearnings || $previousearnings) {
      # define Current Earnings account
      push(@{$form->{equity_account}}, $locale->text('Current Earnings'));

      push(@{$form->{"equity_${this}_period"}}, $form->format_amount(\%myconfig, $currentearnings, $form->{decimalplaces}, $dash));

      push(@{$form->{"equity_${previous}_period"}}, $form->format_amount(\%myconfig, $previousearnings, $form->{decimalplaces}, $dash));
    }
  }

  $form->{period} = $timeperiod;

}


sub generate_balance_sheet {

  $form->{callback} = "$form->{script}?action=generate_balance_sheet";
  for (qw(path login todate tomonth toyear currency decimalplaces accounttype method reportcode reportlogin l_heading l_subtotal l_accno includeperiod previousyear reversedisplay usetemplate)) { $form->{callback} .= "&$_=$form->{$_}" }
  for (qw(department language_code report)) { $form->{callback} .= "&$_=".$form->escape($form->{$_},1) }

  if ($form->{todate}) {
    if ($form->{toyear} && $form->{tomonth}) {
      if ($form->{todate} !~ /\W/) {
        $form->{todate} = substr("0$form->{todate}", -2);
        $form->{todate} = "$form->{toyear}$form->{tomonth}$form->{todate}";
      }
    }
  } else {
    if ($form->{toyear} && $form->{tomonth}) {
      (undef, $form->{todate}) = $form->from_to($form->{toyear}, $form->{tomonth});
    }
  }

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};

  RP->balance_sheet(\%myconfig, \%$form, \%$locale);

  ($form->{department}) = split /--/, $form->{department};

  # setup company variables for the form
  $form->format_string(qw(company address businessnumber companyemail companywebsite));
  $form->{address} =~ s/\n/<br>/g;

  %button = ('Save Report' => { ndx => 8, key => 'S', value => $locale->text('Save Report') }
            );

  if (!$form->{admin}) {
    delete $button{'Save Report'} unless $form->{savereport};
  }

  $this = "this";
  $previous = "previous";
  @periods = sort { $a <=> $b } keys %{ $form->{period} };
  if ($form->{reversedisplay}) {
    @periods = reverse @periods;
    if ($form->{previousyear}) {
      $this = "previous";
      $previous = "this";
    }
  }

  %accounts = ( A => $locale->text('Assets'),
                L => $locale->text('Liabilities'),
                Q => $locale->text('Equity')
              );

  %spacer = ( H => '',
              A => '&nbsp;&nbsp;&nbsp;'
            );

  if ($form->{usetemplate}) {

    $form->{templates} = "$templates/$myconfig{templates}";
    $form->{IN} = "balance_sheet.html";

    &build_report(qw(A L Q));
  }


  if ($form->{usetemplate}) {
    $form->parse_template(\%myconfig, $userspath);
  } else {

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th>$form->{company}<br>
    $form->{address}
    </th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th>|;

  print $locale->text('Balance Sheet');
  print qq|<br>|.$locale->text('as at');

  print qq|<br>|;
  print $locale->date(\%myconfig, $form->{todate}, $form->{longformat});
  print qq|
    </th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th>$form->{department}
    </th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr>
          <td></td>
|;

  $colspan = 1;
  for $period (@periods) {
    $colspan++;
    print qq|<th align=right>$form->{period}{$period}{$this}{todate}</th>|;
    if ($form->{previousyear}) {
      $colspan++;
      print qq|<th align=right>$form->{period}{$period}{$previous}{todate}</th>|;
    }
  }
  print qq|
        </tr>
|;

  for $category (qw(A L Q)) {
    $ml = ($category eq 'A') ? -1 : 1;
    &section_display;
  }

  print qq|
      </table>
    </td>
  </tr>
</table>
|;

  if ($form->{currency} ne $form->{defaultcurrency}) {
    print $locale->text('All amounts in')." $form->{currency} ".$locale->text('converted to')." $form->{currency} @ $form->{exchangerate}";
  }

}

  $form->header;

  print qq|
  <p>

<form method="post" name="main" action="$form->{script}" />
|;

  if ($form->{toyear} && $form->{tomonth}) {
    delete $form->{todate};
  }

  $form->hide_form(qw(department todate tomonth toyear includeperiod currency decimalplaces language_code l_heading l_subtotal l_accno previousyear reversedisplay accounttype method usetemplate));

  $form->hide_form(qw(callback path login report reportcode reportlogin column_index flds sort direction));

  $form->print_button(\%button);

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
</form>

</body>
</html>
|;

}


sub generate_projects {

  $form->{title} = $locale->text('Project Transactions');

  $form->{callback} = "$form->{script}?action=generate_projects";
  for (qw(login path nextsub fromdate todate month year interval l_heading l_subtotal accounttype reportcode reportlogin)) { $form->{callback} .= "&$_=$form->{$_}" }
  for (qw(department projectnumber title report)) { $form->{callback} .= "&$_=".$form->escape($form->{$_},1) }


  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};

  RP->trial_balance(\%myconfig, \%$form);

  &list_accounts;

}


sub generate_trial_balance {

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};

  # get for each account initial balance, debits and credits
  RP->trial_balance(\%myconfig, \%$form);

  $form->{title} = $locale->text('Trial Balance') . " / $form->{company}";
  $form->helpref("trial_balance", $myconfig{countrycode});
  $form->{l_accno} = 1;

  $form->{callback} = "$form->{script}?action=generate_trial_balance";
  for (qw(login path nextsub fromdate todate month year interval l_heading l_subtotal all_accounts accounttype reportcode reportlogin)) { $form->{callback} .= "&$_=$form->{$_}" }
  for (qw(department title report)) { $form->{callback} .= "&$_=".$form->escape($form->{$_},1) }

  &list_accounts;

}


sub list_accounts {

  $title = $form->escape($form->{title});

  if ($form->{department}) {
    ($department) = split /--/, $form->{department};
    $options = $locale->text('Department')." : $department<br>";
    $department = $form->escape($form->{department});
  }
  if ($form->{projectnumber}) {
    ($projectnumber) = split /--/, $form->{projectnumber};
    $options .= $locale->text('Project Number')." : $projectnumber<br>";
    $projectnumber = $form->escape($form->{projectnumber});
  }

  # if there are any dates
  if ($form->{fromdate} || $form->{todate}) {

    if ($form->{fromdate}) {
      $fromdate = $locale->date(\%myconfig, $form->{fromdate}, 1);
    }
    if ($form->{todate}) {
      $todate = $locale->date(\%myconfig, $form->{todate}, 1);
    }

    $form->{period} = "$fromdate - $todate";
  } else {
    $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);

  }
  $options .= $form->{period};

  @column_index = qw(accno description begbalance debit credit endbalance);

  $column_data{accno} = qq|<th class=listheading width=10%>|.$locale->text('Account').qq|</th>|;
  $column_data{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_data{debit} = qq|<th class=listheading width=10%>|.$locale->text('Debit').qq|</th>|;
  $column_data{credit} = qq|<th class=listheading width=10%>|.$locale->text('Credit').qq|</th>|;
  $column_data{begbalance} = qq|<th class=listheading width=10%>|.$locale->text('Beginning Balance').qq|</th>|;
  $column_data{endbalance} = qq|<th class=listheading width=10%>|.$locale->text('Ending Balance').qq|</th>|;


  if ($form->{accounttype} eq 'gifi') {
    $column_data{accno} = qq|<th class=listheading>|.$locale->text('GIFI').qq|</th>|;
  }


  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$options</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr>|;

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
|;


  $callback = $form->escape($form->{callback});

  # sort the whole thing by account numbers and display
  foreach $ref (sort { $a->{accno} cmp $b->{accno} } @{ $form->{TB} }) {

    $description = $form->escape($ref->{description});

    $href = qq|ca.pl?action=list_transactions|;
    for (qw(path accounttype login fromdate todate l_heading l_subtotal l_accno project_id nextsub)) { $href .= "&$_=$form->{$_}" }
    $href .= "&sort=transdate&prevreport=$callback&department=$department&projectnumber=$projectnumber&title=$title";

    if ($form->{accounttype} eq 'gifi') {
      $href .= "&gifi_accno=$ref->{accno}&gifi_description=$description";
      $na = $locale->text('N/A');
      if (!$ref->{accno}) {
        for (qw(accno description)) { $ref->{$_} = $na }
      }
    } else {
      $href .= "&accno=$ref->{accno}&description=$description";
    }

    $ml = ($ref->{category} =~ /(A|E)/) ? -1 : 1;
    $ml *= -1 if $ref->{contra};

    $debit = $form->format_amount(\%myconfig, $ref->{debit}, $form->{precision}, "&nbsp;");
    $credit = $form->format_amount(\%myconfig, $ref->{credit}, $form->{precision}, "&nbsp;");
    $begbalance = $form->format_amount(\%myconfig, $ref->{balance} * $ml, $form->{precision}, "&nbsp;");
    $endbalance = $form->format_amount(\%myconfig, ($ref->{balance} + $ref->{amount}) * $ml, $form->{precision}, "&nbsp;");


    if ($ref->{charttype} eq "H" && $subtotal && $form->{l_subtotal}) {

      if ($subtotal) {

        for (qw(accno begbalance endbalance)) { $column_data{$_} = "<th>&nbsp;</th>" }

        $subtotalbegbalance = $form->format_amount(\%myconfig, $subtotalbegbalance, $form->{precision}, "&nbsp;");
        $subtotalendbalance = $form->format_amount(\%myconfig, $subtotalendbalance, $form->{precision}, "&nbsp;");
        $subtotaldebit = $form->format_amount(\%myconfig, $subtotaldebit, $form->{precision}, "&nbsp;");
        $subtotalcredit = $form->format_amount(\%myconfig, $subtotalcredit, $form->{precision}, "&nbsp;");

        $column_data{description} = "<th class=listsubtotal>$subtotaldescription</th>";
        $column_data{begbalance} = "<th align=right class=listsubtotal>$subtotalbegbalance</th>";
        $column_data{endbalance} = "<th align=right class=listsubtotal>$subtotalendbalance</th>";
        $column_data{debit} = "<th align=right class=listsubtotal>$subtotaldebit</th>";
        $column_data{credit} = "<th align=right class=listsubtotal>$subtotalcredit</th>";

        print qq|
          <tr class=listsubtotal>
|;
        for (@column_index) { print "$column_data{$_}\n" }

        print qq|
          </tr>
|;
      }
    }

    if ($ref->{charttype} eq "H") {
      $subtotal = 1;
      $subtotaldescription = $ref->{description};
      $subtotaldebit = $ref->{debit};
      $subtotalcredit = $ref->{credit};
      $subtotalbegbalance = 0;
      $subtotalendbalance = 0;

      if ($form->{l_heading}) {
        if (! $form->{all_accounts}) {
          if (($subtotaldebit + $subtotalcredit) == 0) {
            $subtotal = 0;
            next;
          }
        }
      } else {
        $subtotal = 0;
        if ($form->{all_accounts} || ($form->{l_subtotal} && (($subtotaldebit + $subtotalcredit) != 0))) {
          $subtotal = 1;
        }
        next;
      }

      for (qw(accno debit credit begbalance endbalance)) { $column_data{$_} = "<th>&nbsp;</th>" }
      $column_data{description} = "<th class=listheading>$ref->{description}</th>";
    }

    if ($ref->{charttype} eq "A") {
      $column_data{accno} = "<td><a href=$href>$ref->{accno}</a></td>";
      $column_data{description} = "<td>$ref->{description}</td>";
      $column_data{debit} = "<td align=right>$debit</td>";
      $column_data{credit} = "<td align=right>$credit</td>";
      $column_data{begbalance} = "<td align=right>$begbalance</td>";
      $column_data{endbalance} = "<td align=right>$endbalance</td>";

      $totaldebit += $ref->{debit};
      $totalcredit += $ref->{credit};

      $cml = ($ref->{contra}) ? -1 : 1;

      $subtotalbegbalance += $ref->{balance} * $ml * $cml;
      $subtotalendbalance += ($ref->{balance} + $ref->{amount}) * $ml * $cml;

    }


    if ($ref->{charttype} eq "H") {
      print qq|
      <tr class=listheading>
|;
    }
    if ($ref->{charttype} eq "A") {
      $i++; $i %= 2;
      print qq|
      <tr class=listrow$i>
|;
    }

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
      </tr>
|;
  }


  # print last subtotal
  if ($subtotal && $form->{l_subtotal}) {
    for (qw(accno begbalance endbalance)) { $column_data{$_} = "<th>&nbsp;</th>" }
    $subtotalbegbalance = $form->format_amount(\%myconfig, $subtotalbegbalance, $form->{precision}, "&nbsp;");
    $subtotalendbalance = $form->format_amount(\%myconfig, $subtotalendbalance, $form->{precision}, "&nbsp;");
    $subtotaldebit = $form->format_amount(\%myconfig, $subtotaldebit, $form->{precision}, "&nbsp;");
    $subtotalcredit = $form->format_amount(\%myconfig, $subtotalcredit, $form->{precision}, "&nbsp;");
    $column_data{description} = "<th class=listsubtotal>$subtotaldescription</th>";
    $column_data{begbalance} = "<th align=right class=listsubtotal>$subtotalbegbalance</th>";
    $column_data{endbalance} = "<th align=right class=listsubtotal>$subtotalendbalance</th>";
    $column_data{debit} = "<th align=right class=listsubtotal>$subtotaldebit</th>";
    $column_data{credit} = "<th align=right class=listsubtotal>$subtotalcredit</th>";

    print qq|
    <tr class=listsubtotal>
|;
    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
    </tr>
|;
  }

  $totaldebit = $form->format_amount(\%myconfig, $totaldebit, $form->{precision}, "&nbsp;");
  $totalcredit = $form->format_amount(\%myconfig, $totalcredit, $form->{precision}, "&nbsp;");

  for (qw(accno description begbalance endbalance)) { $column_data{$_} = "<th>&nbsp;</th>" }

  $column_data{debit} = qq|<th align=right class=listtotal>$totaldebit</th>|;
  $column_data{credit} = qq|<th align=right class=listtotal>$totalcredit</th>|;

  print qq|
        <tr class=listtotal>
|;

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<form method=post action=$form->{script}>
|;

  %button = (
    'Save Report' =>
      {ndx => 8, key => 'S', value => $locale->text('Save Report')},
    'Display All' =>
      {ndx => 9, key => 'A', value => $locale->text('Display All')},
  );

  if (!$form->{admin}) {
    delete $button{'Save Report'} unless $form->{savereport};
  }

  if ($form->{year} && $form->{month}) {
    for (qw(fromdate todate)) { delete $form->{$_} }
  }

  $form->hide_form(qw(department projectnumber fromdate todate month year interval language_code l_heading l_subtotal all_accounts accounttype));

  $form->hide_form(qw(callback path login report reportcode reportlogin sort direction));

  $form->print_button(\%button);

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
</form>


</body>
</html>
|;

}


sub display_all {

  $form->{title} = $locale->text('Accounts');

  require "$form->{path}/ca.pl";

  RP->trial_balance(\%myconfig, $form);

  if ($form->{department}) {
    ($department) = split /--/, $form->{department};
    $options = $locale->text('Department')." : $department<br>";
  }
  if ($form->{projectnumber}) {
    ($projectnumber) = split /--/, $form->{projectnumber};
    $options .= $locale->text('Project Number')." : $projectnumber<br>";
  }

  if ($form->{fromdate} || $form->{todate}) {
    if ($form->{fromdate}) {
      $fromdate = $locale->date(\%myconfig, $form->{fromdate}, 1);
    }
    if ($form->{todate}) {
      $todate = $locale->date(\%myconfig, $form->{todate}, 1);
    }
    $form->{period} = "$fromdate - $todate";
  } else {
    $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);
  }
  $options .= $form->{period};

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$options</td>
  </tr>
</table>
|;

  my $oldform = $form;
  for my $ref (sort { $a->{accno} cmp $b->{accno} } @{$oldform->{TB}}) {
    next unless $ref->{charttype} eq 'A';

    $form = bless {%$oldform}, Form;
    $form->{accno}     = $ref->{accno};
    $form->{l_accno}   = 1;
    $form->{sort}      = 'transdate';
    $form->{subreport} = 1;

    $subtotaldebit = $subtotalcredit = 0;
    $totaldebit    = $totalcredit    = 0;

    &list_transactions;
  }

  print qq|

</body>
</html>
|;
}


sub generate_ar_aging {

  # split customer
  ($form->{customer}) = split(/--/, $form->{customer});

  $form->{vc} = "customer";
  $form->{arap} = "ar";

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};

  $form->{initcallback} = qq|$form->{script}?action=generate_ar_aging&todate=$form->{todate}|;

  RP->aging(\%myconfig, \%$form);

  &aging;

}


sub generate_ap_aging {

  # split vendor
  ($form->{vendor}) = split(/--/, $form->{vendor});
  $vendor = $form->escape($form->{vendor},1);
  $title = $form->escape($form->{title},1);
  $media = $form->escape($form->{media},1);

  $form->{vc} = "vendor";
  $form->{arap} = "ap";

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};

  $form->{initcallback} = qq|$form->{script}?action=generate_ap_aging&todate=$form->{todate}|;

  RP->aging(\%myconfig, \%$form);

  &aging;

}


sub aging {

  $form->{callback} = $form->{initcallback};
  for (qw(path login type format summary reportcode reportlogin)) { $form->{callback} .= "&$_=$form->{$_}" }
  for (qw(title media report)) { $form->{callback} .= qq|&$_=|.$form->escape($form->{$_},1) }
  $form->{callback} .= qq|&$form->{vc}=|.$form->escape($form->{"$form->{vc}"},1);
  $form->{selectprinter} = "";
  for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" }
  chomp $form->{selectprinter};

  %vc_ids = ();
  $form->{curr} = "";

  $form->header;

  $vcnumber = ($form->{vc} eq 'customer') ? $locale->text('Customer Number') : $locale->text('Vendor Number');

  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $action = ($form->{deselect}) ? "deselect_all" : "select_all";
  $column_header{ndx} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); javascript:main.submit()"><input type=hidden name=action value="$action"></th>|;
  $column_header{vc} = qq|<th class=listheading width=60%>|.$locale->text(ucfirst $form->{vc}).qq|</th>|;
  $column_header{"$form->{vc}number"} = qq|<th class=listheading>$vcnumber</th>|;
  $column_header{language} = qq|<th class=listheading>|.$locale->text('Language').qq|</th>|;
  $column_header{invnumber} = qq|<th class=listheading>|.$locale->text('Invoice').qq|</th>|;
  $column_header{ordnumber} = qq|<th class=listheading>|.$locale->text('Order').qq|</th>|;
  $column_header{transdate} = qq|<th class=listheading nowrap>|.$locale->text('Date').qq|</th>|;
  $column_header{duedate} = qq|<th class=listheading nowrap>|.$locale->text('Due Date').qq|</th>|;
  $column_header{c0} = qq|<th class=listheading width=10% nowrap>|.$locale->text('Current').qq|</th>|;
  $column_header{c15} = qq|<th class=listheading width=10% nowrap>15</th>|;
  $column_header{c30} = qq|<th class=listheading width=10% nowrap>30</th>|;
  $column_header{c45} = qq|<th class=listheading width=10% nowrap>45</th>|;
  $column_header{c60} = qq|<th class=listheading width=10% nowrap>60</th>|;
  $column_header{c75} = qq|<th class=listheading width=10% nowrap>75</th>|;
  $column_header{c90} = qq|<th class=listheading width=10% nowrap>90</th>|;
  $column_header{total} = qq|<th class=listheading width=10% nowrap>|.$locale->text('Total').qq|</th>|;

  @column_index = qw(ndx vc);
  push @column_index, "$form->{vc}number";

  if (@{ $form->{all_language} } && $form->{arap} eq 'ar') {
    push @column_index, "language";
    $form->{selectlanguage} = qq|\n|;

    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }

  if (!$form->{summary}) {
    push @column_index, qw(invnumber ordnumber transdate duedate);
  }

  @c = qw(c0 c15 c30 c45 c60 c75 c90);

  for (@c) {
    if ($form->{$_}) {
      push @column_index, $_;
      $form->{callback} .= "&$_=$form->{$_}";
    }
  }

  push @column_index, "total";

  $option = $locale->text('Aged');
  if ($form->{overdue}) {
    $option= $locale->text('Aged Overdue');
    $form->{callback} .= "&overdue=$form->{overdue}";
  }

  if ($form->{department}) {
      $option .= "\n<br>" if $option;
      ($department) = split /--/, $form->{department};
      $option .= $locale->text('Department')." : $department";
      $department = $form->escape($form->{department},1);
      $form->{callback} .= "&department=$department";
  }

  if ($form->{arap} eq 'ar') {
    if ($form->{customer}) {
      $option .= "\n<br>" if $option;
      $option .= $form->{customer};
    }
  }
  if ($form->{arap} eq 'ap') {
    shift @column_index;
    if ($form->{vendor}) {
      $option .= "\n<br>" if $option;
      $option .= $form->{vendor};
    }
  }

  $todate = $locale->date(\%myconfig, $form->{todate}, 1);
  $option .= "\n<br>" if $option;
  $option .= $locale->text('for Period')." ".$locale->text('To')." $todate";

  $title = "$form->{title} / $form->{company}";

  &check_all(qw(allbox ndx_));

  print qq|
<body>

<form method="post" name="main" action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$title</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
|;

  $vc_id = 0;
  $i = 0;
  $k = 0;
  $l = $#{ $form->{AG} };

  $callback = $form->escape($form->{callback},1);

  foreach $ref (@{ $form->{AG} }) {

    if ($curr ne $ref->{curr}) {
      $vc_id = 0;
      for (@column_index) { $column_data{$_} = qq|<th>&nbsp;</th>| }
      if ($curr) {

        for (@c) {
          $column_data{$_} = qq|<th align=right>|.$form->format_amount(\%myconfig, $c{$_}{total}, $form->{precision}, "&nbsp").qq|</th>|;
          $c{$_}{total} = 0;
          $c{$_}{subtotal} = 0;
        }

        $column_data{total} = qq|<th align=right>|.$form->format_amount(\%myconfig, $total, $form->{precision}, "&nbsp").qq|</th>|;

        for (qw(vc ndx language)) { $column_data{$_} = qq|<td>&nbsp;</td>| }
        print qq|
        <tr class=listtotal>
|;

        for (@column_index) { print "$column_data{$_}\n" }

        print qq|
          </tr>
|;

        $total = 0;

      }

      $form->{curr} .= "$ref->{curr} ";

      print qq|
        <tr>
          <td></td>
          <th>$ref->{curr}</th>
        </tr>

        <tr class=listheading>
|;

      for (@column_index) { print "$column_header{$_}\n" }

      print qq|
        </tr>
|;
    }

    $curr = $ref->{curr};
    $k++;

    if ($vc_id != $ref->{vc_id}) {

      $column_data{vc} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{vc_id}&db=$form->{vc}&callback=$callback>$ref->{name}</a></td>|;
      $column_data{"$form->{vc}number"} = qq|<td>$ref->{"$form->{vc}number"}</td>|;

      if ($form->{selectlanguage}) {
        if (exists $form->{"language_code_$ref->{curr}_$ref->{vc_id}"}) {
          $ref->{language_code} = $form->{"language_code_$ref->{curr}_$ref->{vc_id}"};
        }

        $column_data{language} = qq|<td><select name="language_code_$ref->{curr}_$ref->{vc_id}">|.$form->select_option($form->{selectlanguage}, $ref->{language_code}, undef, 1).qq|</select></td>|;
      }

      $checked = ($form->{"ndx_$ref->{curr}_$ref->{vc_id}"}) ? "checked" : "";
      $column_data{ndx} = qq|<td><input name="ndx_$ref->{curr}_$ref->{vc_id}" type=checkbox class=checkbox value=1 $checked></td>|;

      $vc_ids{"$ref->{vc_id}"} = 1;
      $linetotal = 0;

    }

    $vc_id = $ref->{vc_id};

    for (@c) {

      $ref->{$_} = $form->round_amount($ref->{$_} / $ref->{exchangerate}, $form->{precision});

      $c{$_}{total} += $ref->{$_};
      $c{$_}{subtotal} += $ref->{$_};
      $linetotal += $ref->{$_};
      $total += $ref->{$_};

      $column_data{$_} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}, "&nbsp;").qq|</td>|;

    }

    $column_data{total} = qq|<td align=right>|.$form->format_amount(\%myconfig, $linetotal, $form->{precision}, "&nbsp;").qq|</td>|;

    $href = qq|$ref->{module}.pl?path=$form->{path}&action=edit&id=$ref->{id}&login=$form->{login}&callback=|.$form->escape($form->{callback});

    $column_data{invnumber} = qq|<td><a href=$href>$ref->{invnumber}</a></td>|;
    $column_data{ordnumber} = qq|<td>$ref->{ordnumber}</td>|;
    for (qw(transdate duedate)) { $column_data{$_} = qq|<td nowrap>$ref->{$_}</td>| }

    if (!$form->{summary}) {

      $j++; $j %= 2;
      print qq|
        <tr class=listrow$j>
|;

      for (@column_index) { print "$column_data{$_}\n" }

      print qq|
        </tr>
|;

      for (qw(vc ndx language)) { $column_data{$_} = qq|<td>&nbsp;</td>| }
      $column_data{"$form->{vc}number"} = qq|<td>&nbsp;</td>|;

    }

    # print subtotal
    if ($l > 0) {
      if ($k <= $l) {
        $nextid = $form->{AG}->[$k]->{vc_id};
        $nextcurr = $form->{AG}->[$k]->{curr};
      } else {
        $nextid = 0;
        $nextcurr = "";
      }
    }

    if (($vc_id != $nextid) || ($curr ne $nextcurr)) {

      for (@c) {
        $c{$_}{subtotal} = $form->format_amount(\%myconfig, $c{$_}{subtotal}, $form->{precision}, "&nbsp");
      }

      if ($form->{summary}) {
        for (@c) {
          $column_data{$_} = qq|<td align=right>$c{$_}{subtotal}</th>|;
          $c{$_}{subtotal} = 0;
        }

        $j++; $j %= 2;
        print qq|
      <tr class=listrow$j>
|;

        for (@column_index) { print "$column_data{$_}\n" }

        print qq|
      </tr>
|;

      } else {

        for (@column_index) { $column_data{$_} = qq|<th>&nbsp;</th>| }

        for (@c) {
          $column_data{$_} = qq|<th class=listsubtotal align=right>$c{$_}{subtotal}</th>|;
          $c{$_}{subtotal} = 0;
        }

        # print subtotals
        print qq|
      <tr class=listsubtotal>
|;
        for (@column_index) { print "$column_data{$_}\n" }

        print qq|
      </tr>
|;

      }
    }
  }

  print qq|
        </tr>
        <tr class=listtotal>
|;

  for (@column_index) { $column_data{$_} = qq|<th>&nbsp;</th>| }

  for (@c) {
    $column_data{$_} = qq|<th align=right class=listtotal>|.$form->format_amount(\%myconfig, $c{$_}{total}, $form->{precision}, "&nbsp;").qq|</th>|;
  }

  $column_data{total} = qq|<th align=right class=listtotal>|.$form->format_amount(\%myconfig, $total, $form->{precision}, "&nbsp;").qq|</th>|;

  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>
|;

  &print_options if ($form->{arap} eq 'ar');

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->{todate} = $temp{todate};

  $form->{vc_ids} = join ' ', (keys %vc_ids);
  chop $form->{curr};

  $form->hide_form(qw(month year todate title summary overdue initcallback callback arap vc department path login vc_ids curr));
  $form->hide_form(@c, "$form->{vc}");

  $form->hide_form(qw(report reportcode reportlogin));

  if ($form->{arap} eq 'ar') {

    %button = ('Select all' => { ndx => 1, key => 'A', value => $locale->text('Select all') },
               'Deselect all' => { ndx => 2, key => 'A', value => $locale->text('Deselect all') },
               'Preview' => { ndx => 3, key => 'V', value => $locale->text('Preview') },
               'Print' => { ndx => 4, key => 'P', value => $locale->text('Print') },
               'E-mail' => { ndx => 5, key => 'E', value => $locale->text('E-mail') },
              );

    if ($form->{deselect}) {
      delete $button{'Select all'};
    } else {
      delete $button{'Deselect all'};
    }

  }

  $button{'Save Report'} = { ndx => 8, key => 'S', value => $locale->text('Save Report') };

  if (!$form->{admin}) {
    delete $button{'Save Report'} unless $form->{savereport};
  }

  $form->print_button(\%button);

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
</form>

</body>
</html>
|;

}


sub select_all { &{ "select_all_$form->{type}" } }

sub select_all_statement {

  RP->aging(\%myconfig, \%$form);

  for (@{ $form->{AG} }) { $form->{"ndx_$_->{curr}_$_->{vc_id}"} = "checked" }
  $form->{allbox} = "checked";
  $form->{deselect} = 1;

  &aging;

}


sub select_all_reminder {

  RP->reminder(\%myconfig, \%$form);

  for (@{ $form->{AG} }) { $form->{"ndx_$_->{id}"} = "checked" }
  $form->{allbox} = "checked";
  $form->{deselect} = 1;

  &reminder;

}


sub deselect_all { &{ "deselect_all_$form->{type}" } }

sub deselect_all_statement {

  RP->aging(\%myconfig, \%$form);

  for (@{ $form->{AG} }) { $form->{"ndx_$_->{curr}_$_->{vc_id}"} = "" }
  $form->{allbox} = "";

  &aging;

}


sub deselect_all_reminder {

  RP->reminder(\%myconfig, \%$form);

  for (@{ $form->{AG} }) { $form->{"ndx_$_->{id}"} = "" }
  $form->{allbox} = "";

  &reminder;

}


sub generate_reminder {

  $form->{vc} = "customer";
  $form->{arap} = "ar";

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};

  $form->{initcallback} = qq|$form->{script}?action=generate_reminder|;

  RP->reminder(\%myconfig, \%$form);

  &reminder;

}


sub reminder {

  $form->{callback} = $form->{initcallback};
  for (qw(path login type format reportcode reportlogin)) { $form->{callback} .= "&$_=$form->{$_}" }
  for (qw(title media report)) { $form->{callback} .= qq|&$_=|.$form->escape($form->{$_},1) }
  $form->{callback} .= qq|&$form->{vc}=|.$form->escape($form->{"$form->{vc}"},1);
  $form->{selectprinter} = "";
  for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" }
  chomp $form->{selectprinter};


  $form->header;

  $vcnumber = $locale->text('Customer Number');

  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $action = ($form->{deselect}) ? "deselect_all" : "select_all";
  $column_data{ndx} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); javascript:main.submit()"><input type=hidden name=action value="$action"></th>|;
  $column_data{vc} = qq|<th class=listheading width=60%>|.$locale->text(ucfirst $form->{vc}).qq|</th>|;
  $column_data{"$form->{vc}number"} = qq|<th class=listheading>$vcnumber</th>|;
  $column_data{level} = qq|<th class=listheading>|.$locale->text('Level').qq|</th>|;
  $column_data{language} = qq|<th class=listheading>|.$locale->text('Language').qq|</th>|;
  $column_data{invnumber} = qq|<th class=listheading>|.$locale->text('Invoice').qq|</th>|;
  $column_data{ordnumber} = qq|<th class=listheading>|.$locale->text('Order').qq|</th>|;
  $column_data{transdate} = qq|<th class=listheading nowrap>|.$locale->text('Date').qq|</th>|;
  $column_data{duedate} = qq|<th class=listheading nowrap>|.$locale->text('Due Date').qq|</th>|;
  $column_data{due} = qq|<th class=listheading nowrap>|.$locale->text('Due').qq|</th>|;

  @column_index = qw(ndx vc);
  push @column_index, "$form->{vc}number";
  push @column_index, "level";

  $form->{selectlevel} = "1\n2\n3";

  if (@{ $form->{all_language} }) {
    push @column_index, "language";
    $form->{selectlanguage} = qq|\n|;

    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }

  push @column_index, qw(invnumber ordnumber transdate duedate due);

  if ($form->{department}) {
      $option .= "\n<br>" if $option;
      ($department) = split /--/, $form->{department};
      $option .= $locale->text('Department')." : $department";
      $department = $form->escape($form->{department},1);
      $form->{callback} .= "&department=$department";
  }

  if ($form->{customer}) {
    $option .= "\n<br>" if $option;
    ($customer) = split /--/, $form->{customer};
    $option .= $locale->text('Customer')." : $customer";
    $customer = $form->escape($form->{customer},1);
    $form->{callback} .= "&customer=$customer";
  }

  $title = "$form->{title} / $form->{company}";

  &check_all(qw(allbox ndx_));

  print qq|
<body>

<form method="post" name="main" action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$title</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
|;

  $curr = "";
  $form->{ids} = "";

  $callback = $form->escape($form->{callback},1);

  for $ref (@{ $form->{AG} }) {

    if ($curr ne $ref->{curr}) {

      if ($curr) {

        print qq|
        <tr class=listtotal>
|;

        for (@column_index) { $column_data{$_} = qq|<th>&nbsp;</th>| }
        for (@column_index) { print "$column_data{$_}\n" }

        print qq|
          </tr>
|;

      }

      print qq|
        <tr>
          <td></td>
          <th>$ref->{curr}</th>
        </tr>

        <tr class=listheading>
|;

      for (@column_index) { print "$column_data{$_}\n" }

      print qq|
        </tr>
|;
    }

    $curr = $ref->{curr};

    $column_data{vc} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{vc_id}&db=$form->{vc}&callback=$callback>$ref->{name}</a></td>
    <input type=hidden name="vc_$ref->{id}" value="$ref->{vc_id}">|;

    $column_data{"$form->{vc}number"} = qq|<td>$ref->{"$form->{vc}number"}</td>|;

    if (exists $form->{"level_$ref->{id}"}) {
      $ref->{level} = $form->{"level_$ref->{id}"};
    }
    $column_data{level} = qq|<td><select name="level_$ref->{id}">|.$form->select_option($form->{selectlevel}, $ref->{level}).qq|</select></td>|;

    if ($form->{selectlanguage}) {
      if (exists $form->{"language_code_$ref->{id}"}) {
        $ref->{language_code} = $form->{"language_code_$ref->{id}"};
      }

      $column_data{language} = qq|<td><select name="language_code_$ref->{id}">|.$form->select_option($form->{selectlanguage}, $ref->{language_code}, undef, 1).qq|</select></td>|;
    }

    $checked = ($form->{"ndx_$ref->{id}"}) ? "checked" : "";
    $column_data{ndx} = qq|<td><input name="ndx_$ref->{id}" type=checkbox class=checkbox value=1 $checked></td>|;

    $form->{ids} .= "$ref->{id} ";

    $href = qq|$ref->{module}.pl?path=$form->{path}&action=edit&id=$ref->{id}&login=$form->{login}&callback=|.$form->escape($form->{callback});

    $column_data{invnumber} = qq|<td><a href=$href>$ref->{invnumber}</a></td>|;
    $column_data{ordnumber} = qq|<td>$ref->{ordnumber}</td>|;
    for (qw(transdate duedate)) { $column_data{$_} = qq|<td nowrap>$ref->{$_}</td>| }

    $column_data{due} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{due} / $ref->{exchangerate}, $form->{precision}).qq|</td>|;

    $j++; $j %= 2;
    print qq|
      <tr class=listrow$j>
|;

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
      </tr>
|;

    for (qw(vc ndx language level)) { $column_data{$_} = qq|<td>&nbsp;</td>| }
    $column_data{"$form->{vc}number"} = qq|<td>&nbsp;</td>|;

  }

  print qq|
        </tr>
        <tr class=listtotal>
|;

  for (@column_index) { $column_data{$_} = qq|<th>&nbsp;</th>| }
  for (@column_index) { print "$column_data{$_}\n" }

  print qq|
        </tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>
|;

  &print_options;

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  chop $form->{ids};

  $form->hide_form(qw(title initcallback callback vc department path login ids));
  $form->hide_form($form->{vc});
  $form->hide_form(qw(report reportcode reportlogin subject message));

  %button = ('Select all' => { ndx => 1, key => 'A', value => $locale->text('Select all') },
             'Deselect all' => { ndx => 2, key => 'A', value => $locale->text('Deselect all') },
             'Preview' => { ndx => 3, key => 'V', value => $locale->text('Preview') },
             'Print' => { ndx => 4, key => 'P', value => $locale->text('Print') },
             'E-mail' => { ndx => 5, key => 'E', value => $locale->text('E-mail') },
             'Save Level' => { ndx => 6, key => 'L', value => $locale->text('Save Level') },
            );

  if ($form->{deselect}) {
    delete $button{'Select all'};
  } else {
    delete $button{'Deselect all'};
  }

  $button{'Save Report'} = { ndx => 8, key => 'S', value => $locale->text('Save Report') };

  if (!$form->{admin}) {
    delete $button{'Save Report'} unless $form->{savereport};
  }

  $form->print_button(\%button);

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
</form>

</body>
</html>
|;

}


sub save_level {

  if (RP->save_level(\%myconfig, \%$form)) {
    $form->redirect;
  }

  $form->error($locale->text('Could not save reminder level!'));

}


sub print_options {

  $form->{copies} ||= 1;
  $form->{PD}{$form->{type}} = "selected";

  if ($myconfig{printer}) {
    $form->{format} ||= "ps";
  }
  $form->{media} ||= $myconfig{printer};

  $form->{sendmode} = "attachment";

  if ($form->{media} eq 'email') {
    $media = qq|<select name=sendmode>
            <option value=attachment>|.$locale->text('Attachment').qq|
            <option value=inline>|.$locale->text('In-line')
            .qq|</select>|;

    if ($form->{selectlanguage}) {
      $lang = qq|<select name="language_code">|.$form->select_option($form->{selectlanguage}, $form->{language_code}, undef, 1).qq|</select>|;
    }
  } else {
    $media = qq|<select name=media>
            <option value=screen>|.$locale->text('Screen');

    if ($form->{selectprinter} && $latex) {
      for (split /\n/, $form->{selectprinter}) { $media .= qq|
            <option value="$_">$_| }
    }
  }

  $format = qq|<select name=format>
            <option value="html">|.$locale->text('html').qq|
            <option value="xml">|.$locale->text('XML').qq|
            <option value="txt">|.$locale->text('Text');

  $formname{statement} = $locale->text('Statement');
  $formname{reminder} = $locale->text('Reminder');

  $type = qq|<select name=type>
            <option value="$form->{type}" $form->{PD}{$form->{type}}>$formname{$form->{type}}
            </select>|;

  $media .= qq|</select>|;
  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

  if ($latex) {
    $format .= qq|
            <option value="ps">|.$locale->text('Postscript').qq|
            <option value="pdf">|.$locale->text('PDF');
  }

  $format .= qq|</select>|;
  $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;


  print qq|
<table>
  <tr>
    <td>$type</td>
    <td>$lang</td>
    <td>$format</td>
    <td>$media</td>
|;

  if ($form->{selectprinter} && $latex && $form->{media} ne 'email') {
    print qq|
      <td nowrap>|.$locale->text('Copies').qq|
      <input name=copies size=2 value=$form->{copies}></td>
|;
  }

  $form->{selectlanguage} = $form->escape($form->{selectlanguage},1);
  $form->hide_form(qw(selectlanguage));

  print qq|
  </tr>
</table>
|;

}


sub e_mail { &{ "e_mail_$form->{type}" } }


sub e_mail_statement {

  # get name and email addresses
  @vc_ids = split / /, $form->{vc_ids};
  $found = 0;
  for $curr (split / /, $form->{curr}) {
    for (@vc_ids) {
      if ($form->{"ndx_${curr}_$_"}) {
        $form->{"$form->{vc}_id"} = $_;
        $found++;
      }
    }
  }

  $form->error($locale->text('Can only send one statement at a time!')) if $found > 1;

  for $curr (split / /, $form->{curr}) {
    for (@vc_ids) {
      if ($form->{"ndx_${curr}_$_"}) {
        $form->{"$form->{vc}_id"} = $_;
        $form->{language_code} = $form->{"language_code_${curr}_$_"};
        RP->get_customer(\%myconfig, \%$form);
        $selected = 1;
        last;
      }
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $selected;


  if ($form->{admin}) {
    $bcc = qq|
          <th align=right nowrap=true>|.$locale->text('Bcc').qq|</th>
          <td><input name=bcc size=30 value="$form->{bcc}"></td>
|;
  }

  $form->helpref("e_mail_$form->{arap}_statement", $myconfig{countrycode});

  $title = $locale->text('E-mail Statement to')." $form->{$form->{vc}}";

  &prepare_e_mail;

}


sub e_mail_reminder {

  $found = 0;
  for (split / /, $form->{ids}) {
    if ($form->{"ndx_$_"}) {
      $found++;
    }
  }

  $form->error($locale->text('Can only send one reminder at a time!')) if $found > 1;

  # get name and email addresses
  for (split / /, $form->{ids}) {
    if ($form->{"ndx_$_"}) {
      $form->{"$form->{vc}_id"} = $form->{"vc_$_"};
      $form->{language_code} = $form->{"language_code_$_"};
      RP->get_customer(\%myconfig, \%$form);
      $selected = 1;
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $selected;

  if ($form->{admin}) {
    $bcc = qq|
          <th align=right nowrap=true>|.$locale->text('Bcc').qq|</th>
          <td><input name=bcc size=30 value="$form->{bcc}"></td>
|;
  }

  $form->helpref("e_mail_reminder", $myconfig{countrycode});

  $title = $locale->text('E-mail Reminder to')." $form->{$form->{vc}}";

  &prepare_e_mail;

}



sub prepare_e_mail {

  for (qw(media format)) { $form->{"old$_"} = $form->{$_} }

  $form->{media} = "email";
  $form->{format} = "pdf";

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listtop>
    <th>$form->{helpref}$title</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr>
          <th align=right nowrap>|.$locale->text('E-mail').qq|</th>
          <td><input name=email size=30 value="$form->{email}"></td>
          <th align=right nowrap>|.$locale->text('Cc').qq|</th>
          <td><input name=cc size=30 value="$form->{cc}"></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Subject').qq|</th>
          <td><input name=subject size=30 value="|.$form->quote($form->{subject}).qq|"></td>
          $bcc
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr>
          <th align=left nowrap>|.$locale->text('Message').qq|</th>
        </tr>
        <tr>
          <td><textarea name=message rows=15 cols=60 wrap=soft>$form->{message}</textarea></td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
|;

  &print_options;

  $nextsub = "send_email_$form->{type}";

  for (qw(language_code email cc bcc subject message type sendmode format action nextsub)) { delete $form->{$_} }

  $form->hide_form;

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value="$nextsub">

<br>
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">
</form>

</body>
</html>
|;

}


sub send_email_statement {

  $form->{OUT} = "$sendmail";

  $form->isblank("email", $locale->text('E-mail address missing!'));

  RP->aging(\%myconfig, \%$form);

  $form->{subject} = $locale->text('Statement').qq| - $form->{todate}| unless $form->{subject};

  for $curr (split / /, $form->{curr}) {
    for (split / /, $form->{vc_ids}) {
      if ($form->{"ndx_${curr}_$_"}) {
        $form->{"language_code_${curr}_$_"} = $form->{language_code};
      }
    }
  }

  &print_statement;

  if ($form->{callback}) {
    for $curr (split / /, $form->{curr}) {
      for (split / /, $form->{vc_ids}) {
        if ($form->{"ndx_${curr}_$_"}) {
          $form->{callback} .= qq|&ndx_${curr}_$_=1&language_code_${curr}_$_=|.$form->escape($form->{language_code},1);
        }
      }
    }
  }

  $form->redirect($locale->text('Statement sent to')." $form->{$form->{vc}}");

}


sub send_email_reminder {

  $form->{OUT} = "$sendmail";

  $form->isblank("email", $locale->text('E-mail address missing!'));

  RP->reminder(\%myconfig, \%$form);

  $form->{subject} = $locale->text('Reminder') unless $form->{subject};

  for (split / /, $form->{ids}) {
    if ($form->{"ndx_$_"}) {
      $form->{"language_code_$_"} = $form->{language_code};
    }
  }

  &print_reminder;

  if ($form->{callback}) {
    for (split / /, $form->{ids}) {
      if ($form->{"ndx_$_"}) {
        $form->{callback} .= qq|&ndx_$_=1&level_$_=$form->{"level_$_"}&language_code_$_=|.$form->escape($form->{language_code},1);
      }
    }
    for (qw|subject message|) {
      $form->{callback} .= qq|&$_=|.$form->escape($form->{$_}, 1) if $form->{$_};
    }
  }

  $form->redirect($locale->text('Reminder sent to')." $form->{$form->{vc}}");

}


sub print { &{ "print_$form->{type}" } }


sub print_statement {

  @vc_ids = split / /, $form->{vc_ids};
  for $curr (split / /, $form->{curr}) {
    last if $selected;
    for (@vc_ids) {
      if ($form->{"ndx_${curr}_$_"}) {
        $selected = "ndx_${curr}_$_";
        last;
      }
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $selected;

  if ($form->{media} eq 'screen') {
    for $curr (split / /, $form->{curr}) {
      for (@vc_ids) {
        $form->{"ndx_${curr}_$_"} = "";
      }
    }
    $form->{$selected} = 1;
  }

  if ($form->{media} !~ /(screen|email)/) {
    $form->{"$form->{vc}_id"} = "";
    $SIG{INT} = 'IGNORE';
  }

  RP->aging(\%myconfig, \%$form);

  if ($form->{media} !~ /(screen|email)/) {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;
  }

  @c = qw(c0 c15 c30 c45 c60 c75 c90);
  $item = $c[0];
  @{$ag} = ();

  for (@c) {
    if ($form->{$_}) {
      $item = $_;
    }
    push @{ $ag{$item} }, $_;
  }

  for (keys %ag) {
    shift @{ $ag{$_} };
  }

  for (keys %ag) {
    for $item (@{ $ag{$_} }) {
      $c{$_} += $c{$item};
    }
  }

  &do_print_statement;

  if ($form->{callback}) {
    for $curr (split / /, $form->{curr}) {
      for (split / /, $form->{vc_ids}) {
        if ($form->{"ndx_${curr}_$_"}) {
          $form->{callback} .= qq|&ndx_${curr}_$_=1&language_code_${curr}_$_=|.$form->escape($form->{"language_code_${curr}_$_"},1);
        }
      }
    }
  }

  $form->redirect($locale->text('Statements sent to printer!')) if ($form->{media} !~ /(screen|email)/);

}


sub print_reminder {

  @ids = split / /, $form->{ids};
  for (@ids) {
    if ($form->{"ndx_$_"}) {
      $selected = "ndx_$_";
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $selected;

  if ($form->{media} eq 'screen') {
    for (@ids) {
      $form->{"ndx_$_"} = "";
    }
    $form->{$selected} = 1;
  }

  if ($form->{media} !~ /(screen|email)/) {
    $form->{"$form->{vc}_id"} = "";
    $SIG{INT} = 'IGNORE';
  }

  RP->reminder(\%myconfig, \%$form);

  if ($form->{media} !~ /(screen|email)/) {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;
  }

  &do_print_reminder;

  if ($form->{callback}) {
    for (split / /, $form->{ids}) {
      if ($form->{"ndx_$_"}) {
        $form->{callback} .= qq|&ndx_$_=1&level_$_=$form->{"level_$_"}&language_code_$_=|.$form->escape($form->{"language_code_$_"},1);
      }
    }
  }

  $form->redirect($locale->text('Reminders sent to printer!')) if ($form->{media} !~ /(screen|email)/);

}


sub do_print_reminder {

  $out = $form->{OUT};

  $form->{todate} ||= $form->current_date(\%myconfig);
  $form->{statementdate} = $locale->date(\%myconfig, $form->{todate}, 1);

  $form->{templates} = "$templates/$myconfig{templates}";

  for (qw(name email)) { $form->{"user$_"} = $myconfig{$_} }

  # setup variables for the form
  $form->format_string(qw(company address businessnumber companyemail companywebsite username useremail tel fax));

  @a = qw(name address1 address2 city state zipcode country contact typeofcontact salutation firstname lastname);
  push @a, map { "$form->{vc}$_" } qw(number phone fax taxnumber);
  push @a, map { "shipto$_" } qw(name address1 address2 city state zipcode country contact phone fax email);
  push @a, qw(dcn rvc iban qriban bic membernumber clearingnumber);
  push @a, map { "bank$_" } qw(name address1 address2 city state zipcode country);

  $c = CP->new(($form->{language_code}) ? $form->{language_code} : $myconfig{countrycode});

  while (@{ $form->{AG} }) {

    $ref = shift @{ $form->{AG} };
    $form->{OUT} = $out;

    if ($form->{"ndx_$ref->{id}"}) {

      for (@a) { $form->{$_} = $ref->{$_} }

      $form->format_string(@a);

      $form->{IN} = qq|$form->{type}$form->{"level_$ref->{id}"}.$form->{format}|;

      if ($form->{format} =~ /(ps|pdf)/) {
        $form->{IN} =~ s/$&$/tex/;
      }

      $form->{pre} = "<body bgcolor=#ffffff>\n<pre>" if $form->{format} eq 'txt';

      $form->{$form->{vc}} = $form->{name};
      $form->{"$form->{vc}_id"} = $ref->{vc_id};
      $form->{language_code} = $form->{"language_code_$ref->{id}"};
      $form->{currency} = $ref->{curr};

      for (qw(invnumber ordnumber ponumber notes invdate duedate invdescription)) { $form->{$_} = () }

      $ref->{invdate} = $ref->{transdate};
      my @a = qw(invnumber ordnumber ponumber notes invdate duedate invdescription);
      for (@a) { $form->{"${_}_1"} = $ref->{$_} }
      $form->format_string(map { "${_}_1" } qw(invnumber ordnumber ponumber notes invdescription));
      for (@a) { $form->{$_} = $form->{"${_}_1"} }

      $ref->{exchangerate} ||= 1;

      $c->init;

      ($whole, $form->{decimal}) = split /\./, $ref->{due} / $ref->{exchangerate};
      $form->{decimal} = substr("$form->{decimal}00", 0, 2);
      $form->{text_decimal} = $c->num2text($form->{decimal} * 1);
      $form->{text_amount} = $c->num2text($whole);
      $form->{integer_amount} = $whole;

      $form->{out_decimal} = $form->{decimal};
      $form->{text_out_decimal} = $form->{text_decimal};
      $form->{text_out_amount} = $form->{text_amount};
      $form->{integer_out_amount} = $form->{integer_amount};

      my $i = 10;
      for (reverse split //, 100 * $ref->{due}) {
        $form->{"total".$i--} = $_;
      }

      $form->{rvc} = $form->format_dcn($ref->{rvc});
      $form->format_string(rvc);

      $form->{due} = $form->format_amount(\%myconfig, $ref->{due} / $ref->{exchangerate}, $form->{precision});

      $form->parse_template(\%myconfig, $userspath, $dvipdf, $xelatex);

    }
  }
}


sub do_print_statement {

  $out = $form->{OUT};

  $form->{todate} ||= $form->current_date(\%myconfig);
  $form->{statementdate} = $locale->date(\%myconfig, $form->{todate}, 1);

  $form->{templates} = "$templates/$myconfig{templates}";

  for (qw(name email)) { $form->{"user$_"} = $myconfig{$_} }

  # setup variables for the form
  $form->format_string(qw(company address businessnumber companyemail companywebsite username useremail tel fax companyemail companywebsite));

  @a = qw(name address1 address2 city state zipcode country contact typeofcontact salutation firstname lastname);
  push @a, "$form->{vc}number", "$form->{vc}phone", "$form->{vc}fax", "$form->{vc}taxnumber";
  push @a, map { "shipto$_" } qw(name address1 address2 city state zipcode country contact phone fax email);

  $i = 0;
  while (@{ $form->{AG} }) {

    $ref = shift @{ $form->{AG} };
    $form->{OUT} = $out;

    if ($vc_id != $ref->{vc_id}) {

      if ($form->{"ndx_$ref->{curr}_$ref->{vc_id}"}) {

        $vc_id = $ref->{vc_id};

        for (@a) { $form->{$_} = $ref->{$_} }
        $form->format_string(@a);

        $form->{IN} = qq|$form->{type}.$form->{format}|;

        if ($form->{format} =~ /(ps|pdf)/) {
          $form->{IN} =~ s/$&$/tex/;
        }

        $form->{pre} = "<body bgcolor=#ffffff>\n<pre>" if $form->{format} eq 'txt';

        $form->{$form->{vc}} = $form->{name};
        $form->{"$form->{vc}_id"} = $ref->{vc_id};
        $form->{language_code} = $form->{"language_code_$ref->{curr}_$ref->{vc_id}"};
        $form->{currency} = $ref->{curr};

        for (qw(invnumber ordnumber ponumber notes invdate duedate invdescription)) { $form->{$_} = () }
        $form->{total} = 0;
        foreach $item (qw(c0 c15 c30 c45 c60 c75 c90)) {
          $form->{$item} = ();
          $form->{"${item}total"} = 0;
        }

        &statement_details($ref);

        while ($ref) {

          if (scalar (@{ $form->{AG} }) > 0) {
            # one or more left to go
            if ($vc_id == $form->{AG}->[0]->{vc_id}) {
              $ref = shift @{ $form->{AG} };
              &statement_details($ref) if $ref->{curr} eq $form->{currency};
              # any more?
              $ref = scalar (@{ $form->{AG} });
            } else {
              $ref = 0;
            }
          } else {
            # set initial ref to 0
            $ref = 0;
          }

        }

        for ("c0", "c15", "c30", "c45", "c60", "c75", "c90", "") { $form->{"${_}total"} = $form->format_amount(\%myconfig, $form->{"${_}total"}, $form->{precision}) }

        $form->parse_template(\%myconfig, $userspath, $dvipdf, $xelatex);

      }
    }
  }

}


sub statement_details {
  my ($ref) = @_;

  $ref->{invdate} = $ref->{transdate};
  my @a = qw(invnumber ordnumber ponumber notes invdate duedate invdescription);
  for (@a) { $form->{"${_}_1"} = $ref->{$_} }
  $form->format_string(qw(invnumber_1 ordnumber_1 ponumber_1 notes_1 invdescription_1));
  for (@a) { push @{ $form->{$_} }, $form->{"${_}_1"} }

  foreach $item (qw(c0 c15 c30 c45 c60 c75 c90)) {
    $ref->{exchangerate} ||= 1;
    $ref->{$item} = $form->round_amount($ref->{$item} / $ref->{exchangerate}, $form->{precision});
    $form->{"${item}total"} += $ref->{$item};
    $form->{total} += $ref->{$item};
    push @{ $form->{$item} }, $form->format_amount(\%myconfig, $ref->{$item}, $form->{precision});
  }

}


sub generate_tax_report {

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};

  for (qw(fromdate todate)) { $temp{$_} = $form->{$_} };

  RP->tax_report(\%myconfig, \%$form);

  # construct href
  $href = "$form->{script}?action=generate_tax_report";

  for (qw(path direction oldsort login fromdate todate db method summary reportcode reportlogin)) { $href .= "&$_=$form->{$_}" }
  for (split / /, $form->{taxaccounts}) {
    $href .= qq|&accno_$_=$form->{"accno_$_"}&${_}_description=|.$form->escape($form->{"${_}_description"});
  }
  for (split / /, $form->{gifi_taxaccounts}) {
    $href .= qq|&gifi_$_=$form->{"gifi_$_"}&gifi_${_}_description=|.$form->escape($form->{"gifi_${_}_description"});
  }
  for (qw(taxaccounts gifi_taxaccounts department report helpref title)) { $href .= "&$_=".$form->escape($form->{$_}) }

  # construct callback

  $form->sort_order();

  $callback = "$form->{script}?action=generate_tax_report";
  for (qw(path direction oldsort login fromdate todate db method summary reportcode reportlogin)) { $callback .= "&$_=$form->{$_}" }
  for (split / /, $form->{taxaccounts}) {
    $callback .= qq|&accno_$_=$form->{"accno_$_"}&${_}_description=|.$form->escape($form->{"${_}_description"});
  }
  for (split / /, $form->{gifi_taxaccounts}) {
    $callback .= qq|&gifi_$_=$form->{"gifi_$_"}&gifi_${_}_description=|.$form->escape($form->{"gifi_${_}_description"});
  }
  for (qw(taxaccounts gifi_taxaccounts department report helpref title)) { $callback .= "&$_=".$form->escape($form->{$_},1) };

  $title = qq|$form->{title} / $form->{company}|;

  if ($form->{db} eq 'ar') {
    $name = $locale->text('Customer');
    $vcnumber = $locale->text('Customer Number');
    $invoice = 'is.pl';
    $arap = 'ar.pl';
    $form->{vc} = "customer";
  }
  if ($form->{db} eq 'ap') {
    $name = $locale->text('Vendor');
    $vcnumber = $locale->text('Vendor Number');
    $invoice = 'ir.pl';
    $arap = 'ap.pl';
    $form->{vc} = "vendor";
  }

  @columns = qw(id transdate invnumber description name);
  push @columns, "$form->{vc}number";
  push @columns, qw(address country taxnumber netamount tax total);
  @columns = $form->sort_columns(@columns);

  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      # add column to href and callback
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }

  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
    $href .= "&l_subtotal=Y";
  }

  if ($form->{department}) {
    ($department) = split /--/, $form->{department};
    $option = $locale->text('Department')." : $department";
  }

  # if there are any dates
  if ($form->{fromdate} || $form->{todate}) {
    if ($form->{fromdate}) {
      $fromdate = $locale->date(\%myconfig, $form->{fromdate}, 1);
    }
    if ($form->{todate}) {
      $todate = $locale->date(\%myconfig, $form->{todate}, 1);
    }

    $form->{period} = "$fromdate - $todate";
  } else {
    $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);
  }


  $option .= "<br>" if $option;
  $option .= $locale->text('Cash') if ($form->{method} eq 'cash');
  $option .= $locale->text('Accrual') if ($form->{method} eq 'accrual');

  $option .= "<br>$form->{period}";

  $column_data{id} = qq|<th><a class=listheading href=$href&sort=id>|.$locale->text('ID').qq|</th>|;
  $column_data{invnumber} = qq|<th><a class=listheading href=$href&sort=invnumber>|.$locale->text('Invoice').qq|</th>|;
  $column_data{transdate} = qq|<th nowrap><a class=listheading href=$href&sort=transdate>|.$locale->text('Date').qq|</th>|;
  $column_data{netamount} = qq|<th class=listheading>|.$locale->text('Amount').qq|</th>|;
  $column_data{tax} = qq|<th class=listheading>|.$locale->text('Tax').qq|</th>|;
  $column_data{total} = qq|<th class=listheading>|.$locale->text('Total').qq|</th>|;

  $column_data{name} = qq|<th><a class=listheading href=$href&sort=name>$name</th>|;
  $column_data{"$form->{vc}number"} = qq|<th><a class=listheading href=$href&sort=$form->{vc}number>$vcnumber</th>|;
  $column_data{address} = qq|<th class=listheading>|.$locale->text('Address').qq|</th>|;
  $column_data{country} = qq|<th><a class=listheading href=$href&sort=country>|.$locale->text('Country').qq|</th>|;
  $column_data{taxnumber} = qq|<th class=listheading>|.$locale->text('Taxnumber').qq|</th>|;

  $column_data{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</th>|;


  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$title</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  for (@column_index) { print "$column_data{$_}\n" }

  $colspan = $#column_index + 1;

  print qq|
        </tr>
|;

  # add sort and escape callback
  $form->{callback} = "${callback}&sort=$form->{sort}";
  $callback = $form->escape($callback);

  if (@{ $form->{TR} }) {
    $amount{subtotal}{label} = $sameitem = $form->{TR}->[0]->{$form->{sort}};
  }

  foreach $ref (@{ $form->{TR} }) {

    $module = ($ref->{invoice}) ? $invoice : $arap;
    $module = 'ps.pl' if $ref->{till};

    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
        &subtotal('subtotal');
        $amount{subtotal}{label} = $sameitem = $ref->{$form->{sort}};
      }
    }

    # tax heading
    if ($ref->{accno} ne $sameaccno) {
      if ($acctotal) {
        &subtotal('acctotal');
      }
      print qq|
        <tr>
          <th align=left colspan=$colspan>
            $ref->{accno}--$form->{"$ref->{accno}_description"}
          </th>
        </tr>
|;
      $acctotal= 1;
    }
    $amount{acctotal}{label} = $sameaccno = $ref->{accno};

    for (qw(total subtotal acctotal)) {
      $amount{$_}{netamount} += $ref->{netamount};
      $amount{$_}{tax} += $ref->{tax};
      $amount{$_}{total} += $ref->{total};
    }

    for (qw(netamount tax total)) { $ref->{$_} = $form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}, "&nbsp;"); }

    $column_data{id} = qq|<td>$ref->{id}</td>|;
    $column_data{invnumber} = qq|<td><a href=$module?path=$form->{path}&action=edit&id=$ref->{id}&login=$form->{login}&callback=$callback>$ref->{invnumber}</a></td>|;

    $column_data{transdate} = qq|<td nowrap>$ref->{transdate}</td>|;
    for (qw(id partnumber description taxnumber address country)) { $column_data{$_} = qq|<td>$ref->{$_}</td>| }

    $column_data{"$form->{vc}number"} = qq|<td>$ref->{"$form->{vc}number"}</td>|;
    $column_data{name} = qq|<td><a href=ct.pl?path=$form->{path}&login=$form->{login}&action=edit&id=$ref->{vc_id}&db=$form->{vc}&callback=$callback>$ref->{name}</a></td>|;

    for (qw(netamount tax total)) { $column_data{$_} = qq|<td align=right>$ref->{$_}</td>| }

    $i++; $i %= 2;
    if ($form->{summary} != 2) {
      print qq|
        <tr class=listrow$i>
|;

      for (@column_index) { print "$column_data{$_}\n" }

      print qq|
        </tr>
|;
    }

  }

  if ($form->{l_subtotal} eq 'Y') {
    &subtotal('subtotal');
  }

  &subtotal('acctotal');

  for (@column_index) { $column_data{$_} = qq|<th>&nbsp;</th>| }

  print qq|
        </tr>
        <tr class=listtotal>
|;

  $amount{total}{netamount} = $form->format_amount(\%myconfig, $amount{total}{netamount}, $form->{precision}, "&nbsp;");
  $amount{total}{tax} = $form->format_amount(\%myconfig, $amount{total}{tax}, $form->{precision}, "&nbsp;");
  $amount{total}{total} = $form->format_amount(\%myconfig, $amount{total}{total}, $form->{precision}, "&nbsp;");

  $column_data{netamount} = qq|<th class=listtotal align=right>$amount{total}{netamount}</th>|;
  $column_data{tax} = qq|<th class=listtotal align=right>$amount{total}{tax}</th>|;
  $column_data{total} = qq|<th class=listtotal align=right>$amount{total}{total}</th>|;

  for (@column_index) { print "$column_data{$_}\n" }


  print qq|
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<form method=post action=$form->{script}>
|;

  $form->hide_form(map { "l_$_" } qw(id invnumber transdate description name netamount tax subtotal));

  for (keys %temp) { $form->{$_} = $temp{$_} }
  $form->hide_form(qw(taxaccounts gifi_taxaccounts department fromdate todate month year interval summary method vc callback path login));
  $form->hide_form(map { "accno_$_" } split / /, $form->{taxaccounts});
  $form->hide_form(map { "gifi_$_" } split / /, $form->{gifi_taxaccounts});
  $form->hide_form(qw(report reportcode reportlogin));

  $button{'Save Report'} = { ndx => 8, key => 'S', value => $locale->text('Save Report') };

  if (!$form->{admin}) {
    delete $button{'Save Report'} unless $form->{savereport};
  }

  $form->print_button(\%button);

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
</form>

</body>
</html>
|;

}


sub subtotal {

  $_ = shift;

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  if ($amount{$_}{label}) {
    $column_data{$column_index[0]} = qq|<td>$amount{$_}{label}</td>|;
  }

  $amount{$_}{netamount} = $form->format_amount(\%myconfig, $amount{$_}{netamount}, $form->{precision}, "&nbsp;");
  $amount{$_}{tax} = $form->format_amount(\%myconfig, $amount{$_}{tax}, $form->{precision}, "&nbsp;");
  $amount{$_}{total} = $form->format_amount(\%myconfig, $amount{$_}{total}, $form->{precision}, "&nbsp;");

  $column_data{netamount} = "<th class=listsubtotal align=right>$amount{$_}{netamount}</th>";
  $column_data{tax} = "<th class=listsubtotal align=right>$amount{$_}{tax}</th>";
  $column_data{total} = "<th class=listsubtotal align=right>$amount{$_}{total}</th>";

  $amount{$_}{netamount} = 0;
  $amount{$_}{tax} = 0;
  $amount{$_}{total} = 0;

  print qq|
        <tr class=listsubtotal>
|;
  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;

}



sub list_payments {

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};

  for (qw(fromdate todate)) { $temp{$_} = $form->{$_} };


  if ($form->{account}) {
    ($form->{paymentaccounts}) = split /--/, $form->{account};
  }
  if ($form->{department}) {
    ($department, $form->{department_id}) = split /--/, $form->{department};
    $option = $locale->text('Department')." : $department";
  }

  RP->payments(\%myconfig, \%$form);

  @columns = (qw(transdate reference description name));
  @columns = $form->sort_columns(@columns);
  push @columns, "$form->{vc}number";
  push @columns, (qw(paid source memo));

  if ($form->{till}) {
    @columns = (qw(transdate reference name));
    @columns = $form->sort_columns(@columns);
    push @columns, "$form->{vc}number";
    push @columns, (qw(description paid curr source till));

    if ($form->{admin}) {
      push @columns, "employee";
    }
  }

  # construct href
  $form->{paymentaccounts} =~ s/ /%20/g;

  $href = "$form->{script}?action=list_payments";
  @a = (qw(path direction sort oldsort till login fromdate todate fx_transaction db l_subtotal prepayment paymentaccounts vc db reportcode reportlogin));
  for (@a) { $href .= "&$_=$form->{$_}" }
  for (qw(title report helpref)) { $href .= "&$_=".$form->escape($form->{$_}) }

  $form->sort_order();

  $callback = "$form->{script}?action=list_payments";
  for (@a) { $callback .= "&$_=$form->{$_}" }
  for (qw(title report helpref)) { $callback .= "&$_=".$form->escape($form->{$_},1) }

  if ($form->{account}) {
    $callback .= "&account=".$form->escape($form->{account},1);
    $href .= "&account=".$form->escape($form->{account});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Account')." : $form->{account}";
  }
  if ($form->{department}) {
    $callback .= "&department=".$form->escape($form->{department},1);
    $href .= "&department=".$form->escape($form->{department});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Department')." : $form->{department}";
  }

  %vc = ( customer => { name => 'Customer', 'number' => 'Customer Number' },
          vendor => { name => 'Vendor', 'number' => 'Vendor Number' }
        );

  if ($form->{$form->{vc}}) {
    $callback .= "&$form->{vc}=".$form->escape($form->{$form->{vc}},1);
    $href .= "&$form->{vc}=".$form->escape($form->{$form->{vc}});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text($vc{$form->{vc}}{name})." : $form->{$form->{vc}}";
  }
  if ($form->{"$form->{vc}number"}) {
    $callback .= qq|&$form->{vc}number=|.$form->escape($form->{"$form->{vc}number"},1);
    $href .= qq|&$form->{vc}number=|.$form->escape($form->{"$form->{vc}number"});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text($vc{$form->{vc}}{number}).qq| : $form->{"$form->{vc}number"}|;
  }
  if ($form->{reference}) {
    $callback .= "&reference=".$form->escape($form->{reference},1);
    $href .= "&reference=".$form->escape($form->{reference});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Reference')." : $form->{reference}";
  }
  if ($form->{description}) {
    $callback .= "&description=".$form->escape($form->{description},1);
    $href .= "&description=".$form->escape($form->{description});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Description')." : $form->{description}";
  }
  if ($form->{source}) {
    $callback .= "&source=".$form->escape($form->{source},1);
    $href .= "&source=".$form->escape($form->{source});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Source')." : $form->{source}";
  }
  if ($form->{memo}) {
    $callback .= "&memo=".$form->escape($form->{memo},1);
    $href .= "&memo=".$form->escape($form->{memo});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Memo')." : $form->{memo}";
  }
  if ($form->{fromdate}) {
    $callback .= "&fromdate=$form->{fromdate}";
    $href .= "&fromdate=$form->{fromdate}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{fromdate}, 1);
  }
  if ($form->{todate}) {
    $callback .= "&todate=$form->{todate}";
    $href .= "&todate=$form->{todate}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{todate}, 1);
  }

  @column_index = ();
  for (@columns) {
    if ($form->{"l_$_"} eq 'Y') {
      push @column_index, $_;
      $callback .= "&l_$_=Y";
      $href .= "&l_$_=Y";
    }
  }
  $colspan = $#column_index + 1;

  $form->{callback} = $callback;
  $callback = $form->escape($form->{callback});

  $column_data{name} = "<th><a class=listheading href=$href&sort=name>".$locale->text($vc{$form->{vc}}{name})."</a></th>";
  $column_data{"$form->{vc}number"} = "<th><a class=listheading href=$href&sort=$form->{vc}number>".$locale->text($vc{$form->{vc}}{number})."</a></th>";
  $column_data{reference} = "<th><a class=listheading href=$href&sort=reference>".$locale->text('Reference')."</a></th>";
  $column_data{description} = "<th><a class=listheading href=$href&sort=description>".$locale->text('Description')."</a></th>";
  $column_data{transdate} = "<th nowrap><a class=listheading href=$href&sort=transdate>".$locale->text('Date')."</a></th>";
  $column_data{paid} = "<th class=listheading>".$locale->text('Amount')."</a></th>";
  $column_data{curr} = "<th class=listheading>".$locale->text('Curr')."</a></th>";
  $column_data{source} = "<th><a class=listheading href=$href&sort=source>".$locale->text('Source')."</a></th>";
  $column_data{memo} = "<th><a class=listheading href=$href&sort=memo>".$locale->text('Memo')."</a></th>";

  $employee = ($form->{db} eq 'ar') ? $locale->text('Salesperson') : $locale->text('Employee');
  $column_data{employee} = "<th><a class=listheading href=$href&sort=employee>$employee</a></th>";
  $column_data{till} = "<th><a class=listheading href=$href&sort=till>".$locale->text('Till')."</a></th>";

  $title = "$form->{title} / $form->{company}";

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$title</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;

  $isir = ($form->{db} eq 'ar') ? 'is' : 'ir';

  foreach $ref (sort { $a->{accno} cmp $b->{accno} } @{ $form->{PR} }) {

    next unless @{ $form->{$ref->{id}} };

    print qq|
        <tr>
          <th colspan=$colspan align=left>$ref->{accno}--$ref->{description}</th>
        </tr>
|;

    if (@{ $form->{$ref->{id}} }) {
      $sameitem = $form->{$ref->{id}}[0]->{$form->{sort}};
    }

    foreach $payment (@{ $form->{$ref->{id}} }) {

      if ($form->{l_subtotal}) {
        if ($payment->{$form->{sort}} ne $sameitem) {
          # print subtotal
          &payment_subtotal;
        }
      }

      next if ($form->{till} && ! $payment->{till});

      $href = ($payment->{vcid}) ? "<a href=ct.pl?action=edit&id=$payment->{vcid}&db=$form->{vc}&login=$form->{login}&path=$form->{path}&callback=$callback>" : "";

      $column_data{name} = "<td>$href$payment->{name}</a>&nbsp;</td>";
      $column_data{"$form->{vc}number"} = qq|<td>$payment->{"$form->{vc}number"}&nbsp;</td>|;
      $column_data{description} = "<td>$payment->{description}&nbsp;</td>";
      $column_data{transdate} = "<td nowrap>$payment->{transdate}&nbsp;</td>";
      $column_data{paid} = "<td align=right>".$form->format_amount(\%myconfig, $payment->{paid}, $form->{precision}, "&nbsp;")."</td>";
      $column_data{curr} = "<td>$payment->{curr}</td>";

      if ($payment->{module} eq 'gl') {
        $module = $payment->{module};
      } else {
        if ($payment->{invoice}) {
          $module = ($payment->{till}) ? 'ps' : $isir;
        } else {
          $module = $form->{db};
        }
      }

      $href = "<a href=${module}.pl?action=edit&id=$payment->{trans_id}&login=$form->{login}&path=$form->{path}&callback=$callback>";

      $column_data{source} = "<td>$payment->{source}&nbsp;</td>";
      $column_data{reference} = "<td>$href$payment->{reference}&nbsp;</a></td>";

      $column_data{memo} = "<td>$payment->{memo}&nbsp;</td>";
      $column_data{employee} = "<td>$payment->{employee}&nbsp;</td>";
      $column_data{till} = "<td>$payment->{till}&nbsp;</td>";

      $subtotalpaid += $payment->{paid};
      $accounttotalpaid += $payment->{paid};
      $totalpaid += $payment->{paid};

      $i++; $i %= 2;
      print qq|
        <tr class=listrow$i>
|;

      for (@column_index) { print "\n$column_data{$_}" }

      print qq|
        </tr>
|;

      $sameitem = $payment->{$form->{sort}};

    }

    &payment_subtotal if $form->{l_subtotal};

    # print account totals
    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{paid} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $accounttotalpaid, $form->{precision}, "&nbsp;")."</th>";

    print qq|
        <tr class=listtotal>
|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

    $accounttotalpaid = 0;

  }


  # print total
  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{paid} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalpaid, $form->{precision}, "&nbsp;")."</th>";

  print qq|
        <tr class=listtotal>
|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>

      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<form method=post action=$form->{script}>
|;

################
#  &print_report_options;

  $form->hide_form(map { "l_$_" } qw(transdate reference name description paid source memo subtotal));
  $form->hide_form($form->{vc});
  $form->hide_form("$form->{vc}number");

  for (keys %temp) { $form->{$_} = $temp{$_} }
  $form->hide_form(qw(fx_transaction department fromdate todate month year interval account payment accounts vc db callback path login));
  $form->hide_form(qw(report reportcode reportlogin));

  $button{'Save Report'} = { ndx => 8, key => 'S', value => $locale->text('Save Report') };

  if (!$form->{admin}) {
    delete $button{'Save Report'} unless $form->{savereport};
  }

  $form->print_button(\%button);

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
</form>

</body>
</html>
|;

}


sub payment_subtotal {

  if ($subtotalpaid != 0) {
    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{paid} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalpaid, $form->{precision}, "&nbsp;")."</th>";

    print qq|
  <tr class=listsubtotal>
|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
  </tr>
|;
  }

  $subtotalpaid = 0;

}


sub print_report_options {

  $form->{format} ||= "pdf";
  $form->{media} ||= "screen";

  $media = qq|<select name=media>
            <option value=screen $form->{MD}{screen}>|.$locale->text('Screen').qq|
            <option value=file $form->{MD}{file}>|.$locale->text('File');

  $format = qq|<select name=format>
            <option value=csv $form->{DF}{csv}>CSV|;

  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;
  $media .= qq|</select>|;

  if ($latex) {
    $format .= qq|
            <option value=pdf $form->{DF}{pdf}>|.$locale->text('PDF').qq|
            <option value=ps $form->{DF}{ps}>|.$locale->text('Postscript');
  }
  $format .= qq|</select>|;

  print qq|
<form method=post action=$form->{script}>

<table>
  <tr>
    <td>$format</td>
    <td>$media</td>
|;

  print qq|
  </tr>
</table>

<p>
<input class=submit type=submit name=action value="|.$locale->text('Print Report').qq|">|;

  $form->{action} = "print_report";
  $form->{nextsub} = "";

  $form->hide_form;

  print qq|
</form>
|;

}


sub print_report {

  $form->debug;

}

=encoding utf8

=head1 NAME

bin/mozilla/rp.pl - Module for preparing Income Statement and Balance Sheet

=head1 DESCRIPTION

L<bin::mozilla::rp> contains the module for preparing income statement and balance sheet.

=head1 DEPENDENCIES

L<bin::mozilla::rp>

=over

=item * uses
L<SL::CP>,
L<SL::PE>,
L<SL::RP>

=item * requires
L<bin::mozilla::arap>,
L<bin::mozilla::menu>

=back

=head1 FUNCTIONS

L<bin::mozilla::rp> implements the following functions:

=head2 aging

=head2 build_report

=head2 continue

Calls C<< &{$form->{nextsub}} } >>.

=head2 deselect_all

Calls C<< &{ "deselect_all_$form->{type}" } >>.

=head2 deselect_all_reminder

=head2 deselect_all_statement

=head2 display_all

=head2 do_print_reminder

=head2 do_print_statement

=head2 e_mail

Calls C<< &{ "e_mail_$form->{type}" } >>.

=head2 e_mail_reminder

=head2 e_mail_statement

=head2 generate_ap_aging

=head2 generate_ar_aging

=head2 generate_balance_sheet

=head2 generate_income_statement

=head2 generate_projects

=head2 generate_reminder

=head2 generate_tax_report

=head2 generate_trial_balance

=head2 list_accounts

=head2 list_payments

=head2 payment_subtotal

=head2 prepare_e_mail

=head2 print

Calls C<< &{ "print_$form->{type}" } >>.

=head2 print_options

=head2 print_reminder

=head2 print_report

=head2 print_report_options

=head2 print_statement

=head2 reminder

=head2 report

=head2 save_level

=head2 section_display

=head2 section_subtotal

=head2 select_all

Calls C<< &{ "select_all_$form->{type}" } >>.

=head2 select_all_reminder

=head2 select_all_statement

=head2 send_email_reminder

=head2 send_email_statement

=head2 statement_details

  &statement_details($ref);

=head2 subtotal

=cut
