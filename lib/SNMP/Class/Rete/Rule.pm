package SNMP::Class::Rete::Rule;

use v5.14;
use strict;
use warnings;

use Moose;
use Scalar::Util;

use Log::Log4perl qw(:easy);
my $logger = get_logger();


has 'name' => (
		is => 'ro',
		isa => 'Str',
		required => 0,
		default => 'anonymous',
);

has 'rh' => (
	is => 'ro',
	isa => 'CodeRef',
	required => 1,
);

1;