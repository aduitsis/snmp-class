package SNMP::Class::Varbind::MacAddress;

use Moose::Role;
use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Varbind module is actually loaded
INIT {
	SNMP::Class::Varbind::register_plugin(__PACKAGE__);
	DEBUG __PACKAGE__.' plugin activated';
}

sub matches {
	( $_[0]->has_label ) 
	&& 
	( SNMP::Class::Utils::has_textual_convention( $_[0]->get_label ) )
	&& 
	( grep { $_ eq SNMP::Class::Utils::textual_convention_of( $_[0]->get_label ) } qw(MacAddress PhysAddress) )
	;

	#DEBUG SNMP::Class::Utils::textual_convention_of( $_[0]->get_label );
	#DEBUG SNMP::Class::Utils::syntax_of( $_[0]->get_label );
	#DEBUG SNMP::Class::Utils::type_of( $_[0]->get_label );
}	

sub adopt {
	if(matches($_[0])) { 
		__PACKAGE__->meta->apply($_[0]);
		## TRACE "Applying role ".__PACKAGE__." to ".$_[0]->get_label;
		SNMP::Class::Varbind::Hex_Generic->meta->apply($_[0]);
		$_[0]->set_hex_value_delimiter(':');		
	}
}

#sub value {
#	return uc join(':',(unpack '(H2)*',$_[0]->raw_value))
#}


1;
