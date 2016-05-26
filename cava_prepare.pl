#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use File::Copy::Recursive qw(rcopy);
use Cava::Packager::Release;

my $release = Cava::Packager::Release->new();

my $this_path = dirname( __FILE__ );

for my $dir ( qw/img conf/ ) {
    my $source = File::Spec->catdir( $this_path, $dir );
    my $target = File::Spec->catdir( $release->get_release_path, $dir );
    
    rcopy $source, $target;
}