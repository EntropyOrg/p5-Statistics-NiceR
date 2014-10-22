package R::DataConvert::DataFrame;

use strict;
use warnings;

use R::DataConvert::PDL;
use Data::Frame;

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( ref $data ) {
		if( $data->R::Sexp::r_class eq 'data.frame' ) {
			...
		}
	}
	die "could not convert";
}

1;
