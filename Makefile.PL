use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Class::AutoClass',
    'VERSION_FROM'	=> 'lib/Class/AutoClass.pm', # finds $VERSION
    'PREREQ_PM'		=> { Data::Dumper => 2.12,
			    Storable => '2.08',
			    IO::Scalar => '2.104',
			    Test::More => '0.45'
			   }, 
);
