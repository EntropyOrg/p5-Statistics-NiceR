package Statistics::NiceR::Inline::Rutil;

use strict;
use warnings;
use File::Basename;
use File::Spec;

sub Inline {
	return unless $_[-1] eq 'C';
	my $dir = File::Spec->rel2abs( dirname(__FILE__) );
	+{
		INC => "-I$dir",
		TYPEMAPS => File::Spec->catfile( $dir, 'typemap' ),
	};
}

1;
