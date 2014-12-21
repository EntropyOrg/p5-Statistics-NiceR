package Statistics::NiceR::DataConvert::Factor;

use strict;
use warnings;

use Statistics::NiceR::DataConvert::PDL;
use PDL::Factor;
use Scalar::Util qw(blessed);
use Statistics::NiceR::Error;

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( Statistics::NiceR::DataConvert->check_r_sexp($data) ) {
		if( $data->r_class eq 'factor' ) {
			return convert_r_to_perl_factor(@_);
		}
	}
	Statistics::NiceR::Error::Conversion::RtoPerl->throw;
}

sub convert_r_to_perl_factor {
	my ($self, $data) = @_;

	my $r_levels = $data->attrib( "levels" );
	my $levels = Statistics::NiceR::DataConvert->convert_r_to_perl( $r_levels);
	my $data_int = Statistics::NiceR::DataConvert::PDL->convert_r_to_perl_intsxp( $data );
	unshift @$levels, undef; # undef for index 0 for levels: because R starts at 1
	my $f = PDL::Factor->new( integer => $data_int->unpdl, levels => $levels );
	return $f;
}

sub convert_perl_to_r {
	my ($self, $data) = @_;
	if( blessed($data) && $data->isa('PDL::Factor') ) {
		return convert_perl_to_r_factor(@_);
	}
	Statistics::NiceR::Error::Conversion::PerltoR->throw;
}

sub convert_perl_to_r_factor {
	my ($self, $data) = @_;
	my $pdl_data = $data->{PDL}->copy;
	my $levels = $data->levels;
	if( not defined $levels->[0] ) {
		shift @$levels; # TODO this is because R is 1-based and we put in an undef when converting
	} else {
		$pdl_data += 1; # we increment so that 0 -> 1, 1 -> 2, etc.
	}
	my $fac_r = Statistics::NiceR::DataConvert::PDL->convert_perl_to_r_PDL_ndims_1($pdl_data);
	$fac_r->attrib( 'levels', Statistics::NiceR::DataConvert->convert_perl_to_r( $levels ) );
	$fac_r->attrib( 'class', Statistics::NiceR::DataConvert->convert_perl_to_r('factor') );
	return $fac_r;
}

1;
