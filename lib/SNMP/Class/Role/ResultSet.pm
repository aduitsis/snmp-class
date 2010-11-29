package SNMP::Class::Role::ResultSet;

=head1 SNMP::Class::ResultSet

SNMP::Class::ResultSet - A set of L<SNMP::Class::Varbind> objects. 

=head1 VERSION

Version 0.12

=cut

use version; our $VERSION = qv("0.12");

=head1 SYNOPSIS

    use SNMP::Class::ResultSet;

    my $foo = SNMP::Class::ResultSet->new;
    $foo->push($vb1);
    
    ...
    
    #later:
    my $varbind = $foo->pop;
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

use overload 
	'@{}' => \&varbinds,
	'.' => \&dot,
	'+' => \&plus,
	fallback => 1;


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

B<IMPORTANT NOTICE:> All the methods that are returning a ResultSet will only do so when called in scalar context. They alternatively return the list of varbinds in list context.

=head2 new

Constructor. Just issue it without arguments. Creates an empty ResultSet. SNMP::Class::Varbind objects can later be stored in there using the push method.

=head2 smart_return 

In scalar context, this method returns the object itself, while in list context returns the list of the varbinds. In null context, it will croak. This method is mainly used for internal purposes. 

=cut

sub smart_return {
	defined(my $context = wantarray) or croak "ResultSet used in null context";
	$logger->logconfess('Empty resultset detected') if $_[0]->is_empty; #just making sure than an empty resultset will not come up
	if ($context) { #list context
		DEBUG 'List context detected, probably some while loop';
		return @{$_[0]->varbinds};
	}
	####TRACE 'Scalar context detected';
	return $_[0];
}

=head2 varbinds

Accessor. Returns a reference to a list containing all the stored varbinds. Modifying the list alters the object.

=head2 dump

Returns a string representation of the entire ResultSet. Mainly used for debugging purposes. 

=cut

sub dump  {
	return "resultset dump \n".join("\n",($_[0]->map(sub {$_->dump})))."\n---------------\n";
}

=head2 push

Will push arguments to resultset. Arguments must be of type L<SNMP::Class::Varbind> (or descendants of that class). 

Since at this point the internal implementation uses just a regular array, order is preserved. But this may change in 
the future, so a program should really not depend on that behavior. 

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

=head2 pop

Pops a varbind out of the Set. Takes no arguments. Although order is preserved at this point, this behavior is not
guaranteed, so this method should not be used to pop items in a specific order. 

=cut

sub pop {
	return pop @{$_[0]->varbinds};
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
#Its usefulness is to provide a list to compare items to
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

sub match_label {
	my($x,$y) = @_;
	return unless defined($x->get_label_oid); #make sure the item has a label
	return unless defined($y->get_label_oid);
	return $x->get_label_oid->oid_is_equal( $y->get_label_oid ); #compare the labels - nothing else
}

#order of args is important
# $_[0] is the full oid
# $_[1] is the instance
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


#(this is not a method!)
#this is the core of the filtering mechanism
#the match_callback method may be used as an argument to the filter method
#takes 2 arguments:
#1)a reference to a comparing subref which returns true or false (see 5 ready match_* subrefs above)
#2)a list of items to match against. In many cases you should probably pipe multiple items through construct_matchlist to this argument
#produces a closure that matches $_ against any of those items (grep-style) using the comparing subref
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


###sub filter_label {
###	defined(my $self = shift(@_)) or croak 'Incorrect call';
###	return $self->filter(match_callback(\&match_label,construct_matchlist(@_)));
###}
sub filter_label {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	my @labels = map { $_->get_label if $_->has_label} construct_matchlist(@_);
	#TRACE "matchlist is ",join(',',@labels);
	my $ret = SNMP::Class::ResultSet->new;
	map { $ret->push(@{$self->_label_index->{$_->get_label}}) if $_->has_label } construct_matchlist(@_);
	return $ret->smart_return;
}
###sub filter_instance {
###	defined(my $self = shift(@_)) or croak 'Incorrect call';
###	return $self->filter(match_callback(\&match_instance,construct_matchlist(@_)));
###}

sub filter_instance {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	my @instances = map { $_->numeric } construct_matchlist(@_);
	DEBUG "matchlist is ",join(',',@instances);
	my $ret = SNMP::Class::ResultSet->new;
	map { $ret->push(@{$self->_instance_index->{$_->numeric}}) } construct_matchlist(@_);
	return $ret->smart_return;
}


#what is the difference from the filter_instance method? 
#the difference is that hare the arguments are full blown oids
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

sub filter_fulloid {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	return $self->filter(match_callback(\&match_fulloid,construct_matchlist(@_)));
}
sub filter_value {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	return $self->filter(match_callback(\&match_value,@_));
}
sub filter_raw_value {
	defined(my $self = shift(@_)) or croak 'Incorrect call';
	return $self->filter(match_callback(\&match_raw_value,@_));
}

=head2 filter

Method filter can be used when there is the need to filter the varbinds inside the resultset using arbitrary rules. Takes one argument, which is a reference to a subroutine which will be doing the filtering. The subroutine must return an appropriate true or false value just like in L<CORE::grep>. The value of each L<SNMP::Class::Varbind> item in the ResultSet gets assigned to the $_ global variable. For example:

 print $rs->filter(sub {$_->get_label_oid == 'sysName'});

If used in a scalar context, a reference to a new ResultSet containing the filter results will be returned. If used in a list context, a simple array containing the varbinds of the result will be returned. Please note that in the previous example, the print function always forces list context, so we get what we want.

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

=head2 find

Filters based on key-value pairs that are labels and values. 

This method is probably purpose that inspired SNMP::Class::ResultSet. When using SNMP, a programmer often has to single out the row(s) of a table based on a criterion. For example, let us suppose we want to find the rows of the interfaces table for which the ifDescr of the interface is 'eth0' or 'eth1'. If $rs is the entire resultset containing everything, we should probably do something like:

 $rs_new = $rs->find('ifDescr' => 'eth0', ifDescr => 'eth1');

which will find which are the instance oids of the rows that have ifDescr equal to 'eth0' B<or> 'eth1' (if any), and filter using that instances. Anything under those instances is returned, all else is filtered out.

This means that to get the ifSpeed of eth0, one can simply issue:
 
 my $speed = $rs->find('ifDescr' => 'eth0')->ifSpeed;

B<WARNING>: This method assumes the programmer is looking for something that actually exists. In the above example, if an ifDescr with that value does not exist, the method will croak. So, if not certain, make sure that you handle that error (e.g. use eval)  

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


=head2 number_of_items

Returns the number of items present inside the ResultSet

=cut

sub number_of_items {
	return scalar @{$_[0]->varbinds};
}

=head2 is_empty

Reveals whether the ResultSet is empty or not.

=cut

sub is_empty {
	return ($_[0]->number_of_items == 0);
}


=head2 dot

The dot method overloads the '.' operator, returns L<SNMP::Class::Varbind>. Use it to get a single L<SNMP::Class::Varbind> out of a ResultSet as a final instance filter. For example, if $rs contains ifSpeed.1, ifSpeed.2 and ifSpeed.3, then this call: 

 $rs.3 
 
returns the ifSpeed.3 L<SNMP::Class::Varbind>.

B<Please note that this method does not return a ResultSet like the instance method, but a Varbind which should be the sole member of the ResultSet having that instance. If the ResultSet has more than one Varbinds with the requested instance and the dot operator is used, a warning will be issued, and only the first matching Varbind will be returned> 

=cut
 
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

=head2 item

Returns the item of the ResultSet with index same as the first argument. No argument yields the first item (index 0) in the ResultSet.

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
sub plus {
	defined(my $self = shift(@_)) or croak "Incorrect call to plus";
	my $item = shift(@_) or croak "Argument to add(+) missing";

	#check that this object is an SNMP::Class::Varbind
	confess "item to add is not an SNMP::Class::ResultSet!" unless (ref($item)&&(eval $item->isa("SNMP::Class::ResultSet")));

	my $ret = SNMP::Class::ResultSet->new();

	map { $ret->push($_) } (@{$self->varbinds});
	map { $ret->push($_) } (@{$item->varbinds});

	return $ret;
}

#append act on $self
sub append { 
	defined(my $self = shift(@_)) or croak "Incorrect call to append";
	my $item = shift(@_) or croak "Argument to append missing";
	#check that this object is an SNMP::Class::Varbind
	confess "item to add is not an SNMP::Class::ResultSet!" unless (ref($item)&&(eval $item->isa("SNMP::Class::ResultSet")));
	map { $self->push($_) } (@{$item->varbinds});
	return;
}

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


our $AUTOLOAD;

sub AUTOLOAD {
	defined(my $self = shift(@_)) or confess("Incorrect call to AUTOMETHOD");
	####DEBUG $AUTOLOAD;

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
		$logger->debug("ResultSet: $subname seems like a valid OID ");	
		DEBUG "Returning the resultset";
		return $self->filter_label($subname);

	}
	$logger->logconfess("I cannot match $subname with anything");
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

Please report any bugs or feature requests to
C<bug-snmp-class-resultset at rt.cpan.org>, or through the web interface at
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

=head1 COPYRIGHT & LICENSE

Copyright 2007 Athanasios Douitsis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::Class::ResultSet
