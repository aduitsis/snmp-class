package SNMP::Class::Rete::Alpha;

use v5.14;
use strict;
use warnings;

use Moose;
use Scalar::Util;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

has 'type' => (
        is => 'ro',
        isa => 'Str',
        required => 1,
);      

has 'bind' => (
        is => 'ro',
        isa => 'CodeRef',
        required => 1,
);


sub instantiate_with_fact {
	my $self = shift // die 'incorrect call';
	my $fact = shift // die 'missing fact';

	die 'argument is not an SNMP::Class::Fact' unless $fact->isa('SNMP::Class::Fact');

	return unless ( $self->type eq $fact->type );

	return SNMP::Class::Rete::Instantiation->new( $self->bind->($fact) );
}

1;

