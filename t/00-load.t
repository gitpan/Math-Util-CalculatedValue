#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Util::CalculatedValue' ) || print "Bail out!\n";
}

diag( "Testing Math::Util::CalculatedValue $Math::Util::CalculatedValue::VERSION, Perl $], $^X" );
