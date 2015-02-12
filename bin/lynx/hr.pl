#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# payroll module
#
#======================================================================

use SL::HR;
use SL::User;
use SL::AA;
use SL::GL;

require "$form->{path}/arap.pl";
require "$form->{path}/arapprn.pl";

1;
# end of main



sub add {

  $label = "Add ".ucfirst $form->{db};
  $form->{title} = $locale->text($label);

  $form->{callback} = "$form->{script}?action=add&db=$form->{db}&path=$form->{path}&login=$form->{login}" unless $form->{callback};

  &{ "prepare_$form->{db}" };

  &display_form;
  
}


sub search { &{ "search_$form->{db}" } };
  

sub search_employee {

  $form->{title} = $locale->text('Employees');

  $form->helpref("search_employee", $myconfig{countrycode});
  
  @f = ();

  push @f, qq|<input name="l_ndx" type=checkbox class=checkbox value=Y> |.$locale->text('Pos');
  push @f, qq|<input name="l_id" type=checkbox class=checkbox value=Y> |.$locale->text('ID');
  push @f, qq|<input name="l_name" type=checkbox class=checkbox value=Y checked> |.$locale->text('Employee Name');
  push @f, qq|<input name="l_employeenumber" type=checkbox class=checkbox value=Y checked> |.$locale->text('Employee Number');
  push @f, qq|<input name="l_address" type=checkbox class=checkbox value=Y> |.$locale->text('Address');
  push @f, qq|<input name="l_city" type=checkbox class=checkbox value=Y> |.$locale->text('City');
  push @f, qq|<input name="l_state" type=checkbox class=checkbox value=Y> |.$locale->text('State/Province');
  push @f, qq|<input name="l_zipcode" type=checkbox class=checkbox value=Y> |.$locale->text('Zip/Postal Code');
  push @f, qq|<input name="l_country" type=checkbox class=checkbox value=Y> |.$locale->text('Country');
  push @f, qq|<input name="l_workphone" type=checkbox class=checkbox value=Y checked> |.$locale->text('Work Phone');
  push @f, qq|<input name="l_workfax" type=checkbox class=checkbox value=Y checked> |.$locale->text('Work Fax');
  push @f, qq|<input name="l_workmobile" type=checkbox class=checkbox value=Y> |.$locale->text('Work Mobile');
  push @f, qq|<input name="l_homephone" type=checkbox class=checkbox value=Y checked> |.$locale->text('Home Phone');
  push @f, qq|<input name="l_homemobile" type=checkbox class=checkbox value=Y checked> |.$locale->text('Home Mobile');
  push @f, qq|<input name="l_startdate" type=checkbox class=checkbox value=Y checked> |.$locale->text('Startdate');
  push @f, qq|<input name="l_enddate" type=checkbox class=checkbox value=Y checked> |.$locale->text('Enddate');
  push @f, qq|<input name="l_acsrole" type=checkbox class=checkbox value=Y checked> |.$locale->text('Role');
  push @f, qq|<input name="l_sales" type=checkbox class=checkbox value=Y> |.$locale->text('Sales');
  push @f, qq|<input name="l_login" type=checkbox class=checkbox value=Y checked> |.$locale->text('Login');
  push @f, qq|<input name="l_email" type=checkbox class=checkbox value=Y> |.$locale->text('E-mail');
  push @f, qq|<input name="l_ssn" type=checkbox class=checkbox value=Y> |.$locale->text('SSN');
  push @f, qq|<input name="l_dob" type=checkbox class=checkbox value=Y> |.$locale->text('DOB');
  push @f, qq|<input name="l_iban" type=checkbox class=checkbox value=Y> |.$locale->text('IBAN');
  push @f, qq|<input name="l_bic" type=checkbox class=checkbox value=Y> |.$locale->text('BIC');
  push @f, qq|<input name="l_notes" type=checkbox class=checkbox value=Y> |.$locale->text('Notes');
 

  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Employee Name').qq|</th>
	  <td colspan=3><input name=name size=35></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Employee Number').qq|</th>
	  <td colspan=3><input name=employeenumber size=35></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Startdate').qq|</th>
	  <td>|.$locale->text('From').qq| <input name=startdatefrom size=11 class=date title="$myconfig{dateformat}"> |.$locale->text('To').qq| <input name=startdateto size=11 class=date title="$myconfig{dateformat}"></td>
	</tr>
	<tr valign=top>
	  <th align=right nowrap>|.$locale->text('Notes').qq|</th>
	  <td colspan=3><input name=notes size=40></td>
	</tr>
	<tr>
	  <td></td>
	  <td colspan=3><input name=status class=radio type=radio value=all checked>&nbsp;|.$locale->text('All').qq|
	  <input name=status class=radio type=radio value=active>&nbsp;|.$locale->text('Active').qq|
	  <input name=status class=radio type=radio value=inactive>&nbsp;|.$locale->text('Inactive').qq|
	  <input name=status class=radio type=radio value=orphaned>&nbsp;|.$locale->text('Orphaned').qq|
	  <input name=status class=radio type=radio value=sales>&nbsp;|.$locale->text('Sales').qq|
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td colspan=3>
	    <table>
|;

  while (@f) {
    print qq|<tr>\n|;
    for (1 .. 5) {
      print qq|<td nowrap>|. shift @f;
      print qq|</td>\n|;
    }
    print qq|</tr>\n|;
  }

  print qq|
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->{nextsub} = "list_employees";
  
  $form->hide_form(qw(nextsub db path login));

  print qq|
<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
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


sub list_employees {

  HR->employees(\%myconfig, \%$form);
  
  $href = "$form->{script}?action=list_employees";
  for (qw(direction oldsort db path login status)) { $href .= "&$_=$form->{$_}" }
  
  $form->sort_order();

  $callback = "$form->{script}?action=list_employees";
  for (qw(direction oldsort db path login status)) { $callback .= "&$_=$form->{$_}" }
  
  @columns = $form->sort_columns(qw(id employeenumber name address city state zipcode country workphone workfax workmobile homephone homemobile email startdate enddate ssn dob iban bic sales acsrole login notes));
  unshift @columns, "ndx";

  for (@columns) {
    if ($form->{"l_$_"} eq "Y") {
      push @column_index, $_;

      # add column to href and callback
      $callback .= "&l_$_=Y";
      $href .= "&l_$_=Y";
    }
  }

  @columns = ();
  for (@column_index) {
    if ($_ eq 'address') {
      push @columns, ('address1', 'address2');
    } else {
      push @columns, $_;
    }
  }
  @column_index = @columns;

  $option = $locale->text('All');

  if ($form->{status} eq 'sales') {
    $option = $locale->text('Sales');
  }
  if ($form->{status} eq 'orphaned') {
    $option = $locale->text('Orphaned');
  }
  if ($form->{status} eq 'active') {
    $option = $locale->text('Active');
  }
  if ($form->{status} eq 'inactive') {
    $option = $locale->text('Inactive');
  }
  
  if ($form->{employeenumber}) {
    $callback .= "&employeenumber=".$form->escape($form->{employeenumber},1);
    $href .= "&employeenumber=".$form->escape($form->{employeenumber});
    $option .= "\n<br>".$locale->text('Employee Number')." : $form->{employeenumber}";
  }
  if ($form->{name}) {
    $callback .= "&name=".$form->escape($form->{name},1);
    $href .= "&name=".$form->escape($form->{name});
    $option .= "\n<br>".$locale->text('Employee Name')." : $form->{name}";
  }
  if ($form->{startdatefrom}) {
    $callback .= "&startdatefrom=$form->{startdatefrom}";
    $href .= "&startdatefrom=$form->{startdatefrom}";
    $fromdate = $locale->date(\%myconfig, $form->{startdatefrom}, 1);
  }
  if ($form->{startdateto}) {
    $callback .= "&startdateto=$form->{startdateto}";
    $href .= "&startdateto=$form->{startdateto}";
    $todate = $locale->date(\%myconfig, $form->{startdateto}, 1);
  }
  if ($fromdate || $todate) {
    $option .= "\n<br>".$locale->text('Startdate')." $fromdate - $todate";
  }
  
  if ($form->{notes}) {
    $callback .= "&notes=".$form->escape($form->{notes},1);
    $href .= "&notes=".$form->escape($form->{notes});
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Notes')." : $form->{notes}";
  }

  $form->helpref("list_employees", $myconfig{countrycode});

  $href .= "&helpref=".$form->escape($form->{helpref});
  $callback .= "&helpref=".$form->escape($form->{helpref},1);
  
  $form->{callback} = "$callback&sort=$form->{sort}";
  $callback = $form->escape($form->{callback});

  $column_header{ndx} = qq|<th class=listheading width=1%>&nbsp;</th>|;
  $column_header{id} = qq|<th class=listheading>|.$locale->text('ID').qq|</th>|;
  $column_header{employeenumber} = qq|<th><a class=listheading href=$href&sort=employeenumber>|.$locale->text('Number').qq|</a></th>|;
  $column_header{name} = qq|<th><a class=listheading href=$href&sort=name>|.$locale->text('Name').qq|</a></th>|;
  $column_header{address1} = qq|<th class=listheading>|.$locale->text('Address').qq|</a></th>|;
  $column_header{address2} = qq|<th class=listheading>&nbsp;</th>|;
  $column_header{city} = qq|<th><a class=listheading href=$href&sort=city>|.$locale->text('City').qq|</a></th>|;
  $column_header{state} = qq|<th><a class=listheading href=$href&sort=state>|.$locale->text('State/Province').qq|</a></th>|;
  $column_header{zipcode} = qq|<th><a class=listheading href=$href&sort=zipcode>|.$locale->text('Zip/Postal Code').qq|</a></th>|;
  $column_header{country} = qq|<th><a class=listheading href=$href&sort=country>|.$locale->text('Country').qq|</a></th>|;
  $column_header{workphone} = qq|<th><a class=listheading href=$href&sort=workphone>|.$locale->text('Work Phone').qq|</a></th>|;
  $column_header{workfax} = qq|<th><a class=listheading href=$href&sort=workfax>|.$locale->text('Work Fax').qq|</a></th>|;
  $column_header{workmobile} = qq|<th><a class=listheading href=$href&sort=workmobile>|.$locale->text('Work Mobile').qq|</a></th>|;
  $column_header{homephone} = qq|<th><a class=listheading href=$href&sort=homephone>|.$locale->text('Home Phone').qq|</a></th>|;
  $column_header{homemobile} = qq|<th><a class=listheading href=$href&sort=homemobile>|.$locale->text('Home Mobile').qq|</a></th>|;
  
  $column_header{startdate} = qq|<th><a class=listheading href=$href&sort=startdate>|.$locale->text('Startdate').qq|</a></th>|;
  $column_header{enddate} = qq|<th><a class=listheading href=$href&sort=enddate>|.$locale->text('Enddate').qq|</a></th>|;
  $column_header{notes} = qq|<th><a class=listheading href=$href&sort=notes>|.$locale->text('Notes').qq|</a></th>|;
  $column_header{acsrole} = qq|<th><a class=listheading href=$href&sort=acsrole>|.$locale->text('Role').qq|</a></th>|;
  $column_header{login} = qq|<th><a class=listheading href=$href&sort=login>|.$locale->text('Login').qq|</a></th>|;
  
  $column_header{sales} = qq|<th class=listheading>|.$locale->text('S').qq|</th>|;
  $column_header{email} = qq|<th><a class=listheading href=$href&sort=email>|.$locale->text('E-mail').qq|</a></th>|;
  $column_header{ssn} = qq|<th><a class=listheading href=$href&sort=ssn>|.$locale->text('SSN').qq|</a></th>|;
  $column_header{dob} = qq|<th><a class=listheading href=$href&sort=dob>|.$locale->text('DOB').qq|</a></th>|;
  $column_header{iban} = qq|<th><a class=listheading href=$href&sort=iban>|.$locale->text('IBAN').qq|</a></th>|;
  $column_header{bic} = qq|<th><a class=listheading href=$href&sort=bic>|.$locale->text('BIC').qq|</a></th>|;
  
  $form->{title} = $locale->text('Employees') . " / $form->{company}";

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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

  for (@column_index) { print "$column_header{$_}\n" }
  
  print qq|
        </tr>
|;

  $i = 0;
  foreach $ref (@{ $form->{all_employee} }) {

    $i++;
    
    $ref->{notes} =~ s/\r?\n/<br>/g;
    for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

    $column_data{ndx} = "<td align=right>$i</td>";

    $column_data{sales} = ($ref->{sales}) ? "<td>x</td>" : "<td>&nbsp;</td>";
    $column_data{acsrole} = qq|<td>$ref->{acsrole}&nbsp;</td>|;

    $column_data{name} = "<td><a href=$form->{script}?action=edit&db=employee&id=$ref->{id}&path=$form->{path}&login=$form->{login}&status=$form->{status}&callback=$callback>$ref->{name}&nbsp;</td>";

    if ($ref->{email}) {
      $email = $ref->{email};
      $email =~ s/</\&lt;/;
      $email =~ s/>/\&gt;/;
      
      $column_data{email} = qq|<td><a href="mailto:$ref->{email}">$email</a></td>|;
    }

    $j++; $j %= 2;
    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
        </tr>
|;
    
  }

  $i = 1;
  $button{'HR--Employees--Add Employee'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Employee').qq|"> |;
  $button{'HR--Employees--Add Employee'}{order} = $i++;

  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(callback db path login));
  
  foreach $item (sort { $a->{order} <=> $b->{order} } %button) {
    print $item->{code};
  }

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


sub edit {

# $locale->text('Edit Employee')
# $locale->text('Edit Deduction')
# $locale->text('Edit Payroll')

  $label = ucfirst $form->{db};
  $form->{title} = $locale->text("Edit $label");

  &{ "prepare_$form->{db}" };
  &display_form;
  
}


sub new_number {

  $form->{employeenumber} = $form->update_defaults(\%myconfig, employeenumber);

  &display_form;

}


sub prepare_employee {

  HR->get_employee(\%myconfig, \%$form);

  for (keys %$form) { $form->{$_} = $form->quote($form->{$_}) }
  
  for $key (qw(wage deduction acsrole paymentmethod)) {
    if (@{ $form->{"all_$key"} }) {
      if ($form->{login} eq "admin\@$myconfig{dbname}") {
        $form->{"select$key"} = "\n";
      } else {
        if ($form->{id}) {
          $form->{"select$key"} = ($key eq "acsrole") ? "" : "\n";
        } else {
          $form->{"select$key"} = "\n";
        }
      }

      for (@{ $form->{"all_$key"} }) { $form->{"select$key"} .= qq|$_->{description}--$_->{id}\n| }
      
      $form->{$key} = qq|$form->{$key}--$form->{"${key}_id"}|;
      
    }
  }

  for $key (qw(wage deduction)) { delete $form->{$key} }

  $form->{oldemployeelogin} = $form->{employeelogin};

  if ($form->{id}) {
    if ($form->{employeelogin}) {
      open FH, $memberfile;
      @member = <FH>;
      close FH;

      while (@member) {
	$_ = shift @member;
	next if ! /\[$form->{employeelogin}\@$myconfig{dbname}\]/;
	do {
          if (/^tan=/) {
            chomp;
            ($null, $form->{tan}) = split /=/, $_, 2;
          }
	  if (/^password=/) {
            chomp;
	    ($null, $form->{employeepassword}) = split /=/, $_, 2;
	  }
	  $_ = shift @member;
	} until /^\s/;
      }
    }
  }

  $i = 0;
  foreach $ref (@{ $form->{all_employeewage} }) {
    $i++;
    $form->{"wage_$i"} = "$ref->{description}--$ref->{id}" if $ref->{id};
  }
  $form->{wage_rows} = $i;
 
  $i = 0;
  foreach $ref (sort { $a->{edid} <=> $b->{edid} } @{ $form->{all_employeededuction} }) {
    $i++;
    $form->{"deduction_$i"} = "$ref->{description}--$ref->{id}" if $ref->{id};
    $form->{"exempt_$i"} = $ref->{exempt};
    $form->{"maximum_$i"} = $ref->{maximum};
    $form->{"withholding_$i"} = ($ref->{withholding}) ? 1 : 0;
  }
  $form->{deduction_rows} = $i;
  
  $i = 0;
  foreach $ref (@{ $form->{all_payrate} }) {
    $i++;
    for (qw(rate above)) { $form->{"${_}_$i"} = $ref->{$_} }
  }
  $form->{payrate_rows} = $i;

  $form->{payperiod} = "" unless $form->{payperiod} ;

  for $key (qw(ap expense payment)) {
    if (@{ $form->{"${key}_accounts"} }) {
      $form->{"select$key"} = "\n";
      for (@{ $form->{"${key}_accounts"} }) { $form->{"select$key"} .= qq|$_->{accno}--$_->{description}\n| }
    }
    $form->{$key} = qq|$form->{$key}--$form->{"${key}_description"}|;
  }

  $i = 0;
  for (@{ $form->{all_reference} }) {
    $i++;
    $form->{"referencedescription_$i"} = $_->{description};
    $form->{"referenceid_$i"} = $_->{id};
  }
  $form->{reference_rows} = $i;

  for (qw(paymentmethod payment ap wage deduction acsrole)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }

  if (! $form->{readonly}) {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Add Employee/;
  }

  $form->helpref("employee", $myconfig{countrycode});

}


sub employee_header {

  $reference_documents = &reference_documents;

  $form->{deduction_rows}++;
  $form->{payrate_rows}++;
  $form->{wage_rows}++;

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(acs payrate_rows wage_rows deduction_rows reference_rows referenceurl status title helpref oldemployeelogin company));
  $form->hide_form(map { "select$_" } qw(paymentmethod payment ap wage deduction acsrole));
  
  $login = "";

  if ($form->{admin}) {
    $sales = ($form->{sales}) ? "checked" : "";
    $tan = ($form->{tan}) ? "checked" : "";
    
    if ($form->{selectacsrole}) {
      $login = qq|
	      <tr>
		<th align=right>|.$locale->text('Role').qq|</th>
		<td><select name=acsrole>|
		.$form->select_option($form->{selectacsrole}, $form->{acsrole}, 1)
		.qq|</select></td>
	      </tr>
|;
    }
    
    $login .= qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Login').qq|</th>
		<td><input name=employeelogin size=20 value="$form->{employeelogin}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Password').qq|</th>
		<td><input name=employeepassword size=20 value="$form->{employeepassword}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('E-mail TAN').qq|</th>
		<td><input name=tan class=checkbox type=checkbox value=1 $tan></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Sales').qq|</th>
		<td><input name=sales class=checkbox type=checkbox value=1 $sales></td>
	      </tr>
|;
  } else {
    ($acsrole) = split /--/, $form->{acsrole};
    if ($form->{selectacsrole}) {
      $login = qq|
	      <tr>
		<th align=right>|.$locale->text('Role').qq|</th>
		<td>$acsrole</td>
	      </tr>
|;
    }

    if ($form->{employeelogin}) {
      $login .= qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Login').qq|</th>
		<td>$form->{employeelogin}</td>
	      </tr>
|;
    }
    if ($form->{tan}) {
      $login .= qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Use TAN').qq|</th>
		<td>x</td>
	      </tr>
|;
    }
    if ($form->{sales}) {
      $login .= qq|
	      <tr>
		<th align=right>|.$locale->text('Sales').qq|</th>
		<td>x</td>
	      </tr>
|;
    }

    $form->hide_form(qw(acsrole employeelogin sales tan employeepassword));
  }

  print qq|

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Employee Number').qq|</th>
		<td><input name=employeenumber size=32 maxlength=32 value="|.$form->quote($form->{employeenumber}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Name').qq| <font color=red>*</font></th>
		<td><input name=name size=35 maxlength=64 value="|.$form->quote($form->{name}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Address').qq|</th>
		<td><input name=address1 size=35 maxlength=32 value="|.$form->quote($form->{address1}).qq|"></td>
	      </tr>
	      <tr>
		<th></th>
		<td><input name=address2 size=35 maxlength=32 value="|.$form->quote($form->{address2}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('City').qq|</th>
		<td><input name=city size=35 maxlength=32 value="|.$form->quote($form->{city}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('State/Province').qq|</th>
		<td><input name=state size=35 maxlength=32 value="|.$form->quote($form->{state}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Zip/Postal Code').qq|</th>
		<td><input name=zipcode size=10 maxlength=10 value="|.$form->quote($form->{zipcode}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Country').qq|</th>
		<td><input name=country size=35 maxlength=32 value="|.$form->quote($form->{country}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('E-mail').qq|</th>
		<td><input name=email size=35 value="$form->{email}"></td>
	      </tr>
	      $login
	    </table>
	  </td>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Work Phone').qq|</th>
		<td><input name=workphone size=20 maxlength=20 value="$form->{workphone}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Work Fax').qq|</th>
		<td><input name=workfax size=20 maxlength=20 value="$form->{workfax}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Work Mobile').qq|</th>
		<td><input name=workmobile size=20 maxlength=20 value="$form->{workmobile}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Home Phone').qq|</th>
		<td><input name=homephone size=20 maxlength=20 value="$form->{homephone}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Home Mobile').qq|</th>
		<td><input name=homemobile size=20 maxlength=20 value="$form->{homemobile}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Startdate').qq|</th>
		<td><input name=startdate size=11 class=date title="$myconfig{dateformat}" value=$form->{startdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Enddate').qq|</th>
		<td><input name=enddate size=11 class=date title="$myconfig{dateformat}" value=$form->{enddate}></td>
	      </tr>

	      <tr>
		<th align=right nowrap>|.$locale->text('SSN').qq|</th>
		<td><input name=ssn size=20 maxlength=20 value="|.$form->quote($form->{ssn}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('DOB').qq|</th>
		<td><input name=dob size=11 class=date title="$myconfig{dateformat}" value=$form->{dob}></td>
	      </tr>
	      <tr valign=top>
                <th align=right nowrap>|.$locale->text('Notes').qq|</th>
                <td><textarea name=notes rows=3 cols=32>$form->{notes}</textarea></td>
	      </tr>
	    </table>
	  </td>
	</tr>
	<tr valign=top>
	  <td>
	    <table>
	      <tr>
	        <th align=right nowrap>|.$locale->text('Bank').qq|</th>
		<td><input name=bankname size=32 maxlength=64 value="|.$form->quote($form->{bankname}).qq|"></td>
	      </tr>
	      <tr>
	        <th align=right nowrap>|.$locale->text('Address').qq|</th>
		<td><input name=bankaddress1 size=32 maxlength=32 value="|.$form->quote($form->{bankaddress1}).qq|"></td>
	      </tr>
	      <tr>
	        <th></th>
	        <td><input name=bankaddress2 size=32 maxlength=32 value="|.$form->quote($form->{bankaddress2}).qq|"></td>
	      </tr>
	      <tr>
	        <th align=right nowrap>|.$locale->text('City').qq|</th>
		<td><input name=bankcity size=32 maxlength=32 value="|.$form->quote($form->{bankcity}).qq|"></td>
	      </tr>
	      <tr>
	        <th align=right nowrap>|.$locale->text('State/Province').qq|</th>
		<td><input name=bankstate size=32 maxlength=32 value="|.$form->quote($form->{bankstate}).qq|"></td>
	      </tr>
	      <tr>
	        <th align=right nowrap>|.$locale->text('Zip/Postal Code').qq|</th>
		<td><input name=bankzipcode size=11 maxlength=10 value="|.$form->quote($form->{bankzipcode}).qq|"></td>
	      </tr>
	      <tr>
	        <th align=right nowrap>|.$locale->text('Country').qq|</th>
		<td><input name=bankcountry size=32 maxlength=32 value="|.$form->quote($form->{bankcountry}).qq|"></td>
	      </tr>
	    </table>
	  </td>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('IBAN').qq|</th>
		<td><input name=iban size=34 maxlength=34 value="|.$form->quote($form->{iban}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('BIC').qq|</th>
		<td><input name=bic size=11 maxlength=11 value="|.$form->quote($form->{bic}).qq|"></td>
	      </tr>
	      <tr>
	        <th align=right nowrap>|.$locale->text('Member No.').qq|</th>
		<td><input name=membernumber size=20 value="$form->{membernumber}"></td>
	      </tr>
	      <tr>
	        <th align=right nowrap>|.$locale->text('Clearing No.').qq|</th>
		<td><input name=clearingnumber size=20 value="$form->{clearingnumber}"></td>
	      </tr>
	    </table>
	  </td>
	</tr>
	$reference_documents
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        <tr valign=top>
|;
    if ($form->{selectwage}) {

      print qq|
	  <td>
	    <table>
	      <tr class=listheading>
		<th class=listheading>|.$locale->text('Wages').qq|</th>
	      </tr>
|;

    for $i (1 .. $form->{wage_rows}) {

      print qq|
	      <tr>
		<td><select name="wage_$i">|
		.$form->select_option($form->{selectwage}, $form->{"wage_$i"}, 1)
		.qq|</select></td>
	      </tr>
|;
    }
  print qq|
	    </table>
	  </td>
|;
  }
  
    if ($form->{selectdeduction}) {

      print qq|
	  <td>
	    <table>
	      <tr class=listheading>
		<th class=listheading>|.$locale->text('Payroll Deduction').qq|</th>
		<th class=listheading>|.$locale->text('Exempt').qq|</th>
		<th class=listheading>|.$locale->text('Maximum').qq|</th>
	      </tr>
|;

    for $i (1 .. $form->{deduction_rows}) {

      print qq|
	      <tr>
		<td><select name="deduction_$i">|
		.$form->select_option($form->{selectdeduction}, $form->{"deduction_$i"}, 1)
		.qq|</select></td>
		<td><input name="exempt_$i" class="inputright" value=|.$form->format_amount(\%myconfig, $form->{"exempt_$i"}, $form->{precision}).qq|></td>
		<td><input name="maximum_$i" class="inputright" value=|.$form->format_amount(\%myconfig, $form->{"maximum_$i"}, $form->{precision}).qq|></td>
	      </tr>
|;
    }
  print qq|
	    </table>
	  </td>
	</tr>
|;
  }

  if ($form->{selectpaymentmethod}) {
    $paymentmethod = qq|
	      <tr>
	        <th align=right>|.$locale->text('Method').qq|</th>
		<td><select name="paymentmethod">|
		.$form->select_option($form->{selectpaymentmethod}, $form->{paymentmethod}, 1)
		.qq|</select></td>
	      </tr>
|;
  }

  print qq|
        </tr>
	<tr valign=top>
	  <td>
	    <table>
	      <tr>
	        <th align=right>|.$locale->text('AP').qq|</th>
		<td><select name="ap">|
		.$form->select_option($form->{selectap}, $form->{ap})
		.qq|</select></td>
	      </tr>
	      <tr>
	        <th align=right>|.$locale->text('Payment').qq|</th>
		<td><select name="payment">|
		.$form->select_option($form->{selectpayment}, $form->{payment})
		.qq|</select></td>
	      </tr>
	      $paymentmethod
	      <tr>
		<th align=right nowrap>|.$locale->text('Pay Periods').qq|</th>
		<td><input name=payperiod class="inputright" size=3 value=$form->{payperiod}></td>
	      </tr>
	    </table>
	  </td>

	  <td>
	    <table>
	      <tr>
		<th class=listheading>|.$locale->text('Pay Rates').qq|</th>
		<th class=listheading>|.$locale->text('Over').qq|</th>
	      </tr>
|;
   
  for $i (1 .. $form->{payrate_rows}) {
    print qq|
	      <tr>
		<td><input name="rate_$i" size=10 class="inputright" value=|.$form->format_amount(\%myconfig, $form->{"rate_$i"}, $form->{precision}).qq|></td>
		<td><input name="above_$i" size=10 class="inputright" value=|.$form->format_amount(\%myconfig, $form->{"above_$i"}).qq|></td>
	      </tr>
|;
  }

  print qq|
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub employee_footer {

  $form->hide_form(qw(precision id db addressid path login callback));

  if ($form->{readonly}) {

    &islocked;

  } else {

    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
	       'Save' => { ndx => 2, key => 'S', value => $locale->text('Save') },
	       'Save as new' => { ndx => 5, key => 'N', value => $locale->text('Save as new') },
	       'Access Control' => { ndx => 6, key => 'A', value => $locale->text('Access Control') },
	       'New Number' => { ndx => 15, key => 'M', value => $locale->text('New Number') },
	       'Delete' => { ndx => 16, key => 'D', value => $locale->text('Delete') },
	      );
	     
    %f = ();
    for ("Update", "Save", "New Number") { $f{$_} = 1 }
    
    if ($form->{id}) {
      if ($form->{status} eq 'orphaned') {
	$f{'Delete'} = 1;
      }
      $f{'Save as new'} = 1;
    }
    $f{'Access Control'} = 1 if $form->{admin};

    for (keys %button) { delete $button{$_} if ! $f{$_} }
    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
   
  }

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


sub access_control {

  $menufile = "menu.ini";

  $form->helpref("access_control", $myconfig{countrycode});
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{name}</a></th>
  </tr>
  <tr height="5"></tr>
|;

  # access control
  open(FH, $menufile) or $form->error("$menufile : $!");
  # scan for first menu level
  @f = <FH>;
  close(FH);

  if (open(FH, "custom_$menufile")) {
    push @f, <FH>;
  }
  close(FH);

  foreach $item (@f) {
    next unless $item =~ /\[\w+/;
    next if $item =~ /\#/;

    $item =~ s/(\[|\])//g;
    chop $item;

    if ($item =~ /--/) {
      ($level, $menuitem) = split /--/, $item, 2;
    } else {
      $level = $item;
      $menuitem = $item;
      push @acsorder, $item;
    }

    push @{ $acs{$level} }, $menuitem;

  }

  foreach $item (split /;/, $form->{acs}) {
    ($key, $value) = split /--/, $item, 2;
    $excl{$key}{$value} = 1;
  }

  foreach $key (@acsorder) {
    
    $checked = ($excl{$key}{$key}) ? "" : "checked";

    # can't have variable names with & and spaces
    $item = $form->escape("${key}--$key",1);
    
    $acsheading = $key;
    $acsheading =~ s/ /&nbsp;/g;
    
    $acsheading = qq|
    <th align=left nowrap><input name="$item" class=checkbox type=checkbox value=1 $checked>&nbsp;$acsheading</th>\n|;
    $menuitems .= "$item;";
    
    $acsdata = qq|
    <td>|;
    
    foreach $item (@{ $acs{$key} }) {
      next if ($key eq $item);
      
      $checked = ($excl{$key}{$item}) ? "" : "checked";
      
      $acsitem = $form->escape("${key}--$item",1);
      
      $acsdata .= qq|
      <br><input name="$acsitem" class=checkbox type=checkbox value=1 $checked>&nbsp;$item|;
      $menuitems .= "$acsitem;";
    }
    $acsdata .= qq|
    </td>|;
    
    print qq|
    <tr valign=top>$acsheading $acsdata
    </tr>
|;
  }
  
  $form->{access} = "$menuitems";
  
  print qq|
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

  delete $form->{action};
  
  $form->{nextsub} = "save_acs";

  $form->hide_form;
  
  %button = ('Continue' => { ndx => 1, key => 'C', value => $locale->text('Continue') }
	      );
	     
  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
   
  print qq|
 
  </form>

</body>
</html>
|;

}


sub save_acs {

  $form->{acs} = "";
  for (split /;/, $form->{access}) {
    $item = $form->escape($_,1);

    if (!$form->{$item}) {
      $item = $form->unescape($_);
      $form->{acs} .= "${item};";
    }
  }

  &display_form;

}


sub display_form {
  
  &{ "$form->{db}_header" };
  &{ "$form->{db}_footer" };

}


sub save { &{ "save_$form->{db}" } };


sub save_employee {

  $form->isblank("name", $locale->text("Name missing!"));
  $form->error("$memberfile : ".$locale->text('locked!')) if (-f ${memberfile}.LCK);
  
  if (HR->save_employee(\%myconfig, \%$form)) {
    &save_memberfile;
  }
  
  $form->redirect($locale->text('Employee saved!'));
  
}


sub save_memberfile {
  
  # change memberfile
  open(FH, ">${memberfile}.LCK") or $form->error("${memberfile}.LCK : $!");
  close(FH);

  if (! open(FH, "+<$memberfile")) {
    unlink "${memberfile}.LCK";
    $form->error("$memberfile : $!");
  }
  
  $login = "";
  while (<FH>) {
    if (/^\[/) {
      s/(\[|\])//g;
      chomp;
      $login = $_;
      next;
    }
    
    if ($login) {
      push @{ $member{$login} }, $_;
    } else {
      push @member, $_;
    }
  }

  if ($form->{employeelogin}) {
    $employeelogin = "$form->{employeelogin}\@$myconfig{dbname}";
    
    # assign values from old entries
    $oldlogin = "$form->{oldemployeelogin}\@$myconfig{dbname}";

    srand( time() ^ ($$ + ($$ << 15)) );
    
    if (@{ $member{$oldlogin} }) {
      @memberlogin = grep !/^(name=|email=|password=|tan=)/, @{ $member{$oldlogin} };
      ($oldemployeepassword) = grep /^password=/, @{ $member{$oldlogin} };
      pop @memberlogin;

      $oldemployeepassword =~ s/password=//;
      chomp $oldemployeepassword;

      $form->{employeepassword} = $oldemployeepassword if $form->{nochange};

      if ($form->{employeepassword} ne $oldemployeepassword) {
	if ($form->{employeepassword}) {
	  $password = crypt $form->{employeepassword}, substr($form->{employeelogin}, 0, 2);
	  push @memberlogin, "password=$password\n";
	}
      } else {
	if ($oldemployeepassword) {
	  push @memberlogin, "password=$oldemployeepassword\n";
	}
      }

      for (qw(name email tan)) { push @memberlogin, "$_=$form->{$_}\n" if $form->{$_} }

      @{ $member{$employeelogin} } = ();
      
      for (@memberlogin) {
	push @{ $member{$employeelogin} }, $_;
      }
      
    } else {
      for (qw(company dateformat dbconnect dbdriver dbname dbhost dboptions dbpasswd dbuser numberformat)) { $m{$_} = $myconfig{$_} }
      for (qw(name email tan)) { $m{$_} = $form->{$_} }

      $m{dbpasswd} = pack 'u', $myconfig{dbpasswd};
      chop $m{dbpasswd};
      $m{stylesheet} = 'sql-ledger.css';
      $m{timeout} = 86400;

      if ($form->{employeepassword}) {
	$m{password} = crypt $form->{employeepassword}, substr($form->{employeelogin}, 0, 2);
      }

      @{ $member{$employeelogin} } = ();
      
      for (sort keys %m) {
	push @{ $member{$employeelogin} }, "$_=$m{$_}\n" if $m{$_};
      }
    }
    push @{ $member{$employeelogin} }, "\n";
  }
  
  if ($form->{employeelogin} ne $form->{oldemployeelogin}) {
    delete $member{$form->{oldemployeelogin}};   # old format
    delete $member{"$form->{oldemployeelogin}\@$myconfig{dbname}"};
  }
 
  seek(FH, 0, 0);
  truncate(FH, 0);

  # create header
  for (@member) {
    print FH $_;
  }

  for (sort keys %member) {
    print FH "\[$_\]\n";
    for $line (@{ $member{$_} }) {
      print FH $line;
    }
  }
  close(FH);

  if ($form->{employeelogin} ne $form->{oldemployeelogin}) {
    if ($form->{oldemployeelogin}) {
      for ("$form->{oldemployeelogin}.conf", "$form->{oldemployeelogin}\@$myconfig{dbname}.conf") {
	$filename = "$userspath/$_";
	if (-f $filename) {
	  unlink "$filename";
	}
      }
    }
  }

  unlink "${memberfile}.LCK";

}


sub delete { &{ "delete_$form->{db}" } };


sub delete_payroll {

  $form->{title} = $locale->text('Confirm!');

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->{action} = "yes";
  $form->hide_form;

  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|.$locale->text('Are you sure you want to delete Transaction').qq| $form->{invnumber}</h4>

<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>

</body>
</html>
|;

}


sub yes {

  if (AA->delete_transaction(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Transaction deleted!'));
  }

  $form->error($locale->text('Cannot delete transaction!'));

}


sub delete_employee {

  $form->error("$memberfile : ".$locale->text('locked!')) if (-f ${memberfile}.LCK);

  if (HR->delete_employee(\%myconfig, \%$form)) {
    delete $form->{employeelogin};

    &save_memberfile;
  
    $form->redirect($locale->text('Employee deleted!'));
  }
  
  $form->error($locale->text('Cannot delete employee!'));
  
}


sub continue { &{ $form->{nextsub} } };

sub add_employee { &add };
sub add_deduction { &add };
sub add_wage { &add };
sub add_transaction { &add };


sub prepare_payroll {

  HR->payroll_links(\%myconfig, \%$form);

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|$_->{code}--$_->{description}\n| }
  }
  
  for $key (qw(ap payment)) {
    if (@{ $form->{"all_$key"} }) {
      for (@{ $form->{"all_$key"} }) { $form->{"select$key"} .= qq|$_->{accno}--$_->{description}\n| }
    }
  }
 
  if (@{ $form->{all_paymentmethod} }) {
    $form->{selectpaymentmethod} = "\n";
    for (@{ $form->{all_paymentmethod} }) { $form->{selectpaymentmethod} .= qq|$_->{description}--$_->{id}\n| }
  }
  
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "\n";
    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|$_->{description}--$_->{id}\n| }
  }
  
  if (@{ $form->{all_project} }) {
    $form->{selectproject} = "\n";
    for (@{ $form->{all_project} }) { $form->{selectproject} .= qq|$_->{projectnumber}--$_->{id}\n| }
  }

  $i = 0;
  for (@{ $form->{all_reference} }) {
    $i++;
    $form->{"referencedescription_$i"} = $_->{description};
    $form->{"referenceid_$i"} = $_->{id};
  }
  $form->{reference_rows} = $i;
  
  $form->{selectprinter} = "";
  for (@{ $form->{all_printer} }) { $form->{selectprinter} .= "$_->{printer}\n" }
  chomp $form->{selectprinter};

  $form->{formname} = 'payslip';
  $form->{format} ||= $myconfig{outputformat};
  
  if ($myconfig{printer}) {
    $form->{format} ||= "postscript";
  } else {
    $form->{format} ||= "pdf";
  }
  $form->{media} ||= $myconfig{printer};
  
  $form->{selectformname} = qq|payslip--|.$locale->text('Pay Slip');

 
  if (@{ $form->{all_employee} }) {
    $form->{selectemployee} = "\n";
    for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }
  }

  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum(\%myconfig, $form->{transdate}) <= $form->{closedto});

  if (! $form->{readonly}) {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Payroll--Add Transaction/;
  }

  for (qw(formname language employee ap payment paymentmethod printer department project)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }

  $form->helpref("payrolltransaction", $myconfig{countrycode});
  
  if ($form->{id}) {

    $form->{oldemployee} = $form->{employee};

    for $i (1 .. $form->{wage_rows}) {
      $form->{"pay_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"} * $form->{"amount_$i"}, $form->{precision});
      
      $form->{"amount_$i"} = $form->format_amount(\%myconfig, $form->{"amount_$i"}, $form->{precision});
      
      $form->{"qty_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"});
    }

    for $i (1 .. $form->{payrate_rows}) {
      $form->{"rate_$i"} = $form->format_amount(\%myconfig, $form->{"rate_$i"}, $form->{precision});
      $form->{"above_$i"} = $form->format_amount(\%myconfig, $form->{"above_$i"});
    }
    
    $form->{paid} = $form->format_amount(\%myconfig, $form->{paid}, $form->{precision});

    &update_payroll;

  }

}


sub payroll_header {

  $paymentmethod = qq|
		    <tr>
		      <th align=right nowrap>|.$locale->text('Method').qq|</th>
		      <td><select name=paymentmethod>|
		      .$form->select_option($form->{selectpaymentmethod}, $form->{paymentmethod}, 1)
		      .qq|</select></td>
		    </tr>
| if $form->{selectpaymentmethod};

  $project = qq|
		    <tr>
		      <th align=right nowrap>|.$locale->text('Project').qq|</th>
		      <td><select name=project>|
		      .$form->select_option($form->{selectproject}, $form->{project}, 1)
		      .qq|</select></td>
		    </tr>
| if $form->{selectproject};

  $department = qq|
		    <tr>
		      <th align=right nowrap>|.$locale->text('Department').qq|</th>
		      <td><select name=department>|
		      .$form->select_option($form->{selectdepartment}, $form->{department}, 1)
		      .qq|</select></td>
		    </tr>
| if $form->{selectdepartment};

  $reference_documents = &reference_documents;

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->{ARAP} = "AP";

  $form->hide_form(qw(id invnumber helpref title precision ARAP reference_rows referenceurl));
  $form->hide_form(map { "select$_" } qw(formname language employee ap payment paymentmethod printer department project));

  print qq|

<input type=hidden name=action value="update">
 
<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Employee').qq| <font color=red>*</font></th>
		<td><select name=employee onChange="javascript:document.forms[0].submit()">|
		.$form->select_option($form->{selectemployee}, $form->{employee}, 1)
		.qq|</select></td>
	      </tr>
|;

  if ($form->{payrate_rows}) {
    print qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Pay Periods').qq|</th>
		<td>$form->{payperiod}</td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Pay Rates').qq|</th>
		<td>$form->{"rate_1"}</td>
	      </tr>
|;

    for $i (2 .. $form->{payrate_rows}) {
      print qq|
	      <tr>
		<td></td>
		<td>$form->{"rate_$i"} > $form->{"above_$i"}</td>
	      </tr>
|;
    }
  }

  print qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Pay Period Ending').qq|
		<td><input name=transdate size=11 class=date title="$myconfig{dateformat}" value=$form->{transdate}></td>
	      </tr>
|;

  $exemptlabel = $locale->text('Exempt');
  $deferlabel = $locale->text('Deferred');
  
  if ($form->{wage_rows}) {
    for $i (1 .. $form->{wage_rows}) {
      $exempt = ($form->{"exempt_$i"}) ? $exemptlabel : "";
      if ($form->{"defer_$i"}) {
	$exempt .= " / " if $exempt;
	$exempt .= $deferlabel;
      }
      
      print qq|
	      <tr>
		<th align=right nowrap>$form->{"wage_$i"}</th>
		<td><input name="qty_$i" class="inputright" size=10 value=$form->{"qty_$i"}> x <input name="amount_$i" class="inputright" size=10 value=$form->{"amount_$i"}> <b>$exempt</b></td>
	      </tr>
|;
    }
  }

  print qq|
	      $department
	      $project
	      
	      <tr>
		<th align=right nowrap>|.$locale->text('Description').qq|</th>
		<td><input name=description size=50 value="$form->{description}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Source').qq|</th>
		<td><input name=source value="$form->{source}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Memo').qq|</th>
		<td><input name=memo value="$form->{memo}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Paid').qq|</th>
		<td><input name=paid class="inputright" value="$form->{paid}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Date').qq|
		<td><input name=datepaid size=11 class=date title="$myconfig{dateformat}" value=$form->{datepaid}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Payment').qq|</th>
		<td><select name=payment>|
		.$form->select_option($form->{selectpayment}, $form->{payment})
		.qq|</select></td>
	      </tr>
	      $paymentmethod
	      <tr>
		<th align=right nowrap>|.$locale->text('AP').qq|</th>
		<td><select name=ap>|
		.$form->select_option($form->{selectap}, $form->{ap})
		.qq|</select></td>
	      </tr>
	    </table>
	  </td>
    
	  <td align=right>
	    <table>
	      $gross
|;

  for $i (1 .. $form->{wage_rows}) {
    if ($form->{"pay_$i"}) {
      print qq|
	      <tr>
		<th align=right nowrap>$form->{"wage_$i"}</th>
		<td align=right>$form->{"pay_$i"}</td>
	      </tr>
|;
      $form->hide_form(map { "${_}_$i" } qw(wage wage_id pay));
    }
  }

  for $i (1 .. $form->{deduction_rows}) {
    if ($form->{"deduct_$i"}) {
      print qq|
	      <tr>
		<th align=right nowrap>$form->{"deduction_$i"}</th>
		<td align=right>$form->{"deduct_$i"}</td>
	      </tr>
|;

      $form->hide_form(map { "${_}_$i" } qw(deduction deduction_id deduct));
    }
  }
  
  if ($form->{net}) {
    print qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Net').qq|</th>
		<td align=right>$form->{net}</td>
	      </tr>
|;
  }

  $form->hide_form(qw(gross net withheld deduction_rows wage_rows));
  
  print qq|
	    </table>
	  </td>
	</tr>
	$reference_documents
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub payroll_footer {

  $form->hide_form(qw(closedto oldemployee db path login callback));

  $transdate = $form->datetonum(\%myconfig, $form->{transdate});
  
  if ($form->{readonly}) {

    &islocked;

  } else {
  
    &print_options;

    print qq|<br>|;

    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
	       'Preview' => { ndx => 2, key => 'V', value => $locale->text('Preview') },
	       'Print' => { ndx => 3, key => 'P', value => $locale->text('Print') },
	       'Post' => { ndx => 4, key => 'O', value => $locale->text('Post') },
	       'Print and Post' => { ndx => 5, key => 'R', value => $locale->text('Print and Post') },
	       'Post as new' => { ndx => 6, key => 'N', value => $locale->text('Post as new') },
	       'Print and Post as new' => { ndx => 7, key => 'W', value => $locale->text('Print and Post as new') },
	       'Delete' => { ndx => 8, key => 'D', value => $locale->text('Delete') }
	      );

    if (! $form->{id}) {
      for ('Delete', 'Post as new', 'Print and Post as new') { delete $button{$_} }
    }

    if ($form->{locked} || $transdate <= $form->{closedto}) {
      for ("Preview", "Print", "Post", "Print and Post", "Delete") { delete $button{$_} }
    }

    if (!$latex) {
      for ("Preview", "Print and Post", "Print and Post as new") { delete $button{$_} }
    }

    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
    
  }

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


sub update_payroll {

  $upd = 1 if $form->{oldemployee} ne $form->{employee};
  $ap = $form->{ap};
  $pa = $form->{payment};
  $pm = $form->{paymentmethod};
  $form->{trans_id} = $id = $form->{id};

  ($employee, $form->{id}) = split /--/, $form->{employee};
  HR->get_employee(\%myconfig, \%$form, 1);

  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum(\%myconfig, $form->{transdate}) <= $form->{closedto});

  $form->{oldemployee} = $form->{employee};
  $form->{id} = $id;

  $form->{paid} = $form->parse_amount(\%myconfig, $form->{paid});

  if ($upd) {
    for (qw(ap payment)) { $form->{$_} = qq|$form->{$_}--$form->{"${_}_description"}| }
    $form->{paymentmethod} = qq|$form->{paymentmethod}--$form->{paymentmethod_id}|;
    $form->{paid} = 0;

    for (qw(description source memo)) { $form->{$_} = ""; }

    for $i (1 .. $form->{wage_rows}) {
      for (qw(wage pay wage_id qty amount)) { delete $form->{"${_}_$i"} }
    }

  } else {
    $form->{ap} = $ap;
    $form->{payment} = $pa;
    $form->{paymentmethod} = $pm;
  }

  $i = 1;
  for $ref (@{ $form->{all_employeewage} }) {

    $form->{"exempt_$i"} = ($ref->{exempt}) ? 1 : 0;
    $form->{"defer_$i"} = ($ref->{defer}) ? 1 : 0;
    $form->{"wage_$i"} = $ref->{description};
    $form->{"wage_id_$i"} = $ref->{id};
    $form->{"qty_$i"} = $form->parse_amount(\%myconfig, $form->{"qty_$i"});
    $form->{"amount_$i"} = $form->parse_amount(\%myconfig, $form->{"amount_$i"});
 
    if ($upd) {
      if ($ref->{amount}) {
	$form->{"amount_$i"} = $ref->{amount};
	$form->{"qty_$i"} = 1;
      }
    }

    $amount = $form->round_amount($form->{"qty_$i"} * $form->{"amount_$i"}, 10);
    $temp{gross} += $amount unless $ref->{exempt};
    $temp{net} += $amount unless $ref->{defer};
    
    $form->{"pay_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"} * $form->{"amount_$i"}, $form->{precision});

    $form->{"amount_$i"} = $form->format_amount(\%myconfig, $form->{"amount_$i"}, $form->{precision});
    
    $form->{"qty_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"});
    
    $i++;
  }
  $form->{wage_rows} = $i - 1;

  $form->{gross} = $form->format_amount(\%myconfig, $temp{gross}, $form->{precision});

  $form->{withheld} = 0;

  $i = 0;
  $amount = 0;

  
  if ($temp{gross}) {
    for $ed (@{ $form->{all_employeededuction} }) {
      $i++;
      $ok = 1;
      $form->{"deduction_$i"} = $ed->{description};
      $form->{"deduction_id_$i"} = $ed->{id};
      $form->{"deduct_$i"} = 0;

      if ($form->{payrolldeduction}{$ed->{id}}{employeepays}) {
	for $ref (@{ $form->{all_deductionrate} }) {
	  if (($ref->{trans_id} == $ed->{id}) && $ok) {
            $fromwithholding = 0;
            $fromincome = 0;
            $form->{"deduct_$i"} = $ref->{amount};

            $j = 0;
            for (@{ $form->{deduct}{$ref->{trans_id}} }) {
              if ($form->{deduct}{$ed->{id}}[$j]{trans_id} == $ref->{trans_id}) {
                $form->{deduct}{$ed->{id}}[$j]{percent} ||= 1;
                if ($form->{deduct}{$ed->{id}}[$j]{withholding}) {
                  $fromwithholding += $temp{$form->{deduct}{$ed->{id}}[$j]{id}} * $form->{deduct}{$ed->{id}}[$j]{percent};
                } else {
                  $fromincome += $temp{$form->{deduct}{$ed->{id}}[$j]{id}} * $form->{deduct}{$ed->{id}}[$j]{percent};
                }
              }
              $j++;
            }

            if ($form->{payrolldeduction}{$ed->{id}}{basedon}) {
              $amount = $temp{$form->{payrolldeduction}{$ed->{id}}{basedon}} - $fromincome;
            } else {
              $amount = $temp{gross} - $fromincome;
            }

	    if (($amount * $form->{payperiod}) > $ref->{above}) {
	      if (($amount * $form->{payperiod}) < $ref->{below}) {
		$form->{"deduct_$i"} += (($amount * $form->{payperiod}) - $ref->{above}) * $ref->{rate} / $form->{payperiod};
		$ok = 0;
	      } else {
		if ($ref->{below}) {
		  $form->{"deduct_$i"} += ($ref->{below} - $ref->{above}) * $ref->{rate} / $form->{payperiod};
		} else {
		  $form->{"deduct_$i"} += (($amount * $form->{payperiod}) - $ref->{above}) * $ref->{rate} / $form->{payperiod};
		}
	      }
	    }
	  }
	}

        $amount = ($form->{"deduct_$i"} - $fromwithholding - $ed->{exempt} / $form->{payperiod}) * $form->{payrolldeduction}{$ed->{id}}{employeepays};
	$amount = 0 if $amount < 0;

        # check if amount is over maximum
	if ($ed->{maximum}) {
	  if (($amount + $form->{total}{$ed->{id}}) > $ed->{maximum}) {
	    $amount = $ed->{maximum} - $form->{total}{$ed->{id}};
	  }
	}

        # check for age restrictions
	if ($form->{payrolldeduction}{$ed->{id}}{fromage} || $form->{payrolldeduction}{$ed->{id}}{toage}) {
	  $dob = $form->datetonum(\%myconfig, $form->{dob});

	  if ($form->{payrolldeduction}{$ed->{id}}{agedob}) {
	    $transdate = $form->datetonum(\%myconfig, $form->{transdate});
	  } else {
	    $transdate = substr($form->datetonum(\%myconfig, $form->{transdate}),0,4)."1231";
	  }

	  if ($transdate && dob) {
	    if ($form->{payrolldeduction}{$ed->{id}}{fromage}) {
	      $d = $dob + ($form->{payrolldeduction}{$ed->{id}}{fromage} * 10000);
	      $amount = 0 if $transdate <= $d;
	    }
	    if ($form->{payrolldeduction}{$ed->{id}}{toage}) {
	      $d = $dob + ($form->{payrolldeduction}{$ed->{id}}{toage} * 10000);
	      $transdate = substr($form->datetonum(\%myconfig, $form->{transdate}),0,4)."0101" unless $form->{payrolldeduction}{$ed->{id}}{agedob};
	      $amount = 0 if $transdate > $d;
	    }
	  }
	}

	$form->{"deduct_$i"} = $form->round_amount($amount, $form->{precision});

	$temp{$ed->{id}} = $form->{"deduct_$i"};
	$temp{net} -= $form->{"deduct_$i"};
      }
    }
  }
  $form->{deduction_rows} = $i;

  $form->{net} = $form->format_amount(\%myconfig, $temp{net}, $form->{precision});

  for $i (1 .. $form->{deduction_rows}) {
    $form->{withheld} += $form->{"deduct_$i"};
    $form->{"deduct_$i"} = $form->format_amount(\%myconfig, $form->{"deduct_$i"} * -1, $form->{precision});
  }

  for (qw(paid withheld)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $form->{precision}) }
  
  $i = 0;
  for $ref (@{ $form->{all_payrate} }) {
    $i++;
    $form->{"rate_$i"} = $form->format_amount(\%myconfig, $ref->{rate}, $form->{precision});
    $form->{"above_$i"} = $form->format_amount(\%myconfig, $ref->{above});
  }
  $form->{payrate_rows} = $i;

}


sub post {

  ($null, $employee_id) = split /--/, $form->{employee};

  $form->error($locale->text('Employee missing!')) unless $employee_id;
  $form->isblank("transdate", $locale->text('Date missing!'));

  $transdate = $form->datetonum(\%myconfig, $form->{transdate});
  $form->error($locale->text('Cannot post transaction for a closed period!')) if ($transdate <= $form->{closedto});
  
  if (! $form->{repost}) {
    if ($form->{id}) {
      &repost;
      exit;
    } else {
      delete $form->{invnumber};
    }
  }

  if (HR->post_transaction(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Transaction posted!'));
  }

  $form->error($locale->text('Posting failed!'));

}


sub search_payroll {

  $form->{reportcode} = 'payroll';

  HR->search_payroll(\%myconfig, \%$form);
  
  $form->{title} = $locale->text('Payroll Transactions');

  $form->helpref("payroll_transactions", $myconfig{countrycode});
  
  $employeelabel = $locale->text('Employee');
  
  if (@{ $form->{all_employee} }) {
    $form->{selectemployee} = "\n";
    for (@{ $form->{all_employee} }) { $form->{selectemployee} .= qq|$_->{name}--$_->{id}\n| }

    $employee = qq|
        <tr>
	  <th align=right nowrap>$employeelabel</th>
	  <td><select name=employee>|
	  .$form->select_option($form->{selectemployee}, undef, 1)
	  .qq|</select></td>
        </tr>
|;
  } else {
    $employee = qq|
        <tr>
	  <th align=right nowrap>$employeelabel</th>
	  <td><input name=employee size=35></td>
        </tr>
        <tr>
	  <th align=right nowrap>|.$locale->text('Employee Number').qq|</th>
	  <td><input name=employeenumber size=35></td>
        </tr>
|;
  }

  # departments
  if (@{ $form->{all_department} }) {
    $form->{selectdepartment} = "\n";

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|$_->{description}--$_->{id}\n| }

    $department = qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('Department').qq|</th>
	  <td><select name=department>|
	  .$form->select_option($form->{selectdepartment}, $form->{department}, 1)
	  .qq|
	  </select></td>
        </tr>
|;
  }

  # projects
  if (@{ $form->{all_project} }) {
    $form->{selectprojectnumber} = "\n";
    for (@{ $form->{all_project} }) { $form->{selectprojectnumber} .= qq|$_->{projectnumber}--$_->{id}\n| }

    $project = qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('Project').qq|</th>
	  <td><select name=projectnumber>|
	  .$form->select_option($form->{selectprojectnumber}, $form->{projectnumber}, 1)
	  .qq|</select></td>
        </tr>
|;
  }
    
  if (@{ $form->{all_years} }) {
    $selectaccountingyear = "\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|$_\n| }
    $selectaccountingmonth = "\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|$_--|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
      <tr>
        <th align=right>|.$locale->text('Period').qq|</th>
	<td>
	<select name=month>|.$form->select_option($selectaccountingmonth, undef, 1, 1).qq|</select>
	<select name=year>|.$form->select_option($selectaccountingyear, undef, 1).qq|</select>
	<input name=interval class=radio type=radio value=0 checked>&nbsp;|.$locale->text('Current').qq|
	<input name=interval class=radio type=radio value=1>&nbsp;|.$locale->text('Month').qq|
	<input name=interval class=radio type=radio value=3>&nbsp;|.$locale->text('Quarter').qq|
	<input name=interval class=radio type=radio value=12>&nbsp;|.$locale->text('Year').qq|
	</td>
      </tr>
|;
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
  
  if (@{ $form->{all_paymentmethod} }) {
    $form->{selectpaymentmethod} = "\n";
    for (@{ $form->{all_paymentmethod} }) { $form->{selectpaymentmethod} .= qq|$_->{description}--$_->{id}\n| }
    
    $paymentmethod = qq|
        <tr>
	  <th align=right>|.$locale->text('Method').qq|</th>
	  <td><select name=paymentmethod>|
	  .$form->select_option($form->{selectpaymentmethod}, $form->{paymentmethod}, 1)
	  .qq|
	  </select></td>
        </tr>
|;
  }

  @checked = qw(l_subtotal);
  @input = qw(employee paymentmethod transdatefrom transdateto month year sort direction reportlogin);
  %radio = ( interval => { 0 => 0, 1 => 1, 3 => 2, 12 => 3 },
             summary => { 1 => 1, 0 => 1 }
	   );
  
  $form->{sort} = "employee";
  $form->{summary} = 1;

  $form->header;
  
  JS->change_report(\%$form, \@input, \@checked, \%radio);
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        $reportform
        $employee
	$department
	$project
	<tr>
	  <th align=right nowrap>|.$locale->text('Date').qq|</th>
	  <td>|.$locale->text('From').qq| <input name=transdatefrom size=11 class=date title="$myconfig{dateformat}"> |.$locale->text('To').qq| <input name=transdateto size=11 class=date title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
	$paymentmethod
	<tr>
	  <td></td>
	  <td><input name=summary type=radio class=radio value=1> |.$locale->text('Summary').qq|
	  <input name=summary type=radio class=radio value=0 checked> |.$locale->text('Detail').qq|
	  </td>
	</tr>
	<tr>
	  <td></td>
	  <td nowrap><input name="l_subtotal" class=checkbox type=checkbox value=Y> |.$locale->text('Subtotal').qq|</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->{nextsub} = "payroll_transactions";

  $form->hide_form(qw(sort direction reportlogin helpref nextsub db path login));

  print qq|
<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
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


sub payroll_transactions {

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};
  $form->{sort} ||= "employee";
  $form->{reportcode} = 'payroll';
  
  HR->payroll_transactions(\%myconfig, \%$form);

  $form->{title} = $locale->text('Payroll Transactions');
  
  $href = "$form->{script}?action=payroll_transactions";
  for (qw(path login summary db)) { $href .= qq|&$_=$form->{$_}| }
  $href .= "&helpref=".$form->escape($form->{helpref});
  
  $callback = "$form->{script}?action=payroll_transactions";
  for (qw(path login summary db)) { $callback .= qq|&$_=$form->{$_}| }
  $callback .= "&helpref=".$form->escape($form->{helpref},1);
  
  if ($form->{employee}) {
    $callback .= "&employee=".$form->escape($form->{employee},1);
    $href .= "&employee=".$form->escape($form->{employee});
    ($employee) = split /--/, $form->{employee};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Employee');
    $option .= " : $employee";
  }
  if ($form->{department}) {
    $callback .= "&department=".$form->escape($form->{department},1);
    $href .= "&department=".$form->escape($form->{department});
    ($department) = split /--/, $form->{department};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Department')." : $department";
  }
  if ($form->{projectnumber}) {
    $callback .= "&projectnumber=".$form->escape($form->{projectnumber},1);
    $href .= "&projectnumber=".$form->escape($form->{projectnumber});
    ($projectnumber) = split /--/, $form->{projectnumber};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Project')." : $projectnumber";
  }
  if ($form->{transdatefrom}) {
    $callback .= "&transdatefrom=$form->{transdatefrom}";
    $href .= "&transdatefrom=$form->{transdatefrom}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{transdatefrom}, 1);
  }
  if ($form->{transdateto}) {
    $callback .= "&transdateto=$form->{transdateto}";
    $href .= "&transdateto=$form->{transdateto}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{transdateto}, 1);
  }
  
  @column_index = qw(employee transdate payslip invnumber reference paid);
  
  $column_data{employee} = "<th class=listheading>".$locale->text('Employee')."</a></th>";
  $column_data{transdate} = "<th class=listheading>".$locale->text('Date')."</a></th>";
  $column_data{invnumber} = "<th class=listheading>".$locale->text('AP')."</a></th>";
  $column_data{reference} = "<th class=listheading>".$locale->text('GL')."</a></th>";
  $column_data{payslip} = "<th>".$locale->text('Pay Slip')."</th>";
  $column_data{paid} = "<th class=listheading>" . $locale->text('Paid') . "</th>";
  
  for (@{ $form->{all_wage} }) {
    $column_data{$_->{id}} = "<th class=listheading>$_->{description}</th>";
    push @column_index, $_->{id};
  }

  for (@{ $form->{all_deduction} }) {
    $column_data{$_->{id}} = "<th class=listheading>$_->{description}</th>";
    push @column_index, $_->{id};
  }

  $form->{title} = ($form->{title}) ? $form->{title} : $locale->text('Payroll Transactions');
  $form->{title} .= " / $form->{company}";

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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

  # add sort and escape callback, this one we use for the add sub
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);

  $l = $#{$form->{transactions}};
  $i = 0;
  
  foreach $ref (@{ $form->{transactions} }) {

    for (qw(paid)) {
      $column_data{$_} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}, "&nbsp;")."</td>";
      $form->{"subtotal$_"} += $ref->{$_};
      $form->{"total$_"} += $ref->{$_};
    }
    
    for (@{ $form->{all_wage} }) {
      $column_data{$_->{id}} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_->{id}}, $form->{precision}, "&nbsp;")."</td>";
      $form->{"subtotal$_->{id}"} += $ref->{$_->{id}};
      $form->{"total$_->{id}"} += $ref->{$_->{id}};
    }
    for (@{ $form->{all_deduction} }) {
      $column_data{$_->{id}} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_->{id}}, $form->{precision}, "&nbsp;")."</td>";
      $form->{"subtotal$_->{id}"} += $ref->{$_->{id}};
      $form->{"total$_->{id}"} += $ref->{$_->{id}};
    }

    $column_data{invnumber} = "<td><a href=ap.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{invnumber}&nbsp;</a></td>";
    $column_data{reference} = "<td><a href=gl.pl?action=edit&id=$ref->{glid}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{reference}&nbsp;</a></td>";
    $column_data{payslip} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&db=payroll&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{invnumber}&nbsp;</a></td>";
    $column_data{transdate} = "<td nowrap>$ref->{transdate}</td>";
    $column_data{employee} = "<td>$ref->{employee}</td>";

    if ($ref->{$form->{sort}} eq $sameitem) {
      $column_data{$form->{sort}} = "<td>&nbsp;</td>";
    }

    $j++; $j %= 2;

    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;


    if ($form->{l_subtotal} eq 'Y') {
      if ($i < $l) {
	if ($ref->{$form->{sort}} ne $form->{transactions}->[$i+1]->{$form->{sort}}) {
	  &payroll_subtotal;
	}
      } else {
	&payroll_subtotal;
      }
    }

    $sameitem = $ref->{$form->{sort}};
    
    $i++;
  
  }
  
  # total
  for (@column_index) { $column_data{$_} = "<th>&nbsp;</th>" }

  $column_data{paid} = "<th align=right>".$form->format_amount(\%myconfig, $form->{"totalpaid"}, $form->{precision}, "&nbsp;")."</th>";
  
  for (@{ $form->{all_wage} }) {
    $column_data{$_->{id}} = "<th align=right>".$form->format_amount(\%myconfig, $form->{"total$_->{id}"}, $form->{precision}, "&nbsp;")."</th>";
  }

  for (@{ $form->{all_deduction} }) {
    $column_data{$_->{id}} = "<th align=right>".$form->format_amount(\%myconfig, $form->{"total$_->{id}"}, $form->{precision}, "&nbsp;")."</th>";
  }
  
  print "
        <tr class=listtotal>
";

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

<br>

<form method=post action=$form->{script}>
|;

  if ($form->{year} && $form->{month}) {
    for (qw(transdatefrom transdateto)) { delete $form->{$_} }
  }
  $form->hide_form(qw(employee paymentmethod transdatefrom transdateto month year interval summary l_subtotal));

  $form->hide_form(qw(callback path login report reportcode reportlogin db sort direction));

  %button = ('Add Transaction' => { ndx => 1, key => 'A', value => $locale->text('Add Transaction') },
             'Save Report' => { ndx => 8, key => 'S', value => $locale->text('Save Report') }
            );

  if ($myconfig{acs} =~ /HR--HR/) {
    delete $button{'AR--Add Transaction'};
  }
  
  if (!$form->{admin}) {
    delete $button{'Save Report'} unless $form->{savereport};
  }
  
  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

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


sub payroll_subtotal {

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td" }
  
  $column_data{paid} = "<th align=right>".$form->format_amount(\%myconfig, $form->{"subtotalpaid"}, $form->{precision}, "&nbsp;")."</th>";
  
  for (@{ $form->{all_wage} }) {
    $column_data{$_->{id}} = "<td align=right>".$form->format_amount(\%myconfig, $form->{"subtotal$_->{id}"}, $form->{precision}, "&nbsp;")."</td>";
    $form->{"subtotal$_->{id}"} = 0;
  }

  for (@{ $form->{all_deduction} }) {
    $column_data{$_->{id}} = "<td align=right>".$form->format_amount(\%myconfig, $form->{"subtotal$_->{id}"}, $form->{precision}, "&nbsp;")."</td>";
    $form->{"subtotal$_->{id}"} = 0;
  }
  
  print "
        <tr class=listsubtotal>
";

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;

}


sub search_deduction {

  HR->deductions(\%myconfig, \%$form);
  
  $callback = "$form->{script}?action=search_deduction";
  for (qw(db path login)) { $callback .= "&$_=$form->{$_}" } 
  
  @column_index = qw(description rate amount above below basedon employeepays employee_accno employerpays employer_accno);

  $form->helpref("deductions", $myconfig{countrycode});
 
  $form->{callback} = $callback;
  $callback = $form->escape($form->{callback});

  $column_header{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_header{rate} = qq|<th class=listheading nowrap>|.$locale->text('Rate %').qq|</th>|;
  $column_header{amount} = qq|<th class=listheading>|.$locale->text('Amount').qq|</th>|;
  $column_header{above} = qq|<th class=listheading>|.$locale->text('Above').qq|</th>|;
  $column_header{below} = qq|<th class=listheading>|.$locale->text('Below').qq|</th>|;
  $column_header{basedon} = qq|<th class=listheading>|.$locale->text('Based on').qq|</th>|;
  $column_header{employerpays} = qq|<th class=listheading>|.$locale->text('Employer').qq|</th>|;
  $column_header{employeepays} = qq|<th class=listheading>|.$locale->text('Employee').qq|</th>|;
  
  $column_header{employee_accno} = qq|<th class=listheading>|.$locale->text('Account').qq|</th>|;
  $column_header{employer_accno} = qq|<th class=listheading>|.$locale->text('Account').qq|</th>|;
  
  $form->{title} = $locale->text('Deductions') . " / $form->{company}";

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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

  for (@column_index) { print "$column_header{$_}\n" }
  
  print qq|
        </tr>
|;

  
  foreach $ref (@{ $form->{all_deduction} }) {

    $rate = $form->format_amount(\%myconfig, $ref->{rate} * 100, undef, "&nbsp;");
    
    $column_data{rate} = "<td align=right>$rate</td>";

    for (qw(amount above below)) { $column_data{$_} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_}, $form->{precision}, "&nbsp;")."</td>" }
      
    for (qw(basedon employee_accno employer_accno)) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }
    
    for (qw(employerpays employeepays)) { $column_data{$_} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{$_}, undef, "&nbsp;")."</td>" }
    
    if ($ref->{description} ne $sameitem) {
      $column_data{description} = "<td><a href=$form->{script}?action=edit&db=$form->{db}&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{description}</a></td>";
    } else {
      $column_data{description} = "<td>&nbsp;</td>";
    }

    $i++; $i %= 2;
    print "
        <tr class=listrow$i>
";

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
        </tr>
|;

    $sameitem = $ref->{description};
    
  }

  $i = 1;
  
  %button = ('Add Deduction' => { ndx => 1, key => 'A', value => $locale->text('Add Deduction') }
            );
  
  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(db callback path login));

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
  
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


sub prepare_deduction {
  
  HR->get_deduction(\%myconfig, \%$form);

  $i = 1;
  foreach $ref (@{ $form->{deductionrate} }) {
    for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }
    $i++;
  }
  $form->{rate_rows} = $i;
  
  $i = 1;
  foreach $ref (@{ $form->{deduct} }) {
    $form->{"deduct_$i"} = "$ref->{description}--$ref->{id}";
    $form->{"withholding_$i"} = ($ref->{withholding}) ? 1 : 0;
    $form->{"percent_$i"} = $ref->{percent} * 100;
    $i++;
  }
  $form->{deduct_rows} = $i;
  
  $form->{selectaccounts} = "\n";
  for (@{ $form->{accounts} }) { $form->{selectaccounts} .= "$_->{accno}--$_->{description}\n" }

  for (qw(employee employer)) { $form->{"${_}_accno"} = qq|$form->{"${_}_accno"}--$form->{"${_}_accno_description"}| }
  $form->{basedon} = qq|$form->{basedesc}--$form->{basedon}|;

  for (1 .. $form->{rate_rows}) { $form->{"rate_$_"} *= 100 }

  $form->{selectbasedon} = "\n";
  for (@{ $form->{all_deduction} }) {
    $form->{selectbasedon} .= qq|$_->{description}--$_->{id}\n|;
    $form->{showbasedon} = 1;
  }
  
  if (! $form->{readonly}) {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Add Deduction/;
  }

  for (qw(accounts basedon)) { $form->{"select$_"} = $form->escape($form->{"select$_"},1) }
  
  $form->helpref("deduction", $myconfig{countrycode});
  
}


sub deduction_header {

  $agedob{$form->{agedob}} = "checked";

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(helpref title rate_rows deduct_rows precision showbasedon));
  $form->hide_form(map { "select$_" } qw(basedon accounts));

  print qq|
  
<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Description').qq| <font color=red>*</font></th>
	  <td><input name=description size=35 value="|.$form->quote($form->{description}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Employee pays').qq| x</th>
	  <td><input name=employeepays class="inputright" size=4 value=|.$form->format_amount(\%myconfig, $form->{employeepays}).qq|>
	  <select name=employee_accno>|
	  .$form->select_option($form->{selectaccounts}, $form->{employee_accno}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Employer pays').qq| x</th>
	  <td><input name=employerpays class="inputright" size=4 value=|.$form->format_amount(\%myconfig, $form->{employerpays}).qq|>
	  <select name=employer_accno>|
	  .$form->select_option($form->{selectaccounts}, $form->{employer_accno}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Exempt age <').qq|</th>
	  <td><input name=fromage class="inputright" size=4 value=|.$form->format_amount(\%myconfig, $form->{fromage}).qq|>
	  <b>&gt;</b>
	  <input name=toage class="inputright" size=4 value=|.$form->format_amount(\%myconfig, $form->{toage}).qq|>
	  <input name=agedob type=checkbox style=checkbox value=1 $agedob{1}>&nbsp;|.$locale->text('DOB').qq|</td>
        </tr>
	<tr height="5"></tr>
	<tr>
	  <td colspan=2>
	    <table>
	      <tr class=listheading>
	        <th class=listheading>|.$locale->text('Rate %').qq|</th>
		<th class=listheading>|.$locale->text('Amount').qq|</th>
		<th class=listheading>|.$locale->text('Above').qq|</th>
		<th class=listheading>|.$locale->text('Below').qq|</th>
	      </tr>
|;

  for $i (1 .. $form->{rate_rows}) {
    print qq|
	      <tr>
		<td><input name="rate_$i" class="inputright" size=11 value=|.$form->format_amount(\%myconfig, $form->{"rate_$i"}).qq|></td>
		<td><input name="amount_$i" class="inputright" size=11 value=|.$form->format_amount(\%myconfig, $form->{"amount_$i"}, $form->{precision}).qq|></td>
		<td><input name="above_$i" class="inputright" size=11 value=|.$form->format_amount(\%myconfig, $form->{"above_$i"}, $form->{precision}).qq|></td>
		<td><input name="below_$i" class="inputright" size=11 value=|.$form->format_amount(\%myconfig, $form->{"below_$i"}, $form->{precision}).qq|></td>
	      </tr>
|;
  }

  print qq|
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
|;

  if ($form->{showbasedon}) {
    print qq|

  <tr>
    <td>
      <table>
        <tr valign=top>
	  <td>

	    <table>
	      <tr>
		<th>|.$locale->text('Based on').qq|</th>
	      <tr>
	      </tr>
		<td><select name="basedon">|
		.$form->select_option($form->{selectbasedon}, $form->{basedon}, 1).qq|</select></td>
	      </tr>
	    </table>
	  </td>
	  <td>
	    <table>
	      <tr>
		<th>|.$locale->text('Deduct').qq|</th>
		<th>|.$locale->text('Withholding').qq|</th>
		<th>|.$locale->text('%').qq|</th>
	      </tr>

|;

  for $i (1 .. $form->{deduct_rows}) {
    $checked = ($form->{"withholding_$i"}) ? "checked" : "";

    print qq|
	      <tr>
		<td><select name="deduct_$i">|
		.$form->select_option($form->{selectbasedon}, $form->{"deduct_$i"}, 1).qq|</select></td>
		<td align=center><input name="withholding_$i" type=checkbox class=checkbox value=1 $checked>
		<td><input name="percent_$i" class="inputright" size=10 value=|.$form->format_amount(\%myconfig, $form->{"percent_$i"}).qq|></td>
	      </tr>
      |;
  }
  
  print qq|
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
|;
  }

  print qq|
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}



sub deduction_footer {

  $form->hide_form(qw(status id db path login callback));
  
  if ($form->{readonly}) {

    &islocked;

  } else {
    
    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
	       'Save' => { ndx => 3, key => 'S', value => $locale->text('Save') },
	       'Save as new' => { ndx => 7, key => 'N', value => $locale->text('Save as new') },
	       'Delete' => { ndx => 16, key => 'D', value => $locale->text('Delete') },
	      );

    %f = ();
    for ('Update', 'Save') { $f{$_} = 1 }
    
    if ($form->{id}) {
      if ($form->{status} eq 'orphaned') {
	$f{'Delete'} = 1;
      }
      $f{'Save as new'} = 1;
    }

    for (keys %button) { delete $button{$_} if ! $f{$_} }
    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
    
  }

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


sub search_wage {

  HR->wages(\%myconfig, \%$form);
  
  $callback = "$form->{script}?action=search_wage";
  for (qw(db path login)) { $callback .= "&$_=$form->{$_}" } 
  
  @column_index = qw(description amount accno defer exempt);

  $form->helpref("wages", $myconfig{countrycode});
 
  $form->{callback} = $callback;
  $callback = $form->escape($form->{callback});

  $column_data{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_data{amount} = qq|<th class=listheading>|.$locale->text('Amount').qq|</th>|;
  $column_data{accno} = qq|<th class=listheading>|.$locale->text('Account').qq|</th>|;
  $column_data{defer} = qq|<th class=listheading>|.$locale->text('Defer').qq|</th>|;
  $column_data{exempt} = qq|<th class=listheading>|.$locale->text('Exempt').qq|</th>|;
  
  $form->{title} = $locale->text('Wages') . " / $form->{company}";

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
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
  
  print qq|
        </tr>
|;

  
  foreach $ref (@{ $form->{all_wage} }) {

    $column_data{amount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}, "&nbsp;")."</td>";
    $column_data{accno} = "<td>$ref->{accno}&nbsp;</td>";
    $column_data{defer} = "<td>$ref->{defer}&nbsp;</td>";

    $column_data{exempt} = ($ref->{exempt}) ? "<td>x</td>" : "<td></td>";
    
    $column_data{description} = "<td><a href=$form->{script}?action=edit&db=$form->{db}&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{description}</a></td>";

    $i++; $i %= 2;
    print "
        <tr class=listrow$i>
";

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
        </tr>
|;

  }

  $i = 1;
  
  %button = ('Add Wage' => { ndx => 1, key => 'A', value => $locale->text('Add Wage') }
            );
  
  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(db callback path login));

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
  
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


sub prepare_wage {
  
  HR->get_wage(\%myconfig, \%$form);

  $form->{selectaccounts} = "";
  for (@{ $form->{accounts} }) { $form->{selectaccounts} .= "$_->{accno}--$_->{description}\n" }

  $form->{accno} = qq|$form->{accno}--$form->{accno_description}|;
  $form->{defer} = qq|$form->{defer}--$form->{defer_description}|;

  if (! $form->{readonly}) {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Add Wage/;
  }

  $form->helpref("wage", $myconfig{countrycode});
  
}


sub wage_header {

  $form->header;

  $checked{exempt} = ($form->{exempt}) ? "checked" : "";

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(helpref title precision));
  $form->hide_form(map { "select$_" } qw(accounts));

  print qq|
  
<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Description').qq| <font color=red>*</font></th>
	  <td><input name=description size=35 value="|.$form->quote($form->{description}).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Account').qq| <font color=red>*</font></th>
	  <td>
	  <select name=accno>|
	  .$form->select_option($form->{selectaccounts}, $form->{accno}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Defer Payout').qq|</th>
	  <td>
	  <select name=defer>|
	  .$form->select_option("\n".$form->{selectaccounts}, $form->{defer}).qq|</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Amount').qq|</th>
	  <td><input name=amount class=inputright size=10 value=|.$form->format_amount(\%myconfig, $form->{amount}, $form->{precision}).qq|></td>
	</tr>
        <tr>
	  <th></th>
 	  <td><input name="exempt" type=checkbox class=checkbox value=1 $checked{exempt}> <b>|.$locale->text('Exempt').qq|</b></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}



sub wage_footer {

  $form->hide_form(qw(status id db path login callback));
  
  if ($form->{readonly}) {

    &islocked;

  } else {

    %button = (
	       'Save' => { ndx => 3, key => 'S', value => $locale->text('Save') },
	       'Save as new' => { ndx => 7, key => 'N', value => $locale->text('Save as new') },
	       'Delete' => { ndx => 16, key => 'D', value => $locale->text('Delete') },
	      );

    %f = ();
    for ('Update', 'Save') { $f{$_} = 1 }
    
    if ($form->{id}) {
      if ($form->{status} eq 'orphaned') {
	$f{'Delete'} = 1;
      }
      $f{'Save as new'} = 1;
    }

    for (keys %button) { delete $button{$_} if ! $f{$_} }
    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
    
  }

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


sub update {
  &{ "update_$form->{db}" };
  &display_form;
}


sub save { &{ "save_$form->{db}" } };


sub update_deduction {

  # if rate or amount is blank remove row
  @flds = qw(rate amount above below);
  $count = 0;
  @f = ();
  for $i (1 .. $form->{rate_rows}) {
    for (qw(rate amount above below)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    if ($form->{"rate_$i"} + $form->{"amount_$i"} + $form->{"above_$i"} + $form->{"below_$i"}) {
      push @f, {};
      $j = $#f;

      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
  $form->redo_rows(\@flds, \@f, $count, $form->{rate_rows});
  $form->{rate_rows} = $count + 1;
  
  @flds = qw(deduct withholding percent);
  $count = 0;
  @f = ();
  for $i (1 .. $form->{deduct_rows}) {
    if ($form->{"deduct_$i"}) {
      $form->{"percent_$i"} = $form->parse_amount(\%myconfig, $form->{"percent_$i"});
      push @f, {};
      $j = $#f;

      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
  $form->redo_rows(\@flds, \@f, $count, $form->{deduct_rows});
  $form->{deduct_rows} = $count + 1;

}


sub update_employee {

  # if rate or amount is blank remove row
  @flds = qw(deduction exempt maximum);
  $count = 0;
  @f = ();
  for $i (1 .. $form->{deduction_rows}) {
    for (qw(exempt maximum)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    if ($form->{"deduction_$i"}) {
      push @f, {};
      $j = $#f;

      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
  $form->redo_rows(\@flds, \@f, $count, $form->{deduction_rows});
  $form->{deduction_rows} = $count;


  @flds = qw(rate above);
  $count = 0;
  @f = ();
  for $i (1 .. $form->{payrate_rows}) {
    for (@flds) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    if ($form->{"rate_$i"}) {
      push @f, {};
      $j = $#f;

      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
  $form->redo_rows(\@flds, \@f, $count, $form->{payrate_rows});
  $form->{payrate_rows} = $count;
  
  @flds = qw(wage);
  $count = 0;
  @f = ();
  for $i (1 .. $form->{wage_rows}) {
    if ($form->{"wage_$i"}) {
      push @f, {};
      $j = $#f;

      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
  $form->redo_rows(\@flds, \@f, $count, $form->{wage_rows});
  $form->{wage_rows} = $count;

}
 

sub save_as_new {

  for (qw(id addressid)) { delete $form->{$_} }

  &save;

}


sub save_deduction {

  $form->isblank("description", $locale->text("Description missing!"));

  unless ($form->{"rate_1"} || $form->{"amount_1"}) {
    $form->isblank("rate_1", $locale->text("Rate missing!")) unless $form->{"amount_1"};
    $form->isblank("amount_1", $locale->text("Amount missing!"));
  }
  
  HR->save_deduction(\%myconfig, \%$form);
  $form->redirect($locale->text('Deduction saved!'));
  
}


sub delete_deduction {

  HR->delete_deduction(\%myconfig, \%$form);
  $form->redirect($locale->text('Deduction deleted!'));
  
}


sub save_wage {

  $form->isblank("description", $locale->text("Description missing!"));

  HR->save_wage(\%myconfig, \%$form);
  $form->redirect($locale->text('Wage saved!'));
  
}


sub delete_wage {

  HR->delete_wage(\%myconfig, \%$form);
  $form->redirect($locale->text('Wage deleted!'));
  
}


sub preview {

  $form->{format} = "pdf";
  $form->{media} = "screen";

  &print;

}

