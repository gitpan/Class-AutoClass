use strict;
use lib 't/';
use Parent;
use Child;
use GrandChild;
use Test::More qw/no_plan/;
use Data::Dumper; # only for debugging

# this is a regression test covering a bug where the DEFAULTS set in a child class
# do not get correctly applied to attributes in the parent class

my $parent=new Parent;
my $child=new Child;
my $grandchild=new GrandChild;

is($parent->a, 'parent', 'parent has correct default setting');
is($child->a, 'child', 'child has correct default setting');
is($grandchild->a, 'grandchild', 'grandchild has correct default setting');
