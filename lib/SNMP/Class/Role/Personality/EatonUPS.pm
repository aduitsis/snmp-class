package SNMP::Class::Role::Personality::EatonUPS;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'EatonUPS';
our $description = 'is an Eaton Uninterrupted Power Supply';

our @required_oids = qw(eaton);

our @dependencies = qw(SNMP::Class::Role::Personality::SNMP_Agent);

sub get_facts {
        my $s = shift // confess 'incorrect call';

	my @r = ();

	$s->has_exact( xupsEnvAmbientTemp => 0 )
	&&
	push @r , SNMP::Class::Fact->new(
		type	=> 'temperature',
		slots 	=> {
			system		=> $s->sysname,
			engine_id	=> $s->engine_id,
			id		=> 'ambient',
			value		=> $s->xupsEnvAmbientTemp(0)->value,
		},
	);

	$s->has_exact( xupsEnvRemoteTemp => 0 )
	&&
	push @r , SNMP::Class::Fact->new(
		type	=> 'temperature',
		slots 	=> {
			system		=> $s->sysname,
			engine_id	=> $s->engine_id,
			id		=> 'remote',
			value		=> $s->xupsEnvRemoteTemp(0)->value,
		},
	);

	return @r
}

sub predicate {
        does_role($_[0] , 'SNMP::Class::Role::Personality::SNMP_Agent')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {  
        SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
        DEBUG __PACKAGE__.' personality activated';
}

