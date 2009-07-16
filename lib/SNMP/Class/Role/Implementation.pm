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
			$sysname = $self->snmpget(SNMP::Class::OID->new('sysName.0'));
		};
		if($@) {
			DEBUG "Cannot query sysName.0 with version $version (reason: $@) ... go to next";
			next;
		}

		DEBUG 'Got sysname='.$sysname->value;

		return $self;#someone might want to use our object directly in the same line with the create_session method
	}
	confess "Cannot create a session to ".$self->hostname;		
}


sub get {
	return $_[0]->snmpget(SNMP::Class::OID->new($_[1]));
}

sub bulk {
	return $_[0]->snmpbulkwalk(SNMP::Class::OID->new($_[1]));
}	

sub walk {
	defined( my $self = shift ) or confess "missing argument";
	my $oid = SNMP::Class::OID->new(shift);
		
	DEBUG "Object to walk is ".$oid->to_string;

	#we will store the previous-loop-iteration oid here to make sure we didn't enter some loop
	#we init it to something that can't be equal to anything
	my $previous = SNMP::Class::OID->new('.0.0');##let's just assume that no oid can ever be 0.0

	#create the bag
	my $ret = SNMP::Class::ResultSet->new();
	
	#make the initial GET request and put it in the bag
	#@#my $returned_vb = $self->snmpget($oid);
	#@#DEBUG $returned_vb->to_varbind_string;
	#DEBUG $vb->dump;
	#@#$ret->push($returned_vb) unless($returned_vb->no_such_object);

	my $rolling_oid = $oid;
	LOOP: while(1) {
		
		####my $varbind = $vb->generate_varbind;

		#call an SNMP GETNEXT operation
		my $returned_vb = $self->snmpgetnext($rolling_oid);
		DEBUG $returned_vb->to_varbind_string;
		
		#handle some special types
		#For example, a type of ENDOFMIBVIEW means we should stop
#		if($vb->type eq 'ENDOFMIBVIEW') {
#			DEBUG "We should stop because an end of MIB View was encountered";
#			last LOOP;
#		}
		if($returned_vb->end_of_mib) {
				DEBUG $returned_vb->to_varbind_string;
				last LOOP;
		}

		#make sure that we got a different oid than in the previous iteration
		if($previous->oid_is_equal( $returned_vb )) { 
			confess "OID not increasing at ".$returned_vb->to_varbind_string." (".$returned_vb->numeric.")\n";
		}

		#make sure we are still under the original $oid -- if not we are finished
		if(!$oid->contains($returned_vb)) {
			DEBUG $oid->to_string." does not contain ".$returned_vb->to_varbind_string." ... we should stop";
			last LOOP;
		}

		$ret->push($returned_vb);

		#Keep a copy for the next iteration. Remember that only the reference is copied. 
		$previous = $returned_vb;

		#we need to make sure that next iteration we won't use the same $vb
		$rolling_oid = $returned_vb;

	};
	return $ret;
}	
	
sub smart {
	defined( my $self = shift ) or confess "missing argument";	
	
	if ($self->version > 1) {
		return $self->bulk(@_);
	} else {
		return $self->walk(@_);
	}
}



1;
