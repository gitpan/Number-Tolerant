#!perl -T

use Test::More tests => 2;

use_ok( 'Number::Tolerant' );
use_ok( 'Number::Tolerant::Union' );

diag( "Testing Number::Tolerant $Number::Tolerant::VERSION" );
