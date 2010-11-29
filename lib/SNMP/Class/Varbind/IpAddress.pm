package SNMP::Class::Varbind::IpAddress;

use Moose::Role;
use warnings;
use strict;
use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);



INIT {
        SNMP::Class::Varbind::register_plugin(__PACKAGE__);
        DEBUG __PACKAGE__." plugin activated";
}


sub matches {
        #DEBUG SNMP::Class::Utils::textual_convention_of( $_[0]->get_label );
        #DEBUG SNMP::Class::Utils::syntax_of( $_[0]->get_label );
        #DEBUG SNMP::Class::Utils::type_of( $_[0]->get_label );
	return 1 if (
		( SNMP::Class::Utils::syntax_of( $_[0]->get_label ) eq 'IpAddress') 
		||
		( SNMP::Class::Utils::syntax_of( $_[0]->get_label ) eq 'IPADDR') #this is ugly, but NetSNMP returns 'IPADDR' instead of 'IpAddress'
	);
	return;
}

sub adopt {
        if(matches($_[0])) { 
                DEBUG "Applying role ".__PACKAGE__." to ".$_[0]->get_label;
                __PACKAGE__->meta->apply($_[0]);
        }
}

#sub value {
#        defined($_[0]->raw_value) or confess 'Undefined argument';
#        return join(' ',(unpack '(H2)*',$_[0]->raw_value))
#}


1;
