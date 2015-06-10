use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SNMP::Class',
    license             => 'perl',
    dist_author         => 'Athanasios Douitsis <aduitsis@cpan.org>',
    dist_version_from   => 'lib/SNMP/Class.pm',
    build_requires => {
        'Test::More' => 0,
	'Module::Build' => '0',
    },
    requires => {
	'Moose'		=> 0,
	'SNMP'       	=> 0,
	'NetSNMP::OID' 	=> 0,
	'Log::Log4perl' => 0,
	'Data::Printer' => 0,
	'version'	=> 0,
	'YAML'		=> 0,
    },
    recommends => {
	'Time::HiRes'	=> 0,
    },
    add_to_cleanup      => [ 'SNMP::Class-*' ],
);

$builder->create_build_script();
