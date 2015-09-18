use warnings;
use strict;
use Data::Printer;
use Test::More qw(no_plan);

BEGIN {
        use Data::Dumper;
        use Carp;
        use_ok("SNMP::Class");
}


$a = SNMP::Class->new(hostname=>'localhost', cacheable=>1);
isa_ok($a,"SNMP::Class");
my $v = SNMP::Class::Varbind->new(oid=>"sysUpTime.0", value=>"1111", type=>'TIMETICKS');
$a->push( $v );
is( $a->number_of_items , 1 , 'Session contains one varbind');

###p $a; 

my $t1 = $a->create_time;

#$a->save;

# test load manually
#my $b = $a->load;
#isa_ok($b,'SNMP::Class');


#now test load automatically
my $s = SNMP::Class->new(hostname=>'localhost', cacheable=>1);
#is( $s->number_of_items , 1 , 'Cached session contains one varbind');
$s->unserialize_cache( $a->serialize_cache ); 

my $t2 = $s->create_time;

is( $t1 , $t2 , 'Cache serialization and unserialization seems to be working' ) ; 
