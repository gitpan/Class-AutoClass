use lib 't/';
use Test::More qw/no_plan/;
use Class::AutoClass::Root;
use IO::Scalar;
use strict;
use Data::Dumper;

my $obj = new Class::AutoClass::Root;

## Test object validity 
isa_ok($obj,  "Class::AutoClass::Root");
 
 # deprecated outputs to STDERR
  {
    my $DEBUG_BUFFER="";
    tie *STDERR, 'IO::Scalar', \$DEBUG_BUFFER;
    eval { $obj->deprecated };
    ok ($DEBUG_BUFFER =~ /STACK/,  "testing deprecated");
    untie *STDERR;
  }

 my @results = $obj->stack_trace;
 my ($last) = shift @results;
 ok( "@$last" =~ /stack_trace/, "testing stack_trace");
 eval { $obj->throw('Testing throw') };
 ok ($@ =~ /Testing throw/, "testing throw");


 {
  my $DEBUG_BUFFER="";
  tie *STDERR, 'IO::Scalar', \$DEBUG_BUFFER;
  eval { $obj->warn() };
  ok($DEBUG_BUFFER =~ /^MSG:.*$/m, "testing warn with no input - empty message expected"); 
  untie *STDERR;
 }

 {
  my $DEBUG_BUFFER="";
  tie *STDERR, 'IO::Scalar', \$DEBUG_BUFFER;
  eval { $obj->warn("tEsT") };
  ok($DEBUG_BUFFER =~ /tEsT/m, "testing warn with input");
  untie *STDERR;
 }
