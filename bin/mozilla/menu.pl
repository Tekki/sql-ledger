#======================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# two frame layout with refractured menu
#
#======================================================================

$menufile = "menu.ini";
use SL::Menu;
use SL::AM;

require "$form->{path}/js.pl";

1;
# end of main

sub _h {
  my ($s) = @_;
  $s = '' if !defined $s;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/>/&gt;/g;
  $s =~ s/"/&quot;/g;
  return $s;
}


sub menu_env_html {
  my ($form, $locale, $myconfig) = @_;

  my $env = $form->environment // '';

  my %env_label = (
    dev  => $locale->text('Development Environment'),
    test => $locale->text('Test Environment'),
  );

  my $env_txt = _h($env_label{$env} // '');

  my $company_raw = $form->{company} // $myconfig->{company} // $myconfig->{dbname} // '';
  my $company = _h($company_raw);
  my $user    = _h($myconfig->{name}  // '');
  my $db      = _h($myconfig->{dbname} // '');

  my $u = _h($locale->text('User'));
  my $d = _h($locale->text('Dataset'));

  my $html = qq|<div class="menu-env">|;
  $html   .= qq|<div class="menu-env-line menu-env-line--env">$env_txt</div>| if $env_txt ne '';
  $html   .= qq|<div class="menu-env-line"><b>$company</b></div>| if $company ne '';
  $html   .= qq|<div class="menu-env-line">$u: <b>$user</b></div>| if $user ne '';
  $html   .= qq|<div class="menu-env-line">$d: <b>$db</b></div>| if $db ne '';
  $html   .= qq|</div>|;

  return $html;
}


sub display {
  $form->{js} = 1 if !defined($form->{js}) || $form->{js} eq '';

  $menuwidth = $myconfig{menuwidth} || 275;
  $menuwidth = '25%' if $form->{small_device};
  $script = $form->{main} =~ /recent/ ? 'ru.pl' : 'am.pl';

  my $menu_css_width = $menuwidth;
  $menu_css_width .= 'px' if $menu_css_width =~ /^\d+$/;

  $form->header;

print qq|

<body class="app" style="--menu-width: $menu_css_width;">
  <div id="menu_frames" class="app-frames">

    <div class="app-pane app-pane--menu">
      <iframe
        id="acc_menu"
        class="app-menu"
        name="acc_menu"
        src="$form->{script}?login=$form->{login}&action=acc_menu&path=$form->{path}&js=$form->{js}"
        title="Menu"
        loading="eager"></iframe>
    </div>

    <div class="app-pane app-pane--main">
      <iframe
        id="main_window"
        class="app-main"
        name="main_window"
        src="$script?login=$form->{login}&action=$form->{main}&path=$form->{path}"
        title="Main"
        loading="eager"></iframe>
    </div>

  </div>
</body>
</html>
|;

}


sub acc_menu {
  $form->{js} = 1 if !defined($form->{js}) || $form->{js} eq '';

  if (!defined $form->{company}) {
    eval { SL::AM->company_defaults(\%myconfig, $form); 1 };
  }

  my $menu = SL::Menu->new("$menufile");
  $menu->add_file("$form->{path}/custom/$menufile") if -f "$form->{path}/custom/$menufile";
  $menu->add_file("$form->{path}/custom/$form->{login}/$menufile") if -f "$form->{path}/custom/$form->{login}/$menufile";

  $form->{title} = $locale->text('Accounting Menu');

  $form->header;

  my $body_class = $form->{js} ? 'menu menu--js' : 'menu';

  my $js_src = '/js/menu-frame.js';
  if (my $sn = $ENV{SCRIPT_NAME}) {
    if ($sn =~ m{^(.*)/bin/mozilla/[^/]+$}) {
      $js_src = "$1/js/menu-frame.js";
    }
  }
  my $js_src_html = $js_src;
  $js_src_html =~ s/&/&amp;/g;
  $js_src_html =~ s/"/&quot;/g;
  $js_src_html =~ s/</&lt;/g;
  $js_src_html =~ s/>/&gt;/g;

  my $env_html = menu_env_html($form, $locale, \%myconfig);

  print qq|
<body class="$body_class">
  <header class="menu-headerbar">
    $env_html
  </header>
  <nav aria-label="Menu">
|;

  if ($form->{js}) {
    my $state = { i => 0, root_actions => [] };
    jsmenu_frame($menu, undef, $state);

    if (@{ $state->{root_actions} || [] }) {
      print qq|\n<div class="menu-root-actions" role="group" aria-label="Actions">\n|;
      print join('', @{ $state->{root_actions} });
      print qq|</div>\n|;
    }
  } else {
    &section_menu($menu);
  }

  print qq|
  </nav>
|;

  print qq|  <script src="$js_src_html" defer></script>\n| if $form->{js};

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
        print qq|<br>\n$spacer|.$menu->menuitem(\%myconfig, $form, $item, $level).qq|$label</a>|;

        # remove same level items
        map { shift @menuorder } grep /^$item/, @menuorder;

        &section_menu($menu, $item);

        print qq|<br>\n|;

      } else {

        print qq|<br>\n$spacer|.$menu->menuitem(\%myconfig, $form, $item, $level).qq|$label&nbsp;...</a>|;

        # remove same level items
        map { shift @menuorder } grep /^$item/, @menuorder;

      }

    } else {

      if ($menu->{$item}{module}) {

        print qq|<br>\n$spacer|.$menu->menuitem(\%myconfig, $form, $item, $level).qq|$label</a>|;

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
  my ($menu, $level, $state) = @_;
  $state //= { i => 0, root_actions => [] };
  $state->{root_actions} //= [];

  my @menuorder = $menu->access_control(\%myconfig, $level);

  while (@menuorder) {
    $state->{i}++;
    my $i    = $state->{i};
    my $item = shift @menuorder;

    (my $label = $item) =~ s/.*--//g;
    $label = $locale->text($label);
    my $label_html = ($label =~ /<img\b/i) ? $label : _h($label);

    $menu->{$item}{target} = "main_window" unless $menu->{$item}{target};

    my $is_leaf = ($menu->{$item}{module} || $menu->{$item}{href}) && !$menu->{$item}{submenu};

    if (!$is_leaf) {
      my $subid = "sub$i";

      print qq|
<button type="button"
        class="menu-header"
        data-menu-toggle="$subid"
        aria-controls="$subid"
        aria-expanded="false">$label_html</button>
<div class="submenu" id="$subid">|;

      map { shift @menuorder } grep /^\Q$item\E--/, @menuorder;

      jsmenu_frame($menu, $item, $state);

      print qq|
</div>
|;

    } else {
      my $is_root = (!defined($level) || $level eq '');
      my $t       = $menu->{$item}{target} // '';
      my $m       = $menu->{$item}{module} // '';
      my $act     = $menu->{$item}{action} // '';
      my $is_root_action = $is_root && (
        $t =~ /^_(?:blank|top)$/i
        || ($m eq 'login.pl' && $act eq 'logout')
      );

      my $a = $menu->menuitem(\%myconfig, $form, $item, $level);
      $a =~ s/^<a\b/<a class="menu-link"/;

      my $cls = 'menu-item';
      $cls .= ' menu-item--root' if $is_root;

      my $html = qq|<div class="$cls">$a$label_html</a></div>\n|;

      if ($is_root_action) {
        push @{ $state->{root_actions} }, $html;
      } else {
        print $html;
      }
    }
  }
}


sub jsmenu {
  my ($menu, $level) = @_;

  # Legacy JS menu generator (menu_{login}.js) is deprecated.
  # By default it is disabled. Enable ONLY for debugging/compatibility:
  #   SetEnv SQLLEDGER_ALLOW_LEGACY_JSMENU 1   (Apache)
  # or export SQLLEDGER_ALLOW_LEGACY_JSMENU=1 for the CGI environment.
  if (!$ENV{SQLLEDGER_ALLOW_LEGACY_JSMENU}) {
    $form->{items}   = 0;
    $form->{stagger} = '';
    $form->{jsmenu}  = '';   # empty payload; wrapper output remains valid
    return;
  }

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
          $str = $menu->menuitem(\%myconfig, $form, $item, $level);
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
          $str = $menu->menuitem(\%myconfig, $form, $item, $level);
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

=encoding utf8

=head1 NAME

bin/mozilla/menu.pl - Two frame layout with refractured menu

=head1 DESCRIPTION

L<bin::mozilla::menu> contains functions for two frame layout with refractured menu.

=head1 DEPENDENCIES

L<bin::mozilla::menu>

=over

=item * uses
L<SL::Menu>

=item * requires
L<bin::mozilla::js>

=back

=head1 FUNCTIONS

L<bin::mozilla::menu> implements the following functions:

=head2 acc_menu

=head2 display

=head2 jsmenu

  &jsmenu($menu, $level);

=head2 jsmenu_frame

  &jsmenu_frame($menu, $level);

=head2 menubar

=head2 section_menu

  &section_menu($menu, $level);

=cut
