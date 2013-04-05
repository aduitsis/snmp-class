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

GetOptions( 's=s' => \@job_servers );

my $client = Gearman::Client->new;

$client->job_servers(@job_servers);

my $taskset = $client->new_task_set;


my $host = shift // die 'missing argument: hostname to gather from';

my $task = Dump(  [ hostname => $host , community => 'public' , timeout => 1000000, ] );

$taskset->add_task( 'snmp_gather' => $task, {
	on_complete => sub {
		my $fact_set = SNMP::Class::FactSet::Simple::unserialize( ${$_[0]} ) ;
		for( @{ $fact_set->facts } ) {
			say $_->to_string;
		}
	},
	on_fail => sub {
		say STDERR RED "job for $host FAILED";
	},
});


$taskset->wait;
