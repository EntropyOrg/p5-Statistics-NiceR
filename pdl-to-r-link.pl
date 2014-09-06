#!/usr/bin/env perl

use strict;
use warnings;

# NOTE
# http://stackoverflow.com/questions/2463437/r-from-c-simplest-possible-helloworld

BEGIN {
	my $Rhome = `R RHOME`;
	chomp $Rhome;
	$ENV{R_HOME} = $Rhome;
}
my $R_inc = `R CMD config --cppflags`;
my $R_libs   = `R CMD config --ldflags`;

use Inline;

Inline->bind( C => <<'END_OF_C'
int run_R() {
	char *localArgs[] = {"R", "--no-save","--silent"};
	SEXP e, tmp, ret;
	ParseStatus status;
	int i;

	Rf_initEmbeddedR(3, localArgs);


	/* EXAMPLE #1 */

	/* Create the R expressions "rnorm(10)" with the R API.*/
	PROTECT(e = allocVector(LANGSXP, 2));
	tmp = findFun(install("rnorm"), R_GlobalEnv);
	SETCAR(e, tmp);
	SETCADR(e, ScalarInteger(10));

	/* Call it, and store the result in ret */
	PROTECT(ret = R_tryEval(e, R_GlobalEnv, NULL));

	/* Print out ret */
	printf("EXAMPLE #1 Output: ");
	for (i=0; i<length(ret); i++){
	    printf("%f ",REAL(ret)[i]);
	}
	printf("\n");

	UNPROTECT(2);


	/* EXAMPLE 2*/

	/* Parse and eval the R expression "rnorm(10)" from a string */
	PROTECT(tmp = mkString("rnorm(10)"));
	PROTECT(e = R_ParseVector(tmp, -1, &status, R_NilValue));
	PROTECT(ret = R_tryEval(VECTOR_ELT(e,0), R_GlobalEnv, NULL));

	/* And print. */
	printf("EXAMPLE #2 Output: ");
	for (i=0; i<length(ret); i++){
	    printf("%f ",REAL(ret)[i]);
	}
	printf("\n");

	UNPROTECT(3);
	Rf_endEmbeddedR(0);
	return(0);
}
END_OF_C
=>  INC => $R_inc
=> LIBS => $R_libs
=> AUTO_INCLUDE => q{
 #include <Rinternals.h>
 #include <Rembedded.h>
 #include <R_ext/Parse.h>
});

run_R();
