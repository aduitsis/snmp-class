package SNMP::Class::Rete::Instantiation;

use v5.14;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Data::Printer;

use Scalar::Util;

use Moose;

has 'bindings' => (
        is => 'ro',
        isa => 'HashRef[Str]',
        required => 1,
        default => sub { {} }, #even if not supplied, it's going to be an empty hash
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


sub is_compatible {
        my $self = shift // die 'incorrect call';
        my $other = shift // die 'cannot access undef as another instantiation';
        Scalar::Util::blessed $other && $other->isa( __PACKAGE__ ) or die 'argument is not an Instantiation';

        for ( keys %{ $self->bindings } ) {
                return unless ( $self->bindings->{ $_ } eq $other->bindings->{ $_ } ); 
        }
        return 1;
}


sub combine {
        my $self = shift // die 'incorrect call';
        my $other = shift // die 'cannot access undef as another instantiation';
        Scalar::Util::blessed $other && $other->isa( __PACKAGE__ ) or die 'argument is not an Instantiation';

        #( Scalar::Util::blessed $other && $other->isa( __PACKAGE__ ) ) or die 'argument is not an Instantiation';
        my %h = %{ $self->bindings } ;
        @h{keys %{ $other->bindings } } = values %{ $other->bindings };
        return __PACKAGE__->new( \%h );
}

1;
