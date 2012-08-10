package SNMP::Class::Role::Personality::Interfaces;

use Data::Printer;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'SysObjectID';
our $description = 'can identify its model and vendor';

our @required_oids = qw(ifIndex ifDescr ifType ifMtu ifSpeed ifPhysAddress ifAdminStatus ifOperStatus ifName ifAlias ipForwarding);

sub get_facts {

	defined( my $self = shift( @_ ) ) or confess 'incorrect call';

	$self->ifIndex->map(sub {
		my %data = (
			system => $self->sysname,
			engine_id => $self->engine_id,
			index => $_->value,
			description => get_ifunique($self,$_->value),
			type => $self->ifType($_->value)->value,
			mtu => ($self->has_exact('ifMtu',$_->get_instance_oid))? $self->ifMtu($_->value)->value : 0,
			speed => $self->ifSpeed($_->value)->value,
			physical_address => join(':',(map { sprintf "%02X",hex $_} (split ':',$self->ifPhysAddress($_->value)->value))),
			admin_status => $self->ifAdminStatus($_->value)->value,
			oper_status => $self->ifOperStatus($_->value)->value,
		);
		$data{name} = $self->ifName($_->value)->value if $self->contains_label('ifName');
		$data{alias} = $self->ifAlias($_->value)->value if $self->contains_label('ifAlias');

		SNMP::Class::Fact->new(type=>'interface',slots=>\%data);
	})

}

sub get_ifunique {
	defined( my $s = shift(@_) ) or confess 'incorrect call'; #session	
	defined( my $i = shift(@_) ) or confess 'incorrect call'; #instance oid object
	my @ret;
	push @ret,$s->ifDescr($i)->value;
	push @ret,$s->ifName($i)->value if ($s->has_exact('ifName',$i) && ($s->ifName($i)->value ne $s->ifDescr($i)->value));
	push @ret,$s->ifAlias($i)->value if ($s->has_exact('ifAlias',$i) && ($s->ifAlias($i)->value ne ''));
	my $ret = join('-',@ret);
	$ret =~ s/\s+$//g;
	return $ret;
}



sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::SNMP_Agent') 
	&& 
	$_[0]->contains_label('ifIndex')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
