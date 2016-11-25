#!/usr/bin/perl

use v5.14;

use warnings;
use strict;
use Test::More qw(no_plan);
use Test::Exception;
use Data::Printer;

BEGIN {
        use Data::Dumper;
        use Carp;
        use_ok("SNMP::Class::Fact");
        use_ok("SNMP::Class::FactSet::Simple");
        use_ok("SNMP::Class::Rete");
}



my $i = SNMP::Class::Rete::Instantiation->new( { x => 1 , y => 'xixi' } ) ;
say $i->to_string;
say $i->signature;

my $f1 = SNMP::Class::Fact->new( type => 'test1' , slots => { 'alpha' => 'beta' , 'gamma' => 'delta' } );
isa_ok($f1,'SNMP::Class::Fact');
my $f2 = SNMP::Class::Fact->new( type => 'test2' , slots => { 'epsilon' => 'zeta' , 'eta' => 'delta' } );
isa_ok($f2,'SNMP::Class::Fact');


my $fs1 = SNMP::Class::FactSet::Simple->new( fact_set => [ $f1, $f2 ] );
isa_ok($fs1,'SNMP::Class::FactSet::Simple');

my $a1 = SNMP::Class::Rete::Alpha->new( type => 'test1', bind => sub { 
	# (test1 (alpha: 'beta;) (gamma: ?x) )
	( $_[0]->slots->{alpha} eq 'beta' )
	&&
	return { x => $_[0]->slots->{gamma} } 
});

isa_ok($a1,'SNMP::Class::Rete::Alpha');

my $a2 = SNMP::Class::Rete::Alpha->new( type => 'test2', bind => sub { 
	# (test1 (epsilon: 'zeta') (eta: ?x) )
	( $_[0]->slots->{epsilon} eq 'zeta' )
	&&
	return { x => $_[0]->slots->{eta} } 
});


isa_ok($a2,'SNMP::Class::Rete::Alpha');

my $rete = SNMP::Class::Rete->new( fact_set => $fs1 );

my $r1 = SNMP::Class::Rete::Rule->new( rh => 
	sub { 
		say 'Hello world:'.Dumper( @_ ) ; 
		$rete->insert_fact( SNMP::Class::Fact->new( type => 'result1' , slots => { 'theta' => $_[0]->bindings->{x} } ) ) ;
	},
);
isa_ok($r1,'SNMP::Class::Rete::Rule');
$r1->add_alpha( $a1 );
$r1->add_alpha( $a2 );

#my $i1 = $a1->instantiate( $f1 );
#my $i2 = $a2->instantiate( $f2 );

throws_ok( sub { $a1->instantiate( 'rubbish' ) }, qr/argument is not an SNMP::Class::Fact/, 'Alpha::instantiate does not accept rubbish for input' );
throws_ok( sub { $a1->point_to_rule( 'rubbish' ) }, qr/argument is not a Rule/, 'Alpha::point_to_rule does not accept rubbish for input' );
throws_ok( sub { $a2->instantiate( $f1 ) } , qr/cannot instantiate a .* alpha with a/, 'instantiation checks for type and dies on mismatch');
my $broken_bind = SNMP::Class::Rete::Alpha->new( type => 'test1', bind => sub {
	return 'rubbish'
});
throws_ok( sub { $broken_bind->instantiate( $f1 ) } , qr/bind subref did not return a hashref/ , 'bind subref return value is checked by the Alpha::instantiate method');


$rete->insert_rule( $r1 ) ; 


$rete->run;

print Dumper( $rete ) ; 
#my $r1 = SNMP::Class::Rete::Rule->new( lh => [ $a1, $a2 ] , rh => sub { say 'activation' });


#$rete->insert_alpha( $a1 , $a2 );


#isa_ok( $rete->index->{test1}->[0], 'SNMP::Class::Rete::Alpha');
#isa_ok( $rete->index->{test2}->[0], 'SNMP::Class::Rete::Alpha');



#my @insts = $a1->combine( $a2 );
#ok( @insts == 1, "alpha combination should yield one instantiation after rete reset" );
#say Dumper( $rete );
#
#p $r1->combine;

#say Dumper( $rete );

