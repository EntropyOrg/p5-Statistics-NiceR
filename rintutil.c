#ifndef RINTUTIL_H
#define RINTUTIL_H

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

int R_to_PDL_type() {
	/* TODO */
}

SV* charsexp_to_pv(SEXP charsexp) {
	/* TODO */
	return NULL;
}

#endif /* RINTUTIL_H */
