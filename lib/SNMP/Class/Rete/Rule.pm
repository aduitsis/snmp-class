package SNMP::Class::Rete::Rule;

use v5.14;
use strict;
use warnings;

use Moose;
use Scalar::Util;
use List::Util;

use SNMP::Class::Rete::InstantiationSet;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

my $counter = 0;

with 'SNMP::Class::Rete::InstantiationSet';

has rh => (
	is		=> 'ro',
	isa		=> 'CodeRef',
	required	=> 1,
);

has alphas => (
	is		=> 'ro',
	isa		=> 'HashRef[SNMP::Class::Rete::Alpha]',
	default		=> sub { {} },
);

has unique_id => (
	is		=> 'ro',
	isa		=> 'Str',
	default		=> sub { 'rule ' . $counter++ },
);

sub add_alpha {
	my $self = shift // die 'incorrect call';
	my $alpha = shift // die 'missing 2nd argument, alpha node to add to rule';
	$self->alphas->{ $alpha->unique_id } = $alpha;
	$alpha->point_to_rule( $self ) ; 
}

sub trigger { 
	my $self		= shift // die 'incorrect call';
	my $alpha_trigger	= shift // die 'missing alpha';
	my $inst_trigger	= shift // die 'missing instantiation';

	my @result;
	for my $alpha_name ( keys %{ $self->alphas } ) {
		next if $alpha_trigger eq $alpha_name;	
		my $alpha_ref = $self->alphas->{ $alpha_name };
		#for my $test_inst ( @{ $alpha_ref->instantiations } ) {
		$alpha_ref->each_inst( sub { 
			my $new_inst = $inst_trigger->combine( $_ ) // next;
			push @result,$new_inst;
			$self->push_inst( $new_inst );
			$self->rh->( $new_inst ); 
		});
	}
}
1;