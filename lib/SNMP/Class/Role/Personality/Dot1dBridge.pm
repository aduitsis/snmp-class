package SNMP::Class::Role::Personality::Dot1dBridge;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'Dot1dBridge';
our $description = 'is an 802.1D bridge';

our @required_oids = qw( dot1dBaseBridgeAddress dot1dBaseType );

sub get_facts {
	defined( my $s = shift( @_ ) ) or confess 'incorrect call';

	SNMP::Class::Fact->new( 
		type => 'bridge',
		slots => {
			system => $s->sysname,
			engine_id => $s->engine_id,
			address => $s->dot1dBaseBridgeAddress(0)->value,
			type => $s->dot1dBaseType(0)->value,
		}
	);
};

sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::SNMP_Agent') 
	&& 
	$_[0]->contains_label('dot1dBaseBridgeAddress')
	&&
	$_[0]->contains_label('dot1dBaseType') 
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
