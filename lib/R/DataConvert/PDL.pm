package R::DataConvert::PDL;

use strict;
use warnings;

use Inline with => qw(R::Inline::Rinline R::Inline::Rpdl R::Inline::Rutil);
use File::Slurp;
use PDL::Types;
use Text::Template;
use R::Inline::TypeInfo;

## START OF Inline processing

sub _type_helper { R::Inline::TypeInfo->get_type_info($_[0]); }
my $pdl_to_r = {
		PDL_B   => _type_helper('CHARSXP'),

		PDL_S   => _type_helper('INTSXP'),
		PDL_US  => _type_helper('INTSXP'),
		PDL_L   => _type_helper('INTSXP'),
		PDL_IND => _type_helper('INTSXP'),
		PDL_LL  => _type_helper('INTSXP'),

		PDL_F   => _type_helper('REALSXP'),
		PDL_D   => _type_helper('REALSXP'),
};
for my $type (PDL::Types::typesrtkeys()) {
	$pdl_to_r->{$type}{ctype} = PDL::Types::typefld($type, 'ctype');
}

# read in template and fill
my $template_string = read_file(\*DATA);
$template_string =~ s/^__C__$//msg;
my $template = Text::Template->new(
	TYPE => 'STRING', SOURCE => $template_string,
	DELIMITERS => ['{{{', '}}}'], );
Inline->bind( C => $template->fill_in( HASH => { pdl_to_r => \$pdl_to_r }  ) );


## END OF Inline processing

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( R::DataConvert->check_r_sexp($data) ) {
		if( $data->r_class eq 'array' ) {
			return convert_r_to_perl_array(@_);
		} elsif( $data->r_class eq 'matrix' ) {
			return convert_r_to_perl_matrix(@_);
		} elsif( $data->r_class eq 'integer' ) {
			return convert_r_to_perl_intsxp(@_);
		} elsif( $data->r_class eq 'numeric' ) {
			return convert_r_to_perl_realsxp(@_);
		}
	}
	die "could not convert";
}

sub convert_r_to_perl_array {
	my ($self, $data) = @_;
	return make_pdl_array( $data );
}

sub convert_r_to_perl_matrix {
	my ($self, $data) = @_;
	# TODO does this make sense?
	return make_pdl_array( $data )->xchg(0,1);
}

sub convert_r_to_perl_intsxp {
	my ($self, $data) = @_;
	return make_pdl_vector( $data );
}

sub convert_r_to_perl_realsxp {
	my ($self, $data) = @_;
	return make_pdl_vector( $data );
}


sub convert_perl_to_r {
	my ($self, $data) = @_;
	if( blessed $data ) {
		if( $data->isa('PDL') ) {
			return make_r_array( $data );
		}
	}
	die "could not convert";
}

1;
__DATA__
__C__

#include "rintutil.c"

SEXP make_r_array( pdl* p ) {
	SEXP r_dims, r_array;
	SV* ret;
	int dim_i, elem_i;
{{{
	# TODO cover all types
	for my $type (qw(PDL_Double)) {
		$OUT .= qq{
		$type *datad;
		$type  badv;
		};
	}
}}}
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
	/* TODO NOTE: on DESTROY, call R_ReleaseObject() */

	/* TODO support more types */
	datad = p->data;
	memcpy( REAL(r_array), datad, sizeof(PDL_Double) * nelems );
	badv = PDL->get_pdl_badvalue(p);
	if( p->state & PDL_BADVAL ) {
		for( elem_i = 0; elem_i < nelems; elem_i++ ) {
			if( datad[elem_i] == badv ) {
				REAL(r_array)[elem_i] = NA_REAL; /* use r_NA */
			}
		}
	}

	UNPROTECT(1); /* r_dims */

	return r_array;
}

pdl* make_pdl_array( SEXP r_array ) {
	SEXP r_dims;
	size_t ndims;
	PDL_Indx* dims;
	pdl* p;
	int dim_i, elem_i;
	PDL_Indx nelems = 1;
{{{
	# TODO cover all types
	for my $type (qw(PDL_D PDL_L)) {
		$OUT .= qq%
		$pdl_to_r->{$type}{ctype} *datad_$type;
		$pdl_to_r->{$type}{ctype}  badv_$type;
		%;
	}
}}}
	int datatype;

	r_dims = getAttrib(r_array, R_DimSymbol);
	ndims = Rf_length(r_dims);

	Newx(dims, ndims, PDL_Indx);
	for( dim_i = 0; dim_i < ndims; dim_i++ ) {
		dims[dim_i] = INTEGER(r_dims)[dim_i];
		nelems *= dims[dim_i];
	}

	datatype = R_to_PDL_type(TYPEOF(r_array)); /* TODO : R_to_PDL_type */

	p = PDL->pdlnew();
	PDL->setdims (p, dims, ndims);  /* set dims */
	p->datatype = datatype;         /* and data type */
	PDL->allocdata (p);             /* allocate the data chunk */

	Safefree(dims);

	switch(datatype) {
{{{
for my $type (qw(PDL_D PDL_L)) {
	$OUT .= qq%
	case $type:
	datad_$type = ($pdl_to_r->{$type}{ctype} *) p->data;
	badv_$type = PDL->get_pdl_badvalue(p);
	memcpy( datad_$type, $pdl_to_r->{$type}{r_macro}(r_array), sizeof($pdl_to_r->{$type}{ctype}) * nelems );
	for( elem_i = 0; elem_i < nelems; elem_i++ ) {
		if( ISNA( $pdl_to_r->{$type}{r_macro}(r_array)[elem_i] ) ) {
			p->state |= PDL_BADVAL;
			datad_${type}[elem_i] = badv_$type;
		}
	}
	break;
	%;
}
}}}

	}

	return p;
}

pdl* make_pdl_vector( SEXP r_vector ) {
	size_t ndims;
	PDL_Indx* dims;
	pdl* p;
	int elem_i;
	PDL_Indx nelems = 1;
{{{
	# TODO cover all types
	for my $type (qw(PDL_D PDL_L)) {
		$OUT .= qq%
		$pdl_to_r->{$type}{ctype} *datad_$type;
		$pdl_to_r->{$type}{ctype}  badv_$type;
		%;
	}
}}}
	int datatype;

	ndims = 1;
	Newx(dims, ndims, PDL_Indx);
	dims[0] = nelems = Rf_length(r_vector);
	if( dims[0] == 1 ) {
		/* if there is a single value, treat it as a scalar instead of
		 * as a vector.
		 */
		ndims = 0;
	}

	datatype = R_to_PDL_type(TYPEOF(r_vector)); /* TODO : R_to_PDL_type */

	p = PDL->pdlnew();
	PDL->setdims (p, dims, ndims);  /* set dims */
	p->datatype = datatype;         /* and data type */
	PDL->allocdata (p);             /* allocate the data chunk */

	Safefree(dims);

	switch(datatype) {
{{{
for my $type (qw(PDL_D PDL_L)) {
	$OUT .= qq%
	case $type:
	datad_$type = ($pdl_to_r->{$type}{ctype} *) p->data;
	badv_$type = PDL->get_pdl_badvalue(p);
	memcpy( datad_$type, $pdl_to_r->{$type}{r_macro}(r_vector), sizeof($pdl_to_r->{$type}{ctype}) * nelems );
	for( elem_i = 0; elem_i < nelems; elem_i++ ) {
		if( ISNA( $pdl_to_r->{$type}{r_macro}(r_vector)[elem_i] ) ) {
			p->state |= PDL_BADVAL;
			datad_${type}[elem_i] = badv_$type;
		}
	}
	break;
	%;
}
}}}

	}

	return p;
}

