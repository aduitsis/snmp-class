package SNMP::Class::ResultSet;

# this package is just an empty Moose class to which we apply the SNMP::Class::Role::ResultSet
# role. 

use warnings;
use strict;
use SNMP::Class::Role::ResultSet;
use Moose;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

sub BUILD {
	SNMP::Class::Role::ResultSet->meta->apply($_[0]);
}

#sub AUTOLOAD {
#	defined(my $self = shift(@_)) or confess("Incorrect call to AUTOMETHOD");
#	my $subname = $::AUTOLOAD;   # Requested subroutine name is passed via $_;
#	
#	DEBUG "method $subname called";
#	#first: if the resultset has only one item and that item has the requested method, call that method
#	if( ($self->number_of_items == 1) && ($self->varbinds->[0]->meta->has_method($subname)) ) {
#		DEBUG $self->varbinds->[0]->to_varbind_string."actually has the $subname method";	
#		$self->varbinds->[0]->$subname(@_);
#	}
#	elsif (SNMP::Class::Utils::is_valid_oid($subname)) {
#		$logger->debug("ResultSet: $subname seems like a valid OID ");	
#		DEBUG "Returning the resultset";
#		return $self->filter_label($subname);
#
#	}
#	elsif (SNMP::Class::Varbind->can($subname)) {
#		DEBUG "$subname method call was refering to the contained varbind. Will delegate to the first item. Resultset is ".$self->dump;
#		return $self->item_method($subname,@_);
#	}	
#	else {
#		$logger->debug("$subname doesn't seem like something I can actually make sense of. .");
#		return;
#	}
#}
#	
 
1;

