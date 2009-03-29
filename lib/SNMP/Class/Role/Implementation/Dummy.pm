package SNMP::Class::Role::Implementation::Dummy;

use Log::Log4perl qw(:easy);
use Data::Dumper;
use Moose::Role;
use SNMP::Class::Role::Implementation;

with 'SNMP::Class::Role::Implementation';

has '+session' => (
	isa => 'Str',  #this dummy package just returns a dummy string as a session
); 

BEGIN {
	for my $item (qw(snmpget snmpwalk snmpbulkwalk snmpset)) {
	        no strict 'refs';#only temporarily 
	        *{$item} = sub { DEBUG "succeed trivially"; return "$item dummy return value"; };
	        use strict;
	};
}

sub init {
	defined( my $self = shift ) or confess "missing argument";
	return "Session with ".$self->hostname." and version ".$self->version." created trivially";
}

1;
	