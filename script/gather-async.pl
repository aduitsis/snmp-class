#!/usr/bin/perl -w

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


$Term::ANSIColor::AUTORESET = 1;


# AnyEvent doc: just call $quit_program->send anytime you want to quit
my $quit_program = AnyEvent->condvar;

my $job_servers = [ 'localhost:4730' ];
my $recurse;

GetOptions( 's=s' => $job_servers , 'r' => \$recurse );

#this starts empty, will get filled up as we move along
my %visited_ips;

my $gearman = AnyEvent::Gearman::Client->new( job_servers => $job_servers ) ;

### $client->job_servers(@job_servers);

### my $taskset = $client->new_task_set;


#my $host = shift // die 'missing argument: hostname to gather from';
#new_task( $gearman , $host );

my $fact_sets = { } ;
my $watchers;
my $guard = tcp_server 'unix/', "$Bin/control.sock", sub { 
	p $watchers;
	my ($fh) = @_;
	binmode( $fh, ":unix" );
	### say { $fh } "Hello, ready to accept commands";
	print { $fh } 'omnidisco> ';
	say "Hello, ready to accept commands from $fh";
	my $io_watcher = AnyEvent->io ( 
		fh	=> $fh,
		poll	=> 'r',
		cb	=> sub { 
			### p @_;
			### warn "io event <$_[0]>\n";
			my $input = <$fh> // do { 
				delete $watchers->{ $fh };
				say "client closed the connection";
				return
			};
			chomp $input;
			if( my ( $target ) = ( $input =~ /^(?:add|walk|target)\s+(\S+)$/ ) ) {
				say { $fh } "Asked to query $target";
				new_task( $gearman , $target )	
			}
			elsif( my ( $query ) = ( $input =~ /^info\s+(\S+)$/ ) ) {
				if( $fact_sets->{ $query } ) { 
					for my $fact ( @{ $fact_sets->{ $query }->facts} ) { 
						say { $fh } $fact->to_string;
					}
				}
				else { 
					say { $fh } "don't know anything about $query";
				}
			}
			elsif( $input =~ /^dump.*fact/ ) {
				say { $fh } join(' ', keys %{$fact_sets} );
			}
			elsif( $input =~ /^(quit|exit)/i ) {
				$quit_program->send 
			}
			else { 
				say { $fh } "My apologies, I don't know how to $input"
			}
			print { $fh } 'omnidisco> ';
		}
	);
	$watchers->{ $fh } = $io_watcher
};


### $taskset->wait;
$quit_program->recv;

sub new_task { 
	my $gearman = shift // die 'incorrect call';
	my $hostname = shift // die 'incorrect call';
	my $community = shift // 'public';
	my $timeout = shift // 1000000;
	say STDERR GREEN "$hostname: adding task";
	my $task = Dump(  [ hostname => $hostname , community => 'public' , timeout => 1000000, ] );
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
		say STDERR GREEN "$hostname: processing completed"
		
	}
}
	

sub generate_failure_handler {
	my $hostname = shift // die 'incorrect call';
	sub {
		say STDERR RED "job for $hostname FAILED";
	}
}

sub factset_processor { 
	my $gearman = shift // die 'missing taskset';
	my $hostname = shift // die 'missing hostname';
	my $fact_set = shift // die 'missing fact_set';
	my $sysname = get_sysname( $fact_set );	
	my @neighbors = get_neighbors( $fact_set );
	my @ipv4s = get_ipv4s( $fact_set ); 
	$visited_ips{ $_ } =  1 for ( @ipv4s ) ;
	say STDERR BOLD BLACK "$hostname: sysname is $sysname";
	say STDERR BOLD BLACK "$hostname: neighbors are: ".join(' , ',@neighbors);
	say STDERR BOLD BLACK "$hostname: host IPv4 addresses are: ".join(' , ',@ipv4s);
	for( @{ $fact_set->facts } ) {
		say $_->to_string;
	}
	$fact_sets->{$hostname} = $fact_set;
	$fact_sets->{ $sysname } = $fact_set;
	$fact_sets->{ $_ } = $fact_set for( @ipv4s );
	if ( $recurse ) { 
		for my $neighbor ( @neighbors ) {
			if ( $visited_ips{ $neighbor } ) { 
				say STDERR BOLD BLACK "$hostname: neighbor $neighbor already visited"
			}
			else {
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

sub typeslot { 
	my $fact_set = shift // die 'incorrect call';
	my $type = shift // die 'incorrect call';
	my $slot = shift // die 'incorrect call';
	map { $_->slots->{ $slot } } @{ $fact_set->grep( sub { $_->matches( type => $type ) } )->fact_set  }
}
