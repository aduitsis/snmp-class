#!/usr/bin/perl -w

use v5.14;

use warnings;
use strict;
use Gearman::Client;
use YAML;
use Data::Dumper;
use Fatal qw(open close);
use File::Slurp;
use FindBin qw($Bin);
use Getopt::Long;
use YAML qw(DumpFile);
use File::Slurp;
use Socket;
use Term::ANSIColor qw(:constants);
use Data::Printer;

use lib $Bin.'/../lib';
use SNMP::Class;


$Term::ANSIColor::AUTORESET = 1;

my @job_servers = ( 'worker0:4730' );
my $recurse;

GetOptions( 's=s' => \@job_servers , 'r' => \$recurse );

#this starts empty, will get filled up as we move along
my %visited_ips;

my $client = Gearman::Client->new;

$client->job_servers(@job_servers);

my $taskset = $client->new_task_set;


my $host = shift // die 'missing argument: hostname to gather from';

new_task( $taskset , $host );

$taskset->wait;


sub new_task { 
	my $taskset = shift // die 'incorrect call';
	my $hostname = shift // die 'incorrect call';
	my $community = shift // 'public';
	my $timeout = shift // 1000000;
	say STDERR GREEN "$hostname: adding task";
	my $task = Dump(  [ hostname => $hostname , community => 'public' , timeout => 1000000, ] );
	$taskset->add_task( 'snmp_gather' => $task, {
		on_complete	=> generate_completion_handler($taskset,$hostname),
		on_fail		=> generate_failure_handler($hostname),
	});
	say STDERR GREEN "$hostname: submitted"
}

sub generate_completion_handler { 
	my $taskset = shift // die 'missing taskset';
	my $hostname = shift // die 'missing hostname';
	sub { 
		say STDERR GREEN "$hostname: gather completed";
		my $fact_set = SNMP::Class::FactSet::Simple::unserialize( ${$_[0]} ) ;
		factset_processor( $taskset , $hostname, $fact_set ) ; 
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
	my $taskset = shift // die 'missing taskset';
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
	if ( $recurse ) { 
		for my $neighbor ( @neighbors ) {
			if ( $visited_ips{ $neighbor } ) { 
				say STDERR BOLD BLACK "$hostname: neighbor $neighbor already visited"
			}
			else {
				new_task( $taskset , $neighbor )
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
