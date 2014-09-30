package R::Sexp;

use strict;
use warnings;

use Inline with => qw(Rinline Rpdl);
use Inline C => <<EOC;
typedef SEXP R__Sexp;

size_t attrib( R__Sexp self ) {
	size_t len = LENGTH(self);
	return len;
}
EOC
;

1;
