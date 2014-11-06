#!/usr/bin/env perl

use strict;
use warnings;

use R;

Rinterp::eval_SV( q{
			library(aplpack)
			faces(iris[1:20,1:4])
		});

<STDIN>;
