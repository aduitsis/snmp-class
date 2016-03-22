package SNMP::Class::SHA1;

use v5.20;
use strict;
use warnings;

use Module::Load::Conditional qw[can_load check_install requires];

use Sub::Exporter -setup => {
	exports => [ 'sha1_hex' ],
};

my $module;
for ( 'Digest::SHA1' , 'Digest::SHA' ) {
	$module = $_;
	last if ( can_load( modules => { $module => '0' } ) )
}

sub sha1_hex {
	my $sha = $module->new(1);
	$sha->add(@_);
	return $sha->hexdigest
}

1;
