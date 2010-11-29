#!/usr/bin/perl

use warnings;
use strict;
use Test::More qw(no_plan);

BEGIN {
	use Data::Dumper;
	use Carp;
	use_ok("NetSNMP::OID");
	use_ok("SNMP::Class");
}



ok(SNMP::Class::Varbind->new(varbind=>bless( ['system','','NOSUCHOBJECT','NOSUCHOBJECT'], 'SNMP::Varbind' ))->no_such_object == 1,"no such object from SNMP::Varbind");

my $vb1 = SNMP::Varbind->new(["ifDescr.33"]);
isa_ok($vb1,"SNMP::Varbind");
my $v4 = SNMP::Class::Varbind->new(varbind=>$vb1);
isa_ok($v4,"SNMP::Class::Varbind");



my $v1 = SNMP::Class::Varbind->new(oid=>SNMP::Class::OID->new('.1.2.3.4'),type=>'INTEGER');
ok($v1->numeric eq '.1.2.3.4',"OID behavior");

my $v2 = SNMP::Class::Varbind->new(oid=>".1.2.3.4.5.1.2.3",type=>'INTEGER');
my $v3 = SNMP::Class::Varbind->new(oid=>SNMP::Class::OID->new('ifDescr.14'),value=>"ethernet0",type=>"OCTETSTR");
my $v5 = SNMP::Class::Varbind->new(oid=>"ipAdEntAddr.1.2.3.4",value=>"192.168.1.1",type=>'IPADDR');
my $v6 = SNMP::Class::Varbind->new(oid=>"sysUpTime.0", value=>"1111", type=>'TIMETICKS');
isa_ok($v1,"SNMP::Class::Varbind");
isa_ok($v2,"SNMP::Class::Varbind");
isa_ok($v3,"SNMP::Class::Varbind");
isa_ok($v5,"SNMP::Class::Varbind");
isa_ok($v5,"SNMP::Class::Varbind");
isa_ok($v6,"SNMP::Class::Varbind");


ok($v3->generate_netsnmpvarbind->isa("SNMP::Varbind"),"generate_varbind check");


is($v3->to_varbind_string,"ifDescr.14=ethernet0","to_string method");



my $v7 = SNMP::Class::Varbind->new(oid=>'ifName',type=>'no such object');
ok($v7->no_such_object,"No-such-object condition");
ok($v7->to_varbind_string eq 'ifName(no such object)','No-such-object to_varbind_string');

$v7 = SNMP::Class::Varbind->new(oid=>'ifName',type=>'end of mib');
ok($v7->end_of_mib,"End-of-mib condition");
ok($v7->to_varbind_string eq 'End of MIB','End of mib to_varbind_string');






#print $ifTable->get_value;

#my $ifDescr = $ifTable->object("ifDescr");

#print $ifDescr.1,"\n";


#####print $ifTable->object("ifDescr").3,"\n";


####print $ifTable->find("ifDescr","en0")->object("ifSpeed")->value,"\n";
