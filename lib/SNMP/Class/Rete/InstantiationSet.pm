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

has instantiations => (
	is		=> 'ro',
	writer		=> '_set_instantiations',
	isa		=> 'HashRef[SNMP::Class::Rete::Instantiation]',
	required	=> 0,
	default		=> sub { {} },
);

has messages => (
	is		=> 'ro',
	isa		=> 'HashRef[HashRef]',
	default		=> sub { { received => {} , sent => {} } },
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

# this is called on the sending side
sub send {
	my $self	= shift // die 'incorrect call';
	my $recipient	= shift // die 'missing recipient';
	my $msg		= shift // die 'missing message';

	$recipient->receive_handler( $self->unique_id , $msg );
	
	$self->store( 'sent' , $recipient->unique_id , $msg );
}	

# this is called on the receiving side
sub receive_handler {
	my $self	= shift // die 'incorrect call';
	my $sender_id	= shift // die 'missing sender_id';
	my $msg		= shift // die 'missing message';

	# we could use the receive return value to decide whether to store or not
	$self->receive( $sender_id , $msg );

	$self->store( 'received' , $sender_id , $msg );
}

sub store {
	my $self	= shift // die 'incorrect call';
	my $type	= shift // die 'missing type, sent or received';
	my $id		= shift // die 'missing recipient';
	my $msg		= shift // die 'missing message';

	exists $self->messages->{ $type }->{ $id }->{ $msg->signature } 
	or
	$self->messages->{ $type }->{ $id }->{ $msg->signature } = $msg
}	

# this will search for messages of type $type
# and try to filter id by using $filter->() (default: filter excludes only $id, keeps rest)
# and then return all the instantiations in each of the rest of the values
sub search_messages {
	my $self	= shift // die 'incorrect call';
	my $type	= shift // die 'missing type, sent or received';
	my $not_id	= shift // die 'missing recipient';
	my $filter	= shift // sub { $_ ne $not_id };
	
	map { values %{ $self->messages->{ $type }->{ $_ } } } grep { $filter->() } keys %{ $self->messages->{ $type } } 
}

1;
