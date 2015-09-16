package SNMP::Class::Role::Cache::Files;

use Moose::Role;
use Moose::Util::TypeConstraints;

#some common modules...
use Carp;
use Data::Dumper;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

with 'SNMP::Class::Role::Cache';

# this tells whether the module can actually work.
# Files are available always, so this module can 
# work all the time. However, some more advanced
# modules in the future may require additional 
# libraries which may not be present. 
sub works { 
	1;
}

# priority of this Cache implementation compared
# to other implementations. 
sub priority {
	1;
}

sub save {
	$logger->info('saving');
}

sub load {
	$logger->info('loading');
}


1;
