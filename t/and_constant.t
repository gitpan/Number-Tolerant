use Test::More 'no_plan';

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

my $range = Number::Tolerant->new(9 => to => 5);

isa_ok($range, 'Number::Tolerant');

is($range & 5.0, 5.0, ' ... $range & 5.0 == 5.0');
is($range & 5.0, 5.0, ' ... 5.0 & $range == 5.0');
is($range & 6.5, 6.5, ' ... $range & 6.5 == 6.5');
is($range & 6.5, 6.5, ' ... 6.5 & $range == 6.5');
