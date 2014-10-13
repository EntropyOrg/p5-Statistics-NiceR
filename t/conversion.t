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
	  perl_data => sequence(3,3,3) },

];

plan tests => scalar @$test_data;

for my $t (@$test_data) {
	my $r_code = $t->{r_eval};
	my $r_data = Rinterp::eval_SV( $r_code );
	my $perl_data = R::DataConvert->convert_r_to_perl( $r_data );

	compare( $perl_data, $t->{perl_data}, $t->{r_eval} );
}

done_testing;
