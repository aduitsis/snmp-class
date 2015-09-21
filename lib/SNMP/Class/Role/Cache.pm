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
requires( 'save' , 'load' , 'cache_exists' ) ; 

has 'preferred_lifetime' => (
	is => 'rw',
	isa => 'Num',
	default => 3600,
);

has 'valid_lifetime' => (
	is => 'rw',
	isa => 'Num',
	default => 12*3600,
);

sub revive { 
	my $self = shift // die 'incorrect call';
	return unless $self->cache_exists;
	$self->load;
	return unless $self->is_preferred;
	1
}

sub expired { 
	my $self = shift // die 'incorrect call';
	my $attr = shift // die 'incorrect call';
	if ( $self->create_time + $self->$attr >= time ) {
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
