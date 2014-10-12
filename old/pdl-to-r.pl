#!/usr/bin/env perl

use strict;
use warnings;

use PDL;
use Statistics::R;

my $R = Statistics::R->new;

my $oneD = sequence(10);
my $twoD = sequence(10,4);
my $threeD = sequence(10,4,2);

use DDP; p $R;

$R->set('x', $oneD->unpdl   );
$R->set('y', $twoD->unpdl   );
$R->set('z', $threeD->unpdl );

$R->run(q{
  #x <- as.numeric(x)
  #y <- as.numeric(y)
  #z <- as.numeric(z)
  1
});

$R->run(q{
g <- as.vector(x) * 2
});

$R->run(q{ a <- c( typeof(x), dim(x), str(x) )});
$R->run(q{ b <- c( typeof(y), dim(y), str(y) )});
$R->run(q{ c <- c( typeof(z), dim(z), str(z) )});
$R->run(q{ g <- as.vector(x) * 2 });
$R->run(q{ h <- as.array (y) });
$R->run(q{ i <- as.array (z) });

my $z = $R->get('g');
use DDP; p $R->get('a');
use DDP; p $R->get('b');
use DDP; p $R->get('c');
use DDP; p $R->get('g');
use DDP; p $R->get('h');
use DDP; p $R->get('i');

$R->stop;

# TODO

