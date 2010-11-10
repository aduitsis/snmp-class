package SNMP::Class::Utils;

our $VERSION='0.08';

use strict;
use warnings;
use Carp;
use Exporter;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

our @ISA=qw(Exporter);

our @EXPORT = qw(get_attr children_of label_of parent_of oid_of descendants_of);


#str2arr converts a .1.2.3.4-style oid to an array
sub str2arr {
	my $str = shift(@_) or confess "str2arr 1st arg missing";
	my ($dummy,@ret) = split('\.',$str); 
	return @ret;
}
	
#get_attr takes two arguments:
#1)The oid we are interested in
#2)The attribute of that oid we are interested in
#example: get_attr('sysName','objectID')
sub get_attr {
	defined(my $oid_name = shift(@_)) or confess "undefined oid_name";
	defined(my $attr = shift(@_)) or confess "undefined attr";
	if(!defined($SNMP::MIB{$oid_name})) {
		DEBUG "There is no such object: $oid_name";
		return;
	}
	my $ret = $SNMP::MIB{$oid_name}->{$attr};
	return unless defined $ret;
	return if $ret eq '';
	return $ret;
}


sub children_of {
	my $oid_name = shift(@_) or croak "Incorrect call to children_of";
	my $children = get_attr($oid_name,'children');
	my @children = map { $_->{label} } @{$children};
}

sub textual_convention_of {
	my $oid_name = shift(@_) or croak "Incorrect call to textual_convention_of";
	return get_attr($oid_name,'textualConvention');
}

sub has_textual_convention {
	return defined(textual_convention_of($_[0]));
}

sub type_of {
	my $oid_name = shift(@_) or croak "Incorrect call to type_of";
	return get_attr($oid_name,'type');
}

sub has_type {
	return defined(type_of($_[0]));
}

sub syntax_of {
	return get_attr(shift,'syntax');
}

sub has_enums {
	defined(my $oid = shift) or croak 'incorrect call';
	return defined( enums_of($oid) );
}
	

sub enums_of {
	my $oid_name = shift(@_) or croak "Incorrect call to enums_of";
	my $enum = SNMP::Class::Utils::get_attr($oid_name,"enums");
	if(%{$enum}) {
		TRACE "$oid_name is an enumerated type";
		my %reverse = map { $enum->{$_} => $_ } (keys %{$enum});
		return \%reverse;
	}
	return;
}
	

sub label_of {
	my $oid_name = shift(@_);
	croak "Incorrect call to label_of" unless defined($oid_name);
	return get_attr($oid_name,'label');
}

sub subid_of {
	my $oid_name = shift(@_);
	croak "Incorrect call to label_of" unless defined($oid_name);
	return get_attr($oid_name,'subID');
}

sub parent_of {
	my $oid_name = shift(@_) or croak "Incorrect call to parent_of";
	my $parent = get_attr($oid_name , 'parent') or return;
	return $parent->{label};
}

sub oid_of {
	defined( my $oid_name = shift(@_) ) or croak "undefined oid_name";
	return get_attr($oid_name,'objectID');
}

sub descendants_of {
	my $oid_name = shift(@_) or croak "Incorrect call to descendants_of";

	#we will mark visited descendant nodes through this hash
	my %descendants_of;

	#we init the stack with one member, the oid_name itself
	my @stack = (label_of($oid_name));

	#and we continue while there is still stuff inside the stack
	while(@stack) {
		my $item = pop @stack;
		$descendants_of{$item}=1;
		my @children = children_of($item);
		push @stack,(@children);
	}

	return \%descendants_of;
}

sub is_valid_oid {
	my $str = shift(@_);
        eval { get_attr($str,"objectID") };
        if($@) {
                $logger->debug("$str doesn't seem like a valid OID. Returning undef...");
                return;
        }
	$logger->debug("$str seems like a valid OID ");
	return 1;
}

sub convert_to_netsnmp_oid {
	defined ( my $str = shift ) or confess "Missing parameter";
	if(my $obj = NetSNMP::OID->new($str)) {
		return $obj;
	}
	return;
}

sub convert_str_to_array {
	defined ( my $str = shift ) or confess "missing argument";
	$str = (substr($str,0,1) eq '.')? substr($str,1) : $str;
	my @arr = ( split('\.',$str) );
	confess "Empty oid" unless @arr;
	###DEBUG "$str converts to ".join(',',@arr);
	return @arr;
}

	
1;
