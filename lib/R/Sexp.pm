package R::Sexp;

use strict;
use warnings;

use Inline with => qw(R::Inline::Rinline R::Inline::Rpdl R::Inline::Rutil);
use Inline 'C';

1;

__DATA__
__C__

#include "rintutil.c"

size_t attrib( R__Sexp self ) {
	size_t len = LENGTH(self);
	return len;
}

char* r_class( R__Sexp self ) {
	/* TODO */
	return strsxp_to_charptr(
			R_data_class(self, (Rboolean) 0)
		);
}

