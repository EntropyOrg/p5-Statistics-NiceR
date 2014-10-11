package Rinterp;

use strict;
use warnings;

use Inline with => qw(Rinline);
use Inline 'C';

our $loaded = -1;


sub import {
	Inline->init;
	unless($Rinterp::loaded == $$) {
		$Rinterp::loaded = $$;
		_start_R();
	}
}

END {
	_stop_R();
}

1;

__DATA__
__C__

void _start_R() {
	char *localArgs[] = {"R", "--no-save","--silent"};
	Rf_initEmbeddedR(3, localArgs);
}

void _stop_R() {
	Rf_endEmbeddedR(0);
}
