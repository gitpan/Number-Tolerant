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

{ # x_or_more & x_or_more
	my $demand = Number::Tolerant->new(40 => 'or_more');
	my $offer  = Number::Tolerant->new(30 => 'or_more');

	isa_ok($demand, 'Number::Tolerant');
	isa_ok($offer,  'Number::Tolerant');

	my $range = $demand & $offer;

	isa_ok($range,   'Number::Tolerant', 'intersection');

	is("$range", '40 or more', ' ... stringifies');
	is(0+$range,           40, ' ... numifies to 40');

	is($range->{min},         40, ' ... minimum : 40');
	is($range->{max},      undef, ' ... maximum : undef');
	is($range->{value},       40, ' ... value   : 40');
	is($range->{variance}, undef, ' ... variance: undef');
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

{ # x_to_y & infinite
	my $demand = Number::Tolerant->new(40 => to => 60);
	my $offer  = Number::Tolerant->new('infinite');

	isa_ok($demand, 'Number::Tolerant');
	isa_ok($offer,  'Number::Tolerant');

	my $range = $demand & $offer;

	isa_ok($range,   'Number::Tolerant', 'intersection');

	is("$range", '40 to 60', ' ... stringifies');
	is(0+$range,         50, ' ... numifies to 45');

	is($range->{min},      40, ' ... minimum : 40');
	is($range->{max},      60, ' ... maximum : 50');
	is($range->{value},    50, ' ... value   : 45');
	is($range->{variance}, 10, ' ... variance:  5');
}

{ # infinite & infinite
	my $demand = Number::Tolerant->new('infinite');
	my $offer  = Number::Tolerant->new('infinite');

	isa_ok($demand, 'Number::Tolerant');
	isa_ok($offer,  'Number::Tolerant');

	my $range = $demand & $offer;

	isa_ok($range,   'Number::Tolerant', 'intersection');

	is("$range", 'any number', ' ... stringifies');
	is(0+$range,            0, ' ... numifies to 0');

	is($range->{min},      undef, ' ... minimum : undef');
	is($range->{max},      undef, ' ... maximum : undef');
	is($range->{value},        0, ' ... value   : 0');
	is($range->{variance}, undef, ' ... variance: undef');
}
