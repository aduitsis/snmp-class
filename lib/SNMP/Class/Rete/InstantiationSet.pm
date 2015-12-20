package SNMP::Class::Rete::InstantiationSet;

use v5.14;
use strict;
use warnings;

use Moose::Role;
use Scalar::Util qw(blessed);
use Data::Dumper;
use Carp;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

has 'instantiations' => (
	is		=> 'ro',
	writer		=> '_set_instantiations',
	isa		=> 'HashRef[SNMP::Class::Rete::Instantiation]',
	required	=> 0,
	default		=> sub{ {} },
);

sub empty_insts {
	$_[0]->_set_instantiations( {} );
}

sub has_sig {
	exists $_[0]->instantiations->{ $_[1]->signature } 
}

sub get_sig {
	return $_[0]->instantiations->{ $_[1] } if ( $_[0]->has_sig( $_[1] ) ) ;
	return 
}

sub push_inst {
	my $self	= shift // die 'incorrect call';
	my $inst	= shift // die 'missing instantiation';

	blessed( $inst ) && $inst->isa('SNMP::Class::Rete::Instantiation') or confess 'argument is not an SNMP::Class::Rete::Instantiation. Dump of object follows: '.Dumper( $inst );

	# already there
	return if $self->has_sig( $inst );
	
	$self->instantiations->{ $inst->signature } = $inst;

	return 1
}

sub each_inst { 
	my $self	= shift // die 'incorrect call';
	my $code	= shift // die 'missing coderef';

	ref $code eq 'CODE' or confess 'Argument is not a coderef';

	$code->() for ( values %{ $self->instantiations } )
}

sub send {
	my $self	= shift // die 'incorrect call';
	my $recipient	= shift // die 'missing recipient';
	my $msg		= shift // die 'missing message';
	$recipient->receive_handler( $self->unique_id , $msg );
}	

sub receive_handler {
	my $self	= shift // die 'incorrect call';
	my $sender	= shift // die 'missing recipient';
	my $msg		= shift // die 'missing message';

	$self->receive( $sender , $msg );
}
	

1;
