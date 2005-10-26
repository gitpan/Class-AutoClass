use strict;
use lib qw(../lib t/);
use Parent;
use Test::More qw/no_plan/;

# this is a regression test covering a bug (SF# 1222961) where synonyms are not created consistent
# with the documentation

# gender is a synonym for sex
my $parent=new Parent;
$parent->sex('male');
is($parent->gender, 'male', 'var set using "gender", read using "sex"');
$parent->gender('female');
is($parent->sex, 'female', 'var set using "sex", read using "gender"');
$parent->sex('???');
is($parent->whatisya, '???', 'var set using "sex", read using "whatisya" synonym'); # testing second synonym
