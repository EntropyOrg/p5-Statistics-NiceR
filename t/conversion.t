use Test::Most;

use strict;
use warnings;

use PDL;
use R;
use Rinterp;
use R::DataConvert;

sub compare {
	my ($got, $expected, $msg) = @_;
	if( ref $expected ) {
		if( $expected->isa('PDL') ) {
			if( all( $got == $expected ) ) {
				ok(1, $msg);
			} else {
				ok(0, $msg);
				note $got;
			}
			return;
		} 
	}
	die "could not compare";
}

my $test_data = [
	{ r_eval => q{ array(as.double(0:26), dim=c(3,3,3)) },
	  r_class => 'array', r_typeof => 'double',
	  pdl_data => sequence(3,3,3),
	  note => 'n-d array of doubles' },

	{ r_eval => q{ array(0:26, dim=c(3,3,3)) },
	  r_class => 'array', r_typeof => 'integer',
	  pdl_data => sequence(3,3,3),
	  note => 'n-d array of integers' },

	{ r_eval => q{ c(3,2,1) },
	  r_class => 'numeric', r_typeof => 'double',
	  pdl_data => pdl(3,2,1),
	  note => 'vector of integers' },

	{ r_eval => q{ as.integer(c(3,2,1)) },
	  r_class => 'integer', r_typeof => 'integer',
	  pdl_data => pdl(3,2,1),
	  note => 'vector of integers' },

	{ r_eval => q{
	      mdat <- matrix(c(1,2,3, 11,12,13),
	            nrow = 2, ncol = 3, byrow = TRUE,
	            dimnames = list(c("row1", "row2"),
	            c("C.1", "C.2", "C.3"))) },
	  r_class => 'matrix', r_typeof => 'double',
	  pdl_data => pdl( q[ 1 2 3; 11 12 13 ] ),
	  note => 'a matrix'
	},

	{ r_eval => q{ "a string" },
	  r_class => 'character', r_typeof => 'character',
	  perl_data => "a string",
	  note => 'character string'},

	{ r_eval => q{ c("a", "b", "c") },
	  r_class => 'character', r_typeof => 'character',
	  perl_data => ["a", "b", "c"],
	  note => 'character string vector'},

# TODO: g <- list(1,2,3, 1:3); g[4]; g[[4]]
	{ r_eval => q{  list(1,2,3) },
	  r_class => 'list', r_typeof => 'list',
	  perl_data => [ pdl(1) , pdl(2), pdl(3) ],
	  note => 'simple list'},

	{ r_eval => q{  list(1,2,3, as.double(1:3)) },
	  r_class => 'list', r_typeof => 'list',
	  perl_data => [ pdl(1) , pdl(2), pdl(3), pdl([1..3]) ],
	  note => 'nested list'},

	{ r_eval => q{
	      ff <- factor( substring("statistics", 1:10, 1:10),
	                    levels = letters) },
	  r_class => 'factor', r_typeof => 'integer',
	  # as.integer(*)
	  # 19 20  1 20  9 19 20  9  3 19
	  # Levels: a b c d e f g h i j k l m n o p q r s t u v w x y z
	  pdl_data => undef, # TODO
	  note => 'factor'},

	{ r_eval => q{
              ff <- factor( substring("statistics", 1:10, 1:10),
                            levels = letters);
              d <- data.frame(x = 1, y = 1:10, fac = ff) },
	  r_class => 'data.frame', r_typeof => 'list',
	  perl_data => undef, # TODO
	  note => 'data frame'},


# TODO:
# >  k_iris <- kmeans( iris[,-5], centers=3 ); class(k_iris); typeof(k_iris)
# [1] "kmeans"
# [1] "list"
# > fitted(k_iris) # S3 method

];

plan tests => scalar @$test_data;

for my $t (@$test_data) {
	my $r_code = $t->{r_eval};
	my $r_data = Rinterp::eval_SV( $r_code );
	my $perl_data = R::DataConvert->convert_r_to_perl( $r_data );

	subtest "$t->{note}: $t->{r_eval}" => sub {
		compare( $perl_data, $t->{pdl_data}, "data" ) if exists $t->{pdl_data};
		is_deeply( $perl_data, $t->{perl_data}, "data" ) if exists $t->{perl_data};
		is( $r_data->R::Sexp::r_class, $t->{r_class}, "class: $t->{r_class}");
		is( $r_data->R::Sexp::r_typeof, $t->{r_typeof}, "typeof: $t->{r_typeof}");
	}
}

done_testing;
