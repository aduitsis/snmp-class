package SNMP::Class::Role::ResultSet;

=head1 NAME

SNMP::Class::Role::ResultSet - A set of L<SNMP::Class::Varbind> objects. 

=cut

use version; our $VERSION = qv("0.12");

=head1 SYNOPSIS

    use SNMP::Class::ResultSet;

    my $foo = SNMP::Class::ResultSet->new;
    $foo->push($vb1);
    
    ...
    

=cut

use warnings;
use strict;
use Carp;
use SNMP::Class;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use Log::Log4perl qw(:easy);
my $logger = get_logger();

# deactivated because the . could cause strange side effects when accidentally trying to print 
# a ResultSet . The error message produced is not informative at all
#use overload 
#	'@{}' => \&varbinds,
#	'.' => \&dot,
#	'+' => \&plus,
#	fallback => 1;


subtype 'ArrayRefofVarbinds' => as 'ArrayRef[SNMP::Class::Varbind]';
has 'varbinds' => (
	isa => 'ArrayRefofVarbinds',
	is => 'rw',
	default => sub { [] },
);


has '_fulloid_index' => (
	isa => 'HashRef[Any]',
	is => 'rw',
	default => sub { {} },
);
has '_label_index' => (
	isa => 'HashRef[Any]',
	is => 'rw',
	default => sub { {} },
);
has '_instance_index' => (
	isa => 'HashRef[Any]',
	is => 'rw',
	default => sub { {} },
);

	

=head1 METHODS

B<IMPORTANT NOTICE:> All the methods that return a ResultSet will 
only do so when called in scalar context. They return 
the list of varbinds in list context.

=over 4

=item B<new>

Constructor. Just issue it without arguments. 
Creates an empty ResultSet. SNMP::Class::Varbind objects can later 
be stored in there using the push method.

=item B<smart_return>

In scalar context, this method returns the object itself, 
while in list context returns the list of the varbinds. 
In null context, it will croak. 
This method is mainly used for internal purposes. 


=cut

sub smart_return {
	defined(my $context = wantarray) or croak "ResultSet used in null context";
	if ($context) { #list context
		#the check for the empty resultset has been moved here, applying only to the list context
		$logger->logconfess('Empty resultset detected') if $_[0]->is_empty; #just making sure than an empty resultset will not come up 
		DEBUG 'List context detected, probably some while loop';
		return @{$_[0]->varbinds};
	}
	####TRACE 'Scalar context detected';
	return $_[0];
}

=item B<varbinds>

Accessor. Returns a reference to a list containing all the stored varbinds. 
B<WARNING:> Modifying the list alters the object.


=item B<dump>

Returns a string representation of the entire ResultSet. 
Can be used for debugging purposes. 


=cut

sub dump  {
	return "resultset dump \n".join("\n",($_[0]->map(sub {$_->dump})))."\n---------------\n";
}

=item B<push( $item1 , $item2 , ...)>

Will push arguments to resultset. Arguments must be L<SNMP::Class::Varbind>s (or descendants of that class). 
This method will happily push all the items it is given. 

=cut

sub push {
	defined( my $self = shift(@_) ) or die 'incorrect call';
	### TRACE "pushing item(s): ".join(',',(map{$_->to_varbind_string}(@_)));	
	push @{$self->varbinds},(@_);
	
	### TRACE "indexing fulloid(s) ".join(',',(map{$_->numeric}(@_)));
	map { $self->_fulloid_index->{$_->numeric} = $_ } (@_);
	map { push @{$self->_instance_index->{$_->get_instance_oid->numeric}},$_ if $_->has_instance} (@_);
	map { push @{$self->_label_index->{$_->get_label}},$_ if $_->has_label} (@_);

}

=item B<pop>

Pops a varbind out of the Set. Takes no arguments. Although order is preserved at this point, this behavior is not
guaranteed, so this method should not be used to pop items in a specific order. 

=cut

sub pop {
	return pop @{$_[0]->varbinds};
	#@TODO : Cleanup the indexes as well
	#
}



#take a list with possible duplicate elements
#return a list with each element unique
#sub unique {
#	my @ret;
#	for my $elem (@_) {
#		next unless defined($elem);
#		CORE::push @ret,($elem) if(!(grep {$elem == $_} @ret));#make sure the the == operator does what you expect
#	}
#	return @ret;
#}


#this function (this is not a method) takes an assorted list of SNMP::Class::OIDs, SNMP::Class::ResultSets and even strings
#and returns a proper list of SNMP::Class::OIDs. Used for internal purposes. Does not appear in the perldoc.
#Its usefulness is to provide a uniform list to compare items to
sub construct_matchlist {
	my @matchlist;
	for my $item (@_) {
		if(ref($item)) {
			if ( eval $item->isa("SNMP::Class::OID") ) {
				CORE::push @matchlist,($item);
			}
			elsif (eval $item->isa('SNMP::Class::ResultSet')) {
				CORE::push @matchlist,(@{$item->varbinds});
			}
			else { 
				croak "I don't know how to handle a ".ref($item);
			}
		}
		else {
			CORE::push @matchlist,(SNMP::Class::OID->new($item));
		}
	}
	return @matchlist;
}


#4 little handly subroutines to use for matching using various ways

#DON"T FORGET THE INDEXED FUNCTION SHORTCUTS WHEN YOU CHANGE THIS METHOD
sub match_label {
	my($x,$y) = @_;
	return unless defined($x->get_label_oid); #make sure the item has a label
	return unless defined($y->get_label_oid);
	return $x->get_label_oid->oid_is_equal( $y->get_label_oid ); #compare the labels - nothing else
}


#y is what we are looking for
#x is what we have in our set
sub match_label_under {
	my($x,$y) = @_;
	return unless defined($x->get_label_oid); #make sure the item has a label
	return unless defined($y->get_label_oid);
	#####DEBUG $x->get_label_oid->numeric.' '.$y->get_label_oid->numeric.' '.$y->get_label_oid->contains( $x->get_label_oid );
	return $y->get_label_oid->contains( $x->get_label_oid ); #this way we get everything under what we are looking for
}

#order of args is important
# $_[0] is the full oid
# $_[1] is the instance
#DON"T FORGET THE INDEXED FUNCTION SHORTCUTS WHEN YOU CHANGE THIS METHOD
sub match_instance {
	my($x,$y) = @_;
	return unless $x->has_instance;
	#return unless defined($x->get_label_oid);
	#this may need some changes later
	#return unless defined($y->get_label_oid);
	#DEBUG "x is ".$x->get_instance_oid->dump;
	#DEBUG "y is ".$y->dump;
	return $x->get_instance_oid->oid_is_equal( $y );
}

sub match_fulloid {
	my($x,$y) = @_;
	return $x->oid_is_equal( $y ); #Captain Obvious
}

#order of args is important
# $_[0] is the varbind
# $_[1] is the value
sub match_value {
	my($x,$y) = @_;
	return $x->value eq $y;
}

#order of args is important
# $_[0] is the varbind
# $_[1] is the raw_value
sub match_raw_value {
	my($x,$y) = @_;
	return $x->raw_value eq $y;
}


# (this is not a method!)
# this is the core of the filtering mechanism
# the match_callback method may be used as an argument to the filter method
# takes 2 arguments:
# 1)a reference to a comparing subref which returns true or false (see 5 ready match_* subrefs above)
# 2)a list of items to match against. In many cases you should probably pipe multiple items through construct_matchlist to this argument
# produces a closure that matches $_ against any of those items (grep-style) using the comparing subref
sub match_callback {
	defined(my $match_sub_ref = shift(@_)) or croak 'Missing match_sub_ref argument';
	my @matchlist = (@_);
	confess "Please do not supply empty matchlists in your filters -- completely pointless" unless @matchlist;
	#TRACE 'matchlist is '.join(',',@matchlist);
	return sub {		
		for my $match_item (@matchlist) {
			if ($match_sub_ref->($_,$match_item)) {
				TRACE "Item ".$_->to_string." matches"; 
				#if you take a look at sub filter, you will notice that that the $_ iterates over 
				#the items of the result set and is compared against each of the filter arguments
				#the iteration over the filter arguments is being made here, in match_callback
				#the iteration over the resultset is being done inside the filter method
				return 1;
			}
		}
		return;
	};
}

=item B<filter_label_under( $oid1 , $oid2 , ... )>

Returns a subset of the ResultSet whose OIDs fall under or are equal to  
$oid1 or $oid2, etc. Each $oidX can be an L<SNMP::Class::OID> or an L<SNMP::Class::Varbind> 
or even just a string (example: 'ifDescr') in which case it will be interpreted accordingly. 



=cut

sub filter_label_under {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	
	#this is slow for big sets
	###return $self->filter(match_callback(\&match_label_under,construct_matchlist(@_)));

	#maybe this will go a little faster
	my $ret = SNMP::Class::ResultSet->new;
	for my $to_match (construct_matchlist(@_)) { #as much iterations as the arguments of this method
		for my $label ($self->enumerate_labels) { #how many labels do we have
			if (match_label_under(SNMP::Class::OID->new($label),$to_match)) {
				####DEBUG "$label is under ".$to_match->get_label;
				$ret->push(@{$self->_label_index->{$label}});
			}
		}
	}
	return $ret->smart_return;
}

=item B<filter_label( $oid1 , $oid2 , ... )>

Same as filter_label_under, but does keep only those ResultSet items that have equal OID to the
method arguments.

=cut

###sub filter_label {
###	defined(my $self = shift(@_)) or croak 'Incorrect call';
###	return $self->filter(match_callback(\&match_label,construct_matchlist(@_)));
###}
sub filter_label {
	defined(my $self = shift(@_)) or croak 'Incorrect call';

	#my @labels = map { $_->get_label if $_->has_label} construct_matchlist(@_);
	#TRACE "matchlist is ",join(',',@labels);

	my $ret = SNMP::Class::ResultSet->new;
	map { $ret->push(@{$self->_label_index->{$_->get_label}}) if $_->has_label } construct_matchlist(@_);
	return $ret->smart_return;
}

###sub filter_instance {
###	defined(my $self = shift(@_)) or croak 'Incorrect call';
###	return $self->filter(match_callback(\&match_instance,construct_matchlist(@_)));
###}


=item B<contains_label( $oid )>

Used to check whether the ResultSet contains at least one item under the label which 
has equal label to $oid. Example:

 if($rs->contains_label('ifTable') #checks if $rs has indeed the ifTable


=cut
sub contains_label {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	defined(my $oid = shift(@_)) or croak 'Incorrect call';
	my $to_test = SNMP::Class::OID->new($oid);
	$logger->logconfess('no label available for argument') if ! $to_test->has_label;

	#shortcut, will return 1 very fast is there is an exact key available
	return 1 if exists $self->_label_index->{$oid};

	#which labels do we have?
	for my $label ($self->enumerate_labels) {
		####DEBUG $to_test->get_label_oid->numeric.' '.$label;
		return 1 if $to_test->get_label_oid->contains($label);
	}	
	return;
}

=item B<enumerate_labels>

Returns a list of all the labels present in the resultset. Each label appears exactly once.

=cut

sub enumerate_labels {
	return keys %{$_[0]->_label_index};
}
		
		
=item B<filter_instance( $oid1 , $oid2 , ... )>

Returns a subset with only those resultset items that have their instance equal to one of the
arguments. The $oidX items must be instance parts only, not full OIDs.

Example: $rs->filter_instance('.15'); 

=cut

sub filter_instance {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	my @instances = map { $_->numeric } construct_matchlist(@_);
	DEBUG "matchlist is ",join(',',@instances);
	my $ret = SNMP::Class::ResultSet->new;
	map { $ret->push(@{$self->_instance_index->{$_->numeric}}) } construct_matchlist(@_);
	return $ret->smart_return;
}

=item B<filter_instance_from_full( $oid1 , $oid2 , ... )>

Returns a subset with only those resultset items that have their instance equal to one of the
arguments. The $oidX items must be full OIDs, in contrast with B<filter_instance>.

Example: $rs->filter_instance('.1.3.6.1.2.1.2.2.1.2.15'); #will keep instance 15

=cut

#what is the difference from the filter_instance method? 
#the difference is that here the arguments are full blown oids
#instead of bare instances. So, this method check that each of its
#arguments actually *has* an instance and then takes care to extract
#it from the oid
#example: $result_set->filter_instance_from_full('ifDescr.25') 
#will filter the contents of result_set that have their instance equal to .25
sub filter_instance_from_full {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	my @instances = map { $_->get_instance_oid->numeric if ($_->has_instance) } construct_matchlist(@_);
	DEBUG "matchlist is ",join(',',@instances);
	my $ret = SNMP::Class::ResultSet->new;
	map { $ret->push(@{$self->_instance_index->{$_}}) } @instances;
	return $ret->smart_return;
}

=item B<filter_fulloid( $oid1 , $oid2 , ... )>

Returns a subset with only those resultset items that have their OIDs exactly equal to one of
the arguments

=cut

sub filter_fulloid {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	return $self->filter(match_callback(\&match_fulloid,construct_matchlist(@_)));
}

=item B<filter_value( $oid1 , $oid2 , ... )>

Returns a subset with only those resultset items that have their value equal to one of
the arguments. Do note that to extract the value from each resultset item, the value 
(B<NOT> the raw_value) method is used.

=cut

sub filter_value {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	return $self->filter(match_callback(\&match_value,@_));
}

=item B<filter_raw_value( $oid1 , $oid2 , ... )>

Returns a subset with only those resultset items that have their value equal to one of
the arguments. Do note that to extract the value from each resultset item, the raw_value
method is used.

=cut

sub filter_raw_value {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	return $self->filter(match_callback(\&match_raw_value,@_));
}

=item B<filter( $subref )>

Method filter can be used when there is the need to filter the varbinds inside the resultset 
using arbitrary rules. Takes one argument, a reference to a subroutine which will be doing 
the filtering. The subroutine must return an appropriate true or false value just like in
L<CORE::grep>. The value of each L<SNMP::Class::Varbind> item in the ResultSet gets assigned 
to the $_ global variable. For example:

 print $rs->filter(sub {$_->get_label_oid == 'sysName'}); 

If used in a scalar context, a reference to a new ResultSet containing the filter results will be returned. 
If used in a list context, a simple array containing the varbinds of the result will be returned. 
Please note that in the previous example, the print function always forces list context, 
so we get what we want.

=cut

sub filter {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	my $coderef = shift(@_);
	if(ref($coderef) ne 'CODE') {
		confess "First argument must be always a reference to a sub";
	}
	my $ret_set = SNMP::Class::ResultSet->new;
	map { $ret_set->push($_); } ( grep { &$coderef; } @{$self->varbinds} );
	
	return $ret_set->smart_return;
}

=item B<<< find( key1 => value1 , key2 => value2 , ... ) >>>

Filters based on key-value pairs that are labels and values. 

When using SNMP, a programmer often has to single out the row(s) of a table based on a criterion. 
For example, suppose one wants to find the rows of the interfaces table for which the ifDescr of 
the interface is 'eth0' or 'eth1'. If $rs is the entire resultset containing everything, one should 
probably do something like:

 $rs_new = $rs->find('ifDescr' => 'eth0', ifDescr => 'eth1');

which will find the instance oids of the rows that have ifDescr equal to 'eth0' B<or> 'eth1' (if any), 
and filter using that instances. Anything under those instances is returned, all else is filtered out.

This means that to get the ifSpeed of eth0, one can simply issue:
 
 my $speed = $rs->find('ifDescr' => 'eth0')->ifSpeed;

B<WARNING>: This method assumes the programmer is looking 
for something that actually exists. In the above example, 
if an ifDescr with that value does not exist, the method will croak. 
So, if not certain, make sure that you handle that error (e.g. use eval)  

=cut
  	
sub find {
	defined(my $self = shift(@_)) or croak 'Incorrect call';

	my @matchlist = ();
	
	while(1) {
		my $object = shift(@_);
		last unless defined($object);
		my $value = shift(@_);
		last unless defined($value);
		DEBUG "Searching for instances with $object == $value";
		#TRACE Dumper($self->filter_label($object));
		my @to_return = ( $self->filter_label($object)->filter_value($value) ); #force list context
		CORE::push @matchlist,(@to_return);
	}
	#TRACE 'matchlist:' . Dumper(@matchlist);
	
	#be careful. The matchlist which we have may very well be empty! 
	#we should not be filtering against an empty matchlist
	#note that the filter_instance will croak in such a case.
	return $self->filter_instance_from_full(@matchlist);
}


=item B<number_of_items>

Returns the number of items in the ResultSet

=cut

sub number_of_items {
	return scalar @{$_[0]->varbinds};
}

=item B<is_empty>

Tells whether the ResultSet is empty or not.

=cut

sub is_empty {
	return ($_[0]->number_of_items == 0);
}

=item B<exact( $label , $instance )>

When looking for a specific label and instance combination, this method might render assistance. Example:

$rs->exact('ifDescr','.3');

will return the ifDescr.3 items inside the resultset. One has to make sure that what is being looked for actually
exists, otherwise the method will croak. Use eval when unsure, or alternatively, check with one of the has_*
methods. 

=cut

sub exact {
	defined(my $self = shift(@_)) or croak 'incorrect call';
	defined(my $label = shift(@_)) or croak 'incorrect call';
	defined(my $instance = shift(@_)) or croak 'incorrect call';
	
	my $numeric = SNMP::Class::OID->new($label)->add($instance)->numeric;
	DEBUG $numeric.' was requested';
	if(exists $self->_fulloid_index->{$numeric}) {
		return $self->_fulloid_index->{$numeric};
	}
	$logger->logconfess("Sorry! Cannot find $numeric inside the resultset");
}

=item B<has_exact( $label , $instance )>

Returns true if the resultset contains at least one item with label equal to $label and with instance
$instance. 

=cut

sub has_exact {
	return exists $_[0]->_fulloid_index->{SNMP::Class::OID->new($_[1])->add($_[2])->numeric};
}

=item B<has_numeric( $numeric_oid )>

Returns true if the resultset contains at least one item with its OID equal B<in numeric form> to $numeric_oid. Example:

$rs->has_numeric('.1.3.6.1.2.1.2.2.1.2.15');

=cut

sub has_numeric {
	return exists $_[0]->_fulloid_index->{$_[1]};
}

# dot method is not used anymore as the overloaded parts have been switched off. Let it
# stay here for a while
sub dot {
	defined(my $self = shift(@_)) or croak "Incorrect call to dot";
	my $str = shift(@_); #we won't test because it could be false, e.g. ifName.0
	
	#caveat emptor
	#when $str is not a string, evul things will happen as $str will try to call something like:
	#SNMP::Class::OID::add($object, 'dot called with ', 1)
	####$logger->debug("dot called with $str as argument");

	#we force scalar context
	my $ret = scalar $self->filter_instance($str);

	if ($ret->is_empty) {
		confess "dot produced an empty resultset";
	} 
	if ($ret->number_of_items > 1) {
		carp "Warning: resultset with more than 1 items";
	}
	return $ret->item(0);
}

=item B<item( $index )>

Returns the item of the ResultSet with index same as $index. 
Calling the method with no argument yields the first item (index 0) in the ResultSet.

=cut
 
sub item {
	defined(my $self = shift(@_)) or croak "Incorrect call";
	my $index = shift(@_) || 0;
	return $self->varbinds->[$index];
}

#calls named method $method on the and hopefully only existing item. Should not be used by the user.
#This is an internal shortcut to simplify method creation that applies to SNMP::Class::OID single members of a ResultSet
sub item_method {
	defined(my $self = shift(@_)) or croak "Incorrect call";
	my $method = shift(@_) or croak "missing method name";
	my @rest = (@_);
	if($self->is_empty) {
		croak "$method cannot be called on an empty result set";
	}
	if ($self->number_of_items > 1) {
		WARN "Warning: Calling $method on a result set that has more than one item";
	}
	return $self->item(0)->$method(@rest);
}

#warning: plus will not protect you from duplicates
#plus will return a new object
=item B<plus( $other_resultset )>

Can be used to merge two resultsets. Returs a third resultset which contains all the items
from both. Duplicates are not checked and will appear if both resultsets contain similar items.

=cut

sub plus {
	defined(my $self = shift(@_)) or croak "Incorrect call to plus";
	my $item = shift(@_) or croak "Argument to add(+) missing";

	#check that this object is an SNMP::Class::ResultSet
	confess "item to add is not an SNMP::Class::ResultSet!" unless (ref($item)&&(eval $item->isa("SNMP::Class::ResultSet")));

	my $ret = SNMP::Class::ResultSet->new();

	map { $ret->push($_) } (@{$self->varbinds});
	map { $ret->push($_) } (@{$item->varbinds});

	return $ret;
}

#append acts on $self
=item B<append( $other_resultset )>

Same as add, but acts on the object itself. 

=cut
sub append { 
	defined(my $self = shift(@_)) or croak "Incorrect call to append";
	my $item = shift(@_) or croak "Argument to append missing";
	#check that this object is an SNMP::Class::Varbind
	confess "item to add is not an SNMP::Class::ResultSet!" unless (ref($item)&&(eval $item->isa("SNMP::Class::ResultSet")));
	map { $self->push($_) } (@{$item->varbinds});
	return;
}

#it is allowed to call map on an empty resultset
=item B<map( $subref )>

Iterates over the items of the resultset, calling subref on each of the items. $subref gets the
item through the $_ variable. This method returns a list of the return values returned by each 
invocation of $subref. 

This method works a lot similar to the L<CORE::map> function. For a grep-equivalent, see the B<filter> method.

=cut

sub map {
	defined(my $self = shift(@_)) or croak "Incorrect call";
	my $func = shift(@_) or croak "missing sub";
	croak "argument should be code reference" unless (ref $func eq 'CODE');
	#$logger->debug("mapping....");
	my @result;
	for(@{$self->varbinds}) {
		#$logger->debug("executing sub with ".$_->dump);
		CORE::push @result,($func->());
	}
	return @result;
}

=back

=head1 AUTOLOADed methods

=over 4

=item B<label>

A resultset will try to respond to any method matching a name of a known label. For example,

$rs->ifName 

is the same as: 

$rs->filter_label('ifName') 

=item B<label( $instance )>

In addition to the previous case, if there is an argument supplied to the label method, an exact
item matched from the resultset is returned. For example:

$rs->ifName(2) 

is the same as

$rs->exact('ifname','.2') 

=item B<item method>

When a resultset has only one item, it will respond to methods belonging to the item.
For example:

$rs->ifName(2)->value 

is the same as

$rs->exact('ifName','2')->item(0)->value

The available methods of the item are determined by using find_all_methods_by_name on the meta 
of the item. 

B<WARNING> : When using this feature, a warning will be issued when using a resultset with more than one
items. Furthermore, the module will croak if trying to call a method on an empty resultset.

=back

=cut


our $AUTOLOAD;

sub AUTOLOAD {
	defined(my $self = shift(@_)) or confess("Incorrect call to AUTOMETHOD");
	####DEBUG $AUTOLOAD;
	$logger->logconfess('Empty resultset') if $self->is_empty;

	my ($subname) = ($AUTOLOAD =~ /::(\w+)$/);   # Requested subroutine name is passed via $_;
	
	DEBUG "method $subname called";

	####DEBUG 'number of items is '.$self->number_of_items;
	#####DEBUG 'xxx '.Dumper($self->varbinds->[0]->meta->find_all_methods_by_name($subname));
	####DEBUG $self->dump;



	#first: if the resultset has only one item and that item has the requested method, call that method
	if( ($self->number_of_items == 1) && ($self->varbinds->[0]->meta->find_all_methods_by_name($subname)) ) {
		DEBUG $self->varbinds->[0]->to_varbind_string." actually has the $subname method";	
		return $self->item_method($subname,@_);
	}
	elsif (SNMP::Class::Utils::is_valid_oid($subname)) {
		DEBUG "$subname is a label, returning filter_label($subname)";	
		#if we have more arguments, someone requests an exact instance
		if(defined(my $instance = shift(@_))) {
			DEBUG 'special invocation, instance was requested';
			return $self->exact($subname,$instance);
		}
		return $self->filter_label($subname);

	}
	$logger->logconfess("I cannot match $subname with anything.");
	#elsif (SNMP::Class::Varbind->can($subname)) {
	#	DEBUG "$subname method call was refering to the contained varbind. Will delegate to the first item. Resultset is ".$self->dump;
	#	return $self->item_method($subname,@_);
	#}	
	#else {
	#	$logger->debug("$subname doesn't seem like something I can actually make sense of. .");
	#	return;
	#}
}
	
 


=head1 AUTHOR

Athanasios Douitsis, C<< <aduitsis at cpan.org> >>

=head1 BUGS

I would be thankful for any issues reported through L<https://github.com/aduitsis/snmp-class/issues>. 

=head1 SUPPORT

For the time being, please mail the author directly, or simply file an issue. 

=head1 COPYRIGHT & LICENSE

Copyright 2011 Athanasios Douitsis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::Class::ResultSet
