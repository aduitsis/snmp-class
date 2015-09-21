use warnings;
use strict;
use Test::More qw(no_plan);

use Moose::Util qw/find_meta does_role search_class_by_role/;

BEGIN {
	use Data::Dumper;
	use Carp;
	use_ok("SNMP::Class");
}


my $s = SNMP::Class::ResultSet->new;
isa_ok($s,"SNMP::Class::ResultSet");
my $v = SNMP::Class::Varbind->new(oid=>"sysUpTime.0", value=>"1111", type=>'TIMETICKS');
$s->push( $v );


is( $s->number_of_items , 1 , 'Resultset contains one varbind');


my $s2 = SNMP::Class::ResultSet->new;

$s2->copy( $s ) ; 


is( $s2->number_of_items , 1 , 'Copied Resultset contains one varbind');




my $d = SNMP::Class::ResultSet->new;

$d->unserialize_resultset( $s->serialize_resultset ) ; 

is( $d->number_of_items , 1 , 'Unserialized Resultset contains one varbind');


$d->empty;
is( $d->number_of_items , 0 , 'After empty(), resultset contains no varbinds');
ok( $d->is_empty  , 'After empty(), resultset contains no varbinds');

