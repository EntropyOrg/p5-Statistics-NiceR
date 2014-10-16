package R::DataConvert::PDL;

use strict;
use warnings;
use Inline 'Pdlpp';

my $charsxp =  { sexptype => 'CHARSXP' };
my $intsxp = { sexptype => 'INTSXP' };
my $realxsp = { sexptype => 'REALSXP' };
my $pdl_to_r = {
		PDL_B   => $charsxp,

		PDL_S   => $intsxp,
		PDL_US  => $intsxp,
		PDL_L   => $intsxp,
		PDL_IND => $intsxp,
		PDL_LL  => $intsxp,

		PDL_F   => $realxsp,
		PDL_D   => $realxsp,
};

# TODO

1;
__DATA__
__Pdlpp__


