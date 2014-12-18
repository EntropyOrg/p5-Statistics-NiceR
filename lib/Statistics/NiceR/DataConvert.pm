package Statistics::NiceR::DataConvert;

use strict;
use warnings;

use Statistics::NiceR::Sexp;
use Statistics::NiceR::DataConvert::PDL;
use Statistics::NiceR::DataConvert::Perl;
use Statistics::NiceR::DataConvert::DataFrame;
use Statistics::NiceR::DataConvert::Factor;
use Scalar::Util qw(blessed);

sub convert_r_to_perl {
	my ($klass, $data) = @_;
	return unless $klass->check_r_sexp($data);
	for my $p (qw(Statistics::NiceR::DataConvert::PDL Statistics::NiceR::DataConvert::Perl Statistics::NiceR::DataConvert::Factor Statistics::NiceR::DataConvert::DataFrame) ) {
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
	blessed($data) && $data->isa('Statistics::NiceR::Sexp')
}

sub convert_perl_to_r {
	for my $p (qw(Statistics::NiceR::DataConvert::Factor Statistics::NiceR::DataConvert::PDL Statistics::NiceR::DataConvert::DataFrame Statistics::NiceR::DataConvert::Perl) ) {
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
