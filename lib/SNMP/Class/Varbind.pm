package SNMP::Class::Varbind;

our $VERSION = '0.15';


use Moose;
use Moose::Util::TypeConstraints;

use SNMP;
use Carp;
use Log::Log4perl qw(:easy);
use Data::Dumper;
use SNMP::Class::Varbind::SysUpTime;

my $have_time_hires;
eval { require Time::HiRes };
if($@) {
	warn "Time::HiRes not installed -- you only get the low granularity built in time function.";
} 
else { 
	$have_time_hires = 1;
	DEBUG "Successfully loaded Time::HiRes" ;
}

extends 'SNMP::Class::OID';

has 'raw_value' => (
	is => 'ro', #object is immutable
	isa => 'Value | Undef', 
	required => 0,
	init_arg => 'value',
);

has 'type' => (
	is => 'ro',
	isa => 'Value | Undef',
	required => 0,
);

has 'time' => (
	is => 'ro',
	isa => 'Num',
	required => 0,
	default => sub { return ($have_time_hires)? Time::HiRes::time : time; },
);
	
has 'no_such_object' => (
	is => 'ro',
	isa => 'Bool',
	required => 0,
	default => 0,
);




use overload 
	'""' => \&value,
	fallback => 1
;


my @plugins;

sub BUILDARGS {
	#DEBUG Dumper(@_);
	defined( my $class = shift ) or confess "missing class argument";
	my %arg_h = (@_);

	if(defined($arg_h{varbind})) {
		my $varbind = $arg_h{varbind};
		eval { $varbind->isa('SNMP::Varbind') };
		croak "new was called with a varbind that was not an SNMP::Varbind." if $@;

		my $part1 = SNMP::Class::OID->new($varbind->[0]);
		my $part2 = ((!exists($varbind->[1]))||($varbind->[1] eq ''))? SNMP::Class::OID->new('0.0') : SNMP::Class::OID->new($varbind->[1]);
		$arg_h{oid} = $part1 . $part2;
		croak "Internal error. Self is not an SNMP::Class::OID object!" 
			unless ($arg_h{oid}->isa("SNMP::Class::OID"));
		$arg_h{type} = $varbind->[3];
		$arg_h{value} = $varbind->[2];
	}

	return \%arg_h;
}

sub BUILD {
	defined( my $self = shift ) or confess "missing argument";
	for my $plugin (@plugins) {
		no strict 'refs';
		&{"${plugin}::adopt"}($self);
	}
};

		
sub value {
	confess 'You cannot ask for the value of an object that does not exist' if $_[0]->no_such_object;
	return $_[0]->raw_value;
}

sub to_varbind_string {
	if($_[0]->no_such_object) {
		return $_[0]->SUPER::to_string.'(no such object)';
	}
	elsif(defined($_[0]->value)) {
		return $_[0]->SUPER::to_string.'='.$_[0]->value;
	} 
	else {
		return $_[0]->SUPER::to_string.'=undef';	
	}
}


=head2 new(oid=>$oid,type=>$type,value=>$value)


=cut
	

#You get an SNMP::Varbind. Warning, you only get the correct oid, but you shouldn't get types,values,etc.s 
sub generate_netsnmpvarbind {
	#maybe 'or' instead of || ? 
	return SNMP::Varbind->new([$_[0]->numeric]) || croak "Cannot invoke SNMP::Varbind::new method with argument".$_[0]->numeric." \n";	
}


#this is a class method. Other modules wishing to register themselves as varbind handlers must use it. 
sub register_plugin {
	push @plugins,($_[0]);
}
	
	


=head1 AUTHOR

Athanasios Douitsis, C<< <aduitsis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-class-varbind at rt.cpan.org>, or through the web interface at
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

no Moose;

__PACKAGE__->meta->make_immutable;

1; # End of SNMP::Class::Varbind
