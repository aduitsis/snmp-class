package SNMP::Class::Role::Personality::Dot1dTpFdbAddress;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'Dot1dTpFdbAddress';
our $description = 'has a transparent bridge fdb';

our @required_oids = qw( dot1dTpFdbAddress dot1dTpFdbPort dot1dTpFdbStatus dot1dBasePortIfIndex );

sub get_facts {

	defined( my $s = shift( @_ ) ) or confess 'incorrect call';

	grep { defined $_ } ( $s->dot1dTpFdbAddress->map(sub {

		if (! $s->has_exact('dot1dTpFdbPort',$_->get_instance_oid) ) {
			WARN 'no dot1dTpFdbPort.'.$_->get_instance_oid->numeric."\n";
			return;
		}
		if (! $s->has_exact('dot1dTpFdbStatus',$_->get_instance_oid) ) {
			WARN 'warning: no dot1dTpFdbStatus.'.$_->get_instance_oid->numeric."\n";
			return;
		}


		my $port = $s->dot1dTpFdbPort($_->get_instance_oid)->value;
		return if ($port == 0); #if the port=0, we don't have anything else to do

		my $status = $s->dot1dTpFdbStatus($_->get_instance_oid)->value;
		if ($status eq 'self') { #stupid ciscos do not report a correct port number for ports that are 'self'
			SNMP::Class::Fact->new(
				type => 'dot1d_fdb',
				slots => {
					mac_address => $_->value,
					status => $status,
					system => $s->sysname,
					engine_id => $s->engine_id,
				},
			);
		}
		else {
			if (! $s->has_exact('dot1dBasePortIfIndex',$port) ) {
				WARN 'no dot1dBasePortIfIndex'.$_->get_instance_oid->numeric."\n";
				return;
			}
			SNMP::Class::Fact->new(
				type => 'dot1d_fdb',
				slots => {
					interface => $s->get_ifunique($s->dot1dBasePortIfIndex($port)->value),
					mac_address => $_->value,
					status => $status,
					system => $s->sysname,
					engine_id => $s->engine_id,
				}
			);
		}
	}));

}


sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::Interfaces') 
	&& 
	$_[0]->contains_label('dot1dTpFdbAddress')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
