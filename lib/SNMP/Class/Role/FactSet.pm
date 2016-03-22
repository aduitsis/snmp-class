package SNMP::Class::Role::FactSet;

use v5.14;
use strict;
use warnings;

use Log::Log4perl qw(:easy);
my $logger = get_logger();
use Scalar::Util;
use List::Util qw(none any);
use SNMP::Class::Fact; 
use Data::Printer;
use Moose::Role;

requires qw( push grep map facts item count ) ;

=head2 each( sub { ... } )

Iterates over the facts of the factset, executing the subroutine given as the first
argument. The fact for each iteration is in $_;

=cut

sub each {
	my $self = shift // die 'incorrect call';
	my $code = shift // die 'incorrect call';
        my %options = @_;
	my %filter;
	# if the value is a scalar return [the scalar], otherwise return the arrayref verbatim
	for my $i (qw(include_types exclude_types)){
        	if ( defined( $options{ $i } ) ){
                	$filter{$i} = defined(Scalar::Util::reftype( $options{ $i } ))? \@{ $options{ $i } } : [ $options{ $i } ]
        	}
		else {
			$filter{$i} = []
		}
	}
	my @items = ( 
		#if include_types is a thing, keep only those facts that have type in include_types, otherwise return true
		grep { my $item = $_ ; @{ $filter{ include_types } }? any { $item->type eq $_ }  @{ $filter{ include_types } } : 1 } 
			# sort the iteration by type alphabetically
			sort { $a->type cmp $b->type } 
				# keep only facts whose type is not in exclude_types arrayref
				grep { my $item = $_ ; none { $item->type eq $_ } @{ $filter{ exclude_types } } }
					#iterate over facts
					@{ $self->facts } 
	);
	for (@items) {
		$code->();
	}
}

=head2 typeslots($fact_set,$type,$slot)

Searches $fact_set for facts of type $type having a slot $slot, and returns the values of those slots in an array.

=cut

sub typeslots {
	my $self = shift // die 'incorrect call';
	my $type = shift // die 'incorrect call';
	my $slot = shift // die 'incorrect call';
	map { $_->slots->{ $slot } } 
		@{ $self->grep( sub { $_->matches( type => $type ) } )->facts  }
}

sub typeslot {
	my $self = shift // die 'incorrect call';
	my $type = shift // die 'incorrect call';
	my $slot = shift // die 'incorrect call';
	my @arr = $self->typeslots( $type, $slot );
	if ( ! @arr ) { 
		$logger->logconfess("There are no facts of type $type with slot of type $slot in the factset.")
	}
	return $arr[0]
}

sub string_each {
	my $self = shift // die 'incorrect call';
	my $code = shift // die 'missing coderef';
        my %options = @_;
	my %filter;
	for my $i (qw(exclude_slots)){
        	if ( defined( $options{ $i } ) ){
                	$filter{$i} = defined(Scalar::Util::reftype( $options{ $i } ))? \@{ $options{ $i } } : [ $options{ $i } ]
        	}
		else {
			$filter{$i} = []
		}
	}
	local $_ = '(deffacts factset_'.$self->unique_id.' "" ';
	$code->();
	$self->each(
		sub { 
			local $_ = '(' . $_->to_string( exclude => $filter{ exclude_slots } ) .')';
			$code->();
		},
		@_,
	);
	$_ = ')';
	$code->();
}

1;
