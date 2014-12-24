#!/usr/bin/env perl

use v5.16;
use strict;
use warnings;

use Statistics::NiceR;
use Data::Frame::Rlike;

my $r = Statistics::NiceR->new;
my $iris = $r->get('iris');

say "Subset of Iris data set";
say $iris->subset( sub {
		  ( $_->('Sepal.Length') > 6.0 )
		& ( $_->('Petal.Width')  < 2   )
	});

say "\n===\n";

say "10 random numbers from a normal distribution:";
say $r->rnorm( 10 );
