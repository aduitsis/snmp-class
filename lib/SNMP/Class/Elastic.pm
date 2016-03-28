package SNMP::Class::Elastic;

use v5.14;

use Data::Printer;

use warnings;
use strict;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose;
use Moose::Util::TypeConstraints;
use Moose::Util qw(does_role);
use YAML qw(freeze thaw);
use JSON;
use Digest::SHA qw(sha1_hex);
use Scalar::Util qw(blessed);
use DateTime;
use Search::Elasticsearch;

has session => (
	is	=> 'ro',
	isa	=> 'Search::Elasticsearch::Client::2_0::Direct',
	writer	=> '_set_session',
);

has nodes => (
	is	=> 'ro',
	isa	=> 'ArrayRef[Str]',
	writer	=> '_set_nodes',
);

has other_params => (
	is	=> 'ro',
	isa	=> 'ArrayRef[Any]',
	default	=> sub { [] },
);

has default_port => (
	is	=> 'ro',
	isa	=> 'Int',
	default	=> 9200,
);

has index_prefix => (
	is	=> 'rw',
	isa	=> 'Str',
	default	=> 'omnidisco',
);	

#if the new method is invoked with one and only one param, this is the elasticsearch node
sub BUILDARGS {
	my $class = shift // die 'missing class argument';
	my %params = ( @_ == 1 )? ( nodes => [ shift ] ) : @_;
	# if nodes was just a string, put it in an arrayref, otherwise do nothing
	$params{nodes} = [ $params{nodes} ] unless ref $params{nodes};
	return $class->SUPER::BUILDARGS(%params);
}

sub BUILD {
	# for each node item, if portnumber is missing, add a default
	$_[0]->_set_nodes( [ map { ( $_ !~ /:\d+$/ )? $_.':'.$_[0]->default_port : $_ } @{ $_[0]->nodes } ] );
	# construct the connection
	$_[0]->_set_session( Search::Elasticsearch->new( nodes => $_[0]->nodes , @{ $_[0]->other_params } ) );
	$logger->info('will use session to elasticsearch '.join(',', @{ $_[0]->nodes } ));
}

sub index_name {
	my $dt = DateTime->now;
	my $index_name = $dt->strftime($_[0]->index_prefix."-%Y.%m.%d");
}

sub bulk_index {

	my $self	= shift // die 'incorrect call';
	my $fact_set	= shift // die 'missing factset';

	if( !( blessed $fact_set  && does_role($fact_set , 'SNMP::Class::Role::FactSet') ) ) {
		$logger->logconfess("Cannot index something that is not an SNMP::Class::FactSet. Dumping offending object: \n=====\n".p($fact_set)."\n======\n")
	}

	my $bulk = $self->session->bulk_helper;
	$fact_set->each( sub { 
		my @action = ( 
			index => { 
				index   => $self->index_name,
				type    => $_->type,
				source  => $_->elastic_doc, 
			},
		);
		$logger->info('index '.$self->index_name.' inserting fact: '.$_->to_string( exclude => 'engine_id' ));
		$bulk->add_action( @action ) ;
	});
	$bulk->flush;
}

1;
