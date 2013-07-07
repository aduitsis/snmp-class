package SNMP::Class::Rete;

use v5.14;
use Moose;

use SNMP::Class::Rete::Alpha;
use SNMP::Class::Rete::Rule;
use SNMP::Class::Rete::Instantiation;

use Moose;

my $fact_counter = 1;

has 'fact_set' => (
	is => 'ro',
	writer => '_set_fact_set',
	isa => 'SNMP::Class::FactSet::Simple',
	required => 1,
);

has 'rules' => (
	is => 'ro',
	isa => 'ArrayRef[SNMP::Class::Rete::Rule]',
	required => 0,
);

has 'index' => (
	is => 'ro',
	isa => 'HashRef[Str]',
	default => sub { {} },
);

sub BUILD {
	# we will be working with a copy of the original factset
	$_[0]->_set_fact_set( $_[0]->fact_set->clone )
}

sub reset {
	my $self = shift // die 'incorrect call';
	$self->insert_fact( @{ $self->fact_set->facts } )
}

sub run {
	say 'run'
}

sub insert_fact {
	my $self = shift // die 'incorrect call';

	for my $fact ( @_ ) {
		if( exists $self->index->{ $fact->type } ) {
			for my $alpha ( @{ $self->index->{ $fact->type } } ) {
				my $inst = $alpha->instantiate_with_fact( $fact_counter++ => $fact );
			}
		}
	}
}

sub insert_alpha {
	my $self = shift // die 'incorrect call';

	for my $alpha ( @_ ) {
		push @{ $self->index->{ $alpha->type } },$alpha;
	}
}

sub insert_rule {
	my $self = shift // die 'incorrect call';
	for my $rule ( @_ ) {
		push @{ $self->rules }, $rule;
	}

}




1;