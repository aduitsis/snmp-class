package SNMP::Class::PluggableImplementations;

use Carp;
use Data::Dumper;
use Module::Find;
use Module::Load;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

sub load_plugins {
	# find all the modules under $_[0]
	my @plugins = usesub $_[0] ; 

	$logger->debug('Found plugins: '.join(',',@plugins));

	no strict 'refs';
	# sort the modules, take the one with the highest priority and that works
	for my $plugin ( sort { &{ $a.'::priority' } <=> &{ $b.'::priority' } } @plugins ) {
		$logger->debug('Trying '.$plugin);
		if ( &{ $plugin.'::works' } ) {
			$logger->info($plugin.' selected');
			return $plugin
		}
	}
	use strict 'refs';
	confess 'Cannot load any '.$_[0].' implementation';
}

sub import { 
	my ($package, $filename, $line) = caller;
	my $plugin = load_plugins( $package ) ;

	no strict 'refs';
	Sub::Install::install_sub({
		code => sub { 
			#### print STDERR "plugin is $plugin\n";
			# TODO I must find a better way to say the following: 
			&{ $plugin.'::meta' }( $plugin );
		} ,
		into => $package,
		as   => 'plugin_meta',
	});
}

# ---- everything above happens when use SNMP::Class::PluggableImplementations is called ----



1;
