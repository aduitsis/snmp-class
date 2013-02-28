package SNMP::Class::Role::Personality;


=head1 NAME

SNMP::Class::Role::Personality - Personality framework for SNMP::Class

=head1 SYNOPSIS

=head 1 GENERAL

The SNMP::Class::Role::Personality role is applied to all SNMP::Class
objects. This means that SNMP::Class->new( ... ) will return an object
ready to use various personalities. Upon inception, the session object
does not have any specific personalities except this one. 

Each specific personality (SNMP::Class::Role::Personality::XXX) will
register itself with SNMP::Class::Role::Personality via a simple plugin
system, by invoking register_plugin() here. The @plugins array contains
all the available personalities. 

By calling apply_personalities() from SNMP::Class::Role::Personality,
the object ($_[0]) will be passed to the predicate() class method from
each personality. If predicate() returns true, the said personality is
applied to the object ($_->meta->apply( $_[0] )). 

Each personality has an after => 'trigger' method. The
SNMP::Class::Role::Personality::trigger is called after having applied
whatever personalities must be applied to the object. So the object can
do whatever initialization it needs to do with this poor man's BUILD
replacement. 

=cut

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use SNMP::Class::FactSet::Simple;

#use all the plugins here
use SNMP::Class::Role::Personality::SNMP_Agent;
use SNMP::Class::Role::Personality::SysObjectID;
use SNMP::Class::Role::Personality::Interfaces;
use SNMP::Class::Role::Personality::EntityPhysical;
use SNMP::Class::Role::Personality::CInetNetToMediaTable;
use SNMP::Class::Role::Personality::IpNetToMediaPhysAddress;
use SNMP::Class::Role::Personality::CdpCacheAddress;
use SNMP::Class::Role::Personality::IpForwarding;
use SNMP::Class::Role::Personality::Dot1dBridge;
use SNMP::Class::Role::Personality::PortTable;
use SNMP::Class::Role::Personality::Dot1dTpFdbAddress;
use SNMP::Class::Role::Personality::Dot1dStp;
use SNMP::Class::Role::Personality::IpAdEntAddr;
use SNMP::Class::Role::Personality::ManagementDomainName;
use SNMP::Class::Role::Personality::VtpVlanState;
use SNMP::Class::Role::Personality::VmVlan;

#import the utility module
use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

has 'fact_set' => (
	is => 'ro',
	isa => 'SNMP::Class::Role::FactSet',
	default => sub { SNMP::Class::FactSet::Simple->new() },
);

my @plugins;

sub register_plugin {
	push @plugins,$_[0]  
}

sub trigger {
	TRACE 'trigger';
	no strict 'refs';
	ROLE_LOOP: for my $role ( @plugins ) {
		if ( ( ! does_role( $_[0] , $role ) ) && &{ $role . '::predicate' }( $_[0] ) ) {
			DEBUG $role . ' can be applied to object';
			$role->meta->apply( $_[0] );
			DEBUG $role . ' is now applied to object';
			# ready everything
			eval { 
				$_[0]->fact_set->push( &{ $role . '::get_facts' }( $_[0] ) );
			};
			if($@) {
				WARN "module $role failed to calculate its facts. Skipping. Error was: $@";	
				next; 
			}
			
			#now apply role
			#p $_[0]->engine_id;
			#p $_[0]->sysname;
			#p $_[0]->engine_id;
			#p $_[0]->sysname;
			goto ROLE_LOOP; # we restart the loop because we applied a new role so
					# we must check everything from the start
		}	
		#&{$role.'::trigger_action'}($_[0],$role);
	}
	use strict 'refs';
}


sub calculate_personality_dependencies {
	my %personalities = map { $_ => 1 } @_;
	for my $personality ( %personalities ) { 
		no strict 'refs';
		my @dependencies = @{ $personality . '::dependencies' } ;
		use strict 'refs';
		for my $dependency ( @dependencies ) {
			if( ! exists( $personalities{ $dependency } ) ) {
				DEBUG "$personality requires that $dependency is also added";
				return calculate_personality_dependencies( $dependency , @_ );
			}
		}
	}
	return @_;
}

sub prime {
	my $self = shift // die 'incorrect call';
	my @personalities_requested = (@_)? @_ : @plugins;

	#if one is lazy, one will be bored to write SNMP::Class::Role::Personality::
	#in front of each personality
	@personalities_requested = map { (/::/)? $_ : __PACKAGE__ . '::'.$_  } @personalities_requested;
	
	DEBUG 'Personalities requested: '.join(',',@personalities_requested);

	my @personalities_required = calculate_personality_dependencies( @personalities_requested );

	DEBUG 'Personalities required: '.join(',',@personalities_required);

	for ( @personalities_required ) {
		no strict 'refs';

		###p $_,@{ $_ . '::required_oids' };
		if( @{ $_ . '::required_oids' } ) { 
			DEBUG 'Role '.$_.' says we should get '.join(',',@{ $_ . '::required_oids' }) 
		}
		else {
			DEBUG 'Role '.$_.' does not require us to get anything';
		}
		$self->add( @{ $_ . '::required_oids' } );
		use strict 'refs';
	}
	$self->trigger;
}


1;


