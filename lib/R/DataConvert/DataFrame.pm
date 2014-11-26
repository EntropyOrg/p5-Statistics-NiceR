package R::DataConvert::DataFrame;

use strict;
use warnings;

use R::DataConvert::PDL;
use Data::Frame;
use Scalar::Util qw(blessed);

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( R::DataConvert->check_r_sexp($data) ) {
		if( $data->r_class eq 'data.frame' ) {
			return convert_r_to_perl_dataframe(@_);
		}
	}
	die "could not convert";
}

sub convert_r_to_perl_dataframe {
	my ($self, $data) = @_;

	my $data_list = R::DataConvert::Perl->convert_r_to_perl_vecsxp( $data );
	my $col_names = R::DataConvert->convert_r_to_perl($data->attrib( "names" ));
	my $row_names = R::DataConvert->convert_r_to_perl($data->attrib( "row.names" ));
	my $colspec = [ map {
			( $col_names->[$_] => $data_list->[$_] )
		} 0..@$col_names-1 ];
	my $df = Data::Frame->new( columns => $colspec );
	$df->row_names( $row_names );
	return $df;
}

sub convert_perl_to_r {
	my ($self, $data) = @_;
	if( blessed($data) && $data->isa('Data::Frame') ) {
		...
	}
	die "could not convert";
}

1;
