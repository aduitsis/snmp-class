package SNMP::Class::Role::Personality::PortTable;

use Data::Printer;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'PortTable';
our $description = 'has a Cisco Stack Port table';

our @required_oids = qw( portTable );

sub get_facts {

	defined( my $s = shift( @_ ) ) or confess 'incorrect call';
	$s->portName->map(sub {
		SNMP::Class::Fact->new(
			type=>'cisco_stack_port',
			slots=> {
				system => $s->sysname,
				engine_id => $s->engine_id,
				name => $_->value,
				type => $s->portType($_->get_instance_oid)->value,
				oper_status => $s->portOperStatus($_->get_instance_oid)->value,
				admin_speed => $s->portAdminSpeed($_->get_instance_oid)->value,
				duplex => $s->portDuplex($_->get_instance_oid)->value,
				interface => $s->get_ifunique($s->portIfIndex($_->get_instance_oid)->value),
			}
		);
	})

}


sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::Interfaces') 
	&& 
	$_[0]->contains_label('portModuleIndex')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
