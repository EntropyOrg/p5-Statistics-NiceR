#ifndef RINTUTIL_H
#define RINTUTIL_H

char* strsxp_elt_to_charptr(SEXP strsexp, size_t elt) {
	int n;
	size_t total_len;
	const char* temp;
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
