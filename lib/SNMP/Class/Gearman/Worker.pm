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
use JSON;

my $logger = Log::Log4perl::get_logger();

=head2 spawn_worker( \@job_servers , $function_name , $id, $json )

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

If the $json parameter is true, the worker will return its results in JSON format 
instead of YAML. If missing, defaults to false.

=cut

sub spawn_worker {
	defined( my $job_servers = shift ) or die 'missing job servers definition';
	defined( my $function_name = shift ) or die 'missing function name for worker';
	defined( my $id = shift ) or die 'missing child id';
	my $json = shift; #if missing, assume false

	defined( my $pid = fork ) or die $!;

	#father will return to spawn more processes or wait
	return $pid if($pid > 0);

	my $worker = Gearman::Worker->new;
	$worker->job_servers(@{$job_servers});
	$worker->register_function( $function_name => generate_worker($id, $json)); #keep in mind, gather_worker returns a sub
	$logger->info( "worker $id connected to ".join(',',@{$job_servers}).', ready to work' );
	$worker->work while 1;
}

=head2 generate_worker( $id )

Returns a worker that is suitable to pass to gearman. $id is used as
an identifier of the specific worker e.g. for log messages etc. 

=cut

sub generate_worker {
	defined( my $id = shift ) or die 'missing worker id';
	my $json = shift; #allow false value if missing, like in spawn_worker

	#construct a sub (closure) and return it
	return sub {
		my $arg;
		
		if( $json ) {
			my $incoming_args = decode_json shift->arg;
			@{$arg} = %{ $incoming_args }
		} 
		else {
			$arg = Load(shift->arg) #unserialize the arguments
		}

		$logger->info("worker $id told to gather_worker with args: ".join(',',@{$arg}));

		#create a session, walk some oids
		my $str = gather(@{$arg}, json => $json);

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

	my $start_time = time;

	my $s = SNMP::Class->new(@_);

	my %args = ( @_ );
	if( exists( $args{ personalities } ) ) {
		$s->prime( @{ $args{ personalities } } )
	}
	else {
		$s->prime
	}

	my $return_json;
	if( exists( $args{ json } ) && $args{ json } ) {
		$return_json = 1;
		$logger->debug('will return JSON');
	}	


	#for( @{ $s->fact_set->facts } ) {
	#	$logger->info($_->to_string);
	#}

	# special code to handle cisco vlan transparent bridge trick
	# before we call the vendor method, we make sure that the personality supplying it is there


	if( does_role($s , 'SNMP::Class::Role::Personality::VmVlan' ) && ( $s->vendor eq 'cisco' ) ) {
		my $original_community = $s->community;
		for( $s->get_vlans ) {
			$logger->info("doing instance vlan $_ with " . $original_community . '@' . $_);

			$s->change_community( $original_community . '@' . $_ );

			$s->prime( 'Dot1dTpFdbAddress' );
		}
		$s->change_community( $original_community )
	}

	my $stop_time = time;

	# now the $s is primed with SNMP data
	# let's trigger the creation of all facts
	$logger->info('calculating facts');
	$s->calculate_facts;

	$s->fact_set->push( SNMP::Class::Fact->new( 
		type	=> 'gather_meta',
		slots	=> { 
			start_time	=> $start_time,
			stop_time	=> $stop_time,
			target		=> $s->hostname,
			community	=> $s->community,
			port		=> $s->port,
			timeout		=> $s->timeout,
			retries		=> $s->retries,
			version		=> $s->version,
		},
	));
			
	for( @{ $s->fact_set->facts } ) {
		$logger->debug($_->to_string);
	}

	if( $return_json ) {
		return $s->fact_set->TO_JSON
	}
	return $s->fact_set->serialize;
}

1;
