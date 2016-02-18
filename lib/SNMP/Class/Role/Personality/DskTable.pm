package SNMP::Class::Role::Personality::DskTable;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use Moose::Util qw/find_meta does_role search_class_by_role/;

use Moose::Role;

our $id = 'DskTable';
our $description = 'can report the usage on its disks';

our @required_oids = qw(dskTable);

our @dependencies= qw(SNMP::Class::Role::Personality::SNMP_Agent);

sub predicate {
	does_role($_[0] , 'SNMP::Class::Role::Personality::SNMP_Agent') 
	&& 
	$_[0]->contains_label('dskPath')
	&& 
	$_[0]->contains_label('dskDevice')
	&& 
	$_[0]->contains_label('dskTotalLow')
	&& 
	$_[0]->contains_label('dskAvailLow')
	&& 
	$_[0]->contains_label('dskUsedLow')
	&& 
	$_[0]->contains_label('dskTotalHigh')
	&& 
	$_[0]->contains_label('dskAvailHigh')
	&& 
	$_[0]->contains_label('dskUsedHigh')
	&& 
	$_[0]->contains_label('dskPercent')
	&& 
	$_[0]->contains_label('dskPercentNode')
}

sub get_facts {
	defined( my $s = shift( @_ ) ) or confess 'incorrect call';
	$s->dskPath->map(sub {
		SNMP::Class::Fact->new(
			type => 'disk_usage',
			slots => {
				system		=> $s->sysname,
				engine_id	=> $s->engine_id,
				path		=> $_->value,
				device		=> $s->dskDevice( $_->get_instance_oid )->value,
				percent		=> $s->dskPercent( $_->get_instance_oid )->value,
				inodes_percent	=> $s->dskPercentNode( $_->get_instance_oid )->value,
				# if the following is run in a 32-bit machine, it will yield floats.
				# fortunately Perl will autoconvert integers to floats seamlessly
				total		=> 2**32 * $s->dskTotalHigh( $_->get_instance_oid )->value + $s->dskTotalLow( $_->get_instance_oid )->value,
				used		=> 2**32 * $s->dskUsedHigh( $_->get_instance_oid )->value + $s->dskUsedLow( $_->get_instance_oid )->value,
				available	=> 2**32 * $s->dskAvailHigh( $_->get_instance_oid )->value + $s->dskAvailLow( $_->get_instance_oid )->value,
			},
		)
	});
}



#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Role::Personality module is actually loaded
INIT {
	SNMP::Class::Role::Personality::register_plugin( __PACKAGE__ );
	DEBUG __PACKAGE__.' personality activated';
}

1;
