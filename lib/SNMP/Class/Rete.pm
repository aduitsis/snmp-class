package SNMP::Class::Rete;

use v5.14;
use Moose;

use SNMP::Class::Rete::Alpha;
use SNMP::Class::Rete::Rule;
use SNMP::Class::Rete::Instantiation;

use Moose;

my $fact_counter;
my $rule_counter;
my $alpha_counter;

has 'original_fact_set' => (
	is		=> 'ro',
	writer		=> '_set_original_fact_set',
	isa		=> 'SNMP::Class::FactSet::Simple',
);

# contains the known facts
has 'fact_set'	=> (
	is		=> 'ro',
	writer		=> '_set_fact_set',
	isa		=> 'SNMP::Class::FactSet::Simple',
	default		=> sub { SNMP::Class::FactSet::Simple->new },
);

# an array containing the production rules of the Rete
has 'rules'	=> (
	is		=> 'ro',
	isa		=> 'ArrayRef[SNMP::Class::Rete::Rule]',
	required	=> 0,
	default		=> sub{ [] },
);

# a hash (indexed by fact type) containing all the instantiations 
# of facts. Each instatiation corresponds to a specific alpha node
has 'alphas'	=> (
	is	=> 'ro',
	isa	=> 'HashRef[Str]',
	default	=> sub { {} },
);

sub BUILDARGS { 
	my $class = shift // die 'missing class argument';
	if( @_ == 1 ) {
	        return { original_fact_set => shift };
	}
	else {
		my %args = @_;
		$args{ original_fact_set } = $args{ fact_set } if exists $args{ fact_set };
		delete $args{ fact_set } ; 
	        $class->SUPER::BUILDARGS( %args );
	}
}

sub BUILD {
	# initialize alphas here
	# initialize rules here
	$_[0]->reset
}
	
sub reset {
	# the original_fact_set was pointing to the same structure as fact_set
	# now, we clone the original_fact_set and put it in fact_set
	# so we can safely modify fact_set without disturbing the original structure
	my $self = shift // die 'incorrect call';
	$self->_set_fact_set( SNMP::Class::FactSet::Simple->new ) ; 
	$fact_counter = 0;
}

sub run {
	my $self = shift // die 'incorrect call';
	#$self->fact_set->each(sub { 
		#$self->insert_fact( $_ ) 
	#});
	$self->original_fact_set->each( sub { 
		$self->insert_fact( $_ )
	});
}

sub insert_fact {
	my $self = shift // die 'incorrect call';
	for my $fact ( @_ ) {
		$self->fact_set->push( $fact ); 
		$fact_counter++;
		if( exists $self->alphas->{ $fact->type } ) {
			for my $alpha ( @{ $self->alphas->{ $fact->type } } ) {
				my $inst = $alpha->instantiate( $fact );
			}
		}
	}
}

sub insert_rule {
	my $self = shift // die 'incorrect call';
	for my $rule ( @_ ) {
		push @{ $self->rules }, $rule;
		for my $alpha ( keys %{ $rule->alphas } ) {
			if( ! exists $self->alphas->{ $alpha } ) {
				push @{ $self->alphas->{ $rule->alphas->{$alpha}->type } } , $rule->alphas->{ $alpha };
			}
		}
	}
}

1;
