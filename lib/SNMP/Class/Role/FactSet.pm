package SNMP::Class::Role::FactSet;

use strict;
use warnings;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use SNMP::Class::Fact; 

use Moose::Role;

requires qw( push grep map facts item count ) ;

1;
