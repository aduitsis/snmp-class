package SNMP::Class::Role::Personality::ManagementDomainName;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'ManagementDomainName';
our $description = 'implements Cisco VTP';

our @required_oids = qw( managementDomainName managementDomainLocalMode managementDomainRowStatus managementDomainPruningState managementDomainVersionInUse managementDomainLastUpdater );

sub get_facts {
	defined( my $s = shift( @_ ) ) or confess 'incorrect call';
	$s->managementDomainName->map(sub {
		SNMP::Class::Fact->new(
			type => 'vtp_management_domain',
			slots => {
				system => $s->sysname,
				engine_id => $s->engine_id,
				name => $s->managementDomainName($_->get_instance_oid)->value,
				mode => $s->managementDomainLocalMode($_->get_instance_oid)->value,
				status => $s->managementDomainRowStatus($_->get_instance_oid)->value,
				pruning => $s->managementDomainPruningState($_->get_instance_oid)->value,
				vtp_version =>  $s->managementDomainVersionInUse($_->get_instance_oid)->value,
				last_updater => $s->managementDomainLastUpdater($_->get_instance_oid)->value,
			},
		);
	});
}


sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::SNMP_Agent') 
	&& 
	$_[0]->contains_label('managementDomainName')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
