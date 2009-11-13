use strict;
use lib qw(t);
use Test::More;
use Test::Deep;

# test inconsistent attributes -- ones declared as both instance and class attributes
# note that error is detected at 'declare time' during use

eval "use autoclass_011::Inconsistent1";

ok(!$@,'use autoclass_011::Inconsistent1 found no inconsistencies');
eval "use autoclass_011::Inconsistent2";
like($@,qr/^Inconsistent declarations for attribute\(s\) a b/,
     'use autoclass_011::Inconsistent2 found expected inconsistencies');

done_testing();
