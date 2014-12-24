package Statistics::NiceR;
# ABSTRACT: interface to the R programming language
=encoding UTF-8

use strict;
use warnings;

use Statistics::NiceR::Backend::EmbeddedR;
use Statistics::NiceR::Sexp;
use Statistics::NiceR::DataConvert;
use Statistics::NiceR::Error;
use Try::Tiny;

=method new

    new()

Creates a new instance of a wrapper around the R interpreter.

Example

    use Statistics::NiceR

    my $r = Statistics::NiceR->new();

=cut
=method eval_parse

    eval_parse( Str $r_code )

A convenience function that allows for evaluating arbitrary R code.

The return value is the last line of the code in C<$r_code>.

Example:

    use Statistics::NiceR

    my $r = Statistics::NiceR->new();
    my $dataframe = $r->eval_parse( q< iris[1:20,1:4] > );

=cut
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
	my $perl_data = try {
		$self->{converter}->convert_r_to_perl( $r_data );
	} catch {
		die $_ unless ref $_; # don't know what do with the error

		return $r_data if ref $_ && $_->isa( 'Statistics::NiceR::Error::Conversion' );

		$_->throw # for other errors, rethrow;
	};
	# otherwise, no error in conversion
	return $perl_data;
}

1;

=head1 SYNOPSIS

    use Statistics::NiceR

    my $r = Statistics::NiceR->new();

    say $r->pnorm( [ 0 .. 3 ] )
    # [0.5 0.84134475 0.97724987  0.9986501]

=head1 DESCRIPTION

This module provides an interface to the R programming language for statistics
by embedding the R interpreter using its C API. This allows direct access to
R's functions and allows sending and receiving data efficiently.

=head2 CONVERSION

In order to give the module a hassle-free interface, there is a mechanism to
convert Perl types[^1] to R types[^2] and vice-versa for the values sent to and
from the R interpreter.

Currently, the conversion is handled by the modules under the
L<Statistics::NiceR::DataConvert> namespace. It is currently undocumented how
to extend this to more types or how to change the default behaviour, but this
will be addressed in future versions.

[^1]: Such as strings, numbers, and arrays.

[^2]: Such as integers, numerics, data frames, and matrices.

=begin comment

TODO change this wording when the Statistics::NiceR::DataConvert module is
documented and when changing the converter behaviour is documented for
Statistics::NiceR

=end comment

=head2 CALLING R FUNCTIONS

R functions can be called by using the name of the function as a method call.
For example, to call the L<pnorm|https://stat.ethz.ch/R-manual/R-devel/library/stats/html/Normal.html>
function (PDF of the normal distribution), which has the R function signature

    pnorm(q, mean = 0, sd = 1, lower.tail = TRUE, log.p = FALSE)

one could run

    use Statistics::NiceR;
    my $r = Statistics::NiceR->new();

    say $r->pnorm( 0 ) # N( μ = 0, σ² = 1) at x = 0
    # 0.5

    say $r->pnorm( 5, 1, 2 ) # N( μ = 1, σ² = 2) at x = 5
    # 0.977249868051821

Since R can have identifiers that contain a period (".") in their name and Perl
can not, C<Statistics::NiceR> maps

=over 8

=item a single underscore in the Perl function name ("_") to a period in the R function name (".")

=item two consecutive underscores in the Perl function name ("__") to a single underscore in the R function name ("_").

=back

So in order to call R's C<as.Date> function, one could run:

    use Statistics::NiceR;
    my $r = Statistics::NiceR->new();

    say $r->as_Date( "02/27/92", "%m/%d/%y" ); # one underscore
    # [1] "1992-02-27"

or to call R's C<l10n_info> function, one could run:

    use Statistics::NiceR;
    my $r = Statistics::NiceR->new();

    say $r->l10n__info(); # two underscores
    # $MBCS
    # [1] TRUE
    #
    # $`UTF-8`
    # [1] TRUE
    #
    # $`Latin-1`
    # [1] FALSE

=begin comment

TODO Need to document how to call functions with named arguments.

=end comment

=head1 SEE ALSO

=over 4

=item L<The R Project for Statistical Computing|http://www.r-project.org/>

=item Browse and download additional R packages: L<The Comprehensive R Archive Network|http://cran.r-project.org/>

=item L<R Tutorial: R Introduction|http://www.r-tutor.com/r-introduction>

=back

For developers:

=over 4

=item L<Writing R Extensions|http://cran.r-project.org/doc/manuals/r-release/R-exts.html>

=item L<Advanced R by Hadley Wickham: R’s C interface|http://adv-r.had.co.nz/C-interface.html>

=back


=cut
