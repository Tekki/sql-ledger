#=====================================================================
# SQL-Ledger
# Copyright (c) DWS Systems Inc.
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# two frame layout with refractured menu
#
#======================================================================

$menufile = "menu.ini";
use SL::Menu;

require "$form->{path}/js.pl";

1;
# end of main


sub display {
  
  $menuwidth = ($ENV{HTTP_USER_AGENT} =~ /links/i) ? "240" : "155";
  $menuwidth = $myconfig{menuwidth} if $myconfig{menuwidth};

  $form->header;

  print qq|

<FRAMESET COLS="$menuwidth,*" BORDER="1">

  <FRAME NAME="acc_menu" SRC="$form->{script}?login=$form->{login}&action=acc_menu&path=$form->{path}&js=$form->{js}">
  <FRAME NAME="main_window" SRC="am.pl?login=$form->{login}&action=$form->{main}&path=$form->{path}">

</FRAMESET>

</BODY>
</HTML>
|;

}


sub acc_menu {

  my $menu = new Menu "$menufile";
  $menu->add_file("$form->{path}/custom/$menufile") if -f "$form->{path}/custom/$menufile";
  $menu->add_file("$form->{path}/custom/$form->{login}/$menufile") if -f "$form->{path}/custom/$form->{login}/$menufile";

  $form->{title} = $locale->text('Accounting Menu');

  $form->header;

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

<body class=menu />

<img src=$images/sql-ledger.gif width=80 border=0>

<br>$myconfig{name}
|;

  if ($form->{js}) {
    &jsmenu_frame($menu);
  } else {
    &section_menu($menu);
  }

  print qq|
</body>
</html>
|;

}


sub section_menu {
  my ($menu, $level) = @_;

  # build tiered menus
  my @menuorder = $menu->access_control(\%myconfig, $level);

  while (@menuorder) {
    $item = shift @menuorder;
    $label = $item;
    $label =~ s/$level--//g;

    my $spacer = "&nbsp;" x (($item =~ s/--/--/g) * 2);

    $label =~ s/.*--//g;
    $label = $locale->text($label);
    $label =~ s/ /&nbsp;/g if $label !~ /<img /i;

    $menu->{$item}{target} = "main_window" unless $menu->{$item}{target};
    
    if ($menu->{$item}{submenu}) {

      $menu->{$item}{$item} = !$form->{$item};

      if ($form->{level} && $item =~ $form->{level}) {

        # expand menu
	print qq|<br>\n$spacer|.$menu->menuitem(\%myconfig, \%$form, $item, $level).qq|$label</a>|;

	# remove same level items
	map { shift @menuorder } grep /^$item/, @menuorder;
	
	&section_menu($menu, $item);

	print qq|<br>\n|;

      } else {

	print qq|<br>\n$spacer|.$menu->menuitem(\%myconfig, \%$form, $item, $level).qq|$label&nbsp;...</a>|;

        # remove same level items
	map { shift @menuorder } grep /^$item/, @menuorder;

      }
      
    } else {
    
      if ($menu->{$item}{module}) {

	print qq|<br>\n$spacer|.$menu->menuitem(\%myconfig, \%$form, $item, $level).qq|$label</a>|;
	
      } else {

        $form->{tag}++;
	print qq|<a name="id$form->{tag}"></a>
	<p><b>$label</b>|;
	
	&section_menu($menu, $item);

	print qq|<br>\n|;

      }
    }
  }
}



sub jsmenu_frame {
  my ($menu, $level) = @_;

  # build tiered menus
  my @menuorder = $menu->access_control(\%myconfig, $level);

  while (@menuorder){
    $i++;
    $item = shift @menuorder;
    $label = $item;
    $label =~ s/.*--//g;
    $label = $locale->text($label);

    $menu->{$item}{target} = "main_window" unless $menu->{$item}{target};

    if ($menu->{$item}{submenu}) {
      
	$display = "display: none;" unless $level eq ' ';

	print qq|
        <div id="menu$i" class="menuOut" onclick="SwitchMenu('sub$i')" onmouseover="ChangeClass('menu$i','menuOver')" onmouseout="ChangeClass('menu$i','menuOut')">$label</div>
	<div class="submenu" id="sub$i" style="$display">|;
	
	# remove same level items
	map { shift @menuorder } grep /^$item/, @menuorder;

	&jsmenu_frame($menu, $item);
	
	print qq|
	</div>
|;

    } else {

      if ($menu->{$item}{module}) {
	if ($level eq "") {
	  print qq|<div id="menu$i" class="menuOut" onmouseover="ChangeClass('menu$i','menuOver')" onmouseout="ChangeClass('menu$i','menuOut')"> |. 
	  $menu->menuitem(\%myconfig, \%$form, $item, $level).qq|$label</a></div>|;

	  # remove same level items
	  map { shift @menuorder } grep /^$item/, @menuorder;

          &jsmenu_frame($menu, $item);

	} else {
	
	  print qq|<div class="submenu"> |.
          $menu->menuitem(\%myconfig, \%$form, $item, $level).qq|$label</a></div>|;
	}

      } else {

	$display = "display: none;" unless $item eq ' ';

	print qq|
<div id="menu$i" class="menuOut" onclick="SwitchMenu('sub$i')" onmouseover="ChangeClass('menu$i','menuOver')" onmouseout="ChangeClass('menu$i','menuOut')">$label</div>
	<div class="submenu" id="sub$i" style="$display">|;
	
	&jsmenu_frame($menu, $item);
	
	print qq|
	</div>
|;

      }

    }

  }

}


sub jsmenu {
  my ($menu, $level) = @_;
  
  # build menu_{login}.js for user
  my @menuorder = $menu->access_control(\%myconfig, $level);

  while (@menuorder){
    $item = shift @menuorder;
    $label = $item;
    $label =~ s/.*--//g;
    $label = $locale->text($label);

    if ($menu->{$item}{submenu}) {

      $form->{items} = 1;
      
      $form->{jsmenu} .= $form->{stagger};
      $form->{jsmenu} .= qq|['$label', null, null,\n|;
      
      # remove same level items
      map { shift @menuorder } grep /^$item/, @menuorder;

      $form->{stagger} .= "\t";

      &jsmenu($menu, $item);
      
      chop $form->{stagger};
      $form->{jsmenu} .= qq|$form->{stagger}],\n|;

    } else {

      if ($menu->{$item}{module}) {
	$form->{items} = 1;
	
	if ($level eq "") {

	  $menu->{$item}{jsmenu} = 1;
	  $str = $menu->menuitem(\%myconfig, \%$form, $item, $level);
	  $str =~ s/^<a href=//;
	  $str =~ s/>$//;

          $form->{jsmenu} .= $form->{stagger};
	  $form->{jsmenu} .= qq|['$label', '$str'],\n|;
	  
	  # remove same level items
	  map { shift @menuorder } grep /^$item/, @menuorder;

          &jsmenu($menu, $item);

	  $form->{jsmenu} .= qq|$form->{stagger}],\n|;
	  
	} else {
	
	  $menu->{$item}{jsmenu} = 1;
	  $str = $menu->menuitem(\%myconfig, \%$form, $item, $level);
	  $str =~ s/^<a href=//;
	  $str =~ s/>$//;
          $form->{jsmenu} .= $form->{stagger};
	  $form->{jsmenu} .= qq|['$label', '$str'],\n|;

	}

      } else {

        $form->{jsmenu} .= $form->{stagger};
	$form->{jsmenu} .= qq|['$label', null, null,\n|;
	$form->{stagger} .= "\t";
        
	&jsmenu($menu, $item);

	chop $form->{stagger};
        if ($form->{items}) {
	  $form->{jsmenu} .= qq|$form->{stagger}],\n|;
	} else {
	  $form->{jsmenu} =~ s/\t??\['$label', null, null,\s*$//;
	}
	$form->{items} = 0;
      }

    }

  }

}


sub menubar {

  1;

}


