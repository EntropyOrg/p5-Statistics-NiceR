package Rinterp;

use strict;
use warnings;

# TODO Rpdl shouldn't be included, but need for the use in rintutil.c
use Inline with => qw(R::Inline::Rinline R::Inline::Rpdl R::Inline::Rutil);
use Inline 'C';

our $loaded = -1;


sub import {
	Inline->init;
	unless($Rinterp::loaded == $$) {
		$Rinterp::loaded = $$;
		_start_R();
	}
}

END {
	_stop_R();
}

1;

__DATA__
__C__

#include "rintutil.c"

void _start_R() {
	char *localArgs[] = {"R", "--no-save","--silent"};
	Rf_initEmbeddedR(3, localArgs);
}

void _stop_R() {
	Rf_endEmbeddedR(0);
}

SEXP eval_SV( SV* eval_sv ) {
	SEXP tmp, eval_expr_v, ret;
	ParseStatus status;
	char* eval_str;
	int i;
	int error_occurred;

	eval_str = SvPV_nolen(eval_sv);

	PROTECT(tmp = mkString(eval_str));
	PROTECT(eval_expr_v = R_ParseVector(tmp, -1, &status, R_NilValue));
	if (status != PARSE_OK) {
		UNPROTECT(2); /* tmp, eval_expr_v */
		/* TODO throw exception */
		/*error("invalid call %s", eval_str);*/
		return R_NilValue_to_Perl;
	}
	/* Loop is needed here as EXPSEXP will be of length > 1 */
	for(i = 0; i < length(eval_expr_v); i++) {
		ret = R_tryEval(VECTOR_ELT(eval_expr_v, i), R_GlobalEnv, &error_occurred);
		if( error_occurred ) {
			UNPROTECT(2); /* tmp, eval_expr_v */
			/* TODO throw exception */
			return R_NilValue_to_Perl;
		}
	}
	UNPROTECT(2); /* tmp, eval_expr_v */
	PROTECT(ret);

	return ret;
}
