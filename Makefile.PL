use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Class::AutoClass',
    'VERSION_FROM'	=> 'lib/Class/AutoClass.pm', # finds $VERSION
    'PREREQ_PM'		=> {Clone => 0.15,
                            Class::WeakSingleton => 1.03,
			    Data::Dumper => 2.121,
			    Storable => 2.08
			   }, # e.g., Module::Name => 1.1
);
