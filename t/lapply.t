use Test::Most tests => 1;

use strict;
use warnings;

use R;
use PDL;

my $r = R->new;

my $df = $r->get('iris');
my $mean  = Rinterp->R_get_function('mean');
use DDP; p $r->lapply( $df, $mean );
