package R::DataConvert::DataFrame;

use strict;
use warnings;

use R::DataConvert::PDL;
use Data::Frame;

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( ref $data ) {
		if( $data->R::Sexp::r_class eq 'data.frame' ) {
			return make_data_frame($data);
		}
	}
	die "could not convert";
}

sub make_data_frame {
	my ($data) = @_;

	my $data_list = R::DataConvert::Perl::make_perl_list( $data );
	my $col_names = R::DataConvert->convert_r_to_perl($data->R::Sexp::attrib( "names" ));
	my $row_names = R::DataConvert->convert_r_to_perl($data->R::Sexp::attrib( "row.names" ));
	my $colspec = [ map {
			( $col_names->[$_] => $data_list->[$_] )
		} 0..@$col_names-1 ];
	my $df = Data::Frame->new( columns => $colspec );
	$df->row_names( $row_names );
	return $df;
}

1;
