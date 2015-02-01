#!/usr/bin/perl

use v5.14;

use warnings;
use strict;
use JSON;
use Test::More qw(no_plan);

BEGIN {
        use Data::Dumper;
        use Carp;
        use_ok("SNMP::Class::Fact");
        use_ok("SNMP::Class::FactSet::Simple");
}



my $f1 = SNMP::Class::Fact->new( type => 'test1' , slots => { 'alpha' => 'beta' , 'gamma' => 'delta' } );
isa_ok($f1,'SNMP::Class::Fact');
is($f1->to_string,'test1 (alpha "beta") (gamma "delta")','to_string method');
my $f0 = SNMP::Class::Fact->new( 'test1' );
isa_ok($f0,'SNMP::Class::Fact');

my $frozen = $f1->serialize;
my $f2 = SNMP::Class::Fact::unserialize( $frozen );


is($f2->to_string,'test1 (alpha "beta") (gamma "delta")','serialize and unserialize a fact');


my $f3 = SNMP::Class::Fact->new( frozen => $frozen );

is($f3->to_string,'test1 (alpha "beta") (gamma "delta")','serialize and unserialize via the constructor');


ok( $f1->matches( type => 'test1' ), 'matches test1 fact');
ok( $f1->matches( type => 'test1', slots => { 'gamma' => 'delta' }  ), 'matches test1 fact with slots');
ok( $f1->matches( $f2 ), 'matches with another fact');
ok( ! $f1->matches( type => 'something else' ) , 'does not match something else');

ok( $f1->matches( 'test1' ), 'matches test1 fact via implicit type');
ok( $f1->matches( $f0 ), 'matches test1 fact via implicit type, test 2');

my $fs1 = SNMP::Class::FactSet::Simple->new;

$fs1->push( $f1, $f2, $f3 );

ok( $fs1->grep( sub { $_->type eq 'test1' } ), 'grep method test');
ok( $fs1->grep( sub { $_->type eq 'test1' } )->item(0)->matches( 'test1' ), 'grep, then item, then match');


my $serialized = $fs1->serialize;

my $fs2 = SNMP::Class::FactSet::Simple::unserialize( $serialized );

ok( $fs2->count == 3 , 'serialized factset keeps the same number of items');

my $json = $f1->TO_JSON;
###is($json,'{"type":"test1","slots":{"gamma":"delta","alpha":"beta"}}','serialize object to json');
is_deeply( from_json( $json ) , from_json( '{"type":"test1","slots":{"gamma":"delta","alpha":"beta"}}' ), 'serialize object to json');

my $f4 = SNMP::Class::Fact::FROM_JSON( $json );
my $f5 = SNMP::Class::Fact->new( json => $json );
isa_ok($f4,'SNMP::Class::Fact');
isa_ok($f5,'SNMP::Class::Fact');
ok( $f1->matches( $f4 ), 'json serialize and deserialize using TO_JSON and FROM_JSON');
ok( $f1->matches( $f5 ), 'json serialize and deserialize using TO_JSON and constructor');


$json = $f0->TO_JSON;
is($json,'{"type":"test1","slots":{}}','serialize object to json');
$f4 = SNMP::Class::Fact::FROM_JSON( $json );
$f5 = SNMP::Class::Fact->new( json => $json );
isa_ok($f4,'SNMP::Class::Fact');
isa_ok($f5,'SNMP::Class::Fact');
ok( $f0->matches( $f4 ), 'json serialize and deserialize using TO_JSON and FROM_JSON');
ok( $f0->matches( $f5 ), 'json serialize and deserialize using TO_JSON and constructor');

$json = $fs1->TO_JSON;
###say $json;
my $fs3 = SNMP::Class::FactSet::Simple::FROM_JSON( $json );
isa_ok($fs3,'SNMP::Class::FactSet::Simple');

for (my $i=0;$i<$fs3->count;$i++) {
	ok( $fs3->item($i)->matches( $fs1->item($i) ) , "item $i matches" )
}

