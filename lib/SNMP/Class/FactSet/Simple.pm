package SNMP::Class::FactSet::Simple;

use v5.14;

use Data::Printer;

use warnings;
use strict;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose;
use Moose::Util::TypeConstraints;
use YAML qw(freeze thaw);
use JSON;
use Digest::SHA1 qw(sha1_hex);	
use Scalar::Util qw(blessed);

with 'SNMP::Class::Role::FactSet';

subtype 'ArrayRefFacts' => as 'ArrayRef[SNMP::Class::Fact]';

has 'fact_set' => (
	is => 'ro',
	isa => 'ArrayRefFacts',
	default => sub { [] },
);

has 'time' => (
        is => 'ro',
        isa => 'Int',
        required => 0,
        default => sub { time }, #TODO: is something more accurate needed?
);

#declaring a reader attr for 'fact_set' does not satisfy Moose, unfortunately
sub facts {
	$_[0]->fact_set;
}

sub unique_id {
	# order is not significant, FactSets with the same Facts in varying orders should
	# produce the same unique_id. So we try to sort the Fact unique_ids to make the
	# order deterministic. 
	sha1_hex(
		join('',
			$_[0]->time,
			sort map { $_->unique_id } @{ $_[0]->facts }
		)
	);
}

sub push { 
	defined( my $self = shift( @_ ) ) or confess 'incorrect call';
	for( @_ ) {
		if( !( blessed $_  && $_->isa('SNMP::Class::Fact') ) ) { 
			$logger->logconfess("Cannot push something that is not an SNMP::Class::Fact. Dumping offending object: \n=====\n".p($_)."\n======\n")
		}
	}
	push @{ $self->fact_set	} , @_;
}

sub count {
	scalar @{ $_[0]->facts }
}

sub grep {
	SNMP::Class::FactSet::Simple->new( fact_set => [ grep { $_[1]->() } @{ $_[0]->fact_set } ] );
}

sub map {
	SNMP::Class::FactSet::Simple->new( fact_set => [ map { $_[1]->() } @{ $_[0]->fact_set } ] );
}

sub item {
	$_[0]->facts->[ $_[1] ]
}

sub serialize {
	return freeze( $_[0]->facts ); 
}

# a function, not a method
sub unserialize {
	__PACKAGE__->new( fact_set => thaw( $_[0] ) );
}

sub TO_JSON {
	return '{ "time": '. $_[0]->time . ', "fact_set": [' . ( join ',',CORE::map { $_->TO_JSON } ( @{ $_[0]->facts } ) ) . ']}';
	# JSON->new->utf8->allow_blessed->convert_blessed->encode( $_[0]->facts );
}	

sub FROM_JSON {
	my $data = decode_json $_[0];
	__PACKAGE__->new( 
		time => $data->{ time},
		fact_set => [ map { SNMP::Class::Fact->new( type => $_->{type} , slots => $_->{slots} ) } @{ $data->{fact_set} } ],
	);
}	

1;
