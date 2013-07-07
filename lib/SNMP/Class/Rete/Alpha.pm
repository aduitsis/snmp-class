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

has 'instantiations' => (
        is => 'ro',
        isa => 'HashRef[SNMP::Class::Rete::Instantiation]',
        required => 0,
        default => sub{ {} },
);

has 'rules' => (
        is => 'ro',
        isa => 'ArrayRef[SNMP::Class::Rete::Rule]',
        required => 0,
        default => sub { [] },
);

sub instantiate_with_fact {
	my $self = shift // die 'incorrect call';
        my $id = shift // die 'missing fact id';
	my $fact = shift // die 'missing fact';

	die 'argument is not an SNMP::Class::Fact' unless $fact->isa('SNMP::Class::Fact');

        my $result = $self->bind->($fact);
                if( defined( $result ) ) {
                        $self->instantiations->{ $id } = SNMP::Class::Rete::Instantiation->new( $result );
        }
}

sub combine {
        my $self = shift // die 'incorrect call';
        my $other = shift // die 'missing Instantiation';
        
        Scalar::Util::blessed $other && $other->isa( __PACKAGE__ ) or die 'argument is not an Instantiation';

        my @result = ();

        for my $i1 ( keys %{ $self->instantiations } ) {
                for my $i2 ( keys %{ $other->instantiations } ) {
                        if( $self->instantiations->{ $i1 }->is_compatible( $other->instantiations->{ $i2 } ) ) {
                                push @result, $self->instantiations->{ $i1 }->combine( $other->instantiations->{ $i2 } )
                        }
                }
        }

        return @result;
}

sub point_to_rule {
        my $self = shift // die 'incorrect call';
        my $other = shift // die 'missing Instantiation';    
        Scalar::Util::blessed $other && $other->isa( 'SNMP::Class::Rete::Rule' ) or die 'argument is not an Instantiation';

        push @{ $self->rules },$other;

}

1;

