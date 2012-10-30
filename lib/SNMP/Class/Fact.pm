package SNMP::Class::Fact;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Scalar::Util;

use Moose;
use YAML qw(freeze thaw);

has 'type' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);	

has 'slots' => (
	is => 'ro',
	isa => 'HashRef[Str]',
	required => 0,
	default => sub { {} }, #even if not supplied, it's going to be an empty hash
);


sub to_string {
	$_[0]->type . ' ' . join(' ',map { '(' . $_ . ' "'. $_[0]->slots->{$_} . '")' } ( keys %{ $_[0]->slots } ) ) ;
}

sub serialize {
	#freeze( { type => $_[0]->type , slots => $_[0]->slots } )
	freeze( $_[0] );
}

sub unserialize {
	#my $items = thaw( $_[0] );
	#return __PACKAGE__->new( type => $items->{type} , slots => $items->{slots} );
	thaw( $_[0] );
}

sub keys {
	return ( keys %{ $_[0]->slots } )
}

sub matches {
	defined( my $self = shift(@_) ) or confess 'incorrect call';

	my @rest = @_;

	my $target = $rest[0];
	if( ! ( ref( $rest[0] ) && blessed( $rest[0] ) && $rest[0]->isa('SNMP::Class::Fact') ) ){
		$target = SNMP::Class::Fact->new( @rest ) 
	}
	#must be of the same type
	return unless $self->type eq $target->type;
	#and, for each key of the target the source must have the same key with the same value
	for( $target->keys ) {
		return unless ( ( defined $self->slots->{ $_ } ) && ( $self->slots->{ $_ } eq $target->slots->{ $_ } ) );
	}
	return 1;
}
		

sub BUILDARGS {
	my $class = shift( @_ ) ;

	# if there was only one argument, that's the type only
	return $class->SUPER::BUILDARGS( type => $_[0] ) if ( @_ == 1 ) ;

	my %args = @_;

	# if there is the 'frozen' key, then the argument is a serialized SNMP::Class::Fact
	if ( defined( $args{ frozen } ) ) { 
		return SNMP::Class::Fact::unserialize( $args{ frozen } )
	} 
	else {
		return $class->SUPER::BUILDARGS(@_);	
	}
}

1;