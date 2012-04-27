package SNMP::Class::Varbind::CInetNetToMediaEntryInstance;

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
	(
		( $_[0]->get_label eq 'cInetNetToMediaPhysAddress' )
		||
		( $_[0]->get_label eq 'cInetNetToMediaLastUpdated' )
		||
		( $_[0]->get_label eq 'cInetNetToMediaType' )
		||
		( $_[0]->get_label eq 'cInetNetToMediaState' )
	)
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
}

sub if_index {
	return $_[0]->get_instance_oid->slice(1)->to_number;
}

sub address_type {
	#make a new varbind, load it with the appropriate value and return the value
	#the returned value will be the appropriate enum matching the initial number 
	#that was supplied as $_[0]->get_instance_oid->slice(2)->to_number
	return SNMP::Class::Varbind->new(oid=>'cInetNetToMediaNetAddressType',value=>$_[0]->get_instance_oid->slice(2)->to_number)->value;
}

sub address {
	# position 3 is the length of the string. We probably can skip it because we are going to slurp up to the end of the instance oid.
	my @ret;
	my @arr = $_[0]->get_instance_oid->slice(4 .. $_[0]->get_instance_oid->length)->to_array;
	if( $_[0]->address_type eq 'ipv6' ) {
		while ( @arr ) {
			my ($a, $b) = ( shift(@arr) , shift(@arr) );
			push @ret, sprintf("%02x",$a).sprintf("%02x",$b);
		}
		return join(':',@ret);
	}
	else {
		confess 'Type '.$_[0]->address_type.' cannot be handled yet.';
	}
				
}
	

1;
