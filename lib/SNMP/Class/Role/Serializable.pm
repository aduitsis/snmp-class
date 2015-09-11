package SNMP::Class::Role::Serializable;

# this is a role 
use Moose::Role;

use Sereal::Encoder;
use Sereal::Decoder;

my $encoder = Sereal::Encoder->new({});
my $decoder = Sereal::Decoder->new({});

# very simple serialization and unserialization routines
sub serialize {
        $encoder->encode( $_[0] )
}

sub unserialize {
        # if this function has been invoked using the -> notation, e.g.
        # SNMP::Class::Varbind->new_from_sereal( $whatever ), try to
        # detect and act accordingly:
        if( defined( $_[1] ) ) {
                return $decoder->decode( $_[0] )
        }
        $decoder->decode( $_[0] )
}
