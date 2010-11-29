#!/usr/bin/perl

use warnings;
use strict;
use Test::More qw(no_plan);
use Test::Moose;

BEGIN {
	use Data::Dumper;
	use Carp;
	use_ok("SNMP::Class");
}

#some ideas:
#BEGEMOT-NETGRAPH.txt:    DISPLAY-HINT "31a"
#BEGEMOT-SNMPD.txt:    DISPLAY-HINT "14a"
#CISCO-IETF-IP-MIB.my:     DISPLAY-HINT "2x:"
#CISCO-SWITCH-ENGINE-MIB.my:    DISPLAY-HINT        "1d.1d.1d.1d"
#IF-MIB.txt:    DISPLAY-HINT "255a"
#INET-ADDRESS-MIB.txt:    DISPLAY-HINT "1d.1d.1d.1d"
#INET-ADDRESS-MIB.txt:    DISPLAY-HINT "2x:2x:2x:2x:2x:2x:2x:2x"
#INET-ADDRESS-MIB.txt:    DISPLAY-HINT "1d.1d.1d.1d%4d"
#INET-ADDRESS-MIB.txt:    DISPLAY-HINT "2x:2x:2x:2x:2x:2x:2x:2x%4d"
#INET-ADDRESS-MIB.txt:    DISPLAY-HINT "255a"
#INET-ADDRESS-MIB.txt:    DISPLAY-HINT "d"
#IP-MIB.txt:     DISPLAY-HINT "2x:"
#IPMROUTE-STD-MIB.my:   DISPLAY-HINT "100a"
#SNMP-FRAMEWORK-MIB.txt:    DISPLAY-HINT "255t"
#SNMP-TARGET-MIB.txt:    DISPLAY-HINT "255t"
#SNMP-TARGET-MIB.txt:    DISPLAY-HINT "255t"
#SNMPv2-TC.txt:    DISPLAY-HINT "255a"
#SNMPv2-TC.txt:    DISPLAY-HINT "1x:"
#SNMPv2-TC.txt:    DISPLAY-HINT "1x:"
#SNMPv2-TC.txt:    DISPLAY-HINT "2d-1d-1d,1d:1d:1d.1d,1a1d:1d"
#SNMPv2-TM.txt:    DISPLAY-HINT "1d.1d.1d.1d/2d"
#SNMPv2-TM.txt:    DISPLAY-HINT "*1x:/1x:"
#SNMPv2-TM.txt:    DISPLAY-HINT "4x.1x:1x:1x:1x:1x:1x.2d"
#TOKEN-RING-RMON-MIB.my:       DISPLAY-HINT "255a"
#TRANSPORT-ADDRESS-MIB.txt:    DISPLAY-HINT "1d.1d.1d.1d:2d"
#TRANSPORT-ADDRESS-MIB.txt:    DISPLAY-HINT "0a[2x:2x:2x:2x:2x:2x:2x:2x]0a:2d"
#TRANSPORT-ADDRESS-MIB.txt:    DISPLAY-HINT "1d.1d.1d.1d%4d:2d"
#TRANSPORT-ADDRESS-MIB.txt:    DISPLAY-HINT "0a[2x:2x:2x:2x:2x:2x:2x:2x%4d]0a:2d"
#TRANSPORT-ADDRESS-MIB.txt:    DISPLAY-HINT "1a"
#TRANSPORT-ADDRESS-MIB.txt:    DISPLAY-HINT "1a"


sub foo {
	return SNMP::Class::Varbind::DisplayHint::render_octet_str_with_display_hint(SNMP::Class::Varbind::DisplayHint::parse_display_hint($_[0]),[split('',$_[1])]);
}

sub foo2 {
	return SNMP::Class::Varbind::DisplayHint::render_octet_str_with_display_hint(SNMP::Class::Varbind::DisplayHint::parse_display_hint($_[0]),$_[1]);
}

sub foo3 {
	return foo($_[0],pack('C*',(map { hex $_ } @{$_[1]}  )));
}

is(foo('1x:','KLMNOP'),'4b:4c:4d:4e:4f:50','Display-Hint: 1x:');
is(foo3('2x:',[qw(02 08 7c ff fe 63 e4 00)]),'208:7cff:fe63:e400','Display-Hint: 2x:');

