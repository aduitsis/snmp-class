#!/usr/bin/env perl 

use v5.14;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use FindBin qw($Bin);
use Getopt::Long;
use lib $Bin.'/../lib';
use SNMP::Class;
use SNMP;
use Term::ANSIColor qw(:constants);
use Scalar::Util;
use Gearman::Worker;
use YAML;
use Net::Server::Daemonize qw(daemonize);
use Moose::Util qw/find_meta does_role search_class_by_role/;
use Log::Log4perl;
use Data::Printer;


my $daemonize = 0; #by default, stay in the foreground

my $DEBUG = 0;

my $workers = 1;

my $job_servers = 'localhost:4730';

GetOptions( 'j=i' => \$workers, 'd' => \$daemonize , 'v' => \$DEBUG , 's=s' => \$job_servers );

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
        my $pid = spawn_worker($i);
	$children{ $pid } = 1;
}

#wait indefinitely
while( wait != -1 ) { };

sub spawn_worker {
        defined( my $id = shift ) or die 'missing child id';
        defined( my $pid = fork ) or die $!;

        #father will return to spawn more processes or wait
        return $pid if($pid > 0);

	#$logger->set_prefix('worker '.$id.' ');

        my $worker = Gearman::Worker->new;
        $worker->job_servers($job_servers);
        $worker->register_function('snmp_gather' => gather_worker($id) ); #keep in mind, gather_worker returns a sub
	$logger->warn( "connected to $job_servers , ready to work" );
        $worker->work while 1;
}

sub gather_worker {
        defined( my $id = shift ) or die 'missing worker id';
        #construct a sub and return it
        return sub {
                my $arg = Load(shift->arg);

                $logger->info("worker $id told to gather_worker with args: ".join(',',@{$arg}));

                #create a session, walk some oids
                my $str = gather(@{$arg});

                $logger->info("worker $id finished");

		return $str; #it is already serialized, no need to serialize it again

        }
}




sub gather {

	my $return;

	#SNMP::addMibDirs("$Bin/../../mibs");
	#SNMP::loadModules('ALL');

	my $s = SNMP::Class->new(@_);

	$s->prime;

	# before we call the vendor method, we make sure that the personality supplying it is there
	if( does_role($s , 'SNMP::Class::Role::Personality::VmVlan' ) && $s->vendor eq 'cisco' ) {
		my @personalities = qw( SNMP::Class::Role::Personality::SNMP_Agent SNMP::Class::Role::Personality::SysObjectID SNMP::Class::Role::Personality::Dot1Bridge SNMP::Class::Role::Personality::Interfaces SNMP::Class::Role::Personality::Dot1dStp SNMP::Class::Role::Personality::PortTable SNMP::Class::Role::Personality::Dot1dTpFdbAddress);
		for( $s->get_vlans ) {
			my %args = @_;
			$args{ community } .= '@'.$_;
			$logger->info("doing instance vlan $_ with ".$args{ community });
			my $s2 = SNMP::Class->new(%args);
			$s2->prime( @personalities );
				
			for( @{ $s2->fact_set->facts } ) {
				$logger->info($_->to_string);
			}
			$s->fact_set->push( @{ $s2->fact_set->grep( sub { my $type = $_->type; grep { $type eq $_ } qw( dot1d_fdb stp_port ) }  )->fact_set } );
		}
	}


		
	my @vlans = $s->get_vlans;	

	for( @{ $s->fact_set->facts } ) {
		$logger->info($_->to_string);
	}

	return $s->fact_set->serialize;
}
