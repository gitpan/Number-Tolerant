package Number::Tolerant;
our $VERSION = sprintf "%d.%03d", q$Revision: 1.15 $ =~ /(\d+)/g;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(tolerance);

=head1 NAME

Number::Tolerant -- tolerance ranges for inexact numbers

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
C<$x> and C<$y> are both ignored, if passed.

=cut

sub _args_valid {
	my ($method, $x, $y) = @_;
	return 1 if $method eq 'infinite';
	return unless defined $x;
	$method =~ /^(plus|to)/ and return unless defined $y;
	return 1;
}

sub _arg_handler { 
	my $method = shift;
	my %methods = (
		plus_or_minus     => sub { $_[0], $_[1], $_[0] - $_[1], $_[0] + $_[1] },
		plus_or_minus_pct => sub { $_[0], $_[1], $_[0] - $_[0]*($_[1]/100), $_[0] + $_[0]*($_[1]/100) },
		or_more           => sub { $_[0], undef, $_[0], undef },
		or_less           => sub { $_[0], undef, undef, $_[0] },
		to                => sub { ($_[0],$_[1]) = sort { $a <=> $b } ($_[0],$_[1]); ($_[0]+$_[1])/2, $_[1] - ($_[0]+$_[1])/2, $_[0], $_[1] },
		infinite          => sub { 0, undef, undef, undef },
	);
	return $methods{$method};
}

sub values {
	shift; my ($method, $x, $y) = @_;
	return unless _args_valid($method, $x, $y);
	return unless my $handler = _arg_handler($method);
	my %return;
	@return{qw(method value variance min max)} = ($method, $handler->($x,$y));
	return $return{value} if defined $return{variance} and not $return{variance};
	%return;
}

sub tolerance { __PACKAGE__->new(@_); }

sub new {
	my $class = shift;
	unshift @_, undef if $_[0] eq 'infinite';
	return unless my @self = $class->values(@_[1,0,2]) ;
	return $self[0] if @self == 1;
	bless { @self } => $class;
}

sub stringify {
	my %strings = (
		plus_or_minus     => sub { "$_[0]->{value} +/- $_[0]->{variance}"  },
		plus_or_minus_pct => sub { "$_[0]->{value} +/- $_[0]->{variance}%" },
		or_more           => sub { "$_[0]->{min} or more" },
		or_less           => sub { "$_[0]->{max} or less" },
		to                => sub { "$_[0]->{min} to $_[0]->{max}" },
		infinite          => sub { "any number" },
	);
	$strings{$_[0]->{method}}->($_[0]);
}

sub num_eq  { not(num_gt($_[0],$_[1])) and not(num_lt($_[0],$_[1])) }

sub num_gt  {
	$_[2]
		? (defined $_[0]->{max} ? $_[1] >  $_[0]->{max} : undef)
		: (defined $_[0]->{min} ? $_[1] <  $_[0]->{min} : undef)
}

sub num_lt  {
	$_[2]
		? (defined $_[0]->{min} ? $_[1] <  $_[0]->{min} : undef)
		: (defined $_[0]->{max} ? $_[1] >  $_[0]->{max} : undef)
}

sub num_gte {
	$_[2]
		? (defined $_[0]->{max} ? $_[1] >= $_[0]->{max} : undef)
		: (defined $_[0]->{min} ? $_[1] <= $_[0]->{min} : undef)
}

sub num_lte {
	$_[2]
		? (defined $_[0]->{min} ? $_[1] <= $_[0]->{min} : undef)
		: (defined $_[0]->{max} ? $_[1] >= $_[0]->{max} : undef)
}

sub union {
	require Number::Tolerant::Union;
	return Number::Tolerant::Union->new($_[0],$_[1]);
}

sub intersection {
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

=head3 Overloading

Tolerances overload a few operations, mostly comparisons.

=over

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
	'0+' => sub { $_[0]->{value} },
	'""' => \&stringify,
	'==' => \&num_eq,
	'>'  => \&num_gt,
	'<'  => \&num_lt,
	'>=' => \&num_gte,
	'<=' => \&num_lte,
	'|'  => \&union,
	'&'  => \&intersection;

=back

=head1 TODO

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
