package autoclass_030::trio::t3;
use base qw(autoclass_030::trio::t2);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'t3');
 }
1;
