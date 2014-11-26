package R::DataConvert;

use strict;
use warnings;

use R::Sexp;
use R::DataConvert::PDL;
use R::DataConvert::Perl;
use R::DataConvert::DataFrame;
use R::DataConvert::Factor;
use Scalar::Util qw(blessed);

sub convert_r_to_perl {
	my ($klass, $data) = @_;
	return unless $klass->check_r_sexp($data);
	for my $p (qw(R::DataConvert::PDL R::DataConvert::Perl R::DataConvert::Factor R::DataConvert::DataFrame) ) {
		my $ret;
		eval {
			no strict 'refs';
			$ret = &{"${p}::convert_r_to_perl"}(@_);
			1;
		} and return $ret;
		die $@ unless( $@ =~ /could not convert/ );
	}
	die $@; # TODO rethrow
}

sub check_r_sexp {
	my ($klass, $data) = @_;
	blessed $data && $data->isa('R::Sexp')
}

sub convert_perl_to_r {
	for my $p (qw(R::DataConvert::PDL R::DataConvert::Perl R::DataConvert::Factor R::DataConvert::DataFrame) ) {
		my $ret;
		eval {
			no strict 'refs';
			$ret = &{"${p}::convert_perl_to_r"}(@_);
			1;
		} and return $ret;
		die $@ unless( $@ =~ /could not convert/ );
	}
	die $@; # TODO rethrow
}


1;
