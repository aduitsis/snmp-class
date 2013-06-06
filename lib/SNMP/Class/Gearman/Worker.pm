package SNMP::Class::Gearman::Worker;

use v5.14;

use Exporter 'import'; 
our @EXPORT_OK = qw(generate_worker spawn_worker gather);

use strict;
use warnings;
use Carp;
use Data::Dumper;
use SNMP::Class;
use Scalar::Util;
use Gearman::Worker;
use YAML;
use Moose::Util qw/find_meta does_role search_class_by_role/;
use Log::Log4perl;
use Data::Printer;
use Storable;

my $logger = Log::Log4perl::get_logger();

=head2 spawn_worker( \@job_servers , $function_name , $id )

Spawns a worker process that will generate a gearman worker and attach
it to a gearman server. So it basically fork()s and then registers a
worker with a gearman job server. 

The \@job_servers is a reference to an array of
job server definitions. See how the job_servers method is used with
L<Gearman::Worker>. 

The $function name is the name by which the worker will register itself as a 
function with gearman. 

The $id is an identifier (e.g. an integer) that will identify this
specific worker that will be spawned.

=cut

sub spawn_worker {
	defined( my $job_servers = shift ) or die 'missing job servers definition';
	defined( my $function_name = shift ) or die 'missing function name for worker';
	defined( my $id = shift ) or die 'missing child id';
	defined( my $pid = fork ) or die $!;

	#father will return to spawn more processes or wait
	return $pid if($pid > 0);

	my $worker = Gearman::Worker->new;
	$worker->job_servers(@{$job_servers});
	$worker->register_function( $function_name => generate_worker($id)); #keep in mind, gather_worker returns a sub
	$logger->info( "worker $id connected to ".join(',',@{$job_servers}).', ready to work' );
	$worker->work while 1;
}

=head2 generate_worker( $id )

Returns a worker that is suitable to pass to gearman. $id is used as
an identifier of the specific worker e.g. for log messages etc. 

=cut

sub generate_worker {
	defined( my $id = shift ) or die 'missing worker id';

	#construct a sub (closure) and return it
	return sub {
		my $arg = Load(shift->arg); #unserialize the arguments
		$logger->info("worker $id told to gather_worker with args: ".join(',',@{$arg}));

		#create a session, walk some oids
		my $str = gather(@{$arg});

		$logger->info("worker $id finished");

		# A serialized factset is returned
		return $str; #it is already serialized, no need to serialize it again

	}
}

=head2 gather

Gathers all available data from an SNMP agent and returns
whatever facts can be obtained. 

=cut

sub gather {

	#SNMP::addMibDirs("$Bin/../../mibs");
	#SNMP::loadModules('ALL');

	my $s = SNMP::Class->new(@_);

	my %args = ( @_ );
	if( exists( $args{ personalities } ) ) {
		$s->prime( @{ $args{ personalities } } )
	}
	else {
		$s->prime
	}

	#for( @{ $s->fact_set->facts } ) {
	#	$logger->info($_->to_string);
	#}

	# special code to handle cisco vlan transparent bridge trick
	# before we call the vendor method, we make sure that the personality supplying it is there

	if( does_role($s , 'SNMP::Class::Role::Personality::VmVlan' ) && ( $s->vendor eq 'cisco' ) ) {
		for( $s->get_vlans ) {
			my %args = @_;
			$args{ community } .= '@'.$_;
			$logger->info("doing instance vlan $_ with ".$args{ community });

			$s->change_community( $args{ community } );

			$s->prime( 'Dot1dTpFdbAddress' );
		}
	}

	# now the $s is primed with SNMP data
	# let's trigger the creation of all facts
	$logger->info('calculating facts');
	$s->calculate_facts;

	for( @{ $s->fact_set->facts } ) {
		$logger->debug($_->to_string);
	}

	return $s->fact_set->serialize;
}

1;
