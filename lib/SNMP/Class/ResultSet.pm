package SNMP::Class::ResultSet;

# this package is just an empty Moose class to which we apply the SNMP::Class::Role::ResultSet
# role. 

use warnings;
use strict;
use SNMP::Class::Role::ResultSet;
use Moose;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

sub BUILD {
	SNMP::Class::Role::ResultSet->meta->apply($_[0]);
}

 
1;

