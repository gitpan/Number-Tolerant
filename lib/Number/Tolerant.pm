package Number::Tolerant;
our $VERSION = "1.30";

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(tolerance);

use Carp;

=head1 NAME

Number::Tolerant -- tolerance ranges for inexact numbers

=head1 VERSION

version 1.30

 $Id: Tolerant.pm,v 1.20 2004/08/20 19:23:29 rjbs Exp $

=head1 SYNOPSIS

 use Number::Tolerant;

 my $range  = tolerance(10 => to => 12);
 my $random = 10 + rand(2);

 die "I shouldn't die" unless $random == $range;

 print "This line will always print.\n";

=head1 DESCRIPTION

Number::Tolerant creates a number-like object whose value refers to a range of
possible values, each equally acceptable.  It overloads comparison operations
to reflect this.

I use this module to simplify the comparison of measurement results to
specified tolerances.

 reject $product unless $measurement == $specification;

=head1 METHODS

=head2 Instantiation

=head3 C<< Number::Tolerance->new( ... ) >>

=head3 C<< tolerance( ... ) >>

There is a C<new> method on the Number::Tolerant class, but it also exports a
simple function, C<tolerance>, which will return an object of the
Number::Tolerant class.  Both use the same syntax:

 my $range = tolerance( $x => $method => $y);

The meaning of C<$x> and C<$y> are dependant on the value of C<$method>, which
describes the nature of the tolerance.  Tolerances can be defined in five ways,
at present:

  method              range
 -------------------+---------------
  plus_or_minus     | x ± y
  plus_or_minus_pct | x ± (y% of x)
  or_more           | x to Inf
  or_less           | x to -Inf
  to                | x to y
  infinite          | -Inf to Inf

For C<or_less> and C<or_more>, C<$y> is ignored if passed.  For C<infinite>,
neither C<$x> nor C<$y> is used; "infinite" should be the sole argument.

=cut

my $number = qr/(?:[+-]?)(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee](?:[+-]?\d+))?/;
sub _number_re { $number }

my %tolerance_type = (
	constant          => {
		construct => sub { { value => $_[0], min => $_[0], max => $_[0] } },
		parse     => sub { $_[0] if ($_[0] =~ m!\A($number)\Z!) },
		# stringify not needed; constants must never be blessed
		valid_args=> sub {
			return $_[0] if @_==1 and $_[0] =~ $number;
			return
		}
	},
	plus_or_minus     => {
		construct => sub {
			{
				value => $_[0],
				variance => $_[1],
				min => $_[0] - $_[1],
				max => $_[0] + $_[1]
			}
		},
		parse     => sub {
			tolerance("$1", 'plus_or_minus', "$2")
				if ($_[0] =~ m!\A($number) \+/- ($number)\Z!)
		},
		stringify => sub { "$_[0]->{value} +/- $_[0]->{variance}"  },
		valid_args=> sub {
			return ($_[0],$_[2])
				if ((grep { defined } @_) == 3)
				and ($_[0] =~ $number)
				and ($_[1] eq 'plus_or_minus')
				and ($_[2] =~ $number);
			return;
		}
	},
	plus_or_minus_pct => {
		construct => sub {
			{
				value    => $_[0],
				variance => $_[1],
				min      => $_[0] - $_[0]*($_[1]/100),
				max      => $_[0] + $_[0]*($_[1]/100)
			}
		},
		parse     => sub {
			tolerance("$1", 'plus_or_minus_pct', "$2")
				if ($_[0] =~ m!\A($number) \+/- ($number)%\Z!) 
		},
		stringify => sub { "$_[0]->{value} +/- $_[0]->{variance}%" },
		valid_args=> sub {
			return ($_[0],$_[2])
				if ((grep { defined } @_) == 3)
				and ($_[0] =~ $number)
				and ($_[1] eq 'plus_or_minus_pct')
				and ($_[2] =~ $number);
			return;
		}
	},
	or_more           => {
		construct => sub { { value => $_[0], min => $_[0] } },
		parse     => sub { 
			tolerance("$1", 'or_more') if ($_[0] =~ m!\A($number) or more\Z!)
		},
		stringify => sub { "$_[0]->{min} or more" },
		valid_args=> sub {
			return ($_[0])
				if ((grep { defined } @_) == 2)
				and ($_[0] =~ $number) and ($_[1] eq 'or_more');
			return;
		}
	},
	or_less           => {
		construct => sub { { value => $_[0], max => $_[0] } },
		parse     => sub {
			tolerance("$1", 'or_less') if ($_[0] =~ m!\A($number) or less\Z!)
		},
		stringify => sub { "$_[0]->{max} or less" },
		valid_args=> sub {
			return ($_[0])
				if ((grep { defined } @_) == 2)
				and ($_[0] =~ $number) and ($_[1] eq 'or_less');
			return;
		}
	},
	to                => {
		construct => sub {
			($_[0],$_[1]) = sort { $a <=> $b } ($_[0],$_[1]);
			{
				value    => ($_[0]+$_[1])/2,
				variance => $_[1] - ($_[0]+$_[1])/2,
				min      => $_[0],
				max      => $_[1]
			}
		},
		parse     => sub {
			tolerance("$1", 'to', "$2") if ($_[0] =~ m!\A($number) to ($number)\Z!)
		},
		stringify => sub { "$_[0]->{min} to $_[0]->{max}" },
		valid_args=> sub {
			return ($_[0],$_[2])
				if ((grep { defined } @_) == 3)
				and ($_[0] =~ $number) and ($_[1] eq 'to') and ($_[2] =~ $number);
			return;
		}
	},
	infinite          => {
		construct => sub { { value => 0 } },
		parse     => sub { tolerance('infinite') if ($_[0] =~ m!\Aany number\Z!) },
		stringify => sub { "any number" },
		valid_args=> sub {
			return ($_[0]) if @_==1 and defined $_[0] and $_[0] eq 'infinite'; return;
		}
	},
);

sub _tolerance_type { \%tolerance_type }

sub tolerance { __PACKAGE__->new(@_); }

sub new {
	my $class = shift;
	return unless @_;
	my $self;

	for my $type (keys %tolerance_type) {
		next unless $tolerance_type{$type}->{valid_args};
		next unless my @args =  $tolerance_type{$type}->{valid_args}->(@_);
		my $guts = $tolerance_type{$type}->{construct}->(@args);
		return $guts->{value} if
			defined $guts->{min} and defined $guts->{max} and
			$guts->{min} == $guts->{max};
		$self = { method => $type, %$guts };
		last;
	}

	return unless $self;
	bless $self => $class;
}

=head3 C<< from_string($stringification) >>

A new tolerance can be instantiated from the stringification of an old
tolerance.  For example:

 my $range = Number::Tolerant->from_string("10 to 12");

 die "Everything's OK!" if 11 == $range; # program dies of joy

This will I<not> yet parse stringified unions, but that will be implemented in
the future.  (I just don't need it yet.)

=cut

sub from_string {
 	my ($class, $string) = @_;
 	croak "from_string is a class method" if ref $class;
	for my $type (keys %tolerance_type) {
		next unless $tolerance_type{$type}->{parse};
		if (my $tolerance = $tolerance_type{$type}->{parse}->($string)) {
			return $tolerance;
		}
	}
	return;
}

sub _stringify { $tolerance_type{$_[0]->{method}}->{stringify}->($_[0]) }

sub _num_eq  { not(_num_gt($_[0],$_[1])) and not(_num_lt($_[0],$_[1])) }

sub _num_gt  {
	$_[2]
		? (defined $_[0]->{max} ? $_[1] >  $_[0]->{max} : undef)
		: (defined $_[0]->{min} ? $_[1] <  $_[0]->{min} : undef)
}

sub _num_lt  {
	$_[2]
		? (defined $_[0]->{min} ? $_[1] <  $_[0]->{min} : undef)
		: (defined $_[0]->{max} ? $_[1] >  $_[0]->{max} : undef)
}

sub _num_gte {
	return 1 if $_[1] == $_[0];
	$_[2]
		? (defined $_[0]->{max} ? $_[1] > $_[0]->{max} : undef)
		: (defined $_[0]->{min} ? $_[1] < $_[0]->{min} : undef)
}

sub _num_lte {
	return 1 if $_[1] == $_[0];
	$_[2]
		? (defined $_[0]->{min} ? $_[1] < $_[0]->{min} : undef)
		: (defined $_[0]->{max} ? $_[1] > $_[0]->{max} : undef)
}

sub _union {
	require Number::Tolerant::Union;
	return Number::Tolerant::Union->new($_[0],$_[1]);
}

sub _intersection {
	return $_[0] == $_[1] ? $_[1] : () unless ref $_[1];

	my ($min, $max);

	if (defined $_[0]->{min} and defined $_[1]->{min}) {
		($min) = sort {$b<=>$a}  ($_[0]->{min}, $_[1]->{min});
	} else {
		$min = $_[0]->{min} || $_[1]->{min};
	}

	if (defined $_[0]->{max} and defined $_[1]->{max}) {
		($max) = sort {$a<=>$b} ($_[0]->{max}, $_[1]->{max});
	} else {
		$max = $_[0]->{max} || $_[1]->{max};
	}

	return tolerance('infinite') unless defined $min || defined $max;
	return tolerance($min => 'or_more') unless defined $max;
	return tolerance($max => 'or_less') unless defined $min;
	return tolerance($min => to => $max);
}

=head2 Overloading

Tolerances overload a few operations, mostly comparisons.

=over

=item boolean

Tolerances are always true.

=item numification

Tolerances with finite ranges numify to their center values.  Tolerances with
infinite ranges numify to their fixed end.

=item stringification

A tolerance stringifies to a short description of itself.

 infinite - "any number"
 to       - "x to y"
 or_more  - "x or more"
 or_less  - "x or less"
 plus_or_minus     - "x +/- y"
 plus_or_minus_pct - "x +/- y%"

=item equality

A number is equal to a tolerance if it is neither less than nor greater than
it.  (See below).

=item comparison

A number is greater than a tolerance if it is greater than its maximum value.

A number is less than a tolerance if it is less than its minimum value.

No number is greater than an "or_more" tolerance or less than an "or_less"
tolerance.

"...or equal to" comparisons include the min/max values in the permissible
range, as common sense suggests.

=item tolerance intersection

A tolerance C<&> a tolerance or number is the intersection of the two ranges.
Intersections allow you to quickly narrow down a set of tolerances to the most
stringent intersection of values.

 tolerance(5 => to => 6) & tolerance(5.5 => to => 6.5);
 # this yields: tolerance(5.5 => to => 6)

If the given values have no intersection, C<()> is returned.

An intersection with a normal number will yield that number, if it is within
the tolerance.

=item tolerance union

A tolerance C<|> a tolerance or number is the union of the two.  Unions allow
multiple tolerances, whether they intersect or not, to be treated as one.  See
L<Number::Tolerant::Union> for more information.

=cut

use overload
	fallback => 1,
	'bool'   => sub { 1 },
	'0+' => sub { $_[0]->{value} },
	'""' => \&_stringify,
	'==' => \&_num_eq,
	'>'  => \&_num_gt,
	'<'  => \&_num_lt,
	'>=' => \&_num_gte,
	'<=' => \&_num_lte,
	'|'  => \&_union,
	'&'  => \&_intersection;

=back

=head2 EXTENDING

This feature is slighly experimental, but it's here.  Custom tolerance types
can be created by adding entries to the hash returned by the C<_tolerance_type>
method.  Each entry is a hash of coderefs used to implement the tolerance.
The keys are as follows: 

 construct  - returns the reference to be blessed into the tolerance object
 parse      - used by from_string; returns the object that represents the string
              or undef, if the string doesn't represent this kind of tolerance
 stringify  - provides the string representation of the object (which is passed)
 valid_args - passed args from ->new() or tolerance(); if they indicate this 
              type of tolerance, this sub returns args to be passed to
              construct

=head1 TODO

Extend C<from_string> to cover unions.

Allow translation into forms not originally used:

 $range = tolerance(9 => to => 17); 
 $range->convert_to('plus_minus');
 $range->stringify_as('plus_minus_pct');

=head1 SEE ALSO

The module L<Number::Range> provides another way to deal with ranges of
numbers.  The major differences are: N::R is set-like, not range-like; N::R
does not overload any operators.  Number::Tolerant will not (like N::R) attempt
to parse a textual range specification like "1..2,5,7..10"

The C<Number::Range> code:

 $range = Number::Range->new("10..15","20..25");

Is equivalent to the C<Number::Tolerant> code:

 $range = Number::Tolerant::Union->new(10..15,20..25);

...while the following code expresses an actual range:

 $range = tolerance(10 => to => 15) | tolerance(20 => to => 25);

=head1 AUTHOR

Ricardo SIGNES, E<lt>rjbs@cpan.orgE<gt>

=head1 COPYRIGHT

(C) 2004, Ricardo SIGNES.  Number::Tolerant is available under the same terms
as Perl itself.

=cut

"1 ± 0";
