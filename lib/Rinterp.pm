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
		return R_NilValue;
	}
	/* Loop is needed here as EXPSEXP will be of length > 1 */
	for(i = 0; i < length(eval_expr_v); i++) {
		ret = R_tryEval(VECTOR_ELT(eval_expr_v, i), R_GlobalEnv, &error_occurred);
		if( error_occurred ) {
			UNPROTECT(2); /* tmp, eval_expr_v */
			/* TODO throw exception */
			return R_NilValue;
		}
	}
	UNPROTECT(2); /* tmp, eval_expr_v */
	PROTECT(ret);

	return ret;
}

SEXP R_get_function(SV* self, char* fname) {
	return Rf_install(fname);
}


SEXP R_call_function(SV* self, SEXP function, SV* args_ref) {
	SEXP e; /* expression */
	SEXP next; /* pairlist iterator */
	AV* args; /* the array in args_ref */
	AV* arg_av; /* SV container for SEXP */
	SV* arg_sv; /* SV container for SEXP */
	IV arg_intptr; /* integer pointer to SEXP */
	SEXP arg; /* current argument */
	SEXP ret; /* return value */
	int error_occurred; /* error checking boolean */

	int num_args; /* number of arguments */
	int arg_idx; /* argument list iterator */

	/* TODO check svtype for args == AV */
	args = (AV*) SvRV( args_ref );
	num_args = av_len( args ) + 1;

	/* (num_args + 1) slots: function name + args */
	PROTECT(e = allocVector(LANGSXP, num_args + 1));

	SETCAR(e, function); /* function at the beginning of the list */
	if( num_args > 0 ) {
		next = CDR(e); /* begin argument list */

		for( arg_idx = 0; arg_idx < num_args; arg_idx++ ) {
			arg_av = (AV*) *( av_fetch( args, arg_idx, 0 ) );
			/* TODO make sure we can handle keys: currently we only look at the first item (index 0) */
			arg_sv = *(av_fetch( SvRV(arg_av), 0, 0 ));
			arg_intptr = SvIV( (SV*) SvRV(arg_sv) ); /* get integer pointer out of SV */
			arg = INT2PTR(SEXP, arg_intptr ); /* cast the integer to a pointer */

			/* key is for using calls with arg names */
			//val = hv_iternextsv(hv, &key, &len);
			/* TODO  deal with keys */

			SETCAR(next, arg);

			/* TODO deal with keys */
			/*if(key && key[0]) {
				SET_TAG(next, Rf_install(key));
			}*/

			next = CDR(next);
		}
	}
	/*[>DEBUG<]Rf_PrintValue(e);*/

	ret = R_tryEval(e, R_GlobalEnv, &error_occurred );
	UNPROTECT(1); /* e */
	if( error_occurred ) {
		/* TODO error checking */
		return R_NilValue;
	}
	PROTECT(ret);
}
