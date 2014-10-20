package R::DataConvert::Perl;

use strict;
use warnings;

use Inline with => qw(R::Inline::Rinline R::Inline::Rutil);
use Inline 'C';

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( ref $data ) {
		if( $data->R::Sexp::r_class eq 'character' ) {
			return make_perl_string( $data );
		} elsif( $data->R::Sexp::r_class eq 'list' ) {
			return [ map {
					my $curr = $_;
					  ref $curr eq 'R__Sexp'
					? R::DataConvert->convert_r_to_perl($curr)
					: $curr
				} @{ make_list( $data ) } ];
		}
	}
	die "could not convert";
}



1;
__DATA__
__C__

#include "rintutil.c"

SV* make_perl_string( R__Sexp r_char ) {
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

SV* make_list( R__Sexp r_list ) {
	size_t len;
	size_t i;
	R__Sexp e;
	SV* sv_tmp;
	AV* l;

	len = LENGTH(r_list);
	l = newAV();
	av_extend(l, len - 1); /* pre-allocate */
	for( i = 0; i < len; i++ ) {
		e = VECTOR_ELT(r_list, i);

		/*sv_tmp = newSVrv(e, "R__Sexp");*/
		sv_tmp = sv_newmortal();
		sv_setref_pv(sv_tmp, "R__Sexp", (void*)e); /* TODO fix the classname */

		av_store(l, i, SvREFCNT_inc(sv_tmp));
	}
	return newRV_inc(l);

}
