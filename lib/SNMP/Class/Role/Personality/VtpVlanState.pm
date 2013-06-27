package SNMP::Class::Role::Personality::VtpVlanState;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'VtpVlanState';
our $description = 'has VTP managed vlans (Cisco specific)';

our @required_oids = qw( vtpVlanName vtpVlanState vtpVlanType vtpVlanMtu vtpVlanIfIndex );

our @dependencies = qw(SNMP::Class::Role::Personality::Interfaces SNMP::Class::Role::Personality::ManagementDomainName);

sub get_facts {
	defined( my $s = shift( @_ ) ) or confess 'incorrect call';
	$s->vtpVlanState->map(sub {
		my %r = (
			system => $s->sysname,
			engine_id => $s->engine_id,
			name => $s->vtpVlanName($_->get_instance_oid)->value,
			state => $s->vtpVlanState($_->get_instance_oid)->value,
			type => $s->vtpVlanType($_->get_instance_oid)->value,
			mtu => $s->vtpVlanMtu($_->get_instance_oid)->value,
			###dot10said => $s->vtpVlanDot10Said($_->get_instance_oid)->value,
			###type_extensions => $s->vtpVlanTypeExt($_->get_instance_oid)->value,
			#instance has two parts, 1:vtp domain index and 2:vlan number
			vlan => $_->get_instance_oid->slice(2)->to_number,
			vtp_domain => $s->managementDomainName($_->get_instance_oid->slice(1))->value,
		);
		#some stupid cisco devices have no vtpVlanIfIndex
		if(
			( $s->has_exact('vtpVlanIfIndex',$_->get_instance_oid) )
			&&
			( $s->vtpVlanIfIndex($_->get_instance_oid)->value != 0 )
		) {
			$r{interface} = $s->get_ifunique($s->vtpVlanIfIndex($_->get_instance_oid)->value);
		}
		SNMP::Class::Fact->new(
			type => 'vlan',
			slots => \%r,
		);
	});    
}


sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::ManagementDomainName') 
	&&
	does_role($_[0] , 'SNMP::Class::Role::Personality::Interfaces') 
	&& 
	$_[0]->contains_label('vtpVlanState')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
