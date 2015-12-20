package SNMP::Class::Rete::Alpha;

use v5.14;
use strict;
use warnings;

use Moose;
use Scalar::Util;
use Data::Dumper;
use Carp;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

my $counter = 0;

has unique_id => (
	is	=> 'ro',
	isa	=> 'Str',
	default	=> sub { 'alpha ' . $counter++ },
);

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
	writer => '_set_instantiations',
        isa => 'ArrayRef[SNMP::Class::Rete::Instantiation]',
        required => 0,
        default => sub{ [] },
);

has 'rules' => (
        is => 'ro',
        isa => 'HashRef[SNMP::Class::Rete::Rule]',
        required => 0,
        default => sub { {} },
);

sub BUILDARGS {
	my $class = shift // die 'missing class 1st argument';
	my %args;
	if ( @_ == 2 ) {
		%args = { type => $_[1]	, bind => $_[2] } 
	}
	else { 
		%args = @_;
	}
	$class->SUPER::BUILDARGS( %args );
}
	
sub reset {
	$_[0]->_set_instantiations( {} );
}

sub instantiate {
	my $self	= shift	// die 'incorrect call';
	my $fact	= shift	// die 'missing fact';

	die 'argument is not an SNMP::Class::Fact' unless $fact->isa('SNMP::Class::Fact');

	( $fact->type eq $self->type ) or confess 'cannot instantiate a '.$self->type.' alpha with a '.$fact->type.' fact';

        my $result = $self->bind->($fact);
	if( defined( $result ) ) {
		ref $result eq 'HASH' or confess 'bind subref did not return a hashref. Exiting. Returned value was:'.Dumper($result);
		my $instantiation = SNMP::Class::Rete::Instantiation->new( $result );
		
		push @{ $self->instantiations } , $instantiation;

		for my $rule ( keys %{ $self->rules } ) {
			$self->rules->{ $rule }->trigger( $self->unique_id , $instantiation );
		}

		return $instantiation;
        }

}

#sub combine {
#        my $self	= shift // die 'incorrect call';
#        my $other	= shift // die 'missing 2nd SNMP::Class::Rete::Alpha node';
#        
#        Scalar::Util::blessed $other && $other->isa( __PACKAGE__ ) or die 'argument is not an Instantiation';
#
#        my @result = ();
#
#        for my $i1 ( keys %{ $self->instantiations } ) {
#                for my $i2 ( keys %{ $other->instantiations } ) {
#                        if( $self->instantiations->{ $i1 }->is_compatible( $other->instantiations->{ $i2 } ) ) {
#                                push @result, $self->instantiations->{ $i1 }->combine( $other->instantiations->{ $i2 } )
#                        }
#                }
#        }
#
#        return @result;
#}

sub point_to_rule {
        my $self = shift // die 'incorrect call';
        my $rule = shift // die 'missing Instantiation';    
        Scalar::Util::blessed $rule && $rule->isa( 'SNMP::Class::Rete::Rule' ) or die 'argument is not a Rule';

        $self->rules->{ $rule->unique_id } = $rule;
}

1;

