package SNMP::Class::Rete::Alpha;

use v5.14;
use strict;
use warnings;

use Moose;
use Scalar::Util qw(blessed);
use Data::Dumper;
use Carp;

use SNMP::Class::Rete::InstantiationSet;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

my $counter = 0;

with 'SNMP::Class::Rete::InstantiationSet';

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
	
sub instantiate {
	my $self	= shift	// die 'incorrect call';
	my $fact	= shift	// die 'missing fact';

	die 'argument is not an SNMP::Class::Fact' unless $fact->isa('SNMP::Class::Fact');

	( $fact->type eq $self->type ) or confess 'cannot instantiate a '.$self->type.' alpha with a '.$fact->type.' fact';

        my $result = $self->bind->($fact);
	if( defined( $result ) ) {
		ref $result eq 'HASH' or confess 'bind subref did not return a hashref. Exiting. Returned value was:'.Dumper($result);
		my $instantiation = SNMP::Class::Rete::Instantiation->new( $result );
		$self->push_inst( $instantiation );
		
		for my $rule ( values %{ $self->rules } ) {
			#$self->rules->{ $rule }->receive( $self->unique_id , $instantiation );
			$self->send( $rule , $instantiation ); 
		}

		return $instantiation;
        }

}

sub point_to_rule {
        my $self = shift // die 'incorrect call';
        my $rule = shift // die 'missing Instantiation';    
        blessed( $rule ) && $rule->isa( 'SNMP::Class::Rete::Rule' ) or confess 'argument is not a Rule';

        $self->rules->{ $rule->unique_id } = $rule;
}

1;

