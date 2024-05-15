#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Attach Reference Documents to transactions
# CMS is in rd.pl and RD.pm
#
#======================================================================


sub all_references {

  my $i = 0;
  for $ref (@{ $form->{all_reference} }) {
    $i++;
    for (qw(id code description archive_id filename confidential folder)) { $form->{"reference${_}_$i"} = $ref->{$_} }
  }
  $form->{reference_rows} = $i;

}


sub references {

  # reshuffle
  my @flds = map { "reference$_" } qw(id code description tmpfile archive_id filename confidential folder);

  my $count = 0;
  my @f = ();
  my $checked;
  my $i;
  my $rv;
  my $confidential = $locale->text('Confidential');

  for $i (1 .. $form->{reference_rows}) {
    if ($form->{"referencedescription_$i"}) {
      push @f, {};
      $j = $#f;

      for (@flds) { $f[$j]->{$_} = $form->{"${_}_$i"} }
      $count++;
    }
  }
  $form->redo_rows(\@flds, \@f, $count, $form->{reference_rows});
  $form->{reference_rows} = $count + 1;

  if ($form->{referenceurl}) {

    $rv = qq|
            <table>
              <tr class="listheading">
                <th class="listheading" colspan="3">|.$locale->text('Reference Documents').qq|</th>
              </tr>|;

  } else {

    my $rowspan = $form->{reference_rows} + 2;

    $rv = qq|
            <table>
              <tr>
                <th class="listheading clickable" id="document-switch" colspan="4">|.$locale->text('Reference Documents').qq| &#9881;</th>
                <td></td>
                <td id="drop-zone" class="dnd-idle" width="100%" rowspan="$rowspan">|.$locale->text('Drag and Drop').qq|</td>
              </tr>
              <tr class="docdetails noscreen noprint">
                <th class="listheading">|.$locale->text('Description').qq|</th>
                <th class="listheading">|.$locale->text('C').qq|</th>
                <th class="listheading">|.$locale->text('Folder').qq|</th>
                <th class="listheading">|.$locale->text('Filename').qq|</th>
                <td></td>
              </tr>|;

  }


  for $i (1 .. $form->{reference_rows}) {

    $checked = ($form->{"referenceconfidential_$i"}) ? "checked" : "";
    $rv .= qq|
              <tr>
                <td><input name="referencedescription_$i" size=40 value="|.$form->quote($form->{"referencedescription_$i"}).qq|"></td>
                <td><input name="referenceconfidential_$i" title="$confidential" type="checkbox" class="checkbox" value="1" $checked></td>
|;

    if ($form->{referenceurl}) {
      $rv .= qq|
                <td><input name="referencecode_$i" size=10 value="$form->{"referencecode_$i"}">|;
      if ($form->{"referencecode_$i"}) {
        $rv .= qq|
                    <a href="$form->{referenceurl}$form->{"referencecode_$i"}" target="_blank">&#9701;</a>|;
      }
    } else {
      $rv .= qq|
                <td><input name="referencefolder_$i" class="docdetails noscreen noprint" size="20" value="|.$form->quote($form->{"referencefolder_$i"}).qq|"></td>
                <td><input name="referencefilename_$i" class="docdetails noscreen noprint" size="40" value="|.$form->quote($form->{"referencefilename_$i"}).qq|"></td>
                <td>
                  <input type="hidden" name="referencecode_$i" value="$form->{"referencecode_$i"}">|;

      if ($form->{"referencearchive_id_$i"} eq '-') {
        $rv .= qq|
                  <span title="|. $locale->text('Document not archived!').qq|">&#9203;</span>|;
      } elsif ($form->{"referencearchive_id_$i"} * 1) {
        $rv .= qq|
                  <a href="rd.pl?action=download_document&login=$form->{login}&path=$form->{path}&id=$form->{"referencearchive_id_$i"}" target="_blank">&#9660;</a>|;
      } else {
        $rv .= qq|
                  <a href="rd.pl?action=upload&login=$form->{login}&path=$form->{path}&row=$i&description=|.$form->escape($form->{"referencedescription_$i"},1) . qq|" target="popup">&#9651;</a>|;
      }

      $rv .= $form->hide_form(map { "reference${_}_$i" } qw(tmpfile archive_id));
    }

    $rv .= qq|
                </td>
              </tr>
|;
  }

  $rv .= qq|
            </table>

            <script>
              const detailSwitch = document.getElementById('document-switch');
              const detailFields = document.querySelectorAll('.docdetails');
              var detailsHidden = true;

              detailSwitch.addEventListener('click', () => {
                if (detailsHidden) {
                  detailFields.forEach(field => field.classList.remove('noscreen'));
                } else {
                  detailFields.forEach(field =>  field.classList.add('noscreen'));
                }
                detailsHidden = !detailsHidden;
              });

              const dropZone = document.getElementById('drop-zone');

              dropZone.addEventListener('dragover', e => e.preventDefault());

              dropZone.addEventListener('dragenter', () => {
                dropZone.classList.remove('dnd-idle');
                dropZone.classList.add('dnd-active');
              });

              dropZone.addEventListener('dragleave', () => {
                dropZone.classList.remove('dnd-active');
                dropZone.classList.add('dnd-idle');
              });

              dropZone.addEventListener('drop', e => {
                e.preventDefault();
                var uploadFile = e.dataTransfer.files[0];|;

  if ($form->{max_upload_size}) {
    $rv .= qq|

                if (uploadFile.size / 1e+6 > $form->{max_upload_size}
                    && !confirm('|
                  . $locale->text('File is too big! Allowed are:')
                  . qq| $form->{max_upload_size} MB\\n|
                  . $locale->text('Continue?') . qq|'))
                {
                   uploadFile = null;
                }|;
  }

  $rv .= qq|

                if (uploadFile) {
                  dropZone.textContent = '|.$locale->text('Uploading ...').qq|';

                  const form = new FormData();
                  form.set('action', 'upload_file');
                  form.set('data', uploadFile);
                  form.set('login', '$form->{login}');
                  form.set('path', '$form->{path}');

                  const req = new XMLHttpRequest();
                  req.open('POST', 'api.pl');
                  req.addEventListener('load', () => {
                    const res = JSON.parse(req.responseText);
                    if (req.status === 200 && res.result == 'success') {
                      dropZone.textContent = '|.$locale->text('Finished').qq|';

                      document.getElementsByName('referencedescription_$form->{reference_rows}')[0].value
                        = res.data.description;
                      document.getElementsByName('referencefilename_$form->{reference_rows}')[0].value
                        = res.data.filename;
                      document.getElementsByName('referencetmpfile_$form->{reference_rows}')[0].value
                        = res.data.tmpfile;
                      document.getElementsByName('referencearchive_id_$form->{reference_rows}')[0].value
                        = '-';

                      doSubmit(document.querySelector('form[name="main"]'));
                    } else {
                      dropZone.textContent = '|.$locale->text('Error!').qq|';
                    }

                  });
                  req.addEventListener('error', () => { dropZone.textContent = '|.$locale->text('Error!').qq|' });

                  req.send(form);
                }

                dropZone.dispatchEvent(new Event('dragleave'));
              });
            </script>|;

  return $rv;

}


1;


=encoding utf8

=head1 NAME

bin/mozilla/cm.pl - Attach Reference Documents to transactions

=head1 DESCRIPTION

L<bin::mozilla::cm> contains functions for attach reference documents to transactions,
cms is in rd.pl and rd.pm.

=head1 FUNCTIONS

L<bin::mozilla::cm> implements the following functions:

=head2 all_references

=head2 references

=cut
