#!/usr/bin/env perl

use v5.14;

use warnings;
use strict;
use AnyEvent::Gearman;
use AnyEvent::Socket;
use YAML;
use Data::Dumper;
use Fatal qw(open close);
use File::Slurp;
use FindBin qw($Bin);
use Getopt::Long;
use YAML qw(DumpFile);
use File::Slurp;
### use Socket;
use Term::ANSIColor qw(:constants);
use Data::Printer;

use lib $Bin.'/../lib';
use SNMP::Class;

binmode( STDOUT, ":unix" );

$Term::ANSIColor::AUTORESET = 1;


# AnyEvent doc: just call $quit_program->send anytime you want to quit
my $quit_program = AnyEvent->condvar;

my $job_servers = [ 'localhost:4730' ];
my $recurse;
my $query_all_vlans;

my @seed;

GetOptions( 's=s' => $job_servers , 'r' => \$recurse , 'seed=s' => \@seed , 'query-all-vlans' => \$query_all_vlans );

#this starts empty, will get filled up as we move along
my %visited_ips;

my $fact_sets = { } ;

sub connect_to_gearman {
	AnyEvent::Gearman::Client->new( job_servers => $job_servers ) ;
}

my $gearman = connect_to_gearman ;

### $client->job_servers(@job_servers);

### my $taskset = $client->new_task_set;


#my $host = shift // die 'missing argument: hostname to gather from';
#new_task( $gearman , $host );

my $guard = tcp_server 'unix/', "$Bin/control.sock", \&control_handler;

# watchers are the open connections to this daemon from users
# alert transmits messages to all open connections
my %watchers;
my $alert_condvar = AnyEvent->condvar;
$alert_condvar->cb( \&alert_handler ) ;
sub alert_handler {
	my @args = $_[0]->recv // die 'incorrect call';
	for my $watcher ( values %watchers ) {
		if ( $watcher->{ alerts } ) {
			say { $watcher->{ fh } } $args[0];
		}
	}
	$alert_condvar = AnyEvent->condvar;
	$alert_condvar->cb( \&alert_handler ) ;
}

sub control_handler {
	p %watchers;
	my ($fh) = @_;
	binmode( $fh, ":unix" );
	### say { $fh } "Hello, ready to accept commands";
	print { $fh } 'omnidisco> ';
	say STDERR "new connection from $fh";
	my $io_watcher = AnyEvent->io (
		fh	=> $fh,
		poll	=> 'r',
		cb	=> sub {
			### p @_;
			### warn "io event <$_[0]>\n";
			my $input = <$fh> // do {
				delete $watchers{ $fh };
				say STDERR "client closed the connection";
				return
			};
			chomp $input;
			if( my ( $target ) = ( $input =~ /^(?:add|walk|target)\s+(\S+)$/ ) ) {
				say { $fh } "Asked to query $target";
				new_task( $gearman , $target );
				$alert_condvar->send("job submitted for $target");
			}
			elsif( my ( $query, $rest ) = ( $input =~ /^(?:info|show|examine|sh)\s+(\S+)(.*)$/ ) ) {
				my (%options,$bare);
				if( $rest ) {
					( $bare ) = ( $rest =~ /^\s*([^= ]+)\s*/ );
					while( $rest =~ /\s*(?<key>\S+)\s*=\s*(?<value>\S+)(?:\s+|$)/g ) {
						$options{ $+{key} } = $+{value};
					}
				}
				if( $fact_sets->{ $query } ) {
					for my $fact ( @{ $fact_sets->{ $query }->facts} ) {
						next if( $bare && ( $fact->type ne $bare ) );
						say { $fh } $fact->to_string( exclude => 'engine_id' );
					}
				}
				else {
					say { $fh } "don't know anything about $query";
				}
			}
			elsif( $input =~ /^dump.*fact/ ) {
				say { $fh } join("\n", keys %{$fact_sets} );
			}
			elsif( my ($read_var) = ( $input =~ /^\s*get\s*(\S+)\s*/ ) ) {
				no strict 'refs';
				say { $fh } "$read_var = ".${ $read_var };
				use strict 'refs';
			}
			elsif( my ($var,$value) = ( $input =~ /^\s*set\s*(\S+)\s*=\s*(\S+)/ ) ) {
				say { $fh } "Setting $var to $value";
				no strict 'refs';
				${ $var } = $value;
				use strict 'refs';
			}
			elsif( $input =~ /^(quit|exit)/i ) {
				$quit_program->send
			}
			elsif( $input =~ /^(no\s+term\S*\s+mon|term\S*\s+no\s+mon|alert\S*\s+off)/i ) {
				$watchers{ $fh }->{ alerts } = 0;
			}
			elsif( $input =~ /^(term\S*\s+mon|alert\S*\s+on)/i ) {
				$watchers{ $fh }->{ alerts } = 1;
			}
			elsif( $input =~ /^\s*$/ ) {
			}
			else {
				say { $fh } "I beg your pardon, I don't know how to $input"
			}
			print { $fh } 'omnidisco> ';
		}
	);
	$watchers{ $fh } = { fh => $fh , aio => $io_watcher , alerts => 1 } ;
}


#this is done only once, upon program invocation
new_task( $gearman, $_ ) for(@seed);

### $taskset->wait;
$quit_program->recv;

sub new_task {
	my $gearman = shift // die 'incorrect call';
	my $hostname = shift // die 'incorrect call';
	my $community = shift // 'public';
	my $timeout = shift // 5000000;
	say STDERR GREEN "$hostname: adding task";
	my $task = Dump(  [ hostname => $hostname , community => 'public' , timeout => $timeout , query_all_vlans => ($query_all_vlans? 1 : 0 ) ] );
	$gearman->add_task( 'snmp_gather' => $task,
		on_complete	=> generate_completion_handler($gearman,$hostname),
		on_fail		=> generate_failure_handler($hostname),
	);
	say STDERR GREEN "$hostname: submitted"
}

sub generate_completion_handler {
	my $gearman = shift // die 'missing gearman';
	my $hostname = shift // die 'missing hostname';
	sub {
		### p $_[1];
		say STDERR GREEN "$hostname: gather completed";
		my $fact_set = SNMP::Class::FactSet::Simple::unserialize( $_[1] ) ;
		factset_processor( $gearman , $hostname, $fact_set ) ;
		say STDERR GREEN "$hostname: processing completed";
		$alert_condvar->send("job completed for $hostname");

	}
}

sub generate_failure_handler {
	my $hostname = shift // die 'incorrect call';
	sub {
		say STDERR RED "job for $hostname FAILED";
	}
}

sub factset_processor {
	my $gearman = shift // die 'missing taskset'; # in case we need to submit new jobs in the job queue
	my $hostname = shift // die 'missing hostname';
	my $fact_set = shift // die 'missing fact_set';
	my $sysname = get_sysname( $fact_set );
	my @neighbors = get_neighbors( $fact_set );
	my @ipv4s = get_ipv4s( $fact_set );
	$visited_ips{ $_ } =  1 for ( @ipv4s ) ;
	say STDERR BOLD BLACK "$hostname: sysname is $sysname";
	say STDERR BOLD BLACK "$hostname: neighbors are: ".join(' , ',@neighbors);
	say STDERR BOLD BLACK "$hostname: host IPv4 addresses are: ".join(' , ',@ipv4s);
	state $counter = 1;
	say '(deffacts snmp_knowledge_'.$counter++.' "facts on '.$sysname.'"';
	for( @{ $fact_set->facts } ) {
		say '('.$_->to_string.')';
	}
        say ')';
	$fact_sets->{$hostname} = $fact_set;
	$fact_sets->{ $sysname } = $fact_set;
	$fact_sets->{ $_ } = $fact_set for( @ipv4s );
	if ( $recurse ) {
		for my $neighbor ( @neighbors ) {
			if ( $visited_ips{ $neighbor } ) {
				say STDERR BOLD BLACK "$hostname: neighbor $neighbor already visited"
			}
			else {
				$visited_ips{ $neighbor } = 1; #make sure we don't revisit it later
				new_task( $gearman , $neighbor )
			}
		}
	}
}

sub get_sysname {
	$_[0]->grep(sub{ $_->matches( type => 'snmp_agent' ) })->item(0)->slots->{'system'};
}

sub get_ipv4s {
	typeslot( $_[0], 'ipv4', 'ipv4' )
}

sub get_neighbors {
	typeslot( $_[0], 'cdp_neighbor', 'address' )
	### map { $_->slots->{ address } } @{ $_[0]->grep( sub { $_->matches( type => 'cdp_neighbor' ) } )->fact_set  }
}

=head2 typeslot($fact_set,$type,$slot)

Searches $fact_set for facts of type $type having a slot $slot, and returns the values of those slots.

=cut


sub typeslot {
	my $fact_set = shift // die 'incorrect call';
	my $type = shift // die 'incorrect call';
	my $slot = shift // die 'incorrect call';
	map { $_->slots->{ $slot } } @{ $fact_set->grep( sub { $_->matches( type => $type ) } )->fact_set  }
}
