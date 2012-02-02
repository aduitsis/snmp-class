package SNMP::Class;

=head1 NAME

SNMP::Class - Object Oriented SNMP Framework

=cut

our $VERSION = '0.15';

=head1 SYNOPSIS

This module aims to allow SNMP-related tasks to be carried out with the best possible ease and expressiveness trying to hide SNMP-related details as much as possible. 

	use SNMP::Class;
	
	$s = SNMP::Class->new($host);

	$s->add('interfaces','system'); 

	print $s->system(0)->value."\n";
	
=head1 GENERAL

To use anything in the SNMP::Class package, use this module and everything else will be included. SNMP::Class is a Moose class. SNMP::Class itself does not actually implement a lot of functionality, but rather it uses other Roles under the SNMP::Class hierarchy. These Roles implement various pieces of functionality and are applied on each SNMP::Class object to give it certain capabilities. For example, the SNMP::Class::Role::Implementation::NetSNMP can use the Net-SNMP package to talk to SNMP agents. An SNMP::Class object applies this Role to itself to be able to talk to SNMP agents as well. Or, the SNMP::Class::Role::ResultSet can store the results from SNMP operations (GETs,GETNEXTs etc). By applying this Role to itself, an SNMP::Class object can do the same. 
   

=cut

#this also enables warnings and strict
use Moose;
use Moose::Util::TypeConstraints;


#some common modules...
use Carp;
use Data::Dumper;

#load our own
use SNMP::Class::ResultSet;
use SNMP::Class::Varbind;
use SNMP::Class::OID;
use SNMP::Class::Utils;
use SNMP::Class::Role::Implementation::Dummy;
use SNMP::Class::Role::Implementation::NetSNMP;

#setup logging

use Log::Log4perl;

# try to find a universal.logger in the same path with this file
for my $lib (@INC) {
	my $logger_file = $lib.'/SNMP/SNMP-Class.logger';
	if (-f $logger_file) {
		Log::Log4perl->init($logger_file);
	} 
}

####&SNMP::loadModules('ALL');

subtype 'Version_ArrayRefOfInts' => as 'ArrayRef[Int]';

subtype 'VersionString' 
	=> as 'Str'
	=> where { my $str = $_; grep { $str eq $_ } ('1','2','2c','3') }
	=> message { "Version is not valid. Use 1,2,2c or 3." };

coerce 'Version_ArrayRefOfInts'
	=> from 'VersionString'
		=> via { 
			my $str =($_ eq '2c')? 2 : $_; 
			return [$str] 
		};

has 'hostname' => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);

has 'possible_versions' => (
	isa => 'Version_ArrayRefOfInts',
	is => 'ro',
	default => sub { [2,1] },
	coerce => 1,
	init_arg => 'version',  
);

has 'community' => (
	isa => 'Str',
	is => 'ro',
	default => 'public',
);

has 'port' => (
	isa => 'Num',
	is => 'ro',
	default => 161,
);

has 'timeout' => (
	is => 'rw', 
	isa => 'Num',
	default => 1000000, #microseconds
);

has 'retries' => (
	is => 'rw', 
	isa => 'Num',
	default => 5, 
);

my (%session,%name,%version,%community,%deactivate_bulkwalks);


sub BUILDARGS {
	defined( my $class = shift ) or confess "missing class argument";
	if( @_ == 1 ) {
		return { hostname => shift };
	} 
	else {
		return $class->SUPER::BUILDARGS(@_);
	}	
}


sub BUILD {
		### WARNING WARNING WARNING 
		### MOOSE CAVEAT --
		### when a role is applied, the object's attributes are reset 
		### so, do finish applying whatever roles are needed and THEN create_session
		###
		SNMP::Class::Role::Implementation::NetSNMP->meta->apply($_[0]);
		#the session is also a resultset
		SNMP::Class::Role::ResultSet->meta->apply($_[0]);
		$_[0]->create_session;

}

sub add {
	defined(my $self = shift(@_) ) or croak 'incorrect call';
	for my $to_walk (@_) {
		$self->append($self->smart($to_walk));
	}
	return $self;
}

=head1 METHODS

=head2 new(hostname => $host, community => $community, port => $port, version => $version)

This method creates a new session with a managed device. If just the IP or Hostname of the managed device is specified in a single argument ($s->new('myhost.mydomain')), then the module will try to talk using SNMPv2c and community 'public'. If it fails to get a response, it also try to use SNMPv1 with the same 'public' community. If one wishes to specify those details explicitly, one may do so by using the more general form above. The version argument can be either a string or a reference to an array of strings. Allowed values for those strings are '1','2','2c','3'. '2' and '2c' both mean version 2. The module will try to use those versions in the order stored in the array. If unspecified, community will default to 'public', port will default to '161', version will default to ['2','1']. 

=head2 add(@list)

This method tells the module to snmpwalk the specified object ids and store the results. For example:
 
 $s->add('system','interfaces'); 

This will walk the agent under the system and the interfaces subtrees and store the results in $s. If version is 2 or above, the module will try to use snmpbulkwalk otherwise it will resort to snmpgetnext. The results are stored in $s itself. To retrieve them, use $s an L<SNMP::Class:Role::ResultSet>. 

=cut
 
=head1 AUTHOR

Athanasios Douitsis, C<< <aduitsis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP::Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT


=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNMP::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNMP::Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNMP::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/SNMP::Class>

=back

=head1 ACKNOWLEDGEMENTS

This module uses the Perl libraries from the Net-SNMP package (L<http://www.net-snmp.org/>). I feel immensely indebted to the people that made that package available. 

=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 Athanasios Douitsis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;

__PACKAGE__->meta->make_immutable;

1; # End of SNMP::Class
