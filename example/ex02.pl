#!/usr/bin/env perl
#
use v5.16;
use strict;
use warnings;

use Statistics::NiceR;
use Data::Frame;

Moo::Role->apply_roles_to_package( q|Data::Frame|, qw(Data::Frame::Role::Rlike) );
my $r = Statistics::NiceR->new;


my $df = $r->eval_parse( q{
	ff <- factor( substring("statistics", 1:10, 1:10), levels = letters);
	d <- data.frame(x = 1, y = seq(10,1,-1), fac = ff)
	} ); 1;

say "Data frame:";
say $df;

say "\n===\n";

say "Subset of data frame:";
say $df->subset( sub { $_->('fac') == 's' } );
