package SNMP::Class::Role::Personality::CInetNetToMediaTable;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'cInetNetToMediaTable';
our $description = 'has a Cisco ciscoIetfIpMIB cInetNetToMediaTable';

our @required_oids = qw(cInetNetToMediaTable);

sub get_facts {

	defined( my $s = shift( @_ ) ) or confess 'incorrect call';

	$s->cInetNetToMediaPhysAddress->map(sub {
		SNMP::Class::Fact->new(
				type => 'ipv6_net_to_media',
				slots => {
					system => $s->sysname,
					engine_id => $s->engine_id,
					interface => $s->get_ifunique($_->if_index),
					physical_address => uc(join( ':' , ($s->cInetNetToMediaPhysAddress($_->get_instance_oid)->hex_generic_array)[0..5])),
					type => $s->cInetNetToMediaType($_->get_instance_oid)->value,
					state => $s->cInetNetToMediaState($_->get_instance_oid)->value,
					updated => $s->cInetNetToMediaLastUpdated($_->get_instance_oid)->value,
					address_type => $_->address_type,
					address => $_->address,
				}
		);
	});
}


sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::Interfaces') 
	&& 
	$_[0]->contains_label('cInetNetToMediaType')
	&& 
	$_[0]->contains_label('cInetNetToMediaState')
	&& 
	$_[0]->contains_label('cInetNetToMediaLastUpdated')
	&& 
	$_[0]->contains_label('cInetNetToMediaPhysAddress')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
