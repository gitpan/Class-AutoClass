package testPackage3;
use base qw(Class::AutoClass);
  
sub _init_self {
   my($self,$class,$args)=@_;
   $self->{init_self_history} .= __PACKAGE__;
   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
 }
1;