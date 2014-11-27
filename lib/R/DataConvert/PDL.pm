package R::DataConvert::PDL;

use strict;
use warnings;

use Inline with => qw(R::Inline::Rinline R::Inline::Rpdl R::Inline::Rutil);
use File::Slurp;
use PDL::Types;
use Text::Template;
use R::Inline::TypeInfo;
use Scalar::Util qw(blessed);

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
	my $matrix = make_pdl_array( $data )->xchg(0,1);
	my $dimnames = $data->attrib('dimnames');
	if(defined $dimnames) {
		$matrix->hdr->{dimnames} = R::DataConvert->convert_r_to_perl( $dimnames );
	}
	return $matrix;
}

sub convert_r_to_perl_intsxp {
	my ($self, $data) = @_;
	return make_pdl_vector( $data, 1 );
}

sub convert_r_to_perl_realsxp {
	my ($self, $data) = @_;
	return make_pdl_vector( $data, 1 );
}


sub convert_perl_to_r {
	my ($self, $data) = @_;
	if( blessed($data) ) {
		if( $data->isa('PDL') ) {
			if( $data->ndims == 2 ) {
				return convert_perl_to_r_PDL_ndims_2(@_);
			} elsif( $data->ndims == 1 ) {
				return convert_perl_to_r_PDL_ndims_1(@_);
			} elsif( $data->ndims == 0 ) {
				return convert_perl_to_r_PDL_ndims_0(@_);
			} else {
				return convert_perl_to_r_PDL(@_);
			}
		}
	}
	die "could not convert";
}

sub convert_perl_to_r_PDL_ndims_0 {
	my ($self, $data) = @_;
	return make_r_array($data, 1, 0);
}

sub convert_perl_to_r_PDL_ndims_1 {
	my ($self, $data) = @_;
	return make_r_array($data, 1, 0);
}

sub convert_perl_to_r_PDL_ndims_2 {
	my ($self, $data) = @_;
	my $matrix = $data->xchg(0,1);
	# make the matrix physical
	my $r_matrix = make_r_array( $matrix->copy, 0, 1 );
	my $hdr = $data->hdr;
	if( exists $hdr->{dimnames} ) {
		$r_matrix->attrib( 'dimnames', R::DataConvert->convert_perl_to_r( $hdr->{dimnames} ) ) ;
	}
	return $r_matrix;
}

sub convert_perl_to_r_PDL {
	my ($self, $data) = @_;
	return make_r_array( $data, 0, 0 );
}

1;
__DATA__
__C__

#include "rintutil.c"

/* flat is used to make a vector rather than an array */
SEXP make_r_array( pdl* p, int flat, int matrix ) {
	SEXP r_dims, r_array;
	SV* ret;
	int dim_i, elem_i;
	size_t ndims;
{{{
	# TODO cover all types
	for my $type (qw(PDL_D PDL_L)) {
		$OUT .= qq{
		$pdl_to_r->{$type}{ctype} *datad_$type;
		$pdl_to_r->{$type}{ctype}  badv_$type;
		};
	}
}}}
	int r_type;
	PDL_Indx nelems;

	ndims = p->ndims;
	if( ndims == 0 ) {
		/* when the PDL is a simple scalar, then ndims == 0
		 * but there is still a value in the PDL
		 *
		 * see the "single scalar" case below
		 */
		ndims = 1;
	}

	r_type = PDL_to_R_type( p->datatype );

	PROTECT( r_dims = allocVector( INTSXP, ndims ) );

	if( matrix ) {
		/* TODO check if ndims == 2 */
		R_PreserveObject( r_array = allocMatrix( r_type, p->dims[0], p->dims[1] ) );
		nelems = p->dims[0] * p->dims[1];

	} else {
		nelems = 1;
		if( p->ndims == 0 && p->dims[0] == 0 ) {
			/* for pdl(1): single scalar */
			nelems = 1;
			INTEGER(r_dims)[dim_i] = 1;
		} else if( p->ndims == 1 && p->dims[0] == 0 ) {
			/* for pdl([]): Empty */
			nelems = 0;
			INTEGER(r_dims)[dim_i] = 0;
		} else {
			/* n-d array */
			for( dim_i = 0; dim_i < ndims; dim_i++ ) {
				INTEGER(r_dims)[dim_i] = p->dims[dim_i];
				nelems *= p->dims[dim_i];
			}
		}

		R_PreserveObject( r_array = allocVector(r_type, nelems) );

		if( !flat ) {
			/* creates data of R class 'array' */
			dimgets( r_array, r_dims ); /* set dimensions */
		}
	}

	/* TODO NOTE: on DESTROY, call R_ReleaseObject() */

	/* TODO support more types */
	switch(r_type) {
{{{
for my $type (qw(PDL_D PDL_L)) {
	$OUT .= qq%
	case $pdl_to_r->{$type}{sexptype}:
	datad_$type = ($pdl_to_r->{$type}{ctype} *) p->data;
	badv_$type = PDL->get_pdl_badvalue(p);
	memcpy( $pdl_to_r->{$type}{r_macro}(r_array), datad_$type, sizeof($pdl_to_r->{$type}{ctype}) * nelems );
	if( p->state & PDL_BADVAL ) {
		for( elem_i = 0; elem_i < nelems; elem_i++ ) {
			if(datad_${type}[elem_i] == badv_$type) {
				$pdl_to_r->{$type}{r_macro}(r_array)[elem_i] = $pdl_to_r->{$type}{r_NA};
			}
		}

	}
	break;
	%;
}
}}}
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

pdl* make_pdl_vector( SEXP r_vector, int flat ) {
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
	if( dims[0] == 1 && flat ) {
		/* if there is a single value, treat it as a scalar instead of
		 * as a vector.
		 */
		ndims = 0;
		dims[0] = 0;
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

