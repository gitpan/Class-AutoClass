use lib qw(../lib t/);
use Class::AutoClass;
use Class::AutoClass::Args;
use Parent;
@ISA=qw(AutoClass Parent);

my $args=new Class::AutoClass::Args(-arg1=>'value 1');
print $args->arg1, "\n";

my $bob =  Parent->new(-name=>'Bob');
print $bob->name, "\n";
$bob->name('Bobby');
print $bob->name, "\n";
$bob->set(-name=>'Robert');
print $bob->name, "\n";
$bob->set('name','Bobby');
print $bob->name, "\n";
$bob->set(name=>'Robby');
print $bob->name, "\n";