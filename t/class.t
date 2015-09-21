
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

$r = $a->snmpgetnext(SNMP::Class::OID->new('sysDescr.0'));

isa_ok($r,'SNMP::Class::Varbind');

$r = $a->walk('system');

#print $r->dump;
#ok( $a->create_time =~ /^\d+$/ , 'create_time returns a number' );


#print $r->dump;

#$r = $a->walk('.1');
#$a = SNMP::Class->new(hostname=>'localhost',cacheable=>1);
#isa_ok($a,"SNMP::Class");
#ok( $a->can('save') , 'has save method' ) ; 
#ok( $a->can('load') , 'has load method' ) ; 

$a = SNMP::Class->new(hostname=>'localhost');
isa_ok($a,"SNMP::Class");
my $v = SNMP::Class::Varbind->new(oid=>"sysUpTime.0", value=>"1111", type=>'TIMETICKS');
$a->push( $v );
is( $a->number_of_items , 1 , 'Session contains one varbind');
my $t1 = $a->create_time;
# test serialization routines
my $s = SNMP::Class->new(hostname=>'localhost');
is( $s->number_of_items , 0 , 'New session contains no varbinds');
$s->unserialize( $a->serialize );
is( $s->number_of_items , 1 , 'Cached session contains one varbind');
my $t2 = $s->create_time;
is( $t1 , $t2 , 'SNMP::Class serialization and unserialization seems to be working' ) ;
