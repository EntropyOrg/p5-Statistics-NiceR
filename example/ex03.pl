use Rinterp; use R::Sexp; use R::DataConvert; use R; use Data::Frame::Rlike;
R->new->get('iris')->subset( sub {  ($_->('Petal.Width') < 0.15) | ($_->('Sepal.Width') > 3.7) } );
R->new->rnorm( 10 );
