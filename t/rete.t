#!/usr/bin/perl

use v5.14;

use warnings;
use strict;
use Test::More qw(no_plan);
use Data::Printer;

BEGIN {
        use Data::Dumper;
        use Carp;
        use_ok("SNMP::Class::Fact");
        use_ok("SNMP::Class::FactSet::Simple");
        use_ok("SNMP::Class::Rete");
}





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

#my $r1 = SNMP::Class::Rete::Rule->new( lh => [ $a1, $a2 ] , rh => sub { say 'activation' });
#isa_ok($r1,'SNMP::Class::Rete::Rule');

my $rete = SNMP::Class::Rete->new( fact_set => $fs1 );

$rete->insert_alpha( $a1 , $a2 );

my $r1 = SNMP::Class::Rete::Rule->new( name => 'simple test', rh => sub { say 'Hello world' } );

$a1->point_to_rule( $r1 );
$a2->point_to_rule( $r1 );

isa_ok( $rete->index->{test1}->[0], 'SNMP::Class::Rete::Alpha');
isa_ok( $rete->index->{test2}->[0], 'SNMP::Class::Rete::Alpha');


$rete->reset;


say Dumper( $a1->combine( $a2 ));
say Dumper( $rete );


#say Dumper( $rete );
$rete->run;

