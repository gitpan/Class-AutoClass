use lib qw(../lib t/);
use Carp;
use Class::AutoClass::Args;
use Test::More qw/no_plan/;

my($args, @list, @list2, @list3);

$args=new Class::AutoClass::Args(-arg1=>'value 1');
is($args->arg1,'value 1');
$args=new Class::AutoClass::Args(-arg1=>'value 1',-arg2=>'value 1',-arg2=>'value 2');
@list=@{$args->arg2};
is($args->arg1,'value 1');
is($list[0],'value 1');
is($list[1],'value 2');


$args=new Class::AutoClass::Args
  (-arg1=>'value 1',
   -arg2=>'value 1',-arg2=>'value 2',
   ArG3=>'value 1','--arg3'=>'value 2',-ARG3=>'value 3',
  );
@list2=@{$args->arg2};
@list3=@{$args->arg3};
is($args->arg1,'value 1');
is($list2[0],'value 1');
is($list2[1],'value 2');
is($list3[0],'value 1');
is($list3[1],'value 2');
is($list3[2],'value 3');

@list=$args->get_args(qw(arg1 arg2 arg3));
@list=flatten(@list);
is($list[0],'value 1');
is($list[1],'value 1');
is($list[2],'value 2');
is($list[3],'value 1');
is($list[4],'value 2');
is($list[5],'value 3');


$args->set_args
  (-arg1=>'changed value 1',
   -arg2=>'changed value 1',-arg2=>'changed value 2',
   ArG3=>'changed value 1','--arg3'=>'changed value 2',-ARG3=>'changed value 3',
  );
@list=$args->get_args(qw(arg1 arg2 arg3));
@list=flatten(@list);
is($list[0],'changed value 1');
is($list[1],'changed value 1');
is($list[2],'changed value 2');
is($list[3],'changed value 1');
is($list[4],'changed value 2');
is($list[5],'changed value 3');

$args=new Class::AutoClass::Args([-arg1=>'value 7']);
is($args->arg1, 'value 7');
$args=new Class::AutoClass::Args({-arg1=>'value 11'});
is($args->arg1, 'value 11');

sub flatten {map {'ARRAY' eq ref $_? @$_: $_} @_;}
