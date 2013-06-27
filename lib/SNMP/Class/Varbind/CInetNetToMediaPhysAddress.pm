package SNMP::Class::Varbind::CInetNetToMediaPhysAddress;

#this module matches all objects under CInetNetToMediaEntryInstance. It includes
#three methods to ease handling of the three-part instance oid.

use Moose::Role;
use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use List::MoreUtils;

	
#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Varbind module is actually loaded
INIT {
	SNMP::Class::Varbind::register_plugin(__PACKAGE__);
	DEBUG __PACKAGE__." plugin activated";
}

sub matches {
	( $_[0]->has_label ) 
	&& 
	( $_[0]->get_label eq 'cInetNetToMediaPhysAddress' )
	;

	#DEBUG SNMP::Class::Utils::textual_convention_of( $_[0]->get_label );
	#DEBUG SNMP::Class::Utils::syntax_of( $_[0]->get_label );
	#DEBUG SNMP::Class::Utils::type_of( $_[0]->get_label );
}	

sub adopt {
	if(matches($_[0])) { 
		__PACKAGE__->meta->apply($_[0]);
		TRACE "Applying role ".__PACKAGE__." to ".$_[0]->get_label;
	}

	# We also apply the Hex_Generic role because the "1x:" displayhint will produce
	# addresses of the style 0:25:64:94:f2:c8:0:0 and we want 00:25:...
	SNMP::Class::Varbind::Hex_Generic->meta->apply($_[0]);
	$_[0]->set_hex_value_delimiter(':');
}


1;
