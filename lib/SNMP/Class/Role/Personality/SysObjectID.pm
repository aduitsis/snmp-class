package SNMP::Class::Role::Personality::SysObjectID;

use Data::Printer;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'SysObjectID';
our $description = 'can identify its model and vendor';

our @required_oids = qw(system);

sub get_facts {
	defined( my $self = shift( @_ ) ) or confess 'incorrect call';

	my %attrs = (
		system => $self->sysname,
		engine_id => $self->engine_id,
		id => $self->sysObjectID(0)->value,
	);
	if(SNMP::Class::OID->new('.1.3.6.1.4.1')->contains($self->sysObjectID(0)->object_id)) {
		$attrs{vendor} = $self->sysObjectID(0)->object_id->slice(1..7)->to_string;
	}
	SNMP::Class::Fact->new(type=>'system',slots=>\%attrs);
};

sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::SNMP_Agent') 
	&& 
	$_[0]->contains_label('sysObjectID')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
