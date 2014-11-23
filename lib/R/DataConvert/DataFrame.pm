package R::DataConvert::DataFrame;

use strict;
use warnings;

use R::DataConvert::PDL;
use Data::Frame;

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( ref $data ) {
		if( $data->r_class eq 'data.frame' ) {
			return convert_r_to_perl_dataframe(@_);
		}
	}
	die "could not convert";
}

sub convert_r_to_perl_dataframe {
	my ($self, $data) = @_;

	my $data_list = R::DataConvert::Perl::make_perl_list( $data );
	my $col_names = R::DataConvert->convert_r_to_perl($data->attrib( "names" ));
	my $row_names = R::DataConvert->convert_r_to_perl($data->attrib( "row.names" ));
	my $colspec = [ map {
			( $col_names->[$_] => $data_list->[$_] )
		} 0..@$col_names-1 ];
	my $df = Data::Frame->new( columns => $colspec );
	$df->row_names( $row_names );
	return $df;
}

1;
