package Statistics::NiceR;
# ABSTRACT: interface to the R programming language

use strict;
use warnings;

use Statistics::NiceR::Backend::EmbeddedR;
use Statistics::NiceR::Sexp;
use Statistics::NiceR::DataConvert;

sub new {
	my ($klass) = @_;
	my $obj = bless { converter => 'Statistics::NiceR::DataConvert', r_interpreter => 'Statistics::NiceR::Backend::EmbeddedR' }, $klass;

	# add this function to R env so that eval'ing a string is easy via the function call interface
	$obj->{r_interpreter}->eval( q{ eval.parse <- function(x) eval( parse( text = x ) ) } );

	$obj;
}

sub _map_function_perl_to_r {
	my ($name) = @_;
	$name =~ s,__,*,;
	$name =~ s,_,.,;
	$name =~ s,\*,_,;
	$name;
}

sub AUTOLOAD {
	(my $fname = our $AUTOLOAD) =~ s/^@{[__PACKAGE__]}:://;
	my ($self, @args) = @_;
	my $r_fname = _map_function_perl_to_r($fname); 
	my $function = $self->{r_interpreter}->R_get_function($r_fname);
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
