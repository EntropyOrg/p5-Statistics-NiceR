#ifndef RINTUTIL_H
#define RINTUTIL_H

typedef SEXP R__Sexp;

#define R_NilValue_to_Perl (&PL_sv_undef)

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
  return -1; /* TODO exception */
}

int R_to_PDL_type(SEXPTYPE r_type) {
	switch(r_type) {
		case REALSXP: return PDL_D; break;

		case LGLSXP:
		case INTSXP: return PDL_L; /* TODO is this correct? should I check: .Machine$integer.max */

		case CPLXSXP: return -1; /* TODO map to PDL::Complex */

		case STRSXP: return -1; /* TODO map to string or PDL::Char */
  }
  return -1; /* TODO exception */
}

char* strsxp_elt_to_charptr(SEXP strsexp, size_t elt) {
	int n;
	size_t total_len;
	char* temp;
	char* str;

	n = LENGTH(strsexp);
	/* TODO die unless 0 <= elt < n */
	temp = CHAR(STRING_ELT(strsexp, elt));

	total_len = strlen( temp );

	Newx(str, total_len + 1, char); /* TODO check for str != NULL */

	strncpy(str, temp, total_len);

	str[total_len] = '\0';

	return str;
}

char* strsxp_to_charptr(SEXP strsexp) {
	return strsxp_elt_to_charptr(strsexp, 0);
}

#endif /* RINTUTIL_H */
