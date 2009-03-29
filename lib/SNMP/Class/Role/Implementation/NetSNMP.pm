package SNMP::Class::Role::Implementation::NetSNMP;

use Log::Log4perl qw(:easy);
use Data::Dumper;
use Moose::Role;
use SNMP::Class::Role::Implementation;


#try to load the SNMP libraries from NetSNMP
my %have;
eval { require SSSSSNMP; SNMP->import(); }; 
if($@) {
	WARN "Sorry...cannot load SNMP"
}
else {
	$have{SNMP} = 1;
}	



with 'SNMP::Class::Role::Implementation';

has '+session' => (
	isa => 'SNMP::Session',
);

sub init {	#no need to use eval here...it is taken care of by the Implementation Role
	defined( my $self = shift ) or confess "missing argument";
	my %params = (
		version => 'Version',
		community => 'Community',
		hostname => 'DestHost',
		port => 'RemotePort',
	); #@@@@ don't forget to take care of the rest of the parameters later!!!

	my @params;
	
	for my $param (keys %params) {
		push @params,($params{$param},$self->{$param}) if defined($self->$param);
	}
	#@@@Insert here any parameter consistency checks
	
	DEBUG "parameters are ".join(',',@params);
	my $session = SNMP::Session->new(@params);
	confess "Undef session returned from SNMP::Session::new with parameters ".join(',',@params) unless defined($session);
	DEBUG "SNMP::Session creation successful";
	return $session;
	
}		

sub snmpget {
	defined( my $self = shift ) or confess "missing argument";
	defined( my $oid = shift ) or confess "missing oid argument";
	confess "Parameter to SNMP::Class::Role::Implementation::NetSNMP::snmpget should be an SNMP::Class::OID" unless $oid->isa("SNMP::Class::OID");
	DEBUG "Trying to get ".$oid->to_string;
	my @a = $self->session->get(SNMP::Class::OID->new($oid)->netsnmpoid);
	confess $self->session->{ErrorStr} if ($self->session->{ErrorNum} != 0);
	confess 'Got NO-SUCH-INSTANCE when tried to ask '.$self->hostname.' for '.$oid->to_string if ($a[0] eq "NOSUCHINSTANCE");		
	return SNMP::Class::Varbind->new(oid=>$oid,value=>$a[0],no_such_object=>($a[0] eq "NOSUCHOBJECT")? 1 : 0);
}
	
			
sub snmpbulkwalk {
	defined( my $self = shift ) or confess "missing argument";
	
	defined( my $oid = shift ) or confess "missing oid argument";	
	confess "Argument not an SNMP::Class::OID" unless $oid->isa('SNMP::Class::OID');
	DEBUG 'Object to bulkwalk is '.$oid->to_string;

	#create the varbind
	my $vb = SNMP::Class::Varbind->new(oid=>$oid);
	confess "vb is not an SNMP::Class::Varbind" unless (ref $vb eq 'SNMP::Class::Varbind');

	#create the bag
	my $ret = SNMP::Class::ResultSet->new;

	#make the initial GET request and put it in the bag
	$vb = $self->snmpget($vb);
	DEBUG $vb->to_varbind_string;
	$ret->push($vb) unless($vb->no_such_object);
	
	#the first argument is definitely 0, we don't want to just emulate an snmpgetnext call
	#the second argument is tricky. Setting it too high (example: 100000) tends to berzerk some snmp agents, including netsnmp.
	#setting it too low will degrade performance in large datasets since the client will need to generate more traffic
	#So, let's set it to some reasonable value, say 10.
	#we definitely should consider giving the user some knob to turn.
	#After all, he probably will have a good sense about how big the is walk he is doing.
	
	my ($temp) = $self->session->bulkwalk(0,10,$vb->generate_netsnmpvarbind); #magic number 10 for the time being
	#make sure nothing went wrong
	confess $self->session->{ErrorStr} if ($self->session->{ErrorNum} != 0);

	for my $object (@{$temp}) {
		my $vb = SNMP::Class::Varbind->new(varbind=>$object);		
		DEBUG $vb->to_varbind_string;
		$ret->push($vb);
	}		
	return $ret;
}


sub snmpgetnext {
	defined( my $self = shift ) or confess "missing argument";
	defined( my $oid = shift ) or confess "missing oid argument";	
	confess "Argument not an SNMP::Class::OID" unless $oid->isa('SNMP::Class::OID');
	DEBUG 'Object to snmpgetnext is '.$oid->to_string;
	my $vb = SNMP::Class::Varbind->new(oid=>$oid);
	my $netsnmp_varbind = $vb->generate_netsnmpvarbind;
	
	my $value = $session{$id}->getnext($netsnmp_varbind);
	confess $self->session->{ErrorStr} if ($self->session->{ErrorNum} != 0);
	
	$vb = SNMP::Class::Varbind->new(varbind=>$netsnmp_varbind);

}


	

BEGIN {
	for my $item (qw(snmpwalk snmpset)) {
	        no strict 'refs';#only temporarily 
	        *{$item} = sub { DEBUG "succeed trivially" };
	        use strict;
	};
}

1;
	