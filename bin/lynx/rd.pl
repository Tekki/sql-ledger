#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Reference Documents
#
#======================================================================


use SL::RD;

require "$form->{path}/js.pl";

1;


sub formnames {
  
  my %module = ( ar_transaction	=> { script => ar, db => ar, var => "type=transaction", label => $locale->text('AR Transaction') },
              credit_note	=> { script => ar, db => ar, var => "type=credit_note", label => $locale->text('Credit Note') },
              ap_transaction	=> { script => ap, db => ap, var => "type=transaction", label => $locale->text('AP Transaction') },
	      debit_note	=> { script => ap, db => ap, var => "type=debit_note", label => $locale->text('Debit Note') },
	      ar_invoice	=> { script => is, db => ar, var => "type=invoice", label => $locale->text('Sales Invoice') },
	      credit_invoice	=> { script => is, db => ar, var => "type=credit_invoice", label => $locale->text('Credit Invoice') },
	      ap_invoice	=> { script => ir, db => ap, var => "type=invoice", label => $locale->text('Vendor Invoice') },
	      debit_invoice	=> { script => ir, db => ap, var => "type=debit_invoice", label => $locale->text('Debit Invoice') },
	      sales_order	=> { script => oe, db => oe, var => "type=sales_order", label => $locale->text('Sales Order') },
	      sales_quotation	=> { script => oe, db => oe, var => "type=sales_quotation", label => $locale->text('Quotation') },
	      purchase_order	=> { script => oe, db => oe, var => "type=purchase_order", label => $locale->text('Purchase Order') },
	      request_quotation	=> { script => oe, db => oe, var => "type=request_quotation", label => $locale->text('RFQ') },
	      gl		=> { script => gl, db => gl, label => $locale->text('GL Transaction') },
	      project		=> { script => pe, db => oe, var => "type=project", label => $locale->text('Project') },
	      job		=> { script => pe, db => project, var => "type=job", label => $locale->text('Job') },
	      customer		=> { script => ct, db => customer, var => "db=customer", label => $locale->text('Customer') },
	      vendor		=> { script => ct, db => vendor, var => "db=vendor", label => $locale->text('Vendor') },
	      part		=> { script => ic, db => parts, var => "item=part", label => $locale->text('Part') },
	      service		=> { script => ic, db => parts, var => "item=service", label => $locale->text('Service') },
	      assembly		=> { script => ic, db => parts, var => "item=assembly", label => $locale->text('Assembly') },
	      labor		=> { script => ic, db => parts, var => "item=labor", label => $locale->text('Labor') },
	      employee		=> { script => hr, db => employee, var => "db=employee", label => $locale->text('Employee') },
	      timecard		=> { script => jc, db => jcitems, var => "type=timecard", label => $locale->text('Timecard') },
	      storescard	=> { script => jc, db => jcitems, var => "type=storescard", label => $locale->text('Storescard') }
	    );  

  %module;
  
}


sub upload {

  if ($form->{id}) {
    &display_documents;
    exit;
  }

  $form->{title} = $locale->text('Upload Document');
  
  $form->helpref("cms", $myconfig{countrycode});
  
  $form->header;

  $form->{nextsub} = "upload_file";

  &resize;
  
  print qq|
<body>

<form enctype="multipart/form-data" method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{helpref}$form->{title}</a></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align="right">|.$locale->text('Description').qq|</th>
	  <td>
	    <input name=description size=40 value="$form->{description}">
	  </td>
	</tr>
        <tr>
	  <th align="right">|.$locale->text('Folder').qq|</th>
	  <td>
	    <input name=folder size=40 value="$form->{folder}">
	  </td>
	</tr>
        <tr>
	  <th align="right">|.$locale->text('Filename').qq|</th>
	  <td>
	    <input name=file size=40 value="$form->{file}">
	  </td>
	</tr>

        <tr>
	  <th align="right">|.$locale->text('File').qq|</th>
	  <td>
	    <input name=data size=60 type=file>
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

  $form->hide_form(qw(callback row title nextsub login path));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub upload_file {

  if ($form->{row}) {
    
    $form->header;

    $form->{filename} = ($form->{file}) ? $form->{file} : $form->{filename};

    &pickvalue;

    print qq|
<body onLoad="pickvalue('referencedescription_$form->{row}', '$form->{description}'); pickvalue('referencefilename_$form->{row}', '$form->{filename}'); pickvalue('referencetmpfile_$form->{row}', '$form->{tmpfile}'); pickvalue('referencearchive_id_$form->{row}', '-'); pickvalue('referencefolder_$form->{row}', '$form->{folder}'); window.close()">

</body>
</html>
|;
  } else {

    $form->{userspath} = $userspath;

    $form->error($locale->text('No file selected!')) unless $form->{filename};

    if (RD->save_document(\%myconfig, \%$form)) {
      ($script, $argv) = split /\?/, $form->{callback};
      %argv = split /[&=]/, $argv;
      for (qw(action description folder filename)) { delete $form->{$_} }
      for (keys %argv) { $form->{$_} = $argv{$_} }
      &list_documents;
    } else {
      $form->error($locale->text('Add document failed!'));
    }
    
  }

}


sub display_documents {

  $form->{action} = "display_documents";

  $form->{title} = $locale->text('Reference Documents');
  
  $form->helpref("cms", $myconfig{countrycode});
  
  if ($form->{id} eq '-') {
    $form->header;

  print qq|
<script language="javascript" type="text/javascript">
<!--
self.resizeTo(600,600);
//-->
</script>

<body>
|;

    $form->error($locale->text('Document not archived!'));

  }

  if ($form->{id}) {
    if ($data = $form->get_reference(\%myconfig)) {

      $form->{contenttype} ||= 'text/plain';
      
      print qq|Content-Type: $form->{contenttype}
Content-Disposition: inline; filename=$form->{filename};\n\n|;

      open(OUT, ">-") or $form->error("STDOUT : $!");
      
      binmode(OUT);
     
      print OUT $data;
      close(OUT);
       
    } else {
      $form->error($locale->text('No data!'));
    }
  }

}


sub search_documents {

  $form->{title} = $locale->text('Reference Documents');
  
  $form->{nextsub} = "list_documents";
  
  $form->helpref("cms", $myconfig{countrycode});

  %m = &formnames;
  $selectformname = "\n";
  for (sort { $m{$a}->{label} cmp $m{$b}->{label} } keys %m) {
    $selectformname .= qq|$m{$_}{label}--$_\n|;
  }

  $form->header;

  $focus = "description";
  
  print qq|
<body onLoad="main.${focus}.focus()" />

<form method="post" name="main" action="$form->{script}">


<table width=100%>
  <tr><th class=listtop>$form->{helpref}$form->{title}</a></th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Folder').qq|</th>
	  <td><input name=folder size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Form').qq|</th>
	  <td><select name=formname>|
	  .$form->select_option($selectformname, undef, 1).qq|
	  </td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Filename').qq|</th>
	  <td><input name=filename size=40></td>
	</tr>
      </table>
    </td>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->{action} = $form->{nextsub};
  $form->hide_form(qw(action nextsub login path));

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


sub list_documents {

  RD->all_documents(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_documents";
  for (qw(direction oldsort path login)) { $href .= qq|&$_=$form->{$_}| }
  
  $form->sort_order();
  
  $callback = "$form->{script}?action=list_documents";
  for (qw(direction oldsort path login)) { $callback .= qq|&$_=$form->{$_}| }
  
  @columns = qw(description folder filename confidential formname);
  
  if ($form->{description}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Description')." : $form->{description}";
    $href .= "&description=".$form->escape($form->{description});
    $callback .= "&description=$form->{description}";
  }
  if ($form->{filename}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Filename')." : $form->{filename}";
    $href .= "&filename=".$form->escape($form->{filename});
    $callback .= "&filename=$form->{filename}";
  }
  if ($form->{folder}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Folder')." : $form->{folder}";
    $href .= "&folder=".$form->escape($form->{folder});
    $callback .= "&folder=$form->{folder}";
  }
  if ($form->{formname}) {
    ($formname) = split /--/, $form->{formname};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Form')." : $formname";
    $href .= "&formname=".$form->escape($form->{formname});
    $callback .= "&formname=$form->{formname}";
  }
  
  %module = &formnames;

  $column_data{delete} = qq|<th class=listheading width=1%><input name="allbox_delete" type=checkbox class=checkbox value="1" onChange="CheckAll();"></th>|;
  $column_data{confidential} = qq|<th class=listheading>|.$locale->text('C').qq|</th>|;
  $column_data{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_data{folder} = qq|<th><a class=listheading href=$href&sort=folder>|.$locale->text('Folder').qq|</a></th>|;
  $column_data{formname} = qq|<th><a class=listheading href=$href&sort=formname>|.$locale->text('Attached to').qq|</a></th>|;
  $column_data{filename} = qq|<th><a class=listheading href=$href&sort=filename>|.$locale->text('Filename').qq|</a></th>|;
  
  $form->{title} = $locale->text('Reference Documents');

  $form->{callback} = $callback;
  $callback = $form->escape($callback,1);

  @column_index = $form->sort_columns(@columns);

  unshift @column_index, "delete";

  $form->helpref("cms", $myconfig{countrycode});

  $form->header;

  &check_all(qw(allbox_delete id_));

  print qq|
<body>

<form method="post" name="main" action="$form->{script}">

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

  $idlabel = $locale->text('ID');

  $i = 0;
  foreach $ref (@{ $form->{all_documents} }) {

    $i++;

    for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

    if ($ref->{formname}) {
      $column_data{formname} = qq|<td>$module{$ref->{formname}}{label}</td>|;
      if ($module{$ref->{formname}}{script}) {
	$href="$module{$ref->{formname}}{script}.pl?action=edit&id=$ref->{trans_id}&login=$form->{login}&path=$form->{path}";
	$href .= "&$module{$ref->{formname}}{var}" if $module{$ref->{formname}}{var};
	$column_data{formname} = qq|<td><a href="$href" target=_new>$module{$ref->{formname}}{label}</a> - $idlabel $ref->{trans_id}</td>|;
      }
    }
    if ($ref->{filename}) {
      $column_data{filename} = qq|<td><a href=$form->{script}?action=display_documents&login=$form->{login}&path=$form->{path}&id=$ref->{archive_id} target=popup>$ref->{filename}</a></td>|;
    }
    $column_data{description} = qq|<td><a href=$form->{script}?action=edit&login=$form->{login}&path=$form->{path}&id=$ref->{id}&callback=$callback>$ref->{description}</a></td>|;

    $column_data{delete} = qq|<td><input name="id_$i" class=checkbox type=checkbox value=$ref->{id}></td>|;

    if ($ref->{login}) {
      $column_data{confidential} = qq|<td>x</td>|;
    }

    $j++; $j %= 2;

    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
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
|;

  $form->{rowcount} = $i;

  %button = ( 'Add Document' => { ndx => 2, key => 'A', value => $locale->text('Add Document') },
              'Delete Documents' => { ndx => 3, key => 'D', value => $locale->text('Delete Documents') },
	    );
  
  $form->print_button(\%button);

  $form->hide_form(qw(rowcount folder formname callback login path));


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


sub add_document { &upload }


sub edit {

  RD->get_document(\%myconfig, \%$form);

  $form->{title} = $locale->text('Edit Reference Document');
  $form->helpref("cms", $myconfig{countrycode});
  $form->{confidential} = ($form->{confidential}) ? "checked" : "";
  
  $form->error($locale->text('Reference Document does not exist!')) unless $form->{id};
  
  %module = &formnames;

  if ($form->{formname}) {
    $attached = qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('Attached to').qq|</th>|;
      
    if ($module{$form->{formname}}{script}) {
      $href="$module{$form->{formname}}{script}.pl?action=edit&id=$form->{trans_id}&login=$form->{login}&path=$form->{path}";
      $href .= "&$module{$form->{formname}}{var}" if $module{$form->{formname}}{var};
    }
      
    $attached .= qq|<td><a href="$href" target=_new>$module{$form->{formname}}{label}</a></td>|;
  }

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
	  <th align="right">|.$locale->text('Description').qq|</th>
	  <td>
	    <input name=description size=40 value="$form->{description}">
	  </td>
	</tr>
        <tr>
	  <th align="right">|.$locale->text('Folder').qq|</th>
	  <td>
	    <input name=folder size=40 value="$form->{folder}">
	  </td>
	</tr>
        <tr>
	  <th align="right">|.$locale->text('Filename').qq|</th>
	  <td>
	    <input name=file size=40 value="$form->{filename}">
	  </td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Confidential').qq|</th>
	  <td><input name="confidential" class="checkbox" type="checkbox" $form->{confidential}></td>
	</tr>
	$attached
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>

</table>
|;

  $form->hide_form(qw(callback trans_id formname id archive_id login path));
  
  %button = ('Save' => { ndx => 1, key => 'S', value => $locale->text('Save') },
             'Attach' => { ndx => 2, key => 'A', value => $locale->text('Attach') },
             'Detach' => { ndx => 3, key => 'E', value => $locale->text('Detach') },
             'Delete' => { ndx => 11, key => 'D', value => $locale->text('Delete') }
	    );

  delete $button{'Delete'} unless $form->{id};

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


sub detach {

  $form->redirect($locale->text('Document detached!')) if RD->detach_document(\%myconfig, \%$form);
  $form->error($locale->text('Could not detach document!'));

}


sub attach {

  (undef, $form->{formname}) = split /--/, $form->{formname} if $form->{formname} =~ /--/;

  %m = &formnames;
  $selectformname = "";
  for (sort { $m{$a}->{label} cmp $m{$b}->{label} } keys %m) {
    $selectformname .= qq|$m{$_}{label}--$_\n|;
    $formselected = qq|$m{$_}{label}--$_| if $form->{formname} eq $_;
  }

  $form->{title} = $locale->text('Attach Document');
  $form->helpref("cms", $myconfig{countrycode});

  $form->header;

  print qq|
<body>

<form method="post" name="main" action="$form->{script}">


<table width=100%>
  <tr><th class=listtop>$form->{helpref}$form->{title}</a></th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align="right">|.$locale->text('Description').qq|</th>
	  <td>$form->{description}
	  </td>
	</tr>
        <tr>
	  <th align="right">|.$locale->text('Folder').qq|</th>
	  <td>$form->{folder}
	  </td>
	</tr>
        <tr>
	  <th align="right">|.$locale->text('Filename').qq|</th>
	  <td>$form->{file}
	  </td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Attach to').qq|</th>
	  <td><select name=formname>|
	  .$form->select_option($selectformname, $formselected, 1).qq|
	  </td>
	</tr>
        <tr>
	  <th align="right">|.$locale->text('ID').qq|</th>
	  <td><input name=trans_id>
	  </td>
	</tr>
      </table>
    </td>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->{nextsub} = "do_attach";
  $form->{action} = $form->{nextsub};
  $form->hide_form(qw(id action description folder file callback nextsub login path));

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


sub do_attach {

  %m = &formnames;
  ($formname, $form->{formname}) = split /--/, $form->{formname};
  $form->{db} = $m{$form->{formname}}{db};

  $form->redirect($locale->text('Document attached!')) if RD->attach_document(\%myconfig, \%$form);
  
  $form->error($locale->text($formname).qq| |.$locale->text('ID').qq| $form->{trans_id} |.$locale->text('does not exist!'));

}


sub delete {
  
  $form->redirect($locale->text('Document deleted!')) if RD->delete_document(\%myconfig, \%$form);
  
  $form->error($locale->text('Could not delete document!'));

}


sub delete_documents {

  $form->redirect($locale->text('Documents deleted!')) if RD->delete_documents(\%myconfig, \%$form);

}


sub save {

  $form->{userspath} = $userspath;
  $form->redirect($locale->text('Document saved!')) if RD->save_document(\%myconfig, \%$form);
  $form->error($locale->text('Could not save document!'));
  
}


sub continue { &{ $form->{nextsub} } };

