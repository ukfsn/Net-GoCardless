package Net::GoCardless;

use strict;
use warnings;
our $VERSION = '0.01';
use 5.010001;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use Carp qw/croak/;
use Time::Piece;
use Digest::SHA qw/hmac_sha256_base64/;
use JSON;
use Data::Dumper;

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/client_id access_token secret testing timeout/);

sub _go {
    my ($self, $method, $command, $data) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->timeout(($self->timeout ? $self->timeout : 15));

    my $h = HTTP::Headers->new();
    $h->header('User-Agent' => "Net::GoCardless Perl Module/$VERSION");
    $h->header('Authorization' => "bearer ".$self->access_token);
    $h->header('accept' => 'application/json');
    
    my $uri = 'https://' . ($self->testing ? 'sandbox.gocardless.com' : 'gocardless.com') . '/';
    $uri = $uri . $command;

    my $req = HTTP::Request->new($method, $uri, $h, $data);

    my $res = $ua->request($req);
    warn Dumper $res if $self->testing;

    croak $res->status_line unless $res->is_success;
    return $res->decoded_content;
}

sub _connect {
    # Handles new subscription, pre-authorisation and bill setups
    my ($self, $command, $data) = @_;

    $data->{client_id} = $self->client_id;
    $data->{timestamp} = Time::Piece->new()->datetime;
    $data->{nonce} = hmac_sha256_base64($$ . $data->{timestamp}, "Net::GoCardless Perl Module");

    $command = 'connect/'.$command.'s/new';
    $data->{signature} = $self->sign($data);

    my $answer = $self->_go("POST", $command, to_json($data));
    return from_json($answer);
}

sub sign {
    my ($self,$data) = @_;
    my $string = undef;
    for (sort keys %$data) {
        $string .= $_ . '=' . $data->{$_};
    }
    return hmac_sha256_base64($string, $self->secret);
}

sub _api {
    # Handles API calls for existing subscriptions, pre-auths and bills
    my ($self, $command, $data) = @_;

    my $method = "GET";
    if ( $command eq 'new_bill' ) {
        $method = "POST";
        $command = 'api/v1/bills';
    }
    else {
        $command = 'api/v1/'.$command.'s/'.$data->{id};
        $command .= '/'.$data->{subcommand} if $data->{subcommand};
        if ( $data->{filter} ) {
            $command .= '?';
            foreach (keys %{$data->{filter}}) {
                $command .= $_.'='.$data->{filter}->{$_}.'&';

            }
            chop $command; # Remove the extra & character
        }
    }
    
    my $answer = $self->_go($method, $command, to_json($data));
    return from_json($answer);
}

sub new_subscription {
    my ($self, $data) = @_;
    for (qw/merchant_id amount interval_length interval_unit/) {
        croak "You must supply the $_ parameter" unless $data->{$_};
    }

    return $self->_connect("subscription", $data);
}

sub merchant {
    my ($self, $data) = @_;
    return $self->_api("merchant", $data);
}

sub merchant_users {
    my ($self, $data) = @_;
    $data->{subcommand} = 'users';
    $self->merchant($data);
}

sub get_bill {
    my ($self, $data) = @_;
    return $self->_api("bill", $data);
}

sub payment {
    my ($self, $data) = @_;
    return $self->_api("payment", $data);
}

1;
__END__

=head1 NAME

Net::GoCardless - Perl extension for the GoCardless payment processor

=head1 SYNOPSIS

  use Net::GoCardless;
  
  my $go = Net::GoCardless->new(client_id => 'abc123');
  
  my $sub = $go->subscription( ... );
  my $bill = $go->bill( ... );
  my $pre_auth = $go->pre_authorisation( ... );

=head1 DESCRIPTION

Perl module to interface with the GoCardless payment processing system.

You can use this module to set up subscriptions and pre-authorisations and
issue bills for payment via GoCardless and to verify that those payments
have been received (or not).

=head1 SEE ALSO

GoCardless - http://www.gocardless.com/

This module depends upon the following perl modules:

    Carp
    Class::Accessor
    Digest::SHA
    LWP::UserAgent
    Time::Piece
    JSON

A public git repository for this module is available at 
https://github.com/ukfsn/Net-GoCardless

=head1 AUTHOR

Jason Clifford, E<lt>jason@ukfsn.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Jason Clifford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

