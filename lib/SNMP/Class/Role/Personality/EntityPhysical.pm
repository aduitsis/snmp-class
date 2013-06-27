package SNMP::Class::Role::Personality::EntityPhysical;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'EntityPhysical';
our $description = 'is a Hardware Entity';


our @required_oids = qw(entPhysicalDescr entPhysicalVendorType entPhysicalContainedIn entPhysicalClass entPhysicalParentRelPos entPhysicalName entPhysicalHardwareRev entPhysicalFirmwareRev entPhysicalSoftwareRev entPhysicalSerialNum entPhysicalMfgName entPhysicalModelName entPhysicalAlias entPhysicalAssetID entPhysicalIsFRU); 

our @dependencies = qw(SNMP::Class::Role::Personality::SNMP_Agent);

sub get_facts {

	defined( my $self = shift( @_ ) ) or confess 'incorrect call';

	$self->entPhysicalName->map(sub {
		SNMP::Class::Fact->new( 	
				type => 'hardware_entity',
				slots => {
					system => $self->sysname,
					engine_id => $self->engine_id,
					name => $_->value,
					description => $self->entPhysicalDescr($_->get_instance_oid)->value,
					vendor_type => $self->entPhysicalVendorType($_->get_instance_oid)->value,
					physical_class => $self->entPhysicalClass($_->get_instance_oid)->value,    
					hardware_revision => $self->entPhysicalHardwareRev($_->get_instance_oid)->value,
					firmware_revision => $self->entPhysicalFirmwareRev($_->get_instance_oid)->value,
					software_revision => $self->entPhysicalSoftwareRev($_->get_instance_oid)->value,
					serial_number => $self->entPhysicalSerialNum($_->get_instance_oid)->value,
					manufacturer => $self->entPhysicalMfgName($_->get_instance_oid)->value,
					model => $self->entPhysicalModelName($_->get_instance_oid)->value,
					alias => $self->entPhysicalAlias($_->get_instance_oid)->value,
					asset_id => $self->entPhysicalAssetID($_->get_instance_oid)->value,
					is_fru => $self->entPhysicalIsFRU($_->get_instance_oid)->value,
				},
		);
	})

}


sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::SNMP_Agent') 
	&& 
	$_[0]->contains_label('entPhysicalName')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
