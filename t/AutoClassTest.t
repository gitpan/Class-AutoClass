use lib 't/';
use Test::More qw/no_plan/;
use Class::AutoClass;
use strict;

my (%new_called, %init_called);

# setup
my $reference_object = Class::AutoClass->new();


# test isa
is(ref($reference_object), "Class::AutoClass");

# the following tests have been retro-fitted (written after the class),
# so they are far from comprehensive. Please feel encouraged to add to them

# test that object initialization is handled correctly with simple inheritance
# only the base class external constructor should be called
%new_called = ();
Class::testPackage2->new();
is($new_called{'Class::testPackage2'}, undef, "no constructor called for internal classes");
is($new_called{'Class::testPackage1'}, undef, "no constructor called for internal classes");


# test that object initialization is handled correctly in the presence of multiple inheritance
%new_called = ();
Class::testPackage6->new();
is($new_called{'Class::testPackage3'}, undef, "super external class constructor not called");
is($new_called{'Class::testPackage4'}, undef, "super external class constructor not called");
is($new_called{'Class::testPackage5'}, 1, "first seen external constructor called");

%init_called = ();
Class::testPackage2->new();
is($init_called{'Class::testPackage2'}, 1, "testing for correct internal and external class status");
is($init_called{'Class::testPackage1'}, 1);
Class::testPackage6->new();
is($init_called{'Class::testPackage6'}, 1);
is($init_called{'Class::testPackage5'}, undef);
is($init_called{'Class::testPackage4'}, undef);
is($init_called{'Class::testPackage3'}, undef);


# test AUTO_ATTRIBUTES with setter initialization
my $object = Class::testPackage6->new();
is($object->first,undef,"test that AUTO_ATTRIBUTES initially undef");
is($object->last,undef);
is($object->sex,undef);
is($object->friends,undef);
$object->first("rock");
is($object->first,"rock","test populating AUTO_ATTRIBUTES by directly calling method with an arg");
$object->sex(["male", "female", "asexual"]);
is($object->sex->[2],"asexual","test populating AUTO_ATTRIBUTES by directly calling method with annon array arg");
$object->set("last","candy");
is($object->_is_positional,1,"_is_positional routine checks out");
is($object->last,"candy",'test set() method with single attribute using positional notation');
$object->set(-last=>"lobster");
is($object->last,"lobster",'test set() method with single attribute using -key=>value notation');
$object->set({-first=>"red",-last=>"riding hood"});
is($object->get('first'),'red','test get() method');
is($object->get('last'),'riding hood');
my $args = { first=>'Mr.',
             last=>'Ed', 
             sex=>'male', 
             friends=>["trigger", "sea biscuit"] 
           };
$object->set_attributes([qw(first last sex friends)],$args);
is($object->get('first'),'Mr.');
is($object->get('last'),'Ed');
is($object->get('friends')->[1], 'sea biscuit');
eval{ $object->something("else") };
ok($@ =~ /Can\'t locate object method/, "testing that methods are not created for non-AUTO_ATTRIBUTES");

# test AUTO_ATTRIBUTES with constructor initialization
$object = Class::testPackage6->new(first=>'Popeye', last=>'Sailor', sex=>'male', friends=>'olive oil');
is($object->first,"Popeye","test that auto generated method is populated correctly with constructor initialization");
is($object->last,"Sailor");
is($object->sex,"male");
is($object->friends,"olive oil");

# test AUTO_ATTRIBUTES with init initialization
$object = Class::testPackage6->new();
my $args = { first=>'Popeye',
             last=>'Sailor', 
             sex=>'male', 
             friends=>["olive oil", "whimpy"]};
$object->_init($object,$args);
is($object->first,"Popeye","test that auto generated method is populated correctly with _init initialization");
is($object->last,"Sailor");
is($object->sex,"male");
is($object->friends->[0],"olive oil", "test AUTO_ATTRIBUTES with annon array");

# test OTHER_ATTRIBUTES
$object = Class::testPackage6->new();
ok( $object->age() =~/NOT YET IMPLEMENTED/, "test OTHER_ATTRIBUTES without initialization");
my $args = { age=>'10' };
$object->_init($object,$args);
is($object->age(),'10',"tesing OTHER_ATTRIBUTES initialized with _init");

# test SYNONYMS
$object = Class::testPackage6->new();
my $args = { first=>'James',
             last=>'Bond', 
             sex=>'lots', 
             friends=>"too many to mention"};
$object->_init($object,$args);
is($object->get('sex'),'lots',"checking synonyms");
is($object->get('gender'),'lots');

#---------------------------------------------------------------------------------------------------
# internal test packages
#---------------------------------------------------------------------------------------------------
package Class::testPackage1;
 use base qw(Class::AutoClass);
 use vars qw($package);
 BEGIN{ $package = __PACKAGE__; }
 
 sub new(){
   my $class = shift;
   my $class = ref($class) || $class;
   my $self = {};
   $new_called{$package}++;
   bless $self, $class;
 }
 
 sub _init_self {
   my($self,$class,$args)=@_;
   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
   $init_called{$package}++;
 }
1;

package Class::testPackage2;
 use base qw(Class::AutoClass Class::testPackage1);
 use vars qw($package);
 BEGIN{ $package = __PACKAGE__; }
 
 sub _init_self {
   my($self,$class,$args)=@_;
   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
   $init_called{$package}++;
 }
1;


package Class::testPackage3;
 use vars qw($package);
 BEGIN{ $package = __PACKAGE__; }
  
 sub new(){
   my $class = shift;
   my $class = ref($class) || $class;
   my $self = {};
   $new_called{$package}++;
   bless $self, $class;
 }
 sub _init_self {
   my($self,$class,$args)=@_;
   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
   $init_called{$package}++;
 }
1;

package Class::testPackage4;
 use base qw(Class::testPackage3);
 use vars qw($package);
 BEGIN{ $package = __PACKAGE__; }
 
 sub new(){
   my $class = shift;
   my $class = ref($class) || $class;
   my $self = {};
   $new_called{$package}++;
   bless $self, $class;
 }
 sub _init_self {
   my($self,$class,$args)=@_;
   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
   $init_called{$package}++;
 }
1;

package Class::testPackage5;
 use base qw(Class::testPackage3 Class::testPackage4);
 use vars qw($package);
 BEGIN{ $package = __PACKAGE__; }
 
 sub new(){
   my $class = shift;
   my $class = ref($class) || $class;
   my $self = {};
   $new_called{$package}++;
   bless $self, $class;
 }
 sub _init_self {
   my($self,$class,$args)=@_;
   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
   $init_called{$package}++;
 }
1;

package Class::testPackage6;
 use base qw(Class::AutoClass Class::testPackage5);
 use vars qw($package @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS $CASE $age);
 
   BEGIN {
   	$package = __PACKAGE__;
    @AUTO_ATTRIBUTES=qw(first last friends sex);
    @OTHER_ATTRIBUTES=qw(age);
    %SYNONYMS=(gender=>'sex');
    $CASE='upper';
    Class::AutoClass::declare(__PACKAGE__);
  }

 sub age {
  my $self = shift;
  $age = $age || shift;
  return $age ? $age : "NOT YET IMPLEMENTED";
 }
 
 sub _init_self {
   my($self,$class,$args)=@_;
   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
   $init_called{$package}++;
 }
1;
