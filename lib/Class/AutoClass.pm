package Class::AutoClass;
use strict;
our $VERSION = '0.03';
use vars qw($AUTOCLASS $AUTODB @ISA %CACHE);
$AUTOCLASS=__PACKAGE__;
use Class::AutoClass::Root;
use Class::AutoClass::Args;
use Storable qw(dclone); ## TODO : need this anymore?
use Clone;
@ISA=qw(Class::AutoClass::Root);
use Data::Dumper; ## only for debugging

sub new {
  my($class,@args)=@_;
  $class=(ref $class)||$class;
  my $classes=$class->ANCESTORS;
  my $can_new=$class->CAN_NEW;
  if (!@$classes) {		# compute on the fly for backwards compatibility
    #  # enumerate internal super-classes and find a class to create object
    ($classes,$can_new)=_enumerate($class);
  }
  my $self=$can_new? $can_new->new(@args): {};
  bless $self,$class;		# Rebless what comes from new just in case 
  my $args=new Class::AutoClass::Args(@args);
  my $defaults=new Class::AutoClass::Args($args->defaults);
  # set arg defaults into args
  while(my($keyword,$value)=each %$defaults) {
    $args->{$keyword}=$value unless exists $args->{$keyword};
  }
  for my $class (@$classes) {
    $self->_init($class,$args,$defaults);
  }
  $self;
}

sub _init {
  my($self,$class,$args,$defaults)=@_;
  my %synonyms=SYNONYMS($class);
  my $attributes=[AUTO_ATTRIBUTES($class),OTHER_ATTRIBUTES($class),keys %synonyms];
  $self->set_class_defaults($attributes,$class,$args);
  $self->set_attributes($attributes,$args);
  my $init_self=$class->can('_init_self');
  $self->$init_self($class,$args) if $init_self;
}
sub set {
  my $self=shift;
  my $args=new Class::AutoClass::Args(@_);
  while(my($key,$value)=each %$args) {
    my $func=$self->can($key);
    $self->$func($value) if $func;
  }
}
sub get {
  my $self=shift;
  my @keys=Class::AutoClass::Args::fix_keyword(@_);
  my @results;
  for my $key (@keys) {
    my $func=$self->can($key);
    my $result=$func? $self->$func(): undef;
    push(@results,$result);
  }
  wantarray? @results: $results[0];
}
sub set_attributes {
  my($self,$attributes,$args)=@_;
  my @keywords=Class::AutoClass::Args::fix_keyword(@$attributes);
  for my $func (@$attributes) {
    my $keyword=shift @keywords;
    $self->$func($args->{$keyword}) if exists $args->{$keyword};
  }
}

sub set_class_defaults {
  my($self,$attributes,$class,$args)=@_;
  my $class_defaults=DEFAULTS_ARGS($class);
  while(my($keyword,$value)=each %$class_defaults) {
    next if exists $args->{$keyword};
    $args->{$keyword}=ref $value? dclone($value): $value; # deep copy refs
  }
}
sub class {ref $_[0];}
sub ISA {
  my($class)=@_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  @{$class.'::ISA'}
}
sub AUTO_ATTRIBUTES {
  my($class)=@_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  @{$class.'::AUTO_ATTRIBUTES'}
}
sub OTHER_ATTRIBUTES {
  my($class)=@_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  @{$class.'::OTHER_ATTRIBUTES'}
}
sub SYNONYMS {
  my($class)=@_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  %{$class.'::SYNONYMS'}
}
sub DEFAULTS {
  my($class)=@_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  %{$class.'::DEFAULTS'};
}
sub DEFAULTS_ARGS {
  my $class=shift @_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  @_? ${$class.'::DEFAULTS_ARGS'}=$_[0]: ${$class.'::DEFAULTS_ARGS'};
}
sub CASE {
  my $class=shift @_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  ${$class.'::CASE'};
}
sub FORCE_NEW {
  my $class=shift @_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  ${$class.'::FORCE_NEW'};
}
sub AUTODB {
  my($class)=@_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  %{$class.'::AUTODB'}
}
sub ANCESTORS {
  my $class=shift @_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  $_[0] = ref($_[0]) ? $_[0] : []; # keeping the peace  
  @_? ${$class.'::ANCESTORS'}=$_[0]: ${$class.'::ANCESTORS'};
}
sub CAN_NEW {
  my $class=shift @_;
  $class=$class->class if ref $class; # get class if called as object method
  no strict 'refs';
  @_? ${$class.'::CAN_NEW'}=$_[0]: ${$class.'::CAN_NEW'};
}

sub declare {
  my($class,$case)=@_;
  my $attributes=[AUTO_ATTRIBUTES($class)];
  my $synonyms={SYNONYMS($class)};
  my %autodb=AUTODB($class);
  if (%autodb) {
    require 'Class/AutoDB.pm';
    $autodb{'-class'}=$class;
    my $args = Class::AutoClass::Args->new(%autodb);
    my $autodb = Class::AutoDB->new($args);
    $autodb->auto_register(%autodb);
    $autodb->registry->name2coll->{$class}->{__persist} = 1;
    ## TODO: is this still needed?
    unless ($CACHE{'AUTODB'}){
      $CACHE{'AUTODB'}=Clone::clone($autodb); # keep global record
      $CACHE{'AUTODB'}->dbh($autodb->dbh); # otherwise DBI obj goes away
    }
    #for implicitly created objects (no explicit call to autodb constructor, connect by passing DB args)
    if($autodb{'-dsn'}){
      $autodb->_manage_registry($args);
      $autodb->registry->create unless $autodb->exists;
    }
  }

  # enumerate internal super-classes and find an external class to create object
  my($ancestors,$can_new)=_enumerate($class);
  ANCESTORS($class,$ancestors);
  CAN_NEW($class,$can_new);

  # convert DEFAULTS hash into AutoArgs
  DEFAULTS_ARGS($class,new Class::AutoClass::Args(DEFAULTS($class)));

  for my $func (@$attributes) {
  	my $sub;
    my $keyword=Class::AutoClass::Args::fix_keyword($func);
    if(%autodb){
      $sub='*'.$class.'::'.$func."=sub {\@_>1?
        \$_[0]->{\'$keyword\'}=Class::AutoDB::_freeze(\@_):
        \$_[0]->{\'$keyword\'};}";	
    } else {
      $sub='*'.$class.'::'.$func."=sub {\@_>1? 
        \$_[0]->{\'$keyword\'}=\$_[1]: 
        \$_[0]->{\'$keyword\'};}";
      }
    eval $sub;
  }
  while(my($func,$old_func)=each %$synonyms) {
    next if $func eq $old_func;	# avoid infinite recursion if old and new are the same
    my $sub='*'.$class.'::'.$func."=sub {\$_[0]->$old_func(\@_[1..\$\#_])}";
    eval $sub;
  }
  defined $case or $case=CASE($class); # NG 04-01-09 -- allow $CASE to control this
  if ($case=~/lower|lc/i) {	# create lowercase versions of each method, too
    for my $func (@$attributes) {
      my $lc_func=lc $func;
      next if $lc_func eq $func; # avoid infinite recursion if func already lowercase
      my $sub='*'.$class.'::'.$lc_func."=sub {\$_[0]->$func(\@_[1..\$\#_])}";
      eval $sub;
    }
  }
  if ($case=~/upper|uc/i) {	# create uppercase versions of each method, too
    for my $func (@$attributes) {
      my $uc_func=uc $func;
      next if $uc_func eq $func; # avoid infinite recursion if func already uppercase
      my $sub='*'.$class.'::'.$uc_func."=sub {\$_[0]->$func(\@_[1..\$\#_])}";
      eval $sub;
    }
  }
}

sub _enumerate {
  my($class)=@_;
  my $classes=[]; 
  my $types={};
  my $can_new;
  __enumerate($classes,$types,\$can_new,$class);
  return ($classes,$can_new);
}

sub __enumerate {
  my($classes,$types,$can_new,$class)=@_;
  die "Circular inheritance structure. \$class=$class" if $types->{$class} eq 'pending';
  return $types->{$class} if defined $types->{$class};
  $types->{$class}='pending';
  my @isa;
  {
    no strict "refs"; 
    @isa=@{$class.'::ISA'};
  }
  my $type;
  for my $super (@isa) {
    $type='internal',next if $super eq $AUTOCLASS;
    my $super_type=__enumerate($classes,$types,$can_new,$super);
    $type eq 'internal' or $type=$super_type;
  }
  $type or $type='external';
  if (!FORCE_NEW($class) && !$$can_new && $type eq 'internal') {
    for my $super (@isa) {
      next unless $types->{$super} eq 'external';
      $$can_new=$super, last if $super->can('new');
    }
  }
  push(@$classes,$class) if $type eq 'internal';
  $types->{$class}=$type;
  return $types->{$class};
}

sub _is_positional {
  @_%2 || $_[0]!~/^-/;
}

sub DESTROY {
 my $self = shift;
 my $classname = ref($self);

 # write the persistable class, don't write proxyobj's or we'll have circular references
 if($CACHE{AUTODB}) {
   my $registry = $CACHE{AUTODB}->registry;
   my ($result) = map {grep $classname, $_} $registry->collections;
   if($result->name eq $classname && $result->{__persist}) {
     $CACHE{AUTODB}->store($self, $classname);
   }
 }
}

1;

__END__

# Pod documentation

=head1 NAME

Class::AutoClass - Automatically generate simple get and set methods and
automatically initialize objects in a (possibly mulitple) inheritance
structure

=head1 SYNOPSIS

=head2 Define class that uses AutoClass

TestClass defines three attributes that are automatically generated -- scalar_attribute, array_attribute, and hash_attribute -- and one attribute that is coded explicitly -- manual_attribute.  The class also defines synonyms for two of these attributes and provides default values for three of them.

  package TestClass;
  use strict;
  use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
  use Class::AutoClass;
  @ISA=qw(Class::AutoClass);               # AutoClass must be the first super-classs!
  @AUTO_ATTRIBUTES= qw(scalar_attribute 
  		       array_attribute 
  		       hash_attribute);
  @OTHER_ATTRIBUTES=qw(manual_attribute);
  %SYNONYMS=          (scalar=>'scalar_attribute',
                       manual=>'manual_attribute');
  %DEFAULTS=          (manual_attribute=>'a default message',
  		       array_attribute=>[], 
  		       hash_attribute=>{});
  Class::AutoClass::declare(__PACKAGE__);
  

  sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this

    if (defined $self->scalar) {
      push(@{$self->array_attribute},$self->scalar);
      $self->hash_attribute->{$self->scalar}=1
    }
  return;
  }
  
  # Hand coded get/set method for manual_attribute
  sub manual_attribute {
    my $self=shift;
    if (@_) {
      my $manual_attribute=shift @_;
      $self->{manual_attribute}="A manual attribute for class ".ref($self).
        ": $manual_attribute";
    }
    return $self->{manual_attribute};
  }

The first two lines after the package statement -- 'use strict' and
'use vars ...' -- are optional, but highly recommended.

If a class has multiple super-classes, AutoClass, or a subclass of
AutoClass, must be the first one listed in the @ISA definition.

The _init_self method is called by AutoClass after
auto-initialization.  This is where you put all your explicit
initialization, ie, the code you probably would put in your 'new'
method if you weren't using AutoClass.

To illustrate explicit initialization, the example puts the
scalar_attribute into the array_attribute and hash_attribute.  Note
that array_attribute and hash_attribute are already initialized to
their default values of [] and {} respectively, so the dereferencing
operations (@ and ->) need not woory about being called on undefined
values.

If a subclass does not define its own _init_self method, the one
defined in the parent class will be run.  This is often undesirable,
and the example code shows our standard idiom for causing the method
to return immediately if run in a subclass.

=head2 A Perl application that uses the defined class

  use strict;
  use TestClass;
  
  # First define a helper subroutine to print the test objects
  # Note that it accesses the contents of the object using the auto-generated
  # or manually written get methods
  sub pr_test {
    my($test)=@_;
    print "TestClass:\n"; 
    print "scalar_attribute=>",$test->scalar_attribute,"\n";
    print "array_attribute=>[",join(', ',@{$test->array_attribute}),"]\n";
    print "hash_attribute=>{";
    while (my ($key,$value) = each %{$test->hash_attribute}) {
      print "\n    $key\t=> $value";
    }
    print "}\n";
    print "manual_attribute=>",$test->manual_attribute,"\n";
    print "\n";
  }
 
  # Now for the main program
  
  # Create empty object.  
  # Note that default values for array_attribute and hash_attribute are automatically set
  my $test=new TestClass;
  pr_test $test;
  
  # Set some of the object's attributes
  $test->scalar_attribute('A scalar value');
  $test->array_attribute(['An', 'array', 'value']);
  $test->hash_attribute({'A key'=>'A value', 'Another key'=>'Another value'});
  pr_test $test;
  
  # Create object with a scalar value
  # Note that _init_self adds the scalar value to the array_attribute and hash_attribute
  my $test=new TestClass(-scalar_attribute=>'hello world');
  pr_test $test;
  
  # Same thing, but uses the synonym 'scalar' instead of 'scalar_attribute'
  my $test=new TestClass(-scalar=>'hello world');
  pr_test $test;
  
  # Create object with manual_attribute.
  # Note that 'manual_attribute' can be auto-initialized even though the set method is not
  #   auto-generated
  my $test=new TestClass(-manual_attribute=>'an explicitly set value');
  pr_test $test;

Here is the output of the program

  TestClass:
  scalar_attribute=>
  array_attribute=>[]
  hash_attribute=>{}
  manual_attribute=>A manual attribute for class TestClass: a default value
  
  TestClass:
  scalar_attribute=>A scalar value
  array_attribute=>[An, array, value]
  hash_attribute=>{
      A key       => A value
      Another key => Another value}
  manual_attribute=>A manual attribute for class TestClass: a default value
  
  TestClass:
  scalar_attribute=>hello world
  array_attribute=>[hello world]
  hash_attribute=>{
      hello world => 1}
  manual_attribute=>A manual attribute for class TestClass: a default value
  
  TestClass:
  scalar_attribute=>hello world
  array_attribute=>[hello world]
  hash_attribute=>{
      hello world => 1}
  manual_attribute=>A manual attribute for class TestClass: a default value
  
  TestClass:
  scalar_attribute=>
  array_attribute=>[]
  hash_attribute=>{}
  manual_attribute=>A manual attribute for class TestClass: an explicitly set value

=head1 DESCRIPTION

  1) Simple 'get' and 'set' methods are automatically generated

  2) Keyword argument lists are handled as described below

  3) Object 'attributes' are automatically initialized from keyword
  parameters, class defaults, or parameter defaults.  This includes
  attributes for which the 'get' and 'set' methods are maually
  written, as well as those that are auto-generated

  3) The protocol for object creation and initialization is close to
  the 'textbook' approach generally suggested for object-oriented Perl
  (see below)

  4) Object initialization is handled correctly in the presence of
  multiple inheritance

  5) It works for a class to inherit from AutoClass and other classes
  that are not descendants of AutoClass.  This makes it possible to
  use AutoClass in cases where you are subclassing from an existing
  class library.  In such cases, AutoClass lets the external classes
  create the object and do their initialization first before taking
  over.  This is required for correct object initialization in the
  presence of multiple inheritance

The following variables control the operation of the class. 

  @AUTO_ATTRIBUTES is a list of 'attribute' names: get and set methods
  are created for each attribute.  By default, the name of the method
  is identical to the attribute (but see $CASE below).  Values of
  attributes can be set via the 'new' constructor or the 'set' method
  as discussed below.

  @OTHER_ATTRIBUTES is a list of attributes for which get and set
  methods are NOT automatically generated, but whose values can be set
  via the 'new' constructor or the 'set' method as discussed below.

  %SYNONYMS is a hash that defines synonyms for attribues. Each entry
  is of the form 'new_attribute_name'=>'old_attribute_name'.  get and
  set methods are generated for the new names; these methods simply
  call the method for the old name.

  %DEFAULTS defines class default values for any or all attributes.
  Default values can also be set by passing a parameter called
  'defaults'

  $CASE controls whether additional methods are generated with all
  upper or all lower case names.  It should be a string containing the
  strings 'upper' or 'lower' (case insenstive) if the desired case is
  desired.

  $FORCE_NEW should be set to 1 if AutoClass should take
  responsibility for creating the object even if an 'external' (ie,
  non-AutoClass) super-class is capable of doing so.  Normally, if an
  external class in the inheritance structure wants to create the
  object, AutoClass will defer to it.  This sometimes fails if the
  super-class is not designed to allow graceful sub-classing.  In such
  cases, setting $FORCE_NEW can sometime remedy the problem.

The 'declare' function actually generates the methods and 
analyzes the @ISA structure in various ways.  This should be called
once at the beginning of the class definition, and no where else.

If a class has multiple super-classes, AutoClass, or a subclass of
AutoClass, must be the first one listed in the @ISA definition.  This
is to ensure that AutoClass's 'new' method is the one that's called
when you create an object.  (If an external classes in the inheritance
structure wants to create the object, AutoClass will defer to it as
explained above.  Even in this case, AutoClass must be first so its
'new' can orchestrate the processing.)


=head2 Argument Processing

The AutoClass 'new' method, and the auxillary methods 'set' and
'set_attributes' operate on keyword parameter lists.  The actually
argument processing is provided in the related class
Class::AutoClass::Args.

Keywords are insensitive to case and leading dashes: the following calls are all equivalent:

  $test=new TestClass(-scalar_attribute=>'hello world');
  $test=new TestClass(scalar_attribute=>'hello world');
  $test=new TestClass(--SCALAR_attribute=>'hello world');

Internally, for those who care, our convention is to use lowercase,
un-dashed keys for the attributes of an object.

We convert repeated keyword arguments into an ARRAY of the values. Thus:

  $test=new TestClass(array_attribute->'An',array_attribute->'array',array_attribute->'value');

is equivalent to

  $test=new TestClass(array_attribute->['An', 'array', 'value']);

Keyword arguments can be specified via ARRAYs or HASHes which are
dereferenced back to their elements, e.g.,

  $test=new TestClass([scalar_attribute=>'A scalar value',
                       array_attribute=>['An', 'array', 'value'],
                       hash_attribute=>{'A key'=>'A value', 'Another key'=>'Another value'}]);

and

  $test=new TestClass({scalar_attribute=>'A scalar value',
                       array_attribute=>['An', 'array', 'value'],
                       hash_attribute=>{'A key'=>'A value', 'Another key'=>'Another value'}});

are both equivalent to 

  $test=new TestClass(scalar_attribute=>'A scalar value',
                      array_attribute=>['An', 'array', 'value'],
                      hash_attribute=>{'A key'=>'A value', 'Another key'=>'Another value'});

We also allow the argument list to be an object.  This is often used
in new to accomplish what a C++ programmer would call a cast.  In
simple cases, the object is just treated as a HASH and its
attributes are passed to a the method as keyword, value pairs.

=head2 Protocol for Object Creation and Initializaton

We expect objects to be created by invoking new on its class.  

To correctly initialize objects that participate in multiple inheritance, 
we use a technqiue described in Chapter 10 of Paul Fenwick''s excellent 
tutorial on Object Oriented Perl (see http://perltraining.com.au/notes/perloo.pdf).  
(We experimented with Damian Conway's interesting NEXT
pseudo-pseudo-class discussed in Chapter 11 of Fenwick's tutorial
available in CPAN at http://search.cpan.org/author/DCONWAY/NEXT-0.50/lib/NEXT.pm, 
but could not get it to traverse the inheritance structure in the correct,
top-down order.  We understand the problem is now fixed.)

AutoClass::new initializes the object's class structure from top to
bottom, and is careful to initialize each class exactly once even in
the presence of multiple inheritance.  The net effect is that objects
are initialized top-down as expected; a subclass object can assume
that all superior classes are initialized by the time subclass
initialization occurs.

AutoClass automatically initializes attributes and synonyms declared
when the class is defined.  If additional initialization is required,
the class writer can provide an _init_self method.  _init_self is
called after all superclasses are initialized and after the automatic
initialization for the class has been done.

AutoClass initializes attributes and synonyms by calling the set methods
for these elements with the like-named parameter -- it does not simply
slam the parameter into a slot in the object's HASH.  This allows the
class writer to implement non-standard initialization within the set
method.

=head2 Example illustrating multiple inheritance

This example illustrates the operation of AutoClass in a multiple
inheritance situation. The classes A, B, C, and D form a classic
diamond inheritance pattern:

     A
   /  \
  B    C
   \  /
    D

The example also illustrates that attributes are inherited by
subclasses, as you would expect.  It also show the use of %SYNONYMS to
override a method as we work down the inheritance structure.

In practice, you should usually put each package in a separate file.
The example puts them all in one file for expository convenience.

  use Class::AutoClass;
  use Data::Dumper;		# just for printing out objects
  use strict;
  
  package A;
  use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
  @ISA=qw(Class::AutoClass);
  @AUTO_ATTRIBUTES=qw(a_attr array);
  @OTHER_ATTRIBUTES=qw(message);
  %SYNONYMS=(best_attr=>'a_attr');
  %DEFAULTS=(a_attr=>'class default for a_attr',
  	     array=>[]);
  Class::AutoClass::declare(__PACKAGE__);
  
  sub _init_self {
    my($self,$class,$args)=@_;
  #  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
    print "+++ Initializing $class\n";
    push(@{$self->array},"Initializing $class");
  }
  
  package B;
  use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
  @ISA=qw(A);
  @AUTO_ATTRIBUTES=qw(b_attr);
  @OTHER_ATTRIBUTES=qw();
  %SYNONYMS=(best_attr=>'b_attr');
  %DEFAULTS=(b_attr=>'class default for b_attr');
  Class::AutoClass::declare(__PACKAGE__);
  
  package C;
  use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
  @ISA=qw(A);
  @AUTO_ATTRIBUTES=qw(c_attr);
  @OTHER_ATTRIBUTES=qw();
  %SYNONYMS=(best_attr=>'c_attr');
  %DEFAULTS=(c_attr=>'class default for c_attr');
  Class::AutoClass::declare(__PACKAGE__);
  
  package D;
  use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
  @ISA=qw(B C);
  @AUTO_ATTRIBUTES=qw(d_attr);
  @OTHER_ATTRIBUTES=qw();
  %SYNONYMS=(best_attr=>'d_attr');
  %DEFAULTS=(d_attr=>'class default for d_attr');
  Class::AutoClass::declare(__PACKAGE__);
  
  package main;
  
  sub pr {print Dumper(@_);}
  
  print "A:\n"; my $a=new A; pr $a; print "\$a->best_attr => ",$a->best_attr,"\n";
  print "B:\n"; my $b=new B; pr $b; print "\$b->best_attr => ",$b->best_attr,"\n";
  print "C:\n"; my $c=new C; pr $c; print "\$c->best_attr => ",$c->best_attr,"\n";
  print "D:\n"; my $d=new D; pr $d; print "\$d->best_attr => ",$d->best_attr,"\n";

The example creates an object of each class, prints the message 

  "+++ Initializing $class\n" 

as it initializes each superclass, and also
pushes that information onto its 'array' attribute.  The examnple then
prints the object (using Data::Dumper) and also prints the value of
the 'best_attr' attribute to illustrate that the attributes gets
overridden as expected.

Here is the output:

  A:
  +++ Initializing A
  $VAR1 = bless( {
                   'array' => [
                                'Initializing A'
                              ],
                   'a_attr' => 'class default for a_attr'
                 }, 'A' );
  $a->best_attr => class default for a_attr
  B:
  +++ Initializing A
  +++ Initializing B
  $VAR1 = bless( {
                   'array' => [
                                'Initializing A',
                                'Initializing B'
                              ],
                   'a_attr' => 'class default for a_attr',
                   'b_attr' => 'class default for b_attr'
                 }, 'B' );
  $b->best_attr => class default for b_attr
  C:
  +++ Initializing A
  +++ Initializing C
  $VAR1 = bless( {
                   'c_attr' => 'class default for c_attr',
                   'array' => [
                                'Initializing A',
                                'Initializing C'
                              ],
                   'a_attr' => 'class default for a_attr'
                 }, 'C' );
  $c->best_attr => class default for c_attr
  D:
  +++ Initializing A
  +++ Initializing B
  +++ Initializing C
  +++ Initializing D
  $VAR1 = bless( {
                   'd_attr' => 'class default for d_attr',
                   'c_attr' => 'class default for c_attr',
                   'array' => [
                                'Initializing A',
                                'Initializing B',
                                'Initializing C',
                                'Initializing D'
                              ],
                   'a_attr' => 'class default for a_attr',
                   'b_attr' => 'class default for b_attr'
                 }, 'D' );
  $d->best_attr => class default for d_attr


Initialization occurs top-down as required.  When creating an object
of class D, the A-initialization happens first, then B and C in either
order, then D.  The A-initialization only happens once even though D
inherits from A along two paths.


=head1 KNOWN BUGS AND CAVEATS

This is still a work in progress.  

=head2 Bugs, Caveats, and ToDos

There are numerous CPAN modules that overlap the functionality of
AutoClass, including Class::MakeMethods, Class::Multimethods,
Class::Translucent, Class::NamedParms, among others.  CGI.pm and
BioPerl also provide similar keyword parameter processing.  We've
borrowed ideas from some of these modules, but have chosen not to use
any of their code in this alpha release on the grounds that the hard
part of building something like AutoClass is deciding what
capabilities it should provide, and finding easy ways for programmers
to access these capabilities.  The code itself is relatively
straightforward.  Now that we're closer to knowing what we want
AutoClass to do, an important next step will be to incorporate some of these
other modules in cases where they provide the capabilities we want in a better
manner.

  1) Autogeneration of methods is hand crafted and quite wimpy
  compared to Class::MakeMethods or Class::Multimethods.

  2) There is no way to manipulate the arguments that are sent to an
  external base class. There should be a way to specify a subroutine
  that reformats these if needed.

  3) DESTROY not handled

  4) We do not consistently use the '_' prefix on method names for
  internal methods.

  5) It's klunky to use so many global variables to control the
  operation of the class.  This just grew.  It may be better to
  consolidate them all in a single HASH. 

=head1 AUTHOR - Nat Goodman, Chris Cavnor

Email natg@shore.net

=head1 COPYRIGHT

Copyright (c) 2004 Institute for Systems Biology (ISB). All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 PUBLIC METHODS

These methods can be used by code that operates on an AutoClass subclass.

=head2 new

 Title   : new
 Usage   : $test=new TestClass(scalar_attribute=>'A scalar value',
                               array_attribute=>['An', 'array', 'value'])
           where TestClass is a subclass of AutoClass
 Function: Create and initialize object
 Returns : New object of class $class
 Args    : Any arguments needed by subclasses
         -->> Arguments must be in keyword form.  See DESCRIPTION for more.
 Notes   : Tries to invoke superclass to actually create the object


=head2 set

 Title   : set
 Usage   : $self->set(scalar_attribute=>'A scalar value',
                      array_attribute=>['An', 'array', 'value']);
 Function: Set multiple attributes in existing object
 Args    : Parameter list in same format as for new
 Returns : nothing

=head2 set_attributes

 Title   : set_attributes
 Usage   : $self->set_attributes([qw(scalar_attribute array_attribute)],$args)
 Function: Set multiple attributes from a Class::AutoClass::Args object
           Any attribute value that is present in $args is set
 Args    : ARRAY ref of attributes
           Class::AutoClass::Args object
 Returns : nothing

=head2 get

 Title   : get
 Usage   : ($scalar,$array)=$self->get(qw(scalar_attribute,array_attribute))
 Function: Get values for multiple attributes
 Args    : Attribute names
 Returns : List of attribute values

=head1 CLASS WRITER METHODS

These methods are used when defining an AutoClass subclass.

=head2 _init_self

 Title   : _init_self
 Usage   : $self->_init_self($class,$args)
 Function: Perform custom initialization of object
 Returns : nothing useful
 Args    : $class -- lexical (static) class being initialized, not the
           actual (dynamic) class of $self
           $arg -- argument list as a Class::AutoClass::Args object
 Notes   : Implemented by class writers, NOT by AutoClass itself.


=head2 declare

 Title   : declare
 Usage   :   @AUTO_ATTRIBUTES=qw(sex address dob);
             @OTHER_ATTRIBUTES=qw(age);
             %SYNONYMS=(name=>'id');
	     AutoClass::declare(__PACKAGE__,'lower|upper');
	     
 Function: Generate get and set methods for simple attributes and synonyms.
           Method names are identical to the attribute names including case
 Returns : nothing
 Args    : lexical class being created -- should always be __PACKAGE__
           code that indicates whether method should also be generated
            with all lower or upper case names
            OBSOLETE: use $CASE variable, instead
            
=head1 PRIVATE METHODS

These methods are used by AutoClass itself and are normally not
invoked by programs that use AutoClass.

=head2 _init

 Title   : _init_self
 Usage   : $self->_init($class,$args)
 Function: Initialize new object
 Returns : nothing useful
 Args    : $class -- lexical (static) class being initialized, not the
           actual (dynamic) class of $self
           $arg -- argument list in canonical keyword form
 Notes   : Adapted from Chapter 10 of Paul Fenwick''s excellent tutorial on 
           Object Oriented Perl (see http://perltraining.com.au/notes/perloo.pdf).

=head2 _enumerate

 Title   : _enumerate
 Usage   : _enumerate($class);
 Function: locates classes that have a callable constructor
 Args    : a class reference
 Returns : list of internal classes, a class with a callable constructor 


=head2 _fix_args

 Title   : _fix_args
 Usage   : $args=_fix_args(-name=>'Nat',-name=>Goodman,address=>'Seattle')
           $args=$self->_fix_args(@args)

 Function: Convert argument list into canonical form.  This is a HASH ref in 
           which keys are uppercase with no leading dash, and repeated
           keyword arguments are merged into an ARRAY ref.  In the
           example above, the argument list would be converted to this
           hash
              (NAME=>['Nat', 'Goodman'],ADDRESS=>'Seattle')
 Returns : argument list in canonical form
 Args    : argument list in any keyword form

=head2 _fix_keyword

 Title   : _fix_keyword
 Usage   : $keyword=_fix_keyword('-name')
           @keywords=_fix_keyword('-name','-address');
 Function: Convert a keyword or list of keywords into canonical form. This
           is uppercase with no leading dash.  In the example above,
           '-name' would be converted to 'NAME'. Non-scalars are left
           unchanged.
 Returns : keyword or list of keywords in canonical form 
 Args : keyword or list of keywords

=head2 _set_attributes

 Title   : _set_attributes
 Usage   :   my %synonyms=SYNONYMS($class);
             my $attributes=[AUTO_ATTRIBUTES($class),
			     OTHER_ATTRIBUTES($class),
			     keys %synonyms];
             $self->_set_attributes($attributes,$args);
 Function: Set a list of simple attributes from a canonical argument list
 Returns : nothing
 Args    : $attributes -- ARRAY ref of attributes to be set
           $args -- argument list in canonical keyword (hash) form 
 Notes   : The function calls the set method for each attribute passing 
           it the like-named parameter from the argument list

=head2 _is_positional

 Title   : _is_positional
 Usage  : if (_is_positional(@args)) {
             ($arg1,$arg2,$arg3)=@args; 
	   }
 Function: Checks whether an argument list conforms to our convention 
           for positional arguments. The function returns true if 
           (1) the argument list has an odd number of elements, or
           (2) the first argument starts with a dash ('-').
           Obviously, this is not fully general.
 Returns : boolean
 Args    : argument list
 Notes   : As explained in DESCRIPTION, we recommend that methods not 
           support both positional and keyford argument lists, as this 
           is inherently ambiguous.
 BUGS    : NOT YET TESTED in this version
 
=head2 set_class_defaults

 Title   : set_class_defaults
 Usage   : $self->set_class_defaults($attributes,$class,$args);
 Function: Set default values for class argument
 Args    : reference to the class and a Class::AutoClass::Args object
           which contains the arguments to set
 Returns : nothing

=head2 AUTO_ATTRIBUTES

 Title   : AUTO_ATTRIBUTES
 Usage   : @auto_attributes=AUTO_ATTRIBUTES('SubClass')
           @auto_attributes=$self->AUTO_ATTRIBUTES();
 Function: Get @AUTO_ATTRIBUTES for lexical class.
           @AUTO_ATTRIBUTES are attributes for which get and set methods
           are automatically generated.  _init automatically
           initializes these attributes from like-named parameters in
           the argument list
 Args :    class

=head2 OTHER_ATTRIBUTES

 Title   : OTHER_ATTRIBUTES
 Usage   : @other_attributes=OTHER_ATTRIBUTES('SubClass')
           @other_attributes=$self->OTHER_ATTRIBUTES();
 Function: Get @OTHER_ATTRIBUTES for lexical class.
           @OTHER_ATTRIBUTES are attributes for which get and set methods
           are not automatically generated.  _init automatically
           initializes these attributes from like-named parameters in
           the argument list
 Args :    class

=head2 SYNONYMS

 Title   : SYNONYMS
 Usage   : %synonyms=SYNONYMS('SubClass')
           %synonyms=$self->SYNONYMS();
 Function: Get %SYNONYMS for lexical class.
           %SYNONYMS are alternate names for attributes generally
           defined in superclasses.  get and set methods are
           automatically generated.  _init automatically initializes
           these attributes from like-named parameters in the argument
           list
 Args :    class

=head2 DEFAULTS

 Title   : DEFAULTS
 Usage   : %defaults=DEFAULTS('SubClass')
           %defaults=$self->DEFAULTS();
 Function: Get %DEFAULTS for lexical class.
           %DEFAULTS are class default values for parameters
 Args :    class

=head2 DEFAULTS_ARGS

 Title   : DEFAULTS_ARGS
 Usage   : $defaults=DEFAULTS_ARGS('SubClass')
           $defaults=$self->DEFAULTS_ARGS();
           $defaults=DEFAULTS_ARGS('SubClass', $defaults)
           $defaults=$self->DEFAULTS_ARGS($defaults);
 Function: Get or set class defaults for lexical class represented as 
           Class::AutoClass::Args object.
           Used internally in the course of default processing
 Args :    class
           Class::AutoClass::Args object

=head2 CASE

 Title   : CASE
 Usage   : $case=CASE('SubClass')
           $case=$self->CASE();
 Function: Get $CASE for lexical class
           Controls whether get and set methods with all upper- or lowercase 
           names are auto-generated in addition to the methods whose names are
           listed in @AUTO_ATTRIBUTES.
           Rarely used in our experience.
 Args :    class

=head2 FORCE_NEW

 Title   : FORCE_NEW
 Usage   : $force_new=FORCE_NEW('SubClass')
           $force_new=$self->FORCE_NEW();
 Function: Get $FORCE_NEW for lexical class
           Flag used to for AutoClass to create object even if an external 
           superclass is capable of doing so.
           Used in special cases to workaround problems in superclasses
 Args :    class

=head2 AUTODB

 Title   : AUTODB
 Usage   : %auto_db=AUTODB('SubClass')
           %auto_db=$self->AUTODB();
 Function: Get %AUTODB for lexical class
           Control operation of AutoDB.  See Class::AutoDB for details.
 Args :    class

=head2 ANCESTORS

 Title   : ANCESTORS
 Usage   : $ancestors=ANCESTORS('SubClass')
           $ancestors=$self->ANCESTORS();
           $ancestors=ANCESTORS('SubClass', $ancestors)
           $ancestors=$self->ANCESTORS($ancestors);
 Function: Get or set superclasses in correct order for initialization
 Args :    class
           ARRAY of class names

=head2 CAN_NEW

 Title   : CAN_NEW
 Usage   : $can_new=CAN_NEW('SubClass')
           $can_new=$self->CAN_NEW();
           $can_new=CAN_NEW('SubClass', $can_new)
           $can_new=$self->CAN_NEW($can_new);
 Function: Get or set flag indicating whether this class can creat the object
 Args :    class
           boolean

=cut
