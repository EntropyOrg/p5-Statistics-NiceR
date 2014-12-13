package R::DataConvert::PDL;

use strict;
use warnings;

use Inline with => qw(R::Inline::Rinline R::Inline::Rpdl R::Inline::Rutil);
# NOTE: Inline->bind() used below
use File::Slurp::Tiny qw(read_file);
use File::Spec::Functions;
use File::Basename;
use PDL::Types;
use Text::Template;
use R::Inline::TypeInfo;
use Scalar::Util qw(blessed);

my $code;
BEGIN {
	## START OF Inline processing

	sub _type_helper { R::Inline::TypeInfo->get_type_info($_[0]); }
	my $pdl_to_r = {
		PDL_B   => _type_helper('CHARSXP'),

		PDL_S   => _type_helper('INTSXP'),
		PDL_US  => _type_helper('INTSXP'),
		PDL_L   => _type_helper('INTSXP'),
		PDL_IND => _type_helper('INTSXP'),
		PDL_LL  => _type_helper('INTSXP'),

		PDL_F   => _type_helper('REALSXP'),
		PDL_D   => _type_helper('REALSXP'),
	};
	for my $type (PDL::Types::typesrtkeys()) {
		$pdl_to_r->{$type}{ctype} = PDL::Types::typefld($type, 'ctype');
	}

	# read in template and fill
	my $c_template_file = catfile( dirname(__FILE__), 'PDL.c.tmpl' );
	my $template_string = read_file($c_template_file);
	$template_string =~ s/\A.*?__C__$//msg;
	my $template = Text::Template->new(
		TYPE => 'STRING', SOURCE => $template_string,
		DELIMITERS => ['{{{', '}}}'], );
	$code = $template->fill_in( HASH => { pdl_to_r => \$pdl_to_r } );
	## END OF Inline processing
}
use R::DataConvert::PDL::Inline C => $code;

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( R::DataConvert->check_r_sexp($data) ) {
		if( $data->r_class eq 'array' ) {
			return convert_r_to_perl_array(@_);
		} elsif( $data->r_class eq 'matrix' ) {
			return convert_r_to_perl_matrix(@_);
		} elsif( $data->r_class eq 'integer' ) {
			return convert_r_to_perl_intsxp(@_);
		} elsif( $data->r_class eq 'numeric' ) {
			return convert_r_to_perl_realsxp(@_);
		}
	}
	die "could not convert";
}

sub convert_r_to_perl_array {
	my ($self, $data) = @_;
	return make_pdl_array( $data );
}

sub convert_r_to_perl_matrix {
	my ($self, $data) = @_;
	# TODO does this make sense?
	my $matrix = make_pdl_array( $data );
	my $dimnames = $data->attrib('dimnames');
	if(defined $dimnames) {
		$matrix->hdr->{dimnames} = R::DataConvert->convert_r_to_perl( $dimnames );
	}
	return $matrix;
}

sub convert_r_to_perl_intsxp {
	my ($self, $data) = @_;
	return make_pdl_vector( $data, 1 );
}

sub convert_r_to_perl_realsxp {
	my ($self, $data) = @_;
	return make_pdl_vector( $data, 1 );
}


sub convert_perl_to_r {
	my ($self, $data) = @_;
	if( blessed($data) ) {
		if( $data->isa('PDL') ) {
			if( $data->ndims == 2 ) {
				return convert_perl_to_r_PDL_ndims_2(@_);
			} elsif( $data->ndims == 1 ) {
				return convert_perl_to_r_PDL_ndims_1(@_);
			} elsif( $data->ndims == 0 ) {
				return convert_perl_to_r_PDL_ndims_0(@_);
			} else {
				return convert_perl_to_r_PDL(@_);
			}
		}
	}
	die "could not convert";
}

sub convert_perl_to_r_PDL_ndims_0 {
	my ($self, $data) = @_;
	return make_r_array($data, 1, 0);
}

sub convert_perl_to_r_PDL_ndims_1 {
	my ($self, $data) = @_;
	return make_r_array($data, 1, 0);
}

sub convert_perl_to_r_PDL_ndims_2 {
	my ($self, $data) = @_;
	my $r_matrix = make_r_array( $data->copy, 0, 1 );
	my $hdr = $data->hdr;
	if( exists $hdr->{dimnames} ) {
		$r_matrix->attrib( 'dimnames', R::DataConvert->convert_perl_to_r( $hdr->{dimnames} ) ) ;
	}
	return $r_matrix;
}

sub convert_perl_to_r_PDL {
	my ($self, $data) = @_;
	return make_r_array( $data, 0, 0 );
}

1;
__DATA__
__C__
/* see lib/R/DataConvert/PDL.c.tmpl */
