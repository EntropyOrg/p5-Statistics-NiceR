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
	  perl_data => sequence(3,3,3),
	  note => 'n-d array of doubles' },
	{ r_eval => q{ array(0:26, dim=c(3,3,3)) },
	  r_class => 'array', r_typeof => 'integer',
	  perl_data => sequence(3,3,3),
	  note => 'n-d array of integers' },

];

plan tests => scalar @$test_data;

for my $t (@$test_data) {
	my $r_code = $t->{r_eval};
	my $r_data = Rinterp::eval_SV( $r_code );
	my $perl_data = R::DataConvert->convert_r_to_perl( $r_data );

	subtest "$t->{note}: $t->{r_eval}" => sub {
		compare( $perl_data, $t->{perl_data}, "data" );
		is( $r_data->R::Sexp::r_class, $t->{r_class}, "class: $t->{r_class}");
		is( $r_data->R::Sexp::r_typeof, $t->{r_typeof}, "typeof: $t->{r_typeof}");
	}
}

done_testing;
