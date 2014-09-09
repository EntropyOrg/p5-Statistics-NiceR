#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use PDL::LiteF;
use PDL::Core::Dev;
use Inline with => 'Rinline';
use Inline C => Config => TYPEMAPS => 'typemap';
use Inline C => Config => # later: with => 'PDL'
	INC           => &PDL_INCLUDE,
	TYPEMAPS      => &PDL_TYPEMAP,
	AUTO_INCLUDE  => &PDL_AUTO_INCLUDE, # declarations
	BOOT          => &PDL_BOOT;         # code for the XS boot section

use Inline 'C' ;

my $p = sequence(3,3,3);

start_R();

# R: pnorm( array(0:26, dim=c(3,3,3)) )

my $p_R = make_r_array( $p );
my $pnorm_R = call_pnorm( $p_R );
my $pnorm_pdl = make_pdl_array($pnorm_R);
use DDP; p $pnorm_pdl;

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

SEXP make_r_array( pdl* p ) {
	SEXP r_dims, r_array;
	SV* ret;
	int dim_i, elem_i;
	PDL_Double* datad;

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

	datad = p->data;
	memcpy( REAL(r_array), datad, sizeof(PDL_Double) * nelems );

	UNPROTECT(1); /* r_dims */

	return r_array;
}

SEXP call_pnorm( SEXP r_array ) {
	SEXP pnorm, result;
	SV* ret;

	PROTECT( pnorm = install("pnorm") );

	result = eval(lang2(pnorm, r_array), R_GlobalEnv);

	UNPROTECT( 1 ); /* pnorm */

	return result;
}

pdl* make_pdl_array( SEXP r_array ) {
	SEXP r_dims;
	int ndims;
	PDL_Indx* dims;
	pdl* p;
	int dim_i, elem_i;
	PDL_Indx nelems = 1;
	PDL_Double *datad;
	int datatype;

	r_dims = getAttrib(r_array, R_DimSymbol);
	ndims = Rf_length(r_dims);

	Newx(dims, ndims, PDL_Indx);
	for( dim_i = 0; dim_i < ndims; dim_i++ ) {
		dims[dim_i] = INTEGER(r_dims)[dim_i];
		nelems *= dims[dim_i];
	}

	datatype = PDL_D; /* TODO */

	p = PDL->pdlnew();
	PDL->setdims (p, dims, ndims);  /* set dims */
	p->datatype = datatype;         /* and data type */
	PDL->allocdata (p);             /* allocate the data chunk */

	datad = (PDL_Double *) p->data;
	memcpy( datad, REAL(r_array), sizeof(PDL_Double) * nelems );

	return p;
}

void stop_R() {
	Rf_endEmbeddedR(0);
}
