package R::Inline::Rinline;

use strict;
use warnings;
use File::Basename;
use File::Spec;

sub import {
	unless( $ENV{R_HOME} ) {
		my $Rhome = `R RHOME`;
		chomp $Rhome;
		$ENV{R_HOME} = $Rhome;
	}
}

sub Inline {
	return unless $_[-1] eq 'C';
	import();
	my $R_inc = `R CMD config --cppflags`;
	my $R_libs   = `R CMD config --ldflags`;
	my $dir = File::Spec->rel2abs( dirname(__FILE__) );
	+{
		INC => $R_inc,
		LIBS => $R_libs,
		TYPEMAPS => File::Spec->catfile( $dir, 'typemap' ),
		AUTO_INCLUDE => q{
			#include <Rinternals.h>
			#include <Rembedded.h>
			#include <R_ext/Parse.h> },
	};
}

1;
