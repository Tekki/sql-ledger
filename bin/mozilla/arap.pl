#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# common routines for gl, ar, ap, is, ir, oe
#

use SL::AA;

require "$form->{path}/sr.pl";
require "$form->{path}/cm.pl";
require "$form->{path}/js.pl";

# any custom scripts for this one   
if (-f "$form->{path}/custom/arap.pl") {
    eval { require "$form->{path}/custom/arap.pl"; };
}
if (-f "$form->{path}/custom/$form->{login}/arap.pl") {
    eval { require "$form->{path}/custom/$form->{login}/arap.pl"; };
}
 

1;
# end of main


sub check_name {
  my ($name) = @_;

  my ($new_name, $new_id) = split /--/, $form->{$name};
  my $rv = 0;

  # if we use a selection
  if ($form->{"select$name"}) {
    if ($form->{"old$name"} ne $form->{$name}) {
      # this is needed for is, ir and oe
      for (split / /, $form->{taxaccounts}) { delete $form->{"${_}_rate"} }

      for (qw(city state country)) { delete $form->{$_} }
      
      # for credit calculations
      $form->{oldinvtotal} = 0;
      $form->{oldtotalpaid} = 0;
      $form->{calctax} = 1;

      $form->{"${name}_id"} = $new_id;
      AA->get_name(\%myconfig, \%$form);
      
      $form->{"paymentmethod_$form->{paidaccounts}"} = $form->{payment_method};
      $form->{"$form->{ARAP}_paid_$form->{paidaccounts}"} = $form->{payment_accno};

      $form->{$name} = $form->{"old$name"} = "$new_name--$new_id";
      $form->{currency} =~ s/ //g;
      $form->{cashdiscount} *= 100;
      $form->{cashdiscount} = 0 if $form->{type} =~ /(debit|credit)_/;

      # put employee together if there is a new employee_id
      $form->{employee} = "$form->{employee}--$form->{employee_id}" if $form->{employee_id};

      $rv = 1;
    }
  } else {

    my $dosearch;
    # check name, combine name and id
    if ($form->{"old$name"} ne qq|$form->{$name}--$form->{"${name}_id"}|) {
      $form->{searchby} = "name";
      $dosearch = 1;
    }

    if ($form->{"old${name}number"} ne $form->{"${name}number"}) {
      $form->{searchby} = "$form->{vc}number";
      $dosearch = 1;
    }

    if ($dosearch) {

      # this is needed for is, ir and oe
      for (split / /, $form->{taxaccounts}) { delete $form->{"${_}_rate"} }

      # for credit calculations
      $form->{oldinvtotal} = 0;
      $form->{oldtotalpaid} = 0;
      $form->{calctax} = 1;

      # return one name or a list of names in $form->{name_list}
      if (($rv = $form->get_name(\%myconfig, $name, $form->{transdate})) > 1) {
	&select_name($name);
	exit;
      }

      if ($rv == 1) {
	# we got one name
	$form->{"${name}_id"} = $form->{name_list}[0]->{id};
	$form->{$name} = $form->{name_list}[0]->{name};
	$form->{"${name}number"} = $form->{name_list}[0]->{"${name}number"};
	$form->{"old$name"} = qq|$form->{$name}--$form->{"${name}_id"}|;
	$form->{"old${name}number"} = $form->{"${name}number"};

	AA->get_name(\%myconfig, \%$form);

	$form->{"paymentmethod_$form->{paidaccounts}"} = $form->{payment_method};
	$form->{"$form->{ARAP}_paid_$form->{paidaccounts}"} = $form->{payment_accno};

	$form->{currency} =~ s/ //g;
	# put employee together if there is a new employee_id
	$form->{employee} = "$form->{employee}--$form->{employee_id}" if $form->{employee_id};
	$form->{cashdiscount} *= 100;
	$form->{cashdiscount} = 0 if $form->{type} =~ /(debit|credit)_/;

      } else {
	# name is not on file
	$msg = ucfirst $name . " not on file!";
	$form->error($locale->text($msg));
      }
    }
  }

  &rebuild_formnames;


  $rv;

}

# $locale->text('Customer not on file!')
# $locale->text('Vendor not on file!')


sub select_name {
  my ($table) = @_;

# $locale->text('Customer Number')
# $locale->text('Vendor Number')
# $locale->text('Employee Number')

  @column_index = qw(ndx name number address);

  $label = ucfirst $table;
  $labelnumber = "$label Number";
  
  $column_data{ndx} = qq|<th class=listheading width=1%>&nbsp;</th>|;
  $column_data{number} = qq|<th class=listheading>|.$locale->text($labelnumber).qq|</th>|;
  $column_data{name} = qq|<th class=listheading>|.$locale->text($label).qq|</th>|;
  $column_data{address} = qq|<th class=listheading colspan=5>|.$locale->text('Address').qq|</th>|;
  
  $form->helpref("list_names", $myconfig{countrycode});
  
  # list items with radio button on a form
  $form->header;

  $title = $locale->text('Select from one of the names below');

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$title</a></th>
  </tr>
  <tr space=5></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
	</tr>
|;

  @column_index = qw(ndx name number address city state zipcode country);
  
  my $i = 0;
  foreach $ref (@{ $form->{name_list} }) {
    $checked = ($i++) ? "" : "checked";

    $ref->{name} = $form->quote($ref->{name});
    
   $column_data{ndx} = qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
   $column_data{number} = qq|<td><input name="new_${table}number_$i" type=hidden value="|.$form->quote($ref->{"${table}number"}).qq|">$ref->{"${table}number"}</td>|;
   $column_data{name} = qq|<td><input name="new_name_$i" type=hidden value="|.$form->quote($ref->{name}).qq|">$ref->{name}</td>|;
   $column_data{address} = qq|<td>$ref->{address1} $ref->{address2}</td>|;
   for (qw(city state zipcode country)) { $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>| }
    
    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>

<input name="new_id_$i" type=hidden value=$ref->{id}>

|;

  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input name=lastndx type=hidden value=$i>

|;

  # delete variables
  for (qw(nextsub name_list)) { delete $form->{$_} }
  
  $form->{action} = "name_selected";
  
  $form->hide_form;

  print qq|
<input type=hidden name=nextsub value=name_selected>
<input type=hidden name=vc value=$table>
<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}



sub name_selected {

  # replace the variable with the one checked

  # index for new item
  $i = $form->{ndx};
  
  $form->{$form->{vc}} = $form->{"new_name_$i"};
  $form->{"$form->{vc}_id"} = $form->{"new_id_$i"};
  $form->{"old$form->{vc}"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
  $form->{"$form->{vc}number"} = $form->{"new_$form->{vc}number_$i"};
  $form->{"old$form->{vc}number"} = $form->{"$form->{vc}number"};

  # delete all the new_ variables
  for $i (1 .. $form->{lastndx}) {
    for (qw(id, name)) { delete $form->{"new_${_}_$i"} }
    delete $form->{"new_$form->{vc}number_$i"};
  }
  
  for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

  AA->get_name(\%myconfig, \%$form);

  $form->{"old$form->{ARAP}"} = $form->{$form->{ARAP}};

  # put employee together if there is a new employee_id
  $form->{employee} = "$form->{employee}--$form->{employee_id}" if $form->{employee_id};
  $form->{cashdiscount} *= 100;
  $form->{cashdiscount} = 0 if $form->{type} =~ /(debit|credit)_/;
  for (qw(terms discountterms)) { $form->{$_} = "" if ! $form->{$_} }
  
  $form->{"paymentmethod_$form->{paidaccounts}"} = $form->{payment_method};
  $form->{"$form->{ARAP}_paid_$form->{paidaccounts}"} = $form->{payment_accno};

  &rebuild_formnames;

  &update(1);

}


sub rebuild_formnames {

  $form->{selectformname} = $form->unescape($form->{selectformname});

  if ($form->{remittancevoucher}) {
    # add remittance voucher to formname
    if (! ($form->{selectformname} =~ /remittance_voucher/)) {
      $form->{selectformname} .= qq|\nremittance_voucher--|.$locale->text('Remittance Voucher');
    }
  } else {
    if ($form->{selectformname} =~ /remittance_voucher/) {
      $form->{selectformname} =~ s/\nremittance_voucher--.*//s;
    }
  }

  $form->{selectformname} = $form->escape($form->{selectformname},1);

}



sub rebuild_vc {
  my ($vc, $ARAP, $transdate, $job) = @_;

  (undef, $form->{employee_id}) = split /--/, $form->{employee};
  $form->all_vc(\%myconfig, $vc, $ARAP, undef, $transdate, $job);
  $form->{"select$vc"} = ($form->{generate}) ? "\n" : "";
  for (@{ $form->{"all_$vc"} }) { $form->{"select$vc"} .= qq|$_->{name}--$_->{id}\n| }
  $form->{"select$vc"} = $form->escape($form->{"select$vc"},1);
  
  $form->{selectprojectnumber} = "";
  if (@{ $form->{all_project} }) {
    $form->{selectprojectnumber} = "\n";
    for (@{ $form->{all_project} }) { $form->{selectprojectnumber} .= qq|$_->{projectnumber}--$_->{id}\n| }
    $form->{selectprojectnumber} = $form->escape($form->{selectprojectnumber},1);
  }

  1;

}


sub rebuild_departments {

  $form->all_departments(\%myconfig, undef, $form->{vc});

  ($subset) = split /--/, $form->{department};
  $subset =~ s/:.*//g;

  $form->{selectdepartment} = "\n" if @{ $form->{all_department} };
  $form->{olddepartment} = $form->{department};

  for (@{ $form->{all_department} }) { 
    if ($subset) {
      if ($_->{description} =~ /:/) {
        if ($_->{description} =~ /${subset}:/) {
          $form->{selectdepartment} .= qq|$_->{description}--$_->{id}\n|;
        }
      } else {
        $form->{selectdepartment} .= qq|$_->{description}--$_->{id}\n|;
      }
    } else {
      if ($_->{description} !~ /:/) {
        $form->{selectdepartment} .= qq|$_->{description}--$_->{id}\n|;
      }
    }
  }

}


sub add_transaction {

  $form->{action} = "add";

  $form->{callback} = $form->escape($form->{callback},1);
  $argv = "";
  for (keys %$form) { $argv .= "$_=$form->{$_}&" }

  $form->{callback} = "$form->{script}?$argv";

  $form->redirect;
  
}



sub check_project {

  for $i (1 .. $form->{rowcount}) {
    $form->{"project_id_$i"} = "" unless $form->{"projectnumber_$i"};
    if ($form->{"projectnumber_$i"} ne $form->{"oldprojectnumber_$i"}) {
      if ($form->{"projectnumber_$i"}) {
	# get new project
	$form->{projectnumber} = $form->{"projectnumber_$i"};
	if (($rows = PE->projects(\%myconfig, $form)) > 1) {
	  # check form->{project_list} how many there are
	  $form->{rownumber} = $i;
	  &select_project;
	  exit;
	}

	if ($rows == 1) {
	  $form->{"project_id_$i"} = $form->{project_list}->[0]->{id};
	  $form->{"projectnumber_$i"} = $form->{project_list}->[0]->{projectnumber};
	  $form->{"oldprojectnumber_$i"} = $form->{project_list}->[0]->{projectnumber};
	} else {
	  # not on file
	  $form->error($locale->text('Project not on file!'));
	}
      } else {
	$form->{"oldprojectnumber_$i"} = "";
      }
    }
  }

}


sub select_project {
  
  @column_index = qw(ndx projectnumber description);

  $column_data{ndx} = qq|<th width=1%>&nbsp;</th>|;
  $column_data{projectnumber} = qq|<th>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th>|.$locale->text('Description').qq|</th>|;
  
  $form->helpref("select_project", $myconfig{countrycode});
  
  # list items with radio button on a form
  $form->header;

  $title = $locale->text('Select from one of the projects below');

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=rownumber value=$form->{rownumber}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$title</a></th>
  </tr>
  <tr space=5></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
        </tr>
|;

  my $i = 0;
  foreach $ref (@{ $form->{project_list} }) {
    $checked = ($i++) ? "" : "checked";

   $column_data{ndx} = qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
   $column_data{projectnumber} = qq|<td><input name="new_projectnumber_$i" type=hidden value="|.$form->quote($ref->{projectnumber}).qq|">$ref->{projectnumber}</td>|;
   $column_data{description} = qq|<td>$ref->{description}</td>|;
    
    $j++; $j %= 2;
    print qq|
        <tr class=listrow$j>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>

<input name="new_id_$i" type=hidden value=$ref->{id}>

|;

  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input name=lastndx type=hidden value=$i>

|;

  # delete list variable
  for (qw(nextsub project_list)) { delete $form->{$_} }
  
  $form->{action} = "project_selected";
  
  $form->hide_form;

  print qq|
<input type=hidden name=nextsub value=project_selected>
<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub project_selected {
  
  # replace the variable with the one checked

  # index for new item
  $i = $form->{ndx};
  
  $form->{"projectnumber_$form->{rownumber}"} = $form->{"new_projectnumber_$i"};
  $form->{"oldprojectnumber_$form->{rownumber}"} = $form->{"new_projectnumber_$i"};
  $form->{"project_id_$form->{rownumber}"} = $form->{"new_id_$i"};

  # delete all the new_ variables
  for $i (1 .. $form->{lastndx}) {
    for (qw(id projectnumber description)) { delete $form->{"new_${_}_$i"} }
  }
  
  for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

  if ($form->{update}) {
    &{ $form->{update} };
  } else {
    &update;
  }

}


sub post_as_new {

  for (qw(id printed emailed queued)) { delete $form->{$_} }
  $form->{postasnew} = 1;
  &post;

}


sub print_and_post_as_new {

  for (qw(id printed emailed queued)) { delete $form->{$_} }
  &print_and_post;

}
  

sub repost {

  if ($form->{type} =~ /_order/) {
    if ($form->{print_and_save}) {
      $form->{nextsub} = "print_and_save";
      $msg = $locale->text('You are printing and saving an existing order');
    } else {
      $form->{nextsub} = "save";
      $msg = $locale->text('You are saving an existing order');
    }
  } elsif ($form->{type} =~ /_quotation/) {
    if ($form->{print_and_save}) {
      $form->{nextsub} = "print_and_save";
      $msg = $locale->text('You are printing and saving an existing quotation');
    } else {
      $form->{nextsub} = "save";
      $msg = $locale->text('You are saving an existing quotation');
    }
  } else {
    if ($form->{print_and_post}) {
      $form->{nextsub} = "print_and_post";
      $msg = $locale->text('You are printing and posting an existing transaction!');
    } else {
      $form->{nextsub} = "post";
      $msg = $locale->text('You are posting an existing transaction!');
    }
  }
  
  delete $form->{action};
  $form->{repost} = 1;

  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form;

  print qq|
<h2 class=confirm>|.$locale->text('Warning!').qq|</h2>

<h4>$msg</h4>

<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub schedule {
  
  ($form->{recurringreference}, $form->{recurringdescription}, $form->{recurringstartdate}, $form->{recurringrepeat}, $form->{recurringunit}, $form->{recurringhowmany}, $form->{recurringpayment}, $form->{recurringprint}, $form->{recurringemail}, $form->{recurringmessage}) = split /,/, $form->{recurring};

  for (qw(reference description message)) { $form->{"recurring$_"} = $form->quote($form->unescape($form->{"recurring$_"})) }

  $type = $form->{type} || "general_ledger";
  if (exists $form->{ARAP}) {
    $type = lc $form->{ARAP} . "_$form->{type}";
  }
  $form->helpref("recurring_$type", $myconfig{countrycode});

  $form->{recurringstartdate} ||= $form->{transdate};
  $recurringpayment = "checked" if $form->{recurringpayment};

  if ($form->{paidaccounts}) {
    $postpayment = qq|
 	<tr>
	  <th align=right nowrap>|.$locale->text('Include Payment').qq|</th>
	  <td><input name=recurringpayment type=checkbox class=checkbox value=1 $recurringpayment></td>
	</tr>
|;
  }

  if ($form->{recurringnextdate}) {
    $nextdate = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Next Date').qq|</th>
		<td><input name=recurringnextdate size=11 class=date title="$myconfig{'dateformat'}" value=$form->{recurringnextdate}>|.&js_calendar("main", "recurringnextdate").qq|</td>
	      </tr>
|;
  }

  for (split /\r?\n/, $form->unescape($form->{selectformname})) {
    (@_) = split /--/, $_;
    $formname{$_[0]} = $_[1];
  }
  for (qw(check receipt)) { delete $formname{$_} }

  $selectformat = qq|html--|.$locale->text('html').qq|
xml--|.$locale->text('XML').qq|
txt--|.$locale->text('Text').qq|
ps--|.$locale->text('Postscript').qq|
pdf--|.$locale->text('PDF');

  if ($form->{type} !~ /transaction/ && %formname) {
    $email = qq|
	<table>
	  <tr>
	    <th colspan=2 class=listheading>|.$locale->text('E-mail').qq|</th>
	  </tr>
	  
	  <tr>
	    <td>
	      <table>
|;

    # formname:format
    @p = split /:/, $form->{recurringemail};
    %p = ();
    for ($i = 0; $i <= $#p; $i += 2) {
      $p{$p[$i]}{format} = $p[$i+1];
    }
    
    foreach $item (keys %formname) {

      $checked = ($p{$item}{format}) ? "checked" : "";
      $p{$item}{format} ||= "pdf";
    
      $email .= qq|
		<tr>
		  <td><input name="email$item" type=checkbox class=checkbox value=1 $checked></td>
		  <th align=left>$formname{$item}</th>
		  <td><select name="emailformat$item">|
		  .$form->select_option($selectformat, $p{$item}{format}, undef, 1)
		  .qq|</select>
		  </td>
		</tr>
|;
    }
  
    $email .= qq|
	      </table>
	    </td>
	  </tr>
	</table>
|;

    $message = qq|
	<table>
	  <tr>
	    <th class=listheading>|.$locale->text('E-mail message').qq|</th>
	  </tr>

	  <tr>
	    <td><textarea name="recurringmessage" rows=10 cols=60 wrap=soft>$form->{recurringmessage}</textarea></td>
	  </tr>
	</table>
|;

  }

  if ($form->{selectprinter} && $latex && %formname) {
    $selectprinter = "";
    for (split /\n/, $form->unescape($form->{selectprinter})) { $selectprinter .= qq|
          <option value="$_">$_| }
	  
    # formname:format:printer
    @p = split /:/, $form->{recurringprint};

    %p = ();
    for ($i = 0; $i <= $#p; $i += 3) {
      $p{$p[$i]}{formname} = $p[$i];
      $p{$p[$i]}{format} = $p[$i+1];
      $p{$p[$i]}{printer} = $p[$i+2];
    }
    
    $print = qq|
	<table>
	  <tr>
	    <th colspan=2 class=listheading>|.$locale->text('Print').qq|</th>
	  </tr>

	  <tr>
	    <td>
	      <table>
|;

    foreach $item (keys %formname) {
   
      $selectprinter =~ s/ selected//;
      $p{$item}{printer} ||= $myconfig{printer};
      $selectprinter =~ s/(<option value="\Q$p{$item}{printer}\E")/$1 selected/;

      $checked = ($p{$item}{formname}) ? "checked" : "";

      $p{$item}{format} ||= $myconfig{outputformat};
      $p{$item}{format} ||= "postscript";
     
      $print .= qq|
		<tr>
		  <td><input name="print$item" type=checkbox class=checkbox value=1 $checked></td>
		  <th align=left>$formname{$item}</th>
		  <td><select name="printprinter$item">$selectprinter</select></td>
		  <td><select name="printformat$item">|
		  .$form->select_option($selectformat, $p{$item}{format}, undef, 1)
		  .qq|</select>
		  </td>
		</tr>
|;
    }
      
    $print .= qq|
	      </table>
	    </td>
	  </tr>
	</table>
|;


  }
  
  $selectrepeat = "";
  for (1 .. 31) { $selectrepeat .= qq|<option value="$_">$_\n| }
  $selectrepeat =~ s/(<option value="$form->{recurringrepeat}")/$1 selected/;
  
  $selectunit = qq|<option value="days">|.$locale->text('Day(s)').qq|
  <option value="weeks">|.$locale->text('Week(s)').qq|
  <option value="months">|.$locale->text('Month(s)').qq|
  <option value="years">|.$locale->text('Year(s)');

  if ($form->{recurringunit}) {
    $selectunit =~ s/(<option value="$form->{recurringunit}")/$1 selected/;
  }

  if ($form->{$form->{vc}}) {
    $description = $form->{$form->{vc}};
    $description =~ s/--.*//;
  } else {
    $description = $form->{description};
  }

  $repeat = qq|
	    <table>
	      <tr>
		<th colspan=3  class=listheading>|.$locale->text('Repeat').qq|</th>
	      </tr>

	      <tr>
		<th align=right nowrap>|.$locale->text('Every').qq|</th>
		<td><select name=recurringrepeat>$selectrepeat</td>
		<td><select name=recurringunit>$selectunit</td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('For').qq|</th>
		<td><input name=recurringhowmany class="inputright" size=3 value=$form->{recurringhowmany}></td>
		<th align=left nowrap>|.$locale->text('time(s)').qq|</th>
	      </tr>
	    </table>
|;

  
  $title = $locale->text('Recurring Transaction') ." ".  $locale->text('for') ." $description";

  if (($rows = $form->numtextrows($form->{recurringdescription}, 60)) > 1) {
    $description = qq|<textarea name="recurringdescription" rows=$rows cols=35 wrap=soft>$form->{recurringdescription}</textarea>|;
  } else {
    $description = qq|<input name=recurringdescription size=60 value="|.$form->quote($form->{recurringdescription}).qq|">|;
  }
  
  $form->header;

  &calendar;
  
  print qq|
<body>

<form method="post" name="main" action="$form->{script}">

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{helpref}$title</a></th>
  </tr>
  <tr space=5></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Reference').qq|</th>
		<td><input name=recurringreference size=20 value="|.$form->quote($form->{recurringreference}).qq|"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Description').qq|</th>
		<td>$description</td>
	      </tr>

	      <tr>
		<th align=right nowrap>|.$locale->text('Startdate').qq|</th>
		<td><input name=recurringstartdate size=11 class=date title="$myconfig{'dateformat'}" value=$form->{recurringstartdate}>|.&js_calendar("main", "recurringstartdate").qq|</td>
	      </tr>
	      $nextdate
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>
      <table>
	$postpayment
      </table>
    </td>
  </tr>
	
  <tr>
    <td>
      <table>
	<tr valign=top>
	  <td>$repeat</td>
	  <td>$print</td>
	</tr>
	<tr valign=top>  
	  <td>$email</td>
	  <td>$message</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
|;

  %button = ('Save Schedule' => { ndx => 1, key => 'S', value => $locale->text('Save Schedule') },
             'Delete Schedule' => { ndx => 16, key => 'D', value => $locale->text('Delete Schedule') },
	    );
  
  unless ($form->{recurring}) {
    delete $button{'Delete Schedule'};
  }

  $form->print_button(\%button);

  # delete variables
  for (qw(action recurring)) { delete $form->{$_} }
  for (qw(reference description startdate nextdate enddate repeat unit howmany payment print email message)) { delete $form->{"recurring$_"} }

  $form->hide_form;

  print qq|

</form>

</body>
</html>
|;

}


sub save_schedule {

  $form->{recurring} = "";

  for (qw(reference description message)) { $form->{"recurring$_"} = $form->escape($form->{"recurring$_"},1) }
  
  if ($form->{recurringstartdate}) {
    for (qw(reference description startdate repeat unit howmany payment)) { $form->{recurring} .= qq|$form->{"recurring$_"},| }
  }

  @p = ();
  for $item (split /\r?\n/, $form->unescape($form->{selectformname})) {
    (@f) = split /--/, $item;
    push @p, $f[0];
  }

  $recurringemail = "";
  for (@p) { $recurringemail .= qq|$_:$form->{"emailformat$_"}:| if $form->{"email$_"} }
  chop $recurringemail;
  
  $recurringprint = "";
  for (@p) { $recurringprint .= qq|$_:$form->{"printformat$_"}:$form->{"printprinter$_"}:| if $form->{"print$_"} }
  chop $recurringprint;

  $form->{recurring} .= qq|$recurringprint,$recurringemail,$form->{recurringmessage}| if $recurringemail || $recurringprint;

  $form->save_recurring(undef, \%myconfig) if $form->{id};

  if ($form->{recurringid}) {
    $form->redirect;
  } else {
    &update;
  }

}


sub delete_schedule {

  $form->{recurring} = "";

  $form->save_recurring(undef, \%myconfig) if $form->{id};

  if ($form->{recurringid}) {
    $form->redirect;
  } else {
    &update;
  }

}


sub reprint {

  $myconfig{vclimit} = 0;
  $pf = "print_form";

  for (qw(format formname media message)) { $temp{$_} = $form->{$_} }

  if ($form->{module} eq 'oe') {
    &order_links;
    &prepare_order;
    delete $form->{order_details};
    for (keys %$form) { $form->{$_} = $form->unquote($form->{$_}) }
  } else {
    if ($form->{type} eq 'invoice') {
      &invoice_links;
      &prepare_invoice;
      for (keys %$form) { $form->{$_} = $form->unquote($form->{$_}) }
    } else {
      &create_links;
      $form->{rowcount}--;
      for (1 .. $form->{rowcount}) { $form->{"amount_$_"} = $form->format_amount(\%myconfig, $form->{"amount_$_"}, $form->{precision}) }
      for (split / /, $form->{taxaccounts}) { $form->{"tax_$_"} = $form->format_amount(\%myconfig, $form->{"tax_$_"}, $form->{precision}) }
      $pf = "print_transaction";
    }
    for (qw(acc_trans invoice_details)) { delete $form->{$_} }
  }

  for (qw(department employee language month partsgroup project years)) { delete $form->{"all_$_"} }
  
  for (keys %temp) { $form->{$_} = $temp{$_} }
  
  $form->{rowcount}++;
  $form->{paidaccounts}++;

  delete $form->{paid};

  for (1 .. $form->{paidaccounts}) { $form->{"paid_$_"} = $form->format_amount(\%myconfig, $form->{"paid_$_"}, $form->{precision}) }
  $form->{"$form->{ARAP}_paid_$form->{paidaccounts}"} = $form->{payment_accno};
  $form->{"paymentmethod_$form->{paidaccounts}"} = $form->{payment_method};

  $form->{copies} = 1;

  &$pf;

  if ($form->{media} eq 'email') {
    # add email message
    $now = scalar localtime;
    $cc = $locale->text('Cc').qq|: $form->{cc}\n| if $form->{cc};
    $bcc = $locale->text('Bcc').qq|: $form->{bcc}\n| if $form->{bcc};

    $form->{intnotes} .= qq|\n\n| if $form->{intnotes};
    $form->{intnotes} .= qq|[email]\n|
    .$locale->text('Date').qq|: $now\n|
    .$locale->text('To').qq|: $form->{email}\n${cc}${bcc}|
    .$locale->text('Subject').qq|: $form->{subject}\n\n|
    .$locale->text('Message').qq|: |;

    $form->{intnotes} .= ($form->{message}) ? $form->{message} : $locale->text('sent');
    
    $form->save_intnotes(\%myconfig, $form->{module});
  }
  
}


sub islocked {

  print "<p><font color=red>".$locale->text('Locked by').": $form->{haslock}</font>" if $form->{haslock};

}


sub continue { &{ $form->{nextsub} } };
sub gl_transaction { &add };
sub ar_transaction {
  $form->{script} = "ar.pl";
  &add_transaction;
}
sub ap_transaction {
  $form->{script} = "ap.pl";
  &add_transaction;
};
sub sales_invoice_ {
  $form->{script} = "is.pl";
  $form->{type} = "invoice";
  &add_transaction;
}
sub credit_invoice_ {
  $form->{script} = "is.pl";
  $form->{type} = "credit_invoice";
  &add_transaction;
}
sub vendor_invoice_ {
  $form->{script} = "ir.pl";
  $form->{type} = "invoice";
  &add_transaction;
}
sub debit_invoice_ {
  $form->{script} = "ir.pl";
  $form->{type} = "debit_invoice";
  &add_transaction;
}


sub preview {

  $form->{format} = "pdf";
  $form->{media} = "screen";

  &print;
  
}


sub new_number {

  $invnumber = "invnumber";
  $numberfld = ($form->{vc} eq 'customer') ? "sinumber" : "vinumber";
  
  if ($form->{type} =~ /order/) {
    $invnumber = "ordnumber";
    $numberfld = ($form->{vc} eq 'customer') ? "sonumber" : "ponumber";
  } elsif ($form->{type} =~ /quotation/) {
    $invnumber = "quonumber";
    $numberfld = ($form->{vc} eq 'customer') ? "sqnumber" : "rfqnumber";
  } elsif ($form->{script} eq 'gl.pl') {
    $invnumber = "reference";
    $numberfld = "glnumber";
  } elsif ($form->{script} eq 'hr.pl') {
    $numberfld = $invnumber = "employeenumber";
    HR->isadmin(\%myconfig, \%$form);
  }

  $form->{"$invnumber"} = $form->update_defaults(\%myconfig, $numberfld);

  &update;
 
}


