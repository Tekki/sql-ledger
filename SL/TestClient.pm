use v5.40;
use feature 'class';
no warnings 'experimental::class';

class SL::TestClient {
  use HTML::Form;
  use Mojo::File 'path';
  use Mojo::Util qw|decode html_unescape url_escape url_unescape|;
  # use Mojo::Transaction::HTTP::Role::Mechanize;
  use Scalar::Util 'looks_like_number';
  use Test::Mojo;
  use Test::More;
  use Time::Piece;
  use Time::Seconds;
  use YAML::PP;

  field $config :reader;
  field $configfile :param;
  field $connected;
  field %form_params :reader = ();
  field $form_script :reader = '';
  field $last_download;
  field %mimetypes = (
    gz   => 'application/x-gzip',
    html => 'text/html',
    pdf  => 'application/pdf',
    txt  => 'text/plain',
    xlsx => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  field $mj :reader;
  field $password;
  field $test_output;
  field $token;
  field %store :reader;
  field $url;
  field $username;
  field $yp;

  ADJUST {
    $mj = Test::Mojo->new;
    $yp = YAML::PP->new;

    if (-f $configfile) {
      $config = $yp->load_file($configfile);
    } else {
      BAIL_OUT 'Config file not found.';
    }
  };

  method api_login_ok () {
    BAIL_OUT 'Not connected.' unless $connected;

    $self->post_ok('[API login]', 'api.pl', action => 'get_token', password => $password);

    $token = $self->json->{token} or BAIL_OUT $self->body;

    return $self;
  }

  method body () {
    return $mj->tx->res->body;
  }

  method connect_ok ($admin = 0) {
    $connected = 0;

    my $config_ok = $config->{server} && $config->{server}{url};
    if ($admin) {
      $config_ok &&= $config->{server}{adminpassword};
    } else {
       $config_ok &&= $config->{server}{$_} for qw|username password|;
    }

    if ($config_ok) {
      try {
        my $res = $mj->ua->get("$config->{server}{url}/login.pl")->result;
        if ($res->is_success) {
          if ($admin) {
            ($url, $password) = $config->{server}->@{'url', 'adminpassword'};
            $username = 'root login';
          } else {
            ($url, $username, $password) = $config->{server}->@{'url', 'username', 'password'};
          }

          $connected = 1;
          pass "Connect to $url";
        } else {
          BAIL_OUT $res->message;
        }
      } catch ($e) {
        BAIL_OUT $e;
      }
    } else {
      BAIL_OUT 'Config parameters missing.';
    }

    return $self;
  }

  method date_dec31 () {
    return localtime->strftime('%Y1231');
  }

  method date_jan1 () {
    my $time = localtime;
    $time -= ONE_YEAR if $time->mon < 4;
    return $time->strftime('%Y0101');
  }

  method date_today () {
    return localtime->strftime('%Y%m%d');
  }

  method date_tomorrow () {
    ((localtime) + ONE_DAY)->strftime('%Y%m%d');
  }

  method date_yesterday () {
    ((localtime) - ONE_DAY)->strftime('%Y%m%d');
  }

  method dom () {
    return $mj->tx->res->dom;
  }

  method download_is ($label, $type) {
    my %types = (
      pdf  => 'PDF document',
      xlsx => 'Microsoft Excel 2007',
    );

    if ($last_download && -f $last_download) {
      if ($types{$type}) {
        my $test = "$label: type $type";
        if (`file '$last_download'` =~ $types{$type}) {
          pass $test;
        } else {
          fail $test;
        }
      } else {
        fail "$label: test for '$type' available";
      }
    } else {
      fail "$label: download available";
    }
  }

  method download_ok ($label, $type, $button) {
    BAIL_OUT 'Not connected.' unless $connected;

    my %params = %form_params;
    $params{login} ||= $username;
    $params{path}  ||= 'bin/mozilla';
    $params{action} = $button;

    subtest "$label, download file" => sub {
      $last_download = '';

      my $uri = "$url/$form_script";
      $mj->post_ok($uri, $self->headers($uri), form => \%params)
        ->status_is(200, "$label: status ok")
        ->header_is('Content-Type' => $mimetypes{$type}, "$label: response is $type")
        ->or(sub { $self->_register_problems('error'); $self-&_register_problems('warn'); });

      $self->_download_file($label);
    };

    return $self;
  }

  method elements_exist ($label, @selectors) {
    subtest "$label: check elements" => sub {
      $mj->element_exists($_, "Element '$_'") for @selectors;
    };

    return $self;
  }

  method follow_link_ok ($label, $selector, $i = 1) {
    subtest "$label: follow link $selector no. $i" => sub {
      my $links = $self->dom->find("a.$selector");

      if (my $link = $links->[$i -1 ]) {
        $self->get_ok("$label: follow link", $link->attr('href'));
      } else {
        fail "Find link $selector no. $i";
      }
    };

    return $self;
  }

  method form_exists () {
    subtest 'Form exists' => sub {
      $self->elements_exist('form', 'input[type=submit]');
    };

    return $self;
  }

  method form_fields_exist (@names) {
    subtest 'Visible form fields' => sub {
      for (@names) {
        $mj->element_exists(qq|select[name=$_], input[name=$_]:not([type=hidden])|,
          "Form field '$_'");
      }
    };

    return $self;
  }

  method form_hidden_exist (@names) {
    subtest 'Hidden form fields' => sub {
      for (@names) {
        $mj->element_exists(qq|input[name=$_][type=hidden]|, "Hidden form field '$_'");
      }
    };

    return $self;
  }

  method get_ok ($label, $path, %params) {
    BAIL_OUT 'Not connected.' unless $connected;

    $path = $self->_build_path($path, %params);

    subtest "$label, GET request" => sub {
      my $uri = "$url/$path";
      $mj->get_ok($uri, $self->headers($uri))
        ->status_is(200, "$label: status ok")
        ->element_exists_not('h2.error', "$label: no error")
        ->or(sub { $self->_register_problems('error') })
        ->element_exists_not('b.warn', "$label: no warnings")
        ->or(sub { $self->_register_problems('warn') });
    };

    $self->set_form;

    return $self;
  }

  method headers ($uri) {
    my %headers = (REFERER => $uri);
    if ($token) {
      $headers{'SL-Token'} = $token;
    }

    return \%headers;
  }

  method json () {
    return $mj->tx->res->json;
  }

  method params_are ($label, %params) {
    subtest "$label: check params" => sub {
      for my ($key, $value) (%params) {
        my $expected = ref $value ? $store{$$value} : $value;
        ok exists($form_params{$key}), "$key exists"
          and is $form_params{$key}, $expected, "$key is '$expected'";
      }
    };

    return $self;
  }

  method post_ok ($label, $path = $form_script, %params) {
    BAIL_OUT 'Not connected.' unless $connected;

    %params = %form_params unless (%params);

    $params{login} ||= $username unless $username eq 'root login';
    $params{path}  ||= 'bin/mozilla';

    subtest "$label, POST request" => sub {
      my $uri = "$url/$path";
      $mj->post_ok($uri, $self->headers($uri), form => \%params)
        ->status_is(200, "$label: status ok")
        ->element_exists_not('h2.error', "$label: no error")
        ->or(sub { $self->_register_problems('error') })
        ->element_exists_not('b.warn', "$label: no warnings")
        ->or(sub { $self->_register_problems('warn') });
    };

    $self->set_form;

    return $self;
  }

  method press_button_ok ($label, $button) {
    subtest "$label: press button $button" => sub {
      $self->set_action_ok($button)->post_ok($label);
    };

    return $self;
  }

  method remove_locks_ok () {
    subtest 'Remove locks' => sub {
      $self->get_ok('Clear semaphores', 'am.pl', action => 'clear_semaphores')
        ->press_button_ok('Confirm', 'yes');
    };
  }

  method set_action_ok ($action_parameter) {
    $form_params{action} = $action_parameter;
    pass "Set action to '$action_parameter'";

    return $self;
  }

  method set_form ($tx = $mj->tx) {
    my @res_forms
      = HTML::Form->parse(decode('UTF-8', $tx->res->to_string), $tx->req->url->to_string);

    # my $res_forms = $tx->with_roles('+Mechanize')->extract_forms;

    # if ($res_forms->size) {
    #   $form_script = $res_forms->first->attr('action') =~ s~$url/~~r;
    #   %form_params = $res_forms->first->val->%*;
    if (@res_forms) {
      $form_script = $res_forms[0]->action =~ s~$url/~~r;
      %form_params = $res_forms[0]->form;

      $self->dom->at('form')->find('input[type=checkbox]')->each(
        sub ($el, $i) {
          $form_params{$el->attr('name')} //= '';
        }
      );
    } else {
      $form_script = '';
      %form_params = ();
    }

    return $self;
  }

  method set_params_ok ($label, %new_params) {
    my @failed;

    for my ($key, $value) (%new_params) {
      if (exists $form_params{$key}) {
        $form_params{$key} =  ref $value ? $store{$$value} : $value;
      } else {
        push @failed, $key;
      }
    }

    if (@failed) {
      fail "$label: set " . join ', ', @failed;
    } else {
      pass "$label: set " . join ', ', sort keys %new_params;
    }

    return $self;
  }

  method store_ok (@params) {
    for my $param (@params) {
      if (exists $form_params{$param}) {
        $store{$param} = $form_params{$param};
        pass "Retrieve and store $param";
      } else {
        fail "Retrieve $param";
      }
    }

    return $self;
  }

  method test_stamp () {
    return $store{test_stamp} = localtime->strftime('Live Test %Y-%m-%d %H:%M:%S');
  }

  method texts_are ($label, %texts) {
    subtest "$label: check texts" => sub {
      for my ($selector, $text) (%texts) {
        my $expected = ref $text ? $store{$$text} : $text;
        is $self->dom->at($selector)->text, $expected, "$selector is '$expected'";
      }
    };

    return $self;
  }

  method update_row_ok ($label, $counter, %params) {
    subtest "$label" => sub {
      if (my $i = looks_like_number $counter ? $counter : $form_params{$counter}) {
        my %new_row;
        for my ($key, $value) (%params) {
          $new_row{"${key}_$i"} = $value;
        }
        $self->set_params_ok($label, %new_row)->set_action_ok('update')->post_ok('Update');

      } else {
        fail "$label: update row $counter";
      }

    };
  }

  method user_login_ok () {
    BAIL_OUT 'Not connected.' unless $connected;

    return $self->post_ok('[Login]', 'login.pl', action => 'login', password => $password);
  }

  method DESTROY () {
    if ($test_output && $config->{output}) {
      $yp->dump_file($config->{output}, $test_output);
    }
  }

  # internal methods

  method _build_path ($path, %params) {
    if (%params) {
      my @elements;

      for my ($key, $value) (%params) {
        push @elements, url_escape($key) . '=' . url_escape($value // '');
      }
      push @elements, "login=$username" unless $params{login} || $username eq 'root login';
      push @elements, 'path=bin/mozilla' unless $params{path};

      $path .= '?' . join('&', @elements);
    }

    return $path;
  }

  method _download_file ($label) {
    if ( $mj->header_like('Content-Disposition' => qr/attachment/, "$label: Attachment header")
      && $mj->success)
    {
      if ($config->{downloads}) {
        if (-d $config->{downloads}) {
          my $content_disposition = $mj->tx->res->headers->content_disposition;

          my $filename;
          if ($content_disposition =~ /filename\*=UTF-8''(.+)/) {
            $filename = decode 'UTF-8', url_unescape $1;
          } else {
            ($filename) = $content_disposition =~ /filename=(.+)/;
          }
          $filename =~ s/^\d+_//;

          my $download_file
            = path($config->{downloads})->child(localtime->strftime("%Y-%m-%d-%H%M%S_$filename"));

          $mj->tx->result->save_to($download_file);
          $last_download = $download_file;
          pass "$label: download to $config->{downloads}";
        } else {
          BAIL_OUT "$config->{downloads}: not found";
        }
      } else {
        BAIL_OUT 'Download folder not configured';
      }
    } else {
      fail "$label: download file available";
    }
  }

  method _register_problems ($type) {
    my $outputfile = $config->{output};

    if ($outputfile) {
      $test_output ||= -f $outputfile ? $yp->load_file($outputfile) : {};

      $self->dom->find("b.$type")->each(
        sub ($el, $i) {
          my ($msg, $file, $line) = $el->content =~ /(.+) at (\S+) line (\d+)/m;
          if ($msg && $file && $line) {
            $msg =~ s/<br>/\n/g;
            $test_output->{$type}{$file}{sprintf '% 5u', $line} ||= html_unescape $msg;
          }
        }
      );
    }
  }
}

1;
