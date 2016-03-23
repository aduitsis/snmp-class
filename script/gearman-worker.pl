#!/usr/bin/env perl

use v5.14;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use FindBin qw($Bin);
use Getopt::Long;
use lib $Bin.'/../lib';
use SNMP::Class::Gearman::Worker;
use SNMP;
use Term::ANSIColor qw(:constants);
use Scalar::Util;
use Net::Server::Daemonize qw(daemonize);
use Moose::Util qw/find_meta does_role search_class_by_role/;
use Log::Log4perl;
use Data::Printer;
use SNMP::Class::Gearman::Worker;
use Errno;

my $logger = Log::Log4perl->get_logger;

my $daemonize = 0; #by default, stay in the foreground

my $pid_file = '/var/run/gather-worker.pid';

my $DEBUG = 0;

my $workers = 1;

my @job_servers = 'localhost:4730';

my @mibdirs = ();

my $use_json;

GetOptions( 'mib|mibs|M=s' => \@mibdirs , 'j=i' => \$workers, 'd' => \$daemonize , 'v' => \$DEBUG , 's=s' => \@job_servers, 'json' => \$use_json );

for( @mibdirs ) {
	$logger->info('adding '.$_.' to mibdirs');
	SNMP::Class::Utils::add_mib_dirs( $_ )
}

$0 = 'omnidisco master';

if ( $daemonize ) {
	$logger->info('daemonizing...');
	daemonize('nobody','nobody',$pid_file);
}

my %children;

for my $i ( 1 .. $workers ) {
        $logger->info( "spawning worker $i" );
        my $pid = SNMP::Class::Gearman::Worker::spawn_worker( \@job_servers, 'snmp_gather' , $i, $use_json );
	$children{ $pid } = 1;
}

sub exit_workers {
	$logger->info("Sending SIGINT to all children");
}

my $please_exit = 0;
# before we wait, let's setup a signal handler
$SIG{INT} = sub {
	#this will just interrupt the wait down below.
	$please_exit = 1;
	local $SIG{INT} = 'IGNORE';
	kill 'SIGINT', 0;
};
$SIG{TERM} = sub {
	#this will just interrupt the wait down below.
	$please_exit = 1;
	local $SIG{TERM} = 'IGNORE';
	kill 'SIGTERM', 0;
};

#wait indefinitely
while( wait != -1 && ! $please_exit ) { };

$logger->info("$!. We should stop");
if( $!{ECHILD} ) {
	$logger->info("All children gone. Exiting");
	# TODO: we could respawn some workers if user didn't want to exit
}
elsif( $!{EINTR} ) {
	$logger->info("Sending SIGTERM to all to workers");
	# we going to send a SIGTERM to all processes
	# in the process group. This includes us, so
	# we should ignore it
	local $SIG{INT} = 'IGNORE';
	local $SIG{TERM} = 'IGNORE';
	# this sends SIGTERM to the entire process group
	# note, all workers may have already exited
	kill 'SIGTERM', 0;
}
else {
	$logger->info("Don't know how to handle this condition. Exiting anyway");
}

if(-f($pid_file)){
	$logger->info("removing $pid_file");
	unlink($pid_file);
}

$logger->info('exiting');
