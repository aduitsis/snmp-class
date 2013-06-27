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

my $a1 = SNMP::Class::Rete::Alpha->new( type => 'test1', bind => sub { 
	# (test1 (alpha: 'beta;) (gamma: ?x) )
	( $_[0]->slots->{alpha} eq 'beta' )
	&&
	return { x => $_[0]->slots->{gamma} } 
});

isa_ok($a1,'SNMP::Class::Rete::Alpha');

my $inst_a1_f1 = $a1->instantiate_with_fact( $f1 );
isa_ok( $inst_a1_f1, 'SNMP::Class::Rete::Instantiation' );

my $f2 = SNMP::Class::Fact->new( type => 'test2' , slots => { 'epsilon' => 'zeta' , 'eta' => 'delta' } );
isa_ok($f2,'SNMP::Class::Fact');

my $a2 = SNMP::Class::Rete::Alpha->new( type => 'test2', bind => sub { 
	# (test1 (epsilon: 'zeta') (eta: ?x) )
	( $_[0]->slots->{epsilon} eq 'zeta' )
	&&
	return { x => $_[0]->slots->{eta} } 
});

isa_ok($a2,'SNMP::Class::Rete::Alpha');

my $inst_a2_f2 = $a2->instantiate_with_fact( $f2 );
isa_ok( $inst_a2_f2, 'SNMP::Class::Rete::Instantiation' );

# my $b1 = SNMP::Class::Rete::Beta->new( alphas => [ $a1, $a2 ] , action => sub { });

