package SNMP::Class::Rete::Instantiation;

use v5.14;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

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

1;
