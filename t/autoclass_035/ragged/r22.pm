package autoclass_035::ragged::r22;
use base qw(autoclass_035::ragged::r1 autoclass_035::external::ext2);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r22');
 }
1;
