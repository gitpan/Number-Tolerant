use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.034

use Test::More 0.94 tests => 15;



my @module_files = (
    'Number/Tolerant.pm',
    'Number/Tolerant/Constant.pm',
    'Number/Tolerant/Type.pm',
    'Number/Tolerant/Type/constant.pm',
    'Number/Tolerant/Type/infinite.pm',
    'Number/Tolerant/Type/less_than.pm',
    'Number/Tolerant/Type/more_than.pm',
    'Number/Tolerant/Type/offset.pm',
    'Number/Tolerant/Type/or_less.pm',
    'Number/Tolerant/Type/or_more.pm',
    'Number/Tolerant/Type/plus_or_minus.pm',
    'Number/Tolerant/Type/plus_or_minus_pct.pm',
    'Number/Tolerant/Type/to.pm',
    'Number/Tolerant/Union.pm',
    'Test/Tolerant.pm'
);



# no fake home requested

use File::Spec;
use IPC::Open3;
use IO::Handle;

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, '-Mblib', '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



# no warning checks;

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
