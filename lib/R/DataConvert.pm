package R::DataConvert;

use strict;
use warnings;

use R::Sexp;
use R::DataConvert::PDL;


sub convert_r_to_perl {
	&R::DataConvert::PDL::convert_r_to_perl;
}

sub convert_perl_to_r {
	&R::DataConvert::PDL::convert_perl_to_r;
}


1;
