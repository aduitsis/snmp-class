package SNMP::Class::Serializer;

use Carp; 

use Log::Log4perl qw(:nowarn);
my $logger = Log::Log4perl::get_logger();

use Module::Load;
use Module::Load::Conditional qw[can_load check_install requires];

my $can_serialize;

sub can_serialize { $can_serialize }

my $error_sub = sub { 
	my $message = 'Cannot find a suitable serialization module. Please install Sereal.';
	$logger->fatal( $message ) ; 
	die $message;
};

my ( $encode_sub , $decode_sub ) = ( $error_sub , $error_sub ); 

if ( can_load( modules => { 
	'Sereal::Encoder' => undef , 
	'Sereal::Decoder' => undef , 
})) { 

	$can_serialize = 1;

	$logger->info('Found installed Sereal module') ;

	autoload Sereal::Encoder;
	autoload Sereal::Decoder;

	my $encoder = Sereal::Encoder->new({});
	my $decoder = Sereal::Decoder->new({});

	# this function is invoked using the -> notation, e.g.
	# SNMP::Class::Serializer->encode( $whatever )
	$encode_sub = sub { $encoder->encode( $_[1] ) };
	$decode_sub = sub { $decoder->decode( $_[1] ) }; 
} 

Sub::Install::install_sub({
	into	=> __PACKAGE__,
	as	=> 'encode',
	code => $encode_sub, 
});
Sub::Install::install_sub({
	into	=> __PACKAGE__,
	as	=> 'decode',
	code => $decode_sub, 
});
	
1;
