package SNMP::Class::Role::Serializable;

use Log::Log4perl;
my $logger = Log::Log4perl::get_logger();

use Module::Load;
use Module::Load::Conditional qw[can_load check_install requires];

# this is a role 
use Moose::Role;

my $serializable;

sub serializable { $serializable }

my $error_sub = sub { 
	my $message = 'Cannot find a suitable serialization module. Please install Sereal.';
	$logger->fatal( $message ) ; 
	die $message;
};

my ( $serialize_sub , $unserialize_sub ) = ( $error_sub , $error_sub ); 

if ( can_load( modules => { 
	'Sereal::Encoder' => undef , 
	'Sereal::Decoder' => undef , 
})) { 

	$serializable = 1;

	$logger->info('Found installed Sereal module') ;

	autoload Sereal::Encoder;
	autoload Sereal::Decoder;

	my $encoder = Sereal::Encoder->new({});
	my $decoder = Sereal::Decoder->new({});

	$serialize_sub = sub { $encoder->encode( $_[0] ) };
	$unserialize_sub = sub {  
		# if this function has been invoked using the -> notation, e.g.
		# SNMP::Class::Varbind->new_from_sereal( $whatever ), try to
		# detect and act accordingly:
		if( defined( $_[1] ) ) {
			return $decoder->decode( $_[0] )
		}
		$decoder->decode( $_[0] )
	};
} 

Sub::Install::install_sub({
	into	=> __PACKAGE__,
	as	=> 'serialize',
	code => $serialize_sub, 
});
Sub::Install::install_sub({
	into	=> __PACKAGE__,
	as	=> 'unserialize',
	code => $unserialize_sub, 
});
	
1;
