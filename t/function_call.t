use Test::Most tests => 2;

use strict;
use warnings;

use R;
use R::DataConvert;

my $fname = 'sequence';

my $function = Rinterp->R_get_function($fname);

is "$function", $fname, 'function is correct';

my @args = ( [ 10 ] );
my @r_args = map { [ R::DataConvert->convert_perl_to_r($_->[0]) ] } @args;
my $return = Rinterp->R_call_function( $function, @r_args );

is( "$return", q{ [1]  1  2  3  4  5  6  7  8  9 10}, 'string representation of returned SEXP')
