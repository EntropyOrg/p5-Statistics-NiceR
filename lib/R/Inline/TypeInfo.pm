package R::Inline::TypeInfo;

use strict;
use warnings;

my $info = {
	CHARSXP => { sexptype => 'CHARSXP', r_macro => 'CHARACTER',                      },
	INTSXP =>  { sexptype => 'INTSXP',  r_macro => 'INTEGER',   r_NA => 'NA_INTEGER' },
	REALSXP => { sexptype => 'REALSXP', r_macro => 'REAL',      r_NA => 'NA_REAL'    },
};
# NA_REAL, NA_INTEGER, NA_LOGICAL, NA_STRING
#
# NA_COMPLEX, NA_CHARACTER?

sub get_type_info {
	my ($klass, $type ) = @_;
	return $info->{$type};
}
