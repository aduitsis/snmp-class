
use warnings;
use strict;

use Test::More qw(no_plan);
use Test::Exception;

BEGIN { 
	use_ok("SNMP::Class");
	use_ok('SNMP::Class::Serializer');
}


if( SNMP::Class::Serializer::can_serialize ) {
	my $blob = SNMP::Class::Serializer->encode({ alpha => 'beta' });
	is_deeply( SNMP::Class::Serializer->decode( $blob ) , { alpha => 'beta' } , 'serialization and vice versa works');
}
else {
	dies_ok sub { SNMP::Class::Serializer->encode({ alpha => 'beta' }) } , 'Serialization cannot work as expected';
} 
