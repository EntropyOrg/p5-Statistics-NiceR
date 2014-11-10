use Test::Most;

use strict;
use warnings;

use PDL;
use R;
use Rinterp;
use R::DataConvert;
use PDL::Factor;

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


# TODO:
# >  k_iris <- kmeans( iris[,-5], centers=3 ); class(k_iris); typeof(k_iris)
# [1] "kmeans"
# [1] "list"
# > fitted(k_iris) # S3 method

# TODO test bad values

];

plan tests => scalar @$test_data;

sub mog {
	my $s = shift;
	$s =~ s/\$PDL_\d+/\$PDL/msg;
	$s =~ s/my \$o = \d+/my \$o/msg;
	$s;
}

for my $t (@$test_data) {
	my $r_code = $t->{r_eval};

	subtest "$t->{note}: $t->{r_eval}" => sub {
		my $r_data = Rinterp::eval_SV( $r_code );
		my $perl_data;
		eval {
			$perl_data = R::DataConvert->convert_r_to_perl( $r_data ); 1
		} or ok(0, "conversion failed: $@");
		my $conversion = !$@;

		if( $conversion ) {
			compare( $perl_data, $t->{pdl_data}, "PDL data" ) if exists $t->{pdl_data};
			if( exists $t->{perl_data} ) {
				use PDL::IO::Dumper;
				my $s_perl_data = mog sdump($perl_data);
				my $s_expected_perl_data = mog sdump($t->{perl_data});
				is( $s_perl_data , $s_expected_perl_data, 'Perl data [compare dump]' );

				# the following throws "multielement piddle in conditional expression"
				#is_deeply( $perl_data, $t->{perl_data}, "Perl data" );
			}
		}
		is( $r_data->r_class, $t->{r_class}, "class: $t->{r_class}");
		is( $r_data->r_typeof, $t->{r_typeof}, "typeof: $t->{r_typeof}");
	}
}

done_testing;
