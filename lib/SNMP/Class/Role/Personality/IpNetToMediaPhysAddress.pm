package SNMP::Class::Role::Personality::IpNetToMediaPhysAddress;

use Data::Printer;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'IpNetToMediaPhysAddress';
our $description = 'has ARP entries';

our @required_oids = qw(ipNetToMediaPhysAddress ipNetToMediaType);

sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::Interfaces') 
	&& 
	$_[0]->contains_label('ipNetToMediaPhysAddress')
}

sub get_facts {

	defined( my $s = shift( @_ ) ) or confess 'incorrect call';

	# following call returns array of SNMP::Class::Facts
        $s->ipNetToMediaPhysAddress->map(sub {
                if($s->has_exact('ipNetToMediaType',$_->get_instance_oid)) {    
                        SNMP::Class::Fact->new(
				type => 'arp_table',
                                slots => {
					system => $s->sysname,
					engine_id => $s->engine_id,
					mac_address => $_->value,
					ip_address => $_->ip_address,
					interface => $s->get_ifunique($_->if_index),
					type => $s->ipNetToMediaType($_->get_instance_oid)->value,
				},
                        );
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
