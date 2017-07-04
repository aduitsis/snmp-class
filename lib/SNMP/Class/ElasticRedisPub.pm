package SNMP::Class::ElasticRedisPub;

use v5.20;
use strict;
use warnings;

use Log::Log4perl qw(:easy);
my $logger = get_logger();
use Scalar::Util;
use List::Util qw(none any);
use SNMP::Class::Fact;
use SNMP::Class::FactSet::Simple;
use Data::Printer;
use Redis;
use JSON;
use Moose;

has server => (
	is	=> 'ro',
	isa	=> 'Str',
	default	=> 'localhost',
);

has port => (
	is	=> 'ro',
	isa	=> 'Num',
	default	=> 6379,
);

has redis => (
	is	=> 'ro',
	isa	=> 'Redis',
	writer	=> '_set_redis',
);

has expiry => (
	is	=> 'ro',
	isa	=> 'Num',
	default	=> 3600,
);

has channel => (
	is	=> 'ro',
	isa	=> 'Str',
	default	=> 'logstash-omnidisco',
);

sub BUILDARGS {
	my $class = shift // die 'missing class argument';
	if( @_ == 1 ) {
		return { server => shift };
	}
	else {
		return $class->SUPER::BUILDARGS(@_);
	}
}

sub BUILD {
	$_[0]->_set_redis( Redis->new( server => $_[0]->server.':'.$_[0]->port ) );
	$logger->info('connected to redis '.$_[0]->server.':'.$_[0]->port);
}

sub publish {
	my $self        = shift // die 'incorrect call';
	my $fact_set    = shift // die 'missing factset';
	
	if( ! SNMP::Class::Role::FactSet::ensure( $fact_set ) ) {
		$logger->logconfess("Cannot index something that is not an SNMP::Class::FactSet. Dumping offending object: \n=====\n".p($fact_set)."\n======\n")
	}

	$fact_set->each( sub {
		$self->redis->publish( $self->channel => encode_json( $_->logstash_doc ) );
	});
}


1;
