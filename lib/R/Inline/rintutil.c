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
}

int R_to_PDL_type() {
	/* TODO */
}

char* strsxp_to_charptr(SEXP strsexp) {
	int n, i;
	size_t total_len;
	size_t temp_idx;
	size_t temp_len;
	char* temp;
	char* str;

	n = LENGTH(strsexp);
	total_len = 0;
	for(i = 0; i < n; i++) {
		temp = CHAR(STRING_ELT(strsexp, i));
		total_len += strlen(temp);
	}

	Newx(str, total_len + 1, char); /* TODO check for str != NULL */

	temp_idx = 0;
	for(i = 0; i < n; i++) {
		temp = CHAR(STRING_ELT(strsexp, i));
		temp_len = strlen( temp );
		strncpy(&str[temp_idx], temp, temp_len);
		temp_idx += temp_len;
	}
	str[total_len] = '\0';

	return str;
}

#endif /* RINTUTIL_H */
