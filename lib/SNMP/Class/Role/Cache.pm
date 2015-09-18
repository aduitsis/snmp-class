package SNMP::Class::Role::Cache;

use v5.20;

use Moose::Role;
use Moose::Util::TypeConstraints;
use Carp;
use Data::Dumper;
use SNMP::Class::Serializer;

#this will pick one plugin under SNMP::Class::Role::Cache:: 
use SNMP::Class::PluggableImplementations ;

use Log::Log4perl qw(:easy :nowarn);
my $logger = get_logger();

# these methods will probably be supplied by the plugin that was loaded
requires( 'save' , 'load' ) ; 

has 'create_time' => (
	is => 'rw',
	isa => 'Num',
	default => sub { time },
);

has 'preferred_lifetime' => (
	is => 'ro',
	isa => 'Num',
	default => 3600,
);

has 'valid_lifetime' => (
	is => 'ro',
	isa => 'Num',
	default => 12*3600,
);

sub serialize_cache { 
	SNMP::Class::Serializer->encode( { create_time => $_[0]->create_time, } );
} 

sub unserialize_cache { 
	#$_[0]->create_time( SNMP::Class::Serializer->decode( $_[1] )->%*->{create_time} ) ; 
	my $ref = SNMP::Class::Serializer->decode( $_[1] ) ; 
	$_[0]->create_time( $ref->{create_time} ) ; 
}

sub expired { 
	my $self = shift // die 'incorrect call';
	my $attr = shift // die 'incorrect call';
	if ( $self->create_time + $_[0]->$attr >= time ) {
		return 1
	}
	else {
		return
	}
}

sub is_preferred { 
	$_[0]->expired('preferred_lifetime')
}

sub is_valid { 
	$_[0]->expired('valid_lifetime')
}

1;
