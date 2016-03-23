package SNMP::Class::Role::KeyStore;

use v5.20;
use strict;
use warnings;

use Log::Log4perl qw(:easy);
my $logger = get_logger();
use Scalar::Util;
use List::Util qw(none any);
use SNMP::Class::Fact;
use Data::Printer;
use Moose::Role;

requires qw( keys query insert is_visited set_visited );

1;
