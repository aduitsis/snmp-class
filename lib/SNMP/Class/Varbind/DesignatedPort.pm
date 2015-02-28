package SNMP::Class::Varbind::DesignatedPort;

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
	( $_[0]->get_label eq 'dot1dStpPortDesignatedPort')
}	

sub adopt {
	if(matches($_[0])) { 
		__PACKAGE__->meta->apply($_[0]);
		TRACE "Applying role ".__PACKAGE__." to ".$_[0]->get_label;
		
		SNMP::Class::Varbind::Hex_Generic->meta->apply($_[0]);
		$_[0]->set_hex_value_delimiter(':');
	}
}

#sub value {
#	return uc join(':',(unpack '(H2)*',$_[0]->raw_value))
#}

sub parts { 
	( unpack 'CC',$_[0]->raw_value )
}
sub port_priority {
	( $_[0]->parts )[0]
}

sub port_id {
	( $_[0]->parts )[1]
}

1;
