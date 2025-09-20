#! /usr/bin/env perl

use v5.40;
use open ':std', OUT => ':encoding(utf8)';

use FindBin;
use Mojo::File 'path';
use Print::Colored ':all';
use Template;
use YAML::PP 'LoadFile';

chdir $FindBin::Bin;

# config

my $config_file = 'template-config.yml';
die color_error 'Config file not found!' unless -f $config_file;

my %config = LoadFile($config_file)->%*;

my $source = $config{source};
die color_error "$source: Source folder not found!" unless -d $source;

my $templates = '../../templates';

my @all_names = sort keys $config{datasets}->%*;
push @all_names, color_warn 'all';

while (1) {

  # select datasets

  say "\nAvailable datasets:";

  for my ($i, $label) (%all_names[0..$#all_names]) {
    printf "%2d: %s\n", $i+1, $label;
  }

  my $selection = prompt_input 'Generate templates for: ' or last;

  my @selected
    = $selection == @all_names ? @all_names[0 .. $#all_names - 1] : $all_names[$selection - 1];

  # loop over selected names

  for my $name (@selected) {
    say "\n$name:";

    # loop over languages

    for my $lang (sort keys $config{datasets}{$name}->%*) {
      say "  $lang:";

      # paths

      my $path        = $lang eq 'default' ? '' : "/$lang";
      my $source_path = path("$source$path");
      my $target_path = path("$templates/$name$path")->make_path;
      chown $config{www_user_id}, $config{www_group_id}, $target_path;

      # configuration variables

      my $lang_config = $config{datasets}{$name}{$lang};

      unless (ref $lang_config) {
        if ($config{datasets}{$name}{$lang_config}) {
          my $ref_path = $lang_config eq 'default' ? '' : "/$lang_config";
          $source_path = path("$source$ref_path");

          $lang_config = $config{datasets}{$name}{$lang_config};
        } else {
          say color_error 'error';
          die "$name.$lang_config: config not found";
        }
      }

      # copy includes

      for my $file ($config{includes}->@*) {
        $file .= '.tex' unless $file =~ /\.\w+$/;
        printf '    %-24s ... ', $file;

        try {
          path("$source_path/$file")->copy_to($target_path);
          chown $config{www_user_id}, $config{www_group_id}, "$target_path/$file";
        } catch ($e) {
          say color_error 'error';
          die $e;
        }

        say_ok 'ok';
      }

      # process templates

      my $parsed;
      my $tt = Template->new({ENCODING => 'utf8', OUTPUT => \$parsed,});

      for my ($file, $vars) ($lang_config->%*) {
        $file .= '.tex' unless $file =~ /\.\w+$/;
        printf '    %-24s ... ', $file;

        try {
          $parsed = '';
          $tt->process("$source_path/$file", $vars);
          path("$target_path/$file")->spew($parsed, 'UTF-8');
          chown $config{www_user_id}, $config{www_group_id}, "$target_path/$file";
        } catch ($e) {
          say color_error 'error';
          die $e;
        }

        say_ok 'ok';
      }
    }
  }

  last if $selection == @all_names;
}
