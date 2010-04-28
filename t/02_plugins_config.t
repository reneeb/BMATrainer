#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Path::Class;
use File::Basename;

use BMA::Plugins;

my @methods = qw(new get_type);
can_ok( 'BMA::Plugins', @methods );

my $path = Path::Class::Dir->new(
    dirname( __FILE__ ),
)->absolute->stringify;

my $plugins = BMA::Plugins->new(
    directory => $path,
);

ok $plugins, 'Object created successfully';
isa_ok $plugins, 'BMA::Plugins', 'Object is of type "BMA::Plugins"';

my @inactive_input  = qw/Counter/;
my @active_input    = qw/Feuermelder/;
my @inactive_output = qw/Sirene2/;
my @active_output   = qw/Sirene/;

my @active_out_plugins = $plugins->get_type( 'output', 1 );
is scalar( @active_out_plugins ), scalar( @active_output ), 'Nr of active output plugins is correct';

my @active_in_plugins  = $plugins->get_type( 'input', 1 );
is scalar( @active_in_plugins ), scalar( @active_input ), 'Nr of active input plugins is correct';