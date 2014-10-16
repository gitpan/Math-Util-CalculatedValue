use 5.008004;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

if ( $^O eq 'MSWin32' ) {
    die "On Win32 module requires perl >= 5.12" if not $^V or $^V lt v5.12;
}

WriteMakefile(
    NAME             => 'Math::Util::CalculatedValue',
    AUTHOR           => q{binary.com <rakesh@binary.com>},
    VERSION_FROM     => 'lib/Math/Util/CalculatedValue.pm',
    ABSTRACT_FROM    => 'lib/Math/Util/CalculatedValue.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'List::Util'       => 0,
        'MooseX::Role::Validatable' => 0,
        'MooseX::NonMoose' => 0,
        'Test::More'       => 0.96,
        'Test::Exception'  => 0,
        'Test::NoWarnings' => 0,
        'Test::Exception'  => 0
    },
    PREREQ_PM => {
        'List::Util' => 0,
        'MooseX::Role::Validatable' => 0,
        'MooseX::NonMoose' => 0
    },
    META_MERGE => {
        requires  => { perl => 5.008004, },
        resources => {
            homepage   => 'https://github.com/binary-com/perl-Math-Util-CalculatedValue',
            bugtracker => 'https://github.com/binary-com/perl-Math-Util-CalculatedValue/issues',
            repository => 'git@github.com:binary-com/perl-Math-Util-CalculatedValue.git',
            license    => 'http://dev.perl.org/licenses/',
        },
        keywords       => ['cache','redisdb'],
        x_contributors => [
            'Rakesh Kumar Shardiwal <shardiwal@cpan.org>',
        ],
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Math-Util-CalculatedValue-*' },
);
