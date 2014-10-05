package Rpdl;

use strict;
use warnings;
use PDL::LiteF;
use PDL::Core::Dev;

sub Inline {
	return unless $_[-1] eq 'C';
	+{
		INC           => &PDL_INCLUDE,
		TYPEMAPS      => &PDL_TYPEMAP,
		AUTO_INCLUDE  => &PDL_AUTO_INCLUDE('PDL'), # declarations
		BOOT          => &PDL_BOOT('PDL'),         # code for the XS boot section
	};
}



1;
