package R::DataConvert;

use strict;
use warnings;

use R::Sexp;
use R::DataConvert::PDL;
use R::DataConvert::Perl;
use R::DataConvert::DataFrame;
use R::DataConvert::Factor;

sub convert_r_to_perl {
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

sub convert_perl_to_r {
	for my $p (qw(R::DataConvert::PDL R::DataConvert::Perl R::DataConvert::Factor R::DataConvert::DataFrame) ) {
		my $ret;
		eval {
			no strict 'refs';
			$ret = &{"${p}::convert_perl_to_r"}(@_);
			1;
		} and return $ret;
	}
	die $@; # TODO rethrow
}


1;
