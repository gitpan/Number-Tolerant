use Test::More tests => 5;

use strict;
use warnings;

use_ok("Number::Tolerant");

is(
	Number::Tolerant->new(5 => 'thingie' => 0.5),
	undef,
	"there is no 'thingie' method"
);

is(
	Number::Tolerant->new(5 => 'to'),
	undef,
	"'to' requires two values"
);

is(
	Number::Tolerant->new(5 => 'plus_or_minus'),
	undef,
	"'plus_or_minus' requires two values"
);

is(
	Number::Tolerant->new(5 => 'plus_or_minus_pct'),
	undef,
	"'plus_or_minus_pct' requires two values"
);
