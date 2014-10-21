package Number::Tolerant::Constant;
our $VERSION = "1.52";

use strict;
use warnings;

=head1 NAME

Number::Tolerant::Constant - a blessed constant type

=head1 VERSION

version 1.50

 $Id: /my/cs/projects/tolerant/trunk/lib/Number/Tolerant/Constant.pm 22014 2006-05-11T23:00:09.416140Z rjbs  $

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

package Number::Tolerant::Type::constant_obj;
use base qw(Number::Tolerant::Type);

my $number = $Number::Tolerant::Type::number;

sub construct { shift;
  { value => $_[0], min => $_[0], max => $_[0], constant => 1 }
};

sub parse { shift;
  Number::Tolerant::tolerance$_[0] if ($_[0] =~ m!\A($number)\z!)
}

sub stringify { $_[0]->{value} }

sub valid_args { shift;
  return $_[0] if @_==1 and $_[0] =~ m!\A($number)\z!;
  return;
}

package Number::Tolerant::Constant;

sub import {
  Number::Tolerant->disable_plugin("Number::Tolerant::Type::constant");
  Number::Tolerant->enable_plugin( "Number::Tolerant::Type::constant_obj");
}

sub _disable {
  Number::Tolerant->disable_plugin("Number::Tolerant::Type::constant_obj");
  Number::Tolerant->enable_plugin( "Number::Tolerant::Type::constant");
}

=head1 TODO

=head1 AUTHOR

Ricardo SIGNES, E<lt>rjbs@cpan.orgE<gt>

=head1 COPYRIGHT

(C) 2004-2006, Ricardo SIGNES.  Number::Tolerant::Constant is available under
the same terms as Perl itself.

=cut

1;
