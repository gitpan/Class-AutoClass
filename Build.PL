use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass
  (
   class => 'My::Builder',
   code => q{
       sub harness_switches { # turn off -w in Test::Harness
         shift->{properties}{debugger} ? qw(-d) : qw(-X);
       }
     },
  );

my $builder = $class->new
  (module_name         => 'Class::AutoClass',
   license             => 'perl',
   dist_author         => q{Nat Goodman <natg@shore.net>},
   configure_requires=>{'Module::Build' => 0.4007,
		       },
   build_requires =>   {'Carp' => 1.20,
			'Hash::AutoHash::Args' => 1.16,
			'IO::Scalar' => 2.110,
			'Module::Build' => 0.4007,
			'Scalar::Util' => 1.23,
			'Storable' => 2.30,
			'Test::Deep' => 0.11,
			'Test::More' => 0.98,
			'Test::Pod' => 1.48,
			'Test::Pod::Content' => '0.0.6',
		       },
   requires =>         {'Cwd' => 3.40,
			'Hash::AutoHash' => 1.16,
			'Hash::AutoHash::Args' => 1.16,
			'List::MoreUtils' => 0.33,
			'Tie::ToObject' => 0.03,
			'IO::Scalar' => 2.110,
			'XSLoader' => 0.15,
		       },
    add_to_cleanup      => [ 'Class-AutoClass-*' ],
    create_makefile_pl => 'small',
);

$builder->create_build_script();

