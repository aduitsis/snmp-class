package SNMP::Class::Varbind::DisplayHint;

use Moose::Role;
use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);


	
#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Varbind module is actually loaded
INIT {
	SNMP::Class::Varbind::register_plugin(__PACKAGE__);
	DEBUG __PACKAGE__." plugin activated";
}

sub matches {
	( $_[0]->has_label ) 
	&& 
	( defined(SNMP::Class::Utils::get_attr( $_[0]->get_label , 'hint' ))); 

	#DEBUG SNMP::Class::Utils::textual_convention_of( $_[0]->get_label );
	#DEBUG SNMP::Class::Utils::syntax_of( $_[0]->get_label );
	#DEBUG SNMP::Class::Utils::type_of( $_[0]->get_label );
}	

sub adopt {
	if(matches($_[0])) { 
		__PACKAGE__->meta->apply($_[0]);
		DEBUG "Applying role ".__PACKAGE__." to ".$_[0]->get_label;
	}
}

#this function should be able to parse displayhint specs per rfc.2579 par.3.1.
#returns a ref.to an array containing the parts of the hints
sub parse_display_hint {
	defined(my $hint = shift(@_) ) or croak 'missing argument';
	my $ret;
	my (@specs) = ( $hint =~ /((?:|\*)\d+[xdoat][^\d\*]{0,2})/g );
	for my $spec (@specs) {
		my ($rep,$len,$disp,$sep,$term) = ($spec =~ /(|\*)(\d+)([xdoat])([^\d\*]|)([^\d\*]|)/);
		push @{$ret},{spec=>$spec,rep=>$rep,len=>$len,disp=>$disp,sep=>$sep,term=>$term};
	}
	return $ret;
}
	
	
sub render_octet_str_with_display_hint {
	defined(my $specs = shift(@_) ) or croak 'missing argument';
	defined(my $octets = shift(@_) ) or croak 'missing argument';
	#part 1 - just unshift the first element from the $specs 
	defined(my $spec = shift @{$specs}) or confess 'specs should not be empty';

	#make sure that we never run out of specs 
	#(If additional octets remain in the value after interpreting
	#all the octet-format specifications, then the last octet-format
	#specification is re-interpreted to process the additional octets,
	#until no octets remain in the value.
	$specs = [ $spec ] if(! @{$specs});

	#also make sure that we still have octets to process - 
	#otherwise, let's just return the empty string
	if(! @{$octets} ) {
		return '';
	}
	
	#part 2 - how many octets do we need? 
	#'If the repeat indicator is not present, the repeat count is by default 1.'
	TRACE 'doing '.$spec->{spec};
	my $repetitions = 1;
	if($spec->{rep} eq '*') {
		defined(my $byte = shift @{$octets}) or confess 'no more bytes left on string';
		$repetitions = ord $byte; #an unsigned integer which may be zero
	}
	TRACE "doing $repetitions repetitions";
	my @str;#empty array to push the results from each application of the current pattern
	for my $i (1..$repetitions) { #if the repetitions is 0, the range operator will return the empty list
		TRACE "doing rep $i";
		#part 3 - apply the specification	
		my $bytes = '';
		my @bytes;
		for my $j (1..$spec->{len}) {
			my $byte = shift @{$octets};
			last unless defined($byte);#when there are no more items left in the octets array, we will get undef
			TRACE 'Got character '.ord($byte);
			push @bytes,(ord $byte); #since we were shifting from octets, we will be pushing to bytes to maintain the order
		}
		#part 4 - render the bytes using the disp
		if($spec->{disp} =~ /^[xdo]{1}$/) {
			confess 'cannot handle numeric values more than 32bits long' if ($spec->{len} > 4);
			#this is dirty...we need a 32bit 
			while(scalar(@bytes) != 4) { 
				unshift @bytes,0;#until the value is 4 bytes (32bit) long
			}
			my $s = unpack('N',pack('C4',@bytes)); 
			my $format = ($spec->{disp} eq 'x')? '%x' : ($spec->{disp} eq 'd')? '%d' : '%o';
			$s = sprintf($format,$s); #to weed out any remaining zeros in front
			TRACE "value is $s";
			push @str,$s;
		} 
		elsif($spec->{disp} eq 'a') {
			push @str,pack('C*',@bytes); #just copy @TODO maybe a shortcut in the future to make it faster?
		}
		elsif($spec->{disp} eq 't') {
			WARN 'Warning: UTF8 display-hint type not yet implemented properly';
			push @str,pack('U*',@bytes); 
		}
		else {
			confess 'Handling of spec '.$spec->{disp}.' is not implemented yet';
		}
		
	}
	my $str = join($spec->{sep},@str);
	TRACE "str is $str";
	if(@{$octets}) { #if we have more items in the array, we may as well use the separator and/or terminator
		my $append = ($spec->{term} ne '')? $spec->{term} : ($spec->{sep} ne '')? $spec->{sep} : '';
		return $str.$append.render_octet_str_with_display_hint($specs,$octets);
	}
	else {
		return $str;
	}
}

		

sub value {
	#### DEBUG 'raw value is '.join('.',unpack('C*',$_[0]->raw_value));
	my $hint = SNMP::Class::Utils::get_attr( $_[0]->get_label , 'hint' );
	if($_[0]->type eq 'OCTETSTR') {
		my @octets = split('',$_[0]->raw_value);
		####TRACE Dumper(\@octets);
		return render_octet_str_with_display_hint(parse_display_hint($hint),\@octets);
	}
	elsif($_[0]->type eq 'INTEGER') {
		return $_[0]->raw_value;
	}
	else {
		WARN 'cannot handle display hints for types other than octet string or integer. This type is '.$_[0]->type.' and the hint is '.$hint;
	}
		
}		
		

1;
