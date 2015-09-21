use warnings;
use strict;
use Data::Printer;
use Test::More qw(no_plan);

BEGIN {
	use Data::Dumper;
	use Carp;
	use_ok("SNMP::Class");
}

my $a = SNMP::Class->new(hostname=>'localhost', cacheable=>1);
isa_ok($a,"SNMP::Class");

# the cacheable option may cause the object to contain stuff from
# previous test runs. Make sure that whatever is left from previous test runs is removed 
$a->empty();

my $v = SNMP::Class::Varbind->new(oid=>"sysUpTime.0", value=>"1111", type=>'TIMETICKS');
$a->push( $v );

is( $a->number_of_items , 1 , 'Session contains one varbind');
my $t1 = $a->create_time;

$a->save;

# test serialization routines
# should contain 1 varbind which was pushed to the previous object
my $s = SNMP::Class->new(hostname=>'localhost', cacheable=>1);
is( $s->number_of_items , 1 , 'New session contains 1 varbind too');

# test explicit load

is( $s->cache_exists, 1 , 'cache file is present' );
ok( $s->is_valid , 'obviously the object is not expired yet' ); 

$s->load;

ok( $s->is_valid , 'After loading, the object is not expired yet' ); 
 
is( $s->number_of_items , 1 , 'Cached session contains one varbind');
my $t2 = $s->create_time;
is( $t1 , $t2 , 'SNMP::Class serialization and unserialization seems to be working' ) ; 
 
my $s2 = SNMP::Class->new(hostname=>'localhost', cacheable=>1 );
$s2->preferred_lifetime( 0 ) ; 
$s2->valid_lifetime( 0 ) ; 
sleep(1);
ok( ! $s2->is_valid , 'object is expired' ); 

