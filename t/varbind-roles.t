#!/usr/bin/perl

use warnings;
use strict;
use Test::More qw(no_plan);
use Test::Moose;

BEGIN {
	use Data::Dumper;
	use Carp;
	use_ok("NetSNMP::OID");
	use_ok("SNMP::Class");
}



my $v7 = SNMP::Class::Varbind->new(oid=>"ifPhysAddress.35", value=>"GHIJKL", type=>'OCTETSTR');
isa_ok($v7,"SNMP::Class::Varbind");

meta_ok($v7,'has a meta method');

my $arr1 = [ SNMP::Class::Varbind->new(oid=>'dot3ControlFunctionsSupported.10', value=>pack('N',hex('0xf0f0abf0')))->values ];
my $arr2 = [ 'pause' ];
is_deeply( $arr1, $arr2, 'The BITS pseudosyntax works correctly' );


# test our displayhint implementation
my $v9 = SNMP::Class::Varbind->new( oid => 'ipv6InterfaceIdentifier.111' , value => 'ABCDEFGH' , type => 'OCTETSTR' ) ;
isa_ok($v9,"SNMP::Class::Varbind");
does_ok($v9,'SNMP::Class::Varbind::DisplayHint','ipv6InterfaceIdentifier does the DisplayHint role');
is( $v9->value , '4142:4344:4546:4748' , 'DisplayHint is returned correctly' ) ; 

