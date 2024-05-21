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

  my %module = (
    ar_transaction => {
      script => 'ar',
      db     => 'ar',
      number => 'invnumber',
      var    => 'type=transaction',
      label  => $locale->text('AR Transaction')
    },
    ap_invoice => {
      script => 'ir',
      db     => 'ap',
      number => 'invnumber',
      var    => 'type=invoice',
      label  => $locale->text('Vendor Invoice')
    },
    ap_transaction => {
      script => 'ap',
      db     => 'ap',
      number => 'invnumber',
      var    => 'type=transaction',
      label  => $locale->text('AP Transaction')
    },
    ar_invoice => {
      script => 'is',
      db     => 'ar',
      number => 'invnumber',
      var    => 'type=invoice',
      label  => $locale->text('Sales Invoice')
    },
    assembly => {
      script => 'ic',
      db     => 'parts',
      number => 'partnumber',
      var    => 'item=assembly',
      label  => $locale->text('Assembly')
    },
    credit_invoice => {
      script => 'is',
      db     => 'ar',
      number => 'invnumber',
      var    => 'type=credit_invoice',
      label  => $locale->text('Credit Invoice')
    },
    credit_note => {
      script => 'ar',
      db     => 'ar',
      number => 'invnumber',
      var    => 'type=credit_note',
      label  => $locale->text('Credit Note')
    },
    customer => {
      script => 'ct',
      db     => 'customer',
      number => 'customernumber',
      var    => 'db=customer',
      label  => $locale->text('Customer')
    },
    debit_invoice => {
      script => 'ir',
      db     => 'ap',
      number => 'invnumber',
      var    => 'type=debit_invoice',
      label  => $locale->text('Debit Invoice')
    },
    debit_note => {
      script => 'ap',
      db     => 'ap',
      number => 'invnumber',
      var    => 'type=debit_note',
      label  => $locale->text('Debit Note')
    },
    employee => {
      script => 'hr',
      db     => 'employee',
      number => 'employeenumber',
      var    => 'db=employee',
      label  => $locale->text('Employee')
    },
    gl =>
      {script => 'gl', db => 'gl', number => 'id', label => $locale->text('GL Transaction')},
    job => {
      script => 'pe',
      db     => 'project',
      number => 'projectnumber',
      var    => 'type=job',
      label  => $locale->text('Job')
    },
    labor => {
      script => 'ic',
      db     => 'parts',
      number => 'partnumber',
      var    => 'item=labor',
      label  => $locale->text('Labor')
    },
    part => {
      script => 'ic',
      db     => 'parts',
      number => 'partnumber',
      var    => 'item=part',
      label  => $locale->text('Part')
    },
    payslip => {
      script => 'hr',
      db     => 'ap',
      number => 'invnumber',
      var    => 'db=payroll',
      label  => $locale->text('Pay Slip')
    },
    project => {
      script => 'pe',
      db     => 'project',
      number => 'projectnumber',
      var    => 'type=project',
      label  => $locale->text('Project')
    },
    purchase_order => {
      script => 'oe',
      db     => 'oe',
      number => 'ordnumber',
      var    => 'type=purchase_order',
      label  => $locale->text('Purchase Order')
    },
    request_quotation => {
      script => 'oe',
      db     => 'oe',
      number => 'quonumber',
      var    => 'type=request_quotation',
      label  => $locale->text('RFQ')
    },
    sales_order => {
      script => 'oe',
      db     => 'oe',
      number => 'ordnumber',
      var    => 'type=sales_order',
      label  => $locale->text('Sales Order')
    },
    sales_quotation => {
      script => 'oe',
      db     => 'oe',
      number => 'quonumber',
      var    => 'type=sales_quotation',
      label  => $locale->text('Quotation')
    },
    service => {
      script => 'ic',
      db     => 'parts',
      number => 'partnumber',
      var    => 'item=service',
      label  => $locale->text('Service')
    },
    storescard => {
      script => 'jc',
      db     => 'jcitems',
      number => 'id',
      var    => 'type=storescard',
      label  => $locale->text('Stores Card')
    },
    timecard => {
      script => 'jc',
      db     => 'jcitems',
      number => 'id',
      var    => 'type=timecard',
      label  => $locale->text('Timecard')
    },
    vendor => {
      script => 'ct',
      db     => 'vendor',
      number => 'vendornumber',
      var    => 'db=vendor',
      label  => $locale->text('Vendor')
    },
  );

  return %module;

}


sub upload {

  if ($form->{id}) {
    &display_documents;
    exit;
  }

  $form->load_defaults(\%myconfig, undef, ['max_upload_size']);

  $form->{title} = $locale->text('Upload Document');

  $form->helpref("cms", $myconfig{countrycode});

  $form->header;

  $form->{nextsub} = "upload_file";

  &resize;

  $focus = "description";

  print qq|
<body onLoad="main.${focus}.focus()" />

<form enctype="multipart/form-data" name=main method=post action=$form->{script}>

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
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">
</form>|;

  &check_upload_size if $form->{max_upload_size};

  print qq|

</body>
</html>
|;

}


sub upload_file {

  if ($form->{row}) {

    $form->header;

    $form->{filename} = ($form->{file}) ? $form->{file} : $form->{filename};

    &pickvalue;

for (qw(description filename folder)) { $form->{$_} =~ s/'/\\'/g }

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


sub download_document {
  if ($form->{id} and my $data = $form->get_reference(\%myconfig)) {

    $form->{contenttype} ||= 'text/plain';
    my $disposition = $form->{contenttype} =~ /^image/ ? 'inline' : 'attachment';

    print qq|Content-Type: $form->{contenttype}
Content-Disposition: $disposition; filename*=UTF-8''$form->{filename};\n\n|;

    open(OUT, ">-") or $form->error("STDOUT : $!");

    binmode(OUT);

    print OUT $data;
    close(OUT);

  } else {
    $form->error($locale->text('No data!'));
  }
}


sub search_documents {

  RD->prepare_search(\%myconfig, $form);

  $form->{title} = $locale->text('Reference Documents');

  $form->{nextsub} = "list_documents";

  $form->helpref("cms", $myconfig{countrycode});

  %m = &formnames;
  $selectformname = "\n";
  for (sort { $m{$a}->{label} cmp $m{$b}->{label} } keys %m) {
    if ($form->{has_formname}{$_}) {
      $selectformname .= qq|$m{$_}{label}--$_\n|;
    }
  }

  $selectfolder = "\n";
  for my $ref ($form->{all_folder}->@*) {
    $selectfolder .= "$ref->{folder}\n" if $ref->{folder};
  }

  $form->header;

  $focus = "description";

  print qq|
<body onLoad="main.${focus}.focus()">

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
          <td><select name=folder>|
          .$form->select_option($selectfolder).qq|</td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Filename').qq|</th>
          <td><input name=filename size=40></td>
        </tr>
        <tr>
          <th align="right" nowrap>|.$locale->text('Confidential').qq|</th>
          <td><input name="confidential" type="checkbox" value="1"></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Attached to').qq|</th>
          <td><select name=formname>|
          .$form->select_option($selectformname, undef, 1).qq|
          </td>
        </tr>
        <tr>
          <th align="right" nowrap>|.$locale->text('Number').qq|</th>
          <td><input name="document_number" size="40"></td>
        </tr>
      </table>
    </td>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">|;

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

  %m = &formnames;

  RD->all_documents(\%myconfig, $form, \%m);

  $href = "$form->{script}?action=list_documents";
  for (qw(direction oldsort path login)) { $href .= qq|&$_=$form->{$_}| }

  $form->sort_order();

  $callback = "$form->{script}?action=list_documents";
  for (qw(direction oldsort path login)) { $callback .= qq|&$_=$form->{$_}| }

  @columns
    = $form->{referenceurl}
    ? qw|description confidential formname document_number|
    : qw|filename description folder confidential formname document_number|;

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
  if ($form->{confidential}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Confidential');
    $href .= "&confidential=1";
    $callback .= "&confidential=1";
  }
  if ($form->{document_number}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Attached to')." : $form->{document_number}";
    $href .= "&document_number=".$form->escape($form->{document_number});
    $callback .= "&document_number=$form->{document_number}";
  }

  %module = &formnames;

  $column_data{delete} = qq|<th class=listheading width=1%><input name="allbox_delete" type=checkbox class=checkbox value="1" onChange="CheckAll();"></th>|;
  $column_data{confidential} = qq|<th class=listheading>|.$locale->text('C').qq|</th>|;
  $column_data{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_data{document_number} = qq|<th><a class=listheading href=$href&sort=document_number>|.$locale->text('Number').qq|</a></th>|;
  $column_data{folder} = qq|<th><a class=listheading href=$href&sort=folder>|.$locale->text('Folder').qq|</a></th>|;
  $column_data{formname} = qq|<th><a class=listheading href=$href&sort=formname>|.$locale->text('Attached to').qq|</a></th>|;
  $column_data{filename} = qq|<th><a class=listheading href=$href&sort=filename>|.$locale->text('Filename').qq|</a></th>|;

  $form->{title} = $locale->text('Reference Documents') . " / $form->{company}";

  $form->{callback} = $callback;
  $callback = $form->escape($callback,1);

  @column_index = $form->sort_columns(@columns);

  if ($form->{action} eq 'spreadsheet') {
    require "$form->{path}/rdss.pl";
    &documents_spreadsheet($option, \@column_index, \%column_data, \%module);
    exit;
  }

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

  $i = 0;
  my ($sameid, $skipid);
  foreach $ref (@{ $form->{all_documents} }) {

    if (($ref->{archive_id} || '0') eq $sameid) {
      $ref->{filename} = '&#8627';
      $skipid = 1;
    } else {
      $sameid = $ref->{archive_id};
      $skipid = 0;
    }

    $i++;

    for (@column_index) { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" }

    if ($ref->{formname}) {
      $column_data{formname} = qq|<td>$module{$ref->{formname}}{label}</td>|;
      if ($module{$ref->{formname}}{script}) {
        $href="$module{$ref->{formname}}{script}.pl?action=edit&id=$ref->{trans_id}&login=$form->{login}&path=$form->{path}";
        $href .= "&$module{$ref->{formname}}{var}" if $module{$ref->{formname}}{var};
        $column_data{document_number} = qq|<td><a href="$href" target="_blank">$ref->{document_number}</a></td>|;
      }
    }
    if ($ref->{filename}) {
      $column_data{filename} = qq|<td><a href="$form->{script}?action=download_document&login=$form->{login}&path=$form->{path}&id=$ref->{archive_id}">$ref->{filename}</a></td>|;
    }
    $column_data{description} = qq|<td><a href=$form->{script}?action=edit&login=$form->{login}&path=$form->{path}&id=$ref->{id}&callback=$callback>$ref->{description}</a></td>|;

    $column_data{delete} = qq|<td><input name="id_$i" class=checkbox type=checkbox value=$ref->{id}></td>|;

    if ($ref->{login}) {
      $column_data{confidential} = qq|<td align="center">x</td>|;
    }

    unless ($skipid) {
      $j++;
      $j %= 2;
    }

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

  %button = (
    'Add Document'     => {ndx => 2, key => 'A', value => $locale->text('Add Document')},
    'Delete Documents' => {ndx => 3, key => 'D', value => $locale->text('Delete Documents')},
    'Spreadsheet'      => {ndx => 4, key => 'X', value => $locale->text('Spreadsheet')},
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
          <th align="right">|.$locale->text('Number').qq|</th>
          <td><input name="document_number">
          </td>
        </tr>
      </table>
    </td>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">|;

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
  $form->{db}           = $m{$form->{formname}}{db};
  $form->{number_field} = $m{$form->{formname}}{number};

  if (RD->attach_document(\%myconfig, $form)) {
    $form->redirect($locale->text('Document attached!'));
  } else {
    $form->error(
      $locale->text($formname) . qq| $form->{document_number} | . $locale->text('does not exist!'));
  }
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


sub upload_image {

  $form->{title} = $locale->text('Upload Image');

  $form->helpref("upload_image", $myconfig{countrycode});

  $form->header;

  $form->{nextsub} = "upload_imagefile";

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

  $form->hide_form(qw(nextsub login path));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|" accesskey="C" title="|.$locale->text('Continue').qq| [C]">
</form>

</body>
</html>
|;

}


sub upload_imagefile {

  if (-s "$userspath/$form->{tmpfile}") {
    unless ($^O =~ /mswin/i) {
      $image = `file $userspath/$form->{tmpfile}`;
      unless ($image =~ /image/) {
        unlink "$userspath/$form->{tmpfile}";
        $form->error($locale->text('Not an Image file!'));
      }
    }

    open(IN, "$userspath/$form->{tmpfile}") or $form->error("$userspath/$form->{tmpfile} : $!\n");
    open(OUT, "> $images/$myconfig{dbname}/$form->{filename}") or $form->error("$images/$myconfig{dbname}/$form->{filename} : $!\n");

    binmode(IN);
    binmode(OUT);

    while (<IN>) {
      print OUT $_;
    }

    close(IN);
    close(OUT);

  }

  unlink "$userspath/$form->{tmpfile}";

  &list_images;

}


sub list_images {

  opendir DIR, "$images/$myconfig{dbname}" or $form->error("$images/$myconfig{dbname} : $!");

  @files = grep !/^\.\.?$/, readdir DIR;
  closedir DIR;

  @column_index = qw(ndx filename image);

  $form->{allbox} = ($form->{allbox}) ? "checked" : "";
  $action = ($form->{deselect}) ? "deselect_all" : "select_all";
  $column_data{ndx} = qq|<th class=listheading width=1%><input name="allbox" type=checkbox class=checkbox value="1" $form->{allbox} onChange="CheckAll(); javascript:document.main.submit()"><input type=hidden name=action value="$action"></th>|;
  $column_data{filename} = "<th class=listheading>".$locale->text('Filename')."</th>";
  $column_data{image} = "<th class=listheading>".$locale->text('Image')."</th>";

  $form->{callback} = "$form->{script}?action=list_images&path=$form->{path}&login=$form->{login}";

  $form->header;

  &check_all(qw(allbox ndx_));

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
      <table width=100%>
        <tr class=listheading>
|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;

  $checked = ($form->{deselect}) ? "checked" : "";
  $i = 0;
  for (@files) {
    $i++;
    $column_data{ndx} = qq|<td><input name="ndx_$i" class=checkbox type=checkbox value=$_ $checked></td>|;
    $column_data{filename} = qq|<td>$_</td>|;
    $column_data{image} = "<td><a href=$images/$myconfig{dbname}/$_><img src=$images/$myconfig{dbname}/$_ height=32 border=0></a></td>";

    $j++; $j %= 2;
    print "<tr class=listrow$j>";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
    </tr>
|;
  }

  print qq|
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>
|;

  $form->{rowcount} = $i;

  $form->hide_form(qw(rowcount callback path login));

  %button = ('Select all' => { ndx => 2, key => 'A', value => $locale->text('Select all') },
             'Deselect all' => { ndx => 3, key => 'A', value => $locale->text('Deselect all') },
             'Add File' => { ndx => 4, key => 'I', value => $locale->text('Add File') },
             'Delete Files' => { ndx => 5, key => 'D', value => $locale->text('Delete Files') }
             );

  if ($form->{deselect}) {
    delete $button{'Select all'};
  } else {
    delete $button{'Deselect all'};
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


sub select_all {

  $form->{allbox} = 1;
  $form->{deselect} = 1;
  for (qw(allbox deselect)) { $form->{callback} .= "&$_=$form->{$_}" }

  $form->redirect;
}


sub deselect_all {

  $form->redirect;

}


sub add_file { &upload_image }


sub delete_files {

  for $i (1 .. $form->{rowcount}) {
    if ($form->{"ndx_$i"}) {
      unlink qq|$images/$myconfig{dbname}/$form->{"ndx_$i"}|;
    }
  }

  $form->redirect;

}


sub continue { &{ $form->{nextsub} } };


sub spreadsheet {
  $form->parse_callback(\%myconfig, iso_date => 1);

  my $action = $form->{action};
  $form->{action} = 'spreadsheet';
  &$action;
}


=encoding utf8

=head1 NAME

bin/mozilla/rd.pl - Reference Documents

=head1 DESCRIPTION

L<bin::mozilla::rd> contains functions for reference documents.

=head1 DEPENDENCIES

L<bin::mozilla::rd>

=over

=item * uses
L<SL::RD>

=item * requires
L<bin::mozilla::js>,
L<bin::mozilla::menu>

=back

=head1 FUNCTIONS

L<bin::mozilla::rd> implements the following functions:

=head2 add_document

=head2 attach

=head2 continue

Calls C<< &{ $form->{nextsub} } >>.

=head2 delete

=head2 delete_documents

=head2 detach

=head2 display_documents

=head2 download_document

=head2 do_attach

=head2 edit

=head2 formnames

=head2 list_documents

=head2 save

=head2 search_documents

=head2 spreadsheet

=head2 upload

=head2 upload_file

=cut
