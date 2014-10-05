package Rinterp;

use strict;
use warnings;

use Inline with => qw(Rinline);
use Inline 'C';

1;

__DATA__
__C__

void start_R() {
	char *localArgs[] = {"R", "--no-save","--silent"};
	Rf_initEmbeddedR(3, localArgs);
}

void stop_R() {
	Rf_endEmbeddedR(0);
}
