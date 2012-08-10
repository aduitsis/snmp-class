package SNMP::Class::FactSet::Simple;

use warnings;
use strict;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose;
use Moose::Util::TypeConstraints;
use YAML qw(freeze thaw);

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

1;
