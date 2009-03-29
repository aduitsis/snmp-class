package SNMP::Class::Role::Implementation;
use Log::Log4perl qw(:easy);

use Moose::Role;

requires qw(snmpget snmpwalk snmpbulkwalk snmpset init);

has 'version' => (
	is => 'rw',
	isa => 'Num',
	init_arg => undef,#user must not touch this
);
 
has 'session' => (
	is => 'rw',
	required => 0,
	init_arg => undef,
);

has 'sysname' => (
	is => 'rw',
	isa => 'Str',
	required => 0,
	init_arg => undef,
);

sub create_session {		
	defined( my $self = shift ) or confess "missing argument";
		
	for my $version (@{$self->possible_versions}) {
		DEBUG "trying version $version";
		$self->version($version);
		my $session;
		eval { 
			$self->session( $self->init );
		};
		if($@) {
			DEBUG "Cannot init with version $version (reason: $@) ... go to next";
			next;
		}
		
		my $sysname;
		eval {
			$sysname = $self->snmpget(SNMP::Class::OID->new("sysName.0"));
		};
		if($@) {
			DEBUG "Cannot query sysName.0 with version $version (reason: $@) ... go to next";
			next;
		}

		DEBUG 'Got sysname='.$sysname->value;

		return;
	}
	confess "Cannot create a session to ".$self->hostname;		
}


sub get {
	return $_[0]->snmpget(SNMP::Class::OID->new($_[1]));
}

sub bulk {
	return $_[0]->snmpbulkwalk(SNMP::Class::OID->new($_[1]));
}		



1;