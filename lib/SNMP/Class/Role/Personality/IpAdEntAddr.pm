package SNMP::Class::Role::Personality::IpAdEntAddr;

use Data::Printer;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'IpAdEntAddr';
our $description = 'has IPv4 interfaces';

our @required_oids = qw( ipAddrTable );

sub get_facts {
	defined( my $s = shift( @_ ) ) or confess 'incorrect call';
	$s->ipAdEntAddr->map(sub {
		my $ipv4 = $_->value;
		my $mask = $s->ipAdEntNetMask($_->get_instance_oid)->value;
		#from perlmonks http://www.perlmonks.org/?node_id=786521
		my $ipv4_long = unpack 'N', pack 'C4', split '\.', $ipv4;
		my $mask_long = unpack 'N', pack 'C4', split '\.', $mask;
		my $network_long = $ipv4_long & $mask_long;
		my $network_addr = join '.',unpack 'C4', pack 'N',$network_long;
		my $length = 0;
		map { $length += $_ } split '',unpack 'B*', pack 'N',$mask_long;
		my $net = $network_addr.'/'.$length;

		SNMP::Class::Fact->new(
			type => 'ipv4',
			slots => {
				ipv4 => $_->value,
				mask => $mask,
				interface =>  $s->get_ifunique($s->ipAdEntIfIndex($_->get_instance_oid)->value),
				net => $net,
				system => $s->sysname,
				engine_id => $s->engine_id,
			},
		);
	});
}


sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::Interfaces') 
	&& 
	$_[0]->contains_label('ipAdEntAddr')
}

#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
