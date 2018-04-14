#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2018
#
#  Author: Tekki
#     Web: https://tekki.ch
#
#======================================================================
#
# HTML Tag Helpers
#
#======================================================================

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

package TagHelpers;

# constructor

sub new ($class, $myconfig, $form) {
  my $self = {data => [], form => $form, methods => [], myconfig => $myconfig,};

  return bless $self, $class;
}

# methods

sub callback ($self, @fields) {
  $self->{callback} = \@fields;
  return $self;
}

sub customer_link ($self, $id_field, $content) {
  my $href =
    $self->_build_link(qq|'ct.pl?db=customer&action=edit&id=' + $$id_field|);
  my $text = $self->_text($content);
  my $rv   = qq|<a v-bind:href="$href">$text</a>|;
  return $rv;
}

sub end_body ($self) {
  my $myconfig = $self->{myconfig};
  my $form     = $self->{form};

  my $myconfig_json = qq| {
      dateformat: "$myconfig->{dateformat}",
      numberformat: "$myconfig->{numberformat}"
    }|;

  my $form_json = $self->_indent(6, $self->{form}->as_json(1));

  # callback and currentURL
  my $callback_fn = '';
  my $url_fn;
  if (my $callback_fields = $self->{callback}) {
    $url_fn =
        qq|'$form->{script}?path=$form->{path}' + |
      . join(' + ', map { qq|'&$_=' + this.form.$_| } @$callback_fields)
      . qq| + '&login=$form->{login}&js=$form->{js}'|;
    $callback_fn = qq| else {
        rv = '&callback=' + encodeURIComponent(
          $url_fn
        );
      }|;
  } else {
    $url_fn =
qq|'$form->{script}?path=$form->{path}' + '&login=$form->{login}&js=$form->{js}'|;
  }

  # data
  my $data_string = '';
  if (@{$self->{data}}) {
    $data_string =
      "\n" . $self->_indent(4, join ",\n", @{$self->{data}}) . ",";
  }

  # methods
  my $method_string = '';
  if (@{$self->{methods}}) {
    $method_string =
      "\n" . $self->_indent(4, join ",\n", @{$self->{methods}}) . "\n  ";
  }

  my $rv = qq|
</div>
<script src="js/vue-2.5.16.min.js"></script>
<script src="js/vue-select-2.4.0.js"></script>
<script src="js/axios-0.17.1.min.js"></script>
<script src="js/utils.js"></script>
<script>
var app = new Vue({
  el: '#app',
  computed: {
    callback: function() {
      var rv = '';
      if (this.form.callback) {
        rv = '&callback=' + encodeURIComponent(this.form.callback);
      }$callback_fn

      return rv;
    },
    currentURL: function() {
      return $url_fn;
    }
  },
  data: {$data_string
    loadingObject: true,
    myconfig: $myconfig_json,
    form:
$form_json
  },
  methods: {$method_string},
  updated: function() {
    this.loadingObject = false;
  }
});
</script>
</body>
</html>|;

  return "$rv\n";
}

sub order_link ($self, $type_field, $id_field, $content) {
  my $href =
    $self->_build_link(
    qq|'oe.pl?type=' + $$type_field + '&action=edit&id=' + $$id_field|);
  my $text = $self->_text($content);
  my $rv   = qq|<a v-bind:href="$href">$text</a>|;
  return $rv;
}

sub requirements_link ($self, $id_field, $content) {
  my $href =
    $self->_build_link(qq|'mrp.pl?action=part_requirements&id=' + $$id_field|);
  my $text = $self->_text($content);
  my $rv   = qq|<a v-bind:href="$href">$text</a>|;
  return $rv;
}

sub search_part ($self, %definition) {
  push @{$self->{data}}, 'allParts: []', 'selectedPart: null';

  my $searchitems = $definition{searchitems} || 'all';

  push @{$self->{methods}}, qq~getPart: function(newPart) {
  if (this.loadingObject || !newPart) {
    return;
  }
  this.loadingObject = true;
  var self = this;
  axios.post('$definition{script}', {action: '$definition{action}', id: newPart.id, path: 'bin/mozilla', login: this.form.login})
    .then(function(response) {
      self.form = response.data;
      self.selectedPart = self.form;
      history.replaceState(null, null, self.currentURL);
    });
},
searchPartNumber: function(search, loading) {
  this.searchPart(search, loading, 'partnumber');
},
searchPartDescription: function(search, loading) {
  this.searchPart(search, loading, 'description');
},
searchPart: function(search, loading, field) {
  if (search.length > 2) {
    loading(true);
    var self = this;
    var query = {
      action: 'search_part',
      searchitems: '$searchitems',
      path: 'bin/mozilla',
      login: this.form.login
    };
    query[field] = search;
    axios.post('api.pl', query)
      .then(function(response) {
        self.allParts = response.data.parts;
        loading(false);
      });
  }
}~;

  my $rv = {
    columns => [
q|<v-select label="partnumber" :value="selectedPart" :options="allParts" @search="searchPartNumber" @input="getPart">
</v-select>|,
q|<v-select label="description" :value="selectedPart" :options="allParts" @search="searchPartDescription" @input="getPart">
</v-select>|,
    ],
    params => {class => 'noprint'},
  };

  return $rv;
}

sub start_body ($self) {
  my $rv = q|<body>
<div id="app">|;

  return "$rv\n";
}

sub table ($self, %definition) {
  my @rv;
  my $props = $self->_props($definition{params});

  push @rv, qq|<table$props>|;

  for my $row (@{$definition{rows}}) {
    $self->_common_params(\%definition, $row);
    push @rv, $self->tr(%$row);
  }

  push @rv, qq|</table>|;

  my $rv = join "\n", @rv;
  return "$rv\n";
}

sub td ($self, %definition) {
  my @rv;
  my $props = $self->_props($definition{params});
  my $tag = $definition{params}{head} ? 'th' : 'td';

  my $content = $definition{content};
  if (ref $content eq 'ARRAY') {
    my @content;
    push @content, $self->_text($_, $definition{params}) for @$content;
    push @rv, qq|<$tag$props>| . join(' ', @content) . qq|</$tag>|;
  } else {
    push @rv,
        qq|<$tag$props>|
      . $self->_text($content, $definition{params})
      . qq|</$tag>|;
  }

  my $rv = join "\n", @rv;
  return $self->_indent(2, $rv);
}

sub tr ($self, %definition) {
  my @rv;

  my $props = $self->_props($definition{params});
  push @rv, qq|<tr$props>|;


  for my $column (@{$definition{columns}}) {
    my $col = ref $column eq 'HASH' ? $column : {content => $column};
    $self->_common_params(\%definition, $col);
    push @rv, $self->td(%$col);
  }

  push @rv, qq|</tr>|;
  my $rv = join "\n", @rv;
  return $self->_indent(2, $rv);
}

sub vendor_link ($self, $id_field, $content) {
  my $href =
    $self->_build_link(qq|'ct.pl?db=vendor&action=edit&id=' + $$id_field|);
  my $text = $self->_text($content);
  my $rv   = qq|<a v-bind:href="$href">$text</a>|;
  return $rv;
}

# internal methods

sub _build_link ($self, $link) {
  my $rv =
qq|$link + '&path=' + form.path + '&login=' + form.login + '&js=' + form.js + callback|;
  $rv =~ s/&/&amp;/g;
  return $rv;
}

sub _common_params ($self, $parent, $object) {
  if ($parent->{common_params}) {
    $object->{params}->{$_} = $parent->{common_params}->{$_}
      for keys %{$parent->{common_params}};
  }
}

sub _indent ($self, $spaces, $text) {
  my $in = ' ' x $spaces || 0;
  $text =~ s/^(.+)/$in$1/mg;
  return $text;
}

sub _props ($self, $params = {}) {
  my @rv;

  # types
  if (my $type = $params->{type}) {
    if ($type =~ /number|decimal/) {
      $params->{class} = $params->{class} ? "$params->{class} $type" : $type;
    }
  }

  for (sort keys %$params) {
    if (/align|class|colspan|width/) {
      push @rv, qq|$_="$params->{$_}"|;
    } elsif (/for/) {
      push @rv, qq|v-$_="$params->{$_}"|;
    }
  }
  return @rv ? ' ' . join ' ', @rv : '';
}

sub _text ($self, $text, $params = {}) {
  my $rv;
  if (ref $text) {
    my $field = $$text;

    # filters
    my %filters = (date => 'date(myconfig.dateformat)',);
    if (my $type = $params->{type}) {
      $field = "$field | $filters{$type}" if $filters{$type};
    }

    $rv = qq|{{ $field }}|;
  } else {
    $rv = $text;
  }

  return $rv;
}

1;

=encoding utf8

=head1 NAME

TagHelpers - Helpers for HTML tags

=head1 SYNOPSIS

  use SL::TagHelpers;

  my $html = TagHelpers->new;

  $html->callback;
  $html->start_body;

  $html->customer_link;
  $html->order_link;
  $html->requirements_link;
  $html->vendor_link;

  $html->table;
  $html->tr;
  $html->td;

=head1 DESCRIPTION

L<SL::TagHelpers> contains helpers for HTML tags.

=head1 CONSTRUCTOR

L<SL::TagHelpers> uses the following construcor:

=head2 new

  my $html = TagHelpers->new(\%myconfig, $form);

=head1 METHODS

L<SL::TagHelpers> implements the following methods:

=head2 callback

  $html = $html->callback(@fields);

List of the fields used to create the callback.

=head2 customer_link

  $text = $html->customer_link(\$id_field, $content);
  $text = $html->customer_link(\$id_field, \$content_field);

Creates a link to the L<customer module|bin::mozilla::ct/edit>.
See L</vendor_link>.

=head2 end_body

  $text = $html->end_body;

Closes the application C<div>, adds JavaScript blocks, closes C<body>.

=head2 order_link

  $text = $html->order_link(\$type_field, \$id_field, $content);
  $text = $html->order_link(\$type_field, \$id_field, \$content_field);

Creates a link to the L<order entry module|bin::mozilla::oe/edit>.

=head2 requirements_link

  $text = $html->requirements_link(\$id_field, $content);
  $text = $html->requirements_link(\$id_field, \$content_field);

Creates a link to the L<requirements overwiev|bin::mozilla::mrp/part_requirements>
of a part.

=head2 search_part

  $href = $html->search_part(
    action => $action,            # action for selected part
    script => $script,            # script for selected part
    searchitems => $searchitems,  # default 'all'
  );

Sets up the required variables and methods and returns a hash reference
that defines a non-printing table row with two columns and can be inserted
in L</table>.

  $html->table(
    rows => [
      $html->search_part(%definition),
      ...
    ],
  );


=head2 start_body

  $text = $html->start_body;

Opens C<body> and application C<div>.

=head2 table

  @rows = (
    \%row1,
    \%row2,
    ...
  );

  $text = $html->table(
    common_params => \%common_params,
    params        => \%params,
    rows          => \@rows,
  );

Creates a table with the specified L<rows|/tr> and L<parameters|/PARAMETERS>.

=head2 td

  $text = $html->td(
    content       => $content,
    params        => \%params,
  );

Create a table cell, modified by L<parameters|/PARAMETERS>.

  $content = 'A text';

Plain text is rendered directly.

  $content = \'a_field';

Scalar references are linked to the specified field of the C<data> section.

  $content = \('Text 1', \'field1', 'Text 2');

Elements of array references are interpreted individually and concatenated
with spaces.

=head2 tr

  @columns = (
    $column1,   # text
    \$column2,  # reference to field
    \@column4,  # array of texts and references
    \%column3,  # completely defined column
    ...
  );

  $text = $html->tr(
    columns       => \@columns,
    common_params => \%common_params,
    params        => \%params,
  );

Creates a table rows with the specified L<columns|/td> and L<parameters|/PARAMETERS>.

=head2 vendor_link

  $text = $html->vendor_link(\$id_field, $content);
  $text = $html->vendor_link(\$id_field, \$content_field);

Creates a link to the L<vendor module|bin::mozilla::ct/edit>.
See L</customer_link>.

=head1 PARAMETERS

  $html->$el(
    common_params => \%common_params,
    params        => \%params,
    ...
  );

Parameters are defined with C<params> for the element itself and with
C<common_params> for its immediate children. Parameters in an element have
precendence over common parameters.

=head2 align

  %params = ( align => $align );

Aligns the content of the element.

=head2 class

  %params = ( class => 'my_css' );

Adds CSS classes to the element.

=head2 colspan

  %params = ( colspan => $colspan );

Sets the colspan of a table cell.

=head2 for

  %params = ( for => 'item in list' );

Repeats the element.

=head2 head

  %params = ( head => 1 );

Renders a table cell als header.

=head2 width

  %params = ( width => '100%' );

Sets the width of the element.

=cut
