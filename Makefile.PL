
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'tolerance ranges for inexact numbers',
  'AUTHOR' => 'Ricardo Signes <rjbs@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.96',
    'Test::Tester' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Number-Tolerant',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Number::Tolerant',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Math::BigFloat' => '0',
    'Math::BigRat' => '0',
    'Scalar::Util' => '0',
    'Sub::Exporter' => '0.950',
    'Sub::Exporter::Util' => '0',
    'Test::Builder' => '0',
    'overload' => '0'
  },
  'VERSION' => '1.701',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



