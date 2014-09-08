#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use PDL::LiteF;
use PDL::Core::Dev;
use Inline with => 'Rinline';
use Inline C => Config => # later: with => 'PDL'
	INC           => &PDL_INCLUDE,
	TYPEMAPS      => &PDL_TYPEMAP,
	AUTO_INCLUDE  => &PDL_AUTO_INCLUDE, # declarations
	BOOT          => &PDL_BOOT;         # code for the XS boot section

use Inline 'C' ;

my $p = sequence(3,3,3);

start_R();

my $p_R = make_r_array( $p );
use DDP; p $p_R;

my $pnorm_R = call_pnorm( $p_R );

stop_R();

__END__
__C__

void start_R() {
	char *localArgs[] = {"R", "--no-save","--silent"};
	Rf_initEmbeddedR(3, localArgs);
}

SEXPTYPE PDL_to_R_type( int pdl_type ) {
	switch(pdl_type) {
		case PDL_B:
			return CHARSXP;
		case PDL_S:
		case PDL_US:
		case PDL_L:
		case PDL_IND:
		case PDL_LL:
			return INTSXP;
		case PDL_F:
		case PDL_D:
			return REALSXP;
	}
}

SV* make_r_array( pdl* p ) {
	SEXP r_dims, r_array;
	SV* ret;
	int dim_i;

	int r_type = PDL_to_R_type( p->datatype );

	PROTECT( r_dims = allocVector( INTSXP, p->ndims ) );
	PDL_Indx nelems = 1;
	for( dim_i = 0; dim_i < p->ndims; dim_i++ ) {
		INTEGER(r_dims)[dim_i] = p->dims[dim_i];
		nelems *= p->dims[dim_i];
	}

	R_PreserveObject(  r_array = allocVector(r_type, nelems) );
	dimgets( r_array, r_dims ); /* set dimensions */
	/* NOTE: on DESTROY, call R_ReleaseObject() */

	UNPROTECT(1); /* r_dims */

	ret = sv_newmortal();
	sv_setref_pv(ret, "RArray", (void*)r_array);
	printf("1. %d\n", r_array);

	return SvREFCNT_inc(ret);
}

SV* call_pnorm( SV* r_sv ) {
	SEXP pnorm, result;
	SV* ret;

	SEXP r_array = SvPV_nolen(r_sv);
	printf("2. %d\n", r_sv);


	PROTECT( pnorm = install("pnorm") );

	result = eval(lang2(pnorm, r_array), R_GlobalEnv);

	UNPROTECT( 1 ); /* pnorm */
	return NULL;

	//ret = sv_newmortal();
	//sv_setref_pv(ret, "RArray", (void*)result);

	//return ret;
}

pdl* make_pdl_array( SEXP r_array ) {

}

void stop_R() {
	Rf_endEmbeddedR(0);
}
