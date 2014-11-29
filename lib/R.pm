package R;

use strict;
use warnings;

use Rinterp;
use R::Sexp;
use R::DataConvert;

# TODO AUTOLOAD

sub new {
	my ($klass) = @_;
	bless { converter => 'R::DataConvert', r_interpreter => 'Rinterp' }, $klass;
}

our $AUTOLOAD;
sub AUTOLOAD {
	(my $fname = our $AUTOLOAD) =~ s/^@{[__PACKAGE__]}:://;
	my ($self, @args) = @_;
	my $function = $self->{r_interpreter}->R_get_function($fname);
	my @r_args = map { [ $self->{converter}->convert_perl_to_r($_) ] } @args;
	my $r_data = $self->{r_interpreter}->R_call_function( $function, \@r_args );
	return $self->{converter}->convert_r_to_perl( $r_data );
}

1;
