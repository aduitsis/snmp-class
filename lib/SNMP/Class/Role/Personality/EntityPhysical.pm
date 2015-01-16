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
		my $r = { 
					system => $self->sysname,
					engine_id => $self->engine_id,
					name => $_->value,
					description => $self->entPhysicalDescr($_->get_instance_oid)->value,
					vendor_type => $self->entPhysicalVendorType($_->get_instance_oid)->value,
					physical_class => $self->entPhysicalClass($_->get_instance_oid)->value,    
		};
		$r->{ hardware_revision } = $self->entPhysicalHardwareRev($_->get_instance_oid)->value	if $self->has_exact( 'entPhysicalHardwareRev', $_->get_instance_oid );
		$r->{ firmware_revision } = $self->entPhysicalFirmwareRev($_->get_instance_oid)->value	if $self->has_exact( 'entPhysicalFirmwareRev', $_->get_instance_oid );
		$r->{ software_revision } = $self->entPhysicalSoftwareRev($_->get_instance_oid)->value	if $self->has_exact( 'entPhysicalSoftwareRev', $_->get_instance_oid ); 	
		$r->{ serial_number } = $self->entPhysicalSerialNum($_->get_instance_oid)->value	if $self->has_exact( 'entPhysicalSerialNum', $_->get_instance_oid );
		$r->{ manufacturer } = $self->entPhysicalMfgName($_->get_instance_oid)->value		if $self->has_exact( 'entPhysicalMfgName', $_->get_instance_oid );
		$r->{ model } = $self->entPhysicalModelName($_->get_instance_oid)->value		if $self->has_exact( 'entPhysicalModelName', $_->get_instance_oid ); 
		$r->{ alias } = $self->entPhysicalAlias($_->get_instance_oid)->value			if $self->has_exact( 'entPhysicalAlias', $_->get_instance_oid );
		$r->{ asset_id } = $self->entPhysicalAssetID($_->get_instance_oid)->value		if $self->has_exact( 'entPhysicalAssetID', $_->get_instance_oid );
		$r->{ is_fru } = $self->entPhysicalIsFRU($_->get_instance_oid)->value			if $self->has_exact( 'entPhysicalIsFRU', $_->get_instance_oid );

		SNMP::Class::Fact->new( 	
				type => 'hardware_entity',
				slots => $r,
		)
		
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
