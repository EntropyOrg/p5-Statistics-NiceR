package R::DataConvert::Factor;

use strict;
use warnings;

use R::DataConvert::PDL;
use PDL::Factor;

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( ref $data ) {
		if( $data->r_class eq 'factor' ) {
			return convert_r_to_perl_factor(@_);
		}
	}
	die "could not convert";
}

sub convert_r_to_perl_factor {
	my ($self, $data) = @_;

	my $r_levels = $data->attrib( "levels" );
	my $levels = R::DataConvert->convert_r_to_perl( $r_levels);
	# TODO make this cleaner, e.g. give a class override?
	my $data_int = R::DataConvert::PDL::make_pdl_vector( $data );
	unshift @$levels, undef; # undef for index 0 for levels: because R starts at 1
	my $f = PDL::Factor->new( integer => $data_int->unpdl, levels => $levels );
	return $f;
}

1;
