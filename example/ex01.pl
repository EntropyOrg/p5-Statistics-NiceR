#!/usr/bin/env perl

use v5.16;
use strict;
use warnings;

use R;
use Data::Frame::Rlike;

my $r = R->new;
my $iris = $r->get('iris');
say $iris->subset( sub {
		  ( $_->('Sepal.Length') > 6.0 )
		& ( $_->('Petal.Width')  < 2   )
	});
