use Test::More tests => 8;

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

is(
	Number::Tolerant->new(),
	undef,
	"at least one param required"
);

is(
	Number::Tolerant->new(5),
	undef,
	"single param only OK for infinite"
);

is(
	Number::Tolerant->new(undef , 'to' , undef),
	undef,
	"undef-undef range not valid (should it be?)"
);
