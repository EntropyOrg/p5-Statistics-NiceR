use Test::Most tests => 1;

use strict;
use warnings;

use Statistics::NiceR;
use PDL;

my $r = Statistics::NiceR->new;

my $df = $r->get('iris');
my $mean  = Statistics::NiceR::Backend::EmbeddedR->R_get_function('mean');
my $l_mean = $r->lapply( $df, $mean );

is @$l_mean, 5, 'check the length of the mean applied to each of the columns of the iris data.frame';
