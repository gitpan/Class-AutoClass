package GrandChild;

use strict;
use Class::AutoClass;
use Parent;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA = qw(Child);

@AUTO_ATTRIBUTES=qw();
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
%DEFAULTS=(a=>'grandchild');
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}

1;
