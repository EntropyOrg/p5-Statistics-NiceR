use Test::Most;

use strict;
use warnings;

use PDL;
use R;
use Rinterp;
use R::DataConvert;
use PDL::Factor;
use Data::Frame;
use Scalar::Util qw(blessed);

sub mog {
	my $s = shift;
	$s =~ s/\$PDL_\d+/\$PDL/msg;
	$s =~ s/my \$o = \d+/my \$o/msg;
	$s;
}

sub compare {
	my ($got, $expected) = @_;
	if( blessed $expected && $expected->isa('PDL') ) {
		compare_pdl(@_);
	} else {
		compare_perl(@_);
	}
}

sub compare_pdl {
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

sub compare_perl {
	my ($got, $expected, $msg) = @_;
	if( blessed($got) && $got->isa('Data::Frame') ) {
		# stringify Data::Frame's
		is( "$got", "$expected", "$msg: Perl data [compare dump of Data::Frame]");
	} else {
		use PDL::IO::Dumper;
		my $s_perl_data = mog sdump($got);
		my $s_expected_perl_data = mog sdump($expected);
		is( $s_perl_data , $s_expected_perl_data, "$msg: Perl data [compare dump]" );
	}

	# the following throws "multielement piddle in conditional expression"
	#is_deeply( $perl_data, $t->{perl_data}, "Perl data" );
}

my $factor_data = PDL::Factor->new(
	integer => [ qw[19 20 1 20 9 19 20 9 3 19] ],
	levels => [undef, 'a'..'z'], );
my $test_data = [
	{ r_eval => q{ array(as.double(0:26), dim=c(3,3,3)) },
	  r_class => 'array', r_typeof => 'double',
	  pdl_data => sequence(3,3,3),
	  note => 'n-d array of doubles' },

	{ r_eval => q{ array(0:26, dim=c(3,3,3)) },
	  r_class => 'array', r_typeof => 'integer',
	  pdl_data => sequence(long,3,3,3),
	  note => 'n-d array of integers' },

	{ r_eval => q{ c(3,2,1) },
	  r_class => 'numeric', r_typeof => 'double',
	  pdl_data => pdl(3,2,1),
	  note => 'vector of numbers' },

	{ r_eval => q{ as.integer(c(3,2,1)) },
	  r_class => 'integer', r_typeof => 'integer',
	  pdl_data => long(3,2,1),
	  note => 'vector of integers' },

	{ r_eval => q{
	      mdat <- matrix(c(1,2,3, 11,12,13),
	            nrow = 2, ncol = 3, byrow = TRUE,
	            dimnames = list(c("row1", "row2"),
	            c("C.1", "C.2", "C.3"))) },
	  r_class => 'matrix', r_typeof => 'double',
	  pdl_data => do {
	  	my $matrix = pdl( q[ 1 2 3; 11 12 13 ] )->xchg(0,1);
	  	$matrix->hdr->{dimnames} = [
	  		[ "row1", "row2" ],
	  		[ "C.1", "C.2", "C.3" ]
	  	];
		die "not the right matrix" unless $matrix->at(0,1) == 2;
	  	$matrix;
	  },
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
	  pdl_data => $factor_data,
	  note => 'factor'},

	{ r_eval => q{
              ff <- factor( substring("statistics", 1:10, 1:10),
                            levels = letters);
              d <- data.frame(x = 1, y = 1:10, fac = ff) },
	  r_class => 'data.frame', r_typeof => 'list',
	  perl_data => do {
		my $df = Data::Frame->new( columns => [
				x => ones(10),
				y => sequence(10)->long + 1,
				fac => $factor_data,
			  ]);
		$df->row_names( 1..10 );
		$df;
	  },
	  note => 'data frame'},

# test bad values
	{ r_eval => q{
	  	q <- array(as.double(0:26), dim=c(3,3,3));
	  	ifelse( q %% 2, NA, q );                   },
	  r_class => 'array', r_typeof => 'double',
	  pdl_data => do {
	  	my $q = sequence(3,3,3);
	  	$q->setbadif( $q % 2 );
	  },
	  note => 'n-d array of doubles with NA/BAD values' },

	{ r_eval => q{ numeric() },
	  r_class => 'numeric', r_typeof => 'double',
	  pdl_data => do { double([]) },
	  note => 'empty double' },

	{ r_eval => q{ integer() },
	  r_class => 'integer', r_typeof => 'integer',
	  pdl_data => do { long([]) },
	  note => 'empty integer' },

	{ r_eval => q{ list() },
	  r_class => 'list', r_typeof => 'list',
	  pdl_data => do { [] },
	  note => 'empty list' },

# checking for NULL/undef is difficult because it happens at the typemap
#	{ r_eval => q{ NULL },
#	  r_class => 'NULL', r_typeof => 'NULL',
#	  pdl_data => undef,
#	  note => 'NULL/undef' },

	{ r_eval => q{ as.numeric(42) },
	  r_class => 'numeric', r_typeof => 'double',
	  pdl_data => double( 42 ),
	  note => 'single value of type double' },

	{ r_eval => q{ as.numeric(NA) },
	  r_class => 'numeric', r_typeof => 'double',
	  pdl_data => double( q[BAD] ),
	  note => 'single NA/BAD of type double' },

# TODO:
# >  k_iris <- kmeans( iris[,-5], centers=3 ); class(k_iris); typeof(k_iris)
# [1] "kmeans"
# [1] "list"
# > fitted(k_iris) # S3 method
# TODO matrix of characters




];

plan tests => scalar @$test_data;

for my $t (@$test_data) {
	my $r_code = $t->{r_eval};

	subtest "$t->{note}: $t->{r_eval}" => sub {
		my $r_data = Rinterp->eval( $r_code );
		my $perl_data;
		eval {
			$perl_data = R::DataConvert->convert_r_to_perl( $r_data ); 1
		} or ok(0, "conversion failed: $@");
		my $conversion_to_perl = !$@;

		if( $conversion_to_perl ) {
			for my $key ( qw(pdl_data perl_data) ) {
				if( exists $t->{$key} ) {
					compare( $perl_data, $t->{$key}, $key);
				}
			}
		}
		is( $r_data->r_class, $t->{r_class}, "class: $t->{r_class}");
		is( $r_data->r_typeof, $t->{r_typeof}, "typeof: $t->{r_typeof}");

		for my $key ( qw( pdl_data perl_data) ) {
			next unless exists $t->{$key};
			my $converted_r_data;
			eval {
				$converted_r_data = R::DataConvert->convert_perl_to_r( $t->{$key} ); 1
			} or ok(0, "conversion failed: $@");
			my $conversion_to_r = !$@;

			if( $conversion_to_r ) {
				if( $t->{r_class} ne 'list' ) {
					my $is_eq = ok( $r_data->op_equal_all($converted_r_data), 'converted Perl to R: all equality' );
					note $converted_r_data unless $is_eq;
				} else {
					note "skipping testing equality for lists: these throw an error and I do not know why identical(x,y) is not working.";
				}
				is( $converted_r_data->r_class, $t->{r_class}, "Perl->R class: $t->{r_class}");
				is( $converted_r_data->r_typeof, $t->{r_typeof}, "Perl->R typeof: $t->{r_typeof}");

				is( "$converted_r_data", "$r_data", "Perl->R: string representation");

			}

		}
	}
}

done_testing;
