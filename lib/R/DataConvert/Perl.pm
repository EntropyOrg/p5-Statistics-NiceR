package R::DataConvert::Perl;

use strict;
use warnings;

use Inline with => qw(R::Inline::Rinline R::Inline::Rutil);
use PDL; # XXX using PDL
use Inline 'C';
use Scalar::Util qw(reftype);
use Scalar::Util::Numeric qw(isint isfloat);
use List::AllUtils;

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( R::DataConvert->check_r_sexp($data) ) {
		if( $data->r_class eq 'character' ) {
			return convert_r_to_perl_charsxp(@_);
		} elsif( $data->r_class eq 'list' ) {
			return convert_r_to_perl_vecsxp(@_);
		}
	}
	die "could not convert";
}

sub convert_r_to_perl_charsxp {
	my ($self, $data) = @_;
	return make_perl_string( $data );
}

sub convert_r_to_perl_vecsxp {
	my ($self, $data) = @_;
	return [ map {
			my $curr = $_;
			  ref $curr eq 'R::Sexp'
			? R::DataConvert->convert_r_to_perl($curr)
			: $curr
		} @{ make_list( $data ) } ];
}

sub convert_perl_to_r {
	my ($self, $data) = @_;
	if( blessed $data && $data->isa('R::Sexp') ) {
		return convert_perl_to_r_sexp(@_);
	} elsif( isint($data) ) {
		return convert_perl_to_r_integer(@_);
	} elsif( isfloat($data) ) {
		return convert_perl_to_r_float(@_);
	} else {
		if( ref $data ) {
			if( reftype($data) eq 'ARRAY' ) {
				if( List::AllUtils::all { isint($_) } @$data ) {
					return convert_perl_to_r_integer(@_);
				} elsif( List::AllUtils::all { isfloat($_) } @$data ) {
					return convert_perl_to_r_float(@_);
				} else {
					return convert_perl_to_r_array(@_);
				}
			} elsif( reftype($data) eq 'HASH' ) {
				# use R's env()
				...
			} elsif( reftype($data) eq 'SCALAR' ) {
				# boolean, Data::Perl, etc.
				...
			}
		} else {
			# scalar (not a reference), string
			# XXX I think
			...
		}
	}
	die "could not convert";
}

sub convert_perl_to_r_array {
	...  # make an R list (recursively)
}

sub convert_perl_to_r_sexp {
	my ($self, $data) = @_;
	return $data;
}

sub convert_perl_to_r_integer {
	my ($self, $data) = @_;
	# XXX using PDL
	R::DataConvert::PDL->convert_r_to_perl( long($data) );
}

sub convert_perl_to_r_float {
	my ($self, $data) = @_;
	# XXX using PDL
	R::DataConvert::PDL->convert_r_to_perl( double($data) );
}


1;
__DATA__
__C__

#include "rintutil.c"

SV* make_perl_string( SEXP r_char ) {
	size_t len;
	size_t i;
	AV* l;
	SV* sv_tmp;
	char* s;
	size_t s_len;

	len = LENGTH(r_char);
	if( 0 == len ) {
		return R_NilValue_to_Perl;
	} else if( 1 == len ) {
		s = CHAR(STRING_ELT(r_char, 0));
		s_len = strlen(s);
		return SvREFCNT_inc( newSVpv(s, s_len) );
	} else {
		l = newAV();
		av_extend(l, len - 1); /* pre-allocate */
		for( i = 0; i < len; i++ ) {
			s = CHAR(STRING_ELT(r_char, i));
			s_len = strlen(s);

			sv_tmp = newSVpv(s, s_len);
			av_store(l, i, SvREFCNT_inc(sv_tmp));
		}
		return newRV_inc(l);
	}

	return R_NilValue_to_Perl; /* shouldn't get here */
}

SV* make_list( SEXP r_list ) {
	size_t len;
	size_t i;
	SEXP e;
	SV* sv_tmp;
	AV* l;

	len = LENGTH(r_list);
	l = newAV();
	av_extend(l, len - 1); /* pre-allocate */
	for( i = 0; i < len; i++ ) {
		e = VECTOR_ELT(r_list, i);

		sv_tmp = sv_newmortal();
		sv_setref_pv(sv_tmp, "R::Sexp", (void*)e);

		av_store(l, i, SvREFCNT_inc(sv_tmp));
	}
	return newRV_inc(l);

}
