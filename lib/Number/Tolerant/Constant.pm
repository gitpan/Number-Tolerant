package Number::Tolerant::Constant;
our $VERSION = "1.00";

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(tolerance);

use Carp;
use Number::Tolerant;

=head1 NAME

Number::Tolerant::Constant -- a blessed constant type

=head1 VERSION

version 1.00

 $Id: Constant.pm,v 1.1 2004/08/24 19:49:34 rjbs Exp $

=head1 SYNOPSIS

 use Number::Tolerant;
 use Number::Tolerant::Constant;

 my $range  = tolerance(10);
 ref $range; # "Number::Tolerant" -- w/o ::Constant, would be undef

=head1 DESCRIPTION

When Number::Tolerant is about to return a tolerance with zero variation, it
will return a constant instead.  This module will register a constant type that
will catch these constants and return them as Number::Tolerant objects.

I wrote this module to make it simpler to use tolerances with Class::DBI, which
would otherwise complain that the constructor hadn't returned a blessed object.

=cut

my $number = Number::Tolerant->_number_re;

Number::Tolerant->_tolerance_type->{constant} = {
	construct => sub { { value => $_[0], min => $_[0], max => $_[0], constant => 1 } },
	parse     => sub { $_[0] if ($_[0] =~ m!\A($number)\Z!) },
	stringify => sub { $_[0]->{value} },
	valid_args=> sub {
		return $_[0] if @_==1 and $_[0] =~ $number;
		return
	}
};

=head1 TODO

=head1 AUTHOR

Ricardo SIGNES, E<lt>rjbs@cpan.orgE<gt>

=head1 COPYRIGHT

(C) 2004, Ricardo SIGNES.  Number::Tolerant::Constant is available under the
same terms as Perl itself.

=cut

1;
