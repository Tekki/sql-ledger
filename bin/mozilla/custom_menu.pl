######### SSB

sub acc_menu {

  if ($myconfig{role} eq 'timesheet') {
    $menufile = "timesheet.ini";
  }
  
  my $menu = new Menu "$menufile";
  $menu->add_file("custom_$menufile") if -f "custom_$menufile";
  $menu->add_file("$form->{login}_$menufile") if -f "$form->{login}_$menufile";
  
  $form->{title} = $locale->text('Accounting Menu');

  $form->header;
  
 $namegif="$images/$myconfig{dbname}.gif";                                                                  
  if(-e $namegif) {                                                                                          
    $namegif = $namegif;                                                                                       
      } else {                                                                                                   
          $namegif = "$images/sql-ledger.gif";                                                                     
	      } 

  print qq|
<script type="text/javascript">
function SwitchMenu(obj) {
  if (document.getElementById) {
    var el = document.getElementById(obj);

    if (el.style.display == "none") {
      el.style.display = "block"; //display the block of info
    } else {
      el.style.display = "none";
    }
  }
}

function ChangeClass(menu, newClass) {
  if (document.getElementById) {
    document.getElementById(menu).className = newClass;
  }
}
document.onselectstart = new Function("return false");
</script>

<body class=menu>

<img src=$namegif width=80 border=0>
|;

  if ($myconfig{role} eq 'timesheet') {
    &section_menu($menu);
  } else {
    if ($form->{js}) {
      &js_menu($menu);
    } else {
      &section_menu($menu);
    }
  }

  print qq|
</body>
</html>
|;

}


1;

