#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use PDL::LiteF;
use Inline with => qw(Rinline Rpdl);
use Inline C => Config => TYPEMAPS => 'typemap';

use Rinterp;
use R::Sexp;
use Inline 'C' ;

my $p = sequence(3,3,3);
my $q = sequence(3,3,3);
# R:  ifelse( q %% 2, NA, q )
$q = $q->setbadif( $q % 2 );
use DDP; p $q;

Rinterp::start_R();

# R: pnorm( array(0:26, dim=c(3,3,3)) )

my $p_R = R::Sexp::make_r_array( $p );
my $q_R = R::Sexp::make_r_array( $q );

my $pnorm_R = call_pnorm( $p_R );
my $pnorm_q_R = call_pnorm( $q_R );

use DDP; p $pnorm_R;
use DDP; p $pnorm_R->R::Sexp::attrib;
my $pnorm_pdl = R::Sexp::make_pdl_array($pnorm_R);
my $pnorm_q_pdl = R::Sexp::make_pdl_array($pnorm_q_R);
use DDP; p $pnorm_pdl;
use DDP; p $pnorm_q_pdl;

Rinterp::stop_R();

__END__
__C__

#include "rintutil.c"

R__Sexp call_pnorm( R__Sexp r_array ) {
	R__Sexp pnorm, result;
	SV* ret;

	PROTECT( pnorm = install("pnorm") );

	result = eval(lang2(pnorm, r_array), R_GlobalEnv);

	UNPROTECT( 1 ); /* pnorm */

	return result;
}

