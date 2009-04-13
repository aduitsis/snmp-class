#!/usr/bin/perl

use warnings;
use strict;
use Test::More qw(no_plan);

BEGIN {
	use Data::Dumper;
	use Carp;
	use_ok("SNMP::Class");
}

my ($oid,$oid10);

my $oid2 = SNMP::Class::OID->new(".1.2.3.4.5");
isa_ok($oid2,'SNMP::Class::OID');

SKIP: {
	eval { 
		require NetSNMP::OID;
		NetSNMP::OID->import;
	};

	skip "tests that require NetSNMP::OID",3  if $@;	
	
	$oid = NetSNMP::OID->new(".1.2.3.4.5");
	isa_ok($oid,'NetSNMP::OID');

	$oid10 = SNMP::Class::OID->new($oid);
	isa_ok($oid10,'SNMP::Class::OID');

	ok($oid2 == SNMP::Class::OID->new($oid),"basic OID comparison and construction from NetSNMP::OID");
	
	isa_ok($oid2->netsnmpoid,"NetSNMP::OID");

}

my $oid221 = SNMP::Class::OID->new([1,2,3,4]);
isa_ok($oid221,'SNMP::Class::OID');
ok($oid221->length == 4,"length method");
ok($oid221->numeric eq '.1.2.3.4',"numeric method");


my $oid223 = SNMP::Class::OID->new("ifName");
isa_ok($oid223,'SNMP::Class::OID');

my $oid222 = SNMP::Class::OID->new("ifName.5");
isa_ok($oid222,'SNMP::Class::OID');





my $oid4 = SNMP::Class::OID->new(".1.2.3.4.5.6");


my $oid_z = SNMP::Class::OID->new("0");
my $oid_dotz = SNMP::Class::OID->new(".0");


my $oid3 = SNMP::Class::OID->new_from_string("foo");

my $oid9 = $oid2 . ".1.2.3";
my $oid99 = ".1.2.3" . $oid2;

my $zDz = SNMP::Class::OID->new("0.0");


ok($oid9->numeric eq '.1.2.3.4.5.1.2.3',"Concatenation of object and string");
ok($oid99->numeric eq '.1.2.3.1.2.3.4.5',"Reverse concatenation");
ok(($oid2.$oid2)->numeric eq '.1.2.3.4.5.1.2.3.4.5',"Concatenation of objects");
ok(($oid2.$zDz)->numeric eq '.1.2.3.4.5',"Concatenation of object to zeroDotZero");
ok(($zDz.$oid2)->numeric eq '.1.2.3.4.5',"Concatenation of zeroDotZero to object");
ok($oid2 == ".1.2.3.4.5","Comparison to string");
ok($oid2 > ".1.2.3","Comparison to smaller oid");
ok($oid2 < ".1.2.3.4.5.6","Comparison to bigger oid");
ok($oid2 < ".1.2.3.4.6","Comparison to bigger oid (2)");
ok($oid2 < ".2.2.3.4.5","Comparison to bigger oid (3)");
ok($oid2 > ".1.1.3.4.5","Comparison to smaller oid (2)");
ok($oid2 == $oid2,"Comparison");
ok('1.2.3.4.5' == $oid2,"reverse comparison");
ok($oid2->oid_is_equal($oid2),"Comparison using oid_is_equal");
ok($oid2->oid_is_equal('.1.2.3.4.5'),"Comparison using oid_is_equal");
ok($oid2 eq $oid2,"Comparison using cmp");
ok($oid2->contains($oid4),"Hierarchy checking");
ok($oid2->contains(".1.2.3.4.5.6"),"Hierarchy checking with string argument");
ok($oid3 == SNMP::Class::OID->new(".3.102.111.111"),"String conversion test");
ok($oid2->[0] eq 1,"array reference overloading subscript");
is_deeply($oid_z->to_array,(0),"zero oid numeric representation"); 
ok($oid_z->numeric eq '.0',"zero oid string representation"); 
is_deeply($oid_dotz->to_array,(0),"zero oid array representation"); 
is_deeply($zDz->to_arrayref,[0,0],'zero dot array representation');
ok($zDz->to_string eq 'zeroDotZero','zero dot zero string representation');
ok($zDz->numeric eq '.0.0','zero dot zero numeric representation');
ok($oid_dotz->numeric eq '.0',"zero oid string representation"); 
ok($oid2->numeric eq ".1.2.3.4.5" ,"oid numeric method");
ok($oid2->slice(1,2,3,4) == SNMP::Class::OID->new(".1.2.3.4"),"oid slicing explicit");
ok($oid2->slice(1,4) == SNMP::Class::OID->new(".1.2.3.4"),"oid slicing implicit");
ok($oid2->slice(1..4) == SNMP::Class::OID->new(".1.2.3.4"),"oid slicing with range");
ok($oid2->slice(1..1) == SNMP::Class::OID->new(".1"),"oid slicing with 1 member");
ok($oid2->slice(1) == SNMP::Class::OID->new(".1"),"oid slicing with 1 argument");
eval { $oid2->slice(2,1) }; ok($@,"reverse slice failure");
#####
my $oid15 = SNMP::Class::OID->new("ifDescr.14");
ok($oid15->get_label_oid == "ifDescr","get_label_oid on ifDescr.14");
ok($oid15->get_instance_oid == ".14","get_instance_oid on ifDescr.14");
my $oid16 = SNMP::Class::OID->new("ifTable");
ok($oid16->get_label_oid == "ifTable","get_label_oid on ifTable");
eval { $oid16->get_instance_oid };
ok($@,"get_instance_oid on ifTable should fail");
ok(!$oid16->has_instance,"has_instance returns false for ifTable");
my $oid17 = SNMP::Class::OID->new(".10.11.12");
eval { $oid17->get_label_oid };
ok($@,"get_label_oid should fail for something that does not exist");
ok(!$oid17->has_label,"has_label returns false for something that doesn't exist");
eval { $oid17->get_instance_oid };
ok($@,"get_instance_oid should fail for something that does not exist");
ok(!$oid17->has_instance,"has_instance returns false for something that doesn't exist");
my $oid18 = SNMP::Class::OID->new("sysUpTime.0");
ok($oid18->get_label_oid == "sysUpTimeInstance","get_label_oid on sysUpTime");
eval { $oid18->get_instance_oid };
ok($@,"get_instance_oid should fail on something that does not have one");
my $oid19 = SNMP::Class::OID->new("sysName.0");
ok($oid19->get_label_oid == "sysName","get_label_oid on ifDescr.14");
ok($oid19->get_instance_oid == ".0","get_instance_oid on ifDescr.14");




