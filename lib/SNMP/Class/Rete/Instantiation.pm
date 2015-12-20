package SNMP::Class::Rete::Instantiation;

use v5.14;
use Moose;

use Data::Printer;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use Scalar::Util qw( blessed );

use Log::Log4perl qw(:easy);
my $logger = get_logger();

has bindings => (
        is		=> 'ro',
        isa		=> 'HashRef[Str]',
        required	=> 1,
        default		=> sub { {} }, #even if not supplied, it's going to be an empty hash
);

has signature => (
	is		=> 'ro',
	isa		=> 'Str',
	writer		=> '_set_signature',
);

sub BUILDARGS {
        my $class = shift // die 'missing class argument';
        if( @_ == 1 ) {
                return { bindings => shift };
        } 
        else {
                return $class->SUPER::BUILDARGS(@_);
        }       
}

# we will calculate the signature just once and store it. Any Instantiation
# object is immutable, so no danger of any subsequent changes
sub BUILD {
	$_[0]->_set_signature( md5_hex $_[0]->to_string ) 
}

# to ascertain equality, just compare signatures
sub eq {
	$_[0]->signature eq $_[1]->signature
}

# merge two Instantiations
sub combine {
        my $self	= shift // die 'incorrect call';
        my $other	= shift // die 'cannot access undef as another instantiation';
	my $comparator	= shift // sub { $_[0] eq $_[1] } ; 

        Scalar::Util::blessed $other && $other->isa( __PACKAGE__ ) or die '2nd argument is not an Instantiation';
	( ref $comparator eq 'CODE' ) or confess 'expected a coderef as the 3rd argument';

	# any difference and we return false immediately
        for ( keys %{ $self->bindings } ) {
		return unless $comparator->( $self->bindings->{ $_ } , $other->bindings->{ $_ } ) ;
        }

	# merge the values. We just copy the first Instantiation's bindings and then
	# copy the values from the other instantiation over them
	# @TODO optimise by finding the missing values and setting only them
        my %h = %{ $self->bindings } ;
        @h{keys %{ $other->bindings } } = values %{ $other->bindings };
        return __PACKAGE__->new( \%h );
}

# returns a string representation of an Instantiation
sub to_string { 
	join(' , ',map( { $_.'='.$_[0]->bindings->{ $_ }  }  ( sort keys %{ $_[0]->bindings } ) ) ) 
}

1;
