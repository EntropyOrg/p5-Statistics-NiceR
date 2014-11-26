use Test::Most tests => 6;

use strict;
use warnings;

use R;

my $r1 = Rinterp::eval_SV(q{ c(3,2,1) });
my $r2 = Rinterp::eval_SV(q{ c(3,2,1) });
my $r3 = Rinterp::eval_SV(q{ c(3,3,1) });

ok $r1->op_equal_all($r2), "$r1 == $r2"; # TRUE

ok(! $r1->op_equal_all($r3), "$r1 != $r3"); # FALSE
ok(! $r2->op_equal_all($r3), "$r2 != $r3"); # FALSE

ok $r1->op_equal_all($r1), "$r1 == $r1"; # TRUE
ok $r2->op_equal_all($r2), "$r2 == $r2"; # TRUE
ok $r3->op_equal_all($r3), "$r3 == $r3"; # TRUE

done_testing;
