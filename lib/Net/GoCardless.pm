package Net::GoCardless;

use strict;
use warnings;
our $VERSION = '0.01';
use 5.010001;

use LWP::UserAgent;
use Carp qw/croak/;
use Time::Piece;
use Digest::SHA;

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/client_id/);



sub sign {
    my $data = shift;
    my $sha = Digest::SHA->new(sha256_hex);
    $sha->add($data);
    return $sha->sha256_hex;
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

