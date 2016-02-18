package SNMP::Class::Role::Personality::LaLoad;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'LaLoad';
our $description = 'can report its load';

our @required_oids = qw(laLoadInt laNames);

our @dependencies= qw(SNMP::Class::Role::Personality::SNMP_Agent);

sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::SNMP_Agent') 
	&& 
	$_[0]->contains_label('laNames')
	&& 
	$_[0]->contains_label('laLoadInt')
}

sub get_facts {

	defined( my $s = shift( @_ ) ) or confess 'incorrect call';
	# following call returns array of SNMP::Class::Facts
	return ( SNMP::Class::Fact->new(
		type => 'load_average',
		slots => {
			system		=> $s->sysname,
			engine_id	=> $s->engine_id,
			one_min		=> $s->find( laNames => 'Load-1' )->laLoadInt->value / 100,
			five_min	=> $s->find( laNames => 'Load-5' )->laLoadInt->value / 100,
			fifteen_min	=> $s->find( laNames => 'Load-15' )->laLoadInt->value / 100,
		},
	) );
}



#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
