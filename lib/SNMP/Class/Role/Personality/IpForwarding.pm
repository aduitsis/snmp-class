package SNMP::Class::Role::Personality::IpForwarding;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'IpForwarding';
our $description = 'is a router';

our @required_oids = qw( ipForwarding );

our @dependencies = qw(SNMP::Class::Role::Personality::SNMP_Agent);

sub get_facts {
	defined( my $s = shift( @_ ) ) or confess 'incorrect call';

	SNMP::Class::Fact->new( 
		type=>'router',
		slots=> { 
			system => $s->sysname, 
			engine_id => $s->engine_id 
		} 
	);
};

sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::SNMP_Agent') 
	&& 
	$_[0]->contains_label('ipForwarding')
	&&
	( $_[0]->ipForwarding(0)->value eq 'forwarding' )
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
