use Test::More 'no_plan';

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

{ # x_to_y & x_to_y
	my $demand = Number::Tolerant->new(40 => to => 60);
	my $offer  = Number::Tolerant->new(30 => to => 50);

	isa_ok($demand, 'Number::Tolerant');
	isa_ok($offer,  'Number::Tolerant');

	my $range = $demand & $offer;

	isa_ok($range,   'Number::Tolerant', 'intersection');

	is("$range", '40 to 50', ' ... stringifies');
	is(0+$range,         45, ' ... numifies to 45');

	is($range->{min},      40, ' ... minimum : 40');
	is($range->{max},      50, ' ... maximum : 50');
	is($range->{value},    45, ' ... value   : 45');
	is($range->{variance},  5, ' ... variance:  5');
}

{ # x_to_y & x_or_more
	my $demand = Number::Tolerant->new(40 => 'or_more');
	my $offer  = Number::Tolerant->new(30 => to => 50);

	isa_ok($demand, 'Number::Tolerant');
	isa_ok($offer,  'Number::Tolerant');

	my $range = $demand & $offer;

	isa_ok($range,   'Number::Tolerant', 'intersection');

	is("$range", '40 to 50', ' ... stringifies');
	is(0+$range,         45, ' ... numifies to 45');

	is($range->{min},      40, ' ... minimum : 40');
	is($range->{max},      50, ' ... maximum : 50');
	is($range->{value},    45, ' ... value   : 45');
	is($range->{variance},  5, ' ... variance:  5');
}

{ # x_to_y & x_or_less
	my $demand = Number::Tolerant->new(40 => to => 60);
	my $offer  = Number::Tolerant->new(50 => 'or_less');

	isa_ok($demand, 'Number::Tolerant');
	isa_ok($offer,  'Number::Tolerant');

	my $range = $demand & $offer;

	isa_ok($range,   'Number::Tolerant', 'intersection');

	is("$range", '40 to 50', ' ... stringifies');
	is(0+$range,         45, ' ... numifies to 45');

	is($range->{min},      40, ' ... minimum : 40');
	is($range->{max},      50, ' ... maximum : 50');
	is($range->{value},    45, ' ... value   : 45');
	is($range->{variance},  5, ' ... variance:  5');
}
