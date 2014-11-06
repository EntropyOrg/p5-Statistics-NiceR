#!/usr/bin/env perl

use v5.16;
use strict;
use warnings;

use R;
use R::DataConvert;
use Data::Frame::Rlike;

my $iris_r = Rinterp::eval_SV( q{ iris });
my $iris = R::DataConvert->convert_r_to_perl( $iris_r );
say $iris->subset( sub {
		  ( $_->('Sepal.Length') > 6.0 )
		& ( $_->('Petal.Width')  < 2   )
	});
