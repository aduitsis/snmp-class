#!/usr/bin/perl

use v5.14;

use warnings;
use strict;
use JSON;
use Test::More qw(no_plan);
use Data::Printer;

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

is($f1->unique_id,$f2->unique_id,'serialization preserves the unique id');

my $f3 = SNMP::Class::Fact->new( frozen => $frozen );

is($f3->to_string,'test1 (alpha "beta") (gamma "delta")','serialize and unserialize via the constructor');

is($f1->unique_id,$f3->unique_id,'serialization preserves the unique id even when using the constructor');


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
my $time = $f1->time;
#say $json;
#p from_json( $json );
#p from_json( '{"time":'.$time.',"type":"test1","slots":{"gamma":"delta","alpha":"beta"}}' );
###is($json,'{"type":"test1","slots":{"gamma":"delta","alpha":"beta"}}','serialize object to json');
is_deeply( from_json( $json ) , from_json( '{"time":'.$time.',"type":"test1","slots":{"gamma":"delta","alpha":"beta"}}' ), 'serialize object to json');


my $f4 = SNMP::Class::Fact::FROM_JSON( $json );
my $f5 = SNMP::Class::Fact->new( json => $json );
isa_ok($f4,'SNMP::Class::Fact');
isa_ok($f5,'SNMP::Class::Fact');
ok( $f1->matches( $f4 ), 'json serialize and deserialize using TO_JSON and FROM_JSON');
ok( $f1->matches( $f5 ), 'json serialize and deserialize using TO_JSON and constructor');
is($f1->unique_id,$f4->unique_id,'json serialization preserves the unique id');
is($f1->unique_id,$f5->unique_id,'json serialization preserves the unique id even when using the constructor');


$json = $f0->TO_JSON;
# ok( ( grep { $json eq $_ } ('{"type":"test1","slots":{}}','{"slots":{},"type":"test1"}') ) ,'serialize object to json');
$f4 = SNMP::Class::Fact::FROM_JSON( $json );
$f5 = SNMP::Class::Fact->new( json => $json );
isa_ok($f4,'SNMP::Class::Fact');
isa_ok($f5,'SNMP::Class::Fact');
ok( $f0->matches( $f4 ), 'json serialize and deserialize using TO_JSON and FROM_JSON');
ok( $f0->matches( $f5 ), 'json serialize and deserialize using TO_JSON and constructor');
is($f0->unique_id,$f4->unique_id,'json serialization preserves the unique id');
is($f0->unique_id,$f5->unique_id,'json serialization preserves the unique id even when using the constructor');

$json = $fs1->TO_JSON;
###say $json;
my $fs3 = SNMP::Class::FactSet::Simple::FROM_JSON( $json );
isa_ok($fs3,'SNMP::Class::FactSet::Simple');

for (my $i=0;$i<$fs3->count;$i++) {
	ok( $fs3->item($i)->matches( $fs1->item($i) ) , "item $i matches" )
}

is( $fs1->time , $fs3->time , 'FactSet JSON serialization preserves time field' );
#say $fs1->TO_JSON;
#say $fs3->TO_JSON;
is($fs1->unique_id,$fs3->unique_id,'factset json serialization preserves the unique id');

is( $fs1->to_string , "(deffacts knowledge_".$fs1->unique_id." \"\" \n(test1 (alpha \"beta\") (gamma \"delta\"))\n(test1 (alpha \"beta\") (gamma \"delta\"))\n(test1 (alpha \"beta\") (gamma \"delta\"))\n)", 'FactSet to_string without arguments'); 
is( $fs1->to_string( exclude_slots => 'alpha' ) , "(deffacts knowledge_".$fs1->unique_id." \"\" \n(test1 (gamma \"delta\"))\n(test1 (gamma \"delta\"))\n(test1 (gamma \"delta\"))\n)", 'FactSet to_string without arguments and scalar exclude_slots'); 
is( $fs1->to_string( exclude_slots => ['alpha'] ) , "(deffacts knowledge_".$fs1->unique_id." \"\" \n(test1 (gamma \"delta\"))\n(test1 (gamma \"delta\"))\n(test1 (gamma \"delta\"))\n)", 'FactSet to_string without arguments and arrayref exclude_slots'); 
$fs1->push(SNMP::Class::Fact->new(type=>'foo',slots=>{ a => 'b' }));
is( $fs1->to_string( exclude_slots => 'alpha', exclude_types => 'foo' ) , "(deffacts knowledge_".$fs1->unique_id." \"\" \n(test1 (gamma \"delta\"))\n(test1 (gamma \"delta\"))\n(test1 (gamma \"delta\"))\n)", 'FactSet to_string without arguments and scalar exclude_slots and scalar exclude_types'); 
is( $fs1->to_string( exclude_slots => 'alpha', exclude_types => [ 'foo' ] ) , "(deffacts knowledge_".$fs1->unique_id." \"\" \n(test1 (gamma \"delta\"))\n(test1 (gamma \"delta\"))\n(test1 (gamma \"delta\"))\n)", 'FactSet to_string without arguments and scalar exclude_slots and arrayref exclude_types'); 
is( $fs1->to_string( include_types=> 'foo', exclude_slots => 'alpha'  ) , "(deffacts knowledge_".$fs1->unique_id." \"\" \n(foo (a \"b\"))\n)", 'FactSet to_string without arguments and scalar exclude_slots and scalar include_types'); 
is( $fs1->to_string( include_types=> ['foo'], exclude_slots => 'alpha'  ) , "(deffacts knowledge_".$fs1->unique_id." \"\" \n(foo (a \"b\"))\n)", 'FactSet to_string without arguments and scalar exclude_slots and arrayref include_types'); 

