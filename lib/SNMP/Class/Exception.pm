package SNMP::Class::Exception;

use v5.20;
use Moose;

extends 'Throwable::Error';

has error => (
	is	=> 'ro',
);

1;
