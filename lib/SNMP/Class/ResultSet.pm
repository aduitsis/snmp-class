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

=head1 NAME

SNMP::Class::ResultSet 

=head1 GENERAL

This class still exists in order for the user/programmer to be able to
create an object belonging to it. No methods are present in its implementation. 
The initializer just creates the (empty) object and applies the L<SNMP::Class::Role::ResultSet>
role. Hence, all the methods of L<SNMP::Class::Role::ResultSet> are present here as well. 

=cut
 
1;

