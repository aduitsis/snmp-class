package SNMP::Class::Varbind::SysUpTime;

use Moose::Role;
use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);



has 'absolute_time' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	reader => 'get_absolute',
	default => sub { scalar localtime ($_[0]->raw_value + time)  },
);
	
#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Varbind module is actually loaded
INIT {
	SNMP::Class::Varbind::register_plugin(__PACKAGE__);
	DEBUG __PACKAGE__." plugin activated";
}

sub matches {
	$_[0]->get_label eq 'sysUpTimeInstance';
}	

sub adopt {
	if(matches($_[0])) { 
		__PACKAGE__->meta->apply($_[0]);
		DEBUG "one of us now";
	}
}

1;
