package SNMP::Class;

=head1 NAME

SNMP::Class - A convenience class around the NetSNMP perl modules. 

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.15';

=head1 SYNOPSIS

This module aims to enable snmp-related tasks to be carried out with the best possible ease and expressiveness while at the same time allowing advanced features like subclassing to be used without hassle.

	use SNMP::Class;
	
	#create a session to a managed device -- 
	#community will default to public, version will be autoselected from 2,1
	my $s = SNMP::Class->new({DestHost => 'myhost'});    
	
	#modus operandi #1
	#walk the entire table
	my $ifTable = $s->walk("ifTable");
	#-more compact- 
	my $ifTable = $s->ifTable;
	
	#get the ifDescr.3
	my $if_descr_3 = $ifTable->object("ifDescr")->instance("3");
	#more compact
	my $if_descr_3 = $ifTable->object(ifDescr).3;
	
	#iterate over interface descriptions -- method senses list context and returns array
	for my $descr ($ifTable->object"ifDescr")) { 
		print $descr->get_value,"\n";
	}
	
	#get the speed of the instance for which ifDescr is en0
	my $en0_speed = $ifTable->find("ifDescr","en0")->object("ifSpeed")->get_value;  
	#
	#modus operandi #2 - list context
	while($s->ifDescr) {
		print $_->get_value;
	}
	
   
=head1 METHODS

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


###use Log::Log4perl qw(:easy);
###Log::Log4perl->easy_init({
###	level=>$DEBUG,
###	layout => "%M:%L %m%n",
###});
###my $logger = get_logger();


###############################################################

# setup logging

use Log::Log4perl;

# try to find a universal.logger in the same path with this file

for my $lib (@INC) {
	my $logger_file = $lib.'/SNMP/SNMP-Class.logger';
	if (-f $logger_file) {
		Log::Log4perl->init($logger_file);
	} 
}

###############################################################


####&SNMP::loadModules('ALL');


#has 'netsnmp_session' => (
#	isa => 'SNMP::Session',
#	is => 'ro',
#	required => 1, #when we are going to get alternatives, we'll switch that to 0
#);

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
}

=head2 new({DestHost=>$desthost,Community=>$community,Version=>$version,DestPort=>$port})

This method creates a new session with a managed device. Argument must be a hash reference (see L<Class::Std> for that requirement). The members of the hash reference are the same with the arguments of the new method of the L<SNMP> module. If Version is not present, the library will try to probe by querying sysName.0 from the device using version 2 and then version 1, whichever succeeds first. This method croaks if a session cannot be created. If the managed node cannot return the sysName.0 object, the method will also croak. Most people will want to use the method as follows and let the module figure out the rest.
 
 my $session = SNMP::Class->new({DestHost=>'myhost.mydomain'}); 
 

=cut
 




#=head2 AUTOMETHOD
#
#Using a method call that coincides with an SNMP OBJECT-TYPE name is equivalent to issuing a walk with that name as argument. This is provided as a shortcut which can result to more easy to read programs. 
#Also, if such a method is used in a list context, it won't return an SNMP::ResultSet object, but rather a list with the ResultSet's contents. This is pretty convenient for iterating through SNMP results using few lines of code.
#
#=cut
#
#sub AUTOMETHOD {
#	my $self = shift(@_) or croak("Incorrect call to AUTOMETHOD");
#	my $ident = shift(@_) or croak("Second argument to AUTOMETHOD missing");
#	my $subname = $_;   # Requested subroutine name is passed via $_;
#	$logger->debug("AUTOMETHOD called as $subname");  
#	
#	if (eval { my $dummy = SNMP::Class::Utils::get_attr($subname,"objectID") }) {
#		$logger->debug("$subname seems like a valid OID ");
#	}
#	else {
#		$logger->debug("$subname doesn't seem like a valid OID. Returning...");
#		return;
#	}
#	
#	#we'll just have to create this little closure and return it to the Class::Std module
#	#remember: this closure will run in the place of the method that was called by the invoker
#	return sub {
#		if(wantarray) {
#			$logger->debug("$subname called in list context");
#			return @{$self->walk($subname)->varbinds};
#		}
#		return $self->walk($subname);
#	}
#
#}






=head1 AUTHOR

Athanasios Douitsis, C<< <aduitsis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP::Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNMP::Class

You can also look for information at:

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

This module obviously needs the perl libraries from the excellent Net-SNMP package. Many thanks go to the people that make that package available.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Athanasios Douitsis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;

__PACKAGE__->meta->make_immutable;

1; # End of SNMP::Class
