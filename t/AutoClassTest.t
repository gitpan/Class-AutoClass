use lib qw(../lib t/);
use Test::More qw/no_plan/;
use Class::AutoClass;
use testPackage1;
use testPackage2;
use testPackage3;
use testPackage4;
use testPackage5;
use testPackage6;
use strict;
use Data::Dumper; # only for debugging

use vars qw(%init_called);
my ($args, @c_history, @is_history);

# setup
my $reference_object = Class::AutoClass->new();

# test isa
is(ref($reference_object), "Class::AutoClass");

## test inventory:
  ## testPackage1 - isa AutoClass, has constructor, has _init_self
  ## testPackage2 - isa AutoClass, isa testPackage1, has _init_self
  ## testPackage3 - isa AutoClass, has _init_self
  ## testPackage4 - isa testPackage3, has constructor, has _init_self
  ## testPackage5 - isa testPackage3,testPackage4, has constructor, has _init_self
  ## testPackage6 - isa AutoClass,testPackage5, has _init_self

# test that object initialization is handled correctly with simple inheritance.

# t1 - has constructor, _init_self not called by AutoClass
my $t1=testPackage1->new;
is($t1->{constructor_history}, 'testPackage1');
is($t1->{init_self_history}, undef);

# t2 - both t1 and t2's _init_self methods called in correct order, since both ISA AutoClass
my $t2=testPackage2->new;
is($t2->{init_self_history}, 'testPackage1testPackage2'); # init path is concatinated
is($t2->{constructor_history}, undef);

# t3 - no constructor (AutoClass provides one), _init_self called
my $t3=testPackage3->new;
is($t3->{constructor_history}, undef);
is($t3->{init_self_history}, 'testPackage3');

# t4 - has constructor (AutoClass provides one), t4 _init_self not called (t4 not ISA AutoClass)
my $t4=testPackage4->new();
is($t3->{constructor_history}, undef);
is($t3->{init_self_history}, 'testPackage3');
is($t4->{constructor_history}, 'testPackage4');
is($t4->{init_self_history}, undef);

# t5 - has constructor, _init_self not called by AutoClass but subclasses have _init_self called in correct order
my $t5=testPackage5->new;
is($t3->{constructor_history}, undef);
is($t3->{init_self_history}, 'testPackage3');
is($t4->{constructor_history}, 'testPackage4');
is($t4->{init_self_history}, undef);
is($t5->{constructor_history},'testPackage5');
is($t5->{init_self_history}, undef);

# t6 - t4,t5's constructor called, all subclasses have _init_self called in correct order (note that t4,t5's _init_self 
# is called by it's super class - t6, who ISA AutoClass)
my $t6=testPackage6->new;
is($t3->{constructor_history}, undef);
is($t3->{init_self_history}, 'testPackage3');
is($t4->{constructor_history}, 'testPackage4');
is($t4->{init_self_history}, undef);
is($t5->{constructor_history},'testPackage5');
is($t5->{init_self_history}, undef);
is($t6->{constructor_history},undef);
is($t6->{init_self_history}, 'testPackage3testPackage4testPackage5testPackage6');

# test AUTO_ATTRIBUTES with setter initialization
is($t6->first,undef,"test that AUTO_ATTRIBUTES initially undef");
is($t6->last,undef);
is($t6->sex,undef);
is($t6->friends,undef);
# test populating AUTO_ATTRIBUTES by directly calling method with an arg
$t6->first("rock");
is($t6->first,"rock",'test simple setting');
# test populating AUTO_ATTRIBUTES by directly calling method with annon array arg
$t6->sex(["male", "female", "asexual"]);
is($t6->sex->[2],"asexual");
# test set()
$t6->set("first","candy");
is($t6->first,"candy", 'test set() method');
$t6->set(last=>'lobster');
is($t6->last,"lobster");
$t6->set(-first=>"red",-last=>"riding hood");
is($t6->get('first'),'red','test get() method');
$t6->set({-first=>"red",-last=>"riding hood"});
is($t6->get('first'),'red','test get() method');
is($t6->get('last'),'riding hood');
$args = { first=>'Mr.',
          last=>'Ed', 
          sex=>'male', 
          friends=>["trigger", "sea biscuit"] 
        };
$t6->set_attributes([qw(first last sex friends)],$args);
is($t6->get('first'),'Mr.');
is($t6->get('last'),'Ed');
is($t6->get('friends')->[1], 'sea biscuit');
eval{ $t6->something("else") };
ok($@ =~ q/Can't locate object method/, "testing that methods are not created for non-AUTO_ATTRIBUTES");
# test AUTO_ATTRIBUTES with constructor initialization
$t6 = testPackage6->new(first=>'Popeye', last=>'Sailor', sex=>'male', friends=>'olive oil');
is($t6->first,"Popeye","test that auto generated method is populated correctly with constructor initialization");
is($t6->last,"Sailor");
is($t6->sex,"male");
is($t6->friends,"olive oil");

# test AUTO_ATTRIBUTES with init initialization
$t6 = testPackage6->new();
$args = { first=>'Popeye',
          last=>'Sailor', 
          sex=>'male', 
          friends=>["olive oil", "whimpy"]
        };
$t6->_init($t6,$args);
is($t6->first,"Popeye","test that auto generated method is populated correctly with _init initialization");
is($t6->last,"Sailor");
is($t6->sex,"male");
is($t6->friends->[0],"olive oil", "test AUTO_ATTRIBUTES with annon array");

# test OTHER_ATTRIBUTES
$t6 = testPackage6->new();
ok( $t6->age() =~/NOT YET IMPLEMENTED/, "test OTHER_ATTRIBUTES without initialization");
$args = { age=>'10' };
$t6->_init($t6,$args);
is($t6->age(),'10',"tesing OTHER_ATTRIBUTES initialized with _init");

# test SYNONYMS
$t6 = testPackage6->new();
$args = { first=>'James',
             last=>'Bond', 
             sex=>'lots', 
             friends=>"too many to mention"};
$t6->_init($t6,$args);
is($t6->get('sex'),'lots',"checking synonyms");
is($t6->get('gender'),'lots');