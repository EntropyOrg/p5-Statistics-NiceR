#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use PDL::LiteF;
use Inline with => qw(Rinline Rpdl);
use Inline C => Config => TYPEMAPS => 'typemap';

use R;
use R::Sexp;
use Inline 'C' ;

# basic test
sub p_run {
	# R: pnorm( array(0:26, dim=c(3,3,3)) )
	my $p = sequence(3,3,3);
	my $p_R = R::Sexp::make_r_array( $p );

	my $pnorm_R = call_pnorm( $p_R );

	use DDP; p $pnorm_R;
	use DDP; p $pnorm_R->R::Sexp::attrib;

	my $pnorm_pdl = R::Sexp::make_pdl_array($pnorm_R);
	use DDP; p $pnorm_pdl;
}

# test BAD values
sub q_run {
	my $q = sequence(3,3,3);
	# R:  ifelse( q %% 2, NA, q )
	$q = $q->setbadif( $q % 2 );
	use DDP; p $q;

	my $q_R = R::Sexp::make_r_array( $q );
	my $pnorm_q_R = call_pnorm( $q_R );
	my $pnorm_q_pdl = R::Sexp::make_pdl_array($pnorm_q_R);
	use DDP; p $pnorm_q_pdl;

}

sub eval_SV_run {
	# TODO handle errors
	#my $array_R = eval_SV('as.real( array(0:26, dim=c(3,3,3)) )');
	my $array_R = Rinterp::eval_SV('array(as.double(0:26), dim=c(3,3,3))');

	use DDP; p $array_R;

	my $array = R::Sexp::make_pdl_array( $array_R );

	use DDP; p $array;
}


#p_run;
#q_run;
eval_SV_run;


__END__
__C__

#include "rintutil.c"

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

R__Sexp call_pnorm( R__Sexp r_array ) {
	R__Sexp pnorm, result;
	SV* ret;

	PROTECT( pnorm = install("pnorm") );

	result = eval(lang2(pnorm, r_array), R_GlobalEnv);

	UNPROTECT( 1 ); /* pnorm */

	return result;
}

