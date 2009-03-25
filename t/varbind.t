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

#my $s = SNMP::Class->new({ DestHost => 'localhost' });
#$s->deactivate_bulkwalks;

###my $ifTable = $s->walk("ifTable");

#$ifTable->label("ifDescr","ifSpeed");
#print $ifTable->value("en0")->dump;
#print $ifTable->find("ifDescr"=>"en0")->ifSpeed;

#my $ipf = $s->walk("ipForwarding")->value;

#unless ($ipf->is_forwarding) {
#	print STDERR "NOT forwarding\n\n";
#}

my $vb1 = SNMP::Varbind->new(["ifDescr.33"]);
isa_ok($vb1,"SNMP::Varbind");
my $v4 = SNMP::Class::Varbind->new(varbind=>$vb1);
isa_ok($v4,"SNMP::Class::Varbind");

my $v1 = SNMP::Class::Varbind->new(oid=>SNMP::Class::OID->new('.1.2.3.4'),type=>'INTEGER');
ok($v1->numeric eq '.1.2.3.4',"OID behavior");

my $v2 = SNMP::Class::Varbind->new(oid=>".1.2.3.4.5.1.2.3",type=>'INTEGER');
my $v3 = SNMP::Class::Varbind->new(oid=>SNMP::Class::OID->new('ifDescr.14'),value=>"ethernet0",type=>"OCTET_STRING");
my $v5 = SNMP::Class::Varbind->new(oid=>"ipAdEntAddr.1.2.3.4",value=>"192.168.1.1",type=>'IPADDR');
my $v6 = SNMP::Class::Varbind->new(oid=>"sysUpTime.0", value=>"1111", type=>'TIMETICKS');
isa_ok($v1,"SNMP::Class::Varbind");
isa_ok($v2,"SNMP::Class::Varbind");
isa_ok($v3,"SNMP::Class::Varbind");
isa_ok($v5,"SNMP::Class::Varbind");
isa_ok($v5,"SNMP::Class::Varbind");
isa_ok($v6,"SNMP::Class::Varbind");


ok($v3->generate_varbind->isa("SNMP::Varbind"),"generate_varbind check");


ok($v3->to_string eq "ifDescr.14=ethernet0","to_string method");




#print $ifTable->get_value;

#my $ifDescr = $ifTable->object("ifDescr");

#print $ifDescr.1,"\n";


#####print $ifTable->object("ifDescr").3,"\n";


####print $ifTable->find("ifDescr","en0")->object("ifSpeed")->value,"\n";
