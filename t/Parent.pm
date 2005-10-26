package Parent;
use strict;
use Class::AutoClass;
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(Class::AutoClass);
@AUTO_ATTRIBUTES  = qw(name sex address dob a);
@OTHER_ATTRIBUTES = qw(age);
@CLASS_ATTRIBUTES = qw(species population class_hash);
%SYNONYMS         = ( gender => 'sex', whatisya => 'sex' );
%DEFAULTS = (
              a          => 'parent',
              species    => 'Dipodomys gravipes',
              population => 42,
              class_hash => {
                              this  => 'that',
                              these => 'those',
              }
);
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
 my ( $self, $class, $args ) = @_;
 return
   unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this

}
sub age { print "Calculate age from dob. NOT YET IMPLEMENTED\n"; undef }
1;
