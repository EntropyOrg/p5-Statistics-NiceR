use Test::Most tests => 1;

use strict;
use warnings;

use R;
use PDL;

my $r = R->new;

my $df = $r->get('iris');
my $mean  = Rinterp->R_get_function('mean');
my $l_mean = $r->lapply( $df, $mean );

is @$l_mean, 5, 'check the length of the mean applied to each of the columns of the iris data.frame';
