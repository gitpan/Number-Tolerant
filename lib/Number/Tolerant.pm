package Number::Tolerant;
our $VERSION = "1.22";

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(tolerance);

use Carp;

=head1 NAME

Number::Tolerant -- tolerance ranges for inexact numbers

=head1 VERSION

version 1.22

 $Id: Tolerant.pm,v 1.17 2004/08/19 19:36:46 rjbs Exp $

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
  plus_or_minus     | x � y
  plus_or_minus_pct | x � (y% of x)
  or_more           | x to Inf
  or_less           | x to -Inf
  to                | x to y
  infinite          | -Inf to Inf

For C<or_less> and C<or_more>, C<$y> is ignored if passed.  For C<infinite>,
neither C<$x> nor C<$y> is used; "infinite" should be the sole argument.

=cut

sub _args_valid {
	my ($method, $x, $y) = @_;
	return 1 if $method eq 'infinite';
	return unless defined $x;
	return if $method =~ /^(plus|to)/ and not defined $y;
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

sub _values {
	shift; my ($method, $x, $y) = @_;
	return unless $method;
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
	return unless @_;
	unshift @_, undef if $_[0] and $_[0] eq 'infinite';
	return $_[0] if @_==1 and $_[0] =~ $class->_number_re;
	return unless my @self = $class->_values(@_[1,0,2]) ;
	return $self[0] if @self == 1;
	bless { @self } => $class;
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

	if (my @params = $class->_parse_string("$string")) {
		return $class->new(@params);
	} else {
		return;
	}
}

sub _number_re { qr/([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?/ }

sub _parse_string {
	my ($class, $string) = @_;

	my $number = $class->_number_re;

	return ($1)
		if $string =~ m!\A($number)\Z!;
	return ($1, 'plus_or_minus', $6)
		if $string =~ m!\A($number) \+/- ($number)\Z!;
	return ($1, 'plus_or_minus_pct', $6)
		if $string =~ m!\A($number) \+/- ($number)%\Z!;
	return ($1, 'or_more')
		if $string =~ m!\A($number) or more\Z!;
	return ($1, 'or_less')
		if $string =~ m!\A($number) or less\Z!;
	return ($1, 'to', $6)
		if $string =~ m!\A($number) to ($number)\Z!;
	return ('infinite')
		if $string =~ m!\Aany number\Z!;
	return;
}

sub _stringify {
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
	'""' => \&_stringify,
	'==' => \&_num_eq,
	'>'  => \&_num_gt,
	'<'  => \&_num_lt,
	'>=' => \&_num_gte,
	'<=' => \&_num_lte,
	'|'  => \&_union,
	'&'  => \&_intersection;

=back

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

"1 � 0";
