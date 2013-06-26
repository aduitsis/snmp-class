package SNMP::Class::FactSet::Simple;

use v5.14;

use Data::Printer;

use warnings;
use strict;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose;
use Moose::Util::TypeConstraints;
use YAML qw(freeze thaw);
use JSON;

use Scalar::Util 'blessed';

with 'SNMP::Class::Role::FactSet';

subtype 'ArrayRefFacts' => as 'ArrayRef[SNMP::Class::Fact]';

has 'fact_set' => (
	is => 'ro',
	isa => 'ArrayRefFacts',
	default => sub { [] },
);


#declaring a reader attr for 'fact_set' does not satisfy Moose, unfortunately
sub facts {
	$_[0]->fact_set;
}

sub push { 
	defined( my $self = shift( @_ ) ) or confess 'incorrect call';
	for( @_ ) {
		if( !( blessed $_  && $_->isa('SNMP::Class::Fact') ) ) { 
			$logger->logconfess('Cannot push something that is not an SNMP::Class::Fact')
		}
	}
	push @{ $self->fact_set	} , @_;
}

sub count {
	scalar @{ $_[0]->facts }
}

sub grep {
	SNMP::Class::FactSet::Simple->new( fact_set => [ grep { $_[1]->() } @{ $_[0]->fact_set } ] );
}

sub map {
	SNMP::Class::FactSet::Simple->new( fact_set => [ map { $_[1]->() } @{ $_[0]->fact_set } ] );
}

sub item {
	$_[0]->facts->[ $_[1] ]
}

sub serialize {
	return freeze( $_[0]->facts ); 
}

# a function, not a method
sub unserialize {
	__PACKAGE__->new( fact_set => thaw( $_[0] ) );
}

sub TO_JSON {
	return '[' .  ( join ',',CORE::map { $_->TO_JSON } ( @{ $_[0]->facts } ) ) . ']';
	JSON->new->utf8->allow_blessed->convert_blessed->encode( $_[0]->facts );
	###to_json( $_[0]->facts, { allow_blessed => 1, convert_blessed => 1 } ) ;
}	

sub FROM_JSON {
	my $data = decode_json $_[0];
	__PACKAGE__->new( fact_set => [ map { SNMP::Class::Fact->new( type => $_->{type} , slots => $_->{slots} ) } @{ decode_json $_[0] } ] )
}	

1;
