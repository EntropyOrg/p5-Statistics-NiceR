use Test::Most tests => 1;

use strict;
use warnings;

use R;
use PDL;

my $r = R->new;

my $r_seq = $r->sequence( 10 );
my $p_seq = sequence(10) + 1;
ok( ($r_seq == $p_seq)->all, 'sequence autoload works' );
