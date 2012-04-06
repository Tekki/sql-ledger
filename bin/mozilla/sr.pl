#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2007
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================


sub save_report {

  if ($form->{savereport}) {
    delete $form->{savereport};
    &do_save_report;
    exit;
  }
  
  $form->{title} = $locale->text('Save Report');

  $public = ($form->{reportlogin}) ? "" : "checked";
  $form->{savereport} = 1;

  ($form->{reportdescription}, $form->{reportid}) = split /--/, $form->{report};
  
  if ($form->{admin}) {
    $publicreport = qq|
      <tr>
	<th align=right>|.$locale->text('Public').qq|</th>
	<td>
	  <input name=public type=checkbox style=checkbox value=1 $public>
	</td>
      </tr>
|;
  } else {
    $publicreport = $form->hide_form(qw(reportlogin public));
  }
    
  $form->helpref("save_report", $myconfig{countrycode});
  
  $form->header;

print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td>
	    <input name=reportdescription value="$form->{reportdescription}">
	  </td>
	</tr>
	$publicreport
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>

</table>
|;

  for (qw(helpref report reportdescription public)) { delete $form->{$_} }

  $form->hide_form;

  %button = ('Save Report' => { ndx => 1, key => 'S', value => $locale->text('Save Report') });
  
  if ($form->{reportid}) {
    $button{'Save Report as new'} = { ndx => 2, key => 'N', value => $locale->text('Save Report as new') };
    $button{'Delete Report'} = { ndx => 3, key => 'D', value => $locale->text('Delete Report') };
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


sub do_save_report {

  $login = $form->{login};
  $login =~ s/\@.*//;
  if ($form->{admin}) {
    if ($form->{public}) {
      delete $form->{reportlogin};
    } else {
      $form->{reportlogin} ||= $login;
    }
  } else {
    $form->{reportlogin} ||= $login;
  }
  
  $form->save_report(\%myconfig);

  $form->{report} = qq|$form->{reportdescription}--$form->{reportid}|;
  
  if ($form->{callback}) {
    $form->{callback} .= qq|&report=|.$form->escape($form->{report},1);
    for (qw(reportcode reportlogin)) { $form->{callback} .= qq|&$_=$form->{$_}| }
  }
    
  $form->redirect;
  
}


sub save_report_as_new {

  delete $form->{reportid};
  &do_save_report;

}


sub delete_report {

  delete $form->{reportdescription};
  &do_save_report;

}


sub edit_column {

  %flds = split /[=,]/, $form->{flds};
  
  ($fld, $ndx, $t) = split /,/, $form->{editcolumn};

  $title = $form->{title};
  if ($t eq 't') {
    $form->{title} = $locale->text('Edit Column Total');
    $t = "t_";
  } elsif ($t eq 'h') {
    $form->{title} = $locale->text('Edit Column Header');
    $t = "h_";
  } else {
    $form->{title} = $locale->text('Edit Column');
    $t = "";
  }
  $form->{title} .= " / $flds{$fld}";

  %temp = ();
  for (qw(a w f)) {
    $temp{$_} = "$t${_}_$ndx";
  }
  
  $form->{$temp{a}} ||= 'left';
  for (qw(left right center)) { $checked{$_} = "checked" if $form->{$temp{a}} eq $_ }

  $helpref = $form->{helpref};
  $form->helpref("edit_column", $myconfig{countrycode});
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Width').qq|</th>
	  <td><input name="$temp{w}" value="$form->{$temp{w}}" size=3>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Align').qq|</th>
	  <td>
	  <input name="$temp{a}" type=radio value=left $checked{left}> <b>|.$locale->text('Left').qq|</b>
	  <input name="$temp{a}" type=radio value=right $checked{right}> <b>|.$locale->text('Right').qq|</b>
	  </td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Fill').qq|</th>
	  <td><input name="$temp{f}" value="$form->{$temp{f}}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  for (keys %temp) { delete $form->{$temp{$_}} }
  
  for (qw(stylesheet)) { delete $form->{$_} }
  
  $form->{title} = $title;
  $form->{ndx} = $ndx;
  $form->{helpref} = $helpref;

  $form->hide_form;

  %button = ('Save Column' => { ndx => 1, key => 'S', value => $locale->text('Save Column') },
             'Delete Column' => { ndx => 2, key => 'D', value => $locale->text('Delete Column') }
	    );
  
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


sub add_column {

  %flds = split /[=,]/, $form->{flds};
  
  %column_index = split /[=,]/, $form->{column_index};

  $ndx = 1;
  for (keys %column_index) {
    delete $flds{$_};
    $ndx++;
  }

  $title = $form->{title};
  $form->{title} = $locale->text('Add Column');

  $helpref = $form->{helpref};
  $form->helpref("column", $myconfig{countrycode});
 
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
    <td>
      <table>
|;

  $form->{ndxstart} = $ndx;

  for (sort { $flds{$a} cmp $flds{$b} } keys %flds) {

    print qq|
    
	<tr>
	  <th class=listheading colspan=2>$flds{$_}</th>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Width').qq|</th>
	  <td><input name="new_w_$ndx" size=3>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Align').qq|</th>
	  <td>
	  <input name="new_a_$ndx" type=radio value=left checked> <b>|.$locale->text('Left').qq|</b>
	  <input name="new_a_$ndx" type=radio value=right> <b>|.$locale->text('Right').qq|</b>
	  </td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Fill').qq|</th>
	  <td><input name="new_f_$ndx"></td>
	</tr>
|;

    $form->{"new_fld_$ndx"} = $_;
    $form->hide_form("new_fld_$ndx");

    $ndx++;
  }
  
  $form->{ndxend} = $ndx;
 
  print qq|
    
	<tr>
	  <th class=listheading colspan=2>|.$locale->text('Fixed value').qq|</th>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Heading').qq|</th>
	  <td><input name="new_fld" size=20></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Width').qq|</th>
	  <td><input name="new_w_$ndx" size=3>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Align').qq|</th>
	  <td>
	  <input name="new_a_$ndx" type=radio value=left checked> <b>|.$locale->text('Left').qq|</b>
	  <input name="new_a_$ndx" type=radio value=right> <b>|.$locale->text('Right').qq|</b>
	  </td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Fill').qq|</th>
	  <td><input name="new_f_$ndx"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  for (qw(stylesheet)) { delete $form->{$_} }
  
  $form->{title} = $title;
  $form->{helpref} = $helpref;
  
  $form->hide_form;

  %button = ('Save Column' => { ndx => 1, key => 'S', value => $locale->text('Save Column') }
	    );
  
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


sub save_column {

  ($label, $ndx, $t) = split /,/, $form->{editcolumn};
  delete $form->{editcolumn};

  if ($t) {
    @t = ("${t}_f", "${t}_a", "${t}_w");
  } else {
    @t = qw(f a w);
  }
  if (! $form->{"$t[2]_$ndx"}) {
    for (@t) {
      delete $form->{"${_}_$ndx"};
    }
  }

  $j = $form->{ndxstart};
  for $i ($form->{ndxstart} .. $form->{ndxend}) {
    if ($form->{"new_w_$i"}) {
      if (! $form->{"new_fld_$i"}) {
	$form->{"new_fld_$i"} = $form->{new_fld};
	$form->{"new_fld_$i"} =~ s/ /_/g;
	$form->{flds} .= qq|,$form->{"new_fld_$i"}=$form->{new_fld}|;
      }

      $form->{column_index} .= qq|,$form->{"new_fld_$i"}=|;
      delete $form->{"new_fld_$i"};
	
      for (@t) {
	$form->{"${_}_$j"} = $form->{"new_${_}_$i"};
	delete $form->{"new_${_}_$i"};
      }
      $j++;
    }
  }

  &{"$form->{nextsub}"};

}


sub delete_column {

  %flds = split /[=,]/, $form->{flds};
  
  ($fld, $ndx) = split /,/, $form->{editcolumn};
  delete $form->{editcolumn};

  %column_index = ();
  
  $i = 1;
  for (split /,/, $form->{column_index}) {
    ($l, $v) = split /=/, $_;
    $column_index{$i} = { l => $l, v => $v };
    $i++;
  }
  
  delete $column_index{$ndx};

  $form->{column_index} = join ',', map { "$column_index{$_}{l}=$column_index{$_}{v}" } sort { $a <=> $b } keys %column_index;

  $j = $i - 2;
  $ndx;
  for $i ($ndx .. $j) {
    $k = $i + 1;
    for (qw(a w f)) {
      $form->{"${_}_$i"} = $form->{"${_}_$k"};
      $form->{"t_${_}_$i"} = $form->{"t_${_}_$k"};
      $form->{"h_${_}_$i"} = $form->{"h_${_}_$k"};
    }
  }
  
  for (qw(a w f)) {
    delete $form->{"${_}_$k"};
    delete $form->{"t_${_}_$k"};
    delete $form->{"h_${_}_$k"};
  }

  &{$form->{nextsub}};

}


1;
# end of main

