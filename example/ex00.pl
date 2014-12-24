#!/usr/bin/env perl

use v5.16;
use strict;
use warnings;

use Statistics::NiceR;

my $r = Statistics::NiceR->new;
my $face_data = $r->eval_parse(q{
	library(aplpack)
	faces(iris[1:20,1:4])
	});

say "Press return to continue..."; <STDIN>;
