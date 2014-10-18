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
		}
	}
	die "could not convert";
}



1;
__DATA__
__C__

#include "rintutil.c"

char* make_perl_string( R__Sexp r_char ) {
	return strsxp_to_charptr( (SEXP) r_char );
}

