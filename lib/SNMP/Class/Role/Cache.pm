package SNMP::Class::Role::Cache;

use Moose::Role;
use Moose::Util::TypeConstraints;
use Carp;
use Data::Dumper;

#this will pick one plugin under SNMP::Class::Role::Cache:: 
use SNMP::Class::PluggableImplementations ;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

# these methods will probably be supplied by the plugin that was loaded
requires( 'save' , 'load' ) ; 

1;
