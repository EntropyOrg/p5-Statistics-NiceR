package Rinterp;

use strict;
use warnings;

use Inline with => qw(Rinline);
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

R__Sexp eval_SV( SV* eval_sv ) {
	R__Sexp tmp, eval_expr_v, ret;
	ParseStatus status;
	char* eval_str;
	int i;

	eval_str = SvPV_nolen(eval_sv);

	PROTECT(tmp = mkString(eval_str));
	PROTECT(eval_expr_v = R_ParseVector(tmp, -1, &status, R_NilValue));
	if (status != PARSE_OK) {
		UNPROTECT(2); /* tmp, eval_expr_v */
		/*error("invalid call %s", eval_str);*/
		return R_NilValue_to_Perl;
	}
	/* PROTECT(ret = R_tryEval(VECTOR_ELT(e,0), R_GlobalEnv, NULL)); */
	/* Loop is needed here as EXPSEXP will be of length > 1 */
	for(i = 0; i < length(eval_expr_v); i++) {
		ret = eval(VECTOR_ELT(eval_expr_v, i), R_GlobalEnv);
	}
	UNPROTECT(2);

	return ret;
}
