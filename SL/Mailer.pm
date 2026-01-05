#======================================================================
# SQL-Ledger ERP
#
# © 2006-2023 DWS Systems Inc.                   https://sql-ledger.com
# © 2007-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# mailer package
#
#======================================================================
use v5.40;

package SL::Mailer;

use utf8;
use MIME::Base64;

sub new {
  my ($type) = @_;
  my $self = {};

  bless $self, $type;
}


sub send {
  my ($self, $target) = @_;

  my $boundary = time;
  my $domain = $self->{from};
  $domain =~ s/(.*?\@|>)//g;
  my $msgid = "$boundary\@$domain";
  $boundary = "SL-$self->{version}-$boundary";

  $self->{charset} = 'UTF-8';

  $self->{contenttype} ||= "text/plain";

  utf8::encode $self->{$_} for qw|from to cc bcc subject message|;

  my %h;
  for (qw(from to cc bcc)) {
    $self->{$_} =~ s/\&lt;/</g;
    $self->{$_} =~ s/\&gt;/>/g;
    $self->{$_} =~ s/(\/|\\|\$)//g;
    $self->{$_} =~ s/["]?(.*?)["]? (<.*>)/"=?$self->{charset}?B?".encode_base64($1,"")."?= $2"/e if $self->{$_} =~ m/[\x00-\x1F]|[\x7B-\xFFFF]/;
    $h{$_} = $self->{$_};
  }

  $h{cc} = "Cc: $h{cc}\n" if $self->{cc};
  $h{bcc} = "Bcc: $h{bcc}\n" if $self->{bcc};
  $h{subject} = ($self->{subject} =~ /([\x00-\x1F]|[\x7B-\xFFFF])/) ? "Subject: =?$self->{charset}?B?".encode_base64($self->{subject},"")."?=" : "Subject: $self->{subject}";

  if ($self->{notify}) {
    if ($self->{notify} =~ /\@/) {
      $h{notify} = "Disposition-Notification-To: $self->{notify}\n";
    } else {
      $h{notify} = "Disposition-Notification-To: $h{from}\n";
    }
  }

  my $out;
  if ($target) {
    $self->{from} =~ /<(.*)>/;
    my $envelope = $1;
    $envelope =~ s/@/%/;
    $target =~ s/<%from%>/$envelope/;
    open $out, $target or return "$target : $!";
  } else {
    open $out, ">-" or return "STDOUT : $!";
  }

  print $out qq|From: $h{from}
To: $h{to}
$h{cc}$h{bcc}$h{subject}
Message-ID: <$msgid>
$h{notify}X-SL::Mailer: SQL-Ledger $self->{version}
MIME-Version: 1.0
|;


  if (@{ $self->{attachments} }) {
    print $out qq|Content-Type: multipart/mixed; boundary=$boundary\n\n|;

    if ($self->{message} ne "") {
      print $out qq|--${boundary}
Content-Type: $self->{contenttype}; charset=$self->{charset}

$self->{message}

|;
    }

    foreach my $attachment (@{ $self->{attachments} }) {

      my $application = ($attachment =~ /(^\w+$)|\.(html|text|txt|sql)$/) ? "text" : "application";

      my $in;
      unless (open $in, $attachment) {
        close $out;
        return "$attachment : $!";
      }

      binmode $in;

      my $filename = $attachment;
      # strip path
      $filename =~ s/(.*\/|$self->{fileid})//g;

      print $out qq|--${boundary}
Content-Type: $application/$self->{format}; name=${filename}; charset=$self->{charset}
Content-Transfer-Encoding: BASE64
Content-Disposition: attachment; filename=$filename\n\n|;

      my $msg = "";
      while (<$in>) {;
        $msg .= $_;
      }
      print $out encode_base64($msg);

      close $in;

    }
    print $out qq|--${boundary}--\n|;

  } else {
    print $out qq|Content-Type: $self->{contenttype}; charset=$self->{charset}

$self->{message}
|;
  }

  close $out;

  return "";

}


1;


=encoding utf8

=head1 NAME

SL::Mailer - Mailer package

=head1 DESCRIPTION

L<SL::SL::Mailer> contains the mailer package.


=head1 CONSTRUCTOR

L<SL::SL::Mailer> uses the following constructor:

=head2 new

  $mailer = SL::Mailer->new;

=head1 METHODS

L<SL::SL::Mailer> implements the following methods:

=head2 send

  $mailer->send($target);

=cut
