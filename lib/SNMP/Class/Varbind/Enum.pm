package SNMP::Class::Varbind::Enum;

use Moose::Role;
use Carp;
use Data::Dumper;
use Data::Printer;
use Log::Log4perl qw(:easy);
use List::Util qw(max);


#has 'absolute_time' => (
#	is => 'ro',
#	isa => 'Str',
#	lazy => 1,
#	reader => 'get_absolute',
#	default => sub { scalar localtime ($_[0]->raw_value + time)  },
#);

has 'value_separator' => (
	is	=> 'rw',
	isa	=> 'Str',
	default	=> ' ',
);

	
#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Varbind module is actually loaded
INIT {
	SNMP::Class::Varbind::register_plugin(__PACKAGE__);
	DEBUG __PACKAGE__." plugin activated";
}

sub matches {
	### if in the future we decide to move the BITS pseudotype in a separate plugin
	### ( $_[0]->has_label ) && SNMP::Class::Utils::has_enums( $_[0]->get_label ) && ( $_[0]->get_syntax ne 'BITS' );
	( $_[0]->has_label ) && SNMP::Class::Utils::has_enums( $_[0]->get_label );
}	

sub adopt {
	if(matches($_[0])) { 
		__PACKAGE__->meta->apply($_[0]);
		TRACE "Applying role ".__PACKAGE__." to ".$_[0]->get_label;
	}
}

sub values {
	if( $_[0]->get_syntax eq 'BITS' ) {
                my @bits = unpack('(a1)*',unpack('B*',$_[0]->raw_value));
		if ( ! @bits ) { 
			WARN 'cannot extract bits from object. Maybe raw value is undef?';
			return
		}
		my $bits_size = scalar @bits; 
		my %enum = %{ SNMP::Class::Utils::enums_of($_[0]->get_label) } ;
		if (! %enum ) { 
			WARN 'cannot determine the enum hash for '.$_[0]->get_label;
			return;
		}
		my $max_index = max keys %enum;
		if( $max_index > scalar @bits ) {
			WARN 'The maximum index '.$max_index.' for the BITS '.$_[0]->get_label.' exceeds the bit size '.$bits_size.' of the raw value. Returning undef';
			return
		}
		### TRACE join(' ',keys(%{ SNMP::Class::Utils::enums_of($_[0]->get_label) }));
		return ( map { $enum{ $_ } } ( grep { $bits[ $_ ] == 1 }  ( keys %enum ) ) )
	} 
	else {
		WARN 'Tried to call values method on an object that has not a syntax of BITS. Returning undef';
		return
	}
}	

sub value {

	# SNMP.pm returns enums for the BITS pseudotype, so we'll handle it right here
	if( $_[0]->get_syntax eq 'BITS' ) { 
		return join($_[0]->value_separator,$_[0]->values);
	}

	my $value = SNMP::Class::Utils::enums_of($_[0]->get_label)->{$_[0]->raw_value};
	#this should try to handle the case of values not having a corresponding mapping (e.g due to mib impl. errors etc.
	#in the future when we get to have proper exceptions, this should emit an exception which could be possibly picked up
	#TODO: review following behaviour again
	if (! defined($value) ) {
		WARN 'For '.$_[0]->to_string.', value '.$_[0]->raw_value.
			' does not have a valid corresponding enum. This would return an undef value, so I will return the raw number instead';
		return $_[0]->raw_value;
	}
	return SNMP::Class::Utils::enums_of($_[0]->get_label)->{$_[0]->raw_value};
}


1;
