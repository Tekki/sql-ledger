#=====================================================================
# SQL-Ledger ERP
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#=====================================================================
#
# routines to create Javascript functions
#
#=====================================================================


sub change_report {
  my ($form, $input, $checked, $radio) = @_;

  print qq|
<script language="javascript">
<!--

function ChangeReport() {

  var frm = document.forms[0];

|;

  for (@{$input}, @{$checked}, keys %{$radio}) {
    print qq|  var $_ = new Array();\n|;
  }

  print "\n";

  for (@{$input}, @{$checked}, keys %{$radio}) {
    print qq|  ${_}[0] = "$form->{$_}";\n|;
  }

  my $i = 1;
  my $item;
  my $found;
  my %column_index;
  
  for my $ref (@{ $form->{all_report} }) {
    for (@{$input}, @{$checked}) {
      print qq|  ${_}[$i] = "$form->{all_reportvars}{$ref->{reportid}}{"report_$_"}";\n|;
    }
    for $item (keys %{$radio}) {
      $found = 0;
      for (keys %{ $radio->{$item} }) {
	if ($form->{all_reportvars}{$ref->{reportid}}{"report_$item"} eq $_) {
	  print qq|  ${item}\[$i\] = "$radio->{$item}{$_}";\n|;
	  $found = 1;
	}
      }
      if (!$found) {
	print qq|  ${item}\[$i\] = "0";\n|;
      }
    }
    print "\n";
    
    %column_index = split /[,=]/, $form->{all_reportvars}{$ref->{reportid}}{report_column_index};
    for (@{$checked}) {
      $s = $_;
      $s =~ s/l_//;
      if (exists $column_index{$s}) {
	print qq|  ${_}[$i] = "1";\n|;
      }
    }
    $i++;
  }

  print qq|
  var e = frm.report;
  var v = e.options.selectedIndex;

|;

  for (@{$input}) {
    print qq|  frm.${_}.value = ${_}[v];\n|;
  }

  for (@{$checked}) {
    print qq|  frm.${_}.checked = ${_}[v];\n|;
  }

  for (keys %{$radio}) {
    print qq|  frm.${_}[${_}[v]].checked = true;\n|;
  }

  print qq|

}
// -->
</script>
|;

}


sub check_all {
  my ($checkbox, $match) = @_;

  print qq|
<script language="javascript">
<!--

function CheckAll() {

  var frm = document.forms[0]
  var el = frm.elements
  var re = /$match/;

  for (i = 0; i < el.length; i++) {
    if (el[i].type == 'checkbox' && re.test(el[i].name)) {
      el[i].checked = frm.${checkbox}.checked
    }
  }
}

// -->
</script>
|;

}


sub resize {
  my ($width, $height) = @_;

  $width ||= 600;
  $height ||= 600;
  
  print qq|
<script language="javascript" type="text/javascript">
<!--
self.resizeTo($width,$height);
//-->
</script>
|;

}


sub calendar {
  
print qq|
  <script language="javascript" src="js/calendar.js"></script>
  <link rel="stylesheet" href="css/calendar.css">

  <script language="javascript" type="text/javascript">
  <!--
  var A_TCALDEF = {
    'months' : ['|
    .$locale->text('January').qq|', '|
    .$locale->text('February').qq|', '|
    .$locale->text('March').qq|', '|
    .$locale->text('April').qq|', '|
    .$locale->text('May').qq|', '|
    .$locale->text('June').qq|', '|
    .$locale->text('July').qq|', '|
    .$locale->text('August').qq|', '|
    .$locale->text('September').qq|', '|
    .$locale->text('October').qq|', '|
    .$locale->text('November').qq|', '|
    .$locale->text('December').qq|'],
    'weekdays' : ['|
    .$locale->text('Su').qq|', '|
    .$locale->text('Mo').qq|', '|
    .$locale->text('Tu').qq|', '|
    .$locale->text('We').qq|', '|
    .$locale->text('Th').qq|', '|
    .$locale->text('Fr').qq|', '|
    .$locale->text('Sa').qq|'],
    'yearscroll': true, // show year scroller
    'weekstart': 0, // first day of week: 0-Su or 1-Mo
    'centyear'  : 70, // 2 digit years less than 'centyear' are in 20xx, othewise in 19xx.
    'imgpath' : 'images/' // directory with calendar images
  }
|;

print q|
  // date parsing function
  function f_tcalParseDate (s_date) {|;
  
if ($myconfig{dateformat} =~ /^mm/i) {
  print q|
    var re_date = /^\s*(\d{1,2})\W(\d{1,2})\W(\d{2,4})\s*$/;|
}
if ($myconfig{dateformat} =~ /^yy/i) {
  print q|
    var re_date = /^\s*(\d{2,4})\W(\d{1,2})\W(\d{1,2})\s*$/;|
}

print q|
    if (!re_date.exec(s_date))
    return alert ("|
    .$locale->text('Invalid date:').q| '" + s_date + "'.\n|
    .$locale->text('Accepted format is').qq| $myconfig{dateformat}")|;

if ($myconfig{dateformat} =~ /^yy/i) {
print q|
    var n_day = Number(RegExp.$3),
	n_month = Number(RegExp.$2),
	n_year = Number(RegExp.$1);
|;
} elsif ($myconfig{dateformat} =~ /^dd/i) {
print q|
    var n_day = Number(RegExp.$1),
	n_month = Number(RegExp.$2),
	n_year = Number(RegExp.$3);
|;
} else {
print q|
    var n_day = Number(RegExp.$2),
	n_month = Number(RegExp.$1),
	n_year = Number(RegExp.$3);
|;
}

print q|
  if (n_year < 100)
    n_year += (n_year < this.a_tpl.centyear ? 2000 : 1900);
    if (n_month < 1 \|\| n_month > 12)
      return alert ("|
      .$locale->text('Invalid month:').q| '" + n_month + "'.\n|
      .$locale->text('Allowed range is').q| 01-12'");
    var d_numdays = new Date(n_year, n_month, 0);
    if (n_day > d_numdays.getDate())
    return alert("|
    .$locale->text('Invalid day:').q| '" + n_day + "'.\n|
    .$locale->text('Allowed range for selected month is').q| 01 - " + d_numdays.getDate() + ".");
    return new Date (n_year, n_month - 1, n_day);
}
|;

$spc = $myconfig{dateformat};
$spc =~ s/\w//g;
$spc = substr($spc, 0, 1);
if ($myconfig{dateformat} =~ /^yy/i) {
print qq|
function f_tcalGenerDate (d_date) {
  return (
    d_date.getFullYear() + "$spc"
    + (d_date.getMonth() < 9 ? '0' : '') + (d_date.getMonth() + 1) + "$spc"
    + (d_date.getDate() < 10 ? '0' : '') + d_date.getDate()
    );
}
|;
} elsif ($myconfig{dateformat} =~ /^dd/i) {
print qq|
function f_tcalGenerDate (d_date) {
  return (
    (d_date.getDate() < 10 ? '0' : '') + d_date.getDate() + "$spc"
    + (d_date.getMonth() < 9 ? '0' : '') + (d_date.getMonth() + 1) + "$spc"
    + d_date.getFullYear()
    );
}
|;
} else {
print qq|
function f_tcalGenerDate (d_date) {
  return (
    (d_date.getMonth() < 9 ? '0' : '') + (d_date.getMonth() + 1) + "$spc"
    + (d_date.getDate() < 10 ? '0' : '') + d_date.getDate() + "$spc"
    + d_date.getFullYear()
    );
}
|;
}

print q|
// End -->
</script>
|;
}


sub js_calendar {
  my ($formname, $date) = @_;

  $_ = qq|
  <script language="javascript">
  new tcal ({
    'formname': '$formname',
    'controlname': '$date'
  });
  </script>
  |;

}


sub pickvalue {

  print qq|
<script language="javascript" type="text/javascript">
<!--

  function pickvalue(v,a){
    el = eval("window.opener.document.forms[0]." + v);
    el.value=a;
    return;
  }
//-->
</script>
|;

}


sub clock {

  my @gmt = gmtime;
  my @lct = localtime;
  
  my $tz = ((24 - $lct[2]) + $gmt[2]) * -1;
  
print qq|
<script type="text/javascript">
function jsClock() {
  var TimezoneOffset = $tz;
  var localTime = new Date();
  var ms = localTime.getTime() + (localTime.getTimezoneOffset() * 60000) + TimezoneOffset * 3600000;
  var time =  new Date(ms) ;
  var hour = time.getHours();
  var minute = time.getMinutes();
  var second = time.getSeconds();
  var temp = "" + hour;
  if(hour==0) temp = "12";
  if(temp.length==1) temp = " " + temp;
  temp += ((minute < 10) ? ":0" : ":") + minute;
  temp += ((second < 10) ? ":0" : ":") + second;
  document.getElementById("clock").innerHTML = temp;
  setTimeout("jsClock()",1000);
}
</script>
|;

}

1;

