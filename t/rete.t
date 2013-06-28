#!/usr/bin/perl

use v5.14;

use warnings;
use strict;
use Test::More qw(no_plan);

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

my $inst_a1_f1 = $a1->instantiate_with_fact( $f1 );
isa_ok( $inst_a1_f1, 'SNMP::Class::Rete::Instantiation' );


my $a2 = SNMP::Class::Rete::Alpha->new( type => 'test2', bind => sub { 
	# (test1 (epsilon: 'zeta') (eta: ?x) )
	( $_[0]->slots->{epsilon} eq 'zeta' )
	&&
	return { x => $_[0]->slots->{eta} } 
});

isa_ok($a2,'SNMP::Class::Rete::Alpha');

my $inst_a2_f2 = $a2->instantiate_with_fact( $f2 );
isa_ok( $inst_a2_f2, 'SNMP::Class::Rete::Instantiation' );

my $r1 = SNMP::Class::Rete::Rule->new( lh => [ $a1, $a2 ] , rh => sub { say 'activation' });
isa_ok($r1,'SNMP::Class::Rete::Rule');

my $rete = SNMP::Class::Rete->new( fact_set => $fs1 , rules => [ $r1 ]);

$rete->reset;
$rete->run;

