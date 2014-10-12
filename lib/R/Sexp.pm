package R::Sexp;

use strict;
use warnings;

use Inline with => qw(Rinline Rpdl);
use Inline 'C';

1;

__DATA__
__C__

#include "rintutil.c"

size_t attrib( R__Sexp self ) {
	size_t len = LENGTH(self);
	return len;
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