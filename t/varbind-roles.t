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
does_ok($v7,'SNMP::Class::Varbind::DisplayHint',' does the DisplaHint role');



