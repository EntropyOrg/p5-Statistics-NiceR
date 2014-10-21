package R::Sexp;

use strict;
use warnings;

use Inline with => qw(R::Inline::Rinline R::Inline::Rpdl R::Inline::Rutil);
use Inline 'C';

1;

__DATA__
__C__

#include "rintutil.c"

R__Sexp eval_lang2( R__Sexp self, char* func_name ) {
	R__Sexp r_func_name, result;

	PROTECT( r_func_name = install(func_name) );

	PROTECT( result = eval(lang2(r_func_name, self), R_GlobalEnv) ); /* TODO UNPROTECT */

	UNPROTECT( 1 ); /* r_func_name */

	return result;
}

R__Sexp attrib( R__Sexp self, char* name ) {
	R__Sexp r_name;
	R__Sexp attr;

	PROTECT( r_name = mkString(name) );

	PROTECT( attr = getAttrib(self, r_name) ); /* UNPROTECT at DESTROY */

	UNPROTECT(1); /* r_name */

	return attr;
}

char* r_class( R__Sexp self ) {
	/* TODO */
	/* see note about R_data_class in rpy2/rpy/rinterface/sexp.c
	 *
	 * > R_data_class is not exported, although R's own
	 * > package "methods" needs it as part of the API
	 */
	return strsxp_to_charptr(
			R_data_class(self, (Rboolean) 0)
		);
}

char* r_typeof( R__Sexp self ) {
	/* TODO */
	R__Sexp r_typeof, result;

	PROTECT( r_typeof = install("typeof") );

	result = eval(lang2(r_typeof, self), R_GlobalEnv);

	UNPROTECT( 1 ); /* r_typeof */

	return strsxp_to_charptr( result );
}

