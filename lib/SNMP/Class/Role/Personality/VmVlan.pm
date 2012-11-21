package SNMP::Class::Role::Personality::VmVlan;

use Data::Printer; 

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'VmVlan';
our $description = 'has vlans (Cisco specific)';

our @required_oids = qw( vmVlan vmVlanType vmPortStatus );

has 'vlans' => ( 
	is  => 'ro',
	isa => 'HashRef[Int]',
	default => sub { {} },
);
	

sub get_vlans {
	#my %vlans;
	#for( $_[0]->vmVlan ) {
	#	$vlans{ $_->value } = 1;
	#}	
	return keys %{ $_[0]->vlans };
}

sub get_facts {
	defined( my $s = shift( @_ ) ) or confess 'incorrect call';
	grep { defined $_ } ( $s->vmVlan->map(sub {
		# a value of vmVlan==0 means the port has no vlan assigned, ie it must be a native port
		if(($_->value != 0) && $s->has_exact('vmPortStatus',$_->get_instance_oid) && $s->has_exact('vmVlanType',$_->get_instance_oid)) {
			$s->vlans->{ $_->value } = $s->vmVlanType($_->get_instance_oid)->value;
			return SNMP::Class::Fact->new(
				type => 'vlan_port',
				slots => {
					system => $s->sysname,
					engine_id => $s->engine_id,
					interface => $s->get_ifunique($_->get_instance_oid),
					vlan => $_->value,
					type => $s->vmVlanType($_->get_instance_oid)->value,
					status => $s->vmPortStatus($_->get_instance_oid)->value,
				},
			);
		}
		else {
			return
		}
	}));
}


sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::Interfaces') 
	&& 
	$_[0]->contains_label('vmVlan')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
