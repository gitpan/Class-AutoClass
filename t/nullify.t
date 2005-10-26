use strict;
use lib qw(../lib t/);
use Nullable;
use Test::More qw/no_plan/;

# this tests the ability to nullify (using the '_NULLIFY_' flag) an AutoClass object so as to 
# return undef to the caller

my $n1=new Nullable(a => 'hello');
is($n1->a, 'hello', 'returns a Nullable object with param set');
my $n2=new Nullable();
isnt(ref $n2, 'Nullable');
is($n2, undef);