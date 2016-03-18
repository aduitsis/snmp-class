package SNMP::Class::Fact;

use Log::Log4perl qw(:easy :nowarn);
my $logger = get_logger();

use Scalar::Util;
use List::Util qw(none);

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

has 'time' => (
	is => 'ro',
	isa => 'Int',
	required => 0,
	default => sub { time }, #TODO: is something more accurate needed?
);

sub quote_str { 
	#$_[0] =~ s/"/\\"/g;
	$_[0] =~ s/"//g;
	$_[0]
}

=head2 to_string( [ exclude => 'slotname' | exclude =>['slot1','slot2',...] ] )

Returns a string representation of the fact, quoting values of slots as necessary. The exclude
argument can be used to ask for the exclusion of slot(s) name(s) from the string. The value of the 
exclude argument can be either a scalar value or an array reference with many keys to be excluded.
Example: 

 $fact->to_string( exclude => 'engine_id' ); 

 $fact->to_string( exclude => ['engine_id' , 'mac_address'] );

=cut 

sub to_string {
	my $self = shift // die 'incorrect call';
	my %options = @_;
	my @exclude_slots;
	if ( defined( $options{ exclude } ) ){
		@exclude_slots = defined(Scalar::Util::reftype( $options{ exclude } ))? @{ $options{ exclude } } : ( $options{ exclude } ) 
	}
	$self->type . ' ' . join(' ',map { '(' . $_ . ' "'. quote_str($self->slots->{$_}) . '")' } ( sort grep { my $item = $_ ; none { $item eq $_ } @exclude_slots  } keys %{ $self->slots } ) ) ;
}

sub serialize {
	#freeze( { type => $_[0]->type , slots => $_[0]->slots } )
	freeze( $_[0] );
}

sub TO_JSON {
	encode_json { type => $_[0]->type , slots => $_[0]->slots, time => $_[0]->time } 
}

=head2 elastic_doc

Returns a structure suitable to be fed a the document to be inserted into an
elasticsearch cluster. Basically contains the slots and an additional element
date, all packed into a hash reference.

=cut

sub elastic_doc {
	my $date = DateTime->from_epoch( epoch => $_[0]->time )->strftime('%Y-%m-%dT%H:%M:%SZ');
	return { ( %{ $_[0]->slots } ) , date => $date, }
	
}

# WARNING: this is a class method
sub FROM_JSON {
	my $data = decode_json( $_[0] );
	return __PACKAGE__->new( type => $data->{type} , slots => $data->{slots} , time => $data->{time} );
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
