package SNMP::Class::Varbind::IpNetToMediaPhysAddress;

use Moose::Role;
use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);

	
#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Varbind module is actually loaded
INIT {
	SNMP::Class::Varbind::register_plugin(__PACKAGE__);
	DEBUG __PACKAGE__." plugin activated";
}

sub matches {
	( $_[0]->has_label ) 
	&& 
	( $_[0]->get_label eq 'ipNetToMediaPhysAddress' )
	;

	#DEBUG SNMP::Class::Utils::textual_convention_of( $_[0]->get_label );
	#DEBUG SNMP::Class::Utils::syntax_of( $_[0]->get_label );
	#DEBUG SNMP::Class::Utils::type_of( $_[0]->get_label );
}	

sub adopt {
	if(matches($_[0])) { 
		__PACKAGE__->meta->apply($_[0]);
		TRACE "Applying role ".__PACKAGE__." to ".$_[0]->get_label;

		#very interesting!
		#let us try to apply another role: HexGeneric
		SNMP::Class::Varbind::Hex_Generic->meta->apply($_[0]);
		$_[0]->set_hex_value_delimiter(':');
	}
}

sub if_index {
	return $_[0]->get_instance_oid->slice(1)->to_number;
}

sub ip_address {
	#ipv4 addresses only!
	return join('.',$_[0]->get_instance_oid->slice(2..5)->to_array);
}

1;
