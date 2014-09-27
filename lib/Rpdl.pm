package Rpdl;

use strict;
use warnings;

sub Inline {
	return unless $_[-1] eq 'C';
	+{
		AUTO_INCLUDE => <<EOC
EOC
		,
	};
}



1;
