use strict;
use warnings;
package Number::Tolerant::Type;
BEGIN {
  $Number::Tolerant::Type::VERSION = '1.701';
}
use base qw(Number::Tolerant);
# ABSTRACT: a type of tolerance

use Math::BigFloat;
use Math::BigRat;



my $number;
BEGIN {
  $number = qr{
    (?:
      (?:[+-]?)
      (?=[0-9]|\.[0-9])
      [0-9]*
      (?:\.[0-9]*)?
      (?:[Ee](?:[+-]?[0-9]+))?
    )
    |
    (?:
      [0-9]+ / [1-9][0-9]*
    )
  }x;
}

sub number_re { return $number; }

sub normalize_number {
  my ($self, $input) = @_;

  return if not defined $input;
  
  if ($input =~ qr{\A$number\z}) {
    return $input =~ m{/} ? Math::BigRat->new($input) : $input;
    # my $class = $input =~ m{/} ? 'Math::BigRat' : 'Math::BigRat';
    # return $class->new($input);
  }

  local $@;
  return $input if ref $input and eval { $input->isa('Math::BigInt') };

  return;
}


my $X;
BEGIN { $X =  qr/(?:\s*x\s*)/; }

sub variable_re { return $X; }

1;

__END__
=pod

=head1 NAME

Number::Tolerant::Type - a type of tolerance

=head1 VERSION

version 1.701

=head1 SYNOPSIS

=head1 METHODS

=head2 valid_args

  my @args = $type_class->valid_args(@_);

If the arguments to C<valid_args> are valid arguments for this type of
tolerance, this method returns their canonical form, suitable for passing to
C<L</construct>>.  Otherwise this method returns false.

=head2 construct

  my $object_guts = $type_class->construct(@args);

This method is passed the output of the C<L</valid_args>> method, and should
return a hashref that will become the guts of a new tolerance.

=head2 parse

  my $tolerance = $type_class->parse($string);

This method returns a new, fully constructed tolerance from the given string
if the given string can be parsed into a tolerance of this type.

=head2 number_re

  my $number_re = $type_class->number_re;

This method returns the regular expression (as a C<qx> construct) used to match
number in parsed strings.

=head2 normalize_number

  my $number = $type_class->normalize_number($input);

This method will decide whether the given input is a valid number for use with
Number::Tolerant and return it in a canonicalized form.  Math::BigInt objects
are returned intact.  Strings holding numbers are also returned intact.
Strings that appears to be fractions are converted to Math::BigRat objects.

Anything else is considered invalid, and the method will return false.

=head2 variable_re

  my $variable_re = $type_class->variable_re;

This method returns the regular expression (as a C<qr> construct) used to match
the variable in parsed strings.

When parsing "4 <= x <= 10" this regular expression is used to match the letter
"x."

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

