use Rinterp; use R::Sexp; use R::DataConvert; use R; use Data::Frame::Rlike;
$df_r = Rinterp::eval_SV( q{
	ff <- factor( substring("statistics", 1:10, 1:10), levels = letters);
	d <- data.frame(x = 1, y = seq(10,1,-1), fac = ff)
	} ); 1;
$df_r;
$df = R::DataConvert->convert_r_to_perl($df_r);
$df->subset( sub { $_->('fac') == 's' } );
