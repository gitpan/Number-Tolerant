package Number::Tolerant;
our $VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)/g;

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

For C<or_less> and C<or_more>, C<$y> is ignored if passed.

=cut

sub values {
	shift; my ($method, $x, $y) = @_;
	return unless defined $x;
	$method =~ /^(plus|to)/ and return unless defined $y;
	my %methods = (
		plus_or_minus     => sub { $method, $x, $y, $x - $y, $x + $y },
		plus_or_minus_pct => sub { $method, $x, $y, $x - $x*($y/100), $x + $x*($y/100) },
		or_more           => sub { $method, $x, undef, $x, undef },
		or_less           => sub { $method, $x, undef, undef, $x },
		to                => sub { ($x,$y) = sort ($x,$y); $method, ($x+$y)/2, $y - ($x+$y)/2, $x, $y }
	);
	return unless $methods{$method};
	my %return;
	@return{qw(method value tolerance min max)} = $methods{$method}->();
	%return;
}

sub tolerance { __PACKAGE__->new(@_); }

sub new {
	my $class = shift;
	return unless my %self = $class->values(@_[1,0,2]) ;
	bless \%self => $class;
}

sub stringify {
	my %strings = (
		plus_or_minus     => sub { "$_[0]->{value} +/- $_[0]->{tolerance}"  },
		plus_or_minus_pct => sub { "$_[0]->{value} +/- $_[0]->{tolerance}%" },
		or_more           => sub { "$_[0]->{min} or more" },
		or_less           => sub { "$_[0]->{max} or less" },
		to                => sub { "$_[0]->{min} to $_[0]->{max}" },
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

=head2 Overloading

Tolerances overload a few operations, mostly comparisons.

=over

=item numification

Tolerances with finite ranges numify to their center values.  Tolerances with
infinite ranges numify to their fixed end.

=item stringification

A tolerance stringifies to a short description of itself.

 to      - "x to y"
 or_more - "x or more"
 or_less - "x or less"
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

=cut

use overload
	fallback => 1,
	'0+' => sub { $_[0]->{value} },
	'""' => \&stringify,
	'==' => \&num_eq,
	'>'  => \&num_gt,
	'<'  => \&num_lt,
	'>=' => \&num_gte,
	'<=' => \&num_lte;

=back

=head1 TODO

Overload & to create an intersection of allowed values.

Allow translation into forms not originally used:

 $range = tolerance(9 => to => 17); 
 $range->convert_to('plus_minus');

=head1 AUTHOR

Ricardo SIGNES, E<lt>rjbs@cpan.orgE<gt>

=head1 COPYRIGHT

(C) 2004, Ricardo SIGNES.  Number::Tolerant is available under the same terms
as Perl itself.

=cut

"1 ± 0";
