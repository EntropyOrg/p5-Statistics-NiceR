use Test::Most;

use strict;
use warnings;

use R;

my $function = Rinterp::R_get_function("rnorm");

print $function;

my $return = Rinterp::R_call_function( $function, [ 10 ] );
print $return;

#use DDP; p $function;
