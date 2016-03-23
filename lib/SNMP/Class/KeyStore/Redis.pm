package SNMP::Class::KeyStore::Redis;

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
use Moose;

with 'SNMP::Class::Role::KeyStore';

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
	$logger->info('connected to redis '.$_[0]->server.':'.$_[0]->port);
	$_[0]->_set_redis( Redis->new( server => $_[0]->server.':'.$_[0]->port ) );
}

sub keys {
	my @result = $_[0]->redis->keys('omnidisco:factset_index:*');
	map { ($_ =~ /^omnidisco:factset_index:(.+)$/)? $1 : ()  } @result;
}

sub query {
	my $self = shift // die 'incorrect call';
	my $query = shift // die 'missing query key';
	my $id = $self->redis->get( "omnidisco:factset_index:$query" );
	if( defined( $id ) ) {
		my $result = $self->redis->get( "omnidisco:factset:$id" );
		if( defined( $result ) ) {
			return SNMP::Class::FactSet::Simple::unserialize( $result )
		}
		else {  
			return
		}
	}
	else {  
		return
	}
}

sub insert {
	my $self = shift // die 'incorrect call';
	my $fact_set = shift // die 'missing fact_set';
	my @aliases = @_;
	$self->redis->set('omnidisco:factset:'.$fact_set->unique_id => $fact_set->serialize , 'EX' => $self->expiry );
	for my $key ( @aliases ) {
		$self->redis->set("omnidisco:factset_index:$key", => $fact_set->unique_id , 'EX' => $self->expiry );
	}
}

sub is_visited {
	( $_[0]->redis->hexists( 'omnidisco:visited_ips', $_[1] ) && ( time - $_[0]->redis->hget( 'omnidisco:visited_ips', $_[1] ) < $_[0]->expiry ) )
}

sub set_visited {
	my $self = shift // die 'incorrect call';
	$self->redis->hset('omnidisco:visited_ips', $_ => time ) for ( @_ ) ;
}

1;
