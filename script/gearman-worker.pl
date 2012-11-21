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
use SNMP::Class::Gearman::Worker qw(generate_worker);


my $daemonize = 0; #by default, stay in the foreground

my $DEBUG = 0;

my $workers = 1;

my @job_servers = 'localhost:4730';

GetOptions( 'j=i' => \$workers, 'd' => \$daemonize , 'v' => \$DEBUG , 's=s' => \@job_servers );

#my $logger = Log::Dispatchouli->new({
#  ident     => 'gather-worker',
#  facility  => ($daemonize)? 'daemon' : undef ,
#  to_stdout => ($daemonize)? 0 : 1 ,
#  debug     => $DEBUG, 
#});


#my $layout = Log::Log4perl::Layout::PatternLayout->new("[%r] %F %L %m%n");

#my $stderr_appender = Log::Log4perl::Appender->new('Log::Log4perl::Appender::Screen', name => "screenlog", stderr => 1); 
#$stderr_appender->layout( $layout ) ;

my $logger = Log::Log4perl->get_logger;
#p $logger; 
#my $appenders = Log::Log4perl->appenders;
#p $appenders;
#my $log_file_appender = Log::Log4perl->appender_by_name('LogFile');
#p $log_file_appender ; 
#$logger->add_appender( $log_file_appender );



if ( $daemonize ) {
	daemonize('nobody','nobody','/var/run/gather-worker.pid');
	
}

my %children;

for my $i (1..$workers) {
        $logger->debug( "spawning worker $i" );
        my $pid = SNMP::Class::Gearman::Worker::spawn_worker( \@job_servers, 'snmp_gather' , $i);
	$children{ $pid } = 1;
}

#wait indefinitely
while( wait != -1 ) { };
