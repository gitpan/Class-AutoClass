package testPackage6;
use base qw(Class::AutoClass testPackage5);
use vars qw($package @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS $CASE $age);
 
@AUTO_ATTRIBUTES=qw(first last friends sex);
@OTHER_ATTRIBUTES=qw(age);
%SYNONYMS=(gender=>'sex');
$CASE='upper';
Class::AutoClass::declare(__PACKAGE__);

 sub age {
  my $self = shift;
  $age = $age || shift;
  return $age ? $age : "NOT YET IMPLEMENTED";
 }
 
 sub _init_self {
   my($self,$class,$args)=@_;
   $self->{init_self_history} .= __PACKAGE__;
   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
 }
1;