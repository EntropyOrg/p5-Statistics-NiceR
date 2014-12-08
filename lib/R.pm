package R;
# ABSTRACT: interface to the R programming language

use strict;
use warnings;

use Rinterp;
use R::Sexp;
use R::DataConvert;

sub new {
	my ($klass) = @_;
	my $obj = bless { converter => 'R::DataConvert', r_interpreter => 'Rinterp' }, $klass;

	# add this function to R env so that eval'ing a string is easy via the function call interface
	$obj->{r_interpreter}->eval( q{ eval_parse <- function(x) eval( parse( text = x ) ) } );

	$obj;
}

sub AUTOLOAD {
	(my $fname = our $AUTOLOAD) =~ s/^@{[__PACKAGE__]}:://;
	my ($self, @args) = @_;
	my $function = $self->{r_interpreter}->R_get_function($fname);
	my @r_args = map { [ $self->{converter}->convert_perl_to_r($_) ] } @args;
	my $r_data = $self->{r_interpreter}->R_call_function( $function, \@r_args );
	my $perl_data = eval {
		$self->{converter}->convert_r_to_perl( $r_data );
	};
	if( $@ ) {
		return $r_data if( $@ =~ /could not convert/ );

		die $@; # for other errors, rethrow
	}
	# otherwise, no error in conversion
	return $perl_data;
}

1;
