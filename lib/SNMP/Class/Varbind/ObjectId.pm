package SNMP::Class::Varbind::ObjectId;

use Moose::Role;
use warnings;
use strict;
use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);

my $logger = Log::Log4perl->get_logger;

INIT {
        SNMP::Class::Varbind::register_plugin(__PACKAGE__);
        DEBUG __PACKAGE__." plugin activated";
}


sub matches {
        #DEBUG SNMP::Class::Utils::textual_convention_of( $_[0]->get_label );
        #DEBUG SNMP::Class::Utils::syntax_of( $_[0]->get_label );
        #DEBUG SNMP::Class::Utils::type_of( $_[0]->get_label );
	return 1 if (
		( $_[0]->has_syntax ) && (
			( SNMP::Class::Utils::syntax_of( $_[0]->get_label ) eq 'OBJECT IDENTIFIER') 
			||
			( SNMP::Class::Utils::syntax_of( $_[0]->get_label ) eq 'OBJECTID') #this is ugly, but NetSNMP returns 'OBJECTID' instead of 'OBJECT IDENTIFIER'
		)
	);
	return;
}

sub adopt {
        if(matches($_[0])) { 
                DEBUG "Applying role ".__PACKAGE__." to ".$_[0]->get_label;
                __PACKAGE__->meta->apply($_[0]);
        }
}

sub object_id {
	defined($_[0]->raw_value) or confess 'Undefined raw value';
	return SNMP::Class::OID->new($_[0]->raw_value);
}

sub value {
        return $_[0]->object_id->to_string;
}

#sub to_string {
#	return $_[0]->value->numeric;
#}


1;
