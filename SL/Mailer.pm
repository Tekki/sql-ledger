#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# mailer package
#
#======================================================================

package Mailer;

sub new {
  my ($type) = @_;
  my $self = {};

  bless $self, $type;
}


sub send {
  my ($self, $out) = @_;

  my $boundary = time;
  $boundary = "SL-$self->{version}-$boundary";
  my $domain = $self->{from};
  $domain =~ s/(.*?\@|>)//g;
  my $msgid = "$boundary\@$domain";
  
  $self->{charset} ||= "ISO-8859-1";

  if ($out) {
    open(OUT, $out) or return "$out : $!";
  } else {
    open(OUT, ">-") or return "STDOUT : $!";
  }

  $self->{contenttype} ||= "text/plain";
  
  my %h;
  for (qw(from to cc bcc)) {
    $self->{$_} =~ s/\&lt;/</g;
    $self->{$_} =~ s/\&gt;/>/g;
    $self->{$_} =~ s/(\/|\\|\$)//g;
    $self->{$_} =~ s/["]?(.*?)["]? (<.*>)/"=?$self->{charset}?B?".&encode_base64($1,"")."?= $2"/e if $self->{$_} =~ m/[\x00-\x1F]|[\x7B-\xFFFF]/;
    $h{$_} = $self->{$_};
  }
 
  $h{cc} = "Cc: $h{cc}\n" if $self->{cc};
  $h{bcc} = "Bcc: $h{bcc}\n" if $self->{bcc};
  $h{subject} = ($self->{subject} =~ /([\x00-\x1F]|[\x7B-\xFFFF])/) ? "Subject: =?$self->{charset}?B?".&encode_base64($self->{subject},"")."?=" : "Subject: $self->{subject}";
  
  if ($self->{notify}) {
    if ($self->{notify} =~ /\@/) {
      $h{notify} = "Disposition-Notification-To: $self->{notify}\n";
    } else {
      $h{notify} = "Disposition-Notification-To: $h{from}\n";
    }
  }
  
  print OUT qq|From: $h{from}
To: $h{to}
$h{cc}$h{bcc}$h{subject}
Message-ID: <$msgid>
$h{notify}X-Mailer: SQL-Ledger $self->{version}
MIME-Version: 1.0
|;


  if (@{ $self->{attachments} }) {
    print OUT qq|Content-Type: multipart/mixed; boundary="$boundary"

|;
    if ($self->{message} ne "") {
      print OUT qq|--${boundary}
Content-Type: $self->{contenttype}; charset="$self->{charset}"

$self->{message}

|;
    }

    foreach my $attachment (@{ $self->{attachments} }) {

      my $application = ($attachment =~ /(^\w+$)|\.(html|text|txt|sql)$/) ? "text" : "application";
      
      unless (open IN, $attachment) {
	close(OUT);
	return "$attachment : $!";
      }

      binmode(IN);
      
      my $filename = $attachment;
      # strip path
      $filename =~ s/(.*\/|$self->{fileid})//g;
      
      print OUT qq|--${boundary}
Content-Type: $application/$self->{format}; name="$filename"; charset="$self->{charset}"
Content-Transfer-Encoding: BASE64
Content-Disposition: attachment; filename="$filename"\n\n|;

      my $msg = "";
      while (<IN>) {;
        $msg .= $_;
      }
      print OUT &encode_base64($msg);

      close(IN);
      
    }
    print OUT qq|--${boundary}--\n|;

  } else {
    print OUT qq|Content-Type: $self->{contenttype}; charset="$self->{charset}"

$self->{message}
|;
  }

  close(OUT);

  return "";
  
}


sub encode_base64 ($;$) {

  # this code is from the MIME-Base64-2.12 package
  # Copyright 1995-1999,2001 Gisle Aas <gisle@ActiveState.com>

  my $res = "";
  my $eol = $_[1];
  $eol = "\n" unless defined $eol;
  pos($_[0]) = 0;                          # ensure start at the beginning

  $res = join '', map( pack('u',$_)=~ /^.(\S*)/, ($_[0]=~/(.{1,45})/gs));

  $res =~ tr|` -_|AA-Za-z0-9+/|;               # `# help emacs
  # fix padding at the end
  my $padding = (3 - length($_[0]) % 3) % 3;
  $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
  # break encoded string into lines of no more than 60 characters each
  if (length $eol) {
    $res =~ s/(.{1,60})/$1$eol/g;
  }
  return $res;
  
}


1;

