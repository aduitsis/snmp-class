package SNMP::Class::Role::Personality::CdpCacheAddress;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'CdpCacheAddress';
our $description = 'can talk CDP';

our @required_oids = qw(cdpCacheAddress cdpCacheAddressType);

sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::Interfaces') 
	&& 
	$_[0]->contains_label('cdpCacheAddress')
}

sub get_facts {

	defined( my $s = shift( @_ ) ) or confess 'incorrect call';
	# following call returns array of SNMP::Class::Facts
	$s->cdpCacheAddress->map(sub {
		if($s->cdpCacheAddressType($_->get_instance_oid)->value eq 'ip') {
			my $ip = join('.',map { sprintf hex $_ } split(':',$_->value));
			SNMP::Class::Fact->new(
				type => 'cdp_neighbor',
				slots => {
					system => $s->sysname,
					engine_id => $s->engine_id,
					type => 'ip',
					address => $ip,
					interface => $s->get_ifunique($_->get_instance_oid->slice(1)),
					#device_id => $s->cdpCacheDeviceId( $_->get_instance_oid )->value // '',
					#device_port => $s->cdpCacheDevicePort( $_->get_instance_oid )->value // '',
				},
			);

		}
		else {
			# WARN 'Cannot yet handle this type of CDP neighbor: '. $s->cdpCacheAddressType($_->get_instance_oid)->value;
			return (); # to omit an element from map, we return an empty list
		}
	});
}



#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
