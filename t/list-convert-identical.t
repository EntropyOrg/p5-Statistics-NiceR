use Test::Most tests => 4;

use strict;
use warnings;

use Statistics::NiceR;
use Statistics::NiceR::DataConvert;
use PDL;

# A list created in R.
my $l_eval = Statistics::NiceR::Backend::EmbeddedR->eval(q{ list('a',1,2) });

# A list created in Perl and converted to R.
my $l_perl_to_r = Statistics::NiceR::DataConvert->convert_perl_to_r( ['a', pdl(1), pdl(2)] );

# Convert the list from R -> Perl -> R.
my $l_eval_to_perl = Statistics::NiceR::DataConvert->convert_r_to_perl($l_eval);
my $l_roundtrip = Statistics::NiceR::DataConvert->convert_perl_to_r( $l_eval_to_perl );

is( "$l_eval", "$l_perl_to_r", "Perl to R string representation equality");
is( "$l_eval", "$l_roundtrip", "Perl to R string representation equality");

ok( $l_eval->op_identical($l_perl_to_r), "Perl to R string: identical");
ok( $l_eval->op_identical($l_roundtrip), "Perl to R string: identical");
