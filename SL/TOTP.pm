#======================================================================
# SQL-Ledger ERP
#
# © 2025-2026 Tekki (Rolf Stöckli)  https://github.com/Tekki/sql-ledger
#
#======================================================================
#
# Time-based one-time passwords
#
#======================================================================
use v5.40;

package SL::TOTP;

use Digest::SHA 'hmac_sha1';
use Encode 'decode';

sub add_secret ($user = '', $memberfile = '', $userspath = '') {

  $user->{totp_secret} = generate_secret();

  if ($memberfile && $userspath) {
    for (qw|name signature|) {
      $user->{$_} = decode 'UTF-8', $user->{$_};
    }
    $user->{packpw} = 1;
    $user->save_member($memberfile, $userspath);
  }
}

sub check_code ($user, $code, $timestamp = time) {

  my $hash   = hmac_sha1(pack('Q>', int($timestamp / 30)), decode_base32($user->{totp_secret}));
  my $offset = ord(substr($hash, -1)) & 0x0f;
  my $otp    = ((unpack("N", substr($hash, $offset, 4))) & 0x7fffffff) % 10**6;

  return sprintf("%06d", $otp) eq $code;
}

# decode_base32 and encode_base32: from MIME::Base32 by Jens Rehsack

sub decode_base32 ($arg = '') {

  $arg = uc $arg;
  $arg =~ tr|A-Z2-7|\0-\37|;
  $arg = unpack('B*', $arg);
  $arg =~ s/000(.....)/$1/g;
  my $l = length $arg;
  $arg = substr($arg, 0, $l & ~7) if $l & 7;
  $arg = pack('B*', $arg);
  return $arg;
}

sub encode_base32 ($arg = undef) {

  return '' unless defined($arg);    # mimic MIME::Base64
  $arg = unpack('B*', $arg);
  $arg =~ s/(.....)/000$1/g;
  my $l = length($arg);
  if ($l & 7) {
    my $e = substr($arg, $l & ~7);
    $arg = substr($arg, 0, $l & ~7);
    $arg .= "000$e" . '0' x (5 - length $e);
  }
  $arg = pack('B*', $arg);
  $arg =~ tr|\0-\37|A-Z2-7|;
  return $arg;
}

sub generate_secret () {
  my $secret = join '', map { chr int rand 256 } 1 .. 20;
  return encode_base32($secret);
}

sub url ($user) {

  my $account = $user->{login};
  $account .= "\@$ENV{SERVER_NAME}" if $ENV{SERVER_NAME};

  return
    qq|otpauth://totp/SQL-Ledger:$account?secret=$user->{totp_secret}&issuer=SQL-Ledger&algorithm=SHA1&digits=6&period=30|;
}

1;

=encoding utf8

=head1 NAME

SL::TOTP - Time-based one-time passwords

=head1 SYNOPSIS

    use SL::TOTP;
    use SL::User;

    my $user = SL::User->new($memberfile, $form->{login});
    SL::TOTP->add_secret($user, $memberfile, $userspath);

    my $url = SL::TOTP::url($user);

    SL::TOTP->check_code($user, $code);

=head1 DESCRIPTION

L<SL::TOTP> provides functions for time-based one-time passwords.

=head1 DEPENDENCIES

L<SL::TOTP>

=over

=item * uses
L<Digest::SHA>

=back

=head1 FUNCTIONS

L<SL::TOTP> implements the following functions:

=head2 add_secret

    my $user = SL::User->new($memberfile, $form->{login});
    SL::TOTP::add_secret($user, $memberfile, $userspath);

    SL::TOTP::add_secret($user);  # without saving

=head2 check_code

    my $ok = SL::TOTP::check_code($user, $code);  # current time
    my $ok = SL::TOTP::check_code($user, $code, $timestamp); 

=head2 decode_base32

    my $decoded = SL::TOTP::decode_base32($encoded_string);

=head2 encode_base32

    my $encoded_string = SL::TOTP::encode_base32($unencoded_string);

=head2 generate_secret

    my $secret = SL::TOTP::generate_secret();

=head2 url

    my $url = SL::TOTP::url($user);

=cut
