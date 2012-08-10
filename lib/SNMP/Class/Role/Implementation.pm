package SNMP::Class::Role::Implementation;
use Log::Log4perl qw(:easy);

use Moose::Role;

requires qw(snmpget snmpwalk snmpbulkwalk snmpset init);

has 'version' => (
	is => 'rw',
	isa => 'Num',
	init_arg => undef,#user must not touch this
);

 
#this used to be uncommented, but, at some Moose
#version, using +session in one of the actual implementations
#(example: SNMP::Class::Role::Implementation::NetSNMP)
#became something that is not allowed. 

#has 'session' => (
#	is => 'rw',
#	required => 0,
#	init_arg => undef,
#);

has 'sysname' => (
	is => 'ro',
	isa => 'Str',
	required => 0,
	#init_arg => undef, #commented out because each application of a role overwrites the original value if this is undef
	writer => '_set_sysname',
);

has 'engine_id' => (
	is => 'ro',
	isa => 'Maybe[Str]',
	required => 0,
	#init_arg => undef, #commented out because each application of a role overwrites the original value if this is undef
	default => '',
	writer => '_set_engine_id',
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
			DEBUG "Cannot query sysName.0 with version $version (reason: $@) ... going to the next possible snmp version";
			next;
		}

		DEBUG $self->hostname.':sysname='.$sysname->value;
		$self->_set_sysname( $sysname->value );

		#let us also get the engine id
		if($self->version > 1) {
			eval {
				my $id = $self->snmpget(SNMP::Class::OID->new('snmpEngineID.0'));
				DEBUG $self->hostname.':SNMP Engine ID is '.$id->value;
				$self->_set_engine_id( $id->value );
			};
			if($@) {
				WARN 'Agent '.$self->hostname.'  does not have an engine id: '.$@;
			}
		}

		return $self;#someone might want to use our object directly in the same line with the create_session method
	}
	confess "Cannot create a session to ".$self->hostname.' using versions '.join(',',@{$self->possible_versions});		
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
		#maybe after the looping detection was added bellow this is not necessary
		#TODO: review again
		###if($previous->oid_is_equal( $returned_vb )) { 
		###	confess "OID not increasing at ".$returned_vb->to_varbind_string." (".$returned_vb->numeric.")\n";
		###}

		#make sure we are not looping. Some stupid agents can go on looping forever. 
		#we are using the numeric method as this will incur only a fast operation in the implementation of ResultSet
		#TODO: review again 
		if( $ret->has_numeric($returned_vb->numeric) ) {
			WARN 'This agent has a serious bug. It keeps looping back to '.$returned_vb->numeric;
			last LOOP;
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
