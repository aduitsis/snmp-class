
use warnings;
use strict;
use Test::More qw(no_plan);

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


#print $r->dump;

#$r = $a->walk('.1');