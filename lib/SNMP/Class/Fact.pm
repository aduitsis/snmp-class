package SNMP::Class::Fact;

use Log::Log4perl qw(:easy :nowarn);
my $logger = get_logger();

use Scalar::Util;

use Moose;
use YAML qw(freeze thaw);
use JSON;

use SNMP::Class::Serializer;

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


sub quote_str { 
	#$_[0] =~ s/"/\\"/g;
	$_[0] =~ s/"//g;
	$_[0]
}

sub to_string {
	$_[0]->type . ' ' . join(' ',map { '(' . $_ . ' "'. quote_str($_[0]->slots->{$_}) . '")' } ( sort keys %{ $_[0]->slots } ) ) ;
}

sub serialize {
	#freeze( { type => $_[0]->type , slots => $_[0]->slots } )
	freeze( $_[0] );
}

sub TO_JSON {
	encode_json { type => $_[0]->type , slots => $_[0]->slots } 
}

# WARNING: this is a class method
sub FROM_JSON {
	my $data = decode_json( $_[0] );
	return __PACKAGE__->new( type => $data->{type} , slots => $data->{slots} );
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
	elsif( defined( $args{ json } ) ) {
		return SNMP::Class::Fact::from_json( $args{ json } )
	}
	else {
		return $class->SUPER::BUILDARGS(@_);	
	}
}

1;
