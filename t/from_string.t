use Test::More 'no_plan';

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

{ # plusminus
	my $tol = Number::Tolerant->from_string("10 +/- 2");
	is($tol, "10 +/- 2");
}

{ # plusminus_pct
	my $tol = Number::Tolerant->from_string("10 +/- 10%");
	is($tol, "10 +/- 10%");
}

{ # or_less
	my $tol = Number::Tolerant->from_string("10 or less");
	is($tol, "10 or less");
}

{ # or_more
	my $tol = Number::Tolerant->from_string("10 or more");
	is($tol, "10 or more");
}

{ # x_to_y
	my $tol = Number::Tolerant->from_string("8 to 12");
	is($tol, "8 to 12");
}


{ # infinite
	my $tol = Number::Tolerant->from_string("any number");
	is($tol, "any number");
}

{ # constant
	is( Number::Tolerant->from_string("10.12"), "10.12" );
	is( Number::Tolerant->from_string("1012"),  "1012" );
}

{ # bad string
	my $tol = Number::Tolerant->from_string("is this thing on?");
	is($tol, undef);
}

{ # instance method call should die
	my $tol = tolerance(10 => to => 20);
	eval { $tol->from_string("10 to 30"); };
	ok("$@", "from_string is a class method only");
}

