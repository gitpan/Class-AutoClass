package testPackage1;
use base qw(Class::AutoClass);
 
 sub new(){
   my $class = shift;
   $class = ref($class) || $class;
   my $self = {};
   $self->{constructor_history} .= __PACKAGE__;
   bless $self, $class;
 }
 
 sub _init_self {
   my($self,$class,$args)=@_;
   $self->{init_self_history} .= __PACKAGE__;
   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
 }
1;