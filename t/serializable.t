
use warnings;
use strict;

use Test::More qw(no_plan);
use Test::Exception;

BEGIN { 
	use_ok("SNMP::Class");
}

use_ok('SNMP::Class::Role::Serializable');

if( SNMP::Class::Role::Serializable::serializable ) {
	my $blob = SNMP::Class::Role::Serializable::serialize({ alpha => 'beta' });
	is_deeply( SNMP::Class::Role::Serializable::unserialize( $blob ) , { alpha => 'beta' } , 'serialization and vice versa works');
}
else {
	dies_ok sub { SNMP::Class::Role::Serializable::serialize({ alpha => 'beta' }) } , 'Serialization cannot work as expected';
} 
