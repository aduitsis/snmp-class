package SNMP::Class::Varbind::Enum;

use Moose::Role;
use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);


#has 'absolute_time' => (
#	is => 'ro',
#	isa => 'Str',
#	lazy => 1,
#	reader => 'get_absolute',
#	default => sub { scalar localtime ($_[0]->raw_value + time)  },
#);

	
#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Varbind module is actually loaded
INIT {
	SNMP::Class::Varbind::register_plugin(__PACKAGE__);
	DEBUG __PACKAGE__." plugin activated";
}

sub matches {
	( $_[0]->has_label ) && SNMP::Class::Utils::has_enums( $_[0]->get_label );
}	

sub adopt {
	if(matches($_[0])) { 
		__PACKAGE__->meta->apply($_[0]);
		TRACE "Applying role ".__PACKAGE__." to ".$_[0]->get_label;
	}
}

sub value {
	return SNMP::Class::Utils::enums_of($_[0]->get_label)->{$_[0]->raw_value};
}


1;
