#!/usr/bin/env perl

use strict;
use warnings;

use R;

my $r = R->new;
my $face_data = $r->eval_parse(q{
	library(aplpack)
	faces(iris[1:20,1:4])
	});

<STDIN>;
