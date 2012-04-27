package SNMP::Class::Varbind::Hex_Generic;

use Moose::Role;
use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);

has 'hex_value_delimiter' => (
	is => 'rw',
	writer => 'set_hex_value_delimiter',
	default => ' ',
	isa => 'Str',
);

has 'hex_bytes_per_item' => (
	is => 'rw',
	writer => 'set_hex_bytes_per_item',
	default => 2,
	isa => 'Num',
);

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Varbind module is actually loaded
INIT {
	SNMP::Class::Varbind::register_plugin(__PACKAGE__);
	DEBUG __PACKAGE__." plugin activated";
}

sub matches {
	( $_[0]->has_label ) && (
		( $_[0]->get_label eq 'snmpEngineID')
		||
		($_[0]->get_label eq 'dot1dStpPortDesignatedPort')
	);
	#DEBUG SNMP::Class::Utils::textual_convention_of( $_[0]->get_label );
	#DEBUG SNMP::Class::Utils::syntax_of( $_[0]->get_label );
	#DEBUG SNMP::Class::Utils::type_of( $_[0]->get_label );
}	

sub adopt {
	if(matches($_[0])) { 
		#### TRACE "Applying role ".__PACKAGE__." to ".$_[0]->get_label;
		__PACKAGE__->meta->apply($_[0]);
		$_[0]->set_hex_value_delimiter(' ');
	}
}

sub hex_generic_upack_spec {
	return '(H' . $_[0]->hex_bytes_per_item . ')*';
}

sub hex_generic_array {
	defined($_[0]->raw_value) or confess 'Undefined raw value';
	return ( unpack $_[0]->hex_generic_upack_spec , $_[0]->raw_value );
}

sub hex_generic_value {
	return uc join($_[0]->hex_value_delimiter,( $_[0]->hex_generic_array ) );
}

sub value {
	return hex_generic_value(@_);
}


1;
