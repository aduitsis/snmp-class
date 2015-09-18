package SNMP::Class::Role::Cache::Files;

use autodie;

use Moose::Role;
use Moose::Util::TypeConstraints;

#some common modules...
use Carp;
use Data::Dumper;
use File::Spec;
use IO::All;

use Log::Log4perl qw(:easy :nowarn);
my $logger = get_logger();

with 'SNMP::Class::Role::Cache';

# this tells whether the module can actually work.
# Files are available always, so this module can 
# work all the time. However, some more advanced
# modules in the future may require additional 
# libraries which may not be present. 
sub plugin_works { 
	1;
}

# priority of this Cache implementation compared
# to other implementations. 
sub plugin_priority {
	1;
}

sub file_name {
	File::Spec->catfile( File::Spec->tmpdir() , $_[0]->unique_id.'.snmp-class'   )
	### File::Spec->catfile( File::Spec->rootdir() , 'var', 'tmp', $_[0]->unique_id.'.snmp-class'   )
}

sub cache_file { 
	io->file( $_[0]->file_name ) 
}

sub cache_exists {
	$_[0]->cache_file->exists
}

sub save {
	my $self = shift // die 'incorrect call';
	$logger->info('saving '.$self->file_name);
	$self->cache_file->write( $self->serialize ) 
}

sub load {
	my $self = shift // die 'incorrect call';
	$logger->info('loading '.$self->file_name);
	#SNMP::Class->unserialize( $self->cache_file->all ) 
}

1;
