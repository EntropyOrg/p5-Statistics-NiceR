use Test::Most tests => 5;

use strict;
use warnings;

use R;
use PDL;

my $r = R->new;

my $r_seq = $r->sequence( 10 );
my $p_seq = sequence(10) + 1;
ok( ($r_seq == $p_seq)->all, 'sequence autoload works' );

# > g <- array( 0:5, c(2,3) )
#      [,1] [,2] [,3]
# [1,]    0    2    4
# [2,]    1    3    5
# > g[1,2]
# [1] 2
# > g[1,]
# [1] 0 2 4
my $r_mat = $r->array( [0..5] , [2, 3] ); # g
my $r_idx = [1,2]; # R is 1-based
          #  ^ ^
          #  | |
          #  r,c
my $mat_val = 2;
my $p_idx = [map { $_-1 } @$r_idx ]; # perl is 0-based
my $p_mat = sequence(2,3);
ok( ($r_mat == $p_mat)->all, 'autoload + multiple arguments works' );
is( $p_mat->at(@$p_idx), $mat_val, 'sanity check' );
is( $r_mat->at(@$p_idx), $mat_val, 'Perl to R is correct' );

ok( ( $r_mat->slice('(0),') == pdl([0, 2, 4]) )->all );
