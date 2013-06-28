package SNMP::Class::Rete;

use v5.14;
use Moose;

use SNMP::Class::Rete::Alpha;
use SNMP::Class::Rete::Rule;
use SNMP::Class::Rete::Instantiation;

use Moose;



has 'fact_set' => (
	is => 'ro',
	writer => '_set_fact_set',
	isa => 'SNMP::Class::FactSet::Simple',
	required => 1,
);

has 'rules' => (
	is => 'ro',
	isa => 'ArrayRef[SNMP::Class::Rete::Rule]',
	required => 1,
);

sub BUILD {
	# we will be working with a copy of the original factset
	$_[0]->_set_fact_set( $_[0]->fact_set->clone )
}

sub reset {
	say 'reset'
}

sub run {
	say 'run'
}

sub alpha_nodes {
	#remember to deduplicate the alphas
	map { @{ $_->lh } } ( @{ $_[0]->rules } ) 
}



1;