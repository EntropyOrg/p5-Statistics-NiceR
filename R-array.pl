#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use PDL::LiteF;
use PDL::Core::Dev;
use Inline with => qw(Rinline Rpdl);
use Inline C => Config => TYPEMAPS => 'typemap';
use Inline C => Config => # later: with => 'PDL'
	INC           => &PDL_INCLUDE,
	TYPEMAPS      => &PDL_TYPEMAP,
	AUTO_INCLUDE  => &PDL_AUTO_INCLUDE, # declarations
	BOOT          => &PDL_BOOT;         # code for the XS boot section

use R::Sexp;
use Inline 'C' ;

my $p = sequence(3,3,3);
my $q = sequence(3,3,3);
# R:  ifelse( q %% 2, NA, q )
$q = $q->setbadif( $q % 2 );
use DDP; p $q;

start_R();

# R: pnorm( array(0:26, dim=c(3,3,3)) )

my $p_R = make_r_array( $p );
my $q_R = make_r_array( $q );

my $pnorm_R = call_pnorm( $p_R );
my $pnorm_q_R = call_pnorm( $q_R );

use DDP; p $pnorm_R;
use DDP; p $pnorm_R->R::Sexp::attrib;
my $pnorm_pdl = make_pdl_array($pnorm_R);
my $pnorm_q_pdl = make_pdl_array($pnorm_q_R);
use DDP; p $pnorm_pdl;
use DDP; p $pnorm_q_pdl;

stop_R();

__END__
__C__

typedef SEXP R__Sexp;

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

R__Sexp make_r_array( pdl* p ) {
	R__Sexp r_dims, r_array;
	SV* ret;
	int dim_i, elem_i;
	PDL_Double* datad;
	PDL_Double badv;
	int r_type;
	PDL_Indx nelems;

	r_type = PDL_to_R_type( p->datatype );

	PROTECT( r_dims = allocVector( INTSXP, p->ndims ) );
	nelems = 1;
	for( dim_i = 0; dim_i < p->ndims; dim_i++ ) {
		INTEGER(r_dims)[dim_i] = p->dims[dim_i];
		nelems *= p->dims[dim_i];
	}

	R_PreserveObject(  r_array = allocVector(r_type, nelems) );
	dimgets( r_array, r_dims ); /* set dimensions */
	/* NOTE: on DESTROY, call R_ReleaseObject() */

	datad = p->data;
	memcpy( REAL(r_array), datad, sizeof(PDL_Double) * nelems );
	badv = PDL->get_pdl_badvalue(p);
	if( p->state & PDL_BADVAL ) {
		for( elem_i = 0; elem_i < nelems; elem_i++ ) {
			if( datad[elem_i] == badv ) {
				REAL(r_array)[elem_i] = NA_REAL;
			}
		}
	}

	UNPROTECT(1); /* r_dims */

	return r_array;
}

pdl* make_pdl_array( R__Sexp r_array ) {
	R__Sexp r_dims;
	size_t ndims;
	PDL_Indx* dims;
	pdl* p;
	int dim_i, elem_i;
	PDL_Indx nelems = 1;
	PDL_Double *datad;
	PDL_Double badv;
	int datatype;

	r_dims = getAttrib(r_array, R_DimSymbol);
	ndims = Rf_length(r_dims);

	Newx(dims, ndims, PDL_Indx);
	for( dim_i = 0; dim_i < ndims; dim_i++ ) {
		dims[dim_i] = INTEGER(r_dims)[dim_i];
		nelems *= dims[dim_i];
	}

	datatype = PDL_D; /* TODO : R_to_PDL_type */

	p = PDL->pdlnew();
	PDL->setdims (p, dims, ndims);  /* set dims */
	p->datatype = datatype;         /* and data type */
	PDL->allocdata (p);             /* allocate the data chunk */

	Safefree(dims);

	datad = (PDL_Double *) p->data;
	badv = PDL->get_pdl_badvalue(p);
	memcpy( datad, REAL(r_array), sizeof(PDL_Double) * nelems );
	for( elem_i = 0; elem_i < nelems; elem_i++ ) {
		if( ISNA( REAL(r_array)[elem_i] ) ) {
			p->state |= PDL_BADVAL;
			datad[elem_i] = badv;
		}
	}

	return p;
}

void start_R() {
	char *localArgs[] = {"R", "--no-save","--silent"};
	Rf_initEmbeddedR(3, localArgs);
}

R__Sexp call_pnorm( R__Sexp r_array ) {
	R__Sexp pnorm, result;
	SV* ret;

	PROTECT( pnorm = install("pnorm") );

	result = eval(lang2(pnorm, r_array), R_GlobalEnv);

	UNPROTECT( 1 ); /* pnorm */

	return result;
}

void stop_R() {
	Rf_endEmbeddedR(0);
}
