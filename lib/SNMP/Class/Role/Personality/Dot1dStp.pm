package SNMP::Class::Role::Personality::Dot1dStp;

use Data::Printer;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'Dot1dStp';
our $description = 'implements STP';

our @required_oids = qw( dot1dStp );

sub get_facts {
	defined( my $s = shift( @_ ) ) or confess 'incorrect call';
	$s->dot1dStpPort->map(sub {
		SNMP::Class::Fact->new(
			type => 'stp_port',
			slots => {
				system => $s->sysname,
				engine_id => $s->engine_id,
				state => $s->dot1dStpPortState($_->get_instance_oid)->value,
				interface => $s->get_ifunique($s->dot1dBasePortIfIndex($_->get_instance_oid)->value),
				designated_root => $s->dot1dStpPortDesignatedRoot($_->get_instance_oid)->value,
				designated_root_priority => $s->dot1dStpPortDesignatedRoot($_->get_instance_oid)->priority,
				designated_root_mac_address => $s->dot1dStpPortDesignatedRoot($_->get_instance_oid)->mac_address,
				designated_bridge => $s->dot1dStpPortDesignatedBridge($_->get_instance_oid)->value,
				designated_bridge_priority => $s->dot1dStpPortDesignatedBridge($_->get_instance_oid)->priority,
				designated_bridge_mac_address => $s->dot1dStpPortDesignatedBridge($_->get_instance_oid)->mac_address,
				priority => $s->dot1dStpPortPriority($_->get_instance_oid)->value,
				enabled => $s->dot1dStpPortEnable($_->get_instance_oid)->value,
				path_cost => $s->dot1dStpPortPathCost($_->get_instance_oid)->value,
				designated_cost => $s->dot1dStpPortDesignatedCost($_->get_instance_oid)->value,
				designated_port => $s->dot1dStpPortDesignatedPort($_->get_instance_oid)->value,
			},
		);
	});
}


sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::Interfaces') 
	&&
	does_role($_[0] , 'SNMP::Class::Role::Personality::Dot1dTpFdbAddress')
	&& 
	$_[0]->contains_label('dot1dStpPortTable')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
