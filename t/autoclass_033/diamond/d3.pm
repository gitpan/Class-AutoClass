package autoclass_033::diamond::d3;
use base qw(Class::AutoClass autoclass_033::diamond::d20 autoclass_033::diamond::d21);
 
sub new {
  my $self_or_class=shift;
  my $class=ref($self_or_class) || $self_or_class;
  my $self=ref($self_or_class)? $self_or_class: bless {},$class;
  push(@{$self->{new_history}},'d3');
  $self->SUPER::new(@_);
 }

sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d3');
 }
1;
