######################################################################
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#######################################################################
#
# menu for text based browsers (lynx)
#
#######################################################################

$menufile = "menu.ini";
use SL::Menu;


1;
# end of main



sub display {

  $menu = new Menu "$menufile";
  $menu->add_file("custom_$menufile") if -f "custom_$menufile";
  $menu->add_file("$form->{login}_$menufile") if -f "$form->{login}_$menufile";
  
  @menuorder = $menu->access_control(\%myconfig);

  $form->{title} = "SQL-Ledger $form->{version}";
  
  $form->header;

  $offset = int (21 - $#menuorder)/2;

  print "<pre>";
  print "\n" x $offset;
  print "</pre>";

  print qq|<center><table>|;

  map { print "<tr><td>".$menu->menuitem(\%myconfig, \%$form, $_).$locale->text($_).qq|</a></td></tr>|; } @menuorder;

  print qq'
</table>

</body>
</html>
';

}


sub section_menu {

  $menu = new Menu "$menufile", $form->{level};
  
  $menu->add_file("custom_$menufile") if -f "custom_$menufile";
  $menu->add_file("$form->{login}_$menufile") if -f "$form->{login}_$menufile";
  
  # build tiered menus
  @menuorder = $menu->access_control(\%myconfig, $form->{level});

  foreach $item (@menuorder) {
    $a = $item;
    $item =~ s/^$form->{level}--//;
    push @neworder, $a unless ($item =~ /--/);
  }
  @menuorder = @neworder;
 
  $level = $form->{level};
  $level =~ s/--/ /g;

  $form->{title} = $locale->text($level);
  
  $form->header;

  $offset = int (21 - $#menuorder)/2;
  print "<pre>";
  print "\n" x $offset;
  print "</pre>";
  
  print qq|<center><table>|;

  foreach $item (@menuorder) {
    $label = $item;
    $label =~ s/$form->{level}--//g;

    # remove target
    $menu->{$item}{target} = "";

    print "<tr><td>".$menu->menuitem(\%myconfig, \%$form, $item, $form->{level}).$locale->text($label)."</a></td></tr>";
  }
  
  print qq'</table>

</body>
</html>
';

}


sub acc_menu {
  
  &section_menu;
  
}


sub menubar {
  $menu = new Menu "$menufile", "";
  
  # build menubar
  @menuorder = $menu->access_control(\%myconfig, "");

  @neworder = ();
  map { push @neworder, $_ unless ($_ =~ /--/) } @menuorder;
  @menuorder = @neworder;

  print "<p>";
  $form->{script} = "menu.pl";

  print "| ";
  foreach $item (@menuorder) {
    $label = $item;

    # remove target
    $menu->{$item}{target} = "";

    print $menu->menuitem(\%myconfig, \%$form, $item, "").$locale->text($label)."</a> | ";
  }
  
}


