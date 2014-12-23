use Test::Most tests => 1;

use strict;
use warnings;

use Statistics::NiceR;

my $r = Statistics::NiceR->new;
my $iris_subset = $r->eval_parse(q{ iris[1:20,1:4] });

is($iris_subset->number_of_rows, 20, 'correct subset');

done_testing;
