package SNMP::Class::Role::Personality::SNMP_Agent;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'SNMP Agent';
our $description = 'is an SNMP Agent';

our @required_oids = () ; #no oids required for this basic role

our @dependencies = qw();

sub get_facts {

	defined( my $s = shift( @_ ) ) or confess 'incorrect call';

	SNMP::Class::Fact->new(
		type => 'snmp_agent', 
		slots => {
			system => $s->sysname,
			engine_id => $s->engine_id,
			hostname => $s->hostname,
			version => $s->version,
			community => $s->community,
		}
	)

}

sub predicate {
	return ( does_role( $_[0] , 'SNMP::Class::Role::Personality' ) ) 
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
