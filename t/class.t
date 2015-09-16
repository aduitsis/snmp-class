
use warnings;
use strict;
use Test::More qw(no_plan);

use Moose::Util qw/find_meta does_role search_class_by_role/;

BEGIN {
	use Data::Dumper;
	use Carp;
	use_ok("SNMP::Class");
}


eval {
	my $a = SNMP::Class->new(hostname=>'localhost',version=>4);
};
ok($@,"invalid version string");


for my $v (1,2,'2c') {
	$a = SNMP::Class->new(hostname=>'localhost',version=>$v);
	isa_ok($a,"SNMP::Class");
}

$a = SNMP::Class->new(hostname=>'localhost');
isa_ok($a,"SNMP::Class");


my $r = $a->bulk('ifTable');

isa_ok($r,'SNMP::Class::ResultSet');

ok( does_role($r , 'SNMP::Class::Role::Serializable') , 'object is serializable' );

$r = $a->snmpgetnext(SNMP::Class::OID->new('sysDescr.0'));

isa_ok($r,'SNMP::Class::Varbind');

$r = $a->walk('system');

#print $r->dump;
ok( $a->create_time =~ /^\d+$/ , 'create_time returns a number' );


#print $r->dump;

#$r = $a->walk('.1');
$a = SNMP::Class->new(hostname=>'localhost',cacheable=>1);
isa_ok($a,"SNMP::Class");
ok( $a->can('save') , 'has save method' ) ; 
ok( $a->can('load') , 'has load method' ) ; 
