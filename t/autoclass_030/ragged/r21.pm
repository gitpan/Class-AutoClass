package autoclass_030::ragged::r21;
use base qw(autoclass_030::ragged::r1);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r21');
 }
1;
